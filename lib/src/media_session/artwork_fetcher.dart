// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';

import '../models/cover_art.dart';

/// Loads an artwork URL into a [CoverArt], trusting the extra CA bundle
/// `caFile` (the player's `tls-ca-file`, empty for none) on top of the
/// system roots; `null` on any failure.
typedef ArtworkFetcher = Future<CoverArt?> Function(Uri uri, String caFile);

/// Upper bound on a loaded cover. Real covers are a few MB at most;
/// anything larger is not an image worth putting on the media session.
const int _maxArtworkBytes = 20 * 1024 * 1024;

const Duration _timeout = Duration(seconds: 15);

/// Redirects followed before giving up, as many as [HttpClient] follows.
const int _maxRedirects = 5;

/// Whether the media session loads artwork URLs in Dart on [platform]:
/// it downloads an `http(s)://` one and reads a `file://` one, and the
/// native side only ever gets bytes. Remote cover URLs often carry
/// credentials in the query (Subsonic `u`, `t` and `s`, Jellyfin
/// `api_key`, Plex `X-Plex-Token`), and the OS would publish them: MPRIS
/// `mpris:artUrl` on the session bus (Linux), the session metadata other
/// apps with notification access read (Android), the thumbnail source SMTC
/// is given (Windows). Apple's Now Playing takes an image, never a URL.
@internal
bool downloadsArtworkOn(TargetPlatform platform) => switch (platform) {
  TargetPlatform.linux ||
  TargetPlatform.android ||
  TargetPlatform.windows ||
  TargetPlatform.iOS ||
  TargetPlatform.macOS => true,
  _ => false,
};

/// Default [ArtworkFetcher] where [downloadsArtworkOn] holds. It always
/// verifies the certificate, whatever the player's `tls-verify`: that
/// option is off by default in mpv, and a cover URL often carries the
/// server's credentials. A [caFile] adds to the system roots, so a
/// self-hosted server with its own CA shows its covers. Redirects are
/// followed by hand, so one from `https` to plain `http` is refused before
/// anything is sent over it. A response that announces more than 20 MB is
/// dropped before its body is read.
///
/// A `file://` URL is read from disk instead, with the same 20 MB limit,
/// and its MIME type comes from the extension.
@internal
Future<CoverArt?> downloadArtwork(Uri uri, [String caFile = '']) async {
  if (uri.scheme == 'file') return _readArtworkFile(uri);
  HttpClient? client;
  try {
    client = caFile.isEmpty
        ? HttpClient()
        : HttpClient(
            context: SecurityContext(withTrustedRoots: true)
              ..setTrustedCertificates(caFile),
          );
    client.connectionTimeout = _timeout;
    var target = uri;
    var response = await _get(client, target);
    for (var hops = 0; response.isRedirect; hops++) {
      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null || hops == _maxRedirects) return null;
      final next = target.resolve(location);
      if (target.scheme == 'https' && next.scheme != 'https') return null;
      target = next;
      response = await _get(client, target);
    }
    // Not drained: the forced close below drops the connection.
    if (response.statusCode != HttpStatus.ok ||
        response.contentLength > _maxArtworkBytes) {
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
    client?.close(force: true);
  }
}

Future<HttpClientResponse> _get(HttpClient client, Uri uri) async {
  final request = await client.getUrl(uri).timeout(_timeout);
  request.followRedirects = false;
  return request.close().timeout(_timeout);
}

Future<CoverArt?> _readArtworkFile(Uri uri) async {
  try {
    final file = File.fromUri(uri);
    final length = await file.length();
    if (length == 0 || length > _maxArtworkBytes) return null;
    final bytes = await file.readAsBytes();
    // The file may have changed since its length was read.
    if (bytes.isEmpty || bytes.length > _maxArtworkBytes) return null;
    return CoverArt(bytes: bytes, mimeType: _mimeTypeOf(uri.path));
  } catch (_) {
    return null;
  }
}

String _mimeTypeOf(String path) {
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
