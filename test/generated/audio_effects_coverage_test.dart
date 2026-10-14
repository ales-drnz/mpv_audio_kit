// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do NOT edit by hand.
//
// Schema-driven coverage of the effects chain (`audioEffectsChain`) and the
// per-filter `toFilterString()` wire output: every parameter of
// every libavfilter audio filter shipped with this build has at
// least one test pinning the wire shape, and every typed enum
// has its `mpvValue` and `fromMpv` round-trip checked exhaustively.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, unnecessary_const, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/generated/audio_effects_settings.dart'
    show audioEffectsChain;

void main() {
  group('Per-filter wire coverage', () {
    group('AcompressorEffect (acompressor)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AcompressorEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AcompressorEffect()];
        expect(audioEffectsChain(fx), '@aek_acompressor_0:lavfi-acompressor');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, attack: 2000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorEffect(
            enabled: true,
            detection: AcompressorDetection.peak,
          );
          expect(s.toFilterString(), contains('detection='));
          expect(s.toFilterString(), contains('detection=peak'));
        },
      );

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_sc` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorEffect(enabled: true, levelSc: 64.0);
          expect(s.toFilterString(), contains('level_sc='));
          expect(s.toFilterString(), contains('level_sc=64.000'));
        },
      );

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(
          enabled: true,
          link: AcompressorLink.maximum,
        );
        expect(s.toFilterString(), contains('link='));
        expect(s.toFilterString(), contains('link=maximum'));
      });

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, makeup: 64.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=64.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(
          enabled: true,
          mode: AcompressorMode.upward,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=upward'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, ratio: 20.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=20.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AcompressorEffect(enabled: true, release: 9000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=9000.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorEffect(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            attack: AcompressorEffect.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            attack: AcompressorEffect.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            attack: AcompressorEffect.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `knee` const `kneeMin` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          knee: AcompressorEffect.kneeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `knee` const `kneeMax` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          knee: AcompressorEffect.kneeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `knee` const `kneeDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            knee: AcompressorEffect.kneeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelIn: AcompressorEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelIn: AcompressorEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelIn: AcompressorEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelSc: AcompressorEffect.levelScMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelSc: AcompressorEffect.levelScMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            levelSc: AcompressorEffect.levelScDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            makeup: AcompressorEffect.makeupMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            makeup: AcompressorEffect.makeupMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            makeup: AcompressorEffect.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          mix: AcompressorEffect.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          mix: AcompressorEffect.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          mix: AcompressorEffect.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          ratio: AcompressorEffect.ratioMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AcompressorEffect(
          enabled: true,
          ratio: AcompressorEffect.ratioMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            ratio: AcompressorEffect.ratioDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            release: AcompressorEffect.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            release: AcompressorEffect.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            release: AcompressorEffect.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            threshold: AcompressorEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            threshold: AcompressorEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AcompressorEffect(
            enabled: true,
            threshold: AcompressorEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AcontrastEffect (acontrast)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AcontrastEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AcontrastEffect()];
        expect(audioEffectsChain(fx), '@aek_acontrast_0:lavfi-acontrast');
      });

      test(
        'param `contrast` lands in wire when set to a non-default value',
        () {
          final s = const AcontrastEffect(enabled: true, contrast: 100.0);
          expect(s.toFilterString(), contains('contrast='));
          expect(s.toFilterString(), contains('contrast=100.000'));
        },
      );

      test(
        'param `contrast` const `contrastMin` is accepted by toFilterString',
        () {
          final s = AcontrastEffect(
            enabled: true,
            contrast: AcontrastEffect.contrastMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `contrast` const `contrastMax` is accepted by toFilterString',
        () {
          final s = AcontrastEffect(
            enabled: true,
            contrast: AcontrastEffect.contrastMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `contrast` const `contrastDefault` is accepted by toFilterString',
        () {
          final s = AcontrastEffect(
            enabled: true,
            contrast: AcontrastEffect.contrastDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AcrusherEffect (acrusher)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AcrusherEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AcrusherEffect()];
        expect(audioEffectsChain(fx), '@aek_acrusher_0:lavfi-acrusher');
      });

      test('param `aa` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, aa: 1.0);
        expect(s.toFilterString(), contains('aa='));
        expect(s.toFilterString(), contains('aa=1.000'));
      });

      test('param `bits` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, bits: 64.0);
        expect(s.toFilterString(), contains('bits='));
        expect(s.toFilterString(), contains('bits=64.000'));
      });

      test('param `dc` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, dc: 4.0);
        expect(s.toFilterString(), contains('dc='));
        expect(s.toFilterString(), contains('dc=4.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `lfo` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, lfo: true);
        expect(s.toFilterString(), contains('lfo='));
      });

      test(
        'param `lforange` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherEffect(enabled: true, lforange: 250.0);
          expect(s.toFilterString(), contains('lforange='));
          expect(s.toFilterString(), contains('lforange=250.000'));
        },
      );

      test('param `lforate` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, lforate: 200.0);
        expect(s.toFilterString(), contains('lforate='));
        expect(s.toFilterString(), contains('lforate=200.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, mix: 1.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=1.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, mode: AcrusherMode.log);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=log'));
      });

      test('param `samples` lands in wire when set to a non-default value', () {
        final s = const AcrusherEffect(enabled: true, samples: 250.0);
        expect(s.toFilterString(), contains('samples='));
        expect(s.toFilterString(), contains('samples=250.000'));
      });

      test('param `aa` const `aaMin` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, aa: AcrusherEffect.aaMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `aa` const `aaMax` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, aa: AcrusherEffect.aaMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `aa` const `aaDefault` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, aa: AcrusherEffect.aaDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bits` const `bitsMin` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, bits: AcrusherEffect.bitsMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bits` const `bitsMax` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, bits: AcrusherEffect.bitsMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bits` const `bitsDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            bits: AcrusherEffect.bitsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dc` const `dcMin` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, dc: AcrusherEffect.dcMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dc` const `dcMax` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, dc: AcrusherEffect.dcMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dc` const `dcDefault` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, dc: AcrusherEffect.dcDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelIn: AcrusherEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelIn: AcrusherEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelIn: AcrusherEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelOut: AcrusherEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelOut: AcrusherEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            levelOut: AcrusherEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeMin` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforange: AcrusherEffect.lforangeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeMax` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforange: AcrusherEffect.lforangeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforange: AcrusherEffect.lforangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateMin` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforate: AcrusherEffect.lforateMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateMax` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforate: AcrusherEffect.lforateMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            lforate: AcrusherEffect.lforateDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, mix: AcrusherEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, mix: AcrusherEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AcrusherEffect(enabled: true, mix: AcrusherEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `samples` const `samplesMin` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            samples: AcrusherEffect.samplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMax` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            samples: AcrusherEffect.samplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesDefault` is accepted by toFilterString',
        () {
          final s = AcrusherEffect(
            enabled: true,
            samples: AcrusherEffect.samplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdeclickEffect (adeclick)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdeclickEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdeclickEffect()];
        expect(audioEffectsChain(fx), '@aek_adeclick_0:lavfi-adeclick');
      });

      test('param `arorder` lands in wire when set to a non-default value', () {
        final s = const AdeclickEffect(enabled: true, arorder: 25.0);
        expect(s.toFilterString(), contains('arorder='));
        expect(s.toFilterString(), contains('arorder=25.000'));
      });

      test('param `burst` lands in wire when set to a non-default value', () {
        final s = const AdeclickEffect(enabled: true, burst: 10.0);
        expect(s.toFilterString(), contains('burst='));
        expect(s.toFilterString(), contains('burst=10.000'));
      });

      test('param `method` lands in wire when set to a non-default value', () {
        final s = const AdeclickEffect(enabled: true, method: AdeclickM.a);
        expect(s.toFilterString(), contains('method='));
        expect(s.toFilterString(), contains('method=a'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AdeclickEffect(enabled: true, overlap: 95.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=95.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdeclickEffect(enabled: true, threshold: 100.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=100.000'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const AdeclickEffect(enabled: true, window: 100.0);
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=100.000'));
      });

      test(
        'param `arorder` const `arorderMin` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            arorder: AdeclickEffect.arorderMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderMax` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            arorder: AdeclickEffect.arorderMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderDefault` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            arorder: AdeclickEffect.arorderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `burst` const `burstMin` is accepted by toFilterString', () {
        final s = AdeclickEffect(enabled: true, burst: AdeclickEffect.burstMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `burst` const `burstMax` is accepted by toFilterString', () {
        final s = AdeclickEffect(enabled: true, burst: AdeclickEffect.burstMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `burst` const `burstDefault` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            burst: AdeclickEffect.burstDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            overlap: AdeclickEffect.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            overlap: AdeclickEffect.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            overlap: AdeclickEffect.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            threshold: AdeclickEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            threshold: AdeclickEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            threshold: AdeclickEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMin` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            window: AdeclickEffect.windowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMax` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            window: AdeclickEffect.windowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowDefault` is accepted by toFilterString',
        () {
          final s = AdeclickEffect(
            enabled: true,
            window: AdeclickEffect.windowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdeclipEffect (adeclip)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdeclipEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdeclipEffect()];
        expect(audioEffectsChain(fx), '@aek_adeclip_0:lavfi-adeclip');
      });

      test('param `arorder` lands in wire when set to a non-default value', () {
        final s = const AdeclipEffect(enabled: true, arorder: 25.0);
        expect(s.toFilterString(), contains('arorder='));
        expect(s.toFilterString(), contains('arorder=25.000'));
      });

      test('param `hsize` lands in wire when set to a non-default value', () {
        final s = const AdeclipEffect(enabled: true, hsize: 9999);
        expect(s.toFilterString(), contains('hsize='));
        expect(s.toFilterString(), contains('hsize=9999'));
      });

      test('param `method` lands in wire when set to a non-default value', () {
        final s = const AdeclipEffect(enabled: true, method: AdeclipM.a);
        expect(s.toFilterString(), contains('method='));
        expect(s.toFilterString(), contains('method=a'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AdeclipEffect(enabled: true, overlap: 95.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=95.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdeclipEffect(enabled: true, threshold: 100.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=100.000'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const AdeclipEffect(enabled: true, window: 100.0);
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=100.000'));
      });

      test(
        'param `arorder` const `arorderMin` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            arorder: AdeclipEffect.arorderMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderMax` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            arorder: AdeclipEffect.arorderMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderDefault` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            arorder: AdeclipEffect.arorderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `hsize` const `hsizeMin` is accepted by toFilterString', () {
        final s = AdeclipEffect(enabled: true, hsize: AdeclipEffect.hsizeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hsize` const `hsizeMax` is accepted by toFilterString', () {
        final s = AdeclipEffect(enabled: true, hsize: AdeclipEffect.hsizeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `hsize` const `hsizeDefault` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            hsize: AdeclipEffect.hsizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            overlap: AdeclipEffect.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            overlap: AdeclipEffect.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            overlap: AdeclipEffect.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            threshold: AdeclipEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            threshold: AdeclipEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            threshold: AdeclipEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMin` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            window: AdeclipEffect.windowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMax` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            window: AdeclipEffect.windowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowDefault` is accepted by toFilterString',
        () {
          final s = AdeclipEffect(
            enabled: true,
            window: AdeclipEffect.windowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdecorrelateEffect (adecorrelate)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdecorrelateEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdecorrelateEffect()];
        expect(audioEffectsChain(fx), '@aek_adecorrelate_0:lavfi-adecorrelate');
      });

      test('param `seed` lands in wire when set to a non-default value', () {
        final s = const AdecorrelateEffect(enabled: true, seed: 4294967295);
        expect(s.toFilterString(), contains('seed='));
        expect(s.toFilterString(), contains('seed=4294967295'));
      });

      test('param `stages` lands in wire when set to a non-default value', () {
        final s = const AdecorrelateEffect(enabled: true, stages: 16);
        expect(s.toFilterString(), contains('stages='));
        expect(s.toFilterString(), contains('stages=16'));
      });

      test('param `seed` const `seedMin` is accepted by toFilterString', () {
        final s = AdecorrelateEffect(
          enabled: true,
          seed: AdecorrelateEffect.seedMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `seed` const `seedMax` is accepted by toFilterString', () {
        final s = AdecorrelateEffect(
          enabled: true,
          seed: AdecorrelateEffect.seedMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `seed` const `seedDefault` is accepted by toFilterString',
        () {
          final s = AdecorrelateEffect(
            enabled: true,
            seed: AdecorrelateEffect.seedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesMin` is accepted by toFilterString',
        () {
          final s = AdecorrelateEffect(
            enabled: true,
            stages: AdecorrelateEffect.stagesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesMax` is accepted by toFilterString',
        () {
          final s = AdecorrelateEffect(
            enabled: true,
            stages: AdecorrelateEffect.stagesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesDefault` is accepted by toFilterString',
        () {
          final s = AdecorrelateEffect(
            enabled: true,
            stages: AdecorrelateEffect.stagesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdelayEffect (adelay)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdelayEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdelayEffect()];
        expect(audioEffectsChain(fx), '@aek_adelay_0:lavfi-adelay');
      });

      test('param `all` lands in wire when set to a non-default value', () {
        final s = const AdelayEffect(enabled: true, all: true);
        expect(s.toFilterString(), contains('all='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const AdelayEffect(enabled: true, delays: 'wire_test_alt');
        expect(s.toFilterString(), contains('delays='));
      });
    });
    group('AdenormEffect (adenorm)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdenormEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdenormEffect()];
        expect(audioEffectsChain(fx), '@aek_adenorm_0:lavfi-adenorm');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AdenormEffect(enabled: true, level: -90.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=-90.000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AdenormEffect(enabled: true, type: AdenormType.ac);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=ac'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AdenormEffect(enabled: true, level: AdenormEffect.levelMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AdenormEffect(enabled: true, level: AdenormEffect.levelMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AdenormEffect(
            enabled: true,
            level: AdenormEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AderivativeEffect (aderivative)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AderivativeEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AderivativeEffect()];
        expect(audioEffectsChain(fx), '@aek_aderivative_0:lavfi-aderivative');
      });
    });
    group('AdrcEffect (adrc)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdrcEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdrcEffect()];
        expect(audioEffectsChain(fx), '@aek_adrc_0:lavfi-adrc');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AdrcEffect(enabled: true, attack: 1000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=1000.000'));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AdrcEffect(enabled: true, channels: 'wire_test_alt');
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AdrcEffect(enabled: true, release: 2000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test(
        'param `transfer` lands in wire when set to a non-default value',
        () {
          final s = const AdrcEffect(enabled: true, transfer: 'wire_test_alt');
          expect(s.toFilterString(), contains('transfer='));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AdrcEffect(enabled: true, attack: AdrcEffect.attackMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AdrcEffect(enabled: true, attack: AdrcEffect.attackMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AdrcEffect(enabled: true, attack: AdrcEffect.attackDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AdrcEffect(enabled: true, release: AdrcEffect.releaseMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AdrcEffect(enabled: true, release: AdrcEffect.releaseMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AdrcEffect(
            enabled: true,
            release: AdrcEffect.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdynamicequalizerEffect (adynamicequalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdynamicequalizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdynamicequalizerEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_adynamicequalizer_0:lavfi-adynamicequalizer',
        );
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(enabled: true, attack: 2000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test('param `auto` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(
          enabled: true,
          auto: AdynamicequalizerAuto.disabled,
        );
        expect(s.toFilterString(), contains('auto='));
        expect(s.toFilterString(), contains('auto=disabled'));
      });

      test(
        'param `dfrequency` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            dfrequency: 1000000.0,
          );
          expect(s.toFilterString(), contains('dfrequency='));
          expect(s.toFilterString(), contains('dfrequency=1000000.000'));
        },
      );

      test('param `dftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(
          enabled: true,
          dftype: AdynamicequalizerDftype.lowpass,
        );
        expect(s.toFilterString(), contains('dftype='));
        expect(s.toFilterString(), contains('dftype=lowpass'));
      });

      test(
        'param `dqfactor` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            dqfactor: 1000.0,
          );
          expect(s.toFilterString(), contains('dqfactor='));
          expect(s.toFilterString(), contains('dqfactor=1000.000'));
        },
      );

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(enabled: true, makeup: 1000.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=1000.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(
          enabled: true,
          mode: AdynamicequalizerMode.cutbelow,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=cutbelow'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            precision: AdynamicequalizerPrecision.float,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=float'));
        },
      );

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(enabled: true, range: 2000.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=2000.000'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(enabled: true, ratio: 30.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=30.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(enabled: true, release: 2000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test(
        'param `tfrequency` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            tfrequency: 1000000.0,
          );
          expect(s.toFilterString(), contains('tfrequency='));
          expect(s.toFilterString(), contains('tfrequency=1000000.000'));
        },
      );

      test('param `tftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerEffect(
          enabled: true,
          tftype: AdynamicequalizerTftype.lowshelf,
        );
        expect(s.toFilterString(), contains('tftype='));
        expect(s.toFilterString(), contains('tftype=lowshelf'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            threshold: 100.0,
          );
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=100.000'));
        },
      );

      test(
        'param `tqfactor` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerEffect(
            enabled: true,
            tqfactor: 1000.0,
          );
          expect(s.toFilterString(), contains('tqfactor='));
          expect(s.toFilterString(), contains('tqfactor=1000.000'));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            attack: AdynamicequalizerEffect.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            attack: AdynamicequalizerEffect.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            attack: AdynamicequalizerEffect.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dfrequency: AdynamicequalizerEffect.dfrequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dfrequency: AdynamicequalizerEffect.dfrequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dfrequency: AdynamicequalizerEffect.dfrequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dqfactor: AdynamicequalizerEffect.dqfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dqfactor: AdynamicequalizerEffect.dqfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            dqfactor: AdynamicequalizerEffect.dqfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            makeup: AdynamicequalizerEffect.makeupMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            makeup: AdynamicequalizerEffect.makeupMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            makeup: AdynamicequalizerEffect.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = AdynamicequalizerEffect(
          enabled: true,
          range: AdynamicequalizerEffect.rangeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = AdynamicequalizerEffect(
          enabled: true,
          range: AdynamicequalizerEffect.rangeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            range: AdynamicequalizerEffect.rangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AdynamicequalizerEffect(
          enabled: true,
          ratio: AdynamicequalizerEffect.ratioMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AdynamicequalizerEffect(
          enabled: true,
          ratio: AdynamicequalizerEffect.ratioMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            ratio: AdynamicequalizerEffect.ratioDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            release: AdynamicequalizerEffect.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            release: AdynamicequalizerEffect.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            release: AdynamicequalizerEffect.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tfrequency: AdynamicequalizerEffect.tfrequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tfrequency: AdynamicequalizerEffect.tfrequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tfrequency: AdynamicequalizerEffect.tfrequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            threshold: AdynamicequalizerEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            threshold: AdynamicequalizerEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            threshold: AdynamicequalizerEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tqfactor: AdynamicequalizerEffect.tqfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tqfactor: AdynamicequalizerEffect.tqfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerEffect(
            enabled: true,
            tqfactor: AdynamicequalizerEffect.tqfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdynamicsmoothEffect (adynamicsmooth)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AdynamicsmoothEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AdynamicsmoothEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_adynamicsmooth_0:lavfi-adynamicsmooth',
        );
      });

      test(
        'param `basefreq` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicsmoothEffect(
            enabled: true,
            basefreq: 1000000.0,
          );
          expect(s.toFilterString(), contains('basefreq='));
          expect(s.toFilterString(), contains('basefreq=1000000.000'));
        },
      );

      test(
        'param `sensitivity` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicsmoothEffect(
            enabled: true,
            sensitivity: 1000000.0,
          );
          expect(s.toFilterString(), contains('sensitivity='));
          expect(s.toFilterString(), contains('sensitivity=1000000.000'));
        },
      );

      test(
        'param `basefreq` const `basefreqMin` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            basefreq: AdynamicsmoothEffect.basefreqMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `basefreq` const `basefreqMax` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            basefreq: AdynamicsmoothEffect.basefreqMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `basefreq` const `basefreqDefault` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            basefreq: AdynamicsmoothEffect.basefreqDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityMin` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            sensitivity: AdynamicsmoothEffect.sensitivityMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityMax` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            sensitivity: AdynamicsmoothEffect.sensitivityMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityDefault` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothEffect(
            enabled: true,
            sensitivity: AdynamicsmoothEffect.sensitivityDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AechoEffect (aecho)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AechoEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AechoEffect()];
        expect(audioEffectsChain(fx), '@aek_aecho_0:lavfi-aecho');
      });

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const AechoEffect(enabled: true, decays: 'wire_test_alt');
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const AechoEffect(enabled: true, delays: 'wire_test_alt');
        expect(s.toFilterString(), contains('delays='));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const AechoEffect(enabled: true, inGain: 1.0);
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test(
        'param `out_gain` lands in wire when set to a non-default value',
        () {
          final s = const AechoEffect(enabled: true, outGain: 1.0);
          expect(s.toFilterString(), contains('out_gain='));
          expect(s.toFilterString(), contains('out_gain=1.000'));
        },
      );

      test(
        'param `in_gain` const `inGainMin` is accepted by toFilterString',
        () {
          final s = AechoEffect(enabled: true, inGain: AechoEffect.inGainMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainMax` is accepted by toFilterString',
        () {
          final s = AechoEffect(enabled: true, inGain: AechoEffect.inGainMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainDefault` is accepted by toFilterString',
        () {
          final s = AechoEffect(
            enabled: true,
            inGain: AechoEffect.inGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMin` is accepted by toFilterString',
        () {
          final s = AechoEffect(enabled: true, outGain: AechoEffect.outGainMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMax` is accepted by toFilterString',
        () {
          final s = AechoEffect(enabled: true, outGain: AechoEffect.outGainMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainDefault` is accepted by toFilterString',
        () {
          final s = AechoEffect(
            enabled: true,
            outGain: AechoEffect.outGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AemphasisEffect (aemphasis)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AemphasisEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AemphasisEffect()];
        expect(audioEffectsChain(fx), '@aek_aemphasis_0:lavfi-aemphasis');
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AemphasisEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AemphasisEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AemphasisEffect(
          enabled: true,
          mode: AemphasisMode.production,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=production'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AemphasisEffect(enabled: true, type: AemphasisType.col);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=col'));
      });

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelIn: AemphasisEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelIn: AemphasisEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelIn: AemphasisEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelOut: AemphasisEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelOut: AemphasisEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = AemphasisEffect(
            enabled: true,
            levelOut: AemphasisEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AevalEffect (aeval)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AevalEffect(enabled: false, exprs: 'val(0)|val(1)')];
        expect(audioEffectsChain(fx), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = [AevalEffect(exprs: 'val(0)|val(1)')];
          expect(audioEffectsChain(fx), startsWith('@aek_aeval_0:lavfi-aeval'));
          expect(audioEffectsChain(fx), contains('exprs='));
        },
      );

      test(
        'param `channel_layout` lands in wire when set to a non-default value',
        () {
          final s = const AevalEffect(
            enabled: true,
            channelLayout: 'wire_test_alt',
            exprs: 'val(0)|val(1)',
          );
          expect(s.toFilterString(), contains('channel_layout='));
        },
      );

      test('param `exprs` lands in wire when set to a non-default value', () {
        final s = const AevalEffect(enabled: true, exprs: 'wire_test_alt');
        expect(s.toFilterString(), contains('exprs='));
      });
    });
    group('AexciterEffect (aexciter)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AexciterEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AexciterEffect()];
        expect(audioEffectsChain(fx), '@aek_aexciter_0:lavfi-aexciter');
      });

      test('param `amount` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, amount: 64.0);
        expect(s.toFilterString(), contains('amount='));
        expect(s.toFilterString(), contains('amount=64.000'));
      });

      test('param `blend` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, blend: 10.0);
        expect(s.toFilterString(), contains('blend='));
        expect(s.toFilterString(), contains('blend=10.000'));
      });

      test('param `ceil` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, ceil: 20000.0);
        expect(s.toFilterString(), contains('ceil='));
        expect(s.toFilterString(), contains('ceil=20000.000'));
      });

      test('param `drive` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, drive: 10.0);
        expect(s.toFilterString(), contains('drive='));
        expect(s.toFilterString(), contains('drive=10.000'));
      });

      test('param `freq` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, freq: 12000.0);
        expect(s.toFilterString(), contains('freq='));
        expect(s.toFilterString(), contains('freq=12000.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AexciterEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AexciterEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `listen` lands in wire when set to a non-default value', () {
        final s = const AexciterEffect(enabled: true, listen: true);
        expect(s.toFilterString(), contains('listen='));
      });

      test(
        'param `amount` const `amountMin` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            amount: AexciterEffect.amountMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountMax` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            amount: AexciterEffect.amountMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            amount: AexciterEffect.amountDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `blend` const `blendMin` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, blend: AexciterEffect.blendMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blend` const `blendMax` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, blend: AexciterEffect.blendMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blend` const `blendDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            blend: AexciterEffect.blendDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ceil` const `ceilMin` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, ceil: AexciterEffect.ceilMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ceil` const `ceilMax` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, ceil: AexciterEffect.ceilMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ceil` const `ceilDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            ceil: AexciterEffect.ceilDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `drive` const `driveMin` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, drive: AexciterEffect.driveMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `drive` const `driveMax` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, drive: AexciterEffect.driveMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `drive` const `driveDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            drive: AexciterEffect.driveDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `freq` const `freqMin` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, freq: AexciterEffect.freqMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `freq` const `freqMax` is accepted by toFilterString', () {
        final s = AexciterEffect(enabled: true, freq: AexciterEffect.freqMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `freq` const `freqDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            freq: AexciterEffect.freqDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelIn: AexciterEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelIn: AexciterEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelIn: AexciterEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelOut: AexciterEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelOut: AexciterEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = AexciterEffect(
            enabled: true,
            levelOut: AexciterEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfadeEffect (afade)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AfadeEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AfadeEffect()];
        expect(audioEffectsChain(fx), '@aek_afade_0:lavfi-afade');
      });

      test('param `curve` lands in wire when set to a non-default value', () {
        final s = const AfadeEffect(enabled: true, curve: AfadeCurve.nofade);
        expect(s.toFilterString(), contains('curve='));
        expect(s.toFilterString(), contains('curve=nofade'));
      });

      test(
        'param `duration` lands in wire when set to a non-default value',
        () {
          final s = const AfadeEffect(
            enabled: true,
            duration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('duration='));
        },
      );

      test(
        'param `nb_samples` lands in wire when set to a non-default value',
        () {
          final s = const AfadeEffect(
            enabled: true,
            nbSamples: 9223372036854775807,
          );
          expect(s.toFilterString(), contains('nb_samples='));
          expect(
            s.toFilterString(),
            contains('nb_samples=9223372036854775807'),
          );
        },
      );

      test('param `silence` lands in wire when set to a non-default value', () {
        final s = const AfadeEffect(enabled: true, silence: 1.0);
        expect(s.toFilterString(), contains('silence='));
        expect(s.toFilterString(), contains('silence=1.000'));
      });

      test(
        'param `start_sample` lands in wire when set to a non-default value',
        () {
          final s = const AfadeEffect(
            enabled: true,
            startSample: 9223372036854775807,
          );
          expect(s.toFilterString(), contains('start_sample='));
          expect(
            s.toFilterString(),
            contains('start_sample=9223372036854775807'),
          );
        },
      );

      test(
        'param `start_time` lands in wire when set to a non-default value',
        () {
          final s = const AfadeEffect(
            enabled: true,
            startTime: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_time='));
        },
      );

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AfadeEffect(enabled: true, type: AfadeType.out);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=out'));
      });

      test('param `unity` lands in wire when set to a non-default value', () {
        final s = const AfadeEffect(enabled: true, unity: 0.0);
        expect(s.toFilterString(), contains('unity='));
        expect(s.toFilterString(), contains('unity=0.000'));
      });

      test(
        'param `nb_samples` const `nbSamplesMin` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            nbSamples: AfadeEffect.nbSamplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `nb_samples` const `nbSamplesMax` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            nbSamples: AfadeEffect.nbSamplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `nb_samples` const `nbSamplesDefault` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            nbSamples: AfadeEffect.nbSamplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `silence` const `silenceMin` is accepted by toFilterString',
        () {
          final s = AfadeEffect(enabled: true, silence: AfadeEffect.silenceMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `silence` const `silenceMax` is accepted by toFilterString',
        () {
          final s = AfadeEffect(enabled: true, silence: AfadeEffect.silenceMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `silence` const `silenceDefault` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            silence: AfadeEffect.silenceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_sample` const `startSampleMin` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            startSample: AfadeEffect.startSampleMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_sample` const `startSampleMax` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            startSample: AfadeEffect.startSampleMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_sample` const `startSampleDefault` is accepted by toFilterString',
        () {
          final s = AfadeEffect(
            enabled: true,
            startSample: AfadeEffect.startSampleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `unity` const `unityMin` is accepted by toFilterString', () {
        final s = AfadeEffect(enabled: true, unity: AfadeEffect.unityMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `unity` const `unityMax` is accepted by toFilterString', () {
        final s = AfadeEffect(enabled: true, unity: AfadeEffect.unityMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `unity` const `unityDefault` is accepted by toFilterString',
        () {
          final s = AfadeEffect(enabled: true, unity: AfadeEffect.unityDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfftdnEffect (afftdn)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AfftdnEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AfftdnEffect()];
        expect(audioEffectsChain(fx), '@aek_afftdn_0:lavfi-afftdn');
      });

      test(
        'param `adaptivity` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, adaptivity: 1.0);
          expect(s.toFilterString(), contains('adaptivity='));
          expect(s.toFilterString(), contains('adaptivity=1.000'));
        },
      );

      test(
        'param `band_multiplier` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, bandMultiplier: 5.0);
          expect(s.toFilterString(), contains('band_multiplier='));
          expect(s.toFilterString(), contains('band_multiplier=5.000'));
        },
      );

      test(
        'param `band_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(
            enabled: true,
            bandNoise: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('band_noise='));
        },
      );

      test(
        'param `floor_offset` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, floorOffset: 2.0);
          expect(s.toFilterString(), contains('floor_offset='));
          expect(s.toFilterString(), contains('floor_offset=2.000'));
        },
      );

      test(
        'param `gain_smooth` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, gainSmooth: 50);
          expect(s.toFilterString(), contains('gain_smooth='));
          expect(s.toFilterString(), contains('gain_smooth=50'));
        },
      );

      test(
        'param `noise_floor` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, noiseFloor: -20.0);
          expect(s.toFilterString(), contains('noise_floor='));
          expect(s.toFilterString(), contains('noise_floor=-20.000'));
        },
      );

      test(
        'param `noise_link` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(
            enabled: true,
            noiseLink: AfftdnLink.none,
          );
          expect(s.toFilterString(), contains('noise_link='));
          expect(s.toFilterString(), contains('noise_link=none'));
        },
      );

      test(
        'param `noise_reduction` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, noiseReduction: 97.0);
          expect(s.toFilterString(), contains('noise_reduction='));
          expect(s.toFilterString(), contains('noise_reduction=97.000'));
        },
      );

      test(
        'param `noise_type` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, noiseType: AfftdnType.w);
          expect(s.toFilterString(), contains('noise_type='));
          expect(s.toFilterString(), contains('noise_type=w'));
        },
      );

      test(
        'param `output_mode` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(
            enabled: true,
            outputMode: AfftdnMode.input,
          );
          expect(s.toFilterString(), contains('output_mode='));
          expect(s.toFilterString(), contains('output_mode=input'));
        },
      );

      test(
        'param `residual_floor` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, residualFloor: -20.0);
          expect(s.toFilterString(), contains('residual_floor='));
          expect(s.toFilterString(), contains('residual_floor=-20.000'));
        },
      );

      test(
        'param `sample_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(
            enabled: true,
            sampleNoise: AfftdnSample.start,
          );
          expect(s.toFilterString(), contains('sample_noise='));
          expect(s.toFilterString(), contains('sample_noise=start'));
        },
      );

      test(
        'param `track_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, trackNoise: true);
          expect(s.toFilterString(), contains('track_noise='));
        },
      );

      test(
        'param `track_residual` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnEffect(enabled: true, trackResidual: true);
          expect(s.toFilterString(), contains('track_residual='));
        },
      );

      test(
        'param `adaptivity` const `adaptivityMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            adaptivity: AfftdnEffect.adaptivityMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptivity` const `adaptivityMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            adaptivity: AfftdnEffect.adaptivityMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptivity` const `adaptivityDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            adaptivity: AfftdnEffect.adaptivityDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `bandMultiplierMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            bandMultiplier: AfftdnEffect.bandMultiplierMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `bandMultiplierMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            bandMultiplier: AfftdnEffect.bandMultiplierMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `bandMultiplierDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            bandMultiplier: AfftdnEffect.bandMultiplierDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `floor_offset` const `floorOffsetMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            floorOffset: AfftdnEffect.floorOffsetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `floor_offset` const `floorOffsetMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            floorOffset: AfftdnEffect.floorOffsetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `floor_offset` const `floorOffsetDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            floorOffset: AfftdnEffect.floorOffsetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gain_smooth` const `gainSmoothMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            gainSmooth: AfftdnEffect.gainSmoothMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gain_smooth` const `gainSmoothMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            gainSmooth: AfftdnEffect.gainSmoothMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gain_smooth` const `gainSmoothDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            gainSmooth: AfftdnEffect.gainSmoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_floor` const `noiseFloorMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseFloor: AfftdnEffect.noiseFloorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_floor` const `noiseFloorMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseFloor: AfftdnEffect.noiseFloorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_floor` const `noiseFloorDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseFloor: AfftdnEffect.noiseFloorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noiseReductionMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseReduction: AfftdnEffect.noiseReductionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noiseReductionMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseReduction: AfftdnEffect.noiseReductionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noiseReductionDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            noiseReduction: AfftdnEffect.noiseReductionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `residual_floor` const `residualFloorMin` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            residualFloor: AfftdnEffect.residualFloorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `residual_floor` const `residualFloorMax` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            residualFloor: AfftdnEffect.residualFloorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `residual_floor` const `residualFloorDefault` is accepted by toFilterString',
        () {
          final s = AfftdnEffect(
            enabled: true,
            residualFloor: AfftdnEffect.residualFloorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfftfiltEffect (afftfilt)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AfftfiltEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AfftfiltEffect()];
        expect(audioEffectsChain(fx), '@aek_afftfilt_0:lavfi-afftfilt');
      });

      test('param `imag` lands in wire when set to a non-default value', () {
        final s = const AfftfiltEffect(enabled: true, imag: 'wire_test_alt');
        expect(s.toFilterString(), contains('imag='));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AfftfiltEffect(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `real` lands in wire when set to a non-default value', () {
        final s = const AfftfiltEffect(enabled: true, real: 'wire_test_alt');
        expect(s.toFilterString(), contains('real='));
      });

      test(
        'param `win_func` lands in wire when set to a non-default value',
        () {
          final s = const AfftfiltEffect(
            enabled: true,
            winFunc: AfftfiltWinFunc.rect,
          );
          expect(s.toFilterString(), contains('win_func='));
          expect(s.toFilterString(), contains('win_func=rect'));
        },
      );

      test(
        'param `win_size` lands in wire when set to a non-default value',
        () {
          final s = const AfftfiltEffect(enabled: true, winSize: 131072);
          expect(s.toFilterString(), contains('win_size='));
          expect(s.toFilterString(), contains('win_size=131072'));
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            overlap: AfftfiltEffect.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            overlap: AfftfiltEffect.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            overlap: AfftfiltEffect.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `winSizeMin` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            winSize: AfftfiltEffect.winSizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `winSizeMax` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            winSize: AfftfiltEffect.winSizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `winSizeDefault` is accepted by toFilterString',
        () {
          final s = AfftfiltEffect(
            enabled: true,
            winSize: AfftfiltEffect.winSizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AformatEffect (aformat)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AformatEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AformatEffect()];
        expect(audioEffectsChain(fx), '@aek_aformat_0:lavfi-aformat');
      });

      test(
        'param `channel_layouts` lands in wire when set to a non-default value',
        () {
          final s = const AformatEffect(
            enabled: true,
            channelLayouts: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channel_layouts='));
        },
      );

      test(
        'param `sample_fmts` lands in wire when set to a non-default value',
        () {
          final s = const AformatEffect(
            enabled: true,
            sampleFmts: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('sample_fmts='));
        },
      );

      test(
        'param `sample_rates` lands in wire when set to a non-default value',
        () {
          final s = const AformatEffect(
            enabled: true,
            sampleRates: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('sample_rates='));
        },
      );
    });
    group('AfreqshiftEffect (afreqshift)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AfreqshiftEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AfreqshiftEffect()];
        expect(audioEffectsChain(fx), '@aek_afreqshift_0:lavfi-afreqshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftEffect(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftEffect(enabled: true, order: 16);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=16'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftEffect(enabled: true, shift: 2147483647.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=2147483647.000'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          level: AfreqshiftEffect.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          level: AfreqshiftEffect.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftEffect(
            enabled: true,
            level: AfreqshiftEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          order: AfreqshiftEffect.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          order: AfreqshiftEffect.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftEffect(
            enabled: true,
            order: AfreqshiftEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          shift: AfreqshiftEffect.shiftMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = AfreqshiftEffect(
          enabled: true,
          shift: AfreqshiftEffect.shiftMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftEffect(
            enabled: true,
            shift: AfreqshiftEffect.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfwtdnEffect (afwtdn)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AfwtdnEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AfwtdnEffect()];
        expect(audioEffectsChain(fx), '@aek_afwtdn_0:lavfi-afwtdn');
      });

      test(
        'param `adaptive` lands in wire when set to a non-default value',
        () {
          final s = const AfwtdnEffect(enabled: true, adaptive: true);
          expect(s.toFilterString(), contains('adaptive='));
        },
      );

      test('param `levels` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, levels: 12);
        expect(s.toFilterString(), contains('levels='));
        expect(s.toFilterString(), contains('levels=12'));
      });

      test('param `percent` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, percent: 100.0);
        expect(s.toFilterString(), contains('percent='));
        expect(s.toFilterString(), contains('percent=100.000'));
      });

      test('param `profile` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, profile: true);
        expect(s.toFilterString(), contains('profile='));
      });

      test('param `samples` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, samples: 65536);
        expect(s.toFilterString(), contains('samples='));
        expect(s.toFilterString(), contains('samples=65536'));
      });

      test('param `sigma` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, sigma: 1.0);
        expect(s.toFilterString(), contains('sigma='));
        expect(s.toFilterString(), contains('sigma=1.000'));
      });

      test(
        'param `softness` lands in wire when set to a non-default value',
        () {
          final s = const AfwtdnEffect(enabled: true, softness: 10.0);
          expect(s.toFilterString(), contains('softness='));
          expect(s.toFilterString(), contains('softness=10.000'));
        },
      );

      test('param `wavet` lands in wire when set to a non-default value', () {
        final s = const AfwtdnEffect(enabled: true, wavet: AfwtdnWavet.sym2);
        expect(s.toFilterString(), contains('wavet='));
        expect(s.toFilterString(), contains('wavet=sym2'));
      });

      test(
        'param `levels` const `levelsMin` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(enabled: true, levels: AfwtdnEffect.levelsMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `levels` const `levelsMax` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(enabled: true, levels: AfwtdnEffect.levelsMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `levels` const `levelsDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            levels: AfwtdnEffect.levelsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentMin` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            percent: AfwtdnEffect.percentMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentMax` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            percent: AfwtdnEffect.percentMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            percent: AfwtdnEffect.percentDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMin` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            samples: AfwtdnEffect.samplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMax` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            samples: AfwtdnEffect.samplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            samples: AfwtdnEffect.samplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sigma` const `sigmaMin` is accepted by toFilterString', () {
        final s = AfwtdnEffect(enabled: true, sigma: AfwtdnEffect.sigmaMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sigma` const `sigmaMax` is accepted by toFilterString', () {
        final s = AfwtdnEffect(enabled: true, sigma: AfwtdnEffect.sigmaMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sigma` const `sigmaDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            sigma: AfwtdnEffect.sigmaDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessMin` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            softness: AfwtdnEffect.softnessMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessMax` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            softness: AfwtdnEffect.softnessMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnEffect(
            enabled: true,
            softness: AfwtdnEffect.softnessDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AgateEffect (agate)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AgateEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AgateEffect()];
        expect(audioEffectsChain(fx), '@aek_agate_0:lavfi-agate');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, attack: 9000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=9000.000'));
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const AgateEffect(
            enabled: true,
            detection: AgateDetection.peak,
          );
          expect(s.toFilterString(), contains('detection='));
          expect(s.toFilterString(), contains('detection=peak'));
        },
      );

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AgateEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_sc` lands in wire when set to a non-default value',
        () {
          final s = const AgateEffect(enabled: true, levelSc: 64.0);
          expect(s.toFilterString(), contains('level_sc='));
          expect(s.toFilterString(), contains('level_sc=64.000'));
        },
      );

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, link: AgateLink.maximum);
        expect(s.toFilterString(), contains('link='));
        expect(s.toFilterString(), contains('link=maximum'));
      });

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, makeup: 64.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, mode: AgateMode.upward);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=upward'));
      });

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, range: 1.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=1.000'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, ratio: 9000.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=9000.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AgateEffect(enabled: true, release: 9000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=9000.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AgateEffect(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, attack: AgateEffect.attackMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, attack: AgateEffect.attackMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            attack: AgateEffect.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `knee` const `kneeMin` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, knee: AgateEffect.kneeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `knee` const `kneeMax` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, knee: AgateEffect.kneeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `knee` const `kneeDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, knee: AgateEffect.kneeDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, levelIn: AgateEffect.levelInMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, levelIn: AgateEffect.levelInMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            levelIn: AgateEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, levelSc: AgateEffect.levelScMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, levelSc: AgateEffect.levelScMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `levelScDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            levelSc: AgateEffect.levelScDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, makeup: AgateEffect.makeupMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, makeup: AgateEffect.makeupMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            makeup: AgateEffect.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, range: AgateEffect.rangeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, range: AgateEffect.rangeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, range: AgateEffect.rangeDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, ratio: AgateEffect.ratioMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AgateEffect(enabled: true, ratio: AgateEffect.ratioMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, ratio: AgateEffect.ratioDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, release: AgateEffect.releaseMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(enabled: true, release: AgateEffect.releaseMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            release: AgateEffect.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            threshold: AgateEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            threshold: AgateEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AgateEffect(
            enabled: true,
            threshold: AgateEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AiirEffect (aiir)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AiirEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AiirEffect()];
        expect(audioEffectsChain(fx), '@aek_aiir_0:lavfi-aiir');
      });

      test('param `channel` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, channel: 1024);
        expect(s.toFilterString(), contains('channel='));
        expect(s.toFilterString(), contains('channel=1024'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, dry: 0.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=0.000'));
      });

      test('param `format` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, format: AiirFormat.ll);
        expect(s.toFilterString(), contains('format='));
        expect(s.toFilterString(), contains('format=ll'));
      });

      test('param `gains` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, gains: 'wire_test_alt');
        expect(s.toFilterString(), contains('gains='));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const AiirEffect(enabled: true, normalize: false);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, poles: 'wire_test_alt');
        expect(s.toFilterString(), contains('poles='));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AiirEffect(
            enabled: true,
            precision: AiirPrecision.flt,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=flt'));
        },
      );

      test('param `process` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, process: AiirProcess.d);
        expect(s.toFilterString(), contains('process='));
        expect(s.toFilterString(), contains('process=d'));
      });

      test('param `rate` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, rate: 'wire_test_alt');
        expect(s.toFilterString(), contains('rate='));
      });

      test(
        'param `response` lands in wire when set to a non-default value',
        () {
          final s = const AiirEffect(enabled: true, response: true);
          expect(s.toFilterString(), contains('response='));
        },
      );

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, size: 'wire_test_alt');
        expect(s.toFilterString(), contains('size='));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `zeros` lands in wire when set to a non-default value', () {
        final s = const AiirEffect(enabled: true, zeros: 'wire_test_alt');
        expect(s.toFilterString(), contains('zeros='));
      });

      test(
        'param `channel` const `channelMin` is accepted by toFilterString',
        () {
          final s = AiirEffect(enabled: true, channel: AiirEffect.channelMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `channel` const `channelMax` is accepted by toFilterString',
        () {
          final s = AiirEffect(enabled: true, channel: AiirEffect.channelMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `channel` const `channelDefault` is accepted by toFilterString',
        () {
          final s = AiirEffect(
            enabled: true,
            channel: AiirEffect.channelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, dry: AiirEffect.dryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, dry: AiirEffect.dryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, dry: AiirEffect.dryDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, mix: AiirEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, mix: AiirEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, mix: AiirEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, wet: AiirEffect.wetMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, wet: AiirEffect.wetMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = AiirEffect(enabled: true, wet: AiirEffect.wetDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AintegralEffect (aintegral)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AintegralEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AintegralEffect()];
        expect(audioEffectsChain(fx), '@aek_aintegral_0:lavfi-aintegral');
      });
    });
    group('AlimiterEffect (alimiter)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AlimiterEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AlimiterEffect()];
        expect(audioEffectsChain(fx), '@aek_alimiter_0:lavfi-alimiter');
      });

      test('param `asc` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, asc: true);
        expect(s.toFilterString(), contains('asc='));
      });

      test(
        'param `asc_level` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterEffect(enabled: true, ascLevel: 1.0);
          expect(s.toFilterString(), contains('asc_level='));
          expect(s.toFilterString(), contains('asc_level=1.000'));
        },
      );

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, attack: 80.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=80.000'));
      });

      test('param `latency` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, latency: true);
        expect(s.toFilterString(), contains('latency='));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, level: false);
        expect(s.toFilterString(), contains('level='));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `limit` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, limit: 0.0625);
        expect(s.toFilterString(), contains('limit='));
        expect(s.toFilterString(), contains('limit=0.062500'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AlimiterEffect(enabled: true, release: 8000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=8000.000'));
      });

      test(
        'param `asc_level` const `ascLevelMin` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            ascLevel: AlimiterEffect.ascLevelMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `asc_level` const `ascLevelMax` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            ascLevel: AlimiterEffect.ascLevelMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `asc_level` const `ascLevelDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            ascLevel: AlimiterEffect.ascLevelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            attack: AlimiterEffect.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            attack: AlimiterEffect.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            attack: AlimiterEffect.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelIn: AlimiterEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelIn: AlimiterEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelIn: AlimiterEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelOut: AlimiterEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelOut: AlimiterEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            levelOut: AlimiterEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `limit` const `limitMin` is accepted by toFilterString', () {
        final s = AlimiterEffect(enabled: true, limit: AlimiterEffect.limitMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `limit` const `limitMax` is accepted by toFilterString', () {
        final s = AlimiterEffect(enabled: true, limit: AlimiterEffect.limitMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `limit` const `limitDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            limit: AlimiterEffect.limitDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            release: AlimiterEffect.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            release: AlimiterEffect.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AlimiterEffect(
            enabled: true,
            release: AlimiterEffect.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AllpassEffect (allpass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AllpassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AllpassEffect()];
        expect(audioEffectsChain(fx), '@aek_allpass_0:lavfi-allpass');
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AllpassEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AllpassEffect(enabled: true, order: 1);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(
            enabled: true,
            precision: AllpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(
            enabled: true,
            transform: AllpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const AllpassEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const AllpassEffect(
            enabled: true,
            widthType: AllpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = AllpassEffect(
            enabled: true,
            frequency: AllpassEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = AllpassEffect(
            enabled: true,
            frequency: AllpassEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = AllpassEffect(
            enabled: true,
            frequency: AllpassEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, mix: AllpassEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, mix: AllpassEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, mix: AllpassEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, order: AllpassEffect.orderMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, order: AllpassEffect.orderMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AllpassEffect(
            enabled: true,
            order: AllpassEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, width: AllpassEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = AllpassEffect(enabled: true, width: AllpassEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = AllpassEffect(
            enabled: true,
            width: AllpassEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AnequalizerEffect (anequalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AnequalizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AnequalizerEffect()];
        expect(audioEffectsChain(fx), '@aek_anequalizer_0:lavfi-anequalizer');
      });

      test('param `colors` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(
          enabled: true,
          colors: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('colors='));
      });

      test('param `curves` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(enabled: true, curves: true);
        expect(s.toFilterString(), contains('curves='));
      });

      test('param `fscale` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(
          enabled: true,
          fscale: AnequalizerFscale.lin,
        );
        expect(s.toFilterString(), contains('fscale='));
        expect(s.toFilterString(), contains('fscale=lin'));
      });

      test('param `mgain` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(enabled: true, mgain: 900.0);
        expect(s.toFilterString(), contains('mgain='));
        expect(s.toFilterString(), contains('mgain=900.000'));
      });

      test('param `params` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(
          enabled: true,
          params: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('params='));
      });

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const AnequalizerEffect(enabled: true, size: 'wire_test_alt');
        expect(s.toFilterString(), contains('size='));
      });

      test('param `mgain` const `mgainMin` is accepted by toFilterString', () {
        final s = AnequalizerEffect(
          enabled: true,
          mgain: AnequalizerEffect.mgainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mgain` const `mgainMax` is accepted by toFilterString', () {
        final s = AnequalizerEffect(
          enabled: true,
          mgain: AnequalizerEffect.mgainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mgain` const `mgainDefault` is accepted by toFilterString',
        () {
          final s = AnequalizerEffect(
            enabled: true,
            mgain: AnequalizerEffect.mgainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AnlmdnEffect (anlmdn)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AnlmdnEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AnlmdnEffect()];
        expect(audioEffectsChain(fx), '@aek_anlmdn_0:lavfi-anlmdn');
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AnlmdnEffect(enabled: true, output: AnlmdnMode.i);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=i'));
      });

      test('param `patch` lands in wire when set to a non-default value', () {
        final s = const AnlmdnEffect(
          enabled: true,
          patch: const Duration(microseconds: 1002000),
        );
        expect(s.toFilterString(), contains('patch='));
      });

      test(
        'param `research` lands in wire when set to a non-default value',
        () {
          final s = const AnlmdnEffect(
            enabled: true,
            research: const Duration(microseconds: 1006000),
          );
          expect(s.toFilterString(), contains('research='));
        },
      );

      test('param `smooth` lands in wire when set to a non-default value', () {
        final s = const AnlmdnEffect(enabled: true, smooth: 1000.0);
        expect(s.toFilterString(), contains('smooth='));
        expect(s.toFilterString(), contains('smooth=1000.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const AnlmdnEffect(enabled: true, strength: 10000.0);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=10000.000'));
        },
      );

      test(
        'param `smooth` const `smoothMin` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(enabled: true, smooth: AnlmdnEffect.smoothMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothMax` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(enabled: true, smooth: AnlmdnEffect.smoothMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothDefault` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(
            enabled: true,
            smooth: AnlmdnEffect.smoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(
            enabled: true,
            strength: AnlmdnEffect.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(
            enabled: true,
            strength: AnlmdnEffect.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = AnlmdnEffect(
            enabled: true,
            strength: AnlmdnEffect.strengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApadEffect (apad)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ApadEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [ApadEffect()];
        expect(audioEffectsChain(fx), '@aek_apad_0:lavfi-apad');
      });

      test(
        'param `packet_size` lands in wire when set to a non-default value',
        () {
          final s = const ApadEffect(enabled: true, packetSize: 2147483647);
          expect(s.toFilterString(), contains('packet_size='));
          expect(s.toFilterString(), contains('packet_size=2147483647'));
        },
      );

      test('param `pad_dur` lands in wire when set to a non-default value', () {
        final s = const ApadEffect(
          enabled: true,
          padDur: const Duration(microseconds: 999999),
        );
        expect(s.toFilterString(), contains('pad_dur='));
      });

      test('param `pad_len` lands in wire when set to a non-default value', () {
        final s = const ApadEffect(enabled: true, padLen: 9223372036854775807);
        expect(s.toFilterString(), contains('pad_len='));
        expect(s.toFilterString(), contains('pad_len=9223372036854775807'));
      });

      test(
        'param `whole_dur` lands in wire when set to a non-default value',
        () {
          final s = const ApadEffect(
            enabled: true,
            wholeDur: const Duration(microseconds: 999999),
          );
          expect(s.toFilterString(), contains('whole_dur='));
        },
      );

      test(
        'param `whole_len` lands in wire when set to a non-default value',
        () {
          final s = const ApadEffect(
            enabled: true,
            wholeLen: 9223372036854775807,
          );
          expect(s.toFilterString(), contains('whole_len='));
          expect(s.toFilterString(), contains('whole_len=9223372036854775807'));
        },
      );

      test(
        'param `packet_size` const `packetSizeMin` is accepted by toFilterString',
        () {
          final s = ApadEffect(
            enabled: true,
            packetSize: ApadEffect.packetSizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `packet_size` const `packetSizeMax` is accepted by toFilterString',
        () {
          final s = ApadEffect(
            enabled: true,
            packetSize: ApadEffect.packetSizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `packet_size` const `packetSizeDefault` is accepted by toFilterString',
        () {
          final s = ApadEffect(
            enabled: true,
            packetSize: ApadEffect.packetSizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `padLenMin` is accepted by toFilterString',
        () {
          final s = ApadEffect(enabled: true, padLen: ApadEffect.padLenMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `padLenMax` is accepted by toFilterString',
        () {
          final s = ApadEffect(enabled: true, padLen: ApadEffect.padLenMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `padLenDefault` is accepted by toFilterString',
        () {
          final s = ApadEffect(enabled: true, padLen: ApadEffect.padLenDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `wholeLenMin` is accepted by toFilterString',
        () {
          final s = ApadEffect(enabled: true, wholeLen: ApadEffect.wholeLenMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `wholeLenMax` is accepted by toFilterString',
        () {
          final s = ApadEffect(enabled: true, wholeLen: ApadEffect.wholeLenMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `wholeLenDefault` is accepted by toFilterString',
        () {
          final s = ApadEffect(
            enabled: true,
            wholeLen: ApadEffect.wholeLenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AphaserEffect (aphaser)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AphaserEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AphaserEffect()];
        expect(audioEffectsChain(fx), '@aek_aphaser_0:lavfi-aphaser');
      });

      test('param `decay` lands in wire when set to a non-default value', () {
        final s = const AphaserEffect(enabled: true, decay: 0.99);
        expect(s.toFilterString(), contains('decay='));
        expect(s.toFilterString(), contains('decay=0.990'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const AphaserEffect(enabled: true, delay: 5.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=5.000'));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const AphaserEffect(enabled: true, inGain: 1.0);
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test(
        'param `out_gain` lands in wire when set to a non-default value',
        () {
          final s = const AphaserEffect(enabled: true, outGain: 1000000000.0);
          expect(s.toFilterString(), contains('out_gain='));
          expect(s.toFilterString(), contains('out_gain=1000000000.000'));
        },
      );

      test('param `speed` lands in wire when set to a non-default value', () {
        final s = const AphaserEffect(enabled: true, speed: 2.0);
        expect(s.toFilterString(), contains('speed='));
        expect(s.toFilterString(), contains('speed=2.000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AphaserEffect(enabled: true, type: AphaserType.t);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=t'));
      });

      test('param `decay` const `decayMin` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, decay: AphaserEffect.decayMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `decay` const `decayMax` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, decay: AphaserEffect.decayMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `decay` const `decayDefault` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            decay: AphaserEffect.decayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, delay: AphaserEffect.delayMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, delay: AphaserEffect.delayMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            delay: AphaserEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainMin` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            inGain: AphaserEffect.inGainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainMax` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            inGain: AphaserEffect.inGainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainDefault` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            inGain: AphaserEffect.inGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMin` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            outGain: AphaserEffect.outGainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMax` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            outGain: AphaserEffect.outGainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainDefault` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            outGain: AphaserEffect.outGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `speed` const `speedMin` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, speed: AphaserEffect.speedMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `speed` const `speedMax` is accepted by toFilterString', () {
        final s = AphaserEffect(enabled: true, speed: AphaserEffect.speedMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `speed` const `speedDefault` is accepted by toFilterString',
        () {
          final s = AphaserEffect(
            enabled: true,
            speed: AphaserEffect.speedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AphaseshiftEffect (aphaseshift)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AphaseshiftEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AphaseshiftEffect()];
        expect(audioEffectsChain(fx), '@aek_aphaseshift_0:lavfi-aphaseshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftEffect(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftEffect(enabled: true, order: 16);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=16'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftEffect(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          level: AphaseshiftEffect.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          level: AphaseshiftEffect.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftEffect(
            enabled: true,
            level: AphaseshiftEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          order: AphaseshiftEffect.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          order: AphaseshiftEffect.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftEffect(
            enabled: true,
            order: AphaseshiftEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          shift: AphaseshiftEffect.shiftMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = AphaseshiftEffect(
          enabled: true,
          shift: AphaseshiftEffect.shiftMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftEffect(
            enabled: true,
            shift: AphaseshiftEffect.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApsyclipEffect (apsyclip)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ApsyclipEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [ApsyclipEffect()];
        expect(audioEffectsChain(fx), '@aek_apsyclip_0:lavfi-apsyclip');
      });

      test(
        'param `adaptive` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipEffect(enabled: true, adaptive: 1.0);
          expect(s.toFilterString(), contains('adaptive='));
          expect(s.toFilterString(), contains('adaptive=1.000'));
        },
      );

      test('param `clip` lands in wire when set to a non-default value', () {
        final s = const ApsyclipEffect(enabled: true, clip: 0.015625);
        expect(s.toFilterString(), contains('clip='));
        expect(s.toFilterString(), contains('clip=0.015625'));
      });

      test('param `diff` lands in wire when set to a non-default value', () {
        final s = const ApsyclipEffect(enabled: true, diff: true);
        expect(s.toFilterString(), contains('diff='));
      });

      test(
        'param `iterations` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipEffect(enabled: true, iterations: 20);
          expect(s.toFilterString(), contains('iterations='));
          expect(s.toFilterString(), contains('iterations=20'));
        },
      );

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const ApsyclipEffect(enabled: true, level: true);
        expect(s.toFilterString(), contains('level='));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test(
        'param `adaptive` const `adaptiveMin` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            adaptive: ApsyclipEffect.adaptiveMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptive` const `adaptiveMax` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            adaptive: ApsyclipEffect.adaptiveMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptive` const `adaptiveDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            adaptive: ApsyclipEffect.adaptiveDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `clip` const `clipMin` is accepted by toFilterString', () {
        final s = ApsyclipEffect(enabled: true, clip: ApsyclipEffect.clipMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `clip` const `clipMax` is accepted by toFilterString', () {
        final s = ApsyclipEffect(enabled: true, clip: ApsyclipEffect.clipMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `clip` const `clipDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            clip: ApsyclipEffect.clipDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsMin` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            iterations: ApsyclipEffect.iterationsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsMax` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            iterations: ApsyclipEffect.iterationsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            iterations: ApsyclipEffect.iterationsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelIn: ApsyclipEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelIn: ApsyclipEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelIn: ApsyclipEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelOut: ApsyclipEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelOut: ApsyclipEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipEffect(
            enabled: true,
            levelOut: ApsyclipEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApulsatorEffect (apulsator)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ApulsatorEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [ApulsatorEffect()];
        expect(audioEffectsChain(fx), '@aek_apulsator_0:lavfi-apulsator');
      });

      test('param `amount` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(enabled: true, amount: 0.0);
        expect(s.toFilterString(), contains('amount='));
        expect(s.toFilterString(), contains('amount=0.000'));
      });

      test('param `bpm` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(enabled: true, bpm: 300.0);
        expect(s.toFilterString(), contains('bpm='));
        expect(s.toFilterString(), contains('bpm=300.000'));
      });

      test('param `hz` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(enabled: true, hz: 100.0);
        expect(s.toFilterString(), contains('hz='));
        expect(s.toFilterString(), contains('hz=100.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(
          enabled: true,
          mode: ApulsatorMode.triangle,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=triangle'));
      });

      test('param `ms` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(enabled: true, ms: 2000);
        expect(s.toFilterString(), contains('ms='));
        expect(s.toFilterString(), contains('ms=2000'));
      });

      test(
        'param `offset_l` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorEffect(enabled: true, offsetL: 1.0);
          expect(s.toFilterString(), contains('offset_l='));
          expect(s.toFilterString(), contains('offset_l=1.000'));
        },
      );

      test(
        'param `offset_r` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorEffect(enabled: true, offsetR: 1.0);
          expect(s.toFilterString(), contains('offset_r='));
          expect(s.toFilterString(), contains('offset_r=1.000'));
        },
      );

      test('param `timing` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(
          enabled: true,
          timing: ApulsatorTiming.ms,
        );
        expect(s.toFilterString(), contains('timing='));
        expect(s.toFilterString(), contains('timing=ms'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const ApulsatorEffect(enabled: true, width: 2.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=2.000'));
      });

      test(
        'param `amount` const `amountMin` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            amount: ApulsatorEffect.amountMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountMax` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            amount: ApulsatorEffect.amountMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            amount: ApulsatorEffect.amountDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bpm` const `bpmMin` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, bpm: ApulsatorEffect.bpmMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bpm` const `bpmMax` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, bpm: ApulsatorEffect.bpmMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bpm` const `bpmDefault` is accepted by toFilterString', () {
        final s = ApulsatorEffect(
          enabled: true,
          bpm: ApulsatorEffect.bpmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzMin` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, hz: ApulsatorEffect.hzMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzMax` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, hz: ApulsatorEffect.hzMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzDefault` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, hz: ApulsatorEffect.hzDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelIn: ApulsatorEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelIn: ApulsatorEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelIn: ApulsatorEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelOut: ApulsatorEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelOut: ApulsatorEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            levelOut: ApulsatorEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ms` const `msMin` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, ms: ApulsatorEffect.msMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ms` const `msMax` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, ms: ApulsatorEffect.msMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ms` const `msDefault` is accepted by toFilterString', () {
        final s = ApulsatorEffect(enabled: true, ms: ApulsatorEffect.msDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `offset_l` const `offsetLMin` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetL: ApulsatorEffect.offsetLMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_l` const `offsetLMax` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetL: ApulsatorEffect.offsetLMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_l` const `offsetLDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetL: ApulsatorEffect.offsetLDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offsetRMin` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetR: ApulsatorEffect.offsetRMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offsetRMax` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetR: ApulsatorEffect.offsetRMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offsetRDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            offsetR: ApulsatorEffect.offsetRDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = ApulsatorEffect(
          enabled: true,
          width: ApulsatorEffect.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = ApulsatorEffect(
          enabled: true,
          width: ApulsatorEffect.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorEffect(
            enabled: true,
            width: ApulsatorEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AresampleEffect (aresample)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AresampleEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AresampleEffect()];
        expect(audioEffectsChain(fx), '@aek_aresample_0:lavfi-aresample');
      });

      test(
        'param `sample_rate` lands in wire when set to a non-default value',
        () {
          final s = const AresampleEffect(enabled: true, sampleRate: 768000);
          expect(s.toFilterString(), contains('sample_rate='));
          expect(s.toFilterString(), contains('sample_rate=768000'));
        },
      );

      test(
        'param `sample_rate` const `sampleRateMin` is accepted by toFilterString',
        () {
          final s = AresampleEffect(
            enabled: true,
            sampleRate: AresampleEffect.sampleRateMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sample_rate` const `sampleRateMax` is accepted by toFilterString',
        () {
          final s = AresampleEffect(
            enabled: true,
            sampleRate: AresampleEffect.sampleRateMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sample_rate` const `sampleRateDefault` is accepted by toFilterString',
        () {
          final s = AresampleEffect(
            enabled: true,
            sampleRate: AresampleEffect.sampleRateDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ArnndnEffect (arnndn)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ArnndnEffect(enabled: false, model: '')];
        expect(audioEffectsChain(fx), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = [ArnndnEffect(model: '')];
          expect(
            audioEffectsChain(fx),
            startsWith('@aek_arnndn_0:lavfi-arnndn'),
          );
          expect(audioEffectsChain(fx), contains('model='));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const ArnndnEffect(enabled: true, mix: -1.0, model: '');
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=-1.000'));
      });

      test('param `model` lands in wire when set to a non-default value', () {
        final s = const ArnndnEffect(enabled: true, model: 'wire_test_alt');
        expect(s.toFilterString(), contains('model='));
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = ArnndnEffect(
          enabled: true,
          mix: ArnndnEffect.mixMin,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = ArnndnEffect(
          enabled: true,
          mix: ArnndnEffect.mixMax,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = ArnndnEffect(
          enabled: true,
          mix: ArnndnEffect.mixDefault,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AsetrateEffect (asetrate)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsetrateEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsetrateEffect()];
        expect(audioEffectsChain(fx), '@aek_asetrate_0:lavfi-asetrate');
      });
    });
    group('AsoftclipEffect (asoftclip)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsoftclipEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsoftclipEffect()];
        expect(audioEffectsChain(fx), '@aek_asoftclip_0:lavfi-asoftclip');
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AsoftclipEffect(enabled: true, output: 16.0);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=16.000'));
      });

      test(
        'param `oversample` lands in wire when set to a non-default value',
        () {
          final s = const AsoftclipEffect(enabled: true, oversample: 64);
          expect(s.toFilterString(), contains('oversample='));
          expect(s.toFilterString(), contains('oversample=64'));
        },
      );

      test('param `param` lands in wire when set to a non-default value', () {
        final s = const AsoftclipEffect(enabled: true, param: 3.0);
        expect(s.toFilterString(), contains('param='));
        expect(s.toFilterString(), contains('param=3.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AsoftclipEffect(enabled: true, threshold: 1e-06);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1e-6'));
        },
      );

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AsoftclipEffect(
          enabled: true,
          type: AsoftclipTypes.tanh,
        );
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=tanh'));
      });

      test(
        'param `output` const `outputMin` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            output: AsoftclipEffect.outputMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `output` const `outputMax` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            output: AsoftclipEffect.outputMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `output` const `outputDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            output: AsoftclipEffect.outputDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleMin` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            oversample: AsoftclipEffect.oversampleMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleMax` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            oversample: AsoftclipEffect.oversampleMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            oversample: AsoftclipEffect.oversampleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `param` const `paramMin` is accepted by toFilterString', () {
        final s = AsoftclipEffect(
          enabled: true,
          param: AsoftclipEffect.paramMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `param` const `paramMax` is accepted by toFilterString', () {
        final s = AsoftclipEffect(
          enabled: true,
          param: AsoftclipEffect.paramMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `param` const `paramDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            param: AsoftclipEffect.paramDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            threshold: AsoftclipEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            threshold: AsoftclipEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipEffect(
            enabled: true,
            threshold: AsoftclipEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsubboostEffect (asubboost)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsubboostEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsubboostEffect()];
        expect(audioEffectsChain(fx), '@aek_asubboost_0:lavfi-asubboost');
      });

      test('param `boost` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, boost: 12.0);
        expect(s.toFilterString(), contains('boost='));
        expect(s.toFilterString(), contains('boost=12.000'));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AsubboostEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, cutoff: 900.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=900.000'));
      });

      test('param `decay` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, decay: 1.0);
        expect(s.toFilterString(), contains('decay='));
        expect(s.toFilterString(), contains('decay=1.000'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, delay: 100.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=100.000'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, dry: 0.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=0.000'));
      });

      test(
        'param `feedback` lands in wire when set to a non-default value',
        () {
          final s = const AsubboostEffect(enabled: true, feedback: 1.0);
          expect(s.toFilterString(), contains('feedback='));
          expect(s.toFilterString(), contains('feedback=1.000'));
        },
      );

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const AsubboostEffect(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `boost` const `boostMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          boost: AsubboostEffect.boostMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `boost` const `boostMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          boost: AsubboostEffect.boostMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `boost` const `boostDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            boost: AsubboostEffect.boostDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            cutoff: AsubboostEffect.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            cutoff: AsubboostEffect.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            cutoff: AsubboostEffect.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `decay` const `decayMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          decay: AsubboostEffect.decayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `decay` const `decayMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          decay: AsubboostEffect.decayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `decay` const `decayDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            decay: AsubboostEffect.decayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          delay: AsubboostEffect.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          delay: AsubboostEffect.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            delay: AsubboostEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(enabled: true, dry: AsubboostEffect.dryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(enabled: true, dry: AsubboostEffect.dryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          dry: AsubboostEffect.dryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `feedback` const `feedbackMin` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            feedback: AsubboostEffect.feedbackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMax` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            feedback: AsubboostEffect.feedbackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            feedback: AsubboostEffect.feedbackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          slope: AsubboostEffect.slopeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          slope: AsubboostEffect.slopeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = AsubboostEffect(
            enabled: true,
            slope: AsubboostEffect.slopeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = AsubboostEffect(enabled: true, wet: AsubboostEffect.wetMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = AsubboostEffect(enabled: true, wet: AsubboostEffect.wetMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = AsubboostEffect(
          enabled: true,
          wet: AsubboostEffect.wetDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AsubcutEffect (asubcut)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsubcutEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsubcutEffect()];
        expect(audioEffectsChain(fx), '@aek_asubcut_0:lavfi-asubcut');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsubcutEffect(enabled: true, cutoff: 200.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=200.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsubcutEffect(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsubcutEffect(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsubcutEffect(
            enabled: true,
            cutoff: AsubcutEffect.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsubcutEffect(
            enabled: true,
            cutoff: AsubcutEffect.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsubcutEffect(
            enabled: true,
            cutoff: AsubcutEffect.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsubcutEffect(enabled: true, level: AsubcutEffect.levelMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsubcutEffect(enabled: true, level: AsubcutEffect.levelMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsubcutEffect(
            enabled: true,
            level: AsubcutEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsubcutEffect(enabled: true, order: AsubcutEffect.orderMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsubcutEffect(enabled: true, order: AsubcutEffect.orderMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsubcutEffect(
            enabled: true,
            order: AsubcutEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsupercutEffect (asupercut)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsupercutEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsupercutEffect()];
        expect(audioEffectsChain(fx), '@aek_asupercut_0:lavfi-asupercut');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsupercutEffect(enabled: true, cutoff: 192000.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=192000.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsupercutEffect(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsupercutEffect(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsupercutEffect(
            enabled: true,
            cutoff: AsupercutEffect.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsupercutEffect(
            enabled: true,
            cutoff: AsupercutEffect.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsupercutEffect(
            enabled: true,
            cutoff: AsupercutEffect.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsupercutEffect(
          enabled: true,
          level: AsupercutEffect.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsupercutEffect(
          enabled: true,
          level: AsupercutEffect.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsupercutEffect(
            enabled: true,
            level: AsupercutEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsupercutEffect(
          enabled: true,
          order: AsupercutEffect.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsupercutEffect(
          enabled: true,
          order: AsupercutEffect.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsupercutEffect(
            enabled: true,
            order: AsupercutEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsuperpassEffect (asuperpass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsuperpassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsuperpassEffect()];
        expect(audioEffectsChain(fx), '@aek_asuperpass_0:lavfi-asuperpass');
      });

      test('param `centerf` lands in wire when set to a non-default value', () {
        final s = const AsuperpassEffect(enabled: true, centerf: 999999.0);
        expect(s.toFilterString(), contains('centerf='));
        expect(s.toFilterString(), contains('centerf=999999.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsuperpassEffect(enabled: true, level: 2.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=2.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsuperpassEffect(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test('param `qfactor` lands in wire when set to a non-default value', () {
        final s = const AsuperpassEffect(enabled: true, qfactor: 100.0);
        expect(s.toFilterString(), contains('qfactor='));
        expect(s.toFilterString(), contains('qfactor=100.000'));
      });

      test(
        'param `centerf` const `centerfMin` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            centerf: AsuperpassEffect.centerfMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfMax` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            centerf: AsuperpassEffect.centerfMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            centerf: AsuperpassEffect.centerfDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsuperpassEffect(
          enabled: true,
          level: AsuperpassEffect.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsuperpassEffect(
          enabled: true,
          level: AsuperpassEffect.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            level: AsuperpassEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsuperpassEffect(
          enabled: true,
          order: AsuperpassEffect.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsuperpassEffect(
          enabled: true,
          order: AsuperpassEffect.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            order: AsuperpassEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMin` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            qfactor: AsuperpassEffect.qfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMax` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            qfactor: AsuperpassEffect.qfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassEffect(
            enabled: true,
            qfactor: AsuperpassEffect.qfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsuperstopEffect (asuperstop)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AsuperstopEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AsuperstopEffect()];
        expect(audioEffectsChain(fx), '@aek_asuperstop_0:lavfi-asuperstop');
      });

      test('param `centerf` lands in wire when set to a non-default value', () {
        final s = const AsuperstopEffect(enabled: true, centerf: 999999.0);
        expect(s.toFilterString(), contains('centerf='));
        expect(s.toFilterString(), contains('centerf=999999.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsuperstopEffect(enabled: true, level: 2.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=2.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsuperstopEffect(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test('param `qfactor` lands in wire when set to a non-default value', () {
        final s = const AsuperstopEffect(enabled: true, qfactor: 100.0);
        expect(s.toFilterString(), contains('qfactor='));
        expect(s.toFilterString(), contains('qfactor=100.000'));
      });

      test(
        'param `centerf` const `centerfMin` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            centerf: AsuperstopEffect.centerfMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfMax` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            centerf: AsuperstopEffect.centerfMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            centerf: AsuperstopEffect.centerfDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsuperstopEffect(
          enabled: true,
          level: AsuperstopEffect.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsuperstopEffect(
          enabled: true,
          level: AsuperstopEffect.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            level: AsuperstopEffect.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsuperstopEffect(
          enabled: true,
          order: AsuperstopEffect.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsuperstopEffect(
          enabled: true,
          order: AsuperstopEffect.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            order: AsuperstopEffect.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMin` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            qfactor: AsuperstopEffect.qfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMax` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            qfactor: AsuperstopEffect.qfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopEffect(
            enabled: true,
            qfactor: AsuperstopEffect.qfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AtempoEffect (atempo)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AtempoEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AtempoEffect()];
        expect(audioEffectsChain(fx), '@aek_atempo_0:lavfi-atempo');
      });

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const AtempoEffect(enabled: true, tempo: 100.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=100.000'));
      });

      test('param `tempo` const `tempoMin` is accepted by toFilterString', () {
        final s = AtempoEffect(enabled: true, tempo: AtempoEffect.tempoMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tempo` const `tempoMax` is accepted by toFilterString', () {
        final s = AtempoEffect(enabled: true, tempo: AtempoEffect.tempoMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `tempo` const `tempoDefault` is accepted by toFilterString',
        () {
          final s = AtempoEffect(
            enabled: true,
            tempo: AtempoEffect.tempoDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AtiltEffect (atilt)', () {
      test('disabled → drops out of the chain', () {
        const fx = [AtiltEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [AtiltEffect()];
        expect(audioEffectsChain(fx), '@aek_atilt_0:lavfi-atilt');
      });

      test('param `freq` lands in wire when set to a non-default value', () {
        final s = const AtiltEffect(enabled: true, freq: 192000.0);
        expect(s.toFilterString(), contains('freq='));
        expect(s.toFilterString(), contains('freq=192000.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AtiltEffect(enabled: true, level: 4.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=4.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AtiltEffect(enabled: true, order: 30);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=30'));
      });

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const AtiltEffect(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const AtiltEffect(enabled: true, width: 10000.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=10000.000'));
      });

      test('param `freq` const `freqMin` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, freq: AtiltEffect.freqMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `freq` const `freqMax` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, freq: AtiltEffect.freqMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `freq` const `freqDefault` is accepted by toFilterString',
        () {
          final s = AtiltEffect(enabled: true, freq: AtiltEffect.freqDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, level: AtiltEffect.levelMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, level: AtiltEffect.levelMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AtiltEffect(enabled: true, level: AtiltEffect.levelDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, order: AtiltEffect.orderMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, order: AtiltEffect.orderMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AtiltEffect(enabled: true, order: AtiltEffect.orderDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, slope: AtiltEffect.slopeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, slope: AtiltEffect.slopeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = AtiltEffect(enabled: true, slope: AtiltEffect.slopeDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, width: AtiltEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = AtiltEffect(enabled: true, width: AtiltEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = AtiltEffect(enabled: true, width: AtiltEffect.widthDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BandpassEffect (bandpass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [BandpassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [BandpassEffect()];
        expect(audioEffectsChain(fx), '@aek_bandpass_0:lavfi-bandpass');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `csg` lands in wire when set to a non-default value', () {
        final s = const BandpassEffect(enabled: true, csg: true);
        expect(s.toFilterString(), contains('csg='));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BandpassEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(
            enabled: true,
            precision: BandpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(
            enabled: true,
            transform: BandpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BandpassEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BandpassEffect(
            enabled: true,
            widthType: BandpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            blocksize: BandpassEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            blocksize: BandpassEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            blocksize: BandpassEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            frequency: BandpassEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            frequency: BandpassEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            frequency: BandpassEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BandpassEffect(enabled: true, mix: BandpassEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BandpassEffect(enabled: true, mix: BandpassEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BandpassEffect(enabled: true, mix: BandpassEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BandpassEffect(enabled: true, width: BandpassEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BandpassEffect(enabled: true, width: BandpassEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BandpassEffect(
            enabled: true,
            width: BandpassEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BandrejectEffect (bandreject)', () {
      test('disabled → drops out of the chain', () {
        const fx = [BandrejectEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [BandrejectEffect()];
        expect(audioEffectsChain(fx), '@aek_bandreject_0:lavfi-bandreject');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BandrejectEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(
            enabled: true,
            precision: BandrejectPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(
            enabled: true,
            transform: BandrejectTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BandrejectEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectEffect(
            enabled: true,
            widthType: BandrejectWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            blocksize: BandrejectEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            blocksize: BandrejectEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            blocksize: BandrejectEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            frequency: BandrejectEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            frequency: BandrejectEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            frequency: BandrejectEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BandrejectEffect(enabled: true, mix: BandrejectEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BandrejectEffect(enabled: true, mix: BandrejectEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BandrejectEffect(
          enabled: true,
          mix: BandrejectEffect.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BandrejectEffect(
          enabled: true,
          width: BandrejectEffect.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BandrejectEffect(
          enabled: true,
          width: BandrejectEffect.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BandrejectEffect(
            enabled: true,
            width: BandrejectEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BassEffect (bass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [BassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [BassEffect()];
        expect(audioEffectsChain(fx), '@aek_bass_0:lavfi-bass');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(enabled: true, channels: 'wire_test_alt');
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const BassEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BassEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const BassEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(
            enabled: true,
            precision: BassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(
            enabled: true,
            transform: BassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BassEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BassEffect(enabled: true, widthType: BassWidthType.h);
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            blocksize: BassEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            blocksize: BassEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            blocksize: BassEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            frequency: BassEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            frequency: BassEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BassEffect(
            enabled: true,
            frequency: BassEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, gain: BassEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, gain: BassEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = BassEffect(enabled: true, gain: BassEffect.gainDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, mix: BassEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, mix: BassEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, mix: BassEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, poles: BassEffect.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, poles: BassEffect.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = BassEffect(enabled: true, poles: BassEffect.polesDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, width: BassEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BassEffect(enabled: true, width: BassEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BassEffect(enabled: true, width: BassEffect.widthDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BiquadEffect (biquad)', () {
      test('disabled → drops out of the chain', () {
        const fx = [BiquadEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [BiquadEffect()];
        expect(audioEffectsChain(fx), '@aek_biquad_0:lavfi-biquad');
      });

      test('param `a0` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, a0: 2147483647.0);
        expect(s.toFilterString(), contains('a0='));
        expect(s.toFilterString(), contains('a0=2147483647.000'));
      });

      test('param `a1` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, a1: 2147483647.0);
        expect(s.toFilterString(), contains('a1='));
        expect(s.toFilterString(), contains('a1=2147483647.000'));
      });

      test('param `a2` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, a2: 2147483647.0);
        expect(s.toFilterString(), contains('a2='));
        expect(s.toFilterString(), contains('a2=2147483647.000'));
      });

      test('param `b0` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, b0: 2147483647.0);
        expect(s.toFilterString(), contains('b0='));
        expect(s.toFilterString(), contains('b0=2147483647.000'));
      });

      test('param `b1` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, b1: 2147483647.0);
        expect(s.toFilterString(), contains('b1='));
        expect(s.toFilterString(), contains('b1=2147483647.000'));
      });

      test('param `b2` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, b2: 2147483647.0);
        expect(s.toFilterString(), contains('b2='));
        expect(s.toFilterString(), contains('b2=2147483647.000'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BiquadEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BiquadEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BiquadEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BiquadEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BiquadEffect(
            enabled: true,
            precision: BiquadPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BiquadEffect(
            enabled: true,
            transform: BiquadTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `a0` const `a0Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a0: BiquadEffect.a0Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a0` const `a0Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a0: BiquadEffect.a0Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a0` const `a0Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a0: BiquadEffect.a0Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a1: BiquadEffect.a1Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a1: BiquadEffect.a1Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a1: BiquadEffect.a1Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a2: BiquadEffect.a2Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a2: BiquadEffect.a2Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, a2: BiquadEffect.a2Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b0: BiquadEffect.b0Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b0: BiquadEffect.b0Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b0: BiquadEffect.b0Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b1: BiquadEffect.b1Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b1: BiquadEffect.b1Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b1: BiquadEffect.b1Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Min` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b2: BiquadEffect.b2Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Max` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b2: BiquadEffect.b2Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Default` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, b2: BiquadEffect.b2Default);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BiquadEffect(
            enabled: true,
            blocksize: BiquadEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BiquadEffect(
            enabled: true,
            blocksize: BiquadEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BiquadEffect(
            enabled: true,
            blocksize: BiquadEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, mix: BiquadEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, mix: BiquadEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BiquadEffect(enabled: true, mix: BiquadEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('ChannelmapEffect (channelmap)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ChannelmapEffect(enabled: false, map: '0|1')];
        expect(audioEffectsChain(fx), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = [ChannelmapEffect(map: '0|1')];
          expect(
            audioEffectsChain(fx),
            startsWith('@aek_channelmap_0:lavfi-channelmap'),
          );
          expect(audioEffectsChain(fx), contains('map='));
        },
      );

      test(
        'param `channel_layout` lands in wire when set to a non-default value',
        () {
          final s = const ChannelmapEffect(
            enabled: true,
            channelLayout: 'wire_test_alt',
            map: '0|1',
          );
          expect(s.toFilterString(), contains('channel_layout='));
        },
      );

      test('param `map` lands in wire when set to a non-default value', () {
        final s = const ChannelmapEffect(enabled: true, map: 'wire_test_alt');
        expect(s.toFilterString(), contains('map='));
      });
    });
    group('ChorusEffect (chorus)', () {
      test('disabled → drops out of the chain', () {
        const fx = [
          ChorusEffect(
            enabled: false,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          ),
        ];
        expect(audioEffectsChain(fx), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = [
            ChorusEffect(
              delays: '55|60',
              decays: '0.4|0.32',
              speeds: '0.25|0.4',
              depths: '2|1.3',
            ),
          ];
          expect(
            audioEffectsChain(fx),
            startsWith('@aek_chorus_0:lavfi-chorus'),
          );
          expect(audioEffectsChain(fx), contains('delays='));
          expect(audioEffectsChain(fx), contains('decays='));
          expect(audioEffectsChain(fx), contains('speeds='));
          expect(audioEffectsChain(fx), contains('depths='));
        },
      );

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const ChorusEffect(
          enabled: true,
          decays: 'wire_test_alt',
          delays: '55|60',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const ChorusEffect(
          enabled: true,
          delays: 'wire_test_alt',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('delays='));
      });

      test('param `depths` lands in wire when set to a non-default value', () {
        final s = const ChorusEffect(
          enabled: true,
          depths: 'wire_test_alt',
          delays: '55|60',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
        );
        expect(s.toFilterString(), contains('depths='));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const ChorusEffect(
          enabled: true,
          inGain: 1.0,
          delays: '55|60',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test(
        'param `out_gain` lands in wire when set to a non-default value',
        () {
          final s = const ChorusEffect(
            enabled: true,
            outGain: 1.0,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString(), contains('out_gain='));
          expect(s.toFilterString(), contains('out_gain=1.000'));
        },
      );

      test('param `speeds` lands in wire when set to a non-default value', () {
        final s = const ChorusEffect(
          enabled: true,
          speeds: 'wire_test_alt',
          delays: '55|60',
          decays: '0.4|0.32',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('speeds='));
      });

      test(
        'param `in_gain` const `inGainMin` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            inGain: ChorusEffect.inGainMin,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainMax` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            inGain: ChorusEffect.inGainMax,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `inGainDefault` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            inGain: ChorusEffect.inGainDefault,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMin` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            outGain: ChorusEffect.outGainMin,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainMax` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            outGain: ChorusEffect.outGainMax,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `outGainDefault` is accepted by toFilterString',
        () {
          final s = ChorusEffect(
            enabled: true,
            outGain: ChorusEffect.outGainDefault,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('CompandEffect (compand)', () {
      test('disabled → drops out of the chain', () {
        const fx = [CompandEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [CompandEffect()];
        expect(audioEffectsChain(fx), '@aek_compand_0:lavfi-compand');
      });

      test('param `attacks` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, attacks: 'wire_test_alt');
        expect(s.toFilterString(), contains('attacks='));
      });

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, decays: 'wire_test_alt');
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, delay: 20.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=20.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `points` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, points: 'wire_test_alt');
        expect(s.toFilterString(), contains('points='));
      });

      test('param `volume` lands in wire when set to a non-default value', () {
        final s = const CompandEffect(enabled: true, volume: -900.0);
        expect(s.toFilterString(), contains('volume='));
        expect(s.toFilterString(), contains('volume=-900.000'));
      });

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = CompandEffect(enabled: true, delay: CompandEffect.delayMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = CompandEffect(enabled: true, delay: CompandEffect.delayMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = CompandEffect(
            enabled: true,
            delay: CompandEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = CompandEffect(enabled: true, gain: CompandEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = CompandEffect(enabled: true, gain: CompandEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = CompandEffect(
            enabled: true,
            gain: CompandEffect.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeMin` is accepted by toFilterString',
        () {
          final s = CompandEffect(
            enabled: true,
            volume: CompandEffect.volumeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeMax` is accepted by toFilterString',
        () {
          final s = CompandEffect(
            enabled: true,
            volume: CompandEffect.volumeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeDefault` is accepted by toFilterString',
        () {
          final s = CompandEffect(
            enabled: true,
            volume: CompandEffect.volumeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('digit-prefix param `soft-knee` lands in wire via params map', () {
        final s = const CompandEffect(
          enabled: true,
          params: {'soft-knee': 900.0},
        );
        expect(s.toFilterString(), contains('soft-knee='));
        expect(s.toFilterString(), contains('soft-knee=900.000'));
      });
    });
    group('CompensationdelayEffect (compensationdelay)', () {
      test('disabled → drops out of the chain', () {
        const fx = [CompensationdelayEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [CompensationdelayEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_compensationdelay_0:lavfi-compensationdelay',
        );
      });

      test('param `cm` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, cm: 100);
        expect(s.toFilterString(), contains('cm='));
        expect(s.toFilterString(), contains('cm=100'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, dry: 1.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=1.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, m: 100);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=100'));
      });

      test('param `mm` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, mm: 10);
        expect(s.toFilterString(), contains('mm='));
        expect(s.toFilterString(), contains('mm=10'));
      });

      test('param `temp` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, temp: 50);
        expect(s.toFilterString(), contains('temp='));
        expect(s.toFilterString(), contains('temp=50'));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const CompensationdelayEffect(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `cm` const `cmMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          cm: CompensationdelayEffect.cmMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `cm` const `cmMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          cm: CompensationdelayEffect.cmMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `cm` const `cmDefault` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          cm: CompensationdelayEffect.cmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          dry: CompensationdelayEffect.dryMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          dry: CompensationdelayEffect.dryMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          dry: CompensationdelayEffect.dryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          m: CompensationdelayEffect.mMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          m: CompensationdelayEffect.mMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          m: CompensationdelayEffect.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          mm: CompensationdelayEffect.mmMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          mm: CompensationdelayEffect.mmMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmDefault` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          mm: CompensationdelayEffect.mmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `temp` const `tempMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          temp: CompensationdelayEffect.tempMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `temp` const `tempMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          temp: CompensationdelayEffect.tempMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `temp` const `tempDefault` is accepted by toFilterString',
        () {
          final s = CompensationdelayEffect(
            enabled: true,
            temp: CompensationdelayEffect.tempDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          wet: CompensationdelayEffect.wetMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          wet: CompensationdelayEffect.wetMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = CompensationdelayEffect(
          enabled: true,
          wet: CompensationdelayEffect.wetDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('CrossfeedEffect (crossfeed)', () {
      test('disabled → drops out of the chain', () {
        const fx = [CrossfeedEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [CrossfeedEffect()];
        expect(audioEffectsChain(fx), '@aek_crossfeed_0:lavfi-crossfeed');
      });

      test(
        'param `block_size` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedEffect(enabled: true, blockSize: 32768);
          expect(s.toFilterString(), contains('block_size='));
          expect(s.toFilterString(), contains('block_size=32768'));
        },
      );

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedEffect(enabled: true, levelIn: 1.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=1.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedEffect(enabled: true, levelOut: 0.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=0.000'));
        },
      );

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const CrossfeedEffect(enabled: true, range: 1.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=1.000'));
      });

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const CrossfeedEffect(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedEffect(enabled: true, strength: 1.0);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=1.000'));
        },
      );

      test(
        'param `block_size` const `blockSizeMin` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            blockSize: CrossfeedEffect.blockSizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `block_size` const `blockSizeMax` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            blockSize: CrossfeedEffect.blockSizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `block_size` const `blockSizeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            blockSize: CrossfeedEffect.blockSizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelIn: CrossfeedEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelIn: CrossfeedEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelIn: CrossfeedEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelOut: CrossfeedEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelOut: CrossfeedEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            levelOut: CrossfeedEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = CrossfeedEffect(
          enabled: true,
          range: CrossfeedEffect.rangeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = CrossfeedEffect(
          enabled: true,
          range: CrossfeedEffect.rangeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            range: CrossfeedEffect.rangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = CrossfeedEffect(
          enabled: true,
          slope: CrossfeedEffect.slopeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = CrossfeedEffect(
          enabled: true,
          slope: CrossfeedEffect.slopeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            slope: CrossfeedEffect.slopeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            strength: CrossfeedEffect.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            strength: CrossfeedEffect.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedEffect(
            enabled: true,
            strength: CrossfeedEffect.strengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('CrystalizerEffect (crystalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [CrystalizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [CrystalizerEffect()];
        expect(audioEffectsChain(fx), '@aek_crystalizer_0:lavfi-crystalizer');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const CrystalizerEffect(enabled: true, c: false);
        expect(s.toFilterString(), contains('c='));
      });

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const CrystalizerEffect(enabled: true, i: 10.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=10.000'));
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = CrystalizerEffect(enabled: true, i: CrystalizerEffect.iMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = CrystalizerEffect(enabled: true, i: CrystalizerEffect.iMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = CrystalizerEffect(
          enabled: true,
          i: CrystalizerEffect.iDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('DcshiftEffect (dcshift)', () {
      test('disabled → drops out of the chain', () {
        const fx = [DcshiftEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [DcshiftEffect()];
        expect(audioEffectsChain(fx), '@aek_dcshift_0:lavfi-dcshift');
      });

      test(
        'param `limitergain` lands in wire when set to a non-default value',
        () {
          final s = const DcshiftEffect(enabled: true, limitergain: 1.0);
          expect(s.toFilterString(), contains('limitergain='));
          expect(s.toFilterString(), contains('limitergain=1.000'));
        },
      );

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const DcshiftEffect(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });

      test(
        'param `limitergain` const `limitergainMin` is accepted by toFilterString',
        () {
          final s = DcshiftEffect(
            enabled: true,
            limitergain: DcshiftEffect.limitergainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `limitergain` const `limitergainMax` is accepted by toFilterString',
        () {
          final s = DcshiftEffect(
            enabled: true,
            limitergain: DcshiftEffect.limitergainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `limitergain` const `limitergainDefault` is accepted by toFilterString',
        () {
          final s = DcshiftEffect(
            enabled: true,
            limitergain: DcshiftEffect.limitergainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = DcshiftEffect(enabled: true, shift: DcshiftEffect.shiftMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = DcshiftEffect(enabled: true, shift: DcshiftEffect.shiftMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = DcshiftEffect(
            enabled: true,
            shift: DcshiftEffect.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DeesserEffect (deesser)', () {
      test('disabled → drops out of the chain', () {
        const fx = [DeesserEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [DeesserEffect()];
        expect(audioEffectsChain(fx), '@aek_deesser_0:lavfi-deesser');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const DeesserEffect(enabled: true, f: 1.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=1.000'));
      });

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const DeesserEffect(enabled: true, i: 1.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=1.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const DeesserEffect(enabled: true, m: 1.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=1.000'));
      });

      test('param `s` lands in wire when set to a non-default value', () {
        final s = const DeesserEffect(enabled: true, s: DeesserMode.i);
        expect(s.toFilterString(), contains('s='));
        expect(s.toFilterString(), contains('s=i'));
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, f: DeesserEffect.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, f: DeesserEffect.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, f: DeesserEffect.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, i: DeesserEffect.iMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, i: DeesserEffect.iMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, i: DeesserEffect.iDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, m: DeesserEffect.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, m: DeesserEffect.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = DeesserEffect(enabled: true, m: DeesserEffect.mDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('DialoguenhanceEffect (dialoguenhance)', () {
      test('disabled → drops out of the chain', () {
        const fx = [DialoguenhanceEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [DialoguenhanceEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_dialoguenhance_0:lavfi-dialoguenhance',
        );
      });

      test('param `enhance` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceEffect(enabled: true, enhance: 3.0);
        expect(s.toFilterString(), contains('enhance='));
        expect(s.toFilterString(), contains('enhance=3.000'));
      });

      test(
        'param `original` lands in wire when set to a non-default value',
        () {
          final s = const DialoguenhanceEffect(enabled: true, original: 0.0);
          expect(s.toFilterString(), contains('original='));
          expect(s.toFilterString(), contains('original=0.000'));
        },
      );

      test('param `voice` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceEffect(enabled: true, voice: 32.0);
        expect(s.toFilterString(), contains('voice='));
        expect(s.toFilterString(), contains('voice=32.000'));
      });

      test(
        'param `enhance` const `enhanceMin` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            enhance: DialoguenhanceEffect.enhanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `enhance` const `enhanceMax` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            enhance: DialoguenhanceEffect.enhanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `enhance` const `enhanceDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            enhance: DialoguenhanceEffect.enhanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalMin` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            original: DialoguenhanceEffect.originalMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalMax` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            original: DialoguenhanceEffect.originalMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            original: DialoguenhanceEffect.originalDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `voice` const `voiceMin` is accepted by toFilterString', () {
        final s = DialoguenhanceEffect(
          enabled: true,
          voice: DialoguenhanceEffect.voiceMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `voice` const `voiceMax` is accepted by toFilterString', () {
        final s = DialoguenhanceEffect(
          enabled: true,
          voice: DialoguenhanceEffect.voiceMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `voice` const `voiceDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceEffect(
            enabled: true,
            voice: DialoguenhanceEffect.voiceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DrmeterEffect (drmeter)', () {
      test('disabled → drops out of the chain', () {
        const fx = [DrmeterEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [DrmeterEffect()];
        expect(audioEffectsChain(fx), '@aek_drmeter_0:lavfi-drmeter');
      });

      test('param `length` lands in wire when set to a non-default value', () {
        final s = const DrmeterEffect(enabled: true, length: 10.0);
        expect(s.toFilterString(), contains('length='));
        expect(s.toFilterString(), contains('length=10.000'));
      });

      test(
        'param `length` const `lengthMin` is accepted by toFilterString',
        () {
          final s = DrmeterEffect(
            enabled: true,
            length: DrmeterEffect.lengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `length` const `lengthMax` is accepted by toFilterString',
        () {
          final s = DrmeterEffect(
            enabled: true,
            length: DrmeterEffect.lengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `length` const `lengthDefault` is accepted by toFilterString',
        () {
          final s = DrmeterEffect(
            enabled: true,
            length: DrmeterEffect.lengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DynaudnormEffect (dynaudnorm)', () {
      test('disabled → drops out of the chain', () {
        const fx = [DynaudnormEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [DynaudnormEffect()];
        expect(audioEffectsChain(fx), '@aek_dynaudnorm_0:lavfi-dynaudnorm');
      });

      test(
        'param `altboundary` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, altboundary: true);
          expect(s.toFilterString(), contains('altboundary='));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `compress` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, compress: 30.0);
          expect(s.toFilterString(), contains('compress='));
          expect(s.toFilterString(), contains('compress=30.000'));
        },
      );

      test(
        'param `correctdc` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, correctdc: true);
          expect(s.toFilterString(), contains('correctdc='));
        },
      );

      test(
        'param `coupling` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, coupling: false);
          expect(s.toFilterString(), contains('coupling='));
        },
      );

      test('param `curve` lands in wire when set to a non-default value', () {
        final s = const DynaudnormEffect(enabled: true, curve: 'wire_test_alt');
        expect(s.toFilterString(), contains('curve='));
      });

      test(
        'param `framelen` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, framelen: 8000);
          expect(s.toFilterString(), contains('framelen='));
          expect(s.toFilterString(), contains('framelen=8000'));
        },
      );

      test(
        'param `gausssize` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, gausssize: 301);
          expect(s.toFilterString(), contains('gausssize='));
          expect(s.toFilterString(), contains('gausssize=301'));
        },
      );

      test('param `maxgain` lands in wire when set to a non-default value', () {
        final s = const DynaudnormEffect(enabled: true, maxgain: 100.0);
        expect(s.toFilterString(), contains('maxgain='));
        expect(s.toFilterString(), contains('maxgain=100.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const DynaudnormEffect(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const DynaudnormEffect(enabled: true, peak: 1.0);
        expect(s.toFilterString(), contains('peak='));
        expect(s.toFilterString(), contains('peak=1.000'));
      });

      test(
        'param `targetrms` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, targetrms: 1.0);
          expect(s.toFilterString(), contains('targetrms='));
          expect(s.toFilterString(), contains('targetrms=1.000'));
        },
      );

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormEffect(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `compress` const `compressMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            compress: DynaudnormEffect.compressMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compress` const `compressMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            compress: DynaudnormEffect.compressMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compress` const `compressDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            compress: DynaudnormEffect.compressDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `framelen` const `framelenMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            framelen: DynaudnormEffect.framelenMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `framelen` const `framelenMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            framelen: DynaudnormEffect.framelenMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `framelen` const `framelenDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            framelen: DynaudnormEffect.framelenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gausssize` const `gausssizeMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            gausssize: DynaudnormEffect.gausssizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gausssize` const `gausssizeMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            gausssize: DynaudnormEffect.gausssizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gausssize` const `gausssizeDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            gausssize: DynaudnormEffect.gausssizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `maxgain` const `maxgainMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            maxgain: DynaudnormEffect.maxgainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `maxgain` const `maxgainMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            maxgain: DynaudnormEffect.maxgainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `maxgain` const `maxgainDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            maxgain: DynaudnormEffect.maxgainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            overlap: DynaudnormEffect.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            overlap: DynaudnormEffect.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            overlap: DynaudnormEffect.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `peak` const `peakMin` is accepted by toFilterString', () {
        final s = DynaudnormEffect(
          enabled: true,
          peak: DynaudnormEffect.peakMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMax` is accepted by toFilterString', () {
        final s = DynaudnormEffect(
          enabled: true,
          peak: DynaudnormEffect.peakMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `peak` const `peakDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            peak: DynaudnormEffect.peakDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `targetrms` const `targetrmsMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            targetrms: DynaudnormEffect.targetrmsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `targetrms` const `targetrmsMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            targetrms: DynaudnormEffect.targetrmsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `targetrms` const `targetrmsDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            targetrms: DynaudnormEffect.targetrmsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            threshold: DynaudnormEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            threshold: DynaudnormEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormEffect(
            enabled: true,
            threshold: DynaudnormEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('EarwaxEffect (earwax)', () {
      test('disabled → drops out of the chain', () {
        const fx = [EarwaxEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [EarwaxEffect()];
        expect(audioEffectsChain(fx), '@aek_earwax_0:lavfi-earwax');
      });
    });
    group('Ebur128Effect (ebur128)', () {
      test('disabled → drops out of the chain', () {
        const fx = [Ebur128Effect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [Ebur128Effect()];
        expect(audioEffectsChain(fx), '@aek_ebur128_0:lavfi-ebur128');
      });

      test(
        'param `dualmono` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Effect(enabled: true, dualmono: true);
          expect(s.toFilterString(), contains('dualmono='));
        },
      );

      test(
        'param `framelog` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Effect(
            enabled: true,
            framelog: Ebur128Level.info,
          );
          expect(s.toFilterString(), contains('framelog='));
          expect(s.toFilterString(), contains('framelog=info'));
        },
      );

      test('param `gauge` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, gauge: Ebur128Gaugetype.m);
        expect(s.toFilterString(), contains('gauge='));
        expect(s.toFilterString(), contains('gauge=m'));
      });

      test(
        'param `metadata` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Effect(enabled: true, metadata: true);
          expect(s.toFilterString(), contains('metadata='));
        },
      );

      test('param `meter` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, meter: 18);
        expect(s.toFilterString(), contains('meter='));
        expect(s.toFilterString(), contains('meter=18'));
      });

      test('param `panlaw` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, panlaw: 0.0);
        expect(s.toFilterString(), contains('panlaw='));
        expect(s.toFilterString(), contains('panlaw=0.000'));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(
          enabled: true,
          peak: const {Ebur128Mode.none},
        );
        expect(s.toFilterString(), contains('peak='));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(
          enabled: true,
          scale: Ebur128Scaletype.lufs,
        );
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=LUFS'));
      });

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, size: 'wire_test_alt');
        expect(s.toFilterString(), contains('size='));
      });

      test('param `target` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, target: 0);
        expect(s.toFilterString(), contains('target='));
        expect(s.toFilterString(), contains('target=0'));
      });

      test('param `video` lands in wire when set to a non-default value', () {
        final s = const Ebur128Effect(enabled: true, video: true);
        expect(s.toFilterString(), contains('video='));
      });

      test('param `meter` const `meterMin` is accepted by toFilterString', () {
        final s = Ebur128Effect(enabled: true, meter: Ebur128Effect.meterMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `meter` const `meterMax` is accepted by toFilterString', () {
        final s = Ebur128Effect(enabled: true, meter: Ebur128Effect.meterMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `meter` const `meterDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            meter: Ebur128Effect.meterDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawMin` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            panlaw: Ebur128Effect.panlawMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawMax` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            panlaw: Ebur128Effect.panlawMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            panlaw: Ebur128Effect.panlawDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetMin` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            target: Ebur128Effect.targetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetMax` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            target: Ebur128Effect.targetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Effect(
            enabled: true,
            target: Ebur128Effect.targetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('EqualizerEffect (equalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [EqualizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [EqualizerEffect()];
        expect(audioEffectsChain(fx), '@aek_equalizer_0:lavfi-equalizer');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const EqualizerEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const EqualizerEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(
            enabled: true,
            precision: EqualizerPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(
            enabled: true,
            transform: EqualizerTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const EqualizerEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerEffect(
            enabled: true,
            widthType: EqualizerWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            blocksize: EqualizerEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            blocksize: EqualizerEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            blocksize: EqualizerEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            frequency: EqualizerEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            frequency: EqualizerEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            frequency: EqualizerEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = EqualizerEffect(enabled: true, gain: EqualizerEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = EqualizerEffect(enabled: true, gain: EqualizerEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            gain: EqualizerEffect.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = EqualizerEffect(enabled: true, mix: EqualizerEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = EqualizerEffect(enabled: true, mix: EqualizerEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = EqualizerEffect(
          enabled: true,
          mix: EqualizerEffect.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = EqualizerEffect(
          enabled: true,
          width: EqualizerEffect.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = EqualizerEffect(
          enabled: true,
          width: EqualizerEffect.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = EqualizerEffect(
            enabled: true,
            width: EqualizerEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ExtrastereoEffect (extrastereo)', () {
      test('disabled → drops out of the chain', () {
        const fx = [ExtrastereoEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [ExtrastereoEffect()];
        expect(audioEffectsChain(fx), '@aek_extrastereo_0:lavfi-extrastereo');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const ExtrastereoEffect(enabled: true, c: false);
        expect(s.toFilterString(), contains('c='));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const ExtrastereoEffect(enabled: true, m: 10.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=10.000'));
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = ExtrastereoEffect(enabled: true, m: ExtrastereoEffect.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = ExtrastereoEffect(enabled: true, m: ExtrastereoEffect.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = ExtrastereoEffect(
          enabled: true,
          m: ExtrastereoEffect.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('FirequalizerEffect (firequalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [FirequalizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [FirequalizerEffect()];
        expect(audioEffectsChain(fx), '@aek_firequalizer_0:lavfi-firequalizer');
      });

      test(
        'param `accuracy` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(
            enabled: true,
            accuracy: 10000000000.0,
          );
          expect(s.toFilterString(), contains('accuracy='));
          expect(s.toFilterString(), contains('accuracy=10000000000.000'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(enabled: true, delay: 10000000000.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=10000000000.000'));
      });

      test(
        'param `dumpfile` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(
            enabled: true,
            dumpfile: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('dumpfile='));
        },
      );

      test(
        'param `dumpscale` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(
            enabled: true,
            dumpscale: FirequalizerScale.linlin,
          );
          expect(s.toFilterString(), contains('dumpscale='));
          expect(s.toFilterString(), contains('dumpscale=linlin'));
        },
      );

      test('param `fft2` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(enabled: true, fft2: true);
        expect(s.toFilterString(), contains('fft2='));
      });

      test('param `fixed` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(enabled: true, fixed: true);
        expect(s.toFilterString(), contains('fixed='));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(
          enabled: true,
          gain: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('gain='));
      });

      test(
        'param `gain_entry` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(
            enabled: true,
            gainEntry: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('gain_entry='));
        },
      );

      test(
        'param `min_phase` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(enabled: true, minPhase: true);
          expect(s.toFilterString(), contains('min_phase='));
        },
      );

      test('param `multi` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(enabled: true, multi: true);
        expect(s.toFilterString(), contains('multi='));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(
          enabled: true,
          scale: FirequalizerScale.linlin,
        );
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=linlin'));
      });

      test('param `wfunc` lands in wire when set to a non-default value', () {
        final s = const FirequalizerEffect(
          enabled: true,
          wfunc: FirequalizerWfunc.rectangular,
        );
        expect(s.toFilterString(), contains('wfunc='));
        expect(s.toFilterString(), contains('wfunc=rectangular'));
      });

      test(
        'param `zero_phase` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerEffect(enabled: true, zeroPhase: true);
          expect(s.toFilterString(), contains('zero_phase='));
        },
      );

      test(
        'param `accuracy` const `accuracyMin` is accepted by toFilterString',
        () {
          final s = FirequalizerEffect(
            enabled: true,
            accuracy: FirequalizerEffect.accuracyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `accuracy` const `accuracyMax` is accepted by toFilterString',
        () {
          final s = FirequalizerEffect(
            enabled: true,
            accuracy: FirequalizerEffect.accuracyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `accuracy` const `accuracyDefault` is accepted by toFilterString',
        () {
          final s = FirequalizerEffect(
            enabled: true,
            accuracy: FirequalizerEffect.accuracyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = FirequalizerEffect(
          enabled: true,
          delay: FirequalizerEffect.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = FirequalizerEffect(
          enabled: true,
          delay: FirequalizerEffect.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = FirequalizerEffect(
            enabled: true,
            delay: FirequalizerEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('FlangerEffect (flanger)', () {
      test('disabled → drops out of the chain', () {
        const fx = [FlangerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [FlangerEffect()];
        expect(audioEffectsChain(fx), '@aek_flanger_0:lavfi-flanger');
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, delay: 30.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=30.000'));
      });

      test('param `depth` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, depth: 10.0);
        expect(s.toFilterString(), contains('depth='));
        expect(s.toFilterString(), contains('depth=10.000'));
      });

      test('param `interp` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(
          enabled: true,
          interp: FlangerItype.quadratic,
        );
        expect(s.toFilterString(), contains('interp='));
        expect(s.toFilterString(), contains('interp=quadratic'));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, phase: 100.0);
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=100.000'));
      });

      test('param `regen` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, regen: 95.0);
        expect(s.toFilterString(), contains('regen='));
        expect(s.toFilterString(), contains('regen=95.000'));
      });

      test('param `shape` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(
          enabled: true,
          shape: FlangerType.triangular,
        );
        expect(s.toFilterString(), contains('shape='));
        expect(s.toFilterString(), contains('shape=triangular'));
      });

      test('param `speed` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, speed: 10.0);
        expect(s.toFilterString(), contains('speed='));
        expect(s.toFilterString(), contains('speed=10.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const FlangerEffect(enabled: true, width: 100.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=100.000'));
      });

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, delay: FlangerEffect.delayMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, delay: FlangerEffect.delayMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            delay: FlangerEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `depth` const `depthMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, depth: FlangerEffect.depthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `depth` const `depthMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, depth: FlangerEffect.depthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `depth` const `depthDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            depth: FlangerEffect.depthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `phase` const `phaseMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, phase: FlangerEffect.phaseMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `phase` const `phaseMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, phase: FlangerEffect.phaseMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `phase` const `phaseDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            phase: FlangerEffect.phaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `regen` const `regenMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, regen: FlangerEffect.regenMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `regen` const `regenMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, regen: FlangerEffect.regenMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `regen` const `regenDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            regen: FlangerEffect.regenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `speed` const `speedMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, speed: FlangerEffect.speedMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `speed` const `speedMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, speed: FlangerEffect.speedMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `speed` const `speedDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            speed: FlangerEffect.speedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, width: FlangerEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = FlangerEffect(enabled: true, width: FlangerEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = FlangerEffect(
            enabled: true,
            width: FlangerEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HaasEffect (haas)', () {
      test('disabled → drops out of the chain', () {
        const fx = [HaasEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [HaasEffect()];
        expect(audioEffectsChain(fx), '@aek_haas_0:lavfi-haas');
      });

      test(
        'param `left_balance` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, leftBalance: 1.0);
          expect(s.toFilterString(), contains('left_balance='));
          expect(s.toFilterString(), contains('left_balance=1.000'));
        },
      );

      test(
        'param `left_delay` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, leftDelay: 40.0);
          expect(s.toFilterString(), contains('left_delay='));
          expect(s.toFilterString(), contains('left_delay=40.000'));
        },
      );

      test(
        'param `left_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, leftGain: 64.0);
          expect(s.toFilterString(), contains('left_gain='));
          expect(s.toFilterString(), contains('left_gain=64.000'));
        },
      );

      test(
        'param `left_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, leftPhase: true);
          expect(s.toFilterString(), contains('left_phase='));
        },
      );

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test(
        'param `middle_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, middlePhase: true);
          expect(s.toFilterString(), contains('middle_phase='));
        },
      );

      test(
        'param `middle_source` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(
            enabled: true,
            middleSource: HaasSource.left,
          );
          expect(s.toFilterString(), contains('middle_source='));
          expect(s.toFilterString(), contains('middle_source=left'));
        },
      );

      test(
        'param `right_balance` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, rightBalance: -1.0);
          expect(s.toFilterString(), contains('right_balance='));
          expect(s.toFilterString(), contains('right_balance=-1.000'));
        },
      );

      test(
        'param `right_delay` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, rightDelay: 40.0);
          expect(s.toFilterString(), contains('right_delay='));
          expect(s.toFilterString(), contains('right_delay=40.000'));
        },
      );

      test(
        'param `right_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, rightGain: 64.0);
          expect(s.toFilterString(), contains('right_gain='));
          expect(s.toFilterString(), contains('right_gain=64.000'));
        },
      );

      test(
        'param `right_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, rightPhase: false);
          expect(s.toFilterString(), contains('right_phase='));
        },
      );

      test(
        'param `side_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasEffect(enabled: true, sideGain: 64.0);
          expect(s.toFilterString(), contains('side_gain='));
          expect(s.toFilterString(), contains('side_gain=64.000'));
        },
      );

      test(
        'param `left_balance` const `leftBalanceMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftBalance: HaasEffect.leftBalanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_balance` const `leftBalanceMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftBalance: HaasEffect.leftBalanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_balance` const `leftBalanceDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftBalance: HaasEffect.leftBalanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `leftDelayMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftDelay: HaasEffect.leftDelayMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `leftDelayMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftDelay: HaasEffect.leftDelayMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `leftDelayDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftDelay: HaasEffect.leftDelayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `leftGainMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, leftGain: HaasEffect.leftGainMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `leftGainMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, leftGain: HaasEffect.leftGainMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `leftGainDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            leftGain: HaasEffect.leftGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, levelIn: HaasEffect.levelInMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, levelIn: HaasEffect.levelInMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            levelIn: HaasEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, levelOut: HaasEffect.levelOutMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, levelOut: HaasEffect.levelOutMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            levelOut: HaasEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `rightBalanceMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightBalance: HaasEffect.rightBalanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `rightBalanceMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightBalance: HaasEffect.rightBalanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `rightBalanceDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightBalance: HaasEffect.rightBalanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `rightDelayMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightDelay: HaasEffect.rightDelayMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `rightDelayMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightDelay: HaasEffect.rightDelayMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `rightDelayDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightDelay: HaasEffect.rightDelayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `rightGainMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightGain: HaasEffect.rightGainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `rightGainMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightGain: HaasEffect.rightGainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `rightGainDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            rightGain: HaasEffect.rightGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `sideGainMin` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, sideGain: HaasEffect.sideGainMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `sideGainMax` is accepted by toFilterString',
        () {
          final s = HaasEffect(enabled: true, sideGain: HaasEffect.sideGainMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `sideGainDefault` is accepted by toFilterString',
        () {
          final s = HaasEffect(
            enabled: true,
            sideGain: HaasEffect.sideGainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HdcdEffect (hdcd)', () {
      test('disabled → drops out of the chain', () {
        const fx = [HdcdEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [HdcdEffect()];
        expect(audioEffectsChain(fx), '@aek_hdcd_0:lavfi-hdcd');
      });

      test(
        'param `analyze_mode` lands in wire when set to a non-default value',
        () {
          final s = const HdcdEffect(
            enabled: true,
            analyzeMode: HdcdAnalyzeMode.lle,
          );
          expect(s.toFilterString(), contains('analyze_mode='));
          expect(s.toFilterString(), contains('analyze_mode=lle'));
        },
      );

      test(
        'param `bits_per_sample` lands in wire when set to a non-default value',
        () {
          final s = const HdcdEffect(
            enabled: true,
            bitsPerSample: HdcdBitsPerSample.n20,
          );
          expect(s.toFilterString(), contains('bits_per_sample='));
          expect(s.toFilterString(), contains('bits_per_sample=20'));
        },
      );

      test('param `cdt_ms` lands in wire when set to a non-default value', () {
        final s = const HdcdEffect(enabled: true, cdtMs: 60000);
        expect(s.toFilterString(), contains('cdt_ms='));
        expect(s.toFilterString(), contains('cdt_ms=60000'));
      });

      test(
        'param `disable_autoconvert` lands in wire when set to a non-default value',
        () {
          final s = const HdcdEffect(enabled: true, disableAutoconvert: false);
          expect(s.toFilterString(), contains('disable_autoconvert='));
        },
      );

      test(
        'param `force_pe` lands in wire when set to a non-default value',
        () {
          final s = const HdcdEffect(enabled: true, forcePe: true);
          expect(s.toFilterString(), contains('force_pe='));
        },
      );

      test(
        'param `process_stereo` lands in wire when set to a non-default value',
        () {
          final s = const HdcdEffect(enabled: true, processStereo: true);
          expect(s.toFilterString(), contains('process_stereo='));
        },
      );

      test('param `cdt_ms` const `cdtMsMin` is accepted by toFilterString', () {
        final s = HdcdEffect(enabled: true, cdtMs: HdcdEffect.cdtMsMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `cdt_ms` const `cdtMsMax` is accepted by toFilterString', () {
        final s = HdcdEffect(enabled: true, cdtMs: HdcdEffect.cdtMsMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `cdt_ms` const `cdtMsDefault` is accepted by toFilterString',
        () {
          final s = HdcdEffect(enabled: true, cdtMs: HdcdEffect.cdtMsDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HighpassEffect (highpass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [HighpassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [HighpassEffect()];
        expect(audioEffectsChain(fx), '@aek_highpass_0:lavfi-highpass');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const HighpassEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const HighpassEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(
            enabled: true,
            precision: HighpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(
            enabled: true,
            transform: HighpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const HighpassEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const HighpassEffect(
            enabled: true,
            widthType: HighpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            blocksize: HighpassEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            blocksize: HighpassEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            blocksize: HighpassEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            frequency: HighpassEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            frequency: HighpassEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            frequency: HighpassEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, mix: HighpassEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, mix: HighpassEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, mix: HighpassEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, poles: HighpassEffect.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, poles: HighpassEffect.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            poles: HighpassEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, width: HighpassEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = HighpassEffect(enabled: true, width: HighpassEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = HighpassEffect(
            enabled: true,
            width: HighpassEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HighshelfEffect (highshelf)', () {
      test('disabled → drops out of the chain', () {
        const fx = [HighshelfEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [HighshelfEffect()];
        expect(audioEffectsChain(fx), '@aek_highshelf_0:lavfi-highshelf');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const HighshelfEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const HighshelfEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const HighshelfEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(
            enabled: true,
            precision: HighshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(
            enabled: true,
            transform: HighshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const HighshelfEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfEffect(
            enabled: true,
            widthType: HighshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            blocksize: HighshelfEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            blocksize: HighshelfEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            blocksize: HighshelfEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            frequency: HighshelfEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            frequency: HighshelfEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            frequency: HighshelfEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = HighshelfEffect(enabled: true, gain: HighshelfEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = HighshelfEffect(enabled: true, gain: HighshelfEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            gain: HighshelfEffect.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = HighshelfEffect(enabled: true, mix: HighshelfEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = HighshelfEffect(enabled: true, mix: HighshelfEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = HighshelfEffect(
          enabled: true,
          mix: HighshelfEffect.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = HighshelfEffect(
          enabled: true,
          poles: HighshelfEffect.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = HighshelfEffect(
          enabled: true,
          poles: HighshelfEffect.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            poles: HighshelfEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = HighshelfEffect(
          enabled: true,
          width: HighshelfEffect.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = HighshelfEffect(
          enabled: true,
          width: HighshelfEffect.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = HighshelfEffect(
            enabled: true,
            width: HighshelfEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('LoudnormEffect (loudnorm)', () {
      test('disabled → drops out of the chain', () {
        const fx = [LoudnormEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [LoudnormEffect()];
        expect(audioEffectsChain(fx), '@aek_loudnorm_0:lavfi-loudnorm');
      });

      test(
        'param `dual_mono` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(enabled: true, dualMono: true);
          expect(s.toFilterString(), contains('dual_mono='));
        },
      );

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const LoudnormEffect(enabled: true, i: -5.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=-5.000'));
      });

      test('param `linear` lands in wire when set to a non-default value', () {
        final s = const LoudnormEffect(enabled: true, linear: false);
        expect(s.toFilterString(), contains('linear='));
      });

      test('param `lra` lands in wire when set to a non-default value', () {
        final s = const LoudnormEffect(enabled: true, lra: 50.0);
        expect(s.toFilterString(), contains('lra='));
        expect(s.toFilterString(), contains('lra=50.000'));
      });

      test(
        'param `measured_i` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(enabled: true, measuredI: -99.0);
          expect(s.toFilterString(), contains('measured_i='));
          expect(s.toFilterString(), contains('measured_i=-99.000'));
        },
      );

      test(
        'param `measured_lra` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(enabled: true, measuredLra: 99.0);
          expect(s.toFilterString(), contains('measured_lra='));
          expect(s.toFilterString(), contains('measured_lra=99.000'));
        },
      );

      test(
        'param `measured_thresh` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(enabled: true, measuredThresh: 0.0);
          expect(s.toFilterString(), contains('measured_thresh='));
          expect(s.toFilterString(), contains('measured_thresh=0.000'));
        },
      );

      test(
        'param `measured_tp` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(enabled: true, measuredTp: -99.0);
          expect(s.toFilterString(), contains('measured_tp='));
          expect(s.toFilterString(), contains('measured_tp=-99.000'));
        },
      );

      test('param `offset` lands in wire when set to a non-default value', () {
        final s = const LoudnormEffect(enabled: true, offset: 99.0);
        expect(s.toFilterString(), contains('offset='));
        expect(s.toFilterString(), contains('offset=99.000'));
      });

      test(
        'param `print_format` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(
            enabled: true,
            printFormat: LoudnormPrintFormat.json,
          );
          expect(s.toFilterString(), contains('print_format='));
          expect(s.toFilterString(), contains('print_format=json'));
        },
      );

      test(
        'param `stats_file` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormEffect(
            enabled: true,
            statsFile: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('stats_file='));
        },
      );

      test('param `tp` lands in wire when set to a non-default value', () {
        final s = const LoudnormEffect(enabled: true, tp: 0.0);
        expect(s.toFilterString(), contains('tp='));
        expect(s.toFilterString(), contains('tp=0.000'));
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, i: LoudnormEffect.iMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, i: LoudnormEffect.iMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, i: LoudnormEffect.iDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraMin` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, lra: LoudnormEffect.lraMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraMax` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, lra: LoudnormEffect.lraMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraDefault` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, lra: LoudnormEffect.lraDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `measured_i` const `measuredIMin` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredI: LoudnormEffect.measuredIMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_i` const `measuredIMax` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredI: LoudnormEffect.measuredIMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_i` const `measuredIDefault` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredI: LoudnormEffect.measuredIDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measuredLraMin` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredLra: LoudnormEffect.measuredLraMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measuredLraMax` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredLra: LoudnormEffect.measuredLraMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measuredLraDefault` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredLra: LoudnormEffect.measuredLraDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measuredThreshMin` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredThresh: LoudnormEffect.measuredThreshMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measuredThreshMax` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredThresh: LoudnormEffect.measuredThreshMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measuredThreshDefault` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredThresh: LoudnormEffect.measuredThreshDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measuredTpMin` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredTp: LoudnormEffect.measuredTpMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measuredTpMax` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredTp: LoudnormEffect.measuredTpMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measuredTpDefault` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            measuredTp: LoudnormEffect.measuredTpDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetMin` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            offset: LoudnormEffect.offsetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetMax` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            offset: LoudnormEffect.offsetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetDefault` is accepted by toFilterString',
        () {
          final s = LoudnormEffect(
            enabled: true,
            offset: LoudnormEffect.offsetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `tp` const `tpMin` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, tp: LoudnormEffect.tpMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tp` const `tpMax` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, tp: LoudnormEffect.tpMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tp` const `tpDefault` is accepted by toFilterString', () {
        final s = LoudnormEffect(enabled: true, tp: LoudnormEffect.tpDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('LowpassEffect (lowpass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [LowpassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [LowpassEffect()];
        expect(audioEffectsChain(fx), '@aek_lowpass_0:lavfi-lowpass');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const LowpassEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const LowpassEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(
            enabled: true,
            precision: LowpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(
            enabled: true,
            transform: LowpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const LowpassEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const LowpassEffect(
            enabled: true,
            widthType: LowpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            blocksize: LowpassEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            blocksize: LowpassEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            blocksize: LowpassEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            frequency: LowpassEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            frequency: LowpassEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            frequency: LowpassEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, mix: LowpassEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, mix: LowpassEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, mix: LowpassEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, poles: LowpassEffect.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, poles: LowpassEffect.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            poles: LowpassEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, width: LowpassEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = LowpassEffect(enabled: true, width: LowpassEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = LowpassEffect(
            enabled: true,
            width: LowpassEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('LowshelfEffect (lowshelf)', () {
      test('disabled → drops out of the chain', () {
        const fx = [LowshelfEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [LowshelfEffect()];
        expect(audioEffectsChain(fx), '@aek_lowshelf_0:lavfi-lowshelf');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const LowshelfEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const LowshelfEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const LowshelfEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(
            enabled: true,
            precision: LowshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(
            enabled: true,
            transform: LowshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const LowshelfEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfEffect(
            enabled: true,
            widthType: LowshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            blocksize: LowshelfEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            blocksize: LowshelfEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            blocksize: LowshelfEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            frequency: LowshelfEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            frequency: LowshelfEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            frequency: LowshelfEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, gain: LowshelfEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, gain: LowshelfEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            gain: LowshelfEffect.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, mix: LowshelfEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, mix: LowshelfEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, mix: LowshelfEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, poles: LowshelfEffect.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, poles: LowshelfEffect.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            poles: LowshelfEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, width: LowshelfEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = LowshelfEffect(enabled: true, width: LowshelfEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = LowshelfEffect(
            enabled: true,
            width: LowshelfEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('McompandEffect (mcompand)', () {
      test('disabled → drops out of the chain', () {
        const fx = [McompandEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [McompandEffect()];
        expect(audioEffectsChain(fx), '@aek_mcompand_0:lavfi-mcompand');
      });

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const McompandEffect(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('PanEffect (pan)', () {
      test('disabled → drops out of the chain', () {
        const fx = [PanEffect(enabled: false, args: 'stereo|c0=c0|c1=c1')];
        expect(audioEffectsChain(fx), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = [PanEffect(args: 'stereo|c0=c0|c1=c1')];
          expect(audioEffectsChain(fx), startsWith('@aek_pan_0:lavfi-pan'));
          expect(audioEffectsChain(fx), contains('args='));
        },
      );

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const PanEffect(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('RubberbandEffect (rubberband)', () {
      test('disabled → drops out of the chain', () {
        const fx = [RubberbandEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [RubberbandEffect()];
        expect(audioEffectsChain(fx), '@aek_rubberband_0:lavfi-rubberband');
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandEffect(
            enabled: true,
            channels: RubberbandChannels.together,
          );
          expect(s.toFilterString(), contains('channels='));
          expect(s.toFilterString(), contains('channels=together'));
        },
      );

      test(
        'param `detector` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandEffect(
            enabled: true,
            detector: RubberbandDetector.percussive,
          );
          expect(s.toFilterString(), contains('detector='));
          expect(s.toFilterString(), contains('detector=percussive'));
        },
      );

      test('param `formant` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(
          enabled: true,
          formant: RubberbandFormant.preserved,
        );
        expect(s.toFilterString(), contains('formant='));
        expect(s.toFilterString(), contains('formant=preserved'));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(
          enabled: true,
          phase: RubberbandPhase.independent,
        );
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=independent'));
      });

      test('param `pitch` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(enabled: true, pitch: 100.0);
        expect(s.toFilterString(), contains('pitch='));
        expect(s.toFilterString(), contains('pitch=100.000'));
      });

      test('param `pitchq` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(
          enabled: true,
          pitchq: RubberbandPitch.speed,
        );
        expect(s.toFilterString(), contains('pitchq='));
        expect(s.toFilterString(), contains('pitchq=speed'));
      });

      test(
        'param `smoothing` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandEffect(
            enabled: true,
            smoothing: RubberbandSmoothing.on_,
          );
          expect(s.toFilterString(), contains('smoothing='));
          expect(s.toFilterString(), contains('smoothing=on'));
        },
      );

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(enabled: true, tempo: 100.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=100.000'));
      });

      test(
        'param `transients` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandEffect(
            enabled: true,
            transients: RubberbandTransients.mixed,
          );
          expect(s.toFilterString(), contains('transients='));
          expect(s.toFilterString(), contains('transients=mixed'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const RubberbandEffect(
          enabled: true,
          window: RubberbandWindow.short,
        );
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=short'));
      });

      test('param `pitch` const `pitchMin` is accepted by toFilterString', () {
        final s = RubberbandEffect(
          enabled: true,
          pitch: RubberbandEffect.pitchMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `pitch` const `pitchMax` is accepted by toFilterString', () {
        final s = RubberbandEffect(
          enabled: true,
          pitch: RubberbandEffect.pitchMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `pitch` const `pitchDefault` is accepted by toFilterString',
        () {
          final s = RubberbandEffect(
            enabled: true,
            pitch: RubberbandEffect.pitchDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `tempo` const `tempoMin` is accepted by toFilterString', () {
        final s = RubberbandEffect(
          enabled: true,
          tempo: RubberbandEffect.tempoMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tempo` const `tempoMax` is accepted by toFilterString', () {
        final s = RubberbandEffect(
          enabled: true,
          tempo: RubberbandEffect.tempoMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `tempo` const `tempoDefault` is accepted by toFilterString',
        () {
          final s = RubberbandEffect(
            enabled: true,
            tempo: RubberbandEffect.tempoDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SilenceremoveEffect (silenceremove)', () {
      test('disabled → drops out of the chain', () {
        const fx = [SilenceremoveEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [SilenceremoveEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_silenceremove_0:lavfi-silenceremove',
        );
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            detection: SilenceremoveDetection.avg,
          );
          expect(s.toFilterString(), contains('detection='));
          expect(s.toFilterString(), contains('detection=avg'));
        },
      );

      test(
        'param `start_duration` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            startDuration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_duration='));
        },
      );

      test(
        'param `start_mode` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            startMode: SilenceremoveMode.all,
          );
          expect(s.toFilterString(), contains('start_mode='));
          expect(s.toFilterString(), contains('start_mode=all'));
        },
      );

      test(
        'param `start_periods` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            startPeriods: 9000,
          );
          expect(s.toFilterString(), contains('start_periods='));
          expect(s.toFilterString(), contains('start_periods=9000'));
        },
      );

      test(
        'param `start_silence` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            startSilence: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_silence='));
        },
      );

      test(
        'param `start_threshold` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            startThreshold: 1.0,
          );
          expect(s.toFilterString(), contains('start_threshold='));
          expect(s.toFilterString(), contains('start_threshold=1.000'));
        },
      );

      test(
        'param `stop_duration` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            stopDuration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('stop_duration='));
        },
      );

      test(
        'param `stop_mode` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            stopMode: SilenceremoveMode.any,
          );
          expect(s.toFilterString(), contains('stop_mode='));
          expect(s.toFilterString(), contains('stop_mode=any'));
        },
      );

      test(
        'param `stop_periods` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(enabled: true, stopPeriods: 9000);
          expect(s.toFilterString(), contains('stop_periods='));
          expect(s.toFilterString(), contains('stop_periods=9000'));
        },
      );

      test(
        'param `stop_silence` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            stopSilence: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('stop_silence='));
        },
      );

      test(
        'param `stop_threshold` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            stopThreshold: 1.0,
          );
          expect(s.toFilterString(), contains('stop_threshold='));
          expect(s.toFilterString(), contains('stop_threshold=1.000'));
        },
      );

      test(
        'param `timestamp` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveEffect(
            enabled: true,
            timestamp: SilenceremoveTimestamp.copy,
          );
          expect(s.toFilterString(), contains('timestamp='));
          expect(s.toFilterString(), contains('timestamp=copy'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const SilenceremoveEffect(
          enabled: true,
          window: const Duration(microseconds: 1020000),
        );
        expect(s.toFilterString(), contains('window='));
      });

      test(
        'param `start_periods` const `startPeriodsMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startPeriods: SilenceremoveEffect.startPeriodsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_periods` const `startPeriodsMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startPeriods: SilenceremoveEffect.startPeriodsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_periods` const `startPeriodsDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startPeriods: SilenceremoveEffect.startPeriodsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `startThresholdMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startThreshold: SilenceremoveEffect.startThresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `startThresholdMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startThreshold: SilenceremoveEffect.startThresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `startThresholdDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            startThreshold: SilenceremoveEffect.startThresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stopPeriodsMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopPeriods: SilenceremoveEffect.stopPeriodsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stopPeriodsMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopPeriods: SilenceremoveEffect.stopPeriodsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stopPeriodsDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopPeriods: SilenceremoveEffect.stopPeriodsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stopThresholdMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopThreshold: SilenceremoveEffect.stopThresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stopThresholdMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopThreshold: SilenceremoveEffect.stopThresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stopThresholdDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveEffect(
            enabled: true,
            stopThreshold: SilenceremoveEffect.stopThresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SpeechnormEffect (speechnorm)', () {
      test('disabled → drops out of the chain', () {
        const fx = [SpeechnormEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [SpeechnormEffect()];
        expect(audioEffectsChain(fx), '@aek_speechnorm_0:lavfi-speechnorm');
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `compression` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormEffect(enabled: true, compression: 50.0);
          expect(s.toFilterString(), contains('compression='));
          expect(s.toFilterString(), contains('compression=50.000'));
        },
      );

      test(
        'param `expansion` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormEffect(enabled: true, expansion: 50.0);
          expect(s.toFilterString(), contains('expansion='));
          expect(s.toFilterString(), contains('expansion=50.000'));
        },
      );

      test('param `fall` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, fall: 1.0);
        expect(s.toFilterString(), contains('fall='));
        expect(s.toFilterString(), contains('fall=1.000'));
      });

      test('param `invert` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, invert: true);
        expect(s.toFilterString(), contains('invert='));
      });

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, link: true);
        expect(s.toFilterString(), contains('link='));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, peak: 1.0);
        expect(s.toFilterString(), contains('peak='));
        expect(s.toFilterString(), contains('peak=1.000'));
      });

      test('param `raise` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, raise: 1.0);
        expect(s.toFilterString(), contains('raise='));
        expect(s.toFilterString(), contains('raise=1.000'));
      });

      test('param `rms` lands in wire when set to a non-default value', () {
        final s = const SpeechnormEffect(enabled: true, rms: 1.0);
        expect(s.toFilterString(), contains('rms='));
        expect(s.toFilterString(), contains('rms=1.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormEffect(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `compression` const `compressionMin` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            compression: SpeechnormEffect.compressionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compression` const `compressionMax` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            compression: SpeechnormEffect.compressionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compression` const `compressionDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            compression: SpeechnormEffect.compressionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `expansion` const `expansionMin` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            expansion: SpeechnormEffect.expansionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `expansion` const `expansionMax` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            expansion: SpeechnormEffect.expansionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `expansion` const `expansionDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            expansion: SpeechnormEffect.expansionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fall` const `fallMin` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          fall: SpeechnormEffect.fallMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fall` const `fallMax` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          fall: SpeechnormEffect.fallMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fall` const `fallDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            fall: SpeechnormEffect.fallDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `peak` const `peakMin` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          peak: SpeechnormEffect.peakMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMax` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          peak: SpeechnormEffect.peakMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `peak` const `peakDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            peak: SpeechnormEffect.peakDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `raise` const `raiseMin` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          raise: SpeechnormEffect.raiseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `raise` const `raiseMax` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          raise: SpeechnormEffect.raiseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `raise` const `raiseDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            raise: SpeechnormEffect.raiseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `rms` const `rmsMin` is accepted by toFilterString', () {
        final s = SpeechnormEffect(enabled: true, rms: SpeechnormEffect.rmsMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rms` const `rmsMax` is accepted by toFilterString', () {
        final s = SpeechnormEffect(enabled: true, rms: SpeechnormEffect.rmsMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rms` const `rmsDefault` is accepted by toFilterString', () {
        final s = SpeechnormEffect(
          enabled: true,
          rms: SpeechnormEffect.rmsDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            threshold: SpeechnormEffect.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            threshold: SpeechnormEffect.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormEffect(
            enabled: true,
            threshold: SpeechnormEffect.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('StereotoolsEffect (stereotools)', () {
      test('disabled → drops out of the chain', () {
        const fx = [StereotoolsEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [StereotoolsEffect()];
        expect(audioEffectsChain(fx), '@aek_stereotools_0:lavfi-stereotools');
      });

      test(
        'param `balance_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(enabled: true, balanceIn: 1.0);
          expect(s.toFilterString(), contains('balance_in='));
          expect(s.toFilterString(), contains('balance_in=1.000'));
        },
      );

      test(
        'param `balance_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(enabled: true, balanceOut: 1.0);
          expect(s.toFilterString(), contains('balance_out='));
          expect(s.toFilterString(), contains('balance_out=1.000'));
        },
      );

      test('param `base` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, base: 1.0);
        expect(s.toFilterString(), contains('base='));
        expect(s.toFilterString(), contains('base=1.000'));
      });

      test(
        'param `bmode_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(
            enabled: true,
            bmodeIn: StereotoolsBmode.amplitude,
          );
          expect(s.toFilterString(), contains('bmode_in='));
          expect(s.toFilterString(), contains('bmode_in=amplitude'));
        },
      );

      test(
        'param `bmode_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(
            enabled: true,
            bmodeOut: StereotoolsBmode.amplitude,
          );
          expect(s.toFilterString(), contains('bmode_out='));
          expect(s.toFilterString(), contains('bmode_out=amplitude'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, delay: 20.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=20.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(enabled: true, levelIn: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(enabled: true, levelOut: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mlev` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, mlev: 64.0);
        expect(s.toFilterString(), contains('mlev='));
        expect(s.toFilterString(), contains('mlev=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(
          enabled: true,
          mode: StereotoolsMode.lrToMs,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=lr>ms'));
      });

      test('param `mpan` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, mpan: 1.0);
        expect(s.toFilterString(), contains('mpan='));
        expect(s.toFilterString(), contains('mpan=1.000'));
      });

      test('param `mutel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, mutel: true);
        expect(s.toFilterString(), contains('mutel='));
      });

      test('param `muter` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, muter: true);
        expect(s.toFilterString(), contains('muter='));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, phase: 360.0);
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=360.000'));
      });

      test('param `phasel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, phasel: true);
        expect(s.toFilterString(), contains('phasel='));
      });

      test('param `phaser` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, phaser: true);
        expect(s.toFilterString(), contains('phaser='));
      });

      test('param `sbal` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, sbal: 1.0);
        expect(s.toFilterString(), contains('sbal='));
        expect(s.toFilterString(), contains('sbal=1.000'));
      });

      test('param `sclevel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, sclevel: 100.0);
        expect(s.toFilterString(), contains('sclevel='));
        expect(s.toFilterString(), contains('sclevel=100.000'));
      });

      test('param `slev` lands in wire when set to a non-default value', () {
        final s = const StereotoolsEffect(enabled: true, slev: 64.0);
        expect(s.toFilterString(), contains('slev='));
        expect(s.toFilterString(), contains('slev=64.000'));
      });

      test(
        'param `softclip` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsEffect(enabled: true, softclip: true);
          expect(s.toFilterString(), contains('softclip='));
        },
      );

      test(
        'param `balance_in` const `balanceInMin` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceIn: StereotoolsEffect.balanceInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_in` const `balanceInMax` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceIn: StereotoolsEffect.balanceInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_in` const `balanceInDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceIn: StereotoolsEffect.balanceInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balanceOutMin` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceOut: StereotoolsEffect.balanceOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balanceOutMax` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceOut: StereotoolsEffect.balanceOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balanceOutDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            balanceOut: StereotoolsEffect.balanceOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `base` const `baseMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          base: StereotoolsEffect.baseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `base` const `baseMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          base: StereotoolsEffect.baseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `base` const `baseDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            base: StereotoolsEffect.baseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          delay: StereotoolsEffect.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          delay: StereotoolsEffect.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            delay: StereotoolsEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelIn: StereotoolsEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelIn: StereotoolsEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelIn: StereotoolsEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelOut: StereotoolsEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelOut: StereotoolsEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            levelOut: StereotoolsEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mlev` const `mlevMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          mlev: StereotoolsEffect.mlevMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mlev` const `mlevMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          mlev: StereotoolsEffect.mlevMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mlev` const `mlevDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            mlev: StereotoolsEffect.mlevDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mpan` const `mpanMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          mpan: StereotoolsEffect.mpanMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mpan` const `mpanMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          mpan: StereotoolsEffect.mpanMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mpan` const `mpanDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            mpan: StereotoolsEffect.mpanDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `phase` const `phaseMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          phase: StereotoolsEffect.phaseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `phase` const `phaseMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          phase: StereotoolsEffect.phaseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `phase` const `phaseDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            phase: StereotoolsEffect.phaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sbal` const `sbalMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          sbal: StereotoolsEffect.sbalMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sbal` const `sbalMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          sbal: StereotoolsEffect.sbalMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sbal` const `sbalDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            sbal: StereotoolsEffect.sbalDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelMin` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            sclevel: StereotoolsEffect.sclevelMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelMax` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            sclevel: StereotoolsEffect.sclevelMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            sclevel: StereotoolsEffect.sclevelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slev` const `slevMin` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          slev: StereotoolsEffect.slevMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slev` const `slevMax` is accepted by toFilterString', () {
        final s = StereotoolsEffect(
          enabled: true,
          slev: StereotoolsEffect.slevMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slev` const `slevDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsEffect(
            enabled: true,
            slev: StereotoolsEffect.slevDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('StereowidenEffect (stereowiden)', () {
      test('disabled → drops out of the chain', () {
        const fx = [StereowidenEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [StereowidenEffect()];
        expect(audioEffectsChain(fx), '@aek_stereowiden_0:lavfi-stereowiden');
      });

      test(
        'param `crossfeed` lands in wire when set to a non-default value',
        () {
          final s = const StereowidenEffect(enabled: true, crossfeed: 0.8);
          expect(s.toFilterString(), contains('crossfeed='));
          expect(s.toFilterString(), contains('crossfeed=0.800'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const StereowidenEffect(enabled: true, delay: 100.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=100.000'));
      });

      test('param `drymix` lands in wire when set to a non-default value', () {
        final s = const StereowidenEffect(enabled: true, drymix: 1.0);
        expect(s.toFilterString(), contains('drymix='));
        expect(s.toFilterString(), contains('drymix=1.000'));
      });

      test(
        'param `feedback` lands in wire when set to a non-default value',
        () {
          final s = const StereowidenEffect(enabled: true, feedback: 0.9);
          expect(s.toFilterString(), contains('feedback='));
          expect(s.toFilterString(), contains('feedback=0.900'));
        },
      );

      test(
        'param `crossfeed` const `crossfeedMin` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            crossfeed: StereowidenEffect.crossfeedMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `crossfeed` const `crossfeedMax` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            crossfeed: StereowidenEffect.crossfeedMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `crossfeed` const `crossfeedDefault` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            crossfeed: StereowidenEffect.crossfeedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = StereowidenEffect(
          enabled: true,
          delay: StereowidenEffect.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = StereowidenEffect(
          enabled: true,
          delay: StereowidenEffect.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            delay: StereowidenEffect.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixMin` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            drymix: StereowidenEffect.drymixMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixMax` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            drymix: StereowidenEffect.drymixMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixDefault` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            drymix: StereowidenEffect.drymixDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMin` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            feedback: StereowidenEffect.feedbackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMax` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            feedback: StereowidenEffect.feedbackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackDefault` is accepted by toFilterString',
        () {
          final s = StereowidenEffect(
            enabled: true,
            feedback: StereowidenEffect.feedbackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SuperequalizerEffect (superequalizer)', () {
      test('disabled → drops out of the chain', () {
        const fx = [SuperequalizerEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [SuperequalizerEffect()];
        expect(
          audioEffectsChain(fx),
          '@aek_superequalizer_0:lavfi-superequalizer',
        );
      });

      test('digit-prefix param `10b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'10b': 20.0},
        );
        expect(s.toFilterString(), contains('10b='));
        expect(s.toFilterString(), contains('10b=20.000'));
      });

      test('digit-prefix param `11b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'11b': 20.0},
        );
        expect(s.toFilterString(), contains('11b='));
        expect(s.toFilterString(), contains('11b=20.000'));
      });

      test('digit-prefix param `12b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'12b': 20.0},
        );
        expect(s.toFilterString(), contains('12b='));
        expect(s.toFilterString(), contains('12b=20.000'));
      });

      test('digit-prefix param `13b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'13b': 20.0},
        );
        expect(s.toFilterString(), contains('13b='));
        expect(s.toFilterString(), contains('13b=20.000'));
      });

      test('digit-prefix param `14b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'14b': 20.0},
        );
        expect(s.toFilterString(), contains('14b='));
        expect(s.toFilterString(), contains('14b=20.000'));
      });

      test('digit-prefix param `15b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'15b': 20.0},
        );
        expect(s.toFilterString(), contains('15b='));
        expect(s.toFilterString(), contains('15b=20.000'));
      });

      test('digit-prefix param `16b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'16b': 20.0},
        );
        expect(s.toFilterString(), contains('16b='));
        expect(s.toFilterString(), contains('16b=20.000'));
      });

      test('digit-prefix param `17b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'17b': 20.0},
        );
        expect(s.toFilterString(), contains('17b='));
        expect(s.toFilterString(), contains('17b=20.000'));
      });

      test('digit-prefix param `18b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'18b': 20.0},
        );
        expect(s.toFilterString(), contains('18b='));
        expect(s.toFilterString(), contains('18b=20.000'));
      });

      test('digit-prefix param `1b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'1b': 20.0},
        );
        expect(s.toFilterString(), contains('1b='));
        expect(s.toFilterString(), contains('1b=20.000'));
      });

      test('digit-prefix param `2b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'2b': 20.0},
        );
        expect(s.toFilterString(), contains('2b='));
        expect(s.toFilterString(), contains('2b=20.000'));
      });

      test('digit-prefix param `3b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'3b': 20.0},
        );
        expect(s.toFilterString(), contains('3b='));
        expect(s.toFilterString(), contains('3b=20.000'));
      });

      test('digit-prefix param `4b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'4b': 20.0},
        );
        expect(s.toFilterString(), contains('4b='));
        expect(s.toFilterString(), contains('4b=20.000'));
      });

      test('digit-prefix param `5b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'5b': 20.0},
        );
        expect(s.toFilterString(), contains('5b='));
        expect(s.toFilterString(), contains('5b=20.000'));
      });

      test('digit-prefix param `6b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'6b': 20.0},
        );
        expect(s.toFilterString(), contains('6b='));
        expect(s.toFilterString(), contains('6b=20.000'));
      });

      test('digit-prefix param `7b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'7b': 20.0},
        );
        expect(s.toFilterString(), contains('7b='));
        expect(s.toFilterString(), contains('7b=20.000'));
      });

      test('digit-prefix param `8b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'8b': 20.0},
        );
        expect(s.toFilterString(), contains('8b='));
        expect(s.toFilterString(), contains('8b=20.000'));
      });

      test('digit-prefix param `9b` lands in wire via params map', () {
        final s = const SuperequalizerEffect(
          enabled: true,
          params: {'9b': 20.0},
        );
        expect(s.toFilterString(), contains('9b='));
        expect(s.toFilterString(), contains('9b=20.000'));
      });
    });
    group('SurroundEffect (surround)', () {
      test('disabled → drops out of the chain', () {
        const fx = [SurroundEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [SurroundEffect()];
        expect(audioEffectsChain(fx), '@aek_surround_0:lavfi-surround');
      });

      test('param `allx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, allx: 15.0);
        expect(s.toFilterString(), contains('allx='));
        expect(s.toFilterString(), contains('allx=15.000'));
      });

      test('param `ally` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, ally: 15.0);
        expect(s.toFilterString(), contains('ally='));
        expect(s.toFilterString(), contains('ally=15.000'));
      });

      test('param `angle` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, angle: 360.0);
        expect(s.toFilterString(), contains('angle='));
        expect(s.toFilterString(), contains('angle=360.000'));
      });

      test('param `bc_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bcIn: 10.0);
        expect(s.toFilterString(), contains('bc_in='));
        expect(s.toFilterString(), contains('bc_in=10.000'));
      });

      test('param `bc_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bcOut: 10.0);
        expect(s.toFilterString(), contains('bc_out='));
        expect(s.toFilterString(), contains('bc_out=10.000'));
      });

      test('param `bcx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bcx: 15.0);
        expect(s.toFilterString(), contains('bcx='));
        expect(s.toFilterString(), contains('bcx=15.000'));
      });

      test('param `bcy` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bcy: 15.0);
        expect(s.toFilterString(), contains('bcy='));
        expect(s.toFilterString(), contains('bcy=15.000'));
      });

      test('param `bl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, blIn: 10.0);
        expect(s.toFilterString(), contains('bl_in='));
        expect(s.toFilterString(), contains('bl_in=10.000'));
      });

      test('param `bl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, blOut: 10.0);
        expect(s.toFilterString(), contains('bl_out='));
        expect(s.toFilterString(), contains('bl_out=10.000'));
      });

      test('param `blx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, blx: 15.0);
        expect(s.toFilterString(), contains('blx='));
        expect(s.toFilterString(), contains('blx=15.000'));
      });

      test('param `bly` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bly: 15.0);
        expect(s.toFilterString(), contains('bly='));
        expect(s.toFilterString(), contains('bly=15.000'));
      });

      test('param `br_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, brIn: 10.0);
        expect(s.toFilterString(), contains('br_in='));
        expect(s.toFilterString(), contains('br_in=10.000'));
      });

      test('param `br_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, brOut: 10.0);
        expect(s.toFilterString(), contains('br_out='));
        expect(s.toFilterString(), contains('br_out=10.000'));
      });

      test('param `brx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, brx: 15.0);
        expect(s.toFilterString(), contains('brx='));
        expect(s.toFilterString(), contains('brx=15.000'));
      });

      test('param `bry` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, bry: 15.0);
        expect(s.toFilterString(), contains('bry='));
        expect(s.toFilterString(), contains('bry=15.000'));
      });

      test('param `chl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, chlIn: 'wire_test_alt');
        expect(s.toFilterString(), contains('chl_in='));
      });

      test('param `chl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, chlOut: 'wire_test_alt');
        expect(s.toFilterString(), contains('chl_out='));
      });

      test('param `fc_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fcIn: 10.0);
        expect(s.toFilterString(), contains('fc_in='));
        expect(s.toFilterString(), contains('fc_in=10.000'));
      });

      test('param `fc_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fcOut: 10.0);
        expect(s.toFilterString(), contains('fc_out='));
        expect(s.toFilterString(), contains('fc_out=10.000'));
      });

      test('param `fcx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fcx: 15.0);
        expect(s.toFilterString(), contains('fcx='));
        expect(s.toFilterString(), contains('fcx=15.000'));
      });

      test('param `fcy` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fcy: 15.0);
        expect(s.toFilterString(), contains('fcy='));
        expect(s.toFilterString(), contains('fcy=15.000'));
      });

      test('param `fl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, flIn: 10.0);
        expect(s.toFilterString(), contains('fl_in='));
        expect(s.toFilterString(), contains('fl_in=10.000'));
      });

      test('param `fl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, flOut: 10.0);
        expect(s.toFilterString(), contains('fl_out='));
        expect(s.toFilterString(), contains('fl_out=10.000'));
      });

      test('param `flx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, flx: 15.0);
        expect(s.toFilterString(), contains('flx='));
        expect(s.toFilterString(), contains('flx=15.000'));
      });

      test('param `fly` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fly: 15.0);
        expect(s.toFilterString(), contains('fly='));
        expect(s.toFilterString(), contains('fly=15.000'));
      });

      test('param `focus` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, focus: 1.0);
        expect(s.toFilterString(), contains('focus='));
        expect(s.toFilterString(), contains('focus=1.000'));
      });

      test('param `fr_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, frIn: 10.0);
        expect(s.toFilterString(), contains('fr_in='));
        expect(s.toFilterString(), contains('fr_in=10.000'));
      });

      test('param `fr_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, frOut: 10.0);
        expect(s.toFilterString(), contains('fr_out='));
        expect(s.toFilterString(), contains('fr_out=10.000'));
      });

      test('param `frx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, frx: 15.0);
        expect(s.toFilterString(), contains('frx='));
        expect(s.toFilterString(), contains('frx=15.000'));
      });

      test('param `fry` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, fry: 15.0);
        expect(s.toFilterString(), contains('fry='));
        expect(s.toFilterString(), contains('fry=15.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(enabled: true, levelIn: 10.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=10.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(enabled: true, levelOut: 10.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=10.000'));
        },
      );

      test('param `lfe` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, lfe: false);
        expect(s.toFilterString(), contains('lfe='));
      });

      test(
        'param `lfe_high` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(enabled: true, lfeHigh: 512);
          expect(s.toFilterString(), contains('lfe_high='));
          expect(s.toFilterString(), contains('lfe_high=512'));
        },
      );

      test('param `lfe_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, lfeIn: 10.0);
        expect(s.toFilterString(), contains('lfe_in='));
        expect(s.toFilterString(), contains('lfe_in=10.000'));
      });

      test('param `lfe_low` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, lfeLow: 256);
        expect(s.toFilterString(), contains('lfe_low='));
        expect(s.toFilterString(), contains('lfe_low=256'));
      });

      test(
        'param `lfe_mode` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(
            enabled: true,
            lfeMode: SurroundLfeMode.sub,
          );
          expect(s.toFilterString(), contains('lfe_mode='));
          expect(s.toFilterString(), contains('lfe_mode=sub'));
        },
      );

      test('param `lfe_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, lfeOut: 10.0);
        expect(s.toFilterString(), contains('lfe_out='));
        expect(s.toFilterString(), contains('lfe_out=10.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `sl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, slIn: 10.0);
        expect(s.toFilterString(), contains('sl_in='));
        expect(s.toFilterString(), contains('sl_in=10.000'));
      });

      test('param `sl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, slOut: 10.0);
        expect(s.toFilterString(), contains('sl_out='));
        expect(s.toFilterString(), contains('sl_out=10.000'));
      });

      test('param `slx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, slx: 15.0);
        expect(s.toFilterString(), contains('slx='));
        expect(s.toFilterString(), contains('slx=15.000'));
      });

      test('param `sly` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, sly: 15.0);
        expect(s.toFilterString(), contains('sly='));
        expect(s.toFilterString(), contains('sly=15.000'));
      });

      test('param `smooth` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, smooth: 1.0);
        expect(s.toFilterString(), contains('smooth='));
        expect(s.toFilterString(), contains('smooth=1.000'));
      });

      test('param `sr_in` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, srIn: 10.0);
        expect(s.toFilterString(), contains('sr_in='));
        expect(s.toFilterString(), contains('sr_in=10.000'));
      });

      test('param `sr_out` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, srOut: 10.0);
        expect(s.toFilterString(), contains('sr_out='));
        expect(s.toFilterString(), contains('sr_out=10.000'));
      });

      test('param `srx` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, srx: 15.0);
        expect(s.toFilterString(), contains('srx='));
        expect(s.toFilterString(), contains('srx=15.000'));
      });

      test('param `sry` lands in wire when set to a non-default value', () {
        final s = const SurroundEffect(enabled: true, sry: 15.0);
        expect(s.toFilterString(), contains('sry='));
        expect(s.toFilterString(), contains('sry=15.000'));
      });

      test(
        'param `win_func` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(
            enabled: true,
            winFunc: SurroundWinFunc.rect,
          );
          expect(s.toFilterString(), contains('win_func='));
          expect(s.toFilterString(), contains('win_func=rect'));
        },
      );

      test(
        'param `win_size` lands in wire when set to a non-default value',
        () {
          final s = const SurroundEffect(enabled: true, winSize: 65536);
          expect(s.toFilterString(), contains('win_size='));
          expect(s.toFilterString(), contains('win_size=65536'));
        },
      );

      test('param `allx` const `allxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, allx: SurroundEffect.allxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `allx` const `allxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, allx: SurroundEffect.allxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `allx` const `allxDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            allx: SurroundEffect.allxDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ally` const `allyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, ally: SurroundEffect.allyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ally` const `allyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, ally: SurroundEffect.allyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ally` const `allyDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            ally: SurroundEffect.allyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `angle` const `angleMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, angle: SurroundEffect.angleMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `angle` const `angleMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, angle: SurroundEffect.angleMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `angle` const `angleDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            angle: SurroundEffect.angleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bc_in` const `bcInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcIn: SurroundEffect.bcInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bc_in` const `bcInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcIn: SurroundEffect.bcInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bc_in` const `bcInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            bcIn: SurroundEffect.bcInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bc_out` const `bcOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcOut: SurroundEffect.bcOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bc_out` const `bcOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcOut: SurroundEffect.bcOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bc_out` const `bcOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            bcOut: SurroundEffect.bcOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bcx` const `bcxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcx: SurroundEffect.bcxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcx` const `bcxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcx: SurroundEffect.bcxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcx` const `bcxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcx: SurroundEffect.bcxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcy: SurroundEffect.bcyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcy: SurroundEffect.bcyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bcy: SurroundEffect.bcyDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bl_in` const `blInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blIn: SurroundEffect.blInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bl_in` const `blInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blIn: SurroundEffect.blInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bl_in` const `blInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            blIn: SurroundEffect.blInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bl_out` const `blOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blOut: SurroundEffect.blOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bl_out` const `blOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blOut: SurroundEffect.blOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bl_out` const `blOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            blOut: SurroundEffect.blOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `blx` const `blxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blx: SurroundEffect.blxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blx` const `blxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blx: SurroundEffect.blxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blx` const `blxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, blx: SurroundEffect.blxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bly: SurroundEffect.blyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bly: SurroundEffect.blyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bly: SurroundEffect.blyDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `br_in` const `brInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brIn: SurroundEffect.brInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `br_in` const `brInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brIn: SurroundEffect.brInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `br_in` const `brInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            brIn: SurroundEffect.brInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `br_out` const `brOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brOut: SurroundEffect.brOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `br_out` const `brOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brOut: SurroundEffect.brOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `br_out` const `brOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            brOut: SurroundEffect.brOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `brx` const `brxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brx: SurroundEffect.brxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `brx` const `brxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brx: SurroundEffect.brxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `brx` const `brxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, brx: SurroundEffect.brxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bry: SurroundEffect.bryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bry: SurroundEffect.bryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, bry: SurroundEffect.bryDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fc_in` const `fcInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcIn: SurroundEffect.fcInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fc_in` const `fcInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcIn: SurroundEffect.fcInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fc_in` const `fcInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            fcIn: SurroundEffect.fcInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fc_out` const `fcOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcOut: SurroundEffect.fcOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fc_out` const `fcOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcOut: SurroundEffect.fcOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fc_out` const `fcOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            fcOut: SurroundEffect.fcOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fcx` const `fcxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcx: SurroundEffect.fcxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcx` const `fcxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcx: SurroundEffect.fcxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcx` const `fcxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcx: SurroundEffect.fcxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcy: SurroundEffect.fcyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcy: SurroundEffect.fcyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fcy: SurroundEffect.fcyDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fl_in` const `flInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flIn: SurroundEffect.flInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fl_in` const `flInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flIn: SurroundEffect.flInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fl_in` const `flInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            flIn: SurroundEffect.flInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fl_out` const `flOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flOut: SurroundEffect.flOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fl_out` const `flOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flOut: SurroundEffect.flOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fl_out` const `flOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            flOut: SurroundEffect.flOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `flx` const `flxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flx: SurroundEffect.flxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `flx` const `flxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flx: SurroundEffect.flxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `flx` const `flxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, flx: SurroundEffect.flxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fly: SurroundEffect.flyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fly: SurroundEffect.flyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fly: SurroundEffect.flyDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `focus` const `focusMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, focus: SurroundEffect.focusMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `focus` const `focusMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, focus: SurroundEffect.focusMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `focus` const `focusDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            focus: SurroundEffect.focusDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fr_in` const `frInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frIn: SurroundEffect.frInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fr_in` const `frInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frIn: SurroundEffect.frInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fr_in` const `frInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            frIn: SurroundEffect.frInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fr_out` const `frOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frOut: SurroundEffect.frOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fr_out` const `frOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frOut: SurroundEffect.frOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fr_out` const `frOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            frOut: SurroundEffect.frOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `frx` const `frxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frx: SurroundEffect.frxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `frx` const `frxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frx: SurroundEffect.frxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `frx` const `frxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, frx: SurroundEffect.frxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fry: SurroundEffect.fryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fry: SurroundEffect.fryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, fry: SurroundEffect.fryDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `levelInMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelIn: SurroundEffect.levelInMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelIn: SurroundEffect.levelInMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `levelInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelIn: SurroundEffect.levelInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelOut: SurroundEffect.levelOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelOut: SurroundEffect.levelOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `levelOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            levelOut: SurroundEffect.levelOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfeHighMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeHigh: SurroundEffect.lfeHighMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfeHighMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeHigh: SurroundEffect.lfeHighMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfeHighDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeHigh: SurroundEffect.lfeHighDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `lfe_in` const `lfeInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, lfeIn: SurroundEffect.lfeInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lfe_in` const `lfeInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, lfeIn: SurroundEffect.lfeInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `lfe_in` const `lfeInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeIn: SurroundEffect.lfeInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfeLowMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeLow: SurroundEffect.lfeLowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfeLowMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeLow: SurroundEffect.lfeLowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfeLowDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeLow: SurroundEffect.lfeLowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfeOutMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeOut: SurroundEffect.lfeOutMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfeOutMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeOut: SurroundEffect.lfeOutMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfeOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            lfeOut: SurroundEffect.lfeOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            overlap: SurroundEffect.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            overlap: SurroundEffect.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            overlap: SurroundEffect.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sl_in` const `slInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slIn: SurroundEffect.slInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sl_in` const `slInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slIn: SurroundEffect.slInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sl_in` const `slInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            slIn: SurroundEffect.slInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sl_out` const `slOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slOut: SurroundEffect.slOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sl_out` const `slOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slOut: SurroundEffect.slOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sl_out` const `slOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            slOut: SurroundEffect.slOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slx` const `slxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slx: SurroundEffect.slxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slx` const `slxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slx: SurroundEffect.slxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slx` const `slxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, slx: SurroundEffect.slxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sly: SurroundEffect.slyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sly: SurroundEffect.slyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sly: SurroundEffect.slyDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `smooth` const `smoothMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            smooth: SurroundEffect.smoothMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            smooth: SurroundEffect.smoothMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            smooth: SurroundEffect.smoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sr_in` const `srInMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srIn: SurroundEffect.srInMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sr_in` const `srInMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srIn: SurroundEffect.srInMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sr_in` const `srInDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            srIn: SurroundEffect.srInDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sr_out` const `srOutMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srOut: SurroundEffect.srOutMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sr_out` const `srOutMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srOut: SurroundEffect.srOutMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sr_out` const `srOutDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            srOut: SurroundEffect.srOutDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `srx` const `srxMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srx: SurroundEffect.srxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `srx` const `srxMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srx: SurroundEffect.srxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `srx` const `srxDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, srx: SurroundEffect.srxDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryMin` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sry: SurroundEffect.sryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryMax` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sry: SurroundEffect.sryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryDefault` is accepted by toFilterString', () {
        final s = SurroundEffect(enabled: true, sry: SurroundEffect.sryDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `win_size` const `winSizeMin` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            winSize: SurroundEffect.winSizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `winSizeMax` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            winSize: SurroundEffect.winSizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `winSizeDefault` is accepted by toFilterString',
        () {
          final s = SurroundEffect(
            enabled: true,
            winSize: SurroundEffect.winSizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TiltshelfEffect (tiltshelf)', () {
      test('disabled → drops out of the chain', () {
        const fx = [TiltshelfEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [TiltshelfEffect()];
        expect(audioEffectsChain(fx), '@aek_tiltshelf_0:lavfi-tiltshelf');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const TiltshelfEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const TiltshelfEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const TiltshelfEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(
            enabled: true,
            precision: TiltshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(
            enabled: true,
            transform: TiltshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const TiltshelfEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfEffect(
            enabled: true,
            widthType: TiltshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            blocksize: TiltshelfEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            blocksize: TiltshelfEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            blocksize: TiltshelfEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            frequency: TiltshelfEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            frequency: TiltshelfEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            frequency: TiltshelfEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = TiltshelfEffect(enabled: true, gain: TiltshelfEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = TiltshelfEffect(enabled: true, gain: TiltshelfEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            gain: TiltshelfEffect.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = TiltshelfEffect(enabled: true, mix: TiltshelfEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = TiltshelfEffect(enabled: true, mix: TiltshelfEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = TiltshelfEffect(
          enabled: true,
          mix: TiltshelfEffect.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = TiltshelfEffect(
          enabled: true,
          poles: TiltshelfEffect.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = TiltshelfEffect(
          enabled: true,
          poles: TiltshelfEffect.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            poles: TiltshelfEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = TiltshelfEffect(
          enabled: true,
          width: TiltshelfEffect.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = TiltshelfEffect(
          enabled: true,
          width: TiltshelfEffect.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfEffect(
            enabled: true,
            width: TiltshelfEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TrebleEffect (treble)', () {
      test('disabled → drops out of the chain', () {
        const fx = [TrebleEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [TrebleEffect()];
        expect(audioEffectsChain(fx), '@aek_treble_0:lavfi-treble');
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const TrebleEffect(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const TrebleEffect(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const TrebleEffect(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(
            enabled: true,
            precision: TreblePrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(
            enabled: true,
            transform: TrebleTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const TrebleEffect(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const TrebleEffect(
            enabled: true,
            widthType: TrebleWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            blocksize: TrebleEffect.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            blocksize: TrebleEffect.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            blocksize: TrebleEffect.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            frequency: TrebleEffect.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            frequency: TrebleEffect.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            frequency: TrebleEffect.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, gain: TrebleEffect.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, gain: TrebleEffect.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = TrebleEffect(enabled: true, gain: TrebleEffect.gainDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, mix: TrebleEffect.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, mix: TrebleEffect.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, mix: TrebleEffect.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, poles: TrebleEffect.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, poles: TrebleEffect.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            poles: TrebleEffect.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, width: TrebleEffect.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = TrebleEffect(enabled: true, width: TrebleEffect.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = TrebleEffect(
            enabled: true,
            width: TrebleEffect.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TremoloEffect (tremolo)', () {
      test('disabled → drops out of the chain', () {
        const fx = [TremoloEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [TremoloEffect()];
        expect(audioEffectsChain(fx), '@aek_tremolo_0:lavfi-tremolo');
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const TremoloEffect(enabled: true, d: 1.0);
        expect(s.toFilterString(), contains('d='));
        expect(s.toFilterString(), contains('d=1.000'));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TremoloEffect(enabled: true, f: 20000.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=20000.000'));
      });

      test('param `d` const `dMin` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, d: TremoloEffect.dMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dMax` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, d: TremoloEffect.dMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dDefault` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, d: TremoloEffect.dDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, f: TremoloEffect.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, f: TremoloEffect.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = TremoloEffect(enabled: true, f: TremoloEffect.fDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('VibratoEffect (vibrato)', () {
      test('disabled → drops out of the chain', () {
        const fx = [VibratoEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [VibratoEffect()];
        expect(audioEffectsChain(fx), '@aek_vibrato_0:lavfi-vibrato');
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const VibratoEffect(enabled: true, d: 1.0);
        expect(s.toFilterString(), contains('d='));
        expect(s.toFilterString(), contains('d=1.000'));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const VibratoEffect(enabled: true, f: 20000.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=20000.000'));
      });

      test('param `d` const `dMin` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, d: VibratoEffect.dMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dMax` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, d: VibratoEffect.dMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dDefault` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, d: VibratoEffect.dDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, f: VibratoEffect.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, f: VibratoEffect.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = VibratoEffect(enabled: true, f: VibratoEffect.fDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('VirtualbassEffect (virtualbass)', () {
      test('disabled → drops out of the chain', () {
        const fx = [VirtualbassEffect(enabled: false)];
        expect(audioEffectsChain(fx), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = [VirtualbassEffect()];
        expect(audioEffectsChain(fx), '@aek_virtualbass_0:lavfi-virtualbass');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const VirtualbassEffect(enabled: true, cutoff: 500.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=500.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const VirtualbassEffect(enabled: true, strength: 0.5);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=0.500'));
        },
      );

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            cutoff: VirtualbassEffect.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            cutoff: VirtualbassEffect.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            cutoff: VirtualbassEffect.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            strength: VirtualbassEffect.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            strength: VirtualbassEffect.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = VirtualbassEffect(
            enabled: true,
            strength: VirtualbassEffect.strengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
  });

  group('Per-enum round-trip coverage', () {
    group('AcompressorDetection (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AcompressorDetection.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AcompressorDetection.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AcompressorDetection.fromMpv('this_will_never_match'),
          AcompressorDetection.peak,
        );
        expect(AcompressorDetection.fromMpv(null), AcompressorDetection.peak);
      });
    });
    group('AcompressorLink (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AcompressorLink.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AcompressorLink.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AcompressorLink.fromMpv('this_will_never_match'),
          AcompressorLink.average,
        );
        expect(AcompressorLink.fromMpv(null), AcompressorLink.average);
      });
    });
    group('AcompressorMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AcompressorMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AcompressorMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AcompressorMode.fromMpv('this_will_never_match'),
          AcompressorMode.downward,
        );
        expect(AcompressorMode.fromMpv(null), AcompressorMode.downward);
      });
    });
    group('AcrusherMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AcrusherMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AcrusherMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AcrusherMode.fromMpv('this_will_never_match'), AcrusherMode.lin);
        expect(AcrusherMode.fromMpv(null), AcrusherMode.lin);
      });
    });
    group('AdeclickM (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdeclickM.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdeclickM.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AdeclickM.fromMpv('this_will_never_match'), AdeclickM.add);
        expect(AdeclickM.fromMpv(null), AdeclickM.add);
      });
    });
    group('AdeclipM (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdeclipM.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdeclipM.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AdeclipM.fromMpv('this_will_never_match'), AdeclipM.add);
        expect(AdeclipM.fromMpv(null), AdeclipM.add);
      });
    });
    group('AdenormType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdenormType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdenormType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AdenormType.fromMpv('this_will_never_match'), AdenormType.dc);
        expect(AdenormType.fromMpv(null), AdenormType.dc);
      });
    });
    group('AdynamicequalizerAuto (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdynamicequalizerAuto.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdynamicequalizerAuto.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AdynamicequalizerAuto.fromMpv('this_will_never_match'),
          AdynamicequalizerAuto.disabled,
        );
        expect(
          AdynamicequalizerAuto.fromMpv(null),
          AdynamicequalizerAuto.disabled,
        );
      });
    });
    group('AdynamicequalizerDftype (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdynamicequalizerDftype.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdynamicequalizerDftype.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AdynamicequalizerDftype.fromMpv('this_will_never_match'),
          AdynamicequalizerDftype.bandpass,
        );
        expect(
          AdynamicequalizerDftype.fromMpv(null),
          AdynamicequalizerDftype.bandpass,
        );
      });
    });
    group('AdynamicequalizerMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdynamicequalizerMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdynamicequalizerMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AdynamicequalizerMode.fromMpv('this_will_never_match'),
          AdynamicequalizerMode.listen,
        );
        expect(
          AdynamicequalizerMode.fromMpv(null),
          AdynamicequalizerMode.listen,
        );
      });
    });
    group('AdynamicequalizerPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdynamicequalizerPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdynamicequalizerPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AdynamicequalizerPrecision.fromMpv('this_will_never_match'),
          AdynamicequalizerPrecision.auto,
        );
        expect(
          AdynamicequalizerPrecision.fromMpv(null),
          AdynamicequalizerPrecision.auto,
        );
      });
    });
    group('AdynamicequalizerTftype (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AdynamicequalizerTftype.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AdynamicequalizerTftype.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AdynamicequalizerTftype.fromMpv('this_will_never_match'),
          AdynamicequalizerTftype.bell,
        );
        expect(
          AdynamicequalizerTftype.fromMpv(null),
          AdynamicequalizerTftype.bell,
        );
      });
    });
    group('AemphasisMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AemphasisMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AemphasisMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AemphasisMode.fromMpv('this_will_never_match'),
          AemphasisMode.reproduction,
        );
        expect(AemphasisMode.fromMpv(null), AemphasisMode.reproduction);
      });
    });
    group('AemphasisType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AemphasisType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AemphasisType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AemphasisType.fromMpv('this_will_never_match'),
          AemphasisType.col,
        );
        expect(AemphasisType.fromMpv(null), AemphasisType.col);
      });
    });
    group('AfadeCurve (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfadeCurve.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfadeCurve.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfadeCurve.fromMpv('this_will_never_match'), AfadeCurve.nofade);
        expect(AfadeCurve.fromMpv(null), AfadeCurve.nofade);
      });
    });
    group('AfadeType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfadeType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfadeType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfadeType.fromMpv('this_will_never_match'), AfadeType.in_);
        expect(AfadeType.fromMpv(null), AfadeType.in_);
      });
    });
    group('AfftdnLink (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfftdnLink.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfftdnLink.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfftdnLink.fromMpv('this_will_never_match'), AfftdnLink.none);
        expect(AfftdnLink.fromMpv(null), AfftdnLink.none);
      });
    });
    group('AfftdnMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfftdnMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfftdnMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfftdnMode.fromMpv('this_will_never_match'), AfftdnMode.input);
        expect(AfftdnMode.fromMpv(null), AfftdnMode.input);
      });
    });
    group('AfftdnSample (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfftdnSample.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfftdnSample.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AfftdnSample.fromMpv('this_will_never_match'),
          AfftdnSample.none,
        );
        expect(AfftdnSample.fromMpv(null), AfftdnSample.none);
      });
    });
    group('AfftdnType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfftdnType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfftdnType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfftdnType.fromMpv('this_will_never_match'), AfftdnType.white);
        expect(AfftdnType.fromMpv(null), AfftdnType.white);
      });
    });
    group('AfftfiltWinFunc (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfftfiltWinFunc.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfftfiltWinFunc.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AfftfiltWinFunc.fromMpv('this_will_never_match'),
          AfftfiltWinFunc.rect,
        );
        expect(AfftfiltWinFunc.fromMpv(null), AfftfiltWinFunc.rect);
      });
    });
    group('AfwtdnWavet (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AfwtdnWavet.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AfwtdnWavet.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AfwtdnWavet.fromMpv('this_will_never_match'), AfwtdnWavet.sym2);
        expect(AfwtdnWavet.fromMpv(null), AfwtdnWavet.sym2);
      });
    });
    group('AgateDetection (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AgateDetection.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AgateDetection.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AgateDetection.fromMpv('this_will_never_match'),
          AgateDetection.peak,
        );
        expect(AgateDetection.fromMpv(null), AgateDetection.peak);
      });
    });
    group('AgateLink (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AgateLink.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AgateLink.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AgateLink.fromMpv('this_will_never_match'), AgateLink.average);
        expect(AgateLink.fromMpv(null), AgateLink.average);
      });
    });
    group('AgateMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AgateMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AgateMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AgateMode.fromMpv('this_will_never_match'), AgateMode.downward);
        expect(AgateMode.fromMpv(null), AgateMode.downward);
      });
    });
    group('AiirFormat (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AiirFormat.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AiirFormat.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AiirFormat.fromMpv('this_will_never_match'), AiirFormat.ll);
        expect(AiirFormat.fromMpv(null), AiirFormat.ll);
      });
    });
    group('AiirPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AiirPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AiirPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AiirPrecision.fromMpv('this_will_never_match'),
          AiirPrecision.dbl,
        );
        expect(AiirPrecision.fromMpv(null), AiirPrecision.dbl);
      });
    });
    group('AiirProcess (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AiirProcess.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AiirProcess.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AiirProcess.fromMpv('this_will_never_match'), AiirProcess.d);
        expect(AiirProcess.fromMpv(null), AiirProcess.d);
      });
    });
    group('AllpassPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AllpassPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AllpassPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AllpassPrecision.fromMpv('this_will_never_match'),
          AllpassPrecision.auto,
        );
        expect(AllpassPrecision.fromMpv(null), AllpassPrecision.auto);
      });
    });
    group('AllpassTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AllpassTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AllpassTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AllpassTransformType.fromMpv('this_will_never_match'),
          AllpassTransformType.di,
        );
        expect(AllpassTransformType.fromMpv(null), AllpassTransformType.di);
      });
    });
    group('AllpassWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AllpassWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AllpassWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AllpassWidthType.fromMpv('this_will_never_match'),
          AllpassWidthType.h,
        );
        expect(AllpassWidthType.fromMpv(null), AllpassWidthType.h);
      });
    });
    group('AnequalizerFscale (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AnequalizerFscale.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AnequalizerFscale.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AnequalizerFscale.fromMpv('this_will_never_match'),
          AnequalizerFscale.lin,
        );
        expect(AnequalizerFscale.fromMpv(null), AnequalizerFscale.lin);
      });
    });
    group('AnlmdnMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AnlmdnMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AnlmdnMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AnlmdnMode.fromMpv('this_will_never_match'), AnlmdnMode.i);
        expect(AnlmdnMode.fromMpv(null), AnlmdnMode.i);
      });
    });
    group('AphaserType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AphaserType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AphaserType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AphaserType.fromMpv('this_will_never_match'),
          AphaserType.triangular,
        );
        expect(AphaserType.fromMpv(null), AphaserType.triangular);
      });
    });
    group('ApulsatorMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in ApulsatorMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(ApulsatorMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          ApulsatorMode.fromMpv('this_will_never_match'),
          ApulsatorMode.sine,
        );
        expect(ApulsatorMode.fromMpv(null), ApulsatorMode.sine);
      });
    });
    group('ApulsatorTiming (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in ApulsatorTiming.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(ApulsatorTiming.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          ApulsatorTiming.fromMpv('this_will_never_match'),
          ApulsatorTiming.bpm,
        );
        expect(ApulsatorTiming.fromMpv(null), ApulsatorTiming.bpm);
      });
    });
    group('AsoftclipTypes (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AsoftclipTypes.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AsoftclipTypes.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          AsoftclipTypes.fromMpv('this_will_never_match'),
          AsoftclipTypes.hard,
        );
        expect(AsoftclipTypes.fromMpv(null), AsoftclipTypes.hard);
      });
    });
    group('BandpassPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandpassPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandpassPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandpassPrecision.fromMpv('this_will_never_match'),
          BandpassPrecision.auto,
        );
        expect(BandpassPrecision.fromMpv(null), BandpassPrecision.auto);
      });
    });
    group('BandpassTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandpassTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandpassTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandpassTransformType.fromMpv('this_will_never_match'),
          BandpassTransformType.di,
        );
        expect(BandpassTransformType.fromMpv(null), BandpassTransformType.di);
      });
    });
    group('BandpassWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandpassWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandpassWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandpassWidthType.fromMpv('this_will_never_match'),
          BandpassWidthType.h,
        );
        expect(BandpassWidthType.fromMpv(null), BandpassWidthType.h);
      });
    });
    group('BandrejectPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandrejectPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandrejectPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandrejectPrecision.fromMpv('this_will_never_match'),
          BandrejectPrecision.auto,
        );
        expect(BandrejectPrecision.fromMpv(null), BandrejectPrecision.auto);
      });
    });
    group('BandrejectTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandrejectTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandrejectTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandrejectTransformType.fromMpv('this_will_never_match'),
          BandrejectTransformType.di,
        );
        expect(
          BandrejectTransformType.fromMpv(null),
          BandrejectTransformType.di,
        );
      });
    });
    group('BandrejectWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BandrejectWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BandrejectWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BandrejectWidthType.fromMpv('this_will_never_match'),
          BandrejectWidthType.h,
        );
        expect(BandrejectWidthType.fromMpv(null), BandrejectWidthType.h);
      });
    });
    group('BassPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BassPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BassPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BassPrecision.fromMpv('this_will_never_match'),
          BassPrecision.auto,
        );
        expect(BassPrecision.fromMpv(null), BassPrecision.auto);
      });
    });
    group('BassTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BassTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BassTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BassTransformType.fromMpv('this_will_never_match'),
          BassTransformType.di,
        );
        expect(BassTransformType.fromMpv(null), BassTransformType.di);
      });
    });
    group('BassWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BassWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BassWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(BassWidthType.fromMpv('this_will_never_match'), BassWidthType.h);
        expect(BassWidthType.fromMpv(null), BassWidthType.h);
      });
    });
    group('BiquadPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BiquadPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BiquadPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BiquadPrecision.fromMpv('this_will_never_match'),
          BiquadPrecision.auto,
        );
        expect(BiquadPrecision.fromMpv(null), BiquadPrecision.auto);
      });
    });
    group('BiquadTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in BiquadTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(BiquadTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          BiquadTransformType.fromMpv('this_will_never_match'),
          BiquadTransformType.di,
        );
        expect(BiquadTransformType.fromMpv(null), BiquadTransformType.di);
      });
    });
    group('DeesserMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in DeesserMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(DeesserMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(DeesserMode.fromMpv('this_will_never_match'), DeesserMode.i);
        expect(DeesserMode.fromMpv(null), DeesserMode.i);
      });
    });
    group('Ebur128Gaugetype (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in Ebur128Gaugetype.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(Ebur128Gaugetype.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          Ebur128Gaugetype.fromMpv('this_will_never_match'),
          Ebur128Gaugetype.momentary,
        );
        expect(Ebur128Gaugetype.fromMpv(null), Ebur128Gaugetype.momentary);
      });
    });
    group('Ebur128Level (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in Ebur128Level.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(Ebur128Level.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          Ebur128Level.fromMpv('this_will_never_match'),
          Ebur128Level.quiet,
        );
        expect(Ebur128Level.fromMpv(null), Ebur128Level.quiet);
      });
    });
    group('Ebur128Mode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in Ebur128Mode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(Ebur128Mode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(Ebur128Mode.fromMpv('this_will_never_match'), Ebur128Mode.none);
        expect(Ebur128Mode.fromMpv(null), Ebur128Mode.none);
      });
    });
    group('Ebur128Scaletype (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in Ebur128Scaletype.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(Ebur128Scaletype.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          Ebur128Scaletype.fromMpv('this_will_never_match'),
          Ebur128Scaletype.absolute,
        );
        expect(Ebur128Scaletype.fromMpv(null), Ebur128Scaletype.absolute);
      });
    });
    group('EqualizerPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in EqualizerPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(EqualizerPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          EqualizerPrecision.fromMpv('this_will_never_match'),
          EqualizerPrecision.auto,
        );
        expect(EqualizerPrecision.fromMpv(null), EqualizerPrecision.auto);
      });
    });
    group('EqualizerTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in EqualizerTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(EqualizerTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          EqualizerTransformType.fromMpv('this_will_never_match'),
          EqualizerTransformType.di,
        );
        expect(EqualizerTransformType.fromMpv(null), EqualizerTransformType.di);
      });
    });
    group('EqualizerWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in EqualizerWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(EqualizerWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          EqualizerWidthType.fromMpv('this_will_never_match'),
          EqualizerWidthType.h,
        );
        expect(EqualizerWidthType.fromMpv(null), EqualizerWidthType.h);
      });
    });
    group('FirequalizerScale (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in FirequalizerScale.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(FirequalizerScale.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          FirequalizerScale.fromMpv('this_will_never_match'),
          FirequalizerScale.linlin,
        );
        expect(FirequalizerScale.fromMpv(null), FirequalizerScale.linlin);
      });
    });
    group('FirequalizerWfunc (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in FirequalizerWfunc.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(FirequalizerWfunc.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          FirequalizerWfunc.fromMpv('this_will_never_match'),
          FirequalizerWfunc.rectangular,
        );
        expect(FirequalizerWfunc.fromMpv(null), FirequalizerWfunc.rectangular);
      });
    });
    group('FlangerItype (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in FlangerItype.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(FlangerItype.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          FlangerItype.fromMpv('this_will_never_match'),
          FlangerItype.linear,
        );
        expect(FlangerItype.fromMpv(null), FlangerItype.linear);
      });
    });
    group('FlangerType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in FlangerType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(FlangerType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          FlangerType.fromMpv('this_will_never_match'),
          FlangerType.triangular,
        );
        expect(FlangerType.fromMpv(null), FlangerType.triangular);
      });
    });
    group('HaasSource (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HaasSource.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HaasSource.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(HaasSource.fromMpv('this_will_never_match'), HaasSource.left);
        expect(HaasSource.fromMpv(null), HaasSource.left);
      });
    });
    group('HdcdAnalyzeMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HdcdAnalyzeMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HdcdAnalyzeMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HdcdAnalyzeMode.fromMpv('this_will_never_match'),
          HdcdAnalyzeMode.off,
        );
        expect(HdcdAnalyzeMode.fromMpv(null), HdcdAnalyzeMode.off);
      });
    });
    group('HdcdBitsPerSample (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HdcdBitsPerSample.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HdcdBitsPerSample.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HdcdBitsPerSample.fromMpv('this_will_never_match'),
          HdcdBitsPerSample.n16,
        );
        expect(HdcdBitsPerSample.fromMpv(null), HdcdBitsPerSample.n16);
      });
    });
    group('HighpassPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighpassPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighpassPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighpassPrecision.fromMpv('this_will_never_match'),
          HighpassPrecision.auto,
        );
        expect(HighpassPrecision.fromMpv(null), HighpassPrecision.auto);
      });
    });
    group('HighpassTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighpassTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighpassTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighpassTransformType.fromMpv('this_will_never_match'),
          HighpassTransformType.di,
        );
        expect(HighpassTransformType.fromMpv(null), HighpassTransformType.di);
      });
    });
    group('HighpassWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighpassWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighpassWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighpassWidthType.fromMpv('this_will_never_match'),
          HighpassWidthType.h,
        );
        expect(HighpassWidthType.fromMpv(null), HighpassWidthType.h);
      });
    });
    group('HighshelfPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighshelfPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighshelfPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighshelfPrecision.fromMpv('this_will_never_match'),
          HighshelfPrecision.auto,
        );
        expect(HighshelfPrecision.fromMpv(null), HighshelfPrecision.auto);
      });
    });
    group('HighshelfTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighshelfTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighshelfTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighshelfTransformType.fromMpv('this_will_never_match'),
          HighshelfTransformType.di,
        );
        expect(HighshelfTransformType.fromMpv(null), HighshelfTransformType.di);
      });
    });
    group('HighshelfWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HighshelfWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HighshelfWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          HighshelfWidthType.fromMpv('this_will_never_match'),
          HighshelfWidthType.h,
        );
        expect(HighshelfWidthType.fromMpv(null), HighshelfWidthType.h);
      });
    });
    group('LoudnormPrintFormat (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LoudnormPrintFormat.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LoudnormPrintFormat.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LoudnormPrintFormat.fromMpv('this_will_never_match'),
          LoudnormPrintFormat.none,
        );
        expect(LoudnormPrintFormat.fromMpv(null), LoudnormPrintFormat.none);
      });
    });
    group('LowpassPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowpassPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowpassPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowpassPrecision.fromMpv('this_will_never_match'),
          LowpassPrecision.auto,
        );
        expect(LowpassPrecision.fromMpv(null), LowpassPrecision.auto);
      });
    });
    group('LowpassTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowpassTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowpassTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowpassTransformType.fromMpv('this_will_never_match'),
          LowpassTransformType.di,
        );
        expect(LowpassTransformType.fromMpv(null), LowpassTransformType.di);
      });
    });
    group('LowpassWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowpassWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowpassWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowpassWidthType.fromMpv('this_will_never_match'),
          LowpassWidthType.h,
        );
        expect(LowpassWidthType.fromMpv(null), LowpassWidthType.h);
      });
    });
    group('LowshelfPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowshelfPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowshelfPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowshelfPrecision.fromMpv('this_will_never_match'),
          LowshelfPrecision.auto,
        );
        expect(LowshelfPrecision.fromMpv(null), LowshelfPrecision.auto);
      });
    });
    group('LowshelfTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowshelfTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowshelfTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowshelfTransformType.fromMpv('this_will_never_match'),
          LowshelfTransformType.di,
        );
        expect(LowshelfTransformType.fromMpv(null), LowshelfTransformType.di);
      });
    });
    group('LowshelfWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in LowshelfWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(LowshelfWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          LowshelfWidthType.fromMpv('this_will_never_match'),
          LowshelfWidthType.h,
        );
        expect(LowshelfWidthType.fromMpv(null), LowshelfWidthType.h);
      });
    });
    group('RubberbandChannels (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandChannels.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandChannels.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandChannels.fromMpv('this_will_never_match'),
          RubberbandChannels.apart,
        );
        expect(RubberbandChannels.fromMpv(null), RubberbandChannels.apart);
      });
    });
    group('RubberbandDetector (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandDetector.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandDetector.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandDetector.fromMpv('this_will_never_match'),
          RubberbandDetector.compound,
        );
        expect(RubberbandDetector.fromMpv(null), RubberbandDetector.compound);
      });
    });
    group('RubberbandFormant (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandFormant.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandFormant.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandFormant.fromMpv('this_will_never_match'),
          RubberbandFormant.shifted,
        );
        expect(RubberbandFormant.fromMpv(null), RubberbandFormant.shifted);
      });
    });
    group('RubberbandPhase (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandPhase.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandPhase.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandPhase.fromMpv('this_will_never_match'),
          RubberbandPhase.laminar,
        );
        expect(RubberbandPhase.fromMpv(null), RubberbandPhase.laminar);
      });
    });
    group('RubberbandPitch (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandPitch.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandPitch.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandPitch.fromMpv('this_will_never_match'),
          RubberbandPitch.quality,
        );
        expect(RubberbandPitch.fromMpv(null), RubberbandPitch.quality);
      });
    });
    group('RubberbandSmoothing (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandSmoothing.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandSmoothing.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandSmoothing.fromMpv('this_will_never_match'),
          RubberbandSmoothing.off,
        );
        expect(RubberbandSmoothing.fromMpv(null), RubberbandSmoothing.off);
      });
    });
    group('RubberbandTransients (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandTransients.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandTransients.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandTransients.fromMpv('this_will_never_match'),
          RubberbandTransients.crisp,
        );
        expect(RubberbandTransients.fromMpv(null), RubberbandTransients.crisp);
      });
    });
    group('RubberbandWindow (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in RubberbandWindow.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(RubberbandWindow.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          RubberbandWindow.fromMpv('this_will_never_match'),
          RubberbandWindow.standard,
        );
        expect(RubberbandWindow.fromMpv(null), RubberbandWindow.standard);
      });
    });
    group('SilenceremoveDetection (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in SilenceremoveDetection.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(SilenceremoveDetection.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          SilenceremoveDetection.fromMpv('this_will_never_match'),
          SilenceremoveDetection.avg,
        );
        expect(
          SilenceremoveDetection.fromMpv(null),
          SilenceremoveDetection.avg,
        );
      });
    });
    group('SilenceremoveMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in SilenceremoveMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(SilenceremoveMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          SilenceremoveMode.fromMpv('this_will_never_match'),
          SilenceremoveMode.any,
        );
        expect(SilenceremoveMode.fromMpv(null), SilenceremoveMode.any);
      });
    });
    group('SilenceremoveTimestamp (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in SilenceremoveTimestamp.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(SilenceremoveTimestamp.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          SilenceremoveTimestamp.fromMpv('this_will_never_match'),
          SilenceremoveTimestamp.write,
        );
        expect(
          SilenceremoveTimestamp.fromMpv(null),
          SilenceremoveTimestamp.write,
        );
      });
    });
    group('StereotoolsBmode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in StereotoolsBmode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(StereotoolsBmode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          StereotoolsBmode.fromMpv('this_will_never_match'),
          StereotoolsBmode.balance,
        );
        expect(StereotoolsBmode.fromMpv(null), StereotoolsBmode.balance);
      });
    });
    group('StereotoolsMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in StereotoolsMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(StereotoolsMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          StereotoolsMode.fromMpv('this_will_never_match'),
          StereotoolsMode.lrToLr,
        );
        expect(StereotoolsMode.fromMpv(null), StereotoolsMode.lrToLr);
      });
    });
    group('SurroundLfeMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in SurroundLfeMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(SurroundLfeMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          SurroundLfeMode.fromMpv('this_will_never_match'),
          SurroundLfeMode.add,
        );
        expect(SurroundLfeMode.fromMpv(null), SurroundLfeMode.add);
      });
    });
    group('SurroundWinFunc (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in SurroundWinFunc.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(SurroundWinFunc.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          SurroundWinFunc.fromMpv('this_will_never_match'),
          SurroundWinFunc.rect,
        );
        expect(SurroundWinFunc.fromMpv(null), SurroundWinFunc.rect);
      });
    });
    group('TiltshelfPrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TiltshelfPrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TiltshelfPrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TiltshelfPrecision.fromMpv('this_will_never_match'),
          TiltshelfPrecision.auto,
        );
        expect(TiltshelfPrecision.fromMpv(null), TiltshelfPrecision.auto);
      });
    });
    group('TiltshelfTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TiltshelfTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TiltshelfTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TiltshelfTransformType.fromMpv('this_will_never_match'),
          TiltshelfTransformType.di,
        );
        expect(TiltshelfTransformType.fromMpv(null), TiltshelfTransformType.di);
      });
    });
    group('TiltshelfWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TiltshelfWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TiltshelfWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TiltshelfWidthType.fromMpv('this_will_never_match'),
          TiltshelfWidthType.h,
        );
        expect(TiltshelfWidthType.fromMpv(null), TiltshelfWidthType.h);
      });
    });
    group('TreblePrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TreblePrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TreblePrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TreblePrecision.fromMpv('this_will_never_match'),
          TreblePrecision.auto,
        );
        expect(TreblePrecision.fromMpv(null), TreblePrecision.auto);
      });
    });
    group('TrebleTransformType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TrebleTransformType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TrebleTransformType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TrebleTransformType.fromMpv('this_will_never_match'),
          TrebleTransformType.di,
        );
        expect(TrebleTransformType.fromMpv(null), TrebleTransformType.di);
      });
    });
    group('TrebleWidthType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in TrebleWidthType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(TrebleWidthType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
          TrebleWidthType.fromMpv('this_will_never_match'),
          TrebleWidthType.h,
        );
        expect(TrebleWidthType.fromMpv(null), TrebleWidthType.h);
      });
    });
  });
}
