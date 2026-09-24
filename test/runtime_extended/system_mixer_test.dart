// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = defaultFixturePath();
  runtimeSuite(fixturePath: fx, () {
    group('system mixer (ao-volume / ao-mute)', () {
      test('setSystemVolume round-trips on a backend that exposes it', () async {
        // Open a REAL (silent) audio output so `ao-volume` becomes available —
        // `audio-stream-silence` keeps the device open streaming silence, and
        // play:false means no content is heard. Where the host has no such
        // backend (headless CI), `audio-fallback-to-null` lands on the null AO
        // and the test skips.
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );
        addTearDown(player.dispose);
        await player.setAudioStreamSilence(true);
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 8),
        );
        await player.open(Media(fx), play: false);
        try {
          await loaded;
        } catch (_) {}
        // The AO opens after the load; give it a bounded moment to
        // expose its volume before deciding the host has none.
        final aoReady = DateTime.now().add(const Duration(seconds: 3));
        while (await player.getRawProperty('ao-volume') == null &&
            DateTime.now().isBefore(aoReady)) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }

        if (await player.getRawProperty('ao-volume') == null) {
          markTestSkipped('AO does not expose system volume on this host');
          return;
        }

        await player.setSystemVolume(50.0);
        await waitUntil(
          () => ((player.state.systemVolume ?? -1) - 50.0).abs() <= 0.5,
        );
        expect(
          player.state.systemVolume,
          closeTo(50.0, 0.5),
          reason: 'ao-volume round-trips through the real audio output',
        );
        await player.setSystemVolume(100.0);
      }, timeout: const Timeout(Duration(seconds: 20)));

      test(
        'setSystemVolume / setSystemMute are best-effort (no throw on null AO)',
        () async {
          // With the null AO, system volume/mute are unavailable. The setters must
          // NOT throw, and state stays null (the contract for an unsupported AO).
          final player = await buildPlayer(); // ao=null
          addTearDown(player.dispose);
          await player.setSystemVolume(42.0);
          await player.setSystemMute(true);
          expect(player.state.systemVolume, isNull);
          expect(player.state.systemMute, isNull);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );
    });
  });
}
