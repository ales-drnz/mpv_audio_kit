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

    ChorusEffect voice({
      String delays = '40',
      String decays = '0.4',
      String speeds = '0.25',
      String depths = '2',
    }) => ChorusEffect(
      delays: delays,
      decays: decays,
      speeds: speeds,
      depths: depths,
    );

    test('values out of the range chorus can run are refused', () {
      // A negative or NaN depth, or a speed of 0 or above the sample rate,
      // puts the modulation index outside the delay line.
      _refused(voice(depths: '-2'));
      _refused(voice(depths: 'nan'));
      _refused(voice(delays: '-40'));
      _refused(voice(speeds: '0'));
      _refused(voice(speeds: '50000'));
      _refused(voice(speeds: 'inf'));
      _refused(voice(decays: 'NaN'));
      _refused(voice(delays: '1e39'));
      _refused(
        const ChorusEffect(
          delays: '',
          decays: '',
          speeds: '',
          depths: '',
        ).withVoices(const [
          ChorusVoice(delayMs: 40, decay: 0.4, depthMs: 0 / 0, speedHz: 0.25),
        ]),
      );
    });

    test('the edges of that range pass', () {
      _accepted(voice(delays: '0', depths: '0'));
      _accepted(voice(speeds: '100'));
      _accepted(voice(speeds: '0.001'));
    });
  });

  group('aecho', () {
    AechoEffect taps(String delays, String decays) =>
        AechoEffect(delays: delays, decays: decays);

    test('NaN and values out of range are refused', () {
      // aecho checks `delay <= 0 || delay > 90000`, false for NaN, then
      // indexes its buffer with (int)NaN.
      _refused(
        const AechoEffect().withTaps(const [
          AechoTap(delayMs: 500, decay: 0.5),
          AechoTap(delayMs: double.nan, decay: 0.5),
        ]),
      );
      _refused(taps('1000|nan', '0.5|0.5'));
      _refused(taps('1000', 'nan'));
      _refused(taps('inf', '0.5'));
      _refused(taps('0', '0.5'));
      _refused(taps('90001', '0.5'));
      _refused(taps('1000', '1.5'));
      _refused(taps('1000', '0'));
    });

    test('the edges of the range pass, read as floats like aecho', () {
      _accepted(taps('90000', '1'));
      // 90000.001 is 90000 as a float.
      _accepted(taps('90000.001', '1.00000001'));
      _accepted(taps('0.001', '0.001'));
    });
  });

  group('anequalizer', () {
    test('a band with a NaN or infinite value is refused', () {
      // anequalizer checks `freq < 0 || freq > rate / 2`, false for NaN,
      // and does not check width and gain: the band's coefficients turn
      // to NaN.
      _refused(const AnequalizerEffect(params: 'c0 f=nan w=100 g=6 t=0'));
      _refused(const AnequalizerEffect(params: 'c0 f=1000 w=inf g=6'));
      _refused(
        const AnequalizerEffect(
          params: 'c0 f=1000 w=100 g=6|c1 f=1000 w=100 g=-nan',
        ),
      );
      _refused(
        const AnequalizerEffect().withBands(const [
          AnequalizerBand(frequency: 1000, bandwidth: 100, gain: double.nan),
        ]),
      );
    });

    test('finite bands pass, whatever their range', () {
      _accepted(
        const AnequalizerEffect(
          params: 'c0 f=1000 w=100 g=-6 t=1|c1 f=30000 w=100 g=6',
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
