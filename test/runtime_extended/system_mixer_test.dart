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
      test(
        'setSystemVolume round-trips on a backend that exposes it',
        () async {
          // Open a REAL (silent) audio output so `ao-volume` becomes available:
          // `audio-stream-silence` keeps the device open streaming silence, and
          // play:false means no content is heard. Where the host has no device,
          // `audio-fallback-to-null` lands on the null AO and the test skips
          // (on the Linux CI job, which runs a PulseAudio null sink, it fails).
          final player = Player(
            configuration: const PlayerConfiguration(logLevel: LogLevel.off),
          );
          addTearDown(player.dispose);
          await player.setAudioStreamSilence(true);
          // A load that never completes is a failure, not a missing device.
          await openAndWaitForLoad(player, fx);
          // The AO opens after the load; give it a bounded moment to
          // expose its volume before deciding the host has none.
          final aoReady = DateTime.now().add(const Duration(seconds: 3));
          while (await player.getRawProperty('ao-volume') == null &&
              DateTime.now().isBefore(aoReady)) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
          }

          if (await player.getRawProperty('ao-volume') == null) {
            skipWithoutAudioDevice(
              'AO does not expose system volume on this host '
              '(${await player.getRawProperty('current-ao')})',
            );
            return;
          }

          // Read back from the output: the state takes the value as soon as
          // mpv accepts the write.
          Future<double?> aoVolume() async =>
              double.tryParse(await player.getRawProperty('ao-volume') ?? '');
          await player.setSystemVolume(50.0);
          await waitUntil(
            () async => ((await aoVolume() ?? -1) - 50.0).abs() <= 0.5,
            reason: 'ao-volume round-trips through the real audio output',
          );
          expect(player.state.systemVolume, closeTo(50.0, 0.5));
          await player.setSystemVolume(100.0);
          await waitUntil(
            () async => ((await aoVolume() ?? -1) - 100.0).abs() <= 0.5,
            reason: 'ao-volume goes back to 100',
          );

          // coreaudio has no per-app mute; PulseAudio and PipeWire do.
          if (await player.getRawProperty('ao-mute') != null) {
            await player.setSystemMute(true);
            await waitUntil(
              () async => await player.getRawProperty('ao-mute') == 'yes',
              reason: 'ao-mute round-trips through the real audio output',
            );
            expect(player.state.systemMute, isTrue);
            await player.setSystemMute(false);
            await waitUntil(
              () async => await player.getRawProperty('ao-mute') == 'no',
              reason: 'ao-mute goes back to no',
            );
          }
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

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
