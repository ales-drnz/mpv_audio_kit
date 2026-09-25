// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// A setter stores the value it writes, so mpv's echo of it doesn't emit
/// a second, rounded value: `volume` is a C float in mpv and used to come
/// back as 42.400001525878906 after `setVolume(42.37)`.
void main() {
  final fx = defaultFixturePath();

  runtimeSuite(fixturePath: fx, () {
    group('Setter echo', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fx);
      });

      tearDownAll(() => player.dispose());

      Future<void> expectSingleEmission<T>(
        Stream<T> stream,
        Future<void> Function() set,
        T expected,
      ) async {
        final seen = <T>[];
        final sub = stream.skip(1).listen(seen.add);
        await set();
        // A window, not a wait: mpv's echo would land in it.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sub.cancel();
        expect(seen, [expected]);
      }

      test('volume, a float option', () async {
        await expectSingleEmission(
          player.stream.volume,
          () => player.setVolume(42.37),
          42.37,
        );
        expect(player.state.volume, 42.37);
      });

      test('volume gain, a float option', () async {
        await expectSingleEmission(
          player.stream.volumeGain,
          () => player.setVolumeGain(-3.456),
          -3.456,
        );
      });

      test('volume max, a float option', () async {
        await expectSingleEmission(
          player.stream.volumeMax,
          () => player.setVolumeMax(150.25),
          150.25,
        );
      });

      test('rate and pitch, double options', () async {
        await expectSingleEmission(
          player.stream.rate,
          () => player.setRate(1.2345678),
          1.2345678,
        );
        await expectSingleEmission(
          player.stream.pitch,
          () => player.setPitch(0.987654),
          0.987654,
        );
      });

      test('audio delay keeps microseconds', () async {
        await expectSingleEmission(
          player.stream.audioDelay,
          () => player.setAudioDelay(const Duration(microseconds: 123456)),
          const Duration(microseconds: 123456),
        );
      });

      test('replay gain preamp and fallback', () async {
        const settings = ReplayGainSettings(preamp: 2.35, fallback: -6.15);
        await expectSingleEmission(
          player.stream.replayGain.map((r) => (r.preamp, r.fallback)),
          () => player.setReplayGain(settings),
          (2.35, -6.15),
        );
      });
    });
  });
}
