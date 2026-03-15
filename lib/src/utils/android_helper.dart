// This file includes implementations derived from media_kit (https://github.com/media-kit/media-kit).
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Helps resolving Android-specific URIs like `asset://` and `content://`.
abstract class AndroidHelper {
  static const MethodChannel _channel = MethodChannel('mpv_audio_kit');
  static final Map<String, String> _assetCache = {};

  /// Normalizes a URI for use with libmpv.
  /// Converts `asset://` and `content://` schemas into regular file paths or file descriptors.
  static Future<String> normalizeUri(String uri) async {
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
      debugPrint(
          'mpv_audio_kit: AndroidHelper.normalizeUri error for $uri: $e');
    }
    return uri;
  }

  static Future<String> _copyAssetToCache(String uri) async {
    if (_assetCache.containsKey(uri)) {
      return _assetCache[uri]!;
    }

    // Extract the raw path inside the asset bundle
    String assetPath = uri.substring('asset://'.length);
    if (assetPath.startsWith('/')) {
      assetPath = assetPath.substring(1);
    }

    final data = await rootBundle.load(assetPath);

    // Sanitize path for use as a filesystem path
    final safeName =
        assetPath.replaceAll(Platform.pathSeparator, '_').replaceAll('/', '_');
    final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_asset_$safeName');

    await file.writeAsBytes(data.buffer.asUint8List(), flush: true);

    _assetCache[uri] = file.path;
    return file.path;
  }
}
