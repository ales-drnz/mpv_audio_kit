// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// What artwork_download_io.dart and artwork_download_web.dart share: the
// size limit, the MIME type from a name, and the `asset://` read.

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

import '../models/cover_art.dart';

/// Upper bound on a loaded cover. Real covers are a few MB at most;
/// anything larger is not an image worth putting on the media session.
@internal
const int maxArtworkBytes = 20 * 1024 * 1024;

/// The cover of an `asset://` [uri] from the app's bundle, keyed as
/// `Media` keys its assets (`asset://assets/a.png` or
/// `asset:///assets/a.png`); `null` when it is missing, empty or over 20 MB.
@internal
Future<CoverArt?> readArtworkAsset(Uri uri) async {
  final path = uri.toString().substring('asset://'.length);
  final key = Uri.decodeFull(path.startsWith('/') ? path.substring(1) : path);
  try {
    final data = await rootBundle.load(key);
    if (data.lengthInBytes == 0 || data.lengthInBytes > maxArtworkBytes) {
      return null;
    }
    return CoverArt(
      bytes: data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      mimeType: artworkMimeType(key),
    );
  } catch (_) {
    return null;
  }
}

/// The MIME type of an image named [path], from its extension; `''` for
/// one it does not know.
@internal
String artworkMimeType(String path) {
  final name = path.substring(path.lastIndexOf('/') + 1);
  final dot = name.lastIndexOf('.');
  return switch (dot < 0 ? '' : name.substring(dot + 1).toLowerCase()) {
    'png' => 'image/png',
    'jpg' || 'jpeg' => 'image/jpeg',
    'webp' => 'image/webp',
    'bmp' => 'image/bmp',
    'gif' => 'image/gif',
    _ => '',
  };
}
