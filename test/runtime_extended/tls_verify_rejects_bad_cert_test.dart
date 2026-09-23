// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The TLS-verification negative path. A clean handshake against a valid
// certificate only proves verification did not break a good connection; it
// does not prove verification *rejects* a bad one. Rather than depend on an
// external endpoint (badssl.com — flaky under load / offline), this spins up a
// LOCAL HTTPS server with a committed self-signed certificate, so the check is
// deterministic and network-free.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  HttpServer? server;
  late String badCertUrl;
  var ready = false;

  runtimeSuite(() {
    setUpAll(() async {
      // Local HTTPS server presenting a committed self-signed cert (signed by no
      // trusted root) on the loopback interface — `tls-verify` on must reject it,
      // off must let the handshake through.
      final dir = '${Directory.current.path}/test/fixtures/tls';
      final ctx = SecurityContext()
        ..useCertificateChain('$dir/self_signed_cert.pem')
        ..usePrivateKey('$dir/self_signed_key.pem');
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        ctx,
      );
      server!.listen((req) {
        // Any request: hand back a tiny non-audio body. With tls-verify off the
        // handshake completes and mpv fails at the DEMUXER (not the TLS layer);
        // with it on, the connection never gets this far.
        req.response
          ..statusCode = 200
          ..add(const [0, 0, 0, 0]);
        req.response.close();
      });
      badCertUrl = 'https://127.0.0.1:${server!.port}/x';
      ready = true;
    });

    tearDownAll(() => server?.close(force: true));

    group('TLS verify rejects an invalid certificate (local self-signed)', () {
      late Player player;

      setUpAll(() async {
        if (!ready) return;
        // warn surfaces mpv's certificate-verification error on stream.log
        // (the default buildPlayer config silences logs).
        player = await buildPlayer(configuration: const PlayerConfiguration());
      });

      tearDownAll(() async {
        if (!ready) return;
        await player.stop();
        await player.dispose();
      });

      // Opens the bad-certificate URL, waits for the load to resolve, and returns
      // every log line mentioning a certificate — the fingerprint of a TLS
      // verification failure.
      Future<List<String>> openAndCollectCertErrors() async {
        final certErrors = <String>[];
        final logSub = player.stream.log.listen((e) {
          if (e.text.toLowerCase().contains('certificate')) {
            certErrors.add('[${e.prefix}] ${e.text}');
          }
        });
        final ended = Completer<void>();
        final endSub = player.stream.endFile.listen((_) {
          if (!ended.isCompleted) ended.complete();
        });
        try {
          await player.open(Media(badCertUrl), play: false);
          await ended.future.timeout(
            const Duration(seconds: 15),
            onTimeout: () {},
          );
          // Grace window so a trailing error log line is still captured.
          await Future<void>.delayed(const Duration(milliseconds: 300));
        } finally {
          await logSub.cancel();
          await endSub.cancel();
        }
        return certErrors;
      }

      test('tls-verify on → the self-signed certificate is rejected', () async {
        if (!ready) {
          markTestSkipped('libmpv not found');
          return;
        }
        await player.setTlsVerify(true);
        final certErrors = await openAndCollectCertErrors();
        expect(
          certErrors,
          isNotEmpty,
          reason:
              'with tls-verify on, mpv must reject the self-signed '
              'certificate and log a verification failure',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test(
        'tls-verify off → the handshake is not rejected at the TLS layer',
        () async {
          if (!ready) {
            markTestSkipped('libmpv not found');
            return;
          }
          await player.setTlsVerify(false);
          final certErrors = await openAndCollectCertErrors();
          expect(
            certErrors,
            isEmpty,
            reason:
                'with tls-verify off, the handshake completes — any failure '
                'is at the demuxer, not a certificate rejection: $certErrors',
          );
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });
  });
}
