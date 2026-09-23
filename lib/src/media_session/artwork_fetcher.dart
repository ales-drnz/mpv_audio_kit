// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';

/// Downloads a remote artwork URL into a [CoverArt]; `null` on any failure.
typedef ArtworkFetcher = Future<CoverArt?> Function(Uri uri);

/// Upper bound on a downloaded cover. Real covers are a few MB at most;
/// anything larger is not an image worth putting on the media session.
const int _maxArtworkBytes = 20 * 1024 * 1024;

const Duration _timeout = Duration(seconds: 15);

/// Default [ArtworkFetcher] for Linux. MPRIS publishes `mpris:artUrl` on the
/// session bus, where any process can read it, and remote cover URLs often
/// carry credentials in the query (Subsonic `u`, `t` and `s`, Jellyfin
/// `api_key`, Plex `X-Plex-Token`). Fetching the image here lets the native
/// side write it to a private temp file and publish a `file://` URI instead.
@internal
Future<CoverArt?> downloadArtwork(Uri uri) async {
  final client = HttpClient()..connectionTimeout = _timeout;
  try {
    final request = await client.getUrl(uri).timeout(_timeout);
    final response = await request.close().timeout(_timeout);
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(_timeout)) {
      bytes.add(chunk);
      if (bytes.length > _maxArtworkBytes) return null;
    }
    if (bytes.isEmpty) return null;
    return CoverArt(
      bytes: bytes.takeBytes(),
      mimeType: response.headers.contentType?.mimeType ?? '',
    );
  } catch (_) {
    return null;
  } finally {
    client.close(force: true);
  }
}
