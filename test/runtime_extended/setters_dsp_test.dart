// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('DSP / filter / mode setters end-to-end', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test(
        'superequalizer round-trip — band gains preserved via params map',
        () async {
          const bands = {'1b': 1.5, '5b': 0.8, '10b': 1.2, '18b': 0.5};
          await putEffect(player, const SuperequalizerEffect(params: bands));
          expect(effectOf<SuperequalizerEffect>(player).enabled, isTrue);
          expect(effectOf<SuperequalizerEffect>(player).params, bands);

          // Disabling keeps the stage, and its band map, in the list.
          await putEffect(
            player,
            effectOf<SuperequalizerEffect>(player).copyWith(enabled: false),
          );
          expect(effectOf<SuperequalizerEffect>(player).enabled, isFalse);
          expect(effectOf<SuperequalizerEffect>(player).params, bands);
        },
        timeout: const Timeout(Duration(seconds: 5)),
      );

      test('acompressor / loudnorm / rubberband round-trip', () async {
        await putEffect(
          player,
          const AcompressorEffect(threshold: 0.1, ratio: 6),
        );
        expect(effectOf<AcompressorEffect>(player).enabled, isTrue);
        expect(effectOf<AcompressorEffect>(player).threshold, 0.1);
        expect(effectOf<AcompressorEffect>(player).ratio, 6);

        await putEffect(player, const LoudnormEffect(i: -23));
        expect(effectOf<LoudnormEffect>(player).i, -23);

        await putEffect(player, const RubberbandEffect(pitch: 1.5, tempo: 0.8));
        expect(effectOf<RubberbandEffect>(player).pitch, 1.5);
        expect(effectOf<RubberbandEffect>(player).tempo, 0.8);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test(
        'bass + treble round-trip — separate biquad shelves preserved',
        () async {
          await putEffect(player, const BassEffect(g: 4.5, f: 120.0));
          await putEffect(player, const TrebleEffect(g: -2.0, f: 5500.0));
          expect(effectOf<BassEffect>(player).g, 4.5);
          expect(effectOf<BassEffect>(player).f, 120.0);
          expect(effectOf<TrebleEffect>(player).g, -2.0);
          expect(effectOf<TrebleEffect>(player).f, 5500.0);

          // Disabling preserves the parameters.
          await putEffect(
            player,
            effectOf<BassEffect>(player).copyWith(enabled: false),
          );
          expect(effectOf<BassEffect>(player).enabled, isFalse);
          expect(effectOf<BassEffect>(player).g, 4.5);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test(
        'stereotools round-trip — slev (width) + balanceIn preserved',
        () async {
          await putEffect(
            player,
            const StereotoolsEffect(slev: 1.5, balanceIn: -0.3),
          );
          expect(effectOf<StereotoolsEffect>(player).slev, 1.5);
          expect(effectOf<StereotoolsEffect>(player).balanceIn, -0.3);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test('crossfeed round-trip — typed strength + range preserved', () async {
        await putEffect(
          player,
          const CrossfeedEffect(strength: 0.4, range: 0.6),
        );
        expect(effectOf<CrossfeedEffect>(player).strength, 0.4);
        expect(effectOf<CrossfeedEffect>(player).range, 0.6);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test(
        'silenceremove round-trip — start/stop period flags preserved',
        () async {
          await putEffect(
            player,
            const SilenceremoveEffect(
              startPeriods: 1,
              stopPeriods: 1,
              // ffmpeg's silenceremove uses linear-ratio thresholds (not
              // dB) with min=0; 0.001 ≈ -60 dB.
              startThreshold: 0.001,
              stopThreshold: 0.001,
              startDuration: Duration(milliseconds: 500),
              stopDuration: Duration(milliseconds: 500),
            ),
          );
          final s = effectOf<SilenceremoveEffect>(player);
          expect(s.enabled, isTrue);
          expect(s.startPeriods, 1);
          expect(s.stopPeriods, 1);
          expect(s.startThreshold, 0.001);
          expect(s.startDuration, const Duration(milliseconds: 500));

          // Switch to start-only — stopPeriods=0 disables the trailing trim.
          await putEffect(player, s.copyWith(stopPeriods: 0));
          expect(effectOf<SilenceremoveEffect>(player).startPeriods, 1);
          expect(effectOf<SilenceremoveEffect>(player).stopPeriods, 0);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test('setAudioEffects atomic — multiple effects in one write', () async {
        const chain = [
          AcompressorEffect(threshold: 0.1, ratio: 4),
          BassEffect(g: 3),
          TrebleEffect(g: -1),
          StereotoolsEffect(slev: 1.2),
          LoudnormEffect(i: -16),
        ];
        await player.setAudioEffects(chain);
        expect(player.state.audioEffects, chain);
        expect(effectOf<AcompressorEffect>(player).threshold, 0.1);
        expect(effectOf<LoudnormEffect>(player).i, -16);
        // Effects not in the list are not in the chain.
        expect(
          player.state.audioEffects.whereType<SuperequalizerEffect>(),
          isEmpty,
        );

        // Reset the chain.
        await player.setAudioEffects(const []);
        expect(player.state.audioEffects, isEmpty);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test(
        'RawAudioEffect round-trip — raw lavfi entries keep their place',
        () async {
          await player.setAudioEffects(const [
            RawAudioEffect('lavfi-aresample=44100'),
          ]);
          expect(player.state.audioEffects, const [
            RawAudioEffect('lavfi-aresample=44100'),
          ]);

          // Raw and typed stages coexist, in list order.
          await player.setAudioEffects(const [
            RawAudioEffect('lavfi-aresample=48000'),
            AcompressorEffect(threshold: 0.1),
          ]);
          expect(await player.getRawProperty('af'), contains('aresample'));
          expect(effectOf<AcompressorEffect>(player).enabled, isTrue);

          // Clear.
          await player.setAudioEffects(const []);
          expect(player.state.audioEffects, isEmpty);
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test('setRawProperty rejects `af` with ArgumentError', () {
        expect(
          () => player.setRawProperty('af', 'lavfi-volume=2'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('gapless / coverArtAuto enum round-trip', () async {
        await player.setGapless(Gapless.yes);
        expect(player.state.gapless, Gapless.yes);
        await player.setGapless(Gapless.no);
        expect(player.state.gapless, Gapless.no);

        await player.setCoverArtAuto(Cover.exact);
        expect(player.state.coverArtAuto, Cover.exact);
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
