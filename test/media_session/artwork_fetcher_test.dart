// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// `downloadArtwork` against a loopback HTTP server: the Linux media session
// publishes the downloaded bytes as a private file instead of the URL.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';

void main() {
  late HttpServer server;
  late Uri base;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) {
      final response = request.response;
      if (request.uri.path == '/cover') {
        response.headers.contentType = ContentType('image', 'png');
        response.add(const [1, 2, 3, 4]);
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      response.close();
    });
  });

  tearDownAll(() => server.close(force: true));

  test('returns the bytes and MIME type of a served image', () async {
    final cover = await downloadArtwork(base.resolve('/cover?t=tok'));
    expect(cover, isNotNull);
    expect(cover!.bytes, [1, 2, 3, 4]);
    expect(cover.mimeType, 'image/png');
  });

  test('returns null on an HTTP error', () async {
    expect(await downloadArtwork(base.resolve('/missing')), isNull);
  });

  test('returns null when the host is unreachable', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    expect(await downloadArtwork(Uri.parse('http://127.0.0.1:$port/')), isNull);
  });
}
