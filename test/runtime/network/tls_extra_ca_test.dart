// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// setTlsExtraCaFile against a LOCAL HTTPS server with a committed
// self-signed certificate (test/fixtures/tls, SAN localhost and
// 127.0.0.1): with verification on, the server is refused until its
// certificate is trusted on top of the roots, plays then, and is refused
// again once the file is cleared. Needs libmpv-r27 (FFmpeg's ca_extra_file,
// patch_ffmpeg_tls_extra_ca.py of libmpv-scripts).

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();
  final certPath =
      '${Directory.current.path}/test/fixtures/tls/self_signed_cert.pem';
  HttpServer? server;
  late String url;
  var requests = 0;

  runtimeSuite(fixturePath: fixturePath, () {
    setUpAll(() async {
      final dir = '${Directory.current.path}/test/fixtures/tls';
      final ctx = SecurityContext()
        ..useCertificateChain('$dir/self_signed_cert.pem')
        ..usePrivateKey('$dir/self_signed_key.pem');
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        ctx,
      );
      final body = File(fixturePath).readAsBytesSync();
      server!.listen((req) {
        requests++;
        req.response
          ..headers.contentType = ContentType('audio', 'wav')
          ..contentLength = body.length
          ..add(body);
        unawaited(req.response.close());
      });
      url = 'https://127.0.0.1:${server!.port}/a.wav';
    });

    tearDownAll(() => server?.close(force: true));

    /// Opens [url] and returns whether the file loaded (a FILE_LOADED with
    /// a duration) before the entry ended.
    Future<bool> loads(Player player) async {
      final loaded = Completer<bool>();
      final subs = [
        player.stream.duration.listen((d) {
          if (d > Duration.zero && !loaded.isCompleted) loaded.complete(true);
        }),
        player.stream.endFile.listen((_) {
          if (!loaded.isCompleted) loaded.complete(false);
        }),
      ];
      try {
        await player.open(Media(url), play: false);
        return await loaded.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () => false,
        );
      } finally {
        for (final s in subs) {
          await s.cancel();
        }
        await player.stop();
      }
    }

    test('the server plays once its certificate is trusted, and the public '
        'roots stay', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      expect(player.state.settings.tlsVerify, isTrue);

      var before = requests;
      expect(await loads(player), isFalse, reason: 'refused by default');
      expect(requests, before, reason: 'no request past the handshake');

      await player.setTlsExtraCaFile(certPath);
      expect(player.state.settings.tlsExtraCaFile, certPath);
      final lavf = await player.getRawProperty('stream-lavf-o');
      expect(lavf, contains('ca_extra_file=$certPath'));
      expect(lavf, contains('reconnect'), reason: 'the defaults stay');
      expect(
        await player.getRawProperty('tls-ca-file'),
        isEmpty,
        reason: 'the built-in roots are not replaced',
      );
      before = requests;
      expect(await loads(player), isTrue, reason: 'trusted on top');
      expect(requests, greaterThan(before));

      await player.setTlsExtraCaFile('');
      expect(player.state.settings.tlsExtraCaFile, isEmpty);
      expect(
        await player.getRawProperty('stream-lavf-o'),
        isNot(contains('ca_extra_file')),
      );
      before = requests;
      expect(await loads(player), isFalse, reason: 'refused again');
      expect(requests, before);
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a path the option list cannot hold throws ArgumentError', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      for (final bad in ['/a,b.pem', '/a\nb.pem', '/a\rb.pem', '/a\x00b.pem']) {
        await expectLater(
          player.setTlsExtraCaFile(bad),
          throwsArgumentError,
          reason: bad,
        );
      }
      expect(player.state.settings.tlsExtraCaFile, isEmpty);
    });
  });
}
