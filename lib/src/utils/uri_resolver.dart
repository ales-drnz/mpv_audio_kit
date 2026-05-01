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

// De-duplicates concurrent `normalizeUri()` calls for the same asset:
// the first caller does the bundle load + file write, any concurrent
// callers await the same Future. Without this, two open() calls on
// the same asset could both call writeAsBytes() in parallel and the
// second writer could truncate the first writer's file mid-flush.
final Map<String, Future<String>> _assetInflight = {};

Future<String> normalizeUri(String uri) async {
  try {
    if (uri.startsWith('asset://')) {
      return await _copyAssetToCache(uri);
    }
    if (Platform.isAndroid && uri.startsWith('content://')) {
      final fd = await _channel
          .invokeMethod<int>('openFileDescriptor', {'uri': uri});
      if (fd != null && fd > 0) {
        return 'fd://$fd';
      }
    }
  } catch (e) {
    debugPrint('mpv_audio_kit: normalizeUri error for $uri: $e');
  }
  return uri;
}

Future<String> _copyAssetToCache(String uri) {
  final cached = _assetCache[uri];
  if (cached != null) return Future.value(cached);
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

    final safeName = assetPath
        .replaceAll(Platform.pathSeparator, '_')
        .replaceAll('/', '_');
    final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_asset_$safeName');

    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    _assetCache[uri] = file.path;
    return file.path;
  } finally {
    _assetInflight.remove(uri);
  }
}
