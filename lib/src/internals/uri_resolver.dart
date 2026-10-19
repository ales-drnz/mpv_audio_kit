// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Internal URI normalizer invoked by `Player.open()`, `Player.openAll()`,
// `Player.openPlaylistFile()`, `Player.add()`, `Player.replace()` and
// `Player.addAudioTrack()` for every media URI before it reaches mpv.
// Translates host-platform schemes that libmpv does not understand into
// something it does:
//
//   asset://path/inside/bundle  → <temp>/mpv_audio_kit_assets_<app>/mpv_asset_<hash>_<safe_name>
//   content://...               → fd://<n>                     (Android only)
//   file:///path/a%20b.flac     → /path/a b.flac
//
// `file://` URIs become the path mpv itself would store for them, so the
// playlist entries mpv reports match the Media cache keys. All other URIs
// (`http(s)://`, `smb2://`, plain filesystem paths, …) pass through
// unchanged.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../events/player_exception.dart';

const MethodChannel _channel = MethodChannel('mpv_audio_kit');
final Map<String, String> _assetCache = {};

// Deduplicates concurrent [resolveUri] calls for the same asset: the
// first caller does the bundle load + file write, concurrent callers
// await the same Future. Without this, two open() calls on the same
// asset could both reach `writeAsBytes` and the second writer could
// truncate the first writer's file mid-flush.
final Map<String, Future<String>> _assetInflight = {};

/// Resolution result for a URI passed through [resolveUri].
///
/// Carries the libmpv-loadable [uri] plus an optional [dispose] callback
/// that releases what the resolution allocated. For Android `content://`
/// URIs the call detaches a file descriptor from the JVM side, and mpv
/// never closes an `fd://` descriptor (it reads it again on every open of
/// the entry). The player holds it while the entry is in the playlist and
/// calls [dispose] afterwards, at dispose, or at once when the load is
/// aborted before mpv gets the URI.
///
/// For URIs that don't allocate platform resources (asset://, plain
/// paths, network URLs) [dispose] is `null`.
class ResolvedUri {
  /// Wraps a libmpv-loadable [uri] with an optional [dispose] callback
  /// that releases any platform resources the resolution allocated.
  const ResolvedUri(this.uri, [this.dispose]);

  /// The URI as libmpv accepts it (`fd://N`, an absolute filesystem
  /// path, or the original string for pass-through schemes).
  final String uri;

  /// Releases any platform resources allocated by the resolution.
  /// `null` when the resolution allocated nothing.
  final Future<void> Function()? dispose;
}

/// Test-only: replaces [resolveUri] for every load, so a test can stand in
/// for a source that holds a platform resource (an Android `content://`
/// descriptor) on any host, and count its releases.
@visibleForTesting
Future<ResolvedUri> Function(String uri)? debugResolveUriOverride;

/// Resolves [uri] for libmpv and returns a [ResolvedUri] whose
/// [ResolvedUri.dispose] callback must be invoked if the result is
/// never passed to `loadfile`.
///
/// Throws a [SourceException] when an `asset://` cannot be copied out of
/// the bundle, or an Android `content://` URI cannot be resolved to an
/// open file descriptor, so the failure surfaces at the `Player.open()`
/// call site rather than as a URI mpv cannot open.
Future<ResolvedUri> resolveUri(String uri) async {
  final override = debugResolveUriOverride;
  if (override != null) return override(uri);
  final path = fileUrlToPath(uri);
  if (path != null) return ResolvedUri(path);
  if (uri.startsWith('asset://')) {
    try {
      return ResolvedUri(await _copyAssetToCache(uri));
    } catch (e) {
      throw SourceException(uri, 'the asset could not be loaded: $e');
    }
  }
  if (Platform.isAndroid && uri.startsWith('content://')) {
    try {
      final fd = await _channel.invokeMethod<int>('openFileDescriptor', {
        'uri': uri,
      });
      if (fd != null && fd > 0) {
        return ResolvedUri('fd://$fd', () => _closeAndroidFd(fd));
      }
      throw SourceException(
        uri,
        'the ContentResolver returned no file descriptor (it may have '
        'rejected the URI, or the app lacks read permission)',
      );
    } on PlatformException catch (e) {
      throw SourceException(uri, '${e.code}: ${e.message}');
    }
  }
  return ResolvedUri(uri);
}

/// The name [resolveUri] gives mpv for [uri], worked out without loading
/// or copying anything: the path of a `file://` URL or of an `asset://`
/// copy, or [uri] itself. mpv keys a resume point by that name. An
/// Android `content://` URI gets a new descriptor at each load, so it
/// has no name to give and comes back as it is.
Future<String> loadedName(String uri) async {
  final path = fileUrlToPath(uri);
  if (path != null) return path;
  if (uri.startsWith('asset://')) {
    return _assetCache[uri] ?? await _assetCopyPath(_assetKey(uri));
  }
  return uri;
}

/// Whether mpv reads [uri] from an open descriptor (`fd://N`, as an
/// Android `content://` URI loads, or `fdclose://N`).
bool isFdUri(String uri) =>
    uri.startsWith('fd://') || uri.startsWith('fdclose://');

/// The path mpv stores for a `file://` [uri], or `null` for any other URI.
///
/// Mirrors mpv's `mp_file_url_to_filename`, which every `loadfile` goes
/// through: the scheme is dropped whatever its case, `%NN` escapes are
/// decoded byte by byte (a malformed one is kept as it is), and on Windows
/// `/C:/` becomes `C:/`. The playlist then names the entry by this path,
/// not by the URL it was loaded with. Escapes that are not UTF-8 (a
/// Latin-1 file name) give `null`: a Dart string cannot carry those bytes,
/// so the URL goes to mpv as it is and mpv decodes it.
///
/// A host is read as RFC 8089 reads it, where mpv would keep it as the
/// start of a relative path. `localhost` is dropped. On Windows any other
/// host names a share, `\\host\share\...`, as `Uri.file` writes one; so
/// does `localhost` when no drive letter follows it. Elsewhere another host
/// stays in the path, as in mpv. A drive right after the scheme
/// (`file://C:/...`) is a drive, not a host: mpv opens it as `C:/...`.
String? fileUrlToPath(String uri, {bool? windows}) {
  if (uri.length < 7 || uri.substring(0, 7).toLowerCase() != 'file://') {
    return null;
  }
  final isWindows = windows ?? Platform.isWindows;
  var raw = uri.substring(7);
  var share = false;
  final slash = raw.indexOf('/');
  if (slash > 0 && !_isDrive(raw.substring(0, slash))) {
    final local = raw.substring(0, slash).toLowerCase() == 'localhost';
    final drive = raw.length > slash + 2 && raw[slash + 2] == ':';
    if (isWindows && !(local && drive)) {
      share = true;
    } else if (local) {
      raw = raw.substring(slash);
    }
  }
  final src = utf8.encode(raw);
  final out = <int>[];
  for (var i = 0; i < src.length;) {
    if (src[i] != 0x25 || i + 2 >= src.length) {
      out.add(src[i++]);
      continue;
    }
    final hi = _hexDigit(src[i + 1]);
    final lo = _hexDigit(src[i + 2]);
    if (hi >= 0 && lo >= 0) {
      out.add(hi * 16 + lo);
    } else {
      out.addAll(src.sublist(i, i + 3));
    }
    i += 3;
  }
  String path;
  try {
    path = utf8.decode(out);
  } on FormatException {
    return null;
  }
  if (share) return r'\\' + path.replaceAll('/', r'\');
  if (isWindows && path.length > 2 && path[0] == '/' && path[2] == ':') {
    path = path.substring(1);
  }
  return path;
}

// A drive letter and ':', as in `C:`: no host is written that way.
bool _isDrive(String s) =>
    s.length == 2 &&
    s[1] == ':' &&
    ((s.codeUnitAt(0) | 0x20) >= 0x61 && (s.codeUnitAt(0) | 0x20) <= 0x7a);

int _hexDigit(int c) {
  if (c >= 0x30 && c <= 0x39) return c - 0x30;
  if (c >= 0x41 && c <= 0x46) return c - 0x41 + 10;
  if (c >= 0x61 && c <= 0x66) return c - 0x61 + 10;
  return -1;
}

Future<void> _closeAndroidFd(int fd) async {
  try {
    await _channel.invokeMethod<void>('closeFileDescriptor', {'fd': fd});
  } catch (e) {
    debugPrint('mpv_audio_kit: closeFileDescriptor failed for fd=$fd: $e');
  }
}

/// A stable FNV-1a hash of [text] as eight hex digits (deterministic
/// across sessions, unlike String.hashCode).
String _fnv1a(String text) {
  var hash = 0x811c9dc5;
  for (final unit in text.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(8, '0');
}

/// The directory the asset copies go to. One fixed directory and one fixed
/// name per asset: a relaunch overwrites its old copy instead of leaving a
/// new one behind, and a process killed without dispose (the usual end on
/// mobile) leaks nothing that grows. The name carries the user and the app,
/// so two users sharing `/tmp` on Linux, or two apps with an asset of the
/// same name, never meet; on Linux the per-user `XDG_RUNTIME_DIR` is used
/// when there is one.
Future<Directory> _assetDirectory() async {
  final env = Platform.environment;
  final runtime = Platform.isLinux ? env['XDG_RUNTIME_DIR'] : null;
  final owner =
      '${env['USER'] ?? env['USERNAME'] ?? ''}'
      ' ${Platform.resolvedExecutable}';
  final name = 'mpv_audio_kit_assets_${_fnv1a(owner)}';
  if (runtime != null && runtime.isNotEmpty) {
    try {
      final dir = Directory('$runtime${Platform.pathSeparator}$name');
      await dir.create(recursive: true);
      return dir;
    } on FileSystemException {
      // An inherited XDG_RUNTIME_DIR of another user: fall back to temp.
    }
  }
  final dir = Directory(
    '${Directory.systemTemp.path}${Platform.pathSeparator}$name',
  );
  await dir.create(recursive: true);
  return dir;
}

Future<String> _copyAssetToCache(String uri) async {
  final cached = _assetCache[uri];
  // Re-check the file on every hit. macOS and Linux may evict /tmp between
  // sessions or under disk pressure; without this guard a cached path
  // outlives its file and `loadfile` fails opaquely. The miss path
  // re-extracts the asset.
  if (cached != null) {
    if (await File(cached).exists()) return cached;
    _assetCache.remove(uri);
  }
  return _assetInflight.putIfAbsent(uri, () => _doCopyAsset(uri));
}

/// The bundle key of an `asset://` [uri].
String _assetKey(String uri) {
  final assetPath = uri.substring('asset://'.length);
  return assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
}

/// The most characters of an asset key a copy's name keeps, from its end.
const _kAssetNameTail = 64;

/// Where the copy of the asset at [assetPath] goes.
Future<String> _assetCopyPath(String assetPath) async {
  // Both POSIX (`/`) and Windows (`\`) separators are flattened so the
  // temp filename never contains directory parts. On POSIX
  // `Platform.pathSeparator` is `/` and the second pass is a no-op.
  final flat = assetPath
      .replaceAll(Platform.pathSeparator, '_')
      .replaceAll('/', '_');
  // Only the tail is kept, extension included: a deep key flattened whole
  // can pass NAME_MAX, and on Windows MAX_PATH, past which mpv cannot
  // open the copy.
  final runes = flat.runes;
  final safeName = runes.length <= _kAssetNameTail
      ? flat
      : String.fromCharCodes(runes.skip(runes.length - _kAssetNameTail));
  // Flattening and cutting are ambiguous: `a/b.mp3` and `a_b.mp3`
  // collapse to the same name, and the second extraction would overwrite
  // a file mpv may still be streaming. A hash of the ORIGINAL path
  // disambiguates.
  final dir = await _assetDirectory();
  return '${dir.path}${Platform.pathSeparator}'
      'mpv_asset_${_fnv1a(assetPath)}_$safeName';
}

Future<String> _doCopyAsset(String uri) async {
  try {
    final assetPath = _assetKey(uri);
    final data = await rootBundle.load(assetPath);
    final file = File(await _assetCopyPath(assetPath));

    // Written beside the target and renamed onto it, so another instance
    // of the app reading the same copy never sees it truncated. Slice the
    // asset's view explicitly: rootBundle bundles can pack multiple assets
    // into one backing buffer, and the no-arg asUint8List would span the
    // full backing buffer rather than just this asset's range.
    final part = File('${file.path}.$pid.part');
    await part.writeAsBytes(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      flush: true,
    );
    try {
      await part.rename(file.path);
    } on FileSystemException {
      // Windows refuses to replace a file another process has open: that
      // instance holds the same asset, so its copy is kept.
      try {
        await part.delete();
      } on FileSystemException {
        // Left behind; only a later copy from this same process (same
        // pid in the name) overwrites it.
      }
      if (!await file.exists()) rethrow;
    }

    _assetCache[uri] = file.path;
    return file.path;
  } finally {
    // `remove` returns the in-flight Future we are currently completing;
    // discard it: awaiting our own pending Future here would deadlock.
    unawaited(_assetInflight.remove(uri));
  }
}
