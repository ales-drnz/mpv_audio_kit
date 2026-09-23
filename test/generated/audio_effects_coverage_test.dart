// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do NOT edit by hand.
//
// Schema-driven coverage of `AudioEffects.toAfChain()` and the
// per-filter `toFilterString()` wire output: every parameter of
// every libavfilter audio filter shipped with this build has at
// least one test pinning the wire shape, and every typed enum
// has its `mpvValue` / `fromMpv` round-trip checked exhaustively.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable, unnecessary_const, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('Per-filter wire coverage', () {
    group('AcompressorSettings (acompressor)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          acompressor: AcompressorSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          acompressor: AcompressorSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_acompressor:lavfi-acompressor');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, attack: 2000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorSettings(
            enabled: true,
            detection: AcompressorDetection.peak,
          );
          expect(s.toFilterString(), contains('detection='));
          expect(s.toFilterString(), contains('detection=peak'));
        },
      );

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_sc` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorSettings(enabled: true, level_sc: 64.0);
          expect(s.toFilterString(), contains('level_sc='));
          expect(s.toFilterString(), contains('level_sc=64.000'));
        },
      );

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(
          enabled: true,
          link: AcompressorLink.maximum,
        );
        expect(s.toFilterString(), contains('link='));
        expect(s.toFilterString(), contains('link=maximum'));
      });

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, makeup: 64.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=64.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(
          enabled: true,
          mode: AcompressorMode.upward,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=upward'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, ratio: 20.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=20.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, release: 9000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=9000.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AcompressorSettings(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            attack: AcompressorSettings.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            attack: AcompressorSettings.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            attack: AcompressorSettings.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `knee` const `kneeMin` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          knee: AcompressorSettings.kneeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `knee` const `kneeMax` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          knee: AcompressorSettings.kneeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `knee` const `kneeDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            knee: AcompressorSettings.kneeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_in: AcompressorSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_in: AcompressorSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_in: AcompressorSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_sc: AcompressorSettings.level_scMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_sc: AcompressorSettings.level_scMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            level_sc: AcompressorSettings.level_scDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            makeup: AcompressorSettings.makeupMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            makeup: AcompressorSettings.makeupMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            makeup: AcompressorSettings.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          mix: AcompressorSettings.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          mix: AcompressorSettings.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          mix: AcompressorSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          ratio: AcompressorSettings.ratioMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AcompressorSettings(
          enabled: true,
          ratio: AcompressorSettings.ratioMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            ratio: AcompressorSettings.ratioDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            release: AcompressorSettings.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            release: AcompressorSettings.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            release: AcompressorSettings.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            threshold: AcompressorSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            threshold: AcompressorSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AcompressorSettings(
            enabled: true,
            threshold: AcompressorSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AcontrastSettings (acontrast)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acontrast: AcontrastSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acontrast: AcontrastSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_acontrast:lavfi-acontrast');
      });

      test(
        'param `contrast` lands in wire when set to a non-default value',
        () {
          final s = const AcontrastSettings(enabled: true, contrast: 100.0);
          expect(s.toFilterString(), contains('contrast='));
          expect(s.toFilterString(), contains('contrast=100.000'));
        },
      );

      test(
        'param `contrast` const `contrastMin` is accepted by toFilterString',
        () {
          final s = AcontrastSettings(
            enabled: true,
            contrast: AcontrastSettings.contrastMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `contrast` const `contrastMax` is accepted by toFilterString',
        () {
          final s = AcontrastSettings(
            enabled: true,
            contrast: AcontrastSettings.contrastMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `contrast` const `contrastDefault` is accepted by toFilterString',
        () {
          final s = AcontrastSettings(
            enabled: true,
            contrast: AcontrastSettings.contrastDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AcrusherSettings (acrusher)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acrusher: AcrusherSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acrusher: AcrusherSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_acrusher:lavfi-acrusher');
      });

      test('param `aa` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, aa: 1.0);
        expect(s.toFilterString(), contains('aa='));
        expect(s.toFilterString(), contains('aa=1.000'));
      });

      test('param `bits` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, bits: 64.0);
        expect(s.toFilterString(), contains('bits='));
        expect(s.toFilterString(), contains('bits=64.000'));
      });

      test('param `dc` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, dc: 4.0);
        expect(s.toFilterString(), contains('dc='));
        expect(s.toFilterString(), contains('dc=4.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `lfo` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, lfo: true);
        expect(s.toFilterString(), contains('lfo='));
      });

      test(
        'param `lforange` lands in wire when set to a non-default value',
        () {
          final s = const AcrusherSettings(enabled: true, lforange: 250.0);
          expect(s.toFilterString(), contains('lforange='));
          expect(s.toFilterString(), contains('lforange=250.000'));
        },
      );

      test('param `lforate` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, lforate: 200.0);
        expect(s.toFilterString(), contains('lforate='));
        expect(s.toFilterString(), contains('lforate=200.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, mix: 1.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=1.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, mode: AcrusherMode.log);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=log'));
      });

      test('param `samples` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, samples: 250.0);
        expect(s.toFilterString(), contains('samples='));
        expect(s.toFilterString(), contains('samples=250.000'));
      });

      test('param `aa` const `aaMin` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, aa: AcrusherSettings.aaMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `aa` const `aaMax` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, aa: AcrusherSettings.aaMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `aa` const `aaDefault` is accepted by toFilterString', () {
        final s = AcrusherSettings(
          enabled: true,
          aa: AcrusherSettings.aaDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bits` const `bitsMin` is accepted by toFilterString', () {
        final s = AcrusherSettings(
          enabled: true,
          bits: AcrusherSettings.bitsMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bits` const `bitsMax` is accepted by toFilterString', () {
        final s = AcrusherSettings(
          enabled: true,
          bits: AcrusherSettings.bitsMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bits` const `bitsDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            bits: AcrusherSettings.bitsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dc` const `dcMin` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, dc: AcrusherSettings.dcMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dc` const `dcMax` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, dc: AcrusherSettings.dcMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dc` const `dcDefault` is accepted by toFilterString', () {
        final s = AcrusherSettings(
          enabled: true,
          dc: AcrusherSettings.dcDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_in: AcrusherSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_in: AcrusherSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_in: AcrusherSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_out: AcrusherSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_out: AcrusherSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            level_out: AcrusherSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeMin` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforange: AcrusherSettings.lforangeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeMax` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforange: AcrusherSettings.lforangeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforange` const `lforangeDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforange: AcrusherSettings.lforangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateMin` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforate: AcrusherSettings.lforateMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateMax` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforate: AcrusherSettings.lforateMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lforate` const `lforateDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            lforate: AcrusherSettings.lforateDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, mix: AcrusherSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AcrusherSettings(enabled: true, mix: AcrusherSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AcrusherSettings(
          enabled: true,
          mix: AcrusherSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `samples` const `samplesMin` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            samples: AcrusherSettings.samplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMax` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            samples: AcrusherSettings.samplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesDefault` is accepted by toFilterString',
        () {
          final s = AcrusherSettings(
            enabled: true,
            samples: AcrusherSettings.samplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdeclickSettings (adeclick)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adeclick: AdeclickSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adeclick: AdeclickSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_adeclick:lavfi-adeclick');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, a: 25.0);
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=25.000'));
      });

      test('param `arorder` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, arorder: 25.0);
        expect(s.toFilterString(), contains('arorder='));
        expect(s.toFilterString(), contains('arorder=25.000'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, b: 10.0);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=10.000'));
      });

      test('param `burst` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, burst: 10.0);
        expect(s.toFilterString(), contains('burst='));
        expect(s.toFilterString(), contains('burst=10.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, m: AdeclickM.a);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=a'));
      });

      test('param `method` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, method: AdeclickM.a);
        expect(s.toFilterString(), contains('method='));
        expect(s.toFilterString(), contains('method=a'));
      });

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, o: 95.0);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=95.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, overlap: 95.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=95.000'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, t: 100.0);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=100.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdeclickSettings(enabled: true, threshold: 100.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=100.000'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, w: 100.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=100.000'));
      });

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const AdeclickSettings(enabled: true, window: 100.0);
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=100.000'));
      });

      test('param `a` const `aMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, a: AdeclickSettings.aMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a` const `aMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, a: AdeclickSettings.aMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a` const `aDefault` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, a: AdeclickSettings.aDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `arorder` const `arorderMin` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            arorder: AdeclickSettings.arorderMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderMax` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            arorder: AdeclickSettings.arorderMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderDefault` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            arorder: AdeclickSettings.arorderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, b: AdeclickSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, b: AdeclickSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, b: AdeclickSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `burst` const `burstMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(
          enabled: true,
          burst: AdeclickSettings.burstMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `burst` const `burstMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(
          enabled: true,
          burst: AdeclickSettings.burstMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `burst` const `burstDefault` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            burst: AdeclickSettings.burstDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `o` const `oMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, o: AdeclickSettings.oMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, o: AdeclickSettings.oMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oDefault` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, o: AdeclickSettings.oDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            overlap: AdeclickSettings.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            overlap: AdeclickSettings.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            overlap: AdeclickSettings.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `t` const `tMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, t: AdeclickSettings.tMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, t: AdeclickSettings.tMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tDefault` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, t: AdeclickSettings.tDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            threshold: AdeclickSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            threshold: AdeclickSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            threshold: AdeclickSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, w: AdeclickSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, w: AdeclickSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = AdeclickSettings(enabled: true, w: AdeclickSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `window` const `windowMin` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            window: AdeclickSettings.windowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMax` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            window: AdeclickSettings.windowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowDefault` is accepted by toFilterString',
        () {
          final s = AdeclickSettings(
            enabled: true,
            window: AdeclickSettings.windowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdeclipSettings (adeclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adeclip: AdeclipSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adeclip: AdeclipSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_adeclip:lavfi-adeclip');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, a: 25.0);
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=25.000'));
      });

      test('param `arorder` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, arorder: 25.0);
        expect(s.toFilterString(), contains('arorder='));
        expect(s.toFilterString(), contains('arorder=25.000'));
      });

      test('param `hsize` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, hsize: 9999);
        expect(s.toFilterString(), contains('hsize='));
        expect(s.toFilterString(), contains('hsize=9999'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, m: AdeclipM.a);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=a'));
      });

      test('param `method` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, method: AdeclipM.a);
        expect(s.toFilterString(), contains('method='));
        expect(s.toFilterString(), contains('method=a'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, n: 9999);
        expect(s.toFilterString(), contains('n='));
        expect(s.toFilterString(), contains('n=9999'));
      });

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, o: 95.0);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=95.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, overlap: 95.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=95.000'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, t: 100.0);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=100.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdeclipSettings(enabled: true, threshold: 100.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=100.000'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, w: 100.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=100.000'));
      });

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const AdeclipSettings(enabled: true, window: 100.0);
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=100.000'));
      });

      test('param `a` const `aMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, a: AdeclipSettings.aMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a` const `aMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, a: AdeclipSettings.aMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a` const `aDefault` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, a: AdeclipSettings.aDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `arorder` const `arorderMin` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            arorder: AdeclipSettings.arorderMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderMax` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            arorder: AdeclipSettings.arorderMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `arorder` const `arorderDefault` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            arorder: AdeclipSettings.arorderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `hsize` const `hsizeMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(
          enabled: true,
          hsize: AdeclipSettings.hsizeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hsize` const `hsizeMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(
          enabled: true,
          hsize: AdeclipSettings.hsizeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `hsize` const `hsizeDefault` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            hsize: AdeclipSettings.hsizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `n` const `nMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, n: AdeclipSettings.nMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `n` const `nMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, n: AdeclipSettings.nMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `n` const `nDefault` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, n: AdeclipSettings.nDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, o: AdeclipSettings.oMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, o: AdeclipSettings.oMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oDefault` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, o: AdeclipSettings.oDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            overlap: AdeclipSettings.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            overlap: AdeclipSettings.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            overlap: AdeclipSettings.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `t` const `tMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, t: AdeclipSettings.tMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, t: AdeclipSettings.tMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tDefault` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, t: AdeclipSettings.tDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            threshold: AdeclipSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            threshold: AdeclipSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            threshold: AdeclipSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, w: AdeclipSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, w: AdeclipSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = AdeclipSettings(enabled: true, w: AdeclipSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `window` const `windowMin` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            window: AdeclipSettings.windowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowMax` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            window: AdeclipSettings.windowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `window` const `windowDefault` is accepted by toFilterString',
        () {
          final s = AdeclipSettings(
            enabled: true,
            window: AdeclipSettings.windowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdecorrelateSettings (adecorrelate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          adecorrelate: AdecorrelateSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          adecorrelate: AdecorrelateSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_adecorrelate:lavfi-adecorrelate');
      });

      test('param `seed` lands in wire when set to a non-default value', () {
        final s = const AdecorrelateSettings(enabled: true, seed: 4294967295);
        expect(s.toFilterString(), contains('seed='));
        expect(s.toFilterString(), contains('seed=4294967295'));
      });

      test('param `stages` lands in wire when set to a non-default value', () {
        final s = const AdecorrelateSettings(enabled: true, stages: 16);
        expect(s.toFilterString(), contains('stages='));
        expect(s.toFilterString(), contains('stages=16'));
      });

      test('param `seed` const `seedMin` is accepted by toFilterString', () {
        final s = AdecorrelateSettings(
          enabled: true,
          seed: AdecorrelateSettings.seedMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `seed` const `seedMax` is accepted by toFilterString', () {
        final s = AdecorrelateSettings(
          enabled: true,
          seed: AdecorrelateSettings.seedMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `seed` const `seedDefault` is accepted by toFilterString',
        () {
          final s = AdecorrelateSettings(
            enabled: true,
            seed: AdecorrelateSettings.seedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesMin` is accepted by toFilterString',
        () {
          final s = AdecorrelateSettings(
            enabled: true,
            stages: AdecorrelateSettings.stagesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesMax` is accepted by toFilterString',
        () {
          final s = AdecorrelateSettings(
            enabled: true,
            stages: AdecorrelateSettings.stagesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stages` const `stagesDefault` is accepted by toFilterString',
        () {
          final s = AdecorrelateSettings(
            enabled: true,
            stages: AdecorrelateSettings.stagesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdelaySettings (adelay)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adelay: AdelaySettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adelay: AdelaySettings(enabled: true));
        expect(fx.toAfChain(), '@aek_adelay:lavfi-adelay');
      });

      test('param `all` lands in wire when set to a non-default value', () {
        final s = const AdelaySettings(enabled: true, all: true);
        expect(s.toFilterString(), contains('all='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const AdelaySettings(enabled: true, delays: 'wire_test_alt');
        expect(s.toFilterString(), contains('delays='));
      });
    });
    group('AdenormSettings (adenorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adenorm: AdenormSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adenorm: AdenormSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_adenorm:lavfi-adenorm');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AdenormSettings(enabled: true, level: -90.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=-90.000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AdenormSettings(enabled: true, type: AdenormType.ac);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=ac'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AdenormSettings(
          enabled: true,
          level: AdenormSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AdenormSettings(
          enabled: true,
          level: AdenormSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AdenormSettings(
            enabled: true,
            level: AdenormSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AderivativeSettings (aderivative)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          aderivative: AderivativeSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          aderivative: AderivativeSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_aderivative:lavfi-aderivative');
      });
    });
    group('AdrcSettings (adrc)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adrc: AdrcSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adrc: AdrcSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_adrc:lavfi-adrc');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AdrcSettings(enabled: true, attack: 1000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=1000.000'));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AdrcSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AdrcSettings(enabled: true, release: 2000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test(
        'param `transfer` lands in wire when set to a non-default value',
        () {
          final s = const AdrcSettings(
            enabled: true,
            transfer: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('transfer='));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AdrcSettings(enabled: true, attack: AdrcSettings.attackMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AdrcSettings(enabled: true, attack: AdrcSettings.attackMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AdrcSettings(
            enabled: true,
            attack: AdrcSettings.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AdrcSettings(
            enabled: true,
            release: AdrcSettings.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AdrcSettings(
            enabled: true,
            release: AdrcSettings.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AdrcSettings(
            enabled: true,
            release: AdrcSettings.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdynamicequalizerSettings (adynamicequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          adynamicequalizer: AdynamicequalizerSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          adynamicequalizer: AdynamicequalizerSettings(enabled: true),
        );
        expect(
          fx.toAfChain(),
          '@aek_adynamicequalizer:lavfi-adynamicequalizer',
        );
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          attack: 2000.0,
        );
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test('param `auto` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          auto: AdynamicequalizerAuto.disabled,
        );
        expect(s.toFilterString(), contains('auto='));
        expect(s.toFilterString(), contains('auto=disabled'));
      });

      test(
        'param `dfrequency` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerSettings(
            enabled: true,
            dfrequency: 1000000.0,
          );
          expect(s.toFilterString(), contains('dfrequency='));
          expect(s.toFilterString(), contains('dfrequency=1000000.000'));
        },
      );

      test('param `dftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          dftype: AdynamicequalizerDftype.lowpass,
        );
        expect(s.toFilterString(), contains('dftype='));
        expect(s.toFilterString(), contains('dftype=lowpass'));
      });

      test(
        'param `dqfactor` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerSettings(
            enabled: true,
            dqfactor: 1000.0,
          );
          expect(s.toFilterString(), contains('dqfactor='));
          expect(s.toFilterString(), contains('dqfactor=1000.000'));
        },
      );

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          makeup: 1000.0,
        );
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=1000.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          mode: AdynamicequalizerMode.cutbelow,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=cutbelow'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerSettings(
            enabled: true,
            precision: AdynamicequalizerPrecision.float,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=float'));
        },
      );

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(enabled: true, range: 2000.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=2000.000'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(enabled: true, ratio: 30.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=30.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          release: 2000.0,
        );
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test(
        'param `tfrequency` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerSettings(
            enabled: true,
            tfrequency: 1000000.0,
          );
          expect(s.toFilterString(), contains('tfrequency='));
          expect(s.toFilterString(), contains('tfrequency=1000000.000'));
        },
      );

      test('param `tftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
          enabled: true,
          tftype: AdynamicequalizerTftype.lowshelf,
        );
        expect(s.toFilterString(), contains('tftype='));
        expect(s.toFilterString(), contains('tftype=lowshelf'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicequalizerSettings(
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
          final s = const AdynamicequalizerSettings(
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
          final s = AdynamicequalizerSettings(
            enabled: true,
            attack: AdynamicequalizerSettings.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            attack: AdynamicequalizerSettings.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            attack: AdynamicequalizerSettings.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dfrequency: AdynamicequalizerSettings.dfrequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dfrequency: AdynamicequalizerSettings.dfrequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dfrequency` const `dfrequencyDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dfrequency: AdynamicequalizerSettings.dfrequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dqfactor: AdynamicequalizerSettings.dqfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dqfactor: AdynamicequalizerSettings.dqfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `dqfactor` const `dqfactorDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            dqfactor: AdynamicequalizerSettings.dqfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            makeup: AdynamicequalizerSettings.makeupMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            makeup: AdynamicequalizerSettings.makeupMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            makeup: AdynamicequalizerSettings.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = AdynamicequalizerSettings(
          enabled: true,
          range: AdynamicequalizerSettings.rangeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = AdynamicequalizerSettings(
          enabled: true,
          range: AdynamicequalizerSettings.rangeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            range: AdynamicequalizerSettings.rangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AdynamicequalizerSettings(
          enabled: true,
          ratio: AdynamicequalizerSettings.ratioMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AdynamicequalizerSettings(
          enabled: true,
          ratio: AdynamicequalizerSettings.ratioMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            ratio: AdynamicequalizerSettings.ratioDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            release: AdynamicequalizerSettings.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            release: AdynamicequalizerSettings.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            release: AdynamicequalizerSettings.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tfrequency: AdynamicequalizerSettings.tfrequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tfrequency: AdynamicequalizerSettings.tfrequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tfrequency` const `tfrequencyDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tfrequency: AdynamicequalizerSettings.tfrequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            threshold: AdynamicequalizerSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            threshold: AdynamicequalizerSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            threshold: AdynamicequalizerSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorMin` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tqfactor: AdynamicequalizerSettings.tqfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorMax` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tqfactor: AdynamicequalizerSettings.tqfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `tqfactor` const `tqfactorDefault` is accepted by toFilterString',
        () {
          final s = AdynamicequalizerSettings(
            enabled: true,
            tqfactor: AdynamicequalizerSettings.tqfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AdynamicsmoothSettings (adynamicsmooth)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          adynamicsmooth: AdynamicsmoothSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          adynamicsmooth: AdynamicsmoothSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_adynamicsmooth:lavfi-adynamicsmooth');
      });

      test(
        'param `basefreq` lands in wire when set to a non-default value',
        () {
          final s = const AdynamicsmoothSettings(
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
          final s = const AdynamicsmoothSettings(
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
          final s = AdynamicsmoothSettings(
            enabled: true,
            basefreq: AdynamicsmoothSettings.basefreqMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `basefreq` const `basefreqMax` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothSettings(
            enabled: true,
            basefreq: AdynamicsmoothSettings.basefreqMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `basefreq` const `basefreqDefault` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothSettings(
            enabled: true,
            basefreq: AdynamicsmoothSettings.basefreqDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityMin` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothSettings(
            enabled: true,
            sensitivity: AdynamicsmoothSettings.sensitivityMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityMax` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothSettings(
            enabled: true,
            sensitivity: AdynamicsmoothSettings.sensitivityMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sensitivity` const `sensitivityDefault` is accepted by toFilterString',
        () {
          final s = AdynamicsmoothSettings(
            enabled: true,
            sensitivity: AdynamicsmoothSettings.sensitivityDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AechoSettings (aecho)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aecho: AechoSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aecho: AechoSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aecho:lavfi-aecho');
      });

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const AechoSettings(enabled: true, decays: 'wire_test_alt');
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const AechoSettings(enabled: true, delays: 'wire_test_alt');
        expect(s.toFilterString(), contains('delays='));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const AechoSettings(enabled: true, in_gain: 1.0);
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test(
        'param `out_gain` lands in wire when set to a non-default value',
        () {
          final s = const AechoSettings(enabled: true, out_gain: 1.0);
          expect(s.toFilterString(), contains('out_gain='));
          expect(s.toFilterString(), contains('out_gain=1.000'));
        },
      );

      test(
        'param `in_gain` const `in_gainMin` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            in_gain: AechoSettings.in_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainMax` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            in_gain: AechoSettings.in_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainDefault` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            in_gain: AechoSettings.in_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMin` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            out_gain: AechoSettings.out_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMax` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            out_gain: AechoSettings.out_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainDefault` is accepted by toFilterString',
        () {
          final s = AechoSettings(
            enabled: true,
            out_gain: AechoSettings.out_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AemphasisSettings (aemphasis)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aemphasis: AemphasisSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aemphasis: AemphasisSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aemphasis:lavfi-aemphasis');
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AemphasisSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AemphasisSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AemphasisSettings(
          enabled: true,
          mode: AemphasisMode.production,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=production'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AemphasisSettings(
          enabled: true,
          type: AemphasisType.col,
        );
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=col'));
      });

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_in: AemphasisSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_in: AemphasisSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_in: AemphasisSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_out: AemphasisSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_out: AemphasisSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = AemphasisSettings(
            enabled: true,
            level_out: AemphasisSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AevalSettings (aeval)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          aeval: AevalSettings(enabled: false, exprs: 'val(0)|val(1)'),
        );
        expect(fx.toAfChain(), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = AudioEffects(
            aeval: AevalSettings(enabled: true, exprs: 'val(0)|val(1)'),
          );
          expect(fx.toAfChain(), startsWith('@aek_aeval:lavfi-aeval'));
          expect(fx.toAfChain(), contains('exprs='));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const AevalSettings(
          enabled: true,
          c: 'wire_test_alt',
          exprs: 'val(0)|val(1)',
        );
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channel_layout` lands in wire when set to a non-default value',
        () {
          final s = const AevalSettings(
            enabled: true,
            channel_layout: 'wire_test_alt',
            exprs: 'val(0)|val(1)',
          );
          expect(s.toFilterString(), contains('channel_layout='));
        },
      );

      test('param `exprs` lands in wire when set to a non-default value', () {
        final s = const AevalSettings(enabled: true, exprs: 'wire_test_alt');
        expect(s.toFilterString(), contains('exprs='));
      });
    });
    group('AexciterSettings (aexciter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aexciter: AexciterSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aexciter: AexciterSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aexciter:lavfi-aexciter');
      });

      test('param `amount` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, amount: 64.0);
        expect(s.toFilterString(), contains('amount='));
        expect(s.toFilterString(), contains('amount=64.000'));
      });

      test('param `blend` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, blend: 10.0);
        expect(s.toFilterString(), contains('blend='));
        expect(s.toFilterString(), contains('blend=10.000'));
      });

      test('param `ceil` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, ceil: 20000.0);
        expect(s.toFilterString(), contains('ceil='));
        expect(s.toFilterString(), contains('ceil=20000.000'));
      });

      test('param `drive` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, drive: 10.0);
        expect(s.toFilterString(), contains('drive='));
        expect(s.toFilterString(), contains('drive=10.000'));
      });

      test('param `freq` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, freq: 12000.0);
        expect(s.toFilterString(), contains('freq='));
        expect(s.toFilterString(), contains('freq=12000.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AexciterSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AexciterSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `listen` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, listen: true);
        expect(s.toFilterString(), contains('listen='));
      });

      test(
        'param `amount` const `amountMin` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            amount: AexciterSettings.amountMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountMax` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            amount: AexciterSettings.amountMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            amount: AexciterSettings.amountDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `blend` const `blendMin` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          blend: AexciterSettings.blendMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blend` const `blendMax` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          blend: AexciterSettings.blendMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blend` const `blendDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            blend: AexciterSettings.blendDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ceil` const `ceilMin` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          ceil: AexciterSettings.ceilMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ceil` const `ceilMax` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          ceil: AexciterSettings.ceilMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ceil` const `ceilDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            ceil: AexciterSettings.ceilDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `drive` const `driveMin` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          drive: AexciterSettings.driveMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `drive` const `driveMax` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          drive: AexciterSettings.driveMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `drive` const `driveDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            drive: AexciterSettings.driveDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `freq` const `freqMin` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          freq: AexciterSettings.freqMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `freq` const `freqMax` is accepted by toFilterString', () {
        final s = AexciterSettings(
          enabled: true,
          freq: AexciterSettings.freqMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `freq` const `freqDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            freq: AexciterSettings.freqDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_in: AexciterSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_in: AexciterSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_in: AexciterSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_out: AexciterSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_out: AexciterSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = AexciterSettings(
            enabled: true,
            level_out: AexciterSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfadeSettings (afade)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afade: AfadeSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afade: AfadeSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_afade:lavfi-afade');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, c: AfadeCurve.nofade);
        expect(s.toFilterString(), contains('c='));
        expect(s.toFilterString(), contains('c=nofade'));
      });

      test('param `curve` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, curve: AfadeCurve.nofade);
        expect(s.toFilterString(), contains('curve='));
        expect(s.toFilterString(), contains('curve=nofade'));
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(
          enabled: true,
          d: const Duration(microseconds: 1000000),
        );
        expect(s.toFilterString(), contains('d='));
      });

      test(
        'param `duration` lands in wire when set to a non-default value',
        () {
          final s = const AfadeSettings(
            enabled: true,
            duration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('duration='));
        },
      );

      test(
        'param `nb_samples` lands in wire when set to a non-default value',
        () {
          final s = const AfadeSettings(
            enabled: true,
            nb_samples: 9223372036854775807,
          );
          expect(s.toFilterString(), contains('nb_samples='));
          expect(
            s.toFilterString(),
            contains('nb_samples=9223372036854775807'),
          );
        },
      );

      test('param `ns` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, ns: 9223372036854775807);
        expect(s.toFilterString(), contains('ns='));
        expect(s.toFilterString(), contains('ns=9223372036854775807'));
      });

      test('param `silence` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, silence: 1.0);
        expect(s.toFilterString(), contains('silence='));
        expect(s.toFilterString(), contains('silence=1.000'));
      });

      test('param `ss` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, ss: 9223372036854775807);
        expect(s.toFilterString(), contains('ss='));
        expect(s.toFilterString(), contains('ss=9223372036854775807'));
      });

      test('param `st` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(
          enabled: true,
          st: const Duration(microseconds: 1000000),
        );
        expect(s.toFilterString(), contains('st='));
      });

      test(
        'param `start_sample` lands in wire when set to a non-default value',
        () {
          final s = const AfadeSettings(
            enabled: true,
            start_sample: 9223372036854775807,
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
          final s = const AfadeSettings(
            enabled: true,
            start_time: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_time='));
        },
      );

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, t: AfadeType.out);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=out'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, type: AfadeType.out);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=out'));
      });

      test('param `unity` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, unity: 0.0);
        expect(s.toFilterString(), contains('unity='));
        expect(s.toFilterString(), contains('unity=0.000'));
      });

      test(
        'param `nb_samples` const `nb_samplesMin` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            nb_samples: AfadeSettings.nb_samplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `nb_samples` const `nb_samplesMax` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            nb_samples: AfadeSettings.nb_samplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `nb_samples` const `nb_samplesDefault` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            nb_samples: AfadeSettings.nb_samplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ns` const `nsMin` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ns: AfadeSettings.nsMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ns` const `nsMax` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ns: AfadeSettings.nsMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ns` const `nsDefault` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ns: AfadeSettings.nsDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `silence` const `silenceMin` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            silence: AfadeSettings.silenceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `silence` const `silenceMax` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            silence: AfadeSettings.silenceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `silence` const `silenceDefault` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            silence: AfadeSettings.silenceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ss` const `ssMin` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ss: AfadeSettings.ssMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ss` const `ssMax` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ss: AfadeSettings.ssMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ss` const `ssDefault` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, ss: AfadeSettings.ssDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `start_sample` const `start_sampleMin` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            start_sample: AfadeSettings.start_sampleMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_sample` const `start_sampleMax` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            start_sample: AfadeSettings.start_sampleMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_sample` const `start_sampleDefault` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            start_sample: AfadeSettings.start_sampleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `unity` const `unityMin` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, unity: AfadeSettings.unityMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `unity` const `unityMax` is accepted by toFilterString', () {
        final s = AfadeSettings(enabled: true, unity: AfadeSettings.unityMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `unity` const `unityDefault` is accepted by toFilterString',
        () {
          final s = AfadeSettings(
            enabled: true,
            unity: AfadeSettings.unityDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfftdnSettings (afftdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afftdn: AfftdnSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afftdn: AfftdnSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_afftdn:lavfi-afftdn');
      });

      test('param `ad` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, ad: 1.0);
        expect(s.toFilterString(), contains('ad='));
        expect(s.toFilterString(), contains('ad=1.000'));
      });

      test(
        'param `adaptivity` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, adaptivity: 1.0);
          expect(s.toFilterString(), contains('adaptivity='));
          expect(s.toFilterString(), contains('adaptivity=1.000'));
        },
      );

      test(
        'param `band_multiplier` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, band_multiplier: 5.0);
          expect(s.toFilterString(), contains('band_multiplier='));
          expect(s.toFilterString(), contains('band_multiplier=5.000'));
        },
      );

      test(
        'param `band_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(
            enabled: true,
            band_noise: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('band_noise='));
        },
      );

      test('param `bm` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, bm: 5.0);
        expect(s.toFilterString(), contains('bm='));
        expect(s.toFilterString(), contains('bm=5.000'));
      });

      test('param `bn` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, bn: 'wire_test_alt');
        expect(s.toFilterString(), contains('bn='));
      });

      test(
        'param `floor_offset` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, floor_offset: 2.0);
          expect(s.toFilterString(), contains('floor_offset='));
          expect(s.toFilterString(), contains('floor_offset=2.000'));
        },
      );

      test('param `fo` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, fo: 2.0);
        expect(s.toFilterString(), contains('fo='));
        expect(s.toFilterString(), contains('fo=2.000'));
      });

      test(
        'param `gain_smooth` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, gain_smooth: 50);
          expect(s.toFilterString(), contains('gain_smooth='));
          expect(s.toFilterString(), contains('gain_smooth=50'));
        },
      );

      test('param `gs` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, gs: 50);
        expect(s.toFilterString(), contains('gs='));
        expect(s.toFilterString(), contains('gs=50'));
      });

      test('param `nf` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, nf: -20.0);
        expect(s.toFilterString(), contains('nf='));
        expect(s.toFilterString(), contains('nf=-20.000'));
      });

      test('param `nl` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, nl: AfftdnLink.none);
        expect(s.toFilterString(), contains('nl='));
        expect(s.toFilterString(), contains('nl=none'));
      });

      test(
        'param `noise_floor` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, noise_floor: -20.0);
          expect(s.toFilterString(), contains('noise_floor='));
          expect(s.toFilterString(), contains('noise_floor=-20.000'));
        },
      );

      test(
        'param `noise_link` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(
            enabled: true,
            noise_link: AfftdnLink.none,
          );
          expect(s.toFilterString(), contains('noise_link='));
          expect(s.toFilterString(), contains('noise_link=none'));
        },
      );

      test(
        'param `noise_reduction` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, noise_reduction: 97.0);
          expect(s.toFilterString(), contains('noise_reduction='));
          expect(s.toFilterString(), contains('noise_reduction=97.000'));
        },
      );

      test(
        'param `noise_type` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(
            enabled: true,
            noise_type: AfftdnType.w,
          );
          expect(s.toFilterString(), contains('noise_type='));
          expect(s.toFilterString(), contains('noise_type=w'));
        },
      );

      test('param `nr` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, nr: 97.0);
        expect(s.toFilterString(), contains('nr='));
        expect(s.toFilterString(), contains('nr=97.000'));
      });

      test('param `nt` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, nt: AfftdnType.w);
        expect(s.toFilterString(), contains('nt='));
        expect(s.toFilterString(), contains('nt=w'));
      });

      test('param `om` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, om: AfftdnMode.input);
        expect(s.toFilterString(), contains('om='));
        expect(s.toFilterString(), contains('om=input'));
      });

      test(
        'param `output_mode` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(
            enabled: true,
            output_mode: AfftdnMode.input,
          );
          expect(s.toFilterString(), contains('output_mode='));
          expect(s.toFilterString(), contains('output_mode=input'));
        },
      );

      test(
        'param `residual_floor` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, residual_floor: -20.0);
          expect(s.toFilterString(), contains('residual_floor='));
          expect(s.toFilterString(), contains('residual_floor=-20.000'));
        },
      );

      test('param `rf` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, rf: -20.0);
        expect(s.toFilterString(), contains('rf='));
        expect(s.toFilterString(), contains('rf=-20.000'));
      });

      test(
        'param `sample_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(
            enabled: true,
            sample_noise: AfftdnSample.start,
          );
          expect(s.toFilterString(), contains('sample_noise='));
          expect(s.toFilterString(), contains('sample_noise=start'));
        },
      );

      test('param `sn` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, sn: AfftdnSample.start);
        expect(s.toFilterString(), contains('sn='));
        expect(s.toFilterString(), contains('sn=start'));
      });

      test('param `tn` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, tn: true);
        expect(s.toFilterString(), contains('tn='));
      });

      test('param `tr` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, tr: true);
        expect(s.toFilterString(), contains('tr='));
      });

      test(
        'param `track_noise` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, track_noise: true);
          expect(s.toFilterString(), contains('track_noise='));
        },
      );

      test(
        'param `track_residual` lands in wire when set to a non-default value',
        () {
          final s = const AfftdnSettings(enabled: true, track_residual: true);
          expect(s.toFilterString(), contains('track_residual='));
        },
      );

      test('param `ad` const `adMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, ad: AfftdnSettings.adMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ad` const `adMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, ad: AfftdnSettings.adMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ad` const `adDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, ad: AfftdnSettings.adDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `adaptivity` const `adaptivityMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            adaptivity: AfftdnSettings.adaptivityMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptivity` const `adaptivityMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            adaptivity: AfftdnSettings.adaptivityMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptivity` const `adaptivityDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            adaptivity: AfftdnSettings.adaptivityDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `band_multiplierMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            band_multiplier: AfftdnSettings.band_multiplierMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `band_multiplierMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            band_multiplier: AfftdnSettings.band_multiplierMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `band_multiplier` const `band_multiplierDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            band_multiplier: AfftdnSettings.band_multiplierDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bm` const `bmMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, bm: AfftdnSettings.bmMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bm` const `bmMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, bm: AfftdnSettings.bmMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bm` const `bmDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, bm: AfftdnSettings.bmDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `floor_offset` const `floor_offsetMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            floor_offset: AfftdnSettings.floor_offsetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `floor_offset` const `floor_offsetMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            floor_offset: AfftdnSettings.floor_offsetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `floor_offset` const `floor_offsetDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            floor_offset: AfftdnSettings.floor_offsetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fo` const `foMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, fo: AfftdnSettings.foMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fo` const `foMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, fo: AfftdnSettings.foMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fo` const `foDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, fo: AfftdnSettings.foDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain_smooth` const `gain_smoothMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            gain_smooth: AfftdnSettings.gain_smoothMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gain_smooth` const `gain_smoothMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            gain_smooth: AfftdnSettings.gain_smoothMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gain_smooth` const `gain_smoothDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            gain_smooth: AfftdnSettings.gain_smoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gs` const `gsMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, gs: AfftdnSettings.gsMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gs` const `gsMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, gs: AfftdnSettings.gsMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gs` const `gsDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, gs: AfftdnSettings.gsDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `nf` const `nfMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nf: AfftdnSettings.nfMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `nf` const `nfMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nf: AfftdnSettings.nfMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `nf` const `nfDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nf: AfftdnSettings.nfDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `noise_floor` const `noise_floorMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_floor: AfftdnSettings.noise_floorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_floor` const `noise_floorMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_floor: AfftdnSettings.noise_floorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_floor` const `noise_floorDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_floor: AfftdnSettings.noise_floorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noise_reductionMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_reduction: AfftdnSettings.noise_reductionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noise_reductionMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_reduction: AfftdnSettings.noise_reductionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `noise_reduction` const `noise_reductionDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            noise_reduction: AfftdnSettings.noise_reductionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `nr` const `nrMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nr: AfftdnSettings.nrMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `nr` const `nrMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nr: AfftdnSettings.nrMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `nr` const `nrDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, nr: AfftdnSettings.nrDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `residual_floor` const `residual_floorMin` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            residual_floor: AfftdnSettings.residual_floorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `residual_floor` const `residual_floorMax` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            residual_floor: AfftdnSettings.residual_floorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `residual_floor` const `residual_floorDefault` is accepted by toFilterString',
        () {
          final s = AfftdnSettings(
            enabled: true,
            residual_floor: AfftdnSettings.residual_floorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `rf` const `rfMin` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, rf: AfftdnSettings.rfMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rf` const `rfMax` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, rf: AfftdnSettings.rfMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rf` const `rfDefault` is accepted by toFilterString', () {
        final s = AfftdnSettings(enabled: true, rf: AfftdnSettings.rfDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AfftfiltSettings (afftfilt)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afftfilt: AfftfiltSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afftfilt: AfftfiltSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_afftfilt:lavfi-afftfilt');
      });

      test('param `imag` lands in wire when set to a non-default value', () {
        final s = const AfftfiltSettings(enabled: true, imag: 'wire_test_alt');
        expect(s.toFilterString(), contains('imag='));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AfftfiltSettings(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `real` lands in wire when set to a non-default value', () {
        final s = const AfftfiltSettings(enabled: true, real: 'wire_test_alt');
        expect(s.toFilterString(), contains('real='));
      });

      test(
        'param `win_func` lands in wire when set to a non-default value',
        () {
          final s = const AfftfiltSettings(
            enabled: true,
            win_func: AfftfiltWinFunc.rect,
          );
          expect(s.toFilterString(), contains('win_func='));
          expect(s.toFilterString(), contains('win_func=rect'));
        },
      );

      test(
        'param `win_size` lands in wire when set to a non-default value',
        () {
          final s = const AfftfiltSettings(enabled: true, win_size: 131072);
          expect(s.toFilterString(), contains('win_size='));
          expect(s.toFilterString(), contains('win_size=131072'));
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            overlap: AfftfiltSettings.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            overlap: AfftfiltSettings.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            overlap: AfftfiltSettings.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `win_sizeMin` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            win_size: AfftfiltSettings.win_sizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `win_sizeMax` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            win_size: AfftfiltSettings.win_sizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `win_sizeDefault` is accepted by toFilterString',
        () {
          final s = AfftfiltSettings(
            enabled: true,
            win_size: AfftfiltSettings.win_sizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AformatSettings (aformat)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aformat: AformatSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aformat: AformatSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aformat:lavfi-aformat');
      });

      test(
        'param `channel_layouts` lands in wire when set to a non-default value',
        () {
          final s = const AformatSettings(
            enabled: true,
            channel_layouts: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channel_layouts='));
        },
      );

      test('param `cl` lands in wire when set to a non-default value', () {
        final s = const AformatSettings(enabled: true, cl: 'wire_test_alt');
        expect(s.toFilterString(), contains('cl='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const AformatSettings(enabled: true, f: 'wire_test_alt');
        expect(s.toFilterString(), contains('f='));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const AformatSettings(enabled: true, r: 'wire_test_alt');
        expect(s.toFilterString(), contains('r='));
      });

      test(
        'param `sample_fmts` lands in wire when set to a non-default value',
        () {
          final s = const AformatSettings(
            enabled: true,
            sample_fmts: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('sample_fmts='));
        },
      );

      test(
        'param `sample_rates` lands in wire when set to a non-default value',
        () {
          final s = const AformatSettings(
            enabled: true,
            sample_rates: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('sample_rates='));
        },
      );
    });
    group('AfreqshiftSettings (afreqshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afreqshift: AfreqshiftSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afreqshift: AfreqshiftSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_afreqshift:lavfi-afreqshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, order: 16);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=16'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, shift: 2147483647.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=2147483647.000'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          level: AfreqshiftSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          level: AfreqshiftSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftSettings(
            enabled: true,
            level: AfreqshiftSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          order: AfreqshiftSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          order: AfreqshiftSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftSettings(
            enabled: true,
            order: AfreqshiftSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          shift: AfreqshiftSettings.shiftMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = AfreqshiftSettings(
          enabled: true,
          shift: AfreqshiftSettings.shiftMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = AfreqshiftSettings(
            enabled: true,
            shift: AfreqshiftSettings.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AfwtdnSettings (afwtdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afwtdn: AfwtdnSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afwtdn: AfwtdnSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_afwtdn:lavfi-afwtdn');
      });

      test(
        'param `adaptive` lands in wire when set to a non-default value',
        () {
          final s = const AfwtdnSettings(enabled: true, adaptive: true);
          expect(s.toFilterString(), contains('adaptive='));
        },
      );

      test('param `levels` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, levels: 12);
        expect(s.toFilterString(), contains('levels='));
        expect(s.toFilterString(), contains('levels=12'));
      });

      test('param `percent` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, percent: 100.0);
        expect(s.toFilterString(), contains('percent='));
        expect(s.toFilterString(), contains('percent=100.000'));
      });

      test('param `profile` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, profile: true);
        expect(s.toFilterString(), contains('profile='));
      });

      test('param `samples` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, samples: 65536);
        expect(s.toFilterString(), contains('samples='));
        expect(s.toFilterString(), contains('samples=65536'));
      });

      test('param `sigma` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, sigma: 1.0);
        expect(s.toFilterString(), contains('sigma='));
        expect(s.toFilterString(), contains('sigma=1.000'));
      });

      test(
        'param `softness` lands in wire when set to a non-default value',
        () {
          final s = const AfwtdnSettings(enabled: true, softness: 10.0);
          expect(s.toFilterString(), contains('softness='));
          expect(s.toFilterString(), contains('softness=10.000'));
        },
      );

      test('param `wavet` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, wavet: AfwtdnWavet.sym2);
        expect(s.toFilterString(), contains('wavet='));
        expect(s.toFilterString(), contains('wavet=sym2'));
      });

      test(
        'param `levels` const `levelsMin` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            levels: AfwtdnSettings.levelsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `levels` const `levelsMax` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            levels: AfwtdnSettings.levelsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `levels` const `levelsDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            levels: AfwtdnSettings.levelsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentMin` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            percent: AfwtdnSettings.percentMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentMax` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            percent: AfwtdnSettings.percentMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `percent` const `percentDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            percent: AfwtdnSettings.percentDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMin` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            samples: AfwtdnSettings.samplesMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesMax` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            samples: AfwtdnSettings.samplesMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `samples` const `samplesDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            samples: AfwtdnSettings.samplesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sigma` const `sigmaMin` is accepted by toFilterString', () {
        final s = AfwtdnSettings(enabled: true, sigma: AfwtdnSettings.sigmaMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sigma` const `sigmaMax` is accepted by toFilterString', () {
        final s = AfwtdnSettings(enabled: true, sigma: AfwtdnSettings.sigmaMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sigma` const `sigmaDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            sigma: AfwtdnSettings.sigmaDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessMin` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            softness: AfwtdnSettings.softnessMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessMax` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            softness: AfwtdnSettings.softnessMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `softness` const `softnessDefault` is accepted by toFilterString',
        () {
          final s = AfwtdnSettings(
            enabled: true,
            softness: AfwtdnSettings.softnessDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AgateSettings (agate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(agate: AgateSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(agate: AgateSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_agate:lavfi-agate');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, attack: 9000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=9000.000'));
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const AgateSettings(
            enabled: true,
            detection: AgateDetection.peak,
          );
          expect(s.toFilterString(), contains('detection='));
          expect(s.toFilterString(), contains('detection=peak'));
        },
      );

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AgateSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_sc` lands in wire when set to a non-default value',
        () {
          final s = const AgateSettings(enabled: true, level_sc: 64.0);
          expect(s.toFilterString(), contains('level_sc='));
          expect(s.toFilterString(), contains('level_sc=64.000'));
        },
      );

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, link: AgateLink.maximum);
        expect(s.toFilterString(), contains('link='));
        expect(s.toFilterString(), contains('link=maximum'));
      });

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, makeup: 64.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, mode: AgateMode.upward);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=upward'));
      });

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, range: 1.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=1.000'));
      });

      test('param `ratio` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, ratio: 9000.0);
        expect(s.toFilterString(), contains('ratio='));
        expect(s.toFilterString(), contains('ratio=9000.000'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, release: 9000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=9000.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AgateSettings(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            attack: AgateSettings.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            attack: AgateSettings.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            attack: AgateSettings.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `knee` const `kneeMin` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, knee: AgateSettings.kneeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `knee` const `kneeMax` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, knee: AgateSettings.kneeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `knee` const `kneeDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            knee: AgateSettings.kneeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_in: AgateSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_in: AgateSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_in: AgateSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_sc: AgateSettings.level_scMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_sc: AgateSettings.level_scMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_sc` const `level_scDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            level_sc: AgateSettings.level_scDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            makeup: AgateSettings.makeupMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            makeup: AgateSettings.makeupMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `makeup` const `makeupDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            makeup: AgateSettings.makeupDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, range: AgateSettings.rangeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, range: AgateSettings.rangeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            range: AgateSettings.rangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ratio` const `ratioMin` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, ratio: AgateSettings.ratioMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ratio` const `ratioMax` is accepted by toFilterString', () {
        final s = AgateSettings(enabled: true, ratio: AgateSettings.ratioMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ratio` const `ratioDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            ratio: AgateSettings.ratioDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            release: AgateSettings.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            release: AgateSettings.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            release: AgateSettings.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            threshold: AgateSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            threshold: AgateSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AgateSettings(
            enabled: true,
            threshold: AgateSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AiirSettings (aiir)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aiir: AiirSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aiir: AiirSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aiir:lavfi-aiir');
      });

      test('param `channel` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, channel: 1024);
        expect(s.toFilterString(), contains('channel='));
        expect(s.toFilterString(), contains('channel=1024'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, dry: 0.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=0.000'));
      });

      test('param `e` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, e: AiirPrecision.flt);
        expect(s.toFilterString(), contains('e='));
        expect(s.toFilterString(), contains('e=flt'));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, f: AiirFormat.ll);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=ll'));
      });

      test('param `format` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, format: AiirFormat.ll);
        expect(s.toFilterString(), contains('format='));
        expect(s.toFilterString(), contains('format=ll'));
      });

      test('param `gains` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, gains: 'wire_test_alt');
        expect(s.toFilterString(), contains('gains='));
      });

      test('param `k` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, k: 'wire_test_alt');
        expect(s.toFilterString(), contains('k='));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, n: false);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const AiirSettings(enabled: true, normalize: false);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, p: 'wire_test_alt');
        expect(s.toFilterString(), contains('p='));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, poles: 'wire_test_alt');
        expect(s.toFilterString(), contains('poles='));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AiirSettings(
            enabled: true,
            precision: AiirPrecision.flt,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=flt'));
        },
      );

      test('param `process` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, process: AiirProcess.d);
        expect(s.toFilterString(), contains('process='));
        expect(s.toFilterString(), contains('process=d'));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, r: AiirProcess.d);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=d'));
      });

      test('param `rate` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, rate: 'wire_test_alt');
        expect(s.toFilterString(), contains('rate='));
      });

      test(
        'param `response` lands in wire when set to a non-default value',
        () {
          final s = const AiirSettings(enabled: true, response: true);
          expect(s.toFilterString(), contains('response='));
        },
      );

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, size: 'wire_test_alt');
        expect(s.toFilterString(), contains('size='));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `z` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, z: 'wire_test_alt');
        expect(s.toFilterString(), contains('z='));
      });

      test('param `zeros` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, zeros: 'wire_test_alt');
        expect(s.toFilterString(), contains('zeros='));
      });

      test(
        'param `channel` const `channelMin` is accepted by toFilterString',
        () {
          final s = AiirSettings(
            enabled: true,
            channel: AiirSettings.channelMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `channel` const `channelMax` is accepted by toFilterString',
        () {
          final s = AiirSettings(
            enabled: true,
            channel: AiirSettings.channelMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `channel` const `channelDefault` is accepted by toFilterString',
        () {
          final s = AiirSettings(
            enabled: true,
            channel: AiirSettings.channelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, dry: AiirSettings.dryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, dry: AiirSettings.dryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, dry: AiirSettings.dryDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, mix: AiirSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, mix: AiirSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, mix: AiirSettings.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, wet: AiirSettings.wetMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, wet: AiirSettings.wetMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = AiirSettings(enabled: true, wet: AiirSettings.wetDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AintegralSettings (aintegral)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aintegral: AintegralSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aintegral: AintegralSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aintegral:lavfi-aintegral');
      });
    });
    group('AlimiterSettings (alimiter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(alimiter: AlimiterSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(alimiter: AlimiterSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_alimiter:lavfi-alimiter');
      });

      test('param `asc` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, asc: true);
        expect(s.toFilterString(), contains('asc='));
      });

      test(
        'param `asc_level` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterSettings(enabled: true, asc_level: 1.0);
          expect(s.toFilterString(), contains('asc_level='));
          expect(s.toFilterString(), contains('asc_level=1.000'));
        },
      );

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, attack: 80.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=80.000'));
      });

      test('param `latency` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, latency: true);
        expect(s.toFilterString(), contains('latency='));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, level: false);
        expect(s.toFilterString(), contains('level='));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const AlimiterSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `limit` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, limit: 0.0625);
        expect(s.toFilterString(), contains('limit='));
        expect(s.toFilterString(), contains('limit=0.063'));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, release: 8000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=8000.000'));
      });

      test(
        'param `asc_level` const `asc_levelMin` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            asc_level: AlimiterSettings.asc_levelMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `asc_level` const `asc_levelMax` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            asc_level: AlimiterSettings.asc_levelMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `asc_level` const `asc_levelDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            asc_level: AlimiterSettings.asc_levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMin` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            attack: AlimiterSettings.attackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackMax` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            attack: AlimiterSettings.attackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `attack` const `attackDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            attack: AlimiterSettings.attackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_in: AlimiterSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_in: AlimiterSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_in: AlimiterSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_out: AlimiterSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_out: AlimiterSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            level_out: AlimiterSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `limit` const `limitMin` is accepted by toFilterString', () {
        final s = AlimiterSettings(
          enabled: true,
          limit: AlimiterSettings.limitMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `limit` const `limitMax` is accepted by toFilterString', () {
        final s = AlimiterSettings(
          enabled: true,
          limit: AlimiterSettings.limitMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `limit` const `limitDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            limit: AlimiterSettings.limitDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMin` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            release: AlimiterSettings.releaseMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseMax` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            release: AlimiterSettings.releaseMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `release` const `releaseDefault` is accepted by toFilterString',
        () {
          final s = AlimiterSettings(
            enabled: true,
            release: AlimiterSettings.releaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AllpassSettings (allpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(allpass: AllpassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(allpass: AllpassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_allpass:lavfi-allpass');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(
          enabled: true,
          a: AllpassTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, o: 1);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=1'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, order: 1);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(
            enabled: true,
            precision: AllpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, r: AllpassPrecision.s16);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, t: AllpassWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(
            enabled: true,
            transform: AllpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const AllpassSettings(
            enabled: true,
            width_type: AllpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, f: AllpassSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, f: AllpassSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, f: AllpassSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = AllpassSettings(
            enabled: true,
            frequency: AllpassSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = AllpassSettings(
            enabled: true,
            frequency: AllpassSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = AllpassSettings(
            enabled: true,
            frequency: AllpassSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, m: AllpassSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, m: AllpassSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, m: AllpassSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, mix: AllpassSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, mix: AllpassSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = AllpassSettings(
          enabled: true,
          mix: AllpassSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMin` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, o: AllpassSettings.oMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMax` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, o: AllpassSettings.oMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oDefault` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, o: AllpassSettings.oDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AllpassSettings(
          enabled: true,
          order: AllpassSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AllpassSettings(
          enabled: true,
          order: AllpassSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AllpassSettings(
            enabled: true,
            order: AllpassSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, w: AllpassSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, w: AllpassSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = AllpassSettings(enabled: true, w: AllpassSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = AllpassSettings(
          enabled: true,
          width: AllpassSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = AllpassSettings(
          enabled: true,
          width: AllpassSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = AllpassSettings(
            enabled: true,
            width: AllpassSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AnequalizerSettings (anequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          anequalizer: AnequalizerSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          anequalizer: AnequalizerSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_anequalizer:lavfi-anequalizer');
      });

      test('param `colors` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(
          enabled: true,
          colors: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('colors='));
      });

      test('param `curves` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(enabled: true, curves: true);
        expect(s.toFilterString(), contains('curves='));
      });

      test('param `fscale` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(
          enabled: true,
          fscale: AnequalizerFscale.lin,
        );
        expect(s.toFilterString(), contains('fscale='));
        expect(s.toFilterString(), contains('fscale=lin'));
      });

      test('param `mgain` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(enabled: true, mgain: 900.0);
        expect(s.toFilterString(), contains('mgain='));
        expect(s.toFilterString(), contains('mgain=900.000'));
      });

      test('param `params` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(
          enabled: true,
          params: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('params='));
      });

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(
          enabled: true,
          size: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('size='));
      });

      test('param `mgain` const `mgainMin` is accepted by toFilterString', () {
        final s = AnequalizerSettings(
          enabled: true,
          mgain: AnequalizerSettings.mgainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mgain` const `mgainMax` is accepted by toFilterString', () {
        final s = AnequalizerSettings(
          enabled: true,
          mgain: AnequalizerSettings.mgainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mgain` const `mgainDefault` is accepted by toFilterString',
        () {
          final s = AnequalizerSettings(
            enabled: true,
            mgain: AnequalizerSettings.mgainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AnlmdnSettings (anlmdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(anlmdn: AnlmdnSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(anlmdn: AnlmdnSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_anlmdn:lavfi-anlmdn');
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, m: 1000.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=1000.000'));
      });

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, o: AnlmdnMode.i);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=i'));
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, output: AnlmdnMode.i);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=i'));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
          enabled: true,
          p: const Duration(microseconds: 1002000),
        );
        expect(s.toFilterString(), contains('p='));
      });

      test('param `patch` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
          enabled: true,
          patch: const Duration(microseconds: 1002000),
        );
        expect(s.toFilterString(), contains('patch='));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
          enabled: true,
          r: const Duration(microseconds: 1006000),
        );
        expect(s.toFilterString(), contains('r='));
      });

      test(
        'param `research` lands in wire when set to a non-default value',
        () {
          final s = const AnlmdnSettings(
            enabled: true,
            research: const Duration(microseconds: 1006000),
          );
          expect(s.toFilterString(), contains('research='));
        },
      );

      test('param `s` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, s: 10000.0);
        expect(s.toFilterString(), contains('s='));
        expect(s.toFilterString(), contains('s=10000.000'));
      });

      test('param `smooth` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, smooth: 1000.0);
        expect(s.toFilterString(), contains('smooth='));
        expect(s.toFilterString(), contains('smooth=1000.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const AnlmdnSettings(enabled: true, strength: 10000.0);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=10000.000'));
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, m: AnlmdnSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, m: AnlmdnSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, m: AnlmdnSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sMin` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, s: AnlmdnSettings.sMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sMax` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, s: AnlmdnSettings.sMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sDefault` is accepted by toFilterString', () {
        final s = AnlmdnSettings(enabled: true, s: AnlmdnSettings.sDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `smooth` const `smoothMin` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            smooth: AnlmdnSettings.smoothMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothMax` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            smooth: AnlmdnSettings.smoothMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothDefault` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            smooth: AnlmdnSettings.smoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            strength: AnlmdnSettings.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            strength: AnlmdnSettings.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = AnlmdnSettings(
            enabled: true,
            strength: AnlmdnSettings.strengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApadSettings (apad)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apad: ApadSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apad: ApadSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_apad:lavfi-apad');
      });

      test(
        'param `packet_size` lands in wire when set to a non-default value',
        () {
          final s = const ApadSettings(enabled: true, packet_size: 2147483647);
          expect(s.toFilterString(), contains('packet_size='));
          expect(s.toFilterString(), contains('packet_size=2147483647'));
        },
      );

      test('param `pad_dur` lands in wire when set to a non-default value', () {
        final s = const ApadSettings(
          enabled: true,
          pad_dur: const Duration(microseconds: 999999),
        );
        expect(s.toFilterString(), contains('pad_dur='));
      });

      test('param `pad_len` lands in wire when set to a non-default value', () {
        final s = const ApadSettings(
          enabled: true,
          pad_len: 9223372036854775807,
        );
        expect(s.toFilterString(), contains('pad_len='));
        expect(s.toFilterString(), contains('pad_len=9223372036854775807'));
      });

      test(
        'param `whole_dur` lands in wire when set to a non-default value',
        () {
          final s = const ApadSettings(
            enabled: true,
            whole_dur: const Duration(microseconds: 999999),
          );
          expect(s.toFilterString(), contains('whole_dur='));
        },
      );

      test(
        'param `whole_len` lands in wire when set to a non-default value',
        () {
          final s = const ApadSettings(
            enabled: true,
            whole_len: 9223372036854775807,
          );
          expect(s.toFilterString(), contains('whole_len='));
          expect(s.toFilterString(), contains('whole_len=9223372036854775807'));
        },
      );

      test(
        'param `packet_size` const `packet_sizeMin` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            packet_size: ApadSettings.packet_sizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `packet_size` const `packet_sizeMax` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            packet_size: ApadSettings.packet_sizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `packet_size` const `packet_sizeDefault` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            packet_size: ApadSettings.packet_sizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `pad_lenMin` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            pad_len: ApadSettings.pad_lenMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `pad_lenMax` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            pad_len: ApadSettings.pad_lenMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `pad_len` const `pad_lenDefault` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            pad_len: ApadSettings.pad_lenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `whole_lenMin` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            whole_len: ApadSettings.whole_lenMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `whole_lenMax` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            whole_len: ApadSettings.whole_lenMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `whole_len` const `whole_lenDefault` is accepted by toFilterString',
        () {
          final s = ApadSettings(
            enabled: true,
            whole_len: ApadSettings.whole_lenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AphaserSettings (aphaser)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aphaser: AphaserSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aphaser: AphaserSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aphaser:lavfi-aphaser');
      });

      test('param `decay` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, decay: 0.99);
        expect(s.toFilterString(), contains('decay='));
        expect(s.toFilterString(), contains('decay=0.990'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, delay: 5.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=5.000'));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, in_gain: 1.0);
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test(
        'param `out_gain` lands in wire when set to a non-default value',
        () {
          final s = const AphaserSettings(
            enabled: true,
            out_gain: 1000000000.0,
          );
          expect(s.toFilterString(), contains('out_gain='));
          expect(s.toFilterString(), contains('out_gain=1000000000.000'));
        },
      );

      test('param `speed` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, speed: 2.0);
        expect(s.toFilterString(), contains('speed='));
        expect(s.toFilterString(), contains('speed=2.000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, type: AphaserType.t);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=t'));
      });

      test('param `decay` const `decayMin` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          decay: AphaserSettings.decayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `decay` const `decayMax` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          decay: AphaserSettings.decayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `decay` const `decayDefault` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            decay: AphaserSettings.decayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          delay: AphaserSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          delay: AphaserSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            delay: AphaserSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainMin` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            in_gain: AphaserSettings.in_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainMax` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            in_gain: AphaserSettings.in_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainDefault` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            in_gain: AphaserSettings.in_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMin` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            out_gain: AphaserSettings.out_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMax` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            out_gain: AphaserSettings.out_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainDefault` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            out_gain: AphaserSettings.out_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `speed` const `speedMin` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          speed: AphaserSettings.speedMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `speed` const `speedMax` is accepted by toFilterString', () {
        final s = AphaserSettings(
          enabled: true,
          speed: AphaserSettings.speedMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `speed` const `speedDefault` is accepted by toFilterString',
        () {
          final s = AphaserSettings(
            enabled: true,
            speed: AphaserSettings.speedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AphaseshiftSettings (aphaseshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          aphaseshift: AphaseshiftSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          aphaseshift: AphaseshiftSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_aphaseshift:lavfi-aphaseshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, order: 16);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=16'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          level: AphaseshiftSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          level: AphaseshiftSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftSettings(
            enabled: true,
            level: AphaseshiftSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          order: AphaseshiftSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          order: AphaseshiftSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftSettings(
            enabled: true,
            order: AphaseshiftSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          shift: AphaseshiftSettings.shiftMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = AphaseshiftSettings(
          enabled: true,
          shift: AphaseshiftSettings.shiftMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = AphaseshiftSettings(
            enabled: true,
            shift: AphaseshiftSettings.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApsyclipSettings (apsyclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apsyclip: ApsyclipSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apsyclip: ApsyclipSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_apsyclip:lavfi-apsyclip');
      });

      test(
        'param `adaptive` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipSettings(enabled: true, adaptive: 1.0);
          expect(s.toFilterString(), contains('adaptive='));
          expect(s.toFilterString(), contains('adaptive=1.000'));
        },
      );

      test('param `clip` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, clip: 0.015625);
        expect(s.toFilterString(), contains('clip='));
        expect(s.toFilterString(), contains('clip=0.016'));
      });

      test('param `diff` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, diff: true);
        expect(s.toFilterString(), contains('diff='));
      });

      test(
        'param `iterations` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipSettings(enabled: true, iterations: 20);
          expect(s.toFilterString(), contains('iterations='));
          expect(s.toFilterString(), contains('iterations=20'));
        },
      );

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, level: true);
        expect(s.toFilterString(), contains('level='));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const ApsyclipSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test(
        'param `adaptive` const `adaptiveMin` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            adaptive: ApsyclipSettings.adaptiveMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptive` const `adaptiveMax` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            adaptive: ApsyclipSettings.adaptiveMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `adaptive` const `adaptiveDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            adaptive: ApsyclipSettings.adaptiveDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `clip` const `clipMin` is accepted by toFilterString', () {
        final s = ApsyclipSettings(
          enabled: true,
          clip: ApsyclipSettings.clipMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `clip` const `clipMax` is accepted by toFilterString', () {
        final s = ApsyclipSettings(
          enabled: true,
          clip: ApsyclipSettings.clipMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `clip` const `clipDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            clip: ApsyclipSettings.clipDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsMin` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            iterations: ApsyclipSettings.iterationsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsMax` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            iterations: ApsyclipSettings.iterationsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `iterations` const `iterationsDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            iterations: ApsyclipSettings.iterationsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_in: ApsyclipSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_in: ApsyclipSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_in: ApsyclipSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_out: ApsyclipSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_out: ApsyclipSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = ApsyclipSettings(
            enabled: true,
            level_out: ApsyclipSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ApulsatorSettings (apulsator)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apulsator: ApulsatorSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apulsator: ApulsatorSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_apulsator:lavfi-apulsator');
      });

      test('param `amount` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, amount: 0.0);
        expect(s.toFilterString(), contains('amount='));
        expect(s.toFilterString(), contains('amount=0.000'));
      });

      test('param `bpm` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, bpm: 300.0);
        expect(s.toFilterString(), contains('bpm='));
        expect(s.toFilterString(), contains('bpm=300.000'));
      });

      test('param `hz` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, hz: 100.0);
        expect(s.toFilterString(), contains('hz='));
        expect(s.toFilterString(), contains('hz=100.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(
          enabled: true,
          mode: ApulsatorMode.triangle,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=triangle'));
      });

      test('param `ms` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, ms: 2000);
        expect(s.toFilterString(), contains('ms='));
        expect(s.toFilterString(), contains('ms=2000'));
      });

      test(
        'param `offset_l` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorSettings(enabled: true, offset_l: 1.0);
          expect(s.toFilterString(), contains('offset_l='));
          expect(s.toFilterString(), contains('offset_l=1.000'));
        },
      );

      test(
        'param `offset_r` lands in wire when set to a non-default value',
        () {
          final s = const ApulsatorSettings(enabled: true, offset_r: 1.0);
          expect(s.toFilterString(), contains('offset_r='));
          expect(s.toFilterString(), contains('offset_r=1.000'));
        },
      );

      test('param `timing` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(
          enabled: true,
          timing: ApulsatorTiming.ms,
        );
        expect(s.toFilterString(), contains('timing='));
        expect(s.toFilterString(), contains('timing=ms'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, width: 2.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=2.000'));
      });

      test(
        'param `amount` const `amountMin` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            amount: ApulsatorSettings.amountMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountMax` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            amount: ApulsatorSettings.amountMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `amount` const `amountDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            amount: ApulsatorSettings.amountDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bpm` const `bpmMin` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          bpm: ApulsatorSettings.bpmMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bpm` const `bpmMax` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          bpm: ApulsatorSettings.bpmMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bpm` const `bpmDefault` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          bpm: ApulsatorSettings.bpmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzMin` is accepted by toFilterString', () {
        final s = ApulsatorSettings(enabled: true, hz: ApulsatorSettings.hzMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzMax` is accepted by toFilterString', () {
        final s = ApulsatorSettings(enabled: true, hz: ApulsatorSettings.hzMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `hz` const `hzDefault` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          hz: ApulsatorSettings.hzDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_in: ApulsatorSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_in: ApulsatorSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_in: ApulsatorSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_out: ApulsatorSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_out: ApulsatorSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            level_out: ApulsatorSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ms` const `msMin` is accepted by toFilterString', () {
        final s = ApulsatorSettings(enabled: true, ms: ApulsatorSettings.msMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ms` const `msMax` is accepted by toFilterString', () {
        final s = ApulsatorSettings(enabled: true, ms: ApulsatorSettings.msMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ms` const `msDefault` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          ms: ApulsatorSettings.msDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `offset_l` const `offset_lMin` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_l: ApulsatorSettings.offset_lMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_l` const `offset_lMax` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_l: ApulsatorSettings.offset_lMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_l` const `offset_lDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_l: ApulsatorSettings.offset_lDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offset_rMin` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_r: ApulsatorSettings.offset_rMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offset_rMax` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_r: ApulsatorSettings.offset_rMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset_r` const `offset_rDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            offset_r: ApulsatorSettings.offset_rDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          width: ApulsatorSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = ApulsatorSettings(
          enabled: true,
          width: ApulsatorSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = ApulsatorSettings(
            enabled: true,
            width: ApulsatorSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AresampleSettings (aresample)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aresample: AresampleSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aresample: AresampleSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_aresample:lavfi-aresample');
      });

      test(
        'param `sample_rate` lands in wire when set to a non-default value',
        () {
          final s = const AresampleSettings(
            enabled: true,
            sample_rate: 2147483647,
          );
          expect(s.toFilterString(), contains('sample_rate='));
          expect(s.toFilterString(), contains('sample_rate=2147483647'));
        },
      );

      test(
        'param `sample_rate` const `sample_rateMin` is accepted by toFilterString',
        () {
          final s = AresampleSettings(
            enabled: true,
            sample_rate: AresampleSettings.sample_rateMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sample_rate` const `sample_rateMax` is accepted by toFilterString',
        () {
          final s = AresampleSettings(
            enabled: true,
            sample_rate: AresampleSettings.sample_rateMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sample_rate` const `sample_rateDefault` is accepted by toFilterString',
        () {
          final s = AresampleSettings(
            enabled: true,
            sample_rate: AresampleSettings.sample_rateDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ArnndnSettings (arnndn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          arnndn: ArnndnSettings(enabled: false, model: ''),
        );
        expect(fx.toAfChain(), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = AudioEffects(
            arnndn: ArnndnSettings(enabled: true, model: ''),
          );
          expect(fx.toAfChain(), startsWith('@aek_arnndn:lavfi-arnndn'));
          expect(fx.toAfChain(), contains('model='));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(
          enabled: true,
          m: 'wire_test_alt',
          model: '',
        );
        expect(s.toFilterString(), contains('m='));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(enabled: true, mix: -1.0, model: '');
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=-1.000'));
      });

      test('param `model` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(enabled: true, model: 'wire_test_alt');
        expect(s.toFilterString(), contains('model='));
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = ArnndnSettings(
          enabled: true,
          mix: ArnndnSettings.mixMin,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = ArnndnSettings(
          enabled: true,
          mix: ArnndnSettings.mixMax,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = ArnndnSettings(
          enabled: true,
          mix: ArnndnSettings.mixDefault,
          model: '',
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AsetrateSettings (asetrate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asetrate: AsetrateSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asetrate: AsetrateSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asetrate:lavfi-asetrate');
      });
    });
    group('AsoftclipSettings (asoftclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asoftclip: AsoftclipSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asoftclip: AsoftclipSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asoftclip:lavfi-asoftclip');
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AsoftclipSettings(enabled: true, output: 16.0);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=16.000'));
      });

      test(
        'param `oversample` lands in wire when set to a non-default value',
        () {
          final s = const AsoftclipSettings(enabled: true, oversample: 64);
          expect(s.toFilterString(), contains('oversample='));
          expect(s.toFilterString(), contains('oversample=64'));
        },
      );

      test('param `param` lands in wire when set to a non-default value', () {
        final s = const AsoftclipSettings(enabled: true, param: 3.0);
        expect(s.toFilterString(), contains('param='));
        expect(s.toFilterString(), contains('param=3.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const AsoftclipSettings(enabled: true, threshold: 1e-06);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1e-6'));
        },
      );

      test('param `type` lands in wire when set to a non-default value', () {
        final s = const AsoftclipSettings(
          enabled: true,
          type: AsoftclipTypes.tanh,
        );
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=tanh'));
      });

      test(
        'param `output` const `outputMin` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            output: AsoftclipSettings.outputMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `output` const `outputMax` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            output: AsoftclipSettings.outputMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `output` const `outputDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            output: AsoftclipSettings.outputDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleMin` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            oversample: AsoftclipSettings.oversampleMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleMax` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            oversample: AsoftclipSettings.oversampleMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `oversample` const `oversampleDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            oversample: AsoftclipSettings.oversampleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `param` const `paramMin` is accepted by toFilterString', () {
        final s = AsoftclipSettings(
          enabled: true,
          param: AsoftclipSettings.paramMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `param` const `paramMax` is accepted by toFilterString', () {
        final s = AsoftclipSettings(
          enabled: true,
          param: AsoftclipSettings.paramMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `param` const `paramDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            param: AsoftclipSettings.paramDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            threshold: AsoftclipSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            threshold: AsoftclipSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = AsoftclipSettings(
            enabled: true,
            threshold: AsoftclipSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsubboostSettings (asubboost)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asubboost: AsubboostSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asubboost: AsubboostSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asubboost:lavfi-asubboost');
      });

      test('param `boost` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, boost: 12.0);
        expect(s.toFilterString(), contains('boost='));
        expect(s.toFilterString(), contains('boost=12.000'));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const AsubboostSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, cutoff: 900.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=900.000'));
      });

      test('param `decay` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, decay: 1.0);
        expect(s.toFilterString(), contains('decay='));
        expect(s.toFilterString(), contains('decay=1.000'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, delay: 100.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=100.000'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, dry: 0.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=0.000'));
      });

      test(
        'param `feedback` lands in wire when set to a non-default value',
        () {
          final s = const AsubboostSettings(enabled: true, feedback: 1.0);
          expect(s.toFilterString(), contains('feedback='));
          expect(s.toFilterString(), contains('feedback=1.000'));
        },
      );

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `boost` const `boostMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          boost: AsubboostSettings.boostMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `boost` const `boostMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          boost: AsubboostSettings.boostMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `boost` const `boostDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            boost: AsubboostSettings.boostDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            cutoff: AsubboostSettings.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            cutoff: AsubboostSettings.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            cutoff: AsubboostSettings.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `decay` const `decayMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          decay: AsubboostSettings.decayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `decay` const `decayMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          decay: AsubboostSettings.decayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `decay` const `decayDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            decay: AsubboostSettings.decayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          delay: AsubboostSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          delay: AsubboostSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            delay: AsubboostSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          dry: AsubboostSettings.dryMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          dry: AsubboostSettings.dryMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          dry: AsubboostSettings.dryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `feedback` const `feedbackMin` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            feedback: AsubboostSettings.feedbackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMax` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            feedback: AsubboostSettings.feedbackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            feedback: AsubboostSettings.feedbackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          slope: AsubboostSettings.slopeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          slope: AsubboostSettings.slopeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = AsubboostSettings(
            enabled: true,
            slope: AsubboostSettings.slopeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          wet: AsubboostSettings.wetMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          wet: AsubboostSettings.wetMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = AsubboostSettings(
          enabled: true,
          wet: AsubboostSettings.wetDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('AsubcutSettings (asubcut)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asubcut: AsubcutSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asubcut: AsubcutSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asubcut:lavfi-asubcut');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsubcutSettings(enabled: true, cutoff: 200.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=200.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsubcutSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsubcutSettings(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsubcutSettings(
            enabled: true,
            cutoff: AsubcutSettings.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsubcutSettings(
            enabled: true,
            cutoff: AsubcutSettings.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsubcutSettings(
            enabled: true,
            cutoff: AsubcutSettings.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsubcutSettings(
          enabled: true,
          level: AsubcutSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsubcutSettings(
          enabled: true,
          level: AsubcutSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsubcutSettings(
            enabled: true,
            level: AsubcutSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsubcutSettings(
          enabled: true,
          order: AsubcutSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsubcutSettings(
          enabled: true,
          order: AsubcutSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsubcutSettings(
            enabled: true,
            order: AsubcutSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsupercutSettings (asupercut)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asupercut: AsupercutSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asupercut: AsupercutSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asupercut:lavfi-asupercut');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const AsupercutSettings(enabled: true, cutoff: 192000.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=192000.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsupercutSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsupercutSettings(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = AsupercutSettings(
            enabled: true,
            cutoff: AsupercutSettings.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = AsupercutSettings(
            enabled: true,
            cutoff: AsupercutSettings.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = AsupercutSettings(
            enabled: true,
            cutoff: AsupercutSettings.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsupercutSettings(
          enabled: true,
          level: AsupercutSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsupercutSettings(
          enabled: true,
          level: AsupercutSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsupercutSettings(
            enabled: true,
            level: AsupercutSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsupercutSettings(
          enabled: true,
          order: AsupercutSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsupercutSettings(
          enabled: true,
          order: AsupercutSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsupercutSettings(
            enabled: true,
            order: AsupercutSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsuperpassSettings (asuperpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asuperpass: AsuperpassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asuperpass: AsuperpassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asuperpass:lavfi-asuperpass');
      });

      test('param `centerf` lands in wire when set to a non-default value', () {
        final s = const AsuperpassSettings(enabled: true, centerf: 999999.0);
        expect(s.toFilterString(), contains('centerf='));
        expect(s.toFilterString(), contains('centerf=999999.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsuperpassSettings(enabled: true, level: 2.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=2.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsuperpassSettings(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test('param `qfactor` lands in wire when set to a non-default value', () {
        final s = const AsuperpassSettings(enabled: true, qfactor: 100.0);
        expect(s.toFilterString(), contains('qfactor='));
        expect(s.toFilterString(), contains('qfactor=100.000'));
      });

      test(
        'param `centerf` const `centerfMin` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            centerf: AsuperpassSettings.centerfMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfMax` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            centerf: AsuperpassSettings.centerfMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            centerf: AsuperpassSettings.centerfDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsuperpassSettings(
          enabled: true,
          level: AsuperpassSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsuperpassSettings(
          enabled: true,
          level: AsuperpassSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            level: AsuperpassSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsuperpassSettings(
          enabled: true,
          order: AsuperpassSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsuperpassSettings(
          enabled: true,
          order: AsuperpassSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            order: AsuperpassSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMin` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            qfactor: AsuperpassSettings.qfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMax` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            qfactor: AsuperpassSettings.qfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorDefault` is accepted by toFilterString',
        () {
          final s = AsuperpassSettings(
            enabled: true,
            qfactor: AsuperpassSettings.qfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AsuperstopSettings (asuperstop)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asuperstop: AsuperstopSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asuperstop: AsuperstopSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_asuperstop:lavfi-asuperstop');
      });

      test('param `centerf` lands in wire when set to a non-default value', () {
        final s = const AsuperstopSettings(enabled: true, centerf: 999999.0);
        expect(s.toFilterString(), contains('centerf='));
        expect(s.toFilterString(), contains('centerf=999999.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AsuperstopSettings(enabled: true, level: 2.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=2.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AsuperstopSettings(enabled: true, order: 20);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=20'));
      });

      test('param `qfactor` lands in wire when set to a non-default value', () {
        final s = const AsuperstopSettings(enabled: true, qfactor: 100.0);
        expect(s.toFilterString(), contains('qfactor='));
        expect(s.toFilterString(), contains('qfactor=100.000'));
      });

      test(
        'param `centerf` const `centerfMin` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            centerf: AsuperstopSettings.centerfMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfMax` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            centerf: AsuperstopSettings.centerfMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `centerf` const `centerfDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            centerf: AsuperstopSettings.centerfDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AsuperstopSettings(
          enabled: true,
          level: AsuperstopSettings.levelMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AsuperstopSettings(
          enabled: true,
          level: AsuperstopSettings.levelMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            level: AsuperstopSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AsuperstopSettings(
          enabled: true,
          order: AsuperstopSettings.orderMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AsuperstopSettings(
          enabled: true,
          order: AsuperstopSettings.orderMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            order: AsuperstopSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMin` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            qfactor: AsuperstopSettings.qfactorMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorMax` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            qfactor: AsuperstopSettings.qfactorMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `qfactor` const `qfactorDefault` is accepted by toFilterString',
        () {
          final s = AsuperstopSettings(
            enabled: true,
            qfactor: AsuperstopSettings.qfactorDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AtempoSettings (atempo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(atempo: AtempoSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(atempo: AtempoSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_atempo:lavfi-atempo');
      });

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const AtempoSettings(enabled: true, tempo: 100.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=100.000'));
      });

      test('param `tempo` const `tempoMin` is accepted by toFilterString', () {
        final s = AtempoSettings(enabled: true, tempo: AtempoSettings.tempoMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tempo` const `tempoMax` is accepted by toFilterString', () {
        final s = AtempoSettings(enabled: true, tempo: AtempoSettings.tempoMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `tempo` const `tempoDefault` is accepted by toFilterString',
        () {
          final s = AtempoSettings(
            enabled: true,
            tempo: AtempoSettings.tempoDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('AtiltSettings (atilt)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(atilt: AtiltSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(atilt: AtiltSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_atilt:lavfi-atilt');
      });

      test('param `freq` lands in wire when set to a non-default value', () {
        final s = const AtiltSettings(enabled: true, freq: 192000.0);
        expect(s.toFilterString(), contains('freq='));
        expect(s.toFilterString(), contains('freq=192000.000'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AtiltSettings(enabled: true, level: 4.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=4.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AtiltSettings(enabled: true, order: 30);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=30'));
      });

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const AtiltSettings(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const AtiltSettings(enabled: true, width: 10000.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=10000.000'));
      });

      test('param `freq` const `freqMin` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, freq: AtiltSettings.freqMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `freq` const `freqMax` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, freq: AtiltSettings.freqMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `freq` const `freqDefault` is accepted by toFilterString',
        () {
          final s = AtiltSettings(
            enabled: true,
            freq: AtiltSettings.freqDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `level` const `levelMin` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, level: AtiltSettings.levelMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `level` const `levelMax` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, level: AtiltSettings.levelMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level` const `levelDefault` is accepted by toFilterString',
        () {
          final s = AtiltSettings(
            enabled: true,
            level: AtiltSettings.levelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `order` const `orderMin` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, order: AtiltSettings.orderMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `order` const `orderMax` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, order: AtiltSettings.orderMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `order` const `orderDefault` is accepted by toFilterString',
        () {
          final s = AtiltSettings(
            enabled: true,
            order: AtiltSettings.orderDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, slope: AtiltSettings.slopeMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, slope: AtiltSettings.slopeMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = AtiltSettings(
            enabled: true,
            slope: AtiltSettings.slopeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, width: AtiltSettings.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = AtiltSettings(enabled: true, width: AtiltSettings.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = AtiltSettings(
            enabled: true,
            width: AtiltSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BandpassSettings (bandpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bandpass: BandpassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bandpass: BandpassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_bandpass:lavfi-bandpass');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(
          enabled: true,
          a: BandpassTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `csg` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, csg: true);
        expect(s.toFilterString(), contains('csg='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(
            enabled: true,
            precision: BandpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(
          enabled: true,
          r: BandpassPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, t: BandpassWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(
            enabled: true,
            transform: BandpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BandpassSettings(
            enabled: true,
            width_type: BandpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, b: BandpassSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, b: BandpassSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, b: BandpassSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            blocksize: BandpassSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            blocksize: BandpassSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            blocksize: BandpassSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, f: BandpassSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, f: BandpassSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, f: BandpassSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            frequency: BandpassSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            frequency: BandpassSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            frequency: BandpassSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, m: BandpassSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, m: BandpassSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, m: BandpassSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, mix: BandpassSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, mix: BandpassSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BandpassSettings(
          enabled: true,
          mix: BandpassSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, w: BandpassSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, w: BandpassSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = BandpassSettings(enabled: true, w: BandpassSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BandpassSettings(
          enabled: true,
          width: BandpassSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BandpassSettings(
          enabled: true,
          width: BandpassSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BandpassSettings(
            enabled: true,
            width: BandpassSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BandrejectSettings (bandreject)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bandreject: BandrejectSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bandreject: BandrejectSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_bandreject:lavfi-bandreject');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(
          enabled: true,
          a: BandrejectTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(
            enabled: true,
            frequency: 999999.0,
          );
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(
            enabled: true,
            precision: BandrejectPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(
          enabled: true,
          r: BandrejectPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(
          enabled: true,
          t: BandrejectWidthType.h,
        );
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(
            enabled: true,
            transform: BandrejectTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BandrejectSettings(
            enabled: true,
            width_type: BandrejectWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, b: BandrejectSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, b: BandrejectSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          b: BandrejectSettings.bDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            blocksize: BandrejectSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            blocksize: BandrejectSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            blocksize: BandrejectSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, f: BandrejectSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, f: BandrejectSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          f: BandrejectSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            frequency: BandrejectSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            frequency: BandrejectSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            frequency: BandrejectSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, m: BandrejectSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, m: BandrejectSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          m: BandrejectSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          mix: BandrejectSettings.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          mix: BandrejectSettings.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          mix: BandrejectSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, w: BandrejectSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(enabled: true, w: BandrejectSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          w: BandrejectSettings.wDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          width: BandrejectSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BandrejectSettings(
          enabled: true,
          width: BandrejectSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BandrejectSettings(
            enabled: true,
            width: BandrejectSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BassSettings (bass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bass: BassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bass: BassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_bass:lavfi-bass');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, a: BassTransformType.dii);
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(
            enabled: true,
            precision: BassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, r: BassPrecision.s16);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, t: BassWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(
            enabled: true,
            transform: BassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const BassSettings(
            enabled: true,
            width_type: BassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, b: BassSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, b: BassSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, b: BassSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            blocksize: BassSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            blocksize: BassSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            blocksize: BassSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, f: BassSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, f: BassSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, f: BassSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            frequency: BassSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            frequency: BassSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            frequency: BassSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, g: BassSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, g: BassSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, g: BassSettings.gDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, gain: BassSettings.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, gain: BassSettings.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = BassSettings(enabled: true, gain: BassSettings.gainDefault);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, m: BassSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, m: BassSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, m: BassSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, mix: BassSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, mix: BassSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, mix: BassSettings.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, p: BassSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, p: BassSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, p: BassSettings.pDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, poles: BassSettings.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, poles: BassSettings.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            poles: BassSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, w: BassSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, w: BassSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, w: BassSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, width: BassSettings.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = BassSettings(enabled: true, width: BassSettings.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = BassSettings(
            enabled: true,
            width: BassSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('BiquadSettings (biquad)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(biquad: BiquadSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(biquad: BiquadSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_biquad:lavfi-biquad');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(
          enabled: true,
          a: BiquadTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `a0` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a0: 2147483647.0);
        expect(s.toFilterString(), contains('a0='));
        expect(s.toFilterString(), contains('a0=2147483647.000'));
      });

      test('param `a1` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a1: 2147483647.0);
        expect(s.toFilterString(), contains('a1='));
        expect(s.toFilterString(), contains('a1=2147483647.000'));
      });

      test('param `a2` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a2: 2147483647.0);
        expect(s.toFilterString(), contains('a2='));
        expect(s.toFilterString(), contains('a2=2147483647.000'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test('param `b0` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b0: 2147483647.0);
        expect(s.toFilterString(), contains('b0='));
        expect(s.toFilterString(), contains('b0=2147483647.000'));
      });

      test('param `b1` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b1: 2147483647.0);
        expect(s.toFilterString(), contains('b1='));
        expect(s.toFilterString(), contains('b1=2147483647.000'));
      });

      test('param `b2` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b2: 2147483647.0);
        expect(s.toFilterString(), contains('b2='));
        expect(s.toFilterString(), contains('b2=2147483647.000'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const BiquadSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const BiquadSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const BiquadSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const BiquadSettings(
            enabled: true,
            precision: BiquadPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, r: BiquadPrecision.s16);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const BiquadSettings(
            enabled: true,
            transform: BiquadTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `a0` const `a0Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a0: BiquadSettings.a0Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a0` const `a0Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a0: BiquadSettings.a0Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a0` const `a0Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a0: BiquadSettings.a0Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a1: BiquadSettings.a1Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a1: BiquadSettings.a1Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a1` const `a1Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a1: BiquadSettings.a1Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a2: BiquadSettings.a2Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a2: BiquadSettings.a2Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `a2` const `a2Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, a2: BiquadSettings.a2Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b: BiquadSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b: BiquadSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b: BiquadSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b0: BiquadSettings.b0Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b0: BiquadSettings.b0Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b0` const `b0Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b0: BiquadSettings.b0Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b1: BiquadSettings.b1Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b1: BiquadSettings.b1Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b1` const `b1Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b1: BiquadSettings.b1Default);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Min` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b2: BiquadSettings.b2Min);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Max` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b2: BiquadSettings.b2Max);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b2` const `b2Default` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, b2: BiquadSettings.b2Default);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = BiquadSettings(
            enabled: true,
            blocksize: BiquadSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = BiquadSettings(
            enabled: true,
            blocksize: BiquadSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = BiquadSettings(
            enabled: true,
            blocksize: BiquadSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, m: BiquadSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, m: BiquadSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, m: BiquadSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, mix: BiquadSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, mix: BiquadSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = BiquadSettings(enabled: true, mix: BiquadSettings.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('ChannelmapSettings (channelmap)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          channelmap: ChannelmapSettings(enabled: false, map: '0|1'),
        );
        expect(fx.toAfChain(), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = AudioEffects(
            channelmap: ChannelmapSettings(enabled: true, map: '0|1'),
          );
          expect(
            fx.toAfChain(),
            startsWith('@aek_channelmap:lavfi-channelmap'),
          );
          expect(fx.toAfChain(), contains('map='));
        },
      );

      test(
        'param `channel_layout` lands in wire when set to a non-default value',
        () {
          final s = const ChannelmapSettings(
            enabled: true,
            channel_layout: 'wire_test_alt',
            map: '0|1',
          );
          expect(s.toFilterString(), contains('channel_layout='));
        },
      );

      test('param `map` lands in wire when set to a non-default value', () {
        final s = const ChannelmapSettings(enabled: true, map: 'wire_test_alt');
        expect(s.toFilterString(), contains('map='));
      });
    });
    group('ChorusSettings (chorus)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          chorus: ChorusSettings(
            enabled: false,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          ),
        );
        expect(fx.toAfChain(), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = AudioEffects(
            chorus: ChorusSettings(
              enabled: true,
              delays: '55|60',
              decays: '0.4|0.32',
              speeds: '0.25|0.4',
              depths: '2|1.3',
            ),
          );
          expect(fx.toAfChain(), startsWith('@aek_chorus:lavfi-chorus'));
          expect(fx.toAfChain(), contains('delays='));
          expect(fx.toAfChain(), contains('decays='));
          expect(fx.toAfChain(), contains('speeds='));
          expect(fx.toAfChain(), contains('depths='));
        },
      );

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(
          enabled: true,
          decays: 'wire_test_alt',
          delays: '55|60',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(
          enabled: true,
          delays: 'wire_test_alt',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('delays='));
      });

      test('param `depths` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(
          enabled: true,
          depths: 'wire_test_alt',
          delays: '55|60',
          decays: '0.4|0.32',
          speeds: '0.25|0.4',
        );
        expect(s.toFilterString(), contains('depths='));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(
          enabled: true,
          in_gain: 1.0,
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
          final s = const ChorusSettings(
            enabled: true,
            out_gain: 1.0,
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
        final s = const ChorusSettings(
          enabled: true,
          speeds: 'wire_test_alt',
          delays: '55|60',
          decays: '0.4|0.32',
          depths: '2|1.3',
        );
        expect(s.toFilterString(), contains('speeds='));
      });

      test(
        'param `in_gain` const `in_gainMin` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            in_gain: ChorusSettings.in_gainMin,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainMax` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            in_gain: ChorusSettings.in_gainMax,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `in_gain` const `in_gainDefault` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            in_gain: ChorusSettings.in_gainDefault,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMin` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            out_gain: ChorusSettings.out_gainMin,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainMax` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            out_gain: ChorusSettings.out_gainMax,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `out_gain` const `out_gainDefault` is accepted by toFilterString',
        () {
          final s = ChorusSettings(
            enabled: true,
            out_gain: ChorusSettings.out_gainDefault,
            delays: '55|60',
            decays: '0.4|0.32',
            speeds: '0.25|0.4',
            depths: '2|1.3',
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('CompandSettings (compand)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(compand: CompandSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(compand: CompandSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_compand:lavfi-compand');
      });

      test('param `attacks` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(
          enabled: true,
          attacks: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('attacks='));
      });

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(enabled: true, decays: 'wire_test_alt');
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(enabled: true, delay: 20.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=20.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `points` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(enabled: true, points: 'wire_test_alt');
        expect(s.toFilterString(), contains('points='));
      });

      test('param `volume` lands in wire when set to a non-default value', () {
        final s = const CompandSettings(enabled: true, volume: -900.0);
        expect(s.toFilterString(), contains('volume='));
        expect(s.toFilterString(), contains('volume=-900.000'));
      });

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = CompandSettings(
          enabled: true,
          delay: CompandSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = CompandSettings(
          enabled: true,
          delay: CompandSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = CompandSettings(
            enabled: true,
            delay: CompandSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = CompandSettings(enabled: true, gain: CompandSettings.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = CompandSettings(enabled: true, gain: CompandSettings.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = CompandSettings(
            enabled: true,
            gain: CompandSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeMin` is accepted by toFilterString',
        () {
          final s = CompandSettings(
            enabled: true,
            volume: CompandSettings.volumeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeMax` is accepted by toFilterString',
        () {
          final s = CompandSettings(
            enabled: true,
            volume: CompandSettings.volumeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `volume` const `volumeDefault` is accepted by toFilterString',
        () {
          final s = CompandSettings(
            enabled: true,
            volume: CompandSettings.volumeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('digit-prefix param `soft-knee` lands in wire via params map', () {
        final s = const CompandSettings(
          enabled: true,
          params: {'soft-knee': 900.0},
        );
        expect(s.toFilterString(), contains('soft-knee='));
        expect(s.toFilterString(), contains('soft-knee=900.000'));
      });
    });
    group('CompensationdelaySettings (compensationdelay)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          compensationdelay: CompensationdelaySettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          compensationdelay: CompensationdelaySettings(enabled: true),
        );
        expect(
          fx.toAfChain(),
          '@aek_compensationdelay:lavfi-compensationdelay',
        );
      });

      test('param `cm` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, cm: 100);
        expect(s.toFilterString(), contains('cm='));
        expect(s.toFilterString(), contains('cm=100'));
      });

      test('param `dry` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, dry: 1.0);
        expect(s.toFilterString(), contains('dry='));
        expect(s.toFilterString(), contains('dry=1.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, m: 100);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=100'));
      });

      test('param `mm` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, mm: 10);
        expect(s.toFilterString(), contains('mm='));
        expect(s.toFilterString(), contains('mm=10'));
      });

      test('param `temp` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, temp: 50);
        expect(s.toFilterString(), contains('temp='));
        expect(s.toFilterString(), contains('temp=50'));
      });

      test('param `wet` lands in wire when set to a non-default value', () {
        final s = const CompensationdelaySettings(enabled: true, wet: 0.0);
        expect(s.toFilterString(), contains('wet='));
        expect(s.toFilterString(), contains('wet=0.000'));
      });

      test('param `cm` const `cmMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          cm: CompensationdelaySettings.cmMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `cm` const `cmMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          cm: CompensationdelaySettings.cmMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `cm` const `cmDefault` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          cm: CompensationdelaySettings.cmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          dry: CompensationdelaySettings.dryMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          dry: CompensationdelaySettings.dryMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `dry` const `dryDefault` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          dry: CompensationdelaySettings.dryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          m: CompensationdelaySettings.mMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          m: CompensationdelaySettings.mMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          m: CompensationdelaySettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          mm: CompensationdelaySettings.mmMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          mm: CompensationdelaySettings.mmMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mm` const `mmDefault` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          mm: CompensationdelaySettings.mmDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `temp` const `tempMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          temp: CompensationdelaySettings.tempMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `temp` const `tempMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          temp: CompensationdelaySettings.tempMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `temp` const `tempDefault` is accepted by toFilterString',
        () {
          final s = CompensationdelaySettings(
            enabled: true,
            temp: CompensationdelaySettings.tempDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `wet` const `wetMin` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          wet: CompensationdelaySettings.wetMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetMax` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          wet: CompensationdelaySettings.wetMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `wet` const `wetDefault` is accepted by toFilterString', () {
        final s = CompensationdelaySettings(
          enabled: true,
          wet: CompensationdelaySettings.wetDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('CrossfeedSettings (crossfeed)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(crossfeed: CrossfeedSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(crossfeed: CrossfeedSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_crossfeed:lavfi-crossfeed');
      });

      test(
        'param `block_size` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedSettings(enabled: true, block_size: 32768);
          expect(s.toFilterString(), contains('block_size='));
          expect(s.toFilterString(), contains('block_size=32768'));
        },
      );

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedSettings(enabled: true, level_in: 1.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=1.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedSettings(enabled: true, level_out: 0.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=0.000'));
        },
      );

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const CrossfeedSettings(enabled: true, range: 1.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=1.000'));
      });

      test('param `slope` lands in wire when set to a non-default value', () {
        final s = const CrossfeedSettings(enabled: true, slope: 1.0);
        expect(s.toFilterString(), contains('slope='));
        expect(s.toFilterString(), contains('slope=1.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const CrossfeedSettings(enabled: true, strength: 1.0);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=1.000'));
        },
      );

      test(
        'param `block_size` const `block_sizeMin` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            block_size: CrossfeedSettings.block_sizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `block_size` const `block_sizeMax` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            block_size: CrossfeedSettings.block_sizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `block_size` const `block_sizeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            block_size: CrossfeedSettings.block_sizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_in: CrossfeedSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_in: CrossfeedSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_in: CrossfeedSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_out: CrossfeedSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_out: CrossfeedSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            level_out: CrossfeedSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `range` const `rangeMin` is accepted by toFilterString', () {
        final s = CrossfeedSettings(
          enabled: true,
          range: CrossfeedSettings.rangeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `range` const `rangeMax` is accepted by toFilterString', () {
        final s = CrossfeedSettings(
          enabled: true,
          range: CrossfeedSettings.rangeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `range` const `rangeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            range: CrossfeedSettings.rangeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slope` const `slopeMin` is accepted by toFilterString', () {
        final s = CrossfeedSettings(
          enabled: true,
          slope: CrossfeedSettings.slopeMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slope` const `slopeMax` is accepted by toFilterString', () {
        final s = CrossfeedSettings(
          enabled: true,
          slope: CrossfeedSettings.slopeMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slope` const `slopeDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            slope: CrossfeedSettings.slopeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            strength: CrossfeedSettings.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            strength: CrossfeedSettings.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = CrossfeedSettings(
            enabled: true,
            strength: CrossfeedSettings.strengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('CrystalizerSettings (crystalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          crystalizer: CrystalizerSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          crystalizer: CrystalizerSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_crystalizer:lavfi-crystalizer');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const CrystalizerSettings(enabled: true, c: false);
        expect(s.toFilterString(), contains('c='));
      });

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const CrystalizerSettings(enabled: true, i: 10.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=10.000'));
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = CrystalizerSettings(
          enabled: true,
          i: CrystalizerSettings.iMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = CrystalizerSettings(
          enabled: true,
          i: CrystalizerSettings.iMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = CrystalizerSettings(
          enabled: true,
          i: CrystalizerSettings.iDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('DcshiftSettings (dcshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(dcshift: DcshiftSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(dcshift: DcshiftSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_dcshift:lavfi-dcshift');
      });

      test(
        'param `limitergain` lands in wire when set to a non-default value',
        () {
          final s = const DcshiftSettings(enabled: true, limitergain: 1.0);
          expect(s.toFilterString(), contains('limitergain='));
          expect(s.toFilterString(), contains('limitergain=1.000'));
        },
      );

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const DcshiftSettings(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });

      test(
        'param `limitergain` const `limitergainMin` is accepted by toFilterString',
        () {
          final s = DcshiftSettings(
            enabled: true,
            limitergain: DcshiftSettings.limitergainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `limitergain` const `limitergainMax` is accepted by toFilterString',
        () {
          final s = DcshiftSettings(
            enabled: true,
            limitergain: DcshiftSettings.limitergainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `limitergain` const `limitergainDefault` is accepted by toFilterString',
        () {
          final s = DcshiftSettings(
            enabled: true,
            limitergain: DcshiftSettings.limitergainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `shift` const `shiftMin` is accepted by toFilterString', () {
        final s = DcshiftSettings(
          enabled: true,
          shift: DcshiftSettings.shiftMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `shift` const `shiftMax` is accepted by toFilterString', () {
        final s = DcshiftSettings(
          enabled: true,
          shift: DcshiftSettings.shiftMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `shift` const `shiftDefault` is accepted by toFilterString',
        () {
          final s = DcshiftSettings(
            enabled: true,
            shift: DcshiftSettings.shiftDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DeesserSettings (deesser)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(deesser: DeesserSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(deesser: DeesserSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_deesser:lavfi-deesser');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const DeesserSettings(enabled: true, f: 1.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=1.000'));
      });

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const DeesserSettings(enabled: true, i: 1.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=1.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const DeesserSettings(enabled: true, m: 1.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=1.000'));
      });

      test('param `s` lands in wire when set to a non-default value', () {
        final s = const DeesserSettings(enabled: true, s: DeesserMode.i);
        expect(s.toFilterString(), contains('s='));
        expect(s.toFilterString(), contains('s=i'));
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, f: DeesserSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, f: DeesserSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, f: DeesserSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, i: DeesserSettings.iMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, i: DeesserSettings.iMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, i: DeesserSettings.iDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, m: DeesserSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, m: DeesserSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = DeesserSettings(enabled: true, m: DeesserSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('DialoguenhanceSettings (dialoguenhance)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          dialoguenhance: DialoguenhanceSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          dialoguenhance: DialoguenhanceSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_dialoguenhance:lavfi-dialoguenhance');
      });

      test('param `enhance` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceSettings(enabled: true, enhance: 3.0);
        expect(s.toFilterString(), contains('enhance='));
        expect(s.toFilterString(), contains('enhance=3.000'));
      });

      test(
        'param `original` lands in wire when set to a non-default value',
        () {
          final s = const DialoguenhanceSettings(enabled: true, original: 0.0);
          expect(s.toFilterString(), contains('original='));
          expect(s.toFilterString(), contains('original=0.000'));
        },
      );

      test('param `voice` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceSettings(enabled: true, voice: 32.0);
        expect(s.toFilterString(), contains('voice='));
        expect(s.toFilterString(), contains('voice=32.000'));
      });

      test(
        'param `enhance` const `enhanceMin` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            enhance: DialoguenhanceSettings.enhanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `enhance` const `enhanceMax` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            enhance: DialoguenhanceSettings.enhanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `enhance` const `enhanceDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            enhance: DialoguenhanceSettings.enhanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalMin` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            original: DialoguenhanceSettings.originalMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalMax` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            original: DialoguenhanceSettings.originalMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `original` const `originalDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            original: DialoguenhanceSettings.originalDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `voice` const `voiceMin` is accepted by toFilterString', () {
        final s = DialoguenhanceSettings(
          enabled: true,
          voice: DialoguenhanceSettings.voiceMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `voice` const `voiceMax` is accepted by toFilterString', () {
        final s = DialoguenhanceSettings(
          enabled: true,
          voice: DialoguenhanceSettings.voiceMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `voice` const `voiceDefault` is accepted by toFilterString',
        () {
          final s = DialoguenhanceSettings(
            enabled: true,
            voice: DialoguenhanceSettings.voiceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DrmeterSettings (drmeter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(drmeter: DrmeterSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(drmeter: DrmeterSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_drmeter:lavfi-drmeter');
      });

      test('param `length` lands in wire when set to a non-default value', () {
        final s = const DrmeterSettings(enabled: true, length: 10.0);
        expect(s.toFilterString(), contains('length='));
        expect(s.toFilterString(), contains('length=10.000'));
      });

      test(
        'param `length` const `lengthMin` is accepted by toFilterString',
        () {
          final s = DrmeterSettings(
            enabled: true,
            length: DrmeterSettings.lengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `length` const `lengthMax` is accepted by toFilterString',
        () {
          final s = DrmeterSettings(
            enabled: true,
            length: DrmeterSettings.lengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `length` const `lengthDefault` is accepted by toFilterString',
        () {
          final s = DrmeterSettings(
            enabled: true,
            length: DrmeterSettings.lengthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('DynaudnormSettings (dynaudnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(dynaudnorm: DynaudnormSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(dynaudnorm: DynaudnormSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_dynaudnorm:lavfi-dynaudnorm');
      });

      test(
        'param `altboundary` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, altboundary: true);
          expect(s.toFilterString(), contains('altboundary='));
        },
      );

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, b: true);
        expect(s.toFilterString(), contains('b='));
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, c: true);
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `compress` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, compress: 30.0);
          expect(s.toFilterString(), contains('compress='));
          expect(s.toFilterString(), contains('compress=30.000'));
        },
      );

      test(
        'param `correctdc` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, correctdc: true);
          expect(s.toFilterString(), contains('correctdc='));
        },
      );

      test(
        'param `coupling` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, coupling: false);
          expect(s.toFilterString(), contains('coupling='));
        },
      );

      test('param `curve` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(
          enabled: true,
          curve: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('curve='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, f: 8000);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=8000'));
      });

      test(
        'param `framelen` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, framelen: 8000);
          expect(s.toFilterString(), contains('framelen='));
          expect(s.toFilterString(), contains('framelen=8000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, g: 301);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=301'));
      });

      test(
        'param `gausssize` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, gausssize: 301);
          expect(s.toFilterString(), contains('gausssize='));
          expect(s.toFilterString(), contains('gausssize=301'));
        },
      );

      test('param `h` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, h: 'wire_test_alt');
        expect(s.toFilterString(), contains('h='));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, m: 100.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=100.000'));
      });

      test('param `maxgain` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, maxgain: 100.0);
        expect(s.toFilterString(), contains('maxgain='));
        expect(s.toFilterString(), contains('maxgain=100.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, n: false);
        expect(s.toFilterString(), contains('n='));
      });

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, o: 1.0);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=1.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, p: 1.0);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1.000'));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, peak: 1.0);
        expect(s.toFilterString(), contains('peak='));
        expect(s.toFilterString(), contains('peak=1.000'));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, r: 1.0);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=1.000'));
      });

      test('param `s` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, s: 30.0);
        expect(s.toFilterString(), contains('s='));
        expect(s.toFilterString(), contains('s=30.000'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, t: 1.0);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=1.000'));
      });

      test(
        'param `targetrms` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, targetrms: 1.0);
          expect(s.toFilterString(), contains('targetrms='));
          expect(s.toFilterString(), contains('targetrms=1.000'));
        },
      );

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const DynaudnormSettings(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test('param `v` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, v: 'wire_test_alt');
        expect(s.toFilterString(), contains('v='));
      });

      test(
        'param `compress` const `compressMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            compress: DynaudnormSettings.compressMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compress` const `compressMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            compress: DynaudnormSettings.compressMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compress` const `compressDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            compress: DynaudnormSettings.compressDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, f: DynaudnormSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, f: DynaudnormSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          f: DynaudnormSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `framelen` const `framelenMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            framelen: DynaudnormSettings.framelenMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `framelen` const `framelenMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            framelen: DynaudnormSettings.framelenMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `framelen` const `framelenDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            framelen: DynaudnormSettings.framelenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, g: DynaudnormSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, g: DynaudnormSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          g: DynaudnormSettings.gDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gausssize` const `gausssizeMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            gausssize: DynaudnormSettings.gausssizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gausssize` const `gausssizeMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            gausssize: DynaudnormSettings.gausssizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `gausssize` const `gausssizeDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            gausssize: DynaudnormSettings.gausssizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, m: DynaudnormSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, m: DynaudnormSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          m: DynaudnormSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `maxgain` const `maxgainMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            maxgain: DynaudnormSettings.maxgainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `maxgain` const `maxgainMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            maxgain: DynaudnormSettings.maxgainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `maxgain` const `maxgainDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            maxgain: DynaudnormSettings.maxgainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `o` const `oMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, o: DynaudnormSettings.oMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, o: DynaudnormSettings.oMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `o` const `oDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          o: DynaudnormSettings.oDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            overlap: DynaudnormSettings.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            overlap: DynaudnormSettings.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            overlap: DynaudnormSettings.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, p: DynaudnormSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, p: DynaudnormSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          p: DynaudnormSettings.pDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          peak: DynaudnormSettings.peakMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          peak: DynaudnormSettings.peakMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `peak` const `peakDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            peak: DynaudnormSettings.peakDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `r` const `rMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, r: DynaudnormSettings.rMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `r` const `rMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, r: DynaudnormSettings.rMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `r` const `rDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          r: DynaudnormSettings.rDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, s: DynaudnormSettings.sMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, s: DynaudnormSettings.sMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `s` const `sDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          s: DynaudnormSettings.sDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMin` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, t: DynaudnormSettings.tMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMax` is accepted by toFilterString', () {
        final s = DynaudnormSettings(enabled: true, t: DynaudnormSettings.tMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tDefault` is accepted by toFilterString', () {
        final s = DynaudnormSettings(
          enabled: true,
          t: DynaudnormSettings.tDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `targetrms` const `targetrmsMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            targetrms: DynaudnormSettings.targetrmsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `targetrms` const `targetrmsMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            targetrms: DynaudnormSettings.targetrmsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `targetrms` const `targetrmsDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            targetrms: DynaudnormSettings.targetrmsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            threshold: DynaudnormSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            threshold: DynaudnormSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = DynaudnormSettings(
            enabled: true,
            threshold: DynaudnormSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('EarwaxSettings (earwax)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(earwax: EarwaxSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(earwax: EarwaxSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_earwax:lavfi-earwax');
      });
    });
    group('Ebur128Settings (ebur128)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(ebur128: Ebur128Settings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(ebur128: Ebur128Settings(enabled: true));
        expect(fx.toAfChain(), '@aek_ebur128:lavfi-ebur128');
      });

      test(
        'param `dualmono` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Settings(enabled: true, dualmono: true);
          expect(s.toFilterString(), contains('dualmono='));
        },
      );

      test(
        'param `framelog` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Settings(
            enabled: true,
            framelog: Ebur128Level.info,
          );
          expect(s.toFilterString(), contains('framelog='));
          expect(s.toFilterString(), contains('framelog=info'));
        },
      );

      test('param `gauge` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(
          enabled: true,
          gauge: Ebur128Gaugetype.m,
        );
        expect(s.toFilterString(), contains('gauge='));
        expect(s.toFilterString(), contains('gauge=m'));
      });

      test(
        'param `metadata` lands in wire when set to a non-default value',
        () {
          final s = const Ebur128Settings(enabled: true, metadata: true);
          expect(s.toFilterString(), contains('metadata='));
        },
      );

      test('param `meter` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, meter: 18);
        expect(s.toFilterString(), contains('meter='));
        expect(s.toFilterString(), contains('meter=18'));
      });

      test('param `panlaw` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, panlaw: 0.0);
        expect(s.toFilterString(), contains('panlaw='));
        expect(s.toFilterString(), contains('panlaw=0.000'));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(
          enabled: true,
          peak: const {Ebur128Mode.none},
        );
        expect(s.toFilterString(), contains('peak='));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(
          enabled: true,
          scale: Ebur128Scaletype.LUFS,
        );
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=LUFS'));
      });

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, size: 'wire_test_alt');
        expect(s.toFilterString(), contains('size='));
      });

      test('param `target` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, target: 0);
        expect(s.toFilterString(), contains('target='));
        expect(s.toFilterString(), contains('target=0'));
      });

      test('param `video` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, video: true);
        expect(s.toFilterString(), contains('video='));
      });

      test('param `meter` const `meterMin` is accepted by toFilterString', () {
        final s = Ebur128Settings(
          enabled: true,
          meter: Ebur128Settings.meterMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `meter` const `meterMax` is accepted by toFilterString', () {
        final s = Ebur128Settings(
          enabled: true,
          meter: Ebur128Settings.meterMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `meter` const `meterDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            meter: Ebur128Settings.meterDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawMin` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            panlaw: Ebur128Settings.panlawMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawMax` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            panlaw: Ebur128Settings.panlawMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `panlaw` const `panlawDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            panlaw: Ebur128Settings.panlawDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetMin` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            target: Ebur128Settings.targetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetMax` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            target: Ebur128Settings.targetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `target` const `targetDefault` is accepted by toFilterString',
        () {
          final s = Ebur128Settings(
            enabled: true,
            target: Ebur128Settings.targetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('EqualizerSettings (equalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(equalizer: EqualizerSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(equalizer: EqualizerSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_equalizer:lavfi-equalizer');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(
          enabled: true,
          a: EqualizerTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(
            enabled: true,
            precision: EqualizerPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(
          enabled: true,
          r: EqualizerPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(
          enabled: true,
          t: EqualizerWidthType.h,
        );
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(
            enabled: true,
            transform: EqualizerTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const EqualizerSettings(
            enabled: true,
            width_type: EqualizerWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, b: EqualizerSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, b: EqualizerSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          b: EqualizerSettings.bDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            blocksize: EqualizerSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            blocksize: EqualizerSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            blocksize: EqualizerSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, f: EqualizerSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, f: EqualizerSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          f: EqualizerSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            frequency: EqualizerSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            frequency: EqualizerSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            frequency: EqualizerSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, g: EqualizerSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, g: EqualizerSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          g: EqualizerSettings.gDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          gain: EqualizerSettings.gainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          gain: EqualizerSettings.gainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            gain: EqualizerSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, m: EqualizerSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, m: EqualizerSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          m: EqualizerSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          mix: EqualizerSettings.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          mix: EqualizerSettings.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          mix: EqualizerSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, w: EqualizerSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(enabled: true, w: EqualizerSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          w: EqualizerSettings.wDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          width: EqualizerSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = EqualizerSettings(
          enabled: true,
          width: EqualizerSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = EqualizerSettings(
            enabled: true,
            width: EqualizerSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('ExtrastereoSettings (extrastereo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          extrastereo: ExtrastereoSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          extrastereo: ExtrastereoSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_extrastereo:lavfi-extrastereo');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const ExtrastereoSettings(enabled: true, c: false);
        expect(s.toFilterString(), contains('c='));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const ExtrastereoSettings(enabled: true, m: 10.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=10.000'));
      });

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = ExtrastereoSettings(
          enabled: true,
          m: ExtrastereoSettings.mMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = ExtrastereoSettings(
          enabled: true,
          m: ExtrastereoSettings.mMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = ExtrastereoSettings(
          enabled: true,
          m: ExtrastereoSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('FirequalizerSettings (firequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          firequalizer: FirequalizerSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          firequalizer: FirequalizerSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_firequalizer:lavfi-firequalizer');
      });

      test(
        'param `accuracy` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(
            enabled: true,
            accuracy: 10000000000.0,
          );
          expect(s.toFilterString(), contains('accuracy='));
          expect(s.toFilterString(), contains('accuracy=10000000000.000'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
          enabled: true,
          delay: 10000000000.0,
        );
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=10000000000.000'));
      });

      test(
        'param `dumpfile` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(
            enabled: true,
            dumpfile: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('dumpfile='));
        },
      );

      test(
        'param `dumpscale` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(
            enabled: true,
            dumpscale: FirequalizerScale.linlin,
          );
          expect(s.toFilterString(), contains('dumpscale='));
          expect(s.toFilterString(), contains('dumpscale=linlin'));
        },
      );

      test('param `fft2` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, fft2: true);
        expect(s.toFilterString(), contains('fft2='));
      });

      test('param `fixed` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, fixed: true);
        expect(s.toFilterString(), contains('fixed='));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
          enabled: true,
          gain: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('gain='));
      });

      test(
        'param `gain_entry` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(
            enabled: true,
            gain_entry: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('gain_entry='));
        },
      );

      test(
        'param `min_phase` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(enabled: true, min_phase: true);
          expect(s.toFilterString(), contains('min_phase='));
        },
      );

      test('param `multi` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, multi: true);
        expect(s.toFilterString(), contains('multi='));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
          enabled: true,
          scale: FirequalizerScale.linlin,
        );
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=linlin'));
      });

      test('param `wfunc` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
          enabled: true,
          wfunc: FirequalizerWfunc.rectangular,
        );
        expect(s.toFilterString(), contains('wfunc='));
        expect(s.toFilterString(), contains('wfunc=rectangular'));
      });

      test(
        'param `zero_phase` lands in wire when set to a non-default value',
        () {
          final s = const FirequalizerSettings(enabled: true, zero_phase: true);
          expect(s.toFilterString(), contains('zero_phase='));
        },
      );

      test(
        'param `accuracy` const `accuracyMin` is accepted by toFilterString',
        () {
          final s = FirequalizerSettings(
            enabled: true,
            accuracy: FirequalizerSettings.accuracyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `accuracy` const `accuracyMax` is accepted by toFilterString',
        () {
          final s = FirequalizerSettings(
            enabled: true,
            accuracy: FirequalizerSettings.accuracyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `accuracy` const `accuracyDefault` is accepted by toFilterString',
        () {
          final s = FirequalizerSettings(
            enabled: true,
            accuracy: FirequalizerSettings.accuracyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = FirequalizerSettings(
          enabled: true,
          delay: FirequalizerSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = FirequalizerSettings(
          enabled: true,
          delay: FirequalizerSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = FirequalizerSettings(
            enabled: true,
            delay: FirequalizerSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('FlangerSettings (flanger)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(flanger: FlangerSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(flanger: FlangerSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_flanger:lavfi-flanger');
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, delay: 30.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=30.000'));
      });

      test('param `depth` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, depth: 10.0);
        expect(s.toFilterString(), contains('depth='));
        expect(s.toFilterString(), contains('depth=10.000'));
      });

      test('param `interp` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(
          enabled: true,
          interp: FlangerItype.quadratic,
        );
        expect(s.toFilterString(), contains('interp='));
        expect(s.toFilterString(), contains('interp=quadratic'));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, phase: 100.0);
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=100.000'));
      });

      test('param `regen` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, regen: 95.0);
        expect(s.toFilterString(), contains('regen='));
        expect(s.toFilterString(), contains('regen=95.000'));
      });

      test('param `shape` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(
          enabled: true,
          shape: FlangerType.triangular,
        );
        expect(s.toFilterString(), contains('shape='));
        expect(s.toFilterString(), contains('shape=triangular'));
      });

      test('param `speed` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, speed: 10.0);
        expect(s.toFilterString(), contains('speed='));
        expect(s.toFilterString(), contains('speed=10.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const FlangerSettings(enabled: true, width: 100.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=100.000'));
      });

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          delay: FlangerSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          delay: FlangerSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            delay: FlangerSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `depth` const `depthMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          depth: FlangerSettings.depthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `depth` const `depthMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          depth: FlangerSettings.depthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `depth` const `depthDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            depth: FlangerSettings.depthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `phase` const `phaseMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          phase: FlangerSettings.phaseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `phase` const `phaseMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          phase: FlangerSettings.phaseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `phase` const `phaseDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            phase: FlangerSettings.phaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `regen` const `regenMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          regen: FlangerSettings.regenMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `regen` const `regenMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          regen: FlangerSettings.regenMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `regen` const `regenDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            regen: FlangerSettings.regenDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `speed` const `speedMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          speed: FlangerSettings.speedMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `speed` const `speedMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          speed: FlangerSettings.speedMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `speed` const `speedDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            speed: FlangerSettings.speedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          width: FlangerSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = FlangerSettings(
          enabled: true,
          width: FlangerSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = FlangerSettings(
            enabled: true,
            width: FlangerSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HaasSettings (haas)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(haas: HaasSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(haas: HaasSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_haas:lavfi-haas');
      });

      test(
        'param `left_balance` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, left_balance: 1.0);
          expect(s.toFilterString(), contains('left_balance='));
          expect(s.toFilterString(), contains('left_balance=1.000'));
        },
      );

      test(
        'param `left_delay` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, left_delay: 40.0);
          expect(s.toFilterString(), contains('left_delay='));
          expect(s.toFilterString(), contains('left_delay=40.000'));
        },
      );

      test(
        'param `left_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, left_gain: 64.0);
          expect(s.toFilterString(), contains('left_gain='));
          expect(s.toFilterString(), contains('left_gain=64.000'));
        },
      );

      test(
        'param `left_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, left_phase: true);
          expect(s.toFilterString(), contains('left_phase='));
        },
      );

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test(
        'param `middle_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, middle_phase: true);
          expect(s.toFilterString(), contains('middle_phase='));
        },
      );

      test(
        'param `middle_source` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(
            enabled: true,
            middle_source: HaasSource.left,
          );
          expect(s.toFilterString(), contains('middle_source='));
          expect(s.toFilterString(), contains('middle_source=left'));
        },
      );

      test(
        'param `right_balance` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, right_balance: -1.0);
          expect(s.toFilterString(), contains('right_balance='));
          expect(s.toFilterString(), contains('right_balance=-1.000'));
        },
      );

      test(
        'param `right_delay` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, right_delay: 40.0);
          expect(s.toFilterString(), contains('right_delay='));
          expect(s.toFilterString(), contains('right_delay=40.000'));
        },
      );

      test(
        'param `right_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, right_gain: 64.0);
          expect(s.toFilterString(), contains('right_gain='));
          expect(s.toFilterString(), contains('right_gain=64.000'));
        },
      );

      test(
        'param `right_phase` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, right_phase: false);
          expect(s.toFilterString(), contains('right_phase='));
        },
      );

      test(
        'param `side_gain` lands in wire when set to a non-default value',
        () {
          final s = const HaasSettings(enabled: true, side_gain: 64.0);
          expect(s.toFilterString(), contains('side_gain='));
          expect(s.toFilterString(), contains('side_gain=64.000'));
        },
      );

      test(
        'param `left_balance` const `left_balanceMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_balance: HaasSettings.left_balanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_balance` const `left_balanceMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_balance: HaasSettings.left_balanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_balance` const `left_balanceDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_balance: HaasSettings.left_balanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `left_delayMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_delay: HaasSettings.left_delayMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `left_delayMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_delay: HaasSettings.left_delayMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_delay` const `left_delayDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_delay: HaasSettings.left_delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `left_gainMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_gain: HaasSettings.left_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `left_gainMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_gain: HaasSettings.left_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `left_gain` const `left_gainDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            left_gain: HaasSettings.left_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_in: HaasSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_in: HaasSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_in: HaasSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_out: HaasSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_out: HaasSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            level_out: HaasSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `right_balanceMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_balance: HaasSettings.right_balanceMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `right_balanceMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_balance: HaasSettings.right_balanceMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_balance` const `right_balanceDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_balance: HaasSettings.right_balanceDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `right_delayMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_delay: HaasSettings.right_delayMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `right_delayMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_delay: HaasSettings.right_delayMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_delay` const `right_delayDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_delay: HaasSettings.right_delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `right_gainMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_gain: HaasSettings.right_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `right_gainMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_gain: HaasSettings.right_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `right_gain` const `right_gainDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            right_gain: HaasSettings.right_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `side_gainMin` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            side_gain: HaasSettings.side_gainMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `side_gainMax` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            side_gain: HaasSettings.side_gainMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `side_gain` const `side_gainDefault` is accepted by toFilterString',
        () {
          final s = HaasSettings(
            enabled: true,
            side_gain: HaasSettings.side_gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HdcdSettings (hdcd)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(hdcd: HdcdSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(hdcd: HdcdSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_hdcd:lavfi-hdcd');
      });

      test(
        'param `analyze_mode` lands in wire when set to a non-default value',
        () {
          final s = const HdcdSettings(
            enabled: true,
            analyze_mode: HdcdAnalyzeMode.lle,
          );
          expect(s.toFilterString(), contains('analyze_mode='));
          expect(s.toFilterString(), contains('analyze_mode=lle'));
        },
      );

      test(
        'param `bits_per_sample` lands in wire when set to a non-default value',
        () {
          final s = const HdcdSettings(
            enabled: true,
            bits_per_sample: HdcdBitsPerSample.n20,
          );
          expect(s.toFilterString(), contains('bits_per_sample='));
          expect(s.toFilterString(), contains('bits_per_sample=20'));
        },
      );

      test('param `cdt_ms` lands in wire when set to a non-default value', () {
        final s = const HdcdSettings(enabled: true, cdt_ms: 60000);
        expect(s.toFilterString(), contains('cdt_ms='));
        expect(s.toFilterString(), contains('cdt_ms=60000'));
      });

      test(
        'param `disable_autoconvert` lands in wire when set to a non-default value',
        () {
          final s = const HdcdSettings(
            enabled: true,
            disable_autoconvert: false,
          );
          expect(s.toFilterString(), contains('disable_autoconvert='));
        },
      );

      test(
        'param `force_pe` lands in wire when set to a non-default value',
        () {
          final s = const HdcdSettings(enabled: true, force_pe: true);
          expect(s.toFilterString(), contains('force_pe='));
        },
      );

      test(
        'param `process_stereo` lands in wire when set to a non-default value',
        () {
          final s = const HdcdSettings(enabled: true, process_stereo: true);
          expect(s.toFilterString(), contains('process_stereo='));
        },
      );

      test(
        'param `cdt_ms` const `cdt_msMin` is accepted by toFilterString',
        () {
          final s = HdcdSettings(enabled: true, cdt_ms: HdcdSettings.cdt_msMin);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cdt_ms` const `cdt_msMax` is accepted by toFilterString',
        () {
          final s = HdcdSettings(enabled: true, cdt_ms: HdcdSettings.cdt_msMax);
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cdt_ms` const `cdt_msDefault` is accepted by toFilterString',
        () {
          final s = HdcdSettings(
            enabled: true,
            cdt_ms: HdcdSettings.cdt_msDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HighpassSettings (highpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(highpass: HighpassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(highpass: HighpassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_highpass:lavfi-highpass');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(
          enabled: true,
          a: HighpassTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(
            enabled: true,
            precision: HighpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(
          enabled: true,
          r: HighpassPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, t: HighpassWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(
            enabled: true,
            transform: HighpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const HighpassSettings(
            enabled: true,
            width_type: HighpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, b: HighpassSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, b: HighpassSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, b: HighpassSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            blocksize: HighpassSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            blocksize: HighpassSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            blocksize: HighpassSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, f: HighpassSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, f: HighpassSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, f: HighpassSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            frequency: HighpassSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            frequency: HighpassSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            frequency: HighpassSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, m: HighpassSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, m: HighpassSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, m: HighpassSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, mix: HighpassSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, mix: HighpassSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(
          enabled: true,
          mix: HighpassSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, p: HighpassSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, p: HighpassSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, p: HighpassSettings.pDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = HighpassSettings(
          enabled: true,
          poles: HighpassSettings.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = HighpassSettings(
          enabled: true,
          poles: HighpassSettings.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            poles: HighpassSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, w: HighpassSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, w: HighpassSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = HighpassSettings(enabled: true, w: HighpassSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = HighpassSettings(
          enabled: true,
          width: HighpassSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = HighpassSettings(
          enabled: true,
          width: HighpassSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = HighpassSettings(
            enabled: true,
            width: HighpassSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('HighshelfSettings (highshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(highshelf: HighshelfSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(highshelf: HighshelfSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_highshelf:lavfi-highshelf');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(
          enabled: true,
          a: HighshelfTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(
            enabled: true,
            precision: HighshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(
          enabled: true,
          r: HighshelfPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(
          enabled: true,
          t: HighshelfWidthType.h,
        );
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(
            enabled: true,
            transform: HighshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const HighshelfSettings(
            enabled: true,
            width_type: HighshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, b: HighshelfSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, b: HighshelfSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          b: HighshelfSettings.bDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            blocksize: HighshelfSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            blocksize: HighshelfSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            blocksize: HighshelfSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, f: HighshelfSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, f: HighshelfSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          f: HighshelfSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            frequency: HighshelfSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            frequency: HighshelfSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            frequency: HighshelfSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, g: HighshelfSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, g: HighshelfSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          g: HighshelfSettings.gDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          gain: HighshelfSettings.gainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          gain: HighshelfSettings.gainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            gain: HighshelfSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, m: HighshelfSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, m: HighshelfSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          m: HighshelfSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          mix: HighshelfSettings.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          mix: HighshelfSettings.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          mix: HighshelfSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, p: HighshelfSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, p: HighshelfSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          p: HighshelfSettings.pDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          poles: HighshelfSettings.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          poles: HighshelfSettings.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            poles: HighshelfSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, w: HighshelfSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(enabled: true, w: HighshelfSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          w: HighshelfSettings.wDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          width: HighshelfSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = HighshelfSettings(
          enabled: true,
          width: HighshelfSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = HighshelfSettings(
            enabled: true,
            width: HighshelfSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('LoudnormSettings (loudnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(loudnorm: LoudnormSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(loudnorm: LoudnormSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_loudnorm:lavfi-loudnorm');
      });

      test('param `I` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, I: -5.0);
        expect(s.toFilterString(), contains('I='));
        expect(s.toFilterString(), contains('I=-5.000'));
      });

      test('param `LRA` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, LRA: 50.0);
        expect(s.toFilterString(), contains('LRA='));
        expect(s.toFilterString(), contains('LRA=50.000'));
      });

      test('param `TP` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, TP: 0.0);
        expect(s.toFilterString(), contains('TP='));
        expect(s.toFilterString(), contains('TP=0.000'));
      });

      test(
        'param `dual_mono` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, dual_mono: true);
          expect(s.toFilterString(), contains('dual_mono='));
        },
      );

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, i: -5.0);
        expect(s.toFilterString(), contains('i='));
        expect(s.toFilterString(), contains('i=-5.000'));
      });

      test('param `linear` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, linear: false);
        expect(s.toFilterString(), contains('linear='));
      });

      test('param `lra` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, lra: 50.0);
        expect(s.toFilterString(), contains('lra='));
        expect(s.toFilterString(), contains('lra=50.000'));
      });

      test(
        'param `measured_I` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_I: -99.0);
          expect(s.toFilterString(), contains('measured_I='));
          expect(s.toFilterString(), contains('measured_I=-99.000'));
        },
      );

      test(
        'param `measured_LRA` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_LRA: 99.0);
          expect(s.toFilterString(), contains('measured_LRA='));
          expect(s.toFilterString(), contains('measured_LRA=99.000'));
        },
      );

      test(
        'param `measured_TP` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_TP: -99.0);
          expect(s.toFilterString(), contains('measured_TP='));
          expect(s.toFilterString(), contains('measured_TP=-99.000'));
        },
      );

      test(
        'param `measured_i` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_i: -99.0);
          expect(s.toFilterString(), contains('measured_i='));
          expect(s.toFilterString(), contains('measured_i=-99.000'));
        },
      );

      test(
        'param `measured_lra` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_lra: 99.0);
          expect(s.toFilterString(), contains('measured_lra='));
          expect(s.toFilterString(), contains('measured_lra=99.000'));
        },
      );

      test(
        'param `measured_thresh` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_thresh: 0.0);
          expect(s.toFilterString(), contains('measured_thresh='));
          expect(s.toFilterString(), contains('measured_thresh=0.000'));
        },
      );

      test(
        'param `measured_tp` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(enabled: true, measured_tp: -99.0);
          expect(s.toFilterString(), contains('measured_tp='));
          expect(s.toFilterString(), contains('measured_tp=-99.000'));
        },
      );

      test('param `offset` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, offset: 99.0);
        expect(s.toFilterString(), contains('offset='));
        expect(s.toFilterString(), contains('offset=99.000'));
      });

      test(
        'param `print_format` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(
            enabled: true,
            print_format: LoudnormPrintFormat.json,
          );
          expect(s.toFilterString(), contains('print_format='));
          expect(s.toFilterString(), contains('print_format=json'));
        },
      );

      test(
        'param `stats_file` lands in wire when set to a non-default value',
        () {
          final s = const LoudnormSettings(
            enabled: true,
            stats_file: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('stats_file='));
        },
      );

      test('param `tp` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, tp: 0.0);
        expect(s.toFilterString(), contains('tp='));
        expect(s.toFilterString(), contains('tp=0.000'));
      });

      test('param `I` const `IMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, I: LoudnormSettings.IMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `I` const `IMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, I: LoudnormSettings.IMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `I` const `IDefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, I: LoudnormSettings.IDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `LRA` const `LRAMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, LRA: LoudnormSettings.LRAMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `LRA` const `LRAMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, LRA: LoudnormSettings.LRAMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `LRA` const `LRADefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(
          enabled: true,
          LRA: LoudnormSettings.LRADefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `TP` const `TPMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, TP: LoudnormSettings.TPMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `TP` const `TPMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, TP: LoudnormSettings.TPMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `TP` const `TPDefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(
          enabled: true,
          TP: LoudnormSettings.TPDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, i: LoudnormSettings.iMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, i: LoudnormSettings.iMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `i` const `iDefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, i: LoudnormSettings.iDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, lra: LoudnormSettings.lraMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, lra: LoudnormSettings.lraMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `lra` const `lraDefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(
          enabled: true,
          lra: LoudnormSettings.lraDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `measured_I` const `measured_IMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_I: LoudnormSettings.measured_IMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_I` const `measured_IMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_I: LoudnormSettings.measured_IMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_I` const `measured_IDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_I: LoudnormSettings.measured_IDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_LRA` const `measured_LRAMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_LRA: LoudnormSettings.measured_LRAMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_LRA` const `measured_LRAMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_LRA: LoudnormSettings.measured_LRAMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_LRA` const `measured_LRADefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_LRA: LoudnormSettings.measured_LRADefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_TP` const `measured_TPMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_TP: LoudnormSettings.measured_TPMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_TP` const `measured_TPMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_TP: LoudnormSettings.measured_TPMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_TP` const `measured_TPDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_TP: LoudnormSettings.measured_TPDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_i` const `measured_iMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_i: LoudnormSettings.measured_iMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_i` const `measured_iMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_i: LoudnormSettings.measured_iMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_i` const `measured_iDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_i: LoudnormSettings.measured_iDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measured_lraMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_lra: LoudnormSettings.measured_lraMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measured_lraMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_lra: LoudnormSettings.measured_lraMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_lra` const `measured_lraDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_lra: LoudnormSettings.measured_lraDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measured_threshMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_thresh: LoudnormSettings.measured_threshMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measured_threshMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_thresh: LoudnormSettings.measured_threshMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_thresh` const `measured_threshDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_thresh: LoudnormSettings.measured_threshDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measured_tpMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_tp: LoudnormSettings.measured_tpMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measured_tpMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_tp: LoudnormSettings.measured_tpMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `measured_tp` const `measured_tpDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            measured_tp: LoudnormSettings.measured_tpDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetMin` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            offset: LoudnormSettings.offsetMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetMax` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            offset: LoudnormSettings.offsetMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `offset` const `offsetDefault` is accepted by toFilterString',
        () {
          final s = LoudnormSettings(
            enabled: true,
            offset: LoudnormSettings.offsetDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `tp` const `tpMin` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, tp: LoudnormSettings.tpMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tp` const `tpMax` is accepted by toFilterString', () {
        final s = LoudnormSettings(enabled: true, tp: LoudnormSettings.tpMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tp` const `tpDefault` is accepted by toFilterString', () {
        final s = LoudnormSettings(
          enabled: true,
          tp: LoudnormSettings.tpDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('LowpassSettings (lowpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(lowpass: LowpassSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(lowpass: LowpassSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_lowpass:lavfi-lowpass');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(
          enabled: true,
          a: LowpassTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(
            enabled: true,
            precision: LowpassPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, r: LowpassPrecision.s16);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, t: LowpassWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(
            enabled: true,
            transform: LowpassTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const LowpassSettings(
            enabled: true,
            width_type: LowpassWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, b: LowpassSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, b: LowpassSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, b: LowpassSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            blocksize: LowpassSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            blocksize: LowpassSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            blocksize: LowpassSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, f: LowpassSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, f: LowpassSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, f: LowpassSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            frequency: LowpassSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            frequency: LowpassSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            frequency: LowpassSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, m: LowpassSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, m: LowpassSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, m: LowpassSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, mix: LowpassSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, mix: LowpassSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(
          enabled: true,
          mix: LowpassSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, p: LowpassSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, p: LowpassSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, p: LowpassSettings.pDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = LowpassSettings(
          enabled: true,
          poles: LowpassSettings.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = LowpassSettings(
          enabled: true,
          poles: LowpassSettings.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            poles: LowpassSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, w: LowpassSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, w: LowpassSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = LowpassSettings(enabled: true, w: LowpassSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = LowpassSettings(
          enabled: true,
          width: LowpassSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = LowpassSettings(
          enabled: true,
          width: LowpassSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = LowpassSettings(
            enabled: true,
            width: LowpassSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('LowshelfSettings (lowshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(lowshelf: LowshelfSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(lowshelf: LowshelfSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_lowshelf:lavfi-lowshelf');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(
          enabled: true,
          a: LowshelfTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(
            enabled: true,
            precision: LowshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(
          enabled: true,
          r: LowshelfPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, t: LowshelfWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(
            enabled: true,
            transform: LowshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const LowshelfSettings(
            enabled: true,
            width_type: LowshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, b: LowshelfSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, b: LowshelfSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, b: LowshelfSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            blocksize: LowshelfSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            blocksize: LowshelfSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            blocksize: LowshelfSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, f: LowshelfSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, f: LowshelfSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, f: LowshelfSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            frequency: LowshelfSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            frequency: LowshelfSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            frequency: LowshelfSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, g: LowshelfSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, g: LowshelfSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, g: LowshelfSettings.gDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          gain: LowshelfSettings.gainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          gain: LowshelfSettings.gainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            gain: LowshelfSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, m: LowshelfSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, m: LowshelfSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, m: LowshelfSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, mix: LowshelfSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, mix: LowshelfSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          mix: LowshelfSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, p: LowshelfSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, p: LowshelfSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, p: LowshelfSettings.pDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          poles: LowshelfSettings.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          poles: LowshelfSettings.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            poles: LowshelfSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, w: LowshelfSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, w: LowshelfSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = LowshelfSettings(enabled: true, w: LowshelfSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          width: LowshelfSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = LowshelfSettings(
          enabled: true,
          width: LowshelfSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = LowshelfSettings(
            enabled: true,
            width: LowshelfSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('McompandSettings (mcompand)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(mcompand: McompandSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(mcompand: McompandSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_mcompand:lavfi-mcompand');
      });

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const McompandSettings(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('PanSettings (pan)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          pan: PanSettings(enabled: false, args: 'stereo|c0=c0|c1=c1'),
        );
        expect(fx.toAfChain(), '');
      });

      test(
        'enabled with required params → wire carries the filter name and required options',
        () {
          const fx = AudioEffects(
            pan: PanSettings(enabled: true, args: 'stereo|c0=c0|c1=c1'),
          );
          expect(fx.toAfChain(), startsWith('@aek_pan:lavfi-pan'));
          expect(fx.toAfChain(), contains('args='));
        },
      );

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const PanSettings(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('RubberbandSettings (rubberband)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(rubberband: RubberbandSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(rubberband: RubberbandSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_rubberband:lavfi-rubberband');
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandSettings(
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
          final s = const RubberbandSettings(
            enabled: true,
            detector: RubberbandDetector.percussive,
          );
          expect(s.toFilterString(), contains('detector='));
          expect(s.toFilterString(), contains('detector=percussive'));
        },
      );

      test('param `formant` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
          enabled: true,
          formant: RubberbandFormant.preserved,
        );
        expect(s.toFilterString(), contains('formant='));
        expect(s.toFilterString(), contains('formant=preserved'));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
          enabled: true,
          phase: RubberbandPhase.independent,
        );
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=independent'));
      });

      test('param `pitch` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(enabled: true, pitch: 100.0);
        expect(s.toFilterString(), contains('pitch='));
        expect(s.toFilterString(), contains('pitch=100.000'));
      });

      test('param `pitchq` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
          enabled: true,
          pitchq: RubberbandPitch.speed,
        );
        expect(s.toFilterString(), contains('pitchq='));
        expect(s.toFilterString(), contains('pitchq=speed'));
      });

      test(
        'param `smoothing` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandSettings(
            enabled: true,
            smoothing: RubberbandSmoothing.on_,
          );
          expect(s.toFilterString(), contains('smoothing='));
          expect(s.toFilterString(), contains('smoothing=on'));
        },
      );

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(enabled: true, tempo: 100.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=100.000'));
      });

      test(
        'param `transients` lands in wire when set to a non-default value',
        () {
          final s = const RubberbandSettings(
            enabled: true,
            transients: RubberbandTransients.mixed,
          );
          expect(s.toFilterString(), contains('transients='));
          expect(s.toFilterString(), contains('transients=mixed'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
          enabled: true,
          window: RubberbandWindow.short,
        );
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=short'));
      });

      test('param `pitch` const `pitchMin` is accepted by toFilterString', () {
        final s = RubberbandSettings(
          enabled: true,
          pitch: RubberbandSettings.pitchMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `pitch` const `pitchMax` is accepted by toFilterString', () {
        final s = RubberbandSettings(
          enabled: true,
          pitch: RubberbandSettings.pitchMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `pitch` const `pitchDefault` is accepted by toFilterString',
        () {
          final s = RubberbandSettings(
            enabled: true,
            pitch: RubberbandSettings.pitchDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `tempo` const `tempoMin` is accepted by toFilterString', () {
        final s = RubberbandSettings(
          enabled: true,
          tempo: RubberbandSettings.tempoMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `tempo` const `tempoMax` is accepted by toFilterString', () {
        final s = RubberbandSettings(
          enabled: true,
          tempo: RubberbandSettings.tempoMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `tempo` const `tempoDefault` is accepted by toFilterString',
        () {
          final s = RubberbandSettings(
            enabled: true,
            tempo: RubberbandSettings.tempoDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SilenceremoveSettings (silenceremove)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          silenceremove: SilenceremoveSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          silenceremove: SilenceremoveSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_silenceremove:lavfi-silenceremove');
      });

      test(
        'param `detection` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
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
          final s = const SilenceremoveSettings(
            enabled: true,
            start_duration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_duration='));
        },
      );

      test(
        'param `start_mode` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            start_mode: SilenceremoveMode.all,
          );
          expect(s.toFilterString(), contains('start_mode='));
          expect(s.toFilterString(), contains('start_mode=all'));
        },
      );

      test(
        'param `start_periods` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            start_periods: 9000,
          );
          expect(s.toFilterString(), contains('start_periods='));
          expect(s.toFilterString(), contains('start_periods=9000'));
        },
      );

      test(
        'param `start_silence` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            start_silence: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('start_silence='));
        },
      );

      test(
        'param `start_threshold` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            start_threshold: 1.0,
          );
          expect(s.toFilterString(), contains('start_threshold='));
          expect(s.toFilterString(), contains('start_threshold=1.000'));
        },
      );

      test(
        'param `stop_duration` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            stop_duration: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('stop_duration='));
        },
      );

      test(
        'param `stop_mode` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            stop_mode: SilenceremoveMode.any,
          );
          expect(s.toFilterString(), contains('stop_mode='));
          expect(s.toFilterString(), contains('stop_mode=any'));
        },
      );

      test(
        'param `stop_periods` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            stop_periods: 9000,
          );
          expect(s.toFilterString(), contains('stop_periods='));
          expect(s.toFilterString(), contains('stop_periods=9000'));
        },
      );

      test(
        'param `stop_silence` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            stop_silence: const Duration(microseconds: 1000000),
          );
          expect(s.toFilterString(), contains('stop_silence='));
        },
      );

      test(
        'param `stop_threshold` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            stop_threshold: 1.0,
          );
          expect(s.toFilterString(), contains('stop_threshold='));
          expect(s.toFilterString(), contains('stop_threshold=1.000'));
        },
      );

      test(
        'param `timestamp` lands in wire when set to a non-default value',
        () {
          final s = const SilenceremoveSettings(
            enabled: true,
            timestamp: SilenceremoveTimestamp.copy,
          );
          expect(s.toFilterString(), contains('timestamp='));
          expect(s.toFilterString(), contains('timestamp=copy'));
        },
      );

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const SilenceremoveSettings(
          enabled: true,
          window: const Duration(microseconds: 1020000),
        );
        expect(s.toFilterString(), contains('window='));
      });

      test(
        'param `start_periods` const `start_periodsMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_periods: SilenceremoveSettings.start_periodsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_periods` const `start_periodsMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_periods: SilenceremoveSettings.start_periodsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_periods` const `start_periodsDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_periods: SilenceremoveSettings.start_periodsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `start_thresholdMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_threshold: SilenceremoveSettings.start_thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `start_thresholdMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_threshold: SilenceremoveSettings.start_thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `start_threshold` const `start_thresholdDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            start_threshold: SilenceremoveSettings.start_thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stop_periodsMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_periods: SilenceremoveSettings.stop_periodsMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stop_periodsMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_periods: SilenceremoveSettings.stop_periodsMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_periods` const `stop_periodsDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_periods: SilenceremoveSettings.stop_periodsDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stop_thresholdMin` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_threshold: SilenceremoveSettings.stop_thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stop_thresholdMax` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_threshold: SilenceremoveSettings.stop_thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `stop_threshold` const `stop_thresholdDefault` is accepted by toFilterString',
        () {
          final s = SilenceremoveSettings(
            enabled: true,
            stop_threshold: SilenceremoveSettings.stop_thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SpeechnormSettings (speechnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(speechnorm: SpeechnormSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(speechnorm: SpeechnormSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_speechnorm:lavfi-speechnorm');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, c: 50.0);
        expect(s.toFilterString(), contains('c='));
        expect(s.toFilterString(), contains('c=50.000'));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test(
        'param `compression` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormSettings(enabled: true, compression: 50.0);
          expect(s.toFilterString(), contains('compression='));
          expect(s.toFilterString(), contains('compression=50.000'));
        },
      );

      test('param `e` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, e: 50.0);
        expect(s.toFilterString(), contains('e='));
        expect(s.toFilterString(), contains('e=50.000'));
      });

      test(
        'param `expansion` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormSettings(enabled: true, expansion: 50.0);
          expect(s.toFilterString(), contains('expansion='));
          expect(s.toFilterString(), contains('expansion=50.000'));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, f: 1.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=1.000'));
      });

      test('param `fall` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, fall: 1.0);
        expect(s.toFilterString(), contains('fall='));
        expect(s.toFilterString(), contains('fall=1.000'));
      });

      test('param `h` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, h: 'wire_test_alt');
        expect(s.toFilterString(), contains('h='));
      });

      test('param `i` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, i: true);
        expect(s.toFilterString(), contains('i='));
      });

      test('param `invert` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, invert: true);
        expect(s.toFilterString(), contains('invert='));
      });

      test('param `l` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, l: true);
        expect(s.toFilterString(), contains('l='));
      });

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, link: true);
        expect(s.toFilterString(), contains('link='));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, m: 1.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=1.000'));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, p: 1.0);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1.000'));
      });

      test('param `peak` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, peak: 1.0);
        expect(s.toFilterString(), contains('peak='));
        expect(s.toFilterString(), contains('peak=1.000'));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, r: 1.0);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=1.000'));
      });

      test('param `raise` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, raise: 1.0);
        expect(s.toFilterString(), contains('raise='));
        expect(s.toFilterString(), contains('raise=1.000'));
      });

      test('param `rms` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, rms: 1.0);
        expect(s.toFilterString(), contains('rms='));
        expect(s.toFilterString(), contains('rms=1.000'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, t: 1.0);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=1.000'));
      });

      test(
        'param `threshold` lands in wire when set to a non-default value',
        () {
          final s = const SpeechnormSettings(enabled: true, threshold: 1.0);
          expect(s.toFilterString(), contains('threshold='));
          expect(s.toFilterString(), contains('threshold=1.000'));
        },
      );

      test('param `c` const `cMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, c: SpeechnormSettings.cMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `c` const `cMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, c: SpeechnormSettings.cMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `c` const `cDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          c: SpeechnormSettings.cDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `compression` const `compressionMin` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            compression: SpeechnormSettings.compressionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compression` const `compressionMax` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            compression: SpeechnormSettings.compressionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `compression` const `compressionDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            compression: SpeechnormSettings.compressionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `e` const `eMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, e: SpeechnormSettings.eMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `e` const `eMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, e: SpeechnormSettings.eMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `e` const `eDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          e: SpeechnormSettings.eDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `expansion` const `expansionMin` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            expansion: SpeechnormSettings.expansionMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `expansion` const `expansionMax` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            expansion: SpeechnormSettings.expansionMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `expansion` const `expansionDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            expansion: SpeechnormSettings.expansionDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, f: SpeechnormSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, f: SpeechnormSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          f: SpeechnormSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fall` const `fallMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          fall: SpeechnormSettings.fallMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fall` const `fallMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          fall: SpeechnormSettings.fallMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fall` const `fallDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            fall: SpeechnormSettings.fallDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, m: SpeechnormSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, m: SpeechnormSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          m: SpeechnormSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, p: SpeechnormSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, p: SpeechnormSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          p: SpeechnormSettings.pDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          peak: SpeechnormSettings.peakMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `peak` const `peakMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          peak: SpeechnormSettings.peakMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `peak` const `peakDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            peak: SpeechnormSettings.peakDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `r` const `rMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, r: SpeechnormSettings.rMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `r` const `rMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, r: SpeechnormSettings.rMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `r` const `rDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          r: SpeechnormSettings.rDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `raise` const `raiseMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          raise: SpeechnormSettings.raiseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `raise` const `raiseMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          raise: SpeechnormSettings.raiseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `raise` const `raiseDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            raise: SpeechnormSettings.raiseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `rms` const `rmsMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          rms: SpeechnormSettings.rmsMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rms` const `rmsMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          rms: SpeechnormSettings.rmsMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `rms` const `rmsDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          rms: SpeechnormSettings.rmsDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMin` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, t: SpeechnormSettings.tMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tMax` is accepted by toFilterString', () {
        final s = SpeechnormSettings(enabled: true, t: SpeechnormSettings.tMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `t` const `tDefault` is accepted by toFilterString', () {
        final s = SpeechnormSettings(
          enabled: true,
          t: SpeechnormSettings.tDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `threshold` const `thresholdMin` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            threshold: SpeechnormSettings.thresholdMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdMax` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            threshold: SpeechnormSettings.thresholdMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `threshold` const `thresholdDefault` is accepted by toFilterString',
        () {
          final s = SpeechnormSettings(
            enabled: true,
            threshold: SpeechnormSettings.thresholdDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('StereotoolsSettings (stereotools)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          stereotools: StereotoolsSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          stereotools: StereotoolsSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_stereotools:lavfi-stereotools');
      });

      test(
        'param `balance_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(enabled: true, balance_in: 1.0);
          expect(s.toFilterString(), contains('balance_in='));
          expect(s.toFilterString(), contains('balance_in=1.000'));
        },
      );

      test(
        'param `balance_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(enabled: true, balance_out: 1.0);
          expect(s.toFilterString(), contains('balance_out='));
          expect(s.toFilterString(), contains('balance_out=1.000'));
        },
      );

      test('param `base` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, base: 1.0);
        expect(s.toFilterString(), contains('base='));
        expect(s.toFilterString(), contains('base=1.000'));
      });

      test(
        'param `bmode_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(
            enabled: true,
            bmode_in: StereotoolsBmode.amplitude,
          );
          expect(s.toFilterString(), contains('bmode_in='));
          expect(s.toFilterString(), contains('bmode_in=amplitude'));
        },
      );

      test(
        'param `bmode_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(
            enabled: true,
            bmode_out: StereotoolsBmode.amplitude,
          );
          expect(s.toFilterString(), contains('bmode_out='));
          expect(s.toFilterString(), contains('bmode_out=amplitude'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, delay: 20.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=20.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(enabled: true, level_in: 64.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=64.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(enabled: true, level_out: 64.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=64.000'));
        },
      );

      test('param `mlev` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, mlev: 64.0);
        expect(s.toFilterString(), contains('mlev='));
        expect(s.toFilterString(), contains('mlev=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(
          enabled: true,
          mode: StereotoolsMode.lr_to_ms,
        );
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=lr>ms'));
      });

      test('param `mpan` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, mpan: 1.0);
        expect(s.toFilterString(), contains('mpan='));
        expect(s.toFilterString(), contains('mpan=1.000'));
      });

      test('param `mutel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, mutel: true);
        expect(s.toFilterString(), contains('mutel='));
      });

      test('param `muter` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, muter: true);
        expect(s.toFilterString(), contains('muter='));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, phase: 360.0);
        expect(s.toFilterString(), contains('phase='));
        expect(s.toFilterString(), contains('phase=360.000'));
      });

      test('param `phasel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, phasel: true);
        expect(s.toFilterString(), contains('phasel='));
      });

      test('param `phaser` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, phaser: true);
        expect(s.toFilterString(), contains('phaser='));
      });

      test('param `sbal` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, sbal: 1.0);
        expect(s.toFilterString(), contains('sbal='));
        expect(s.toFilterString(), contains('sbal=1.000'));
      });

      test('param `sclevel` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, sclevel: 100.0);
        expect(s.toFilterString(), contains('sclevel='));
        expect(s.toFilterString(), contains('sclevel=100.000'));
      });

      test('param `slev` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, slev: 64.0);
        expect(s.toFilterString(), contains('slev='));
        expect(s.toFilterString(), contains('slev=64.000'));
      });

      test(
        'param `softclip` lands in wire when set to a non-default value',
        () {
          final s = const StereotoolsSettings(enabled: true, softclip: true);
          expect(s.toFilterString(), contains('softclip='));
        },
      );

      test(
        'param `balance_in` const `balance_inMin` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_in: StereotoolsSettings.balance_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_in` const `balance_inMax` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_in: StereotoolsSettings.balance_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_in` const `balance_inDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_in: StereotoolsSettings.balance_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balance_outMin` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_out: StereotoolsSettings.balance_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balance_outMax` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_out: StereotoolsSettings.balance_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `balance_out` const `balance_outDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            balance_out: StereotoolsSettings.balance_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `base` const `baseMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          base: StereotoolsSettings.baseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `base` const `baseMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          base: StereotoolsSettings.baseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `base` const `baseDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            base: StereotoolsSettings.baseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          delay: StereotoolsSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          delay: StereotoolsSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            delay: StereotoolsSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_in: StereotoolsSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_in: StereotoolsSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_in: StereotoolsSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_out: StereotoolsSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_out: StereotoolsSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            level_out: StereotoolsSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mlev` const `mlevMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          mlev: StereotoolsSettings.mlevMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mlev` const `mlevMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          mlev: StereotoolsSettings.mlevMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mlev` const `mlevDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            mlev: StereotoolsSettings.mlevDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `mpan` const `mpanMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          mpan: StereotoolsSettings.mpanMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mpan` const `mpanMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          mpan: StereotoolsSettings.mpanMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `mpan` const `mpanDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            mpan: StereotoolsSettings.mpanDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `phase` const `phaseMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          phase: StereotoolsSettings.phaseMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `phase` const `phaseMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          phase: StereotoolsSettings.phaseMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `phase` const `phaseDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            phase: StereotoolsSettings.phaseDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sbal` const `sbalMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          sbal: StereotoolsSettings.sbalMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sbal` const `sbalMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          sbal: StereotoolsSettings.sbalMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sbal` const `sbalDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            sbal: StereotoolsSettings.sbalDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelMin` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            sclevel: StereotoolsSettings.sclevelMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelMax` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            sclevel: StereotoolsSettings.sclevelMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sclevel` const `sclevelDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            sclevel: StereotoolsSettings.sclevelDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slev` const `slevMin` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          slev: StereotoolsSettings.slevMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slev` const `slevMax` is accepted by toFilterString', () {
        final s = StereotoolsSettings(
          enabled: true,
          slev: StereotoolsSettings.slevMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `slev` const `slevDefault` is accepted by toFilterString',
        () {
          final s = StereotoolsSettings(
            enabled: true,
            slev: StereotoolsSettings.slevDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('StereowidenSettings (stereowiden)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          stereowiden: StereowidenSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          stereowiden: StereowidenSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_stereowiden:lavfi-stereowiden');
      });

      test(
        'param `crossfeed` lands in wire when set to a non-default value',
        () {
          final s = const StereowidenSettings(enabled: true, crossfeed: 0.8);
          expect(s.toFilterString(), contains('crossfeed='));
          expect(s.toFilterString(), contains('crossfeed=0.800'));
        },
      );

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const StereowidenSettings(enabled: true, delay: 100.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=100.000'));
      });

      test('param `drymix` lands in wire when set to a non-default value', () {
        final s = const StereowidenSettings(enabled: true, drymix: 1.0);
        expect(s.toFilterString(), contains('drymix='));
        expect(s.toFilterString(), contains('drymix=1.000'));
      });

      test(
        'param `feedback` lands in wire when set to a non-default value',
        () {
          final s = const StereowidenSettings(enabled: true, feedback: 0.9);
          expect(s.toFilterString(), contains('feedback='));
          expect(s.toFilterString(), contains('feedback=0.900'));
        },
      );

      test(
        'param `crossfeed` const `crossfeedMin` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            crossfeed: StereowidenSettings.crossfeedMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `crossfeed` const `crossfeedMax` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            crossfeed: StereowidenSettings.crossfeedMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `crossfeed` const `crossfeedDefault` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            crossfeed: StereowidenSettings.crossfeedDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `delay` const `delayMin` is accepted by toFilterString', () {
        final s = StereowidenSettings(
          enabled: true,
          delay: StereowidenSettings.delayMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `delay` const `delayMax` is accepted by toFilterString', () {
        final s = StereowidenSettings(
          enabled: true,
          delay: StereowidenSettings.delayMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `delay` const `delayDefault` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            delay: StereowidenSettings.delayDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixMin` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            drymix: StereowidenSettings.drymixMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixMax` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            drymix: StereowidenSettings.drymixMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `drymix` const `drymixDefault` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            drymix: StereowidenSettings.drymixDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMin` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            feedback: StereowidenSettings.feedbackMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackMax` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            feedback: StereowidenSettings.feedbackMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `feedback` const `feedbackDefault` is accepted by toFilterString',
        () {
          final s = StereowidenSettings(
            enabled: true,
            feedback: StereowidenSettings.feedbackDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('SuperequalizerSettings (superequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          superequalizer: SuperequalizerSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          superequalizer: SuperequalizerSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_superequalizer:lavfi-superequalizer');
      });

      test('digit-prefix param `10b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'10b': 20.0},
        );
        expect(s.toFilterString(), contains('10b='));
        expect(s.toFilterString(), contains('10b=20.000'));
      });

      test('digit-prefix param `11b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'11b': 20.0},
        );
        expect(s.toFilterString(), contains('11b='));
        expect(s.toFilterString(), contains('11b=20.000'));
      });

      test('digit-prefix param `12b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'12b': 20.0},
        );
        expect(s.toFilterString(), contains('12b='));
        expect(s.toFilterString(), contains('12b=20.000'));
      });

      test('digit-prefix param `13b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'13b': 20.0},
        );
        expect(s.toFilterString(), contains('13b='));
        expect(s.toFilterString(), contains('13b=20.000'));
      });

      test('digit-prefix param `14b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'14b': 20.0},
        );
        expect(s.toFilterString(), contains('14b='));
        expect(s.toFilterString(), contains('14b=20.000'));
      });

      test('digit-prefix param `15b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'15b': 20.0},
        );
        expect(s.toFilterString(), contains('15b='));
        expect(s.toFilterString(), contains('15b=20.000'));
      });

      test('digit-prefix param `16b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'16b': 20.0},
        );
        expect(s.toFilterString(), contains('16b='));
        expect(s.toFilterString(), contains('16b=20.000'));
      });

      test('digit-prefix param `17b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'17b': 20.0},
        );
        expect(s.toFilterString(), contains('17b='));
        expect(s.toFilterString(), contains('17b=20.000'));
      });

      test('digit-prefix param `18b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'18b': 20.0},
        );
        expect(s.toFilterString(), contains('18b='));
        expect(s.toFilterString(), contains('18b=20.000'));
      });

      test('digit-prefix param `1b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'1b': 20.0},
        );
        expect(s.toFilterString(), contains('1b='));
        expect(s.toFilterString(), contains('1b=20.000'));
      });

      test('digit-prefix param `2b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'2b': 20.0},
        );
        expect(s.toFilterString(), contains('2b='));
        expect(s.toFilterString(), contains('2b=20.000'));
      });

      test('digit-prefix param `3b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'3b': 20.0},
        );
        expect(s.toFilterString(), contains('3b='));
        expect(s.toFilterString(), contains('3b=20.000'));
      });

      test('digit-prefix param `4b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'4b': 20.0},
        );
        expect(s.toFilterString(), contains('4b='));
        expect(s.toFilterString(), contains('4b=20.000'));
      });

      test('digit-prefix param `5b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'5b': 20.0},
        );
        expect(s.toFilterString(), contains('5b='));
        expect(s.toFilterString(), contains('5b=20.000'));
      });

      test('digit-prefix param `6b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'6b': 20.0},
        );
        expect(s.toFilterString(), contains('6b='));
        expect(s.toFilterString(), contains('6b=20.000'));
      });

      test('digit-prefix param `7b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'7b': 20.0},
        );
        expect(s.toFilterString(), contains('7b='));
        expect(s.toFilterString(), contains('7b=20.000'));
      });

      test('digit-prefix param `8b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'8b': 20.0},
        );
        expect(s.toFilterString(), contains('8b='));
        expect(s.toFilterString(), contains('8b=20.000'));
      });

      test('digit-prefix param `9b` lands in wire via params map', () {
        final s = const SuperequalizerSettings(
          enabled: true,
          params: {'9b': 20.0},
        );
        expect(s.toFilterString(), contains('9b='));
        expect(s.toFilterString(), contains('9b=20.000'));
      });
    });
    group('SurroundSettings (surround)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(surround: SurroundSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(surround: SurroundSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_surround:lavfi-surround');
      });

      test('param `allx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, allx: 15.0);
        expect(s.toFilterString(), contains('allx='));
        expect(s.toFilterString(), contains('allx=15.000'));
      });

      test('param `ally` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, ally: 15.0);
        expect(s.toFilterString(), contains('ally='));
        expect(s.toFilterString(), contains('ally=15.000'));
      });

      test('param `angle` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, angle: 360.0);
        expect(s.toFilterString(), contains('angle='));
        expect(s.toFilterString(), contains('angle=360.000'));
      });

      test('param `bc_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bc_in: 10.0);
        expect(s.toFilterString(), contains('bc_in='));
        expect(s.toFilterString(), contains('bc_in=10.000'));
      });

      test('param `bc_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bc_out: 10.0);
        expect(s.toFilterString(), contains('bc_out='));
        expect(s.toFilterString(), contains('bc_out=10.000'));
      });

      test('param `bcx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bcx: 15.0);
        expect(s.toFilterString(), contains('bcx='));
        expect(s.toFilterString(), contains('bcx=15.000'));
      });

      test('param `bcy` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bcy: 15.0);
        expect(s.toFilterString(), contains('bcy='));
        expect(s.toFilterString(), contains('bcy=15.000'));
      });

      test('param `bl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bl_in: 10.0);
        expect(s.toFilterString(), contains('bl_in='));
        expect(s.toFilterString(), contains('bl_in=10.000'));
      });

      test('param `bl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bl_out: 10.0);
        expect(s.toFilterString(), contains('bl_out='));
        expect(s.toFilterString(), contains('bl_out=10.000'));
      });

      test('param `blx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, blx: 15.0);
        expect(s.toFilterString(), contains('blx='));
        expect(s.toFilterString(), contains('blx=15.000'));
      });

      test('param `bly` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bly: 15.0);
        expect(s.toFilterString(), contains('bly='));
        expect(s.toFilterString(), contains('bly=15.000'));
      });

      test('param `br_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, br_in: 10.0);
        expect(s.toFilterString(), contains('br_in='));
        expect(s.toFilterString(), contains('br_in=10.000'));
      });

      test('param `br_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, br_out: 10.0);
        expect(s.toFilterString(), contains('br_out='));
        expect(s.toFilterString(), contains('br_out=10.000'));
      });

      test('param `brx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, brx: 15.0);
        expect(s.toFilterString(), contains('brx='));
        expect(s.toFilterString(), contains('brx=15.000'));
      });

      test('param `bry` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, bry: 15.0);
        expect(s.toFilterString(), contains('bry='));
        expect(s.toFilterString(), contains('bry=15.000'));
      });

      test('param `chl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(
          enabled: true,
          chl_in: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('chl_in='));
      });

      test('param `chl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(
          enabled: true,
          chl_out: 'wire_test_alt',
        );
        expect(s.toFilterString(), contains('chl_out='));
      });

      test('param `fc_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fc_in: 10.0);
        expect(s.toFilterString(), contains('fc_in='));
        expect(s.toFilterString(), contains('fc_in=10.000'));
      });

      test('param `fc_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fc_out: 10.0);
        expect(s.toFilterString(), contains('fc_out='));
        expect(s.toFilterString(), contains('fc_out=10.000'));
      });

      test('param `fcx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fcx: 15.0);
        expect(s.toFilterString(), contains('fcx='));
        expect(s.toFilterString(), contains('fcx=15.000'));
      });

      test('param `fcy` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fcy: 15.0);
        expect(s.toFilterString(), contains('fcy='));
        expect(s.toFilterString(), contains('fcy=15.000'));
      });

      test('param `fl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fl_in: 10.0);
        expect(s.toFilterString(), contains('fl_in='));
        expect(s.toFilterString(), contains('fl_in=10.000'));
      });

      test('param `fl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fl_out: 10.0);
        expect(s.toFilterString(), contains('fl_out='));
        expect(s.toFilterString(), contains('fl_out=10.000'));
      });

      test('param `flx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, flx: 15.0);
        expect(s.toFilterString(), contains('flx='));
        expect(s.toFilterString(), contains('flx=15.000'));
      });

      test('param `fly` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fly: 15.0);
        expect(s.toFilterString(), contains('fly='));
        expect(s.toFilterString(), contains('fly=15.000'));
      });

      test('param `focus` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, focus: 1.0);
        expect(s.toFilterString(), contains('focus='));
        expect(s.toFilterString(), contains('focus=1.000'));
      });

      test('param `fr_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fr_in: 10.0);
        expect(s.toFilterString(), contains('fr_in='));
        expect(s.toFilterString(), contains('fr_in=10.000'));
      });

      test('param `fr_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fr_out: 10.0);
        expect(s.toFilterString(), contains('fr_out='));
        expect(s.toFilterString(), contains('fr_out=10.000'));
      });

      test('param `frx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, frx: 15.0);
        expect(s.toFilterString(), contains('frx='));
        expect(s.toFilterString(), contains('frx=15.000'));
      });

      test('param `fry` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, fry: 15.0);
        expect(s.toFilterString(), contains('fry='));
        expect(s.toFilterString(), contains('fry=15.000'));
      });

      test(
        'param `level_in` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(enabled: true, level_in: 10.0);
          expect(s.toFilterString(), contains('level_in='));
          expect(s.toFilterString(), contains('level_in=10.000'));
        },
      );

      test(
        'param `level_out` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(enabled: true, level_out: 10.0);
          expect(s.toFilterString(), contains('level_out='));
          expect(s.toFilterString(), contains('level_out=10.000'));
        },
      );

      test('param `lfe` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, lfe: false);
        expect(s.toFilterString(), contains('lfe='));
      });

      test(
        'param `lfe_high` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(enabled: true, lfe_high: 512);
          expect(s.toFilterString(), contains('lfe_high='));
          expect(s.toFilterString(), contains('lfe_high=512'));
        },
      );

      test('param `lfe_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, lfe_in: 10.0);
        expect(s.toFilterString(), contains('lfe_in='));
        expect(s.toFilterString(), contains('lfe_in=10.000'));
      });

      test('param `lfe_low` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, lfe_low: 256);
        expect(s.toFilterString(), contains('lfe_low='));
        expect(s.toFilterString(), contains('lfe_low=256'));
      });

      test(
        'param `lfe_mode` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(
            enabled: true,
            lfe_mode: SurroundLfeMode.sub,
          );
          expect(s.toFilterString(), contains('lfe_mode='));
          expect(s.toFilterString(), contains('lfe_mode=sub'));
        },
      );

      test('param `lfe_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, lfe_out: 10.0);
        expect(s.toFilterString(), contains('lfe_out='));
        expect(s.toFilterString(), contains('lfe_out=10.000'));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `sl_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sl_in: 10.0);
        expect(s.toFilterString(), contains('sl_in='));
        expect(s.toFilterString(), contains('sl_in=10.000'));
      });

      test('param `sl_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sl_out: 10.0);
        expect(s.toFilterString(), contains('sl_out='));
        expect(s.toFilterString(), contains('sl_out=10.000'));
      });

      test('param `slx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, slx: 15.0);
        expect(s.toFilterString(), contains('slx='));
        expect(s.toFilterString(), contains('slx=15.000'));
      });

      test('param `sly` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sly: 15.0);
        expect(s.toFilterString(), contains('sly='));
        expect(s.toFilterString(), contains('sly=15.000'));
      });

      test('param `smooth` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, smooth: 1.0);
        expect(s.toFilterString(), contains('smooth='));
        expect(s.toFilterString(), contains('smooth=1.000'));
      });

      test('param `sr_in` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sr_in: 10.0);
        expect(s.toFilterString(), contains('sr_in='));
        expect(s.toFilterString(), contains('sr_in=10.000'));
      });

      test('param `sr_out` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sr_out: 10.0);
        expect(s.toFilterString(), contains('sr_out='));
        expect(s.toFilterString(), contains('sr_out=10.000'));
      });

      test('param `srx` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, srx: 15.0);
        expect(s.toFilterString(), contains('srx='));
        expect(s.toFilterString(), contains('srx=15.000'));
      });

      test('param `sry` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, sry: 15.0);
        expect(s.toFilterString(), contains('sry='));
        expect(s.toFilterString(), contains('sry=15.000'));
      });

      test(
        'param `win_func` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(
            enabled: true,
            win_func: SurroundWinFunc.rect,
          );
          expect(s.toFilterString(), contains('win_func='));
          expect(s.toFilterString(), contains('win_func=rect'));
        },
      );

      test(
        'param `win_size` lands in wire when set to a non-default value',
        () {
          final s = const SurroundSettings(enabled: true, win_size: 65536);
          expect(s.toFilterString(), contains('win_size='));
          expect(s.toFilterString(), contains('win_size=65536'));
        },
      );

      test('param `allx` const `allxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          allx: SurroundSettings.allxMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `allx` const `allxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          allx: SurroundSettings.allxMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `allx` const `allxDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            allx: SurroundSettings.allxDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `ally` const `allyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          ally: SurroundSettings.allyMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `ally` const `allyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          ally: SurroundSettings.allyMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `ally` const `allyDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            ally: SurroundSettings.allyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `angle` const `angleMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          angle: SurroundSettings.angleMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `angle` const `angleMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          angle: SurroundSettings.angleMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `angle` const `angleDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            angle: SurroundSettings.angleDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bc_in` const `bc_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bc_in: SurroundSettings.bc_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bc_in` const `bc_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bc_in: SurroundSettings.bc_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bc_in` const `bc_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bc_in: SurroundSettings.bc_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bc_out` const `bc_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bc_out: SurroundSettings.bc_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bc_out` const `bc_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bc_out: SurroundSettings.bc_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bc_out` const `bc_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bc_out: SurroundSettings.bc_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `bcx` const `bcxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bcx: SurroundSettings.bcxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcx` const `bcxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bcx: SurroundSettings.bcxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcx` const `bcxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bcx: SurroundSettings.bcxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bcy: SurroundSettings.bcyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bcy: SurroundSettings.bcyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bcy` const `bcyDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bcy: SurroundSettings.bcyDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bl_in` const `bl_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bl_in: SurroundSettings.bl_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bl_in` const `bl_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bl_in: SurroundSettings.bl_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `bl_in` const `bl_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bl_in: SurroundSettings.bl_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bl_out` const `bl_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bl_out: SurroundSettings.bl_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bl_out` const `bl_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bl_out: SurroundSettings.bl_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `bl_out` const `bl_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            bl_out: SurroundSettings.bl_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `blx` const `blxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, blx: SurroundSettings.blxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blx` const `blxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, blx: SurroundSettings.blxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `blx` const `blxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          blx: SurroundSettings.blxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bly: SurroundSettings.blyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bly: SurroundSettings.blyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bly` const `blyDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bly: SurroundSettings.blyDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `br_in` const `br_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          br_in: SurroundSettings.br_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `br_in` const `br_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          br_in: SurroundSettings.br_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `br_in` const `br_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            br_in: SurroundSettings.br_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `br_out` const `br_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            br_out: SurroundSettings.br_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `br_out` const `br_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            br_out: SurroundSettings.br_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `br_out` const `br_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            br_out: SurroundSettings.br_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `brx` const `brxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, brx: SurroundSettings.brxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `brx` const `brxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, brx: SurroundSettings.brxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `brx` const `brxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          brx: SurroundSettings.brxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bry: SurroundSettings.bryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, bry: SurroundSettings.bryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `bry` const `bryDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          bry: SurroundSettings.bryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fc_in` const `fc_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fc_in: SurroundSettings.fc_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fc_in` const `fc_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fc_in: SurroundSettings.fc_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fc_in` const `fc_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fc_in: SurroundSettings.fc_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fc_out` const `fc_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fc_out: SurroundSettings.fc_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fc_out` const `fc_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fc_out: SurroundSettings.fc_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fc_out` const `fc_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fc_out: SurroundSettings.fc_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fcx` const `fcxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fcx: SurroundSettings.fcxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcx` const `fcxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fcx: SurroundSettings.fcxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcx` const `fcxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fcx: SurroundSettings.fcxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fcy: SurroundSettings.fcyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fcy: SurroundSettings.fcyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fcy` const `fcyDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fcy: SurroundSettings.fcyDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fl_in` const `fl_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fl_in: SurroundSettings.fl_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fl_in` const `fl_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fl_in: SurroundSettings.fl_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fl_in` const `fl_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fl_in: SurroundSettings.fl_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fl_out` const `fl_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fl_out: SurroundSettings.fl_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fl_out` const `fl_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fl_out: SurroundSettings.fl_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fl_out` const `fl_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fl_out: SurroundSettings.fl_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `flx` const `flxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, flx: SurroundSettings.flxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `flx` const `flxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, flx: SurroundSettings.flxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `flx` const `flxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          flx: SurroundSettings.flxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fly: SurroundSettings.flyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fly: SurroundSettings.flyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fly` const `flyDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fly: SurroundSettings.flyDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `focus` const `focusMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          focus: SurroundSettings.focusMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `focus` const `focusMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          focus: SurroundSettings.focusMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `focus` const `focusDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            focus: SurroundSettings.focusDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `fr_in` const `fr_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fr_in: SurroundSettings.fr_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fr_in` const `fr_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fr_in: SurroundSettings.fr_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `fr_in` const `fr_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fr_in: SurroundSettings.fr_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fr_out` const `fr_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fr_out: SurroundSettings.fr_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fr_out` const `fr_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fr_out: SurroundSettings.fr_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `fr_out` const `fr_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            fr_out: SurroundSettings.fr_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `frx` const `frxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, frx: SurroundSettings.frxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `frx` const `frxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, frx: SurroundSettings.frxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `frx` const `frxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          frx: SurroundSettings.frxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fry: SurroundSettings.fryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, fry: SurroundSettings.fryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `fry` const `fryDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          fry: SurroundSettings.fryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `level_in` const `level_inMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_in: SurroundSettings.level_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_in: SurroundSettings.level_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_in` const `level_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_in: SurroundSettings.level_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_out: SurroundSettings.level_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_out: SurroundSettings.level_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `level_out` const `level_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            level_out: SurroundSettings.level_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfe_highMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_high: SurroundSettings.lfe_highMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfe_highMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_high: SurroundSettings.lfe_highMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_high` const `lfe_highDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_high: SurroundSettings.lfe_highDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_in` const `lfe_inMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_in: SurroundSettings.lfe_inMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_in` const `lfe_inMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_in: SurroundSettings.lfe_inMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_in` const `lfe_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_in: SurroundSettings.lfe_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfe_lowMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_low: SurroundSettings.lfe_lowMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfe_lowMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_low: SurroundSettings.lfe_lowMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_low` const `lfe_lowDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_low: SurroundSettings.lfe_lowDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfe_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_out: SurroundSettings.lfe_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfe_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_out: SurroundSettings.lfe_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `lfe_out` const `lfe_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            lfe_out: SurroundSettings.lfe_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            overlap: SurroundSettings.overlapMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            overlap: SurroundSettings.overlapMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `overlap` const `overlapDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            overlap: SurroundSettings.overlapDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sl_in` const `sl_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sl_in: SurroundSettings.sl_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sl_in` const `sl_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sl_in: SurroundSettings.sl_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sl_in` const `sl_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sl_in: SurroundSettings.sl_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sl_out` const `sl_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sl_out: SurroundSettings.sl_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sl_out` const `sl_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sl_out: SurroundSettings.sl_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sl_out` const `sl_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sl_out: SurroundSettings.sl_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `slx` const `slxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, slx: SurroundSettings.slxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slx` const `slxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, slx: SurroundSettings.slxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `slx` const `slxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          slx: SurroundSettings.slxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, sly: SurroundSettings.slyMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, sly: SurroundSettings.slyMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sly` const `slyDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sly: SurroundSettings.slyDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `smooth` const `smoothMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            smooth: SurroundSettings.smoothMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            smooth: SurroundSettings.smoothMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `smooth` const `smoothDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            smooth: SurroundSettings.smoothDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `sr_in` const `sr_inMin` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sr_in: SurroundSettings.sr_inMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sr_in` const `sr_inMax` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sr_in: SurroundSettings.sr_inMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `sr_in` const `sr_inDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sr_in: SurroundSettings.sr_inDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sr_out` const `sr_outMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sr_out: SurroundSettings.sr_outMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sr_out` const `sr_outMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sr_out: SurroundSettings.sr_outMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `sr_out` const `sr_outDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            sr_out: SurroundSettings.sr_outDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `srx` const `srxMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, srx: SurroundSettings.srxMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `srx` const `srxMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, srx: SurroundSettings.srxMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `srx` const `srxDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          srx: SurroundSettings.srxDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryMin` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, sry: SurroundSettings.sryMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryMax` is accepted by toFilterString', () {
        final s = SurroundSettings(enabled: true, sry: SurroundSettings.sryMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `sry` const `sryDefault` is accepted by toFilterString', () {
        final s = SurroundSettings(
          enabled: true,
          sry: SurroundSettings.sryDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `win_size` const `win_sizeMin` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            win_size: SurroundSettings.win_sizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `win_sizeMax` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            win_size: SurroundSettings.win_sizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `win_size` const `win_sizeDefault` is accepted by toFilterString',
        () {
          final s = SurroundSettings(
            enabled: true,
            win_size: SurroundSettings.win_sizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TiltshelfSettings (tiltshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(tiltshelf: TiltshelfSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(tiltshelf: TiltshelfSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_tiltshelf:lavfi-tiltshelf');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(
          enabled: true,
          a: TiltshelfTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(
            enabled: true,
            precision: TiltshelfPrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(
          enabled: true,
          r: TiltshelfPrecision.s16,
        );
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(
          enabled: true,
          t: TiltshelfWidthType.h,
        );
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(
            enabled: true,
            transform: TiltshelfTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const TiltshelfSettings(
            enabled: true,
            width_type: TiltshelfWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, b: TiltshelfSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, b: TiltshelfSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          b: TiltshelfSettings.bDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            blocksize: TiltshelfSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            blocksize: TiltshelfSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            blocksize: TiltshelfSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, f: TiltshelfSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, f: TiltshelfSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          f: TiltshelfSettings.fDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            frequency: TiltshelfSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            frequency: TiltshelfSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            frequency: TiltshelfSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, g: TiltshelfSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, g: TiltshelfSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          g: TiltshelfSettings.gDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          gain: TiltshelfSettings.gainMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          gain: TiltshelfSettings.gainMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            gain: TiltshelfSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, m: TiltshelfSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, m: TiltshelfSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          m: TiltshelfSettings.mDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          mix: TiltshelfSettings.mixMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          mix: TiltshelfSettings.mixMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          mix: TiltshelfSettings.mixDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, p: TiltshelfSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, p: TiltshelfSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          p: TiltshelfSettings.pDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          poles: TiltshelfSettings.polesMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          poles: TiltshelfSettings.polesMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            poles: TiltshelfSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, w: TiltshelfSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(enabled: true, w: TiltshelfSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          w: TiltshelfSettings.wDefault,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          width: TiltshelfSettings.widthMin,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = TiltshelfSettings(
          enabled: true,
          width: TiltshelfSettings.widthMax,
        );
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = TiltshelfSettings(
            enabled: true,
            width: TiltshelfSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TrebleSettings (treble)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(treble: TrebleSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(treble: TrebleSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_treble:lavfi-treble');
      });

      test('param `a` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(
          enabled: true,
          a: TrebleTransformType.dii,
        );
        expect(s.toFilterString(), contains('a='));
        expect(s.toFilterString(), contains('a=dii'));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, b: 32768);
        expect(s.toFilterString(), contains('b='));
        expect(s.toFilterString(), contains('b=32768'));
      });

      test(
        'param `blocksize` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(enabled: true, blocksize: 32768);
          expect(s.toFilterString(), contains('blocksize='));
          expect(s.toFilterString(), contains('blocksize=32768'));
        },
      );

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test(
        'param `channels` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(
            enabled: true,
            channels: 'wire_test_alt',
          );
          expect(s.toFilterString(), contains('channels='));
        },
      );

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test(
        'param `frequency` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(enabled: true, frequency: 999999.0);
          expect(s.toFilterString(), contains('frequency='));
          expect(s.toFilterString(), contains('frequency=999999.000'));
        },
      );

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, g: 900.0);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=900.000'));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, gain: 900.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=900.000'));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, m: 0.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=0.000'));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, mix: 0.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=0.000'));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, n: true);
        expect(s.toFilterString(), contains('n='));
      });

      test(
        'param `normalize` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(enabled: true, normalize: true);
          expect(s.toFilterString(), contains('normalize='));
        },
      );

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, p: 1);
        expect(s.toFilterString(), contains('p='));
        expect(s.toFilterString(), contains('p=1'));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, poles: 1);
        expect(s.toFilterString(), contains('poles='));
        expect(s.toFilterString(), contains('poles=1'));
      });

      test(
        'param `precision` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(
            enabled: true,
            precision: TreblePrecision.s16,
          );
          expect(s.toFilterString(), contains('precision='));
          expect(s.toFilterString(), contains('precision=s16'));
        },
      );

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, r: TreblePrecision.s16);
        expect(s.toFilterString(), contains('r='));
        expect(s.toFilterString(), contains('r=s16'));
      });

      test('param `t` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, t: TrebleWidthType.h);
        expect(s.toFilterString(), contains('t='));
        expect(s.toFilterString(), contains('t=h'));
      });

      test(
        'param `transform` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(
            enabled: true,
            transform: TrebleTransformType.dii,
          );
          expect(s.toFilterString(), contains('transform='));
          expect(s.toFilterString(), contains('transform=dii'));
        },
      );

      test('param `w` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, w: 99999.0);
        expect(s.toFilterString(), contains('w='));
        expect(s.toFilterString(), contains('w=99999.000'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, width: 99999.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=99999.000'));
      });

      test(
        'param `width_type` lands in wire when set to a non-default value',
        () {
          final s = const TrebleSettings(
            enabled: true,
            width_type: TrebleWidthType.h,
          );
          expect(s.toFilterString(), contains('width_type='));
          expect(s.toFilterString(), contains('width_type=h'));
        },
      );

      test('param `b` const `bMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, b: TrebleSettings.bMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, b: TrebleSettings.bMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `b` const `bDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, b: TrebleSettings.bDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `blocksize` const `blocksizeMin` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            blocksize: TrebleSettings.blocksizeMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeMax` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            blocksize: TrebleSettings.blocksizeMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `blocksize` const `blocksizeDefault` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            blocksize: TrebleSettings.blocksizeDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, f: TrebleSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, f: TrebleSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, f: TrebleSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `frequency` const `frequencyMin` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            frequency: TrebleSettings.frequencyMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyMax` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            frequency: TrebleSettings.frequencyMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `frequency` const `frequencyDefault` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            frequency: TrebleSettings.frequencyDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `g` const `gMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, g: TrebleSettings.gMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, g: TrebleSettings.gMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `g` const `gDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, g: TrebleSettings.gDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, gain: TrebleSettings.gainMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `gain` const `gainMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, gain: TrebleSettings.gainMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `gain` const `gainDefault` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            gain: TrebleSettings.gainDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `m` const `mMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, m: TrebleSettings.mMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, m: TrebleSettings.mMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `m` const `mDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, m: TrebleSettings.mDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, mix: TrebleSettings.mixMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, mix: TrebleSettings.mixMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `mix` const `mixDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, mix: TrebleSettings.mixDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, p: TrebleSettings.pMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, p: TrebleSettings.pMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `p` const `pDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, p: TrebleSettings.pDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, poles: TrebleSettings.polesMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `poles` const `polesMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, poles: TrebleSettings.polesMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `poles` const `polesDefault` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            poles: TrebleSettings.polesDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test('param `w` const `wMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, w: TrebleSettings.wMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, w: TrebleSettings.wMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `w` const `wDefault` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, w: TrebleSettings.wDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMin` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, width: TrebleSettings.widthMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `width` const `widthMax` is accepted by toFilterString', () {
        final s = TrebleSettings(enabled: true, width: TrebleSettings.widthMax);
        expect(s.toFilterString, returnsNormally);
      });

      test(
        'param `width` const `widthDefault` is accepted by toFilterString',
        () {
          final s = TrebleSettings(
            enabled: true,
            width: TrebleSettings.widthDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );
    });
    group('TremoloSettings (tremolo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(tremolo: TremoloSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(tremolo: TremoloSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_tremolo:lavfi-tremolo');
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const TremoloSettings(enabled: true, d: 1.0);
        expect(s.toFilterString(), contains('d='));
        expect(s.toFilterString(), contains('d=1.000'));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TremoloSettings(enabled: true, f: 20000.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=20000.000'));
      });

      test('param `d` const `dMin` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, d: TremoloSettings.dMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dMax` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, d: TremoloSettings.dMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dDefault` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, d: TremoloSettings.dDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, f: TremoloSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, f: TremoloSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = TremoloSettings(enabled: true, f: TremoloSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('VibratoSettings (vibrato)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(vibrato: VibratoSettings(enabled: false));
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(vibrato: VibratoSettings(enabled: true));
        expect(fx.toAfChain(), '@aek_vibrato:lavfi-vibrato');
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const VibratoSettings(enabled: true, d: 1.0);
        expect(s.toFilterString(), contains('d='));
        expect(s.toFilterString(), contains('d=1.000'));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const VibratoSettings(enabled: true, f: 20000.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=20000.000'));
      });

      test('param `d` const `dMin` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, d: VibratoSettings.dMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dMax` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, d: VibratoSettings.dMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `d` const `dDefault` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, d: VibratoSettings.dDefault);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMin` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, f: VibratoSettings.fMin);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fMax` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, f: VibratoSettings.fMax);
        expect(s.toFilterString, returnsNormally);
      });

      test('param `f` const `fDefault` is accepted by toFilterString', () {
        final s = VibratoSettings(enabled: true, f: VibratoSettings.fDefault);
        expect(s.toFilterString, returnsNormally);
      });
    });
    group('VirtualbassSettings (virtualbass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(
          virtualbass: VirtualbassSettings(enabled: false),
        );
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
          virtualbass: VirtualbassSettings(enabled: true),
        );
        expect(fx.toAfChain(), '@aek_virtualbass:lavfi-virtualbass');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const VirtualbassSettings(enabled: true, cutoff: 500.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=500.000'));
      });

      test(
        'param `strength` lands in wire when set to a non-default value',
        () {
          final s = const VirtualbassSettings(enabled: true, strength: 0.5);
          expect(s.toFilterString(), contains('strength='));
          expect(s.toFilterString(), contains('strength=0.500'));
        },
      );

      test(
        'param `cutoff` const `cutoffMin` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            cutoff: VirtualbassSettings.cutoffMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffMax` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            cutoff: VirtualbassSettings.cutoffMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `cutoff` const `cutoffDefault` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            cutoff: VirtualbassSettings.cutoffDefault,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMin` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            strength: VirtualbassSettings.strengthMin,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthMax` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            strength: VirtualbassSettings.strengthMax,
          );
          expect(s.toFilterString, returnsNormally);
        },
      );

      test(
        'param `strength` const `strengthDefault` is accepted by toFilterString',
        () {
          final s = VirtualbassSettings(
            enabled: true,
            strength: VirtualbassSettings.strengthDefault,
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
          StereotoolsMode.lr_to_lr,
        );
        expect(StereotoolsMode.fromMpv(null), StereotoolsMode.lr_to_lr);
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
