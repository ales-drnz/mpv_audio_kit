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

  group('over HTTPS with a self-signed certificate', () {
    final certPath =
        '${Directory.current.path}/test/fixtures/tls/self_signed_cert.pem';
    late HttpServer secure;
    late Uri cover;

    setUpAll(() async {
      final context = SecurityContext()
        ..useCertificateChain(certPath)
        ..usePrivateKey(
          '${Directory.current.path}/test/fixtures/tls/self_signed_key.pem',
        );
      secure = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      cover = Uri.parse('https://localhost:${secure.port}/cover');
      secure.listen((request) {
        request.response
          ..headers.contentType = ContentType('image', 'png')
          ..add(const [9, 8, 7])
          ..close();
      });
    });

    tearDownAll(() => secure.close(force: true));

    test('is refused against the system roots alone', () async {
      expect(await downloadArtwork(cover), isNull);
    });

    test(
      "loads when the player's CA bundle trusts it",
      () async {
        final art = await downloadArtwork(cover, certPath);
        expect(art?.bytes, [9, 8, 7]);
      },
      // On Apple the plugin fetches the image natively, so this download
      // never runs there, and the system TLS check refuses this test
      // certificate (20 years, no serverAuth usage) whatever the roots.
      skip: Platform.isMacOS
          ? 'the download path is not used on Apple platforms'
          : false,
    );

    test('is refused when the CA bundle cannot be read', () async {
      expect(await downloadArtwork(cover, '/nonexistent/ca.pem'), isNull);
    });
  });
}
