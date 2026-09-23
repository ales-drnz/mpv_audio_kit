// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// On-device regression guard for the native `embed_cacert` patch: the bundled
// libmpv links OpenSSL whose build-time default cert path does not exist on a
// device, so without the Mozilla CA roots compiled into the binary an HTTPS
// handshake with verification ON would fail "certificate verify failed". This
// test enables `tls-verify`, sets NO `tls-ca-file`, opens a real HTTPS audio
// stream, and asserts the demuxer comes up with no TLS error on the log — i.e.
// trust comes solely from the embedded roots. Requires a binary built with the
// embed_cacert patch.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('TLS handshake (embedded Mozilla CA roots)', () {
    late Player player;
    final tlsErrors = <String>[];
    StreamSubscription<MpvLogEntry>? logSub;

    setUp(() async {
      tlsErrors.clear();
      player = Player();
      await player.setRawProperty('ao', 'null');
      logSub = player.stream.log.listen((entry) {
        final lower = entry.text.toLowerCase();
        if (lower.contains('tls') &&
            (lower.contains('verification failed') ||
                lower.contains('certificate'))) {
          tlsErrors.add('[${entry.prefix}] ${entry.text}');
        }
      });
    });

    tearDown(() async {
      await logSub?.cancel();
      await player.stop();
      await player.dispose();
    });

    testWidgets(
      'tls-verify ON + no tls-ca-file completes an https handshake',
      (_) async {
        const httpsUrl = 'https://streams.radiomast.io/ref-128k-aaclc-stereo';

        // Verification ON, no custom CA file: the only possible trust source is
        // the CA bundle compiled into libmpv.
        await player.setTlsVerify(true);
        expect(
          player.state.tlsCaFile,
          isEmpty,
          reason: 'no custom CA file — the embedded roots are the only trust',
        );

        // Race the handshake against a 15s timeout. On success we observe
        // `demuxer-via-network` flipping to true (the demuxer started reading
        // bytes); on failure either the timeout fires or a TLS error was
        // captured on the log stream above.
        final demuxerOk = player.stream.demuxerViaNetwork
            .firstWhere((v) => v == true)
            .timeout(const Duration(seconds: 15), onTimeout: () => false);

        await player.open(const Media(httpsUrl), play: false);

        final ok = await demuxerOk;
        expect(
          tlsErrors,
          isEmpty,
          reason:
              'mpv reported a TLS error (embedded CA roots missing?): '
              '$tlsErrors',
        );
        expect(
          ok,
          isTrue,
          reason:
              'Demuxer never came up — TLS handshake likely failed '
              'silently or the stream is unreachable.',
        );
      },
      // Extra slack on the test timeout itself: handshake + first audio packet
      // on a 128 kbps stream typically lands in 2-4 s, but emulators and
      // tunneled networks add latency.
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
