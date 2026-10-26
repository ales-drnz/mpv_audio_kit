// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart on dart:io platforms.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/cover_art.dart';
import 'artwork_fetcher.dart' show ArtworkFetcher, downloadsArtworkOn;
import 'artwork_sources.dart';

/// The plugin's channel, which reads a `content://` cover on Android
/// (FileDescriptorChannel.kt).
const MethodChannel _channel = MethodChannel('mpv_audio_kit');

const Duration _timeout = Duration(seconds: 15);

/// Redirects followed before giving up, as many as [HttpClient] follows.
const int _maxRedirects = 5;

/// Default [ArtworkFetcher] where [downloadsArtworkOn] holds. It always
/// verifies the certificate, whatever the player's `tls-verify`: that
/// option is off by default in mpv, and a cover URL often carries the
/// server's credentials. A [caFile] adds to the system roots, so a
/// self-hosted server with its own CA shows its covers. Redirects are
/// followed by hand, so one from `https` to plain `http` is refused before
/// anything is sent over it. A response that announces more than 20 MB is
/// dropped before its body is read.
///
/// A `file://` URL is read from disk instead, and an `asset://` one from
/// the app's bundle, with the same 20 MB limit and the MIME type of the
/// extension. On Android a `content://` or `android.resource://` URL is
/// read through the ContentResolver, which gives its MIME type.
@internal
Future<CoverArt?> downloadArtwork(Uri uri, [String caFile = '']) async {
  switch (uri.scheme) {
    case 'file':
      return _readArtworkFile(uri);
    case 'asset':
      return readArtworkAsset(uri);
    case 'content' || 'android.resource':
      return defaultTargetPlatform == TargetPlatform.android
          ? _readArtworkContent(uri)
          : null;
    case 'http' || 'https':
      break;
    default:
      return null;
  }
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
        response.contentLength > maxArtworkBytes) {
      return null;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response.timeout(_timeout)) {
      bytes.add(chunk);
      if (bytes.length > maxArtworkBytes) return null;
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
    if (length == 0 || length > maxArtworkBytes) return null;
    final bytes = await file.readAsBytes();
    // The file may have changed since its length was read.
    if (bytes.isEmpty || bytes.length > maxArtworkBytes) return null;
    return CoverArt(bytes: bytes, mimeType: artworkMimeType(uri.path));
  } catch (_) {
    return null;
  }
}

Future<CoverArt?> _readArtworkContent(Uri uri) async {
  try {
    final read = await _channel.invokeMapMethod<String, Object?>(
      'readArtwork',
      {'uri': uri.toString(), 'maxBytes': maxArtworkBytes},
    );
    final bytes = read?['bytes'];
    if (bytes is! Uint8List || bytes.isEmpty) return null;
    if (bytes.length > maxArtworkBytes) return null;
    final type = read?['mimeType'];
    return CoverArt(
      bytes: bytes,
      mimeType: type is String && type.isNotEmpty
          ? type
          : artworkMimeType(uri.path),
    );
  } catch (_) {
    return null;
  }
}
