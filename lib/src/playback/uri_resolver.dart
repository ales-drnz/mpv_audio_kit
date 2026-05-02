// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Internal URI normalizer invoked by `Player.open()` / `Player.openAll()` /
// `Player.add()` / `Player.replace()` for every media URI before it
// reaches `loadfile`. Translates host-platform schemes that libmpv does
// not understand into something it does:
//
//   asset://path/inside/bundle  → /tmp/mpv_asset_<safe_name>   (every platform)
//   content://...               → fd://<n>                     (Android only)
//
// All other URIs (`file://`, `http(s)://`, `rtsp://`, `smb2://`, plain
// filesystem paths, …) pass through unchanged.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

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
/// the caller MUST invoke if the URI is never handed to mpv (e.g. when
/// the caller's `_disposed` flag flips between resolve and `loadfile`).
/// For Android `content://` URIs the call detaches a file descriptor
/// from the JVM side; without disposing on abort the FD is leaked for
/// the process lifetime.
///
/// For URIs that don't allocate platform resources (asset://, plain
/// paths, network URLs) [dispose] is `null`.
class ResolvedUri {
  const ResolvedUri(this.uri, [this.dispose]);

  /// The URI as libmpv accepts it (`fd://N`, an absolute filesystem
  /// path, or the original string for pass-through schemes).
  final String uri;

  /// Releases any platform resources allocated by the resolution.
  /// `null` when the resolution allocated nothing.
  final Future<void> Function()? dispose;
}

/// Resolves [uri] for libmpv and returns a [ResolvedUri] whose
/// [ResolvedUri.dispose] callback must be invoked if the result is
/// never passed to `loadfile`.
///
/// Throws a [StateError] when an Android `content://` URI cannot be
/// resolved to an open file descriptor — letting the failure surface
/// at the `Player.open()` call site rather than silently handing mpv
/// a URI it cannot open. `asset://` failures keep the soft-fallback
/// behaviour: the original URI is returned and mpv emits a typed
/// end-file error if the path does not work either.
Future<ResolvedUri> resolveUri(String uri) async {
  if (uri.startsWith('asset://')) {
    try {
      return ResolvedUri(await _copyAssetToCache(uri));
    } catch (e) {
      debugPrint('mpv_audio_kit: asset resolution failed for $uri: $e');
      return ResolvedUri(uri);
    }
  }
  if (Platform.isAndroid && uri.startsWith('content://')) {
    try {
      final fd = await _channel
          .invokeMethod<int>('openFileDescriptor', {'uri': uri});
      if (fd != null && fd > 0) {
        return ResolvedUri('fd://$fd', () => _closeAndroidFd(fd));
      }
      throw StateError(
        'mpv_audio_kit: content:// resolution returned no file descriptor '
        'for $uri (the ContentResolver may have rejected the URI or the '
        'caller lacks read permission)',
      );
    } on PlatformException catch (e) {
      throw StateError(
        'mpv_audio_kit: content:// resolution failed for $uri '
        '(${e.code}: ${e.message})',
      );
    }
  }
  return ResolvedUri(uri);
}

Future<void> _closeAndroidFd(int fd) async {
  try {
    await _channel.invokeMethod<void>('closeFileDescriptor', {'fd': fd});
  } catch (e) {
    debugPrint('mpv_audio_kit: closeFileDescriptor failed for fd=$fd: $e');
  }
}

Future<String> _copyAssetToCache(String uri) {
  final cached = _assetCache[uri];
  // Re-check the file on every hit. macOS / Linux may evict /tmp between
  // sessions or under disk pressure; without this guard a cached path
  // outlives its file and `loadfile` fails opaquely. The miss path
  // re-extracts the asset.
  if (cached != null && File(cached).existsSync()) return Future.value(cached);
  if (cached != null) _assetCache.remove(uri);
  return _assetInflight.putIfAbsent(uri, () => _doCopyAsset(uri));
}

Future<String> _doCopyAsset(String uri) async {
  try {
    // Re-check the cache: a previous in-flight copy for the same URI
    // may have completed between our cache miss and putIfAbsent.
    final cached = _assetCache[uri];
    if (cached != null) return cached;

    String assetPath = uri.substring('asset://'.length);
    if (assetPath.startsWith('/')) {
      assetPath = assetPath.substring(1);
    }

    final data = await rootBundle.load(assetPath);

    // Both POSIX (`/`) and Windows (`\`) separators are flattened so the
    // temp filename never contains directory parts. On POSIX
    // `Platform.pathSeparator` is `/` and the second pass is a no-op.
    final safeName =
        assetPath.replaceAll(Platform.pathSeparator, '_').replaceAll('/', '_');
    final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_asset_$safeName');

    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    _assetCache[uri] = file.path;
    return file.path;
  } finally {
    _assetInflight.remove(uri);
  }
}
