// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Unit tests for the check the effects chain passes before it reaches mpv
// (`validateAudioEffects`): a value a lavfi filter accepts and then reads
// or writes out of its buffers with is refused with an ArgumentError.
// Values are counted the way the filter counts them: av_strtok skips
// empty items, and an item sscanf cannot read is dropped. Every corner,
// default and curated preset of the generated manifest, and what the
// typed helpers write, must pass.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/audio_effects_validation.dart';
import 'package:test/test.dart';

import '../generated/_audio_effects_param_corners.dart';

void _refused(AudioEffect e) =>
    expect(() => validateAudioEffects([e]), throwsArgumentError, reason: '$e');

void _accepted(AudioEffect e) =>
    expect(() => validateAudioEffects([e]), returnsNormally, reason: '$e');

void main() {
  group('chorus', () {
    test('lists with different numbers of voices are refused', () {
      // chorus checks the counts with && where it means ||: with delays
      // as long as speeds and depths, it reads decays[1] from a buffer
      // that holds one float.
      _refused(
        const ChorusEffect(
          delays: '40|50',
          decays: '0.4',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        ),
      );
      _refused(
        const ChorusEffect(
          delays: '40|50',
          decays: '0.4|0.3',
          speeds: '0.25',
          depths: '2|1.3',
        ),
      );
      _refused(
        const ChorusEffect(
          delays: '40',
          decays: '0.4',
          speeds: '0.25',
          depths: '2|1.3',
        ),
      );
    });

    test('voices are counted the way chorus counts them', () {
      // Empty items are skipped, and so is an item with no number.
      _accepted(
        const ChorusEffect(
          delays: '40||50',
          decays: '0.4|0.3|',
          speeds: '|0.25|0.4',
          depths: ' 2 | 1.3 ',
        ),
      );
      _accepted(
        const ChorusEffect(
          delays: '40|x|50',
          decays: '0.4|0.3',
          speeds: '0.25|0.4',
          depths: '2|1.3ms',
        ),
      );
      _refused(
        const ChorusEffect(
          delays: '40|50',
          decays: '0.4|x',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        ),
      );
    });

    test('a disabled stage is not checked', () {
      _accepted(
        const ChorusEffect(
          enabled: false,
          delays: '40|50',
          decays: '0.4',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        ),
      );
    });

    test('the error names the stage and the list', () {
      expect(
        () => validateAudioEffects(const [
          EqualizerEffect(),
          ChorusEffect(
            delays: '40|50',
            decays: '0.4',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          ),
        ]),
        throwsA(
          isA<ArgumentError>()
              .having((e) => e.name, 'name', 'effects[1].decays')
              .having((e) => e.invalidValue, 'invalidValue', '0.4'),
        ),
      );
    });
  });

  group('the effects manifest', () {
    test('every corner passes', () {
      for (final c in kFilterParamCorners) {
        expect(
          () => validateAudioEffects(c.bundle),
          returnsNormally,
          reason: '${c.filter} ${c.label}',
        );
      }
    });

    test('every filter at its defaults and every curated preset passes', () {
      for (final s in kFilterSamples) {
        expect(
          () => validateAudioEffects(s.bundle),
          returnsNormally,
          reason: '${s.filter} ${s.label}',
        );
      }
    });

    test('what the typed helpers write passes', () {
      validateAudioEffects([
        const AechoEffect().withTaps(const [
          AechoTap(delayMs: 60, decay: 0.4),
          AechoTap(delayMs: 120, decay: 0.2),
        ]),
        const ChorusEffect(
          delays: '',
          decays: '',
          speeds: '',
          depths: '',
        ).withVoices(const [
          ChorusVoice(delayMs: 40, decay: 0.4, depthMs: 2, speedHz: 0.25),
          ChorusVoice(delayMs: 55, decay: 0.3, depthMs: 1.3, speedHz: 0.4),
        ]),
        const CompandEffect()
            .withEnvelopes(const [
              CompandEnvelope(attackSeconds: 0.01, decaySeconds: 0.3),
            ])
            .withTransferPoints(const [
              CompandPoint(inDb: -80, outDb: -80),
              CompandPoint(inDb: -20, outDb: -12),
              CompandPoint(inDb: 0, outDb: -6),
            ]),
        const McompandEffect().withBands(const [
          McompandBand(
            thresholdDb: -30,
            ratio: 3,
            attackSeconds: 0.005,
            releaseSeconds: 0.1,
            kneeDb: 6,
            makeupDb: 2,
            crossoverHz: 200,
          ),
          McompandBand(
            thresholdDb: -24,
            ratio: 2,
            attackSeconds: 0.0005,
            releaseSeconds: 0.0004,
            kneeDb: 6,
            makeupDb: 0,
            crossoverHz: 20000,
          ),
        ]),
        const AnequalizerEffect().withBands(const [
          AnequalizerBand(frequency: 1000, bandwidth: 500, gain: 6),
        ], channels: 6),
        const PanEffect(args: 'stereo|FL<FL+0.5*FC+0.6*BL|FR<FR+0.5*FC+BR'),
      ]);
    });
  });
}
