// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  late Player player;

  runtimeSuite(() {
    setUpAll(() async {
      player = await buildPlayer();
      await openAndWaitForLoad(
        player,
        '${Directory.current.path}/test/fixtures/sine_5s.flac',
      );
    });

    tearDownAll(() => player.dispose());

    test(
      'stream.loudnessMeter emits live EBU R128 measurements from the chain',
      () async {
        // The pipeline polls `af-metadata/aek_ebur128/...`; inject the meter
        // under that label via the raw `custom` slot (the typed `ebur128`
        // route emits the same label through `toAfChain`).
        await player.setAudioEffects(
          const AudioEffects(custom: ['@aek_ebur128:lavfi-ebur128=metadata=1']),
        );
        await player.play();

        // The meter starts at its silence floor (≈ -120.7) until 400 ms of
        // audio has flowed through the freshly-built chain — wait for a real
        // measurement, not just the first emission.
        final first = await player.stream.loudnessMeter
            .firstWhere((l) => (l.momentary ?? -200) > -100)
            .timeout(const Duration(seconds: 10));

        // The sine fixture plays around -22 LUFS momentary; accept a generous
        // window — the assertion is "a plausible live measurement", not a
        // reference-level check.
        expect(first.momentary!, lessThan(0));
        expect(first.momentary!, greaterThan(-70));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'loudness stream stays silent when the meter is not in the chain',
      () async {
        await player.setAudioEffects(const AudioEffects());
        // Drain any tick already in flight from the previous test, then
        // assert silence over an observation window.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final emissions = <Loudness>[];
        final sub = player.stream.loudnessMeter.listen(emissions.add);
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await sub.cancel();
        expect(
          emissions,
          isEmpty,
          reason: 'no ebur128 stage in the chain — the poll must not emit',
        );
      },
      timeout: const Timeout(Duration(seconds: 10)),
    );
  });
}
