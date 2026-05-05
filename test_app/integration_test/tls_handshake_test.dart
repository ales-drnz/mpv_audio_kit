// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Regression guard: verifies that a Player can open an `https://` URL on a
// real device. mbedtls (the TLS backend our binaries link) has no system
// trust store on Android — without the auto-extracted Mozilla CA pem
// shipped with the package, every HTTPS handshake would fail with
// "tls: Certificate verification failed". This test reproduces exactly
// that scenario: open an HTTPS audio stream and assert the loader gets
// far enough that `network` properties are observable, with no TLS error
// surfacing on the log stream.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('TLS handshake (Mozilla CA bundle auto-loaded)', () {
    late Player player;
    final tlsErrors = <String>[];
    StreamSubscription<MpvLogEntry>? logSub;

    setUp(() async {
      tlsErrors.clear();
      player = Player(
        configuration: const PlayerConfiguration(
          autoPlay: false,
          // Surface mpv's own log lines so we can assert no TLS-related
          // error appears during the handshake window.
          logLevel: LogLevel.warn,
        ),
      );
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
      'auto-configured tls-ca-file lets mpv complete an https handshake',
      (_) async {
        // The auto-extracted bundled cacert.pem is a real filesystem path
        // before open() returns — open() awaits Player._tlsBundleReady.
        // After construction, state.tlsCaFile must be a non-empty path that
        // exists on disk.
        // Note: state.tlsCaFile is populated asynchronously inside the
        // constructor's _autoConfigureTlsCaBundle Future. Trigger by
        // opening any URL (which awaits that Future) — using a tiny HTTPS
        // resource keeps the round-trip fast.
        const httpsUrl = 'https://streams.radiomast.io/ref-128k-aaclc-stereo';

        // Race the handshake against a 15s timeout. On success we observe
        // `demuxer-via-network` flipping to true (the demuxer started
        // reading bytes); on failure either the timeout fires or we
        // captured a TLS error in the log stream above.
        final demuxerOk = player.stream.demuxerViaNetwork
            .firstWhere((v) => v == true)
            .timeout(const Duration(seconds: 15),
                onTimeout: () => false);

        await player.open(Media(httpsUrl), play: false);

        // tlsCaFile must be wired up by the time open() returns.
        expect(player.state.tlsCaFile, isNotEmpty,
            reason: 'Auto-extraction of the bundled cacert.pem failed.');

        final ok = await demuxerOk;
        expect(tlsErrors, isEmpty,
            reason: 'mpv reported a TLS error: $tlsErrors');
        expect(ok, isTrue,
            reason: 'Demuxer never came up — TLS handshake likely failed '
                'silently or the stream is unreachable.');
      },
      // Extra slack on the test timeout itself: handshake + first audio
      // packet on a 128 kbps stream typically lands in 2-4 s, but emulators
      // and tunneled networks add latency.
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
