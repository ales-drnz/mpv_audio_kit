// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do NOT edit by hand.
// Source of truth: ffmpeg libavfilter `AVOption[]` arrays via
// `scripts/lavfi_codegen/schema.json`. Regenerate with
// `scripts/lavfi_codegen/generate_tests.py`.
//
// Schema-driven coverage of `AudioEffects.toAfChain()` and the
// per-filter `toFilterString()` wire output: every parameter of
// every libavfilter audio filter shipped with this build has at
// least one test pinning the wire shape, and every typed enum
// has its `mpvValue` / `fromMpv` round-trip checked exhaustively.
// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, unused_local_variable

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('Per-filter wire coverage', () {
    group('AbenchSettings (abench)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(abench: AbenchSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(abench: AbenchSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-abench');
      });
    });
    group('AcompressorSettings (acompressor)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acompressor: AcompressorSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(acompressor: AcompressorSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-acompressor');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, attack: 2000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test('param `detection` lands in wire when set to a non-default value',
          () {
        final s = const AcompressorSettings(
            enabled: true, detection: AcompressorDetection.peak);
        expect(s.toFilterString(), contains('detection='));
        expect(s.toFilterString(), contains('detection=peak'));
      });

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AcompressorSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_sc` lands in wire when set to a non-default value',
          () {
        final s = const AcompressorSettings(enabled: true, level_sc: 64.0);
        expect(s.toFilterString(), contains('level_sc='));
        expect(s.toFilterString(), contains('level_sc=64.000'));
      });

      test('param `link` lands in wire when set to a non-default value', () {
        final s = const AcompressorSettings(
            enabled: true, link: AcompressorLink.maximum);
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
            enabled: true, mode: AcompressorMode.upward);
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

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const AcompressorSettings(enabled: true, threshold: 1.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=1.000'));
      });
    });
    group('AcontrastSettings (acontrast)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acontrast: AcontrastSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acontrast: AcontrastSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-acontrast');
      });

      test('param `contrast` lands in wire when set to a non-default value',
          () {
        final s = const AcontrastSettings(enabled: true, contrast: 100.0);
        expect(s.toFilterString(), contains('contrast='));
        expect(s.toFilterString(), contains('contrast=100.000'));
      });
    });
    group('AcopySettings (acopy)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acopy: AcopySettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acopy: AcopySettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-acopy');
      });
    });
    group('AcrusherSettings (acrusher)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acrusher: AcrusherSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acrusher: AcrusherSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-acrusher');
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

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AcrusherSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const AcrusherSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `lfo` lands in wire when set to a non-default value', () {
        final s = const AcrusherSettings(enabled: true, lfo: true);
        expect(s.toFilterString(), contains('lfo='));
      });

      test('param `lforange` lands in wire when set to a non-default value',
          () {
        final s = const AcrusherSettings(enabled: true, lforange: 250.0);
        expect(s.toFilterString(), contains('lforange='));
        expect(s.toFilterString(), contains('lforange=250.000'));
      });

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
    });
    group('AcueSettings (acue)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(acue: AcueSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(acue: AcueSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-acue');
      });

      test('param `buffer` lands in wire when set to a non-default value', () {
        final s = const AcueSettings(
            enabled: true, buffer: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('buffer='));
      });

      test('param `preroll` lands in wire when set to a non-default value', () {
        final s = const AcueSettings(
            enabled: true, preroll: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('preroll='));
      });
    });
    group('AdeclickSettings (adeclick)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adeclick: AdeclickSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adeclick: AdeclickSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adeclick');
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

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const AdeclickSettings(enabled: true, threshold: 100.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=100.000'));
      });

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
    });
    group('AdeclipSettings (adeclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adeclip: AdeclipSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adeclip: AdeclipSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adeclip');
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

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const AdeclipSettings(enabled: true, threshold: 100.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=100.000'));
      });

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
    });
    group('AdecorrelateSettings (adecorrelate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adecorrelate: AdecorrelateSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(adecorrelate: AdecorrelateSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adecorrelate');
      });

      test('param `stages` lands in wire when set to a non-default value', () {
        final s = const AdecorrelateSettings(enabled: true, stages: 1);
        expect(s.toFilterString(), contains('stages='));
        expect(s.toFilterString(), contains('stages=1'));
      });
    });
    group('AdelaySettings (adelay)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adelay: AdelaySettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adelay: AdelaySettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adelay');
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
        const fx = AudioEffects(adenorm: AdenormSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adenorm: AdenormSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adenorm');
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
    });
    group('AderivativeSettings (aderivative)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aderivative: AderivativeSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(aderivative: AderivativeSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aderivative');
      });
    });
    group('AdrcSettings (adrc)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adrc: AdrcSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(adrc: AdrcSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adrc');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AdrcSettings(enabled: true, attack: 1000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=1000.000'));
      });

      test('param `channels` lands in wire when set to a non-default value',
          () {
        final s = const AdrcSettings(enabled: true, channels: 'wire_test_alt');
        expect(s.toFilterString(), contains('channels='));
      });

      test('param `release` lands in wire when set to a non-default value', () {
        final s = const AdrcSettings(enabled: true, release: 2000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test('param `transfer` lands in wire when set to a non-default value',
          () {
        final s = const AdrcSettings(enabled: true, transfer: 'wire_test_alt');
        expect(s.toFilterString(), contains('transfer='));
      });
    });
    group('AdynamicequalizerSettings (adynamicequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adynamicequalizer: AdynamicequalizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
            adynamicequalizer: AdynamicequalizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adynamicequalizer');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s =
            const AdynamicequalizerSettings(enabled: true, attack: 2000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=2000.000'));
      });

      test('param `auto` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
            enabled: true, auto: AdynamicequalizerAuto.off);
        expect(s.toFilterString(), contains('auto='));
        expect(s.toFilterString(), contains('auto=off'));
      });

      test('param `dfrequency` lands in wire when set to a non-default value',
          () {
        final s = const AdynamicequalizerSettings(
            enabled: true, dfrequency: 1000000.0);
        expect(s.toFilterString(), contains('dfrequency='));
        expect(s.toFilterString(), contains('dfrequency=1000000.000'));
      });

      test('param `dftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
            enabled: true, dftype: AdynamicequalizerDftype.lowpass);
        expect(s.toFilterString(), contains('dftype='));
        expect(s.toFilterString(), contains('dftype=lowpass'));
      });

      test('param `dqfactor` lands in wire when set to a non-default value',
          () {
        final s =
            const AdynamicequalizerSettings(enabled: true, dqfactor: 1000.0);
        expect(s.toFilterString(), contains('dqfactor='));
        expect(s.toFilterString(), contains('dqfactor=1000.000'));
      });

      test('param `makeup` lands in wire when set to a non-default value', () {
        final s =
            const AdynamicequalizerSettings(enabled: true, makeup: 1000.0);
        expect(s.toFilterString(), contains('makeup='));
        expect(s.toFilterString(), contains('makeup=1000.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
            enabled: true, mode: AdynamicequalizerMode.cutbelow);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=cutbelow'));
      });

      test('param `precision` lands in wire when set to a non-default value',
          () {
        final s = const AdynamicequalizerSettings(
            enabled: true, precision: AdynamicequalizerPrecision.float);
        expect(s.toFilterString(), contains('precision='));
        expect(s.toFilterString(), contains('precision=float'));
      });

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
        final s =
            const AdynamicequalizerSettings(enabled: true, release: 2000.0);
        expect(s.toFilterString(), contains('release='));
        expect(s.toFilterString(), contains('release=2000.000'));
      });

      test('param `tfrequency` lands in wire when set to a non-default value',
          () {
        final s = const AdynamicequalizerSettings(
            enabled: true, tfrequency: 1000000.0);
        expect(s.toFilterString(), contains('tfrequency='));
        expect(s.toFilterString(), contains('tfrequency=1000000.000'));
      });

      test('param `tftype` lands in wire when set to a non-default value', () {
        final s = const AdynamicequalizerSettings(
            enabled: true, tftype: AdynamicequalizerTftype.lowshelf);
        expect(s.toFilterString(), contains('tftype='));
        expect(s.toFilterString(), contains('tftype=lowshelf'));
      });

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s =
            const AdynamicequalizerSettings(enabled: true, threshold: 100.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=100.000'));
      });

      test('param `tqfactor` lands in wire when set to a non-default value',
          () {
        final s =
            const AdynamicequalizerSettings(enabled: true, tqfactor: 1000.0);
        expect(s.toFilterString(), contains('tqfactor='));
        expect(s.toFilterString(), contains('tqfactor=1000.000'));
      });
    });
    group('AdynamicsmoothSettings (adynamicsmooth)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(adynamicsmooth: AdynamicsmoothSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(adynamicsmooth: AdynamicsmoothSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-adynamicsmooth');
      });

      test('param `basefreq` lands in wire when set to a non-default value',
          () {
        final s =
            const AdynamicsmoothSettings(enabled: true, basefreq: 1000000.0);
        expect(s.toFilterString(), contains('basefreq='));
        expect(s.toFilterString(), contains('basefreq=1000000.000'));
      });

      test('param `sensitivity` lands in wire when set to a non-default value',
          () {
        final s =
            const AdynamicsmoothSettings(enabled: true, sensitivity: 1000000.0);
        expect(s.toFilterString(), contains('sensitivity='));
        expect(s.toFilterString(), contains('sensitivity=1000000.000'));
      });
    });
    group('AechoSettings (aecho)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aecho: AechoSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aecho: AechoSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aecho');
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

      test('param `out_gain` lands in wire when set to a non-default value',
          () {
        final s = const AechoSettings(enabled: true, out_gain: 1.0);
        expect(s.toFilterString(), contains('out_gain='));
        expect(s.toFilterString(), contains('out_gain=1.000'));
      });
    });
    group('AemphasisSettings (aemphasis)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aemphasis: AemphasisSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aemphasis: AemphasisSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aemphasis');
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AemphasisSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const AemphasisSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const AemphasisSettings(
            enabled: true, mode: AemphasisMode.production);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=production'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s =
            const AemphasisSettings(enabled: true, type: AemphasisType.col);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=col'));
      });
    });
    group('AevalSettings (aeval)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aeval: AevalSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aeval: AevalSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aeval');
      });
    });
    group('AexciterSettings (aexciter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aexciter: AexciterSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aexciter: AexciterSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aexciter');
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

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AexciterSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const AexciterSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `listen` lands in wire when set to a non-default value', () {
        final s = const AexciterSettings(enabled: true, listen: true);
        expect(s.toFilterString(), contains('listen='));
      });
    });
    group('AfadeSettings (afade)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afade: AfadeSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afade: AfadeSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-afade');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, c: AfadeCurve.tri);
        expect(s.toFilterString(), contains('c='));
        expect(s.toFilterString(), contains('c=tri'));
      });

      test('param `curve` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, curve: AfadeCurve.tri);
        expect(s.toFilterString(), contains('curve='));
        expect(s.toFilterString(), contains('curve=tri'));
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(
            enabled: true, d: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('d='));
      });

      test('param `duration` lands in wire when set to a non-default value',
          () {
        final s = const AfadeSettings(
            enabled: true, duration: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('duration='));
      });

      test('param `silence` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(enabled: true, silence: 1.0);
        expect(s.toFilterString(), contains('silence='));
        expect(s.toFilterString(), contains('silence=1.000'));
      });

      test('param `st` lands in wire when set to a non-default value', () {
        final s = const AfadeSettings(
            enabled: true, st: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('st='));
      });

      test('param `start_time` lands in wire when set to a non-default value',
          () {
        final s = const AfadeSettings(
            enabled: true, start_time: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('start_time='));
      });

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
    });
    group('AfftdnSettings (afftdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afftdn: AfftdnSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afftdn: AfftdnSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-afftdn');
      });

      test('param `ad` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, ad: 1.0);
        expect(s.toFilterString(), contains('ad='));
        expect(s.toFilterString(), contains('ad=1.000'));
      });

      test('param `adaptivity` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, adaptivity: 1.0);
        expect(s.toFilterString(), contains('adaptivity='));
        expect(s.toFilterString(), contains('adaptivity=1.000'));
      });

      test(
          'param `band_multiplier` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, band_multiplier: 5.0);
        expect(s.toFilterString(), contains('band_multiplier='));
        expect(s.toFilterString(), contains('band_multiplier=5.000'));
      });

      test('param `band_noise` lands in wire when set to a non-default value',
          () {
        final s =
            const AfftdnSettings(enabled: true, band_noise: 'wire_test_alt');
        expect(s.toFilterString(), contains('band_noise='));
      });

      test('param `bm` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, bm: 5.0);
        expect(s.toFilterString(), contains('bm='));
        expect(s.toFilterString(), contains('bm=5.000'));
      });

      test('param `bn` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, bn: 'wire_test_alt');
        expect(s.toFilterString(), contains('bn='));
      });

      test('param `floor_offset` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, floor_offset: 2.0);
        expect(s.toFilterString(), contains('floor_offset='));
        expect(s.toFilterString(), contains('floor_offset=2.000'));
      });

      test('param `fo` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, fo: 2.0);
        expect(s.toFilterString(), contains('fo='));
        expect(s.toFilterString(), contains('fo=2.000'));
      });

      test('param `gain_smooth` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, gain_smooth: 50);
        expect(s.toFilterString(), contains('gain_smooth='));
        expect(s.toFilterString(), contains('gain_smooth=50'));
      });

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
        final s = const AfftdnSettings(enabled: true, nl: AfftdnLink.min);
        expect(s.toFilterString(), contains('nl='));
        expect(s.toFilterString(), contains('nl=min'));
      });

      test('param `noise_floor` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, noise_floor: -20.0);
        expect(s.toFilterString(), contains('noise_floor='));
        expect(s.toFilterString(), contains('noise_floor=-20.000'));
      });

      test('param `noise_link` lands in wire when set to a non-default value',
          () {
        final s =
            const AfftdnSettings(enabled: true, noise_link: AfftdnLink.min);
        expect(s.toFilterString(), contains('noise_link='));
        expect(s.toFilterString(), contains('noise_link=min'));
      });

      test(
          'param `noise_reduction` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, noise_reduction: 97.0);
        expect(s.toFilterString(), contains('noise_reduction='));
        expect(s.toFilterString(), contains('noise_reduction=97.000'));
      });

      test('param `noise_type` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, noise_type: AfftdnType.w);
        expect(s.toFilterString(), contains('noise_type='));
        expect(s.toFilterString(), contains('noise_type=w'));
      });

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
        final s = const AfftdnSettings(enabled: true, om: AfftdnMode.i);
        expect(s.toFilterString(), contains('om='));
        expect(s.toFilterString(), contains('om=i'));
      });

      test('param `output_mode` lands in wire when set to a non-default value',
          () {
        final s =
            const AfftdnSettings(enabled: true, output_mode: AfftdnMode.i);
        expect(s.toFilterString(), contains('output_mode='));
        expect(s.toFilterString(), contains('output_mode=i'));
      });

      test(
          'param `residual_floor` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, residual_floor: -20.0);
        expect(s.toFilterString(), contains('residual_floor='));
        expect(s.toFilterString(), contains('residual_floor=-20.000'));
      });

      test('param `rf` lands in wire when set to a non-default value', () {
        final s = const AfftdnSettings(enabled: true, rf: -20.0);
        expect(s.toFilterString(), contains('rf='));
        expect(s.toFilterString(), contains('rf=-20.000'));
      });

      test('param `sample_noise` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(
            enabled: true, sample_noise: AfftdnSample.start);
        expect(s.toFilterString(), contains('sample_noise='));
        expect(s.toFilterString(), contains('sample_noise=start'));
      });

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

      test('param `track_noise` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, track_noise: true);
        expect(s.toFilterString(), contains('track_noise='));
      });

      test(
          'param `track_residual` lands in wire when set to a non-default value',
          () {
        final s = const AfftdnSettings(enabled: true, track_residual: true);
        expect(s.toFilterString(), contains('track_residual='));
      });
    });
    group('AfftfiltSettings (afftfilt)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afftfilt: AfftfiltSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afftfilt: AfftfiltSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-afftfilt');
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

      test('param `win_size` lands in wire when set to a non-default value',
          () {
        final s = const AfftfiltSettings(enabled: true, win_size: 131072);
        expect(s.toFilterString(), contains('win_size='));
        expect(s.toFilterString(), contains('win_size=131072'));
      });
    });
    group('AformatSettings (aformat)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aformat: AformatSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aformat: AformatSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aformat');
      });
    });
    group('AfreqshiftSettings (afreqshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afreqshift: AfreqshiftSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afreqshift: AfreqshiftSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-afreqshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, order: 1);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=1'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AfreqshiftSettings(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });
    });
    group('AfwtdnSettings (afwtdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(afwtdn: AfwtdnSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(afwtdn: AfwtdnSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-afwtdn');
      });

      test('param `adaptive` lands in wire when set to a non-default value',
          () {
        final s = const AfwtdnSettings(enabled: true, adaptive: true);
        expect(s.toFilterString(), contains('adaptive='));
      });

      test('param `levels` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, levels: 1);
        expect(s.toFilterString(), contains('levels='));
        expect(s.toFilterString(), contains('levels=1'));
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

      test('param `softness` lands in wire when set to a non-default value',
          () {
        final s = const AfwtdnSettings(enabled: true, softness: 10.0);
        expect(s.toFilterString(), contains('softness='));
        expect(s.toFilterString(), contains('softness=10.000'));
      });

      test('param `wavet` lands in wire when set to a non-default value', () {
        final s = const AfwtdnSettings(enabled: true, wavet: AfwtdnWavet.sym4);
        expect(s.toFilterString(), contains('wavet='));
        expect(s.toFilterString(), contains('wavet=sym4'));
      });
    });
    group('AgateSettings (agate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(agate: AgateSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(agate: AgateSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-agate');
      });

      test('param `attack` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, attack: 9000.0);
        expect(s.toFilterString(), contains('attack='));
        expect(s.toFilterString(), contains('attack=9000.000'));
      });

      test('param `detection` lands in wire when set to a non-default value',
          () {
        final s =
            const AgateSettings(enabled: true, detection: AgateDetection.peak);
        expect(s.toFilterString(), contains('detection='));
        expect(s.toFilterString(), contains('detection=peak'));
      });

      test('param `knee` lands in wire when set to a non-default value', () {
        final s = const AgateSettings(enabled: true, knee: 8.0);
        expect(s.toFilterString(), contains('knee='));
        expect(s.toFilterString(), contains('knee=8.000'));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AgateSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_sc` lands in wire when set to a non-default value',
          () {
        final s = const AgateSettings(enabled: true, level_sc: 64.0);
        expect(s.toFilterString(), contains('level_sc='));
        expect(s.toFilterString(), contains('level_sc=64.000'));
      });

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

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const AgateSettings(enabled: true, threshold: 1.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=1.000'));
      });
    });
    group('AiirSettings (aiir)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aiir: AiirSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aiir: AiirSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aiir');
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

      test('param `normalize` lands in wire when set to a non-default value',
          () {
        final s = const AiirSettings(enabled: true, normalize: false);
        expect(s.toFilterString(), contains('normalize='));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, p: 'wire_test_alt');
        expect(s.toFilterString(), contains('p='));
      });

      test('param `poles` lands in wire when set to a non-default value', () {
        final s = const AiirSettings(enabled: true, poles: 'wire_test_alt');
        expect(s.toFilterString(), contains('poles='));
      });

      test('param `precision` lands in wire when set to a non-default value',
          () {
        final s =
            const AiirSettings(enabled: true, precision: AiirPrecision.flt);
        expect(s.toFilterString(), contains('precision='));
        expect(s.toFilterString(), contains('precision=flt'));
      });

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

      test('param `response` lands in wire when set to a non-default value',
          () {
        final s = const AiirSettings(enabled: true, response: true);
        expect(s.toFilterString(), contains('response='));
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
    });
    group('AintegralSettings (aintegral)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aintegral: AintegralSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aintegral: AintegralSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aintegral');
      });
    });
    group('AlatencySettings (alatency)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(alatency: AlatencySettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(alatency: AlatencySettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-alatency');
      });
    });
    group('AlimiterSettings (alimiter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(alimiter: AlimiterSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(alimiter: AlimiterSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-alimiter');
      });

      test('param `asc` lands in wire when set to a non-default value', () {
        final s = const AlimiterSettings(enabled: true, asc: true);
        expect(s.toFilterString(), contains('asc='));
      });

      test('param `asc_level` lands in wire when set to a non-default value',
          () {
        final s = const AlimiterSettings(enabled: true, asc_level: 1.0);
        expect(s.toFilterString(), contains('asc_level='));
        expect(s.toFilterString(), contains('asc_level=1.000'));
      });

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

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const AlimiterSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const AlimiterSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

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
    });
    group('AllpassSettings (allpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(allpass: AllpassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(allpass: AllpassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-allpass');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const AllpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const AllpassSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('AloopSettings (aloop)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aloop: AloopSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aloop: AloopSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aloop');
      });

      test('param `loop` lands in wire when set to a non-default value', () {
        final s = const AloopSettings(enabled: true, loop: -1);
        expect(s.toFilterString(), contains('loop='));
        expect(s.toFilterString(), contains('loop=-1'));
      });

      test('param `time` lands in wire when set to a non-default value', () {
        final s = const AloopSettings(
            enabled: true, time: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('time='));
      });
    });
    group('AmetadataSettings (ametadata)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(ametadata: AmetadataSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(ametadata: AmetadataSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-ametadata');
      });
    });
    group('AnequalizerSettings (anequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(anequalizer: AnequalizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(anequalizer: AnequalizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-anequalizer');
      });

      test('param `colors` lands in wire when set to a non-default value', () {
        final s =
            const AnequalizerSettings(enabled: true, colors: 'wire_test_alt');
        expect(s.toFilterString(), contains('colors='));
      });

      test('param `curves` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(enabled: true, curves: true);
        expect(s.toFilterString(), contains('curves='));
      });

      test('param `fscale` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(
            enabled: true, fscale: AnequalizerFscale.lin);
        expect(s.toFilterString(), contains('fscale='));
        expect(s.toFilterString(), contains('fscale=lin'));
      });

      test('param `mgain` lands in wire when set to a non-default value', () {
        final s = const AnequalizerSettings(enabled: true, mgain: 900.0);
        expect(s.toFilterString(), contains('mgain='));
        expect(s.toFilterString(), contains('mgain=900.000'));
      });

      test('param `params` lands in wire when set to a non-default value', () {
        final s =
            const AnequalizerSettings(enabled: true, params: 'wire_test_alt');
        expect(s.toFilterString(), contains('params='));
      });
    });
    group('AnlmdnSettings (anlmdn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(anlmdn: AnlmdnSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(anlmdn: AnlmdnSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-anlmdn');
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, m: 1000.0);
        expect(s.toFilterString(), contains('m='));
        expect(s.toFilterString(), contains('m=1000.000'));
      });

      test('param `o` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, o: AnlmdnMode.o);
        expect(s.toFilterString(), contains('o='));
        expect(s.toFilterString(), contains('o=o'));
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(enabled: true, output: AnlmdnMode.o);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=o'));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
            enabled: true, p: const Duration(microseconds: 1002000));
        expect(s.toFilterString(), contains('p='));
      });

      test('param `patch` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
            enabled: true, patch: const Duration(microseconds: 1002000));
        expect(s.toFilterString(), contains('patch='));
      });

      test('param `r` lands in wire when set to a non-default value', () {
        final s = const AnlmdnSettings(
            enabled: true, r: const Duration(microseconds: 1006000));
        expect(s.toFilterString(), contains('r='));
      });

      test('param `research` lands in wire when set to a non-default value',
          () {
        final s = const AnlmdnSettings(
            enabled: true, research: const Duration(microseconds: 1006000));
        expect(s.toFilterString(), contains('research='));
      });

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

      test('param `strength` lands in wire when set to a non-default value',
          () {
        final s = const AnlmdnSettings(enabled: true, strength: 10000.0);
        expect(s.toFilterString(), contains('strength='));
        expect(s.toFilterString(), contains('strength=10000.000'));
      });
    });
    group('AnullSettings (anull)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(anull: AnullSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(anull: AnullSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-anull');
      });
    });
    group('ApadSettings (apad)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apad: ApadSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apad: ApadSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-apad');
      });

      test('param `packet_size` lands in wire when set to a non-default value',
          () {
        final s = const ApadSettings(enabled: true, packet_size: 0);
        expect(s.toFilterString(), contains('packet_size='));
        expect(s.toFilterString(), contains('packet_size=0'));
      });

      test('param `pad_dur` lands in wire when set to a non-default value', () {
        final s = const ApadSettings(
            enabled: true, pad_dur: const Duration(microseconds: 999999));
        expect(s.toFilterString(), contains('pad_dur='));
      });

      test('param `whole_dur` lands in wire when set to a non-default value',
          () {
        final s = const ApadSettings(
            enabled: true, whole_dur: const Duration(microseconds: 999999));
        expect(s.toFilterString(), contains('whole_dur='));
      });
    });
    group('ApermsSettings (aperms)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aperms: ApermsSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aperms: ApermsSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aperms');
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const ApermsSettings(enabled: true, mode: ApermsMode.ro);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=ro'));
      });
    });
    group('AphaserSettings (aphaser)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aphaser: AphaserSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aphaser: AphaserSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aphaser');
      });

      test('param `decay` lands in wire when set to a non-default value', () {
        final s = const AphaserSettings(enabled: true, decay: 0.0);
        expect(s.toFilterString(), contains('decay='));
        expect(s.toFilterString(), contains('decay=0.000'));
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

      test('param `out_gain` lands in wire when set to a non-default value',
          () {
        final s = const AphaserSettings(enabled: true, out_gain: 1000000000.0);
        expect(s.toFilterString(), contains('out_gain='));
        expect(s.toFilterString(), contains('out_gain=1000000000.000'));
      });

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
    });
    group('AphaseshiftSettings (aphaseshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aphaseshift: AphaseshiftSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(aphaseshift: AphaseshiftSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aphaseshift');
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, level: 0.0);
        expect(s.toFilterString(), contains('level='));
        expect(s.toFilterString(), contains('level=0.000'));
      });

      test('param `order` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, order: 1);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=1'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const AphaseshiftSettings(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });
    });
    group('ApsyclipSettings (apsyclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apsyclip: ApsyclipSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apsyclip: ApsyclipSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-apsyclip');
      });

      test('param `adaptive` lands in wire when set to a non-default value',
          () {
        final s = const ApsyclipSettings(enabled: true, adaptive: 1.0);
        expect(s.toFilterString(), contains('adaptive='));
        expect(s.toFilterString(), contains('adaptive=1.000'));
      });

      test('param `clip` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, clip: 2.0);
        expect(s.toFilterString(), contains('clip='));
        expect(s.toFilterString(), contains('clip=2.000'));
      });

      test('param `diff` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, diff: true);
        expect(s.toFilterString(), contains('diff='));
      });

      test('param `iterations` lands in wire when set to a non-default value',
          () {
        final s = const ApsyclipSettings(enabled: true, iterations: 20);
        expect(s.toFilterString(), contains('iterations='));
        expect(s.toFilterString(), contains('iterations=20'));
      });

      test('param `level` lands in wire when set to a non-default value', () {
        final s = const ApsyclipSettings(enabled: true, level: true);
        expect(s.toFilterString(), contains('level='));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const ApsyclipSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const ApsyclipSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });
    });
    group('ApulsatorSettings (apulsator)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(apulsator: ApulsatorSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(apulsator: ApulsatorSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-apulsator');
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

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const ApulsatorSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const ApulsatorSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(
            enabled: true, mode: ApulsatorMode.triangle);
        expect(s.toFilterString(), contains('mode='));
        expect(s.toFilterString(), contains('mode=triangle'));
      });

      test('param `ms` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, ms: 2000);
        expect(s.toFilterString(), contains('ms='));
        expect(s.toFilterString(), contains('ms=2000'));
      });

      test('param `offset_l` lands in wire when set to a non-default value',
          () {
        final s = const ApulsatorSettings(enabled: true, offset_l: 1.0);
        expect(s.toFilterString(), contains('offset_l='));
        expect(s.toFilterString(), contains('offset_l=1.000'));
      });

      test('param `offset_r` lands in wire when set to a non-default value',
          () {
        final s = const ApulsatorSettings(enabled: true, offset_r: 1.0);
        expect(s.toFilterString(), contains('offset_r='));
        expect(s.toFilterString(), contains('offset_r=1.000'));
      });

      test('param `timing` lands in wire when set to a non-default value', () {
        final s =
            const ApulsatorSettings(enabled: true, timing: ApulsatorTiming.ms);
        expect(s.toFilterString(), contains('timing='));
        expect(s.toFilterString(), contains('timing=ms'));
      });

      test('param `width` lands in wire when set to a non-default value', () {
        final s = const ApulsatorSettings(enabled: true, width: 2.0);
        expect(s.toFilterString(), contains('width='));
        expect(s.toFilterString(), contains('width=2.000'));
      });
    });
    group('ArealtimeSettings (arealtime)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(arealtime: ArealtimeSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(arealtime: ArealtimeSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-arealtime');
      });

      test('param `limit` lands in wire when set to a non-default value', () {
        final s = const ArealtimeSettings(
            enabled: true, limit: const Duration(microseconds: 3000000));
        expect(s.toFilterString(), contains('limit='));
      });

      test('param `speed` lands in wire when set to a non-default value', () {
        final s = const ArealtimeSettings(enabled: true, speed: 2.0);
        expect(s.toFilterString(), contains('speed='));
        expect(s.toFilterString(), contains('speed=2.000'));
      });
    });
    group('AresampleSettings (aresample)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aresample: AresampleSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aresample: AresampleSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aresample');
      });

      test('param `sample_rate` lands in wire when set to a non-default value',
          () {
        final s = const AresampleSettings(enabled: true, sample_rate: 1);
        expect(s.toFilterString(), contains('sample_rate='));
        expect(s.toFilterString(), contains('sample_rate=1'));
      });
    });
    group('AreverseSettings (areverse)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(areverse: AreverseSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(areverse: AreverseSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-areverse');
      });
    });
    group('ArnndnSettings (arnndn)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(arnndn: ArnndnSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(arnndn: ArnndnSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-arnndn');
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(enabled: true, m: 'wire_test_alt');
        expect(s.toFilterString(), contains('m='));
      });

      test('param `mix` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(enabled: true, mix: -1.0);
        expect(s.toFilterString(), contains('mix='));
        expect(s.toFilterString(), contains('mix=-1.000'));
      });

      test('param `model` lands in wire when set to a non-default value', () {
        final s = const ArnndnSettings(enabled: true, model: 'wire_test_alt');
        expect(s.toFilterString(), contains('model='));
      });
    });
    group('AsegmentSettings (asegment)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asegment: AsegmentSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asegment: AsegmentSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asegment');
      });

      test('param `samples` lands in wire when set to a non-default value', () {
        final s =
            const AsegmentSettings(enabled: true, samples: 'wire_test_alt');
        expect(s.toFilterString(), contains('samples='));
      });
    });
    group('AselectSettings (aselect)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aselect: AselectSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(aselect: AselectSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aselect');
      });
    });
    group('AsendcmdSettings (asendcmd)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asendcmd: AsendcmdSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asendcmd: AsendcmdSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asendcmd');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const AsendcmdSettings(enabled: true, c: 'wire_test_alt');
        expect(s.toFilterString(), contains('c='));
      });

      test('param `commands` lands in wire when set to a non-default value',
          () {
        final s =
            const AsendcmdSettings(enabled: true, commands: 'wire_test_alt');
        expect(s.toFilterString(), contains('commands='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const AsendcmdSettings(enabled: true, f: 'wire_test_alt');
        expect(s.toFilterString(), contains('f='));
      });

      test('param `filename` lands in wire when set to a non-default value',
          () {
        final s =
            const AsendcmdSettings(enabled: true, filename: 'wire_test_alt');
        expect(s.toFilterString(), contains('filename='));
      });
    });
    group('AsetnsamplesSettings (asetnsamples)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asetnsamples: AsetnsamplesSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(asetnsamples: AsetnsamplesSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asetnsamples');
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const AsetnsamplesSettings(enabled: true, n: 1);
        expect(s.toFilterString(), contains('n='));
        expect(s.toFilterString(), contains('n=1'));
      });

      test(
          'param `nb_out_samples` lands in wire when set to a non-default value',
          () {
        final s = const AsetnsamplesSettings(enabled: true, nb_out_samples: 1);
        expect(s.toFilterString(), contains('nb_out_samples='));
        expect(s.toFilterString(), contains('nb_out_samples=1'));
      });

      test('param `p` lands in wire when set to a non-default value', () {
        final s = const AsetnsamplesSettings(enabled: true, p: false);
        expect(s.toFilterString(), contains('p='));
      });

      test('param `pad` lands in wire when set to a non-default value', () {
        final s = const AsetnsamplesSettings(enabled: true, pad: false);
        expect(s.toFilterString(), contains('pad='));
      });
    });
    group('AsetptsSettings (asetpts)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asetpts: AsetptsSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asetpts: AsetptsSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asetpts');
      });
    });
    group('AsetrateSettings (asetrate)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asetrate: AsetrateSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asetrate: AsetrateSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asetrate');
      });
    });
    group('AsettbSettings (asettb)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asettb: AsettbSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asettb: AsettbSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asettb');
      });
    });
    group('AshowinfoSettings (ashowinfo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(ashowinfo: AshowinfoSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(ashowinfo: AshowinfoSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-ashowinfo');
      });
    });
    group('AsidedataSettings (asidedata)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asidedata: AsidedataSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asidedata: AsidedataSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asidedata');
      });
    });
    group('AsoftclipSettings (asoftclip)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asoftclip: AsoftclipSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asoftclip: AsoftclipSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asoftclip');
      });

      test('param `output` lands in wire when set to a non-default value', () {
        final s = const AsoftclipSettings(enabled: true, output: 16.0);
        expect(s.toFilterString(), contains('output='));
        expect(s.toFilterString(), contains('output=16.000'));
      });

      test('param `oversample` lands in wire when set to a non-default value',
          () {
        final s = const AsoftclipSettings(enabled: true, oversample: 2);
        expect(s.toFilterString(), contains('oversample='));
        expect(s.toFilterString(), contains('oversample=2'));
      });

      test('param `param` lands in wire when set to a non-default value', () {
        final s = const AsoftclipSettings(enabled: true, param: 3.0);
        expect(s.toFilterString(), contains('param='));
        expect(s.toFilterString(), contains('param=3.000'));
      });

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const AsoftclipSettings(enabled: true, threshold: 1e-06);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=0.000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s =
            const AsoftclipSettings(enabled: true, type: AsoftclipTypes.tanh);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=tanh'));
      });
    });
    group('AspectralstatsSettings (aspectralstats)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(aspectralstats: AspectralstatsSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(aspectralstats: AspectralstatsSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-aspectralstats');
      });

      test('param `measure` lands in wire when set to a non-default value', () {
        final s = const AspectralstatsSettings(
            enabled: true, measure: const {AspectralstatsMeasure.none});
        expect(s.toFilterString(), contains('measure='));
      });

      test('param `overlap` lands in wire when set to a non-default value', () {
        final s = const AspectralstatsSettings(enabled: true, overlap: 1.0);
        expect(s.toFilterString(), contains('overlap='));
        expect(s.toFilterString(), contains('overlap=1.000'));
      });

      test('param `win_size` lands in wire when set to a non-default value',
          () {
        final s = const AspectralstatsSettings(enabled: true, win_size: 65536);
        expect(s.toFilterString(), contains('win_size='));
        expect(s.toFilterString(), contains('win_size=65536'));
      });
    });
    group('AstatsSettings (astats)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(astats: AstatsSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(astats: AstatsSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-astats');
      });

      test('param `length` lands in wire when set to a non-default value', () {
        final s = const AstatsSettings(enabled: true, length: 10.0);
        expect(s.toFilterString(), contains('length='));
        expect(s.toFilterString(), contains('length=10.000'));
      });

      test(
          'param `measure_overall` lands in wire when set to a non-default value',
          () {
        final s = const AstatsSettings(
            enabled: true, measure_overall: const {AstatsMeasure.none});
        expect(s.toFilterString(), contains('measure_overall='));
      });

      test(
          'param `measure_perchannel` lands in wire when set to a non-default value',
          () {
        final s = const AstatsSettings(
            enabled: true, measure_perchannel: const {AstatsMeasure.none});
        expect(s.toFilterString(), contains('measure_perchannel='));
      });

      test('param `metadata` lands in wire when set to a non-default value',
          () {
        final s = const AstatsSettings(enabled: true, metadata: true);
        expect(s.toFilterString(), contains('metadata='));
      });

      test('param `reset` lands in wire when set to a non-default value', () {
        final s = const AstatsSettings(enabled: true, reset: 1);
        expect(s.toFilterString(), contains('reset='));
        expect(s.toFilterString(), contains('reset=1'));
      });
    });
    group('AstreamselectSettings (astreamselect)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(astreamselect: AstreamselectSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(astreamselect: AstreamselectSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-astreamselect');
      });

      test('param `inputs` lands in wire when set to a non-default value', () {
        final s = const AstreamselectSettings(enabled: true, inputs: 3);
        expect(s.toFilterString(), contains('inputs='));
        expect(s.toFilterString(), contains('inputs=3'));
      });

      test('param `map` lands in wire when set to a non-default value', () {
        final s =
            const AstreamselectSettings(enabled: true, map: 'wire_test_alt');
        expect(s.toFilterString(), contains('map='));
      });
    });
    group('AsubboostSettings (asubboost)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asubboost: AsubboostSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asubboost: AsubboostSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asubboost');
      });

      test('param `boost` lands in wire when set to a non-default value', () {
        final s = const AsubboostSettings(enabled: true, boost: 12.0);
        expect(s.toFilterString(), contains('boost='));
        expect(s.toFilterString(), contains('boost=12.000'));
      });

      test('param `channels` lands in wire when set to a non-default value',
          () {
        final s =
            const AsubboostSettings(enabled: true, channels: 'wire_test_alt');
        expect(s.toFilterString(), contains('channels='));
      });

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

      test('param `feedback` lands in wire when set to a non-default value',
          () {
        final s = const AsubboostSettings(enabled: true, feedback: 1.0);
        expect(s.toFilterString(), contains('feedback='));
        expect(s.toFilterString(), contains('feedback=1.000'));
      });

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
    });
    group('AsubcutSettings (asubcut)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asubcut: AsubcutSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asubcut: AsubcutSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asubcut');
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
    });
    group('AsupercutSettings (asupercut)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asupercut: AsupercutSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asupercut: AsupercutSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asupercut');
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
    });
    group('AsuperpassSettings (asuperpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asuperpass: AsuperpassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asuperpass: AsuperpassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asuperpass');
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
    });
    group('AsuperstopSettings (asuperstop)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(asuperstop: AsuperstopSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(asuperstop: AsuperstopSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-asuperstop');
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
    });
    group('AtempoSettings (atempo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(atempo: AtempoSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(atempo: AtempoSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-atempo');
      });

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const AtempoSettings(enabled: true, tempo: 2.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=2.000'));
      });
    });
    group('AtiltSettings (atilt)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(atilt: AtiltSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(atilt: AtiltSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-atilt');
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
        final s = const AtiltSettings(enabled: true, order: 2);
        expect(s.toFilterString(), contains('order='));
        expect(s.toFilterString(), contains('order=2'));
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
    });
    group('AtrimSettings (atrim)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(atrim: AtrimSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(atrim: AtrimSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-atrim');
      });
    });
    group('BandpassSettings (bandpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bandpass: BandpassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bandpass: BandpassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-bandpass');
      });

      test('param `csg` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, csg: true);
        expect(s.toFilterString(), contains('csg='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BandpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const BandpassSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });
    });
    group('BandrejectSettings (bandreject)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bandreject: BandrejectSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bandreject: BandrejectSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-bandreject');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BandrejectSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const BandrejectSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });
    });
    group('BassSettings (bass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(bass: BassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(bass: BassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-bass');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const BassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const BassSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('BiquadSettings (biquad)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(biquad: BiquadSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(biquad: BiquadSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-biquad');
      });

      test('param `a0` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a0: 2.0);
        expect(s.toFilterString(), contains('a0='));
        expect(s.toFilterString(), contains('a0=2.000'));
      });

      test('param `a1` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a1: 1.0);
        expect(s.toFilterString(), contains('a1='));
        expect(s.toFilterString(), contains('a1=1.000'));
      });

      test('param `a2` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, a2: 1.0);
        expect(s.toFilterString(), contains('a2='));
        expect(s.toFilterString(), contains('a2=1.000'));
      });

      test('param `b0` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b0: 1.0);
        expect(s.toFilterString(), contains('b0='));
        expect(s.toFilterString(), contains('b0=1.000'));
      });

      test('param `b1` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b1: 1.0);
        expect(s.toFilterString(), contains('b1='));
        expect(s.toFilterString(), contains('b1=1.000'));
      });

      test('param `b2` lands in wire when set to a non-default value', () {
        final s = const BiquadSettings(enabled: true, b2: 1.0);
        expect(s.toFilterString(), contains('b2='));
        expect(s.toFilterString(), contains('b2=1.000'));
      });
    });
    group('ChannelmapSettings (channelmap)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(channelmap: ChannelmapSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(channelmap: ChannelmapSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-channelmap');
      });

      test(
          'param `channel_layout` lands in wire when set to a non-default value',
          () {
        final s = const ChannelmapSettings(
            enabled: true, channel_layout: 'wire_test_alt');
        expect(s.toFilterString(), contains('channel_layout='));
      });

      test('param `map` lands in wire when set to a non-default value', () {
        final s = const ChannelmapSettings(enabled: true, map: 'wire_test_alt');
        expect(s.toFilterString(), contains('map='));
      });
    });
    group('ChorusSettings (chorus)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(chorus: ChorusSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(chorus: ChorusSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-chorus');
      });

      test('param `decays` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(enabled: true, decays: 'wire_test_alt');
        expect(s.toFilterString(), contains('decays='));
      });

      test('param `delays` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(enabled: true, delays: 'wire_test_alt');
        expect(s.toFilterString(), contains('delays='));
      });

      test('param `depths` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(enabled: true, depths: 'wire_test_alt');
        expect(s.toFilterString(), contains('depths='));
      });

      test('param `in_gain` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(enabled: true, in_gain: 1.0);
        expect(s.toFilterString(), contains('in_gain='));
        expect(s.toFilterString(), contains('in_gain=1.000'));
      });

      test('param `out_gain` lands in wire when set to a non-default value',
          () {
        final s = const ChorusSettings(enabled: true, out_gain: 1.0);
        expect(s.toFilterString(), contains('out_gain='));
        expect(s.toFilterString(), contains('out_gain=1.000'));
      });

      test('param `speeds` lands in wire when set to a non-default value', () {
        final s = const ChorusSettings(enabled: true, speeds: 'wire_test_alt');
        expect(s.toFilterString(), contains('speeds='));
      });
    });
    group('CompandSettings (compand)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(compand: CompandSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(compand: CompandSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-compand');
      });

      test('param `attacks` lands in wire when set to a non-default value', () {
        final s =
            const CompandSettings(enabled: true, attacks: 'wire_test_alt');
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

      test('digit-prefix param `soft-knee` lands in wire via params map', () {
        final s =
            const CompandSettings(enabled: true, params: {'soft-knee': 900.0});
        expect(s.toFilterString(), contains('soft-knee='));
        expect(s.toFilterString(), contains('soft-knee=900.000'));
      });
    });
    group('CompensationdelaySettings (compensationdelay)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(compensationdelay: CompensationdelaySettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(
            compensationdelay: CompensationdelaySettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-compensationdelay');
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
    });
    group('CrossfeedSettings (crossfeed)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(crossfeed: CrossfeedSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(crossfeed: CrossfeedSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-crossfeed');
      });

      test('param `block_size` lands in wire when set to a non-default value',
          () {
        final s = const CrossfeedSettings(enabled: true, block_size: 32768);
        expect(s.toFilterString(), contains('block_size='));
        expect(s.toFilterString(), contains('block_size=32768'));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const CrossfeedSettings(enabled: true, level_in: 1.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=1.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const CrossfeedSettings(enabled: true, level_out: 0.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=0.000'));
      });

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

      test('param `strength` lands in wire when set to a non-default value',
          () {
        final s = const CrossfeedSettings(enabled: true, strength: 1.0);
        expect(s.toFilterString(), contains('strength='));
        expect(s.toFilterString(), contains('strength=1.000'));
      });
    });
    group('CrystalizerSettings (crystalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(crystalizer: CrystalizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(crystalizer: CrystalizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-crystalizer');
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
    });
    group('DcshiftSettings (dcshift)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(dcshift: DcshiftSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(dcshift: DcshiftSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-dcshift');
      });

      test('param `limitergain` lands in wire when set to a non-default value',
          () {
        final s = const DcshiftSettings(enabled: true, limitergain: 1.0);
        expect(s.toFilterString(), contains('limitergain='));
        expect(s.toFilterString(), contains('limitergain=1.000'));
      });

      test('param `shift` lands in wire when set to a non-default value', () {
        final s = const DcshiftSettings(enabled: true, shift: 1.0);
        expect(s.toFilterString(), contains('shift='));
        expect(s.toFilterString(), contains('shift=1.000'));
      });
    });
    group('DeesserSettings (deesser)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(deesser: DeesserSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(deesser: DeesserSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-deesser');
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
        final s = const DeesserSettings(enabled: true, s: DeesserMode.o);
        expect(s.toFilterString(), contains('s='));
        expect(s.toFilterString(), contains('s=o'));
      });
    });
    group('DialoguenhanceSettings (dialoguenhance)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(dialoguenhance: DialoguenhanceSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(dialoguenhance: DialoguenhanceSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-dialoguenhance');
      });

      test('param `enhance` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceSettings(enabled: true, enhance: 3.0);
        expect(s.toFilterString(), contains('enhance='));
        expect(s.toFilterString(), contains('enhance=3.000'));
      });

      test('param `original` lands in wire when set to a non-default value',
          () {
        final s = const DialoguenhanceSettings(enabled: true, original: 0.0);
        expect(s.toFilterString(), contains('original='));
        expect(s.toFilterString(), contains('original=0.000'));
      });

      test('param `voice` lands in wire when set to a non-default value', () {
        final s = const DialoguenhanceSettings(enabled: true, voice: 32.0);
        expect(s.toFilterString(), contains('voice='));
        expect(s.toFilterString(), contains('voice=32.000'));
      });
    });
    group('DrmeterSettings (drmeter)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(drmeter: DrmeterSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(drmeter: DrmeterSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-drmeter');
      });

      test('param `length` lands in wire when set to a non-default value', () {
        final s = const DrmeterSettings(enabled: true, length: 10.0);
        expect(s.toFilterString(), contains('length='));
        expect(s.toFilterString(), contains('length=10.000'));
      });
    });
    group('DynaudnormSettings (dynaudnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(dynaudnorm: DynaudnormSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(dynaudnorm: DynaudnormSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-dynaudnorm');
      });

      test('param `altboundary` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, altboundary: true);
        expect(s.toFilterString(), contains('altboundary='));
      });

      test('param `b` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, b: true);
        expect(s.toFilterString(), contains('b='));
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, c: true);
        expect(s.toFilterString(), contains('c='));
      });

      test('param `channels` lands in wire when set to a non-default value',
          () {
        final s =
            const DynaudnormSettings(enabled: true, channels: 'wire_test_alt');
        expect(s.toFilterString(), contains('channels='));
      });

      test('param `compress` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, compress: 30.0);
        expect(s.toFilterString(), contains('compress='));
        expect(s.toFilterString(), contains('compress=30.000'));
      });

      test('param `correctdc` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, correctdc: true);
        expect(s.toFilterString(), contains('correctdc='));
      });

      test('param `coupling` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, coupling: false);
        expect(s.toFilterString(), contains('coupling='));
      });

      test('param `curve` lands in wire when set to a non-default value', () {
        final s =
            const DynaudnormSettings(enabled: true, curve: 'wire_test_alt');
        expect(s.toFilterString(), contains('curve='));
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, f: 8000);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=8000'));
      });

      test('param `framelen` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, framelen: 8000);
        expect(s.toFilterString(), contains('framelen='));
        expect(s.toFilterString(), contains('framelen=8000'));
      });

      test('param `g` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, g: 301);
        expect(s.toFilterString(), contains('g='));
        expect(s.toFilterString(), contains('g=301'));
      });

      test('param `gausssize` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, gausssize: 301);
        expect(s.toFilterString(), contains('gausssize='));
        expect(s.toFilterString(), contains('gausssize=301'));
      });

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

      test('param `targetrms` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, targetrms: 1.0);
        expect(s.toFilterString(), contains('targetrms='));
        expect(s.toFilterString(), contains('targetrms=1.000'));
      });

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const DynaudnormSettings(enabled: true, threshold: 1.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=1.000'));
      });

      test('param `v` lands in wire when set to a non-default value', () {
        final s = const DynaudnormSettings(enabled: true, v: 'wire_test_alt');
        expect(s.toFilterString(), contains('v='));
      });
    });
    group('EarwaxSettings (earwax)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(earwax: EarwaxSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(earwax: EarwaxSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-earwax');
      });
    });
    group('Ebur128Settings (ebur128)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(ebur128: Ebur128Settings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(ebur128: Ebur128Settings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-ebur128');
      });

      test('param `dualmono` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, dualmono: true);
        expect(s.toFilterString(), contains('dualmono='));
      });

      test('param `framelog` lands in wire when set to a non-default value',
          () {
        final s =
            const Ebur128Settings(enabled: true, framelog: Ebur128Level.info);
        expect(s.toFilterString(), contains('framelog='));
        expect(s.toFilterString(), contains('framelog=info'));
      });

      test('param `gauge` lands in wire when set to a non-default value', () {
        final s =
            const Ebur128Settings(enabled: true, gauge: Ebur128Gaugetype.m);
        expect(s.toFilterString(), contains('gauge='));
        expect(s.toFilterString(), contains('gauge=m'));
      });

      test('param `integrated` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, integrated: 1.0);
        expect(s.toFilterString(), contains('integrated='));
        expect(s.toFilterString(), contains('integrated=1.000'));
      });

      test('param `lra_high` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, lra_high: 1.0);
        expect(s.toFilterString(), contains('lra_high='));
        expect(s.toFilterString(), contains('lra_high=1.000'));
      });

      test('param `lra_low` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, lra_low: 1.0);
        expect(s.toFilterString(), contains('lra_low='));
        expect(s.toFilterString(), contains('lra_low=1.000'));
      });

      test('param `metadata` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, metadata: true);
        expect(s.toFilterString(), contains('metadata='));
      });

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
            enabled: true, peak: const {Ebur128Mode.none});
        expect(s.toFilterString(), contains('peak='));
      });

      test('param `range` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, range: 1.0);
        expect(s.toFilterString(), contains('range='));
        expect(s.toFilterString(), contains('range=1.000'));
      });

      test('param `sample_peak` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, sample_peak: 1.0);
        expect(s.toFilterString(), contains('sample_peak='));
        expect(s.toFilterString(), contains('sample_peak=1.000'));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s =
            const Ebur128Settings(enabled: true, scale: Ebur128Scaletype.LUFS);
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=LUFS'));
      });

      test('param `target` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, target: 0);
        expect(s.toFilterString(), contains('target='));
        expect(s.toFilterString(), contains('target=0'));
      });

      test('param `true_peak` lands in wire when set to a non-default value',
          () {
        final s = const Ebur128Settings(enabled: true, true_peak: 1.0);
        expect(s.toFilterString(), contains('true_peak='));
        expect(s.toFilterString(), contains('true_peak=1.000'));
      });

      test('param `video` lands in wire when set to a non-default value', () {
        final s = const Ebur128Settings(enabled: true, video: true);
        expect(s.toFilterString(), contains('video='));
      });
    });
    group('EqualizerSettings (equalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(equalizer: EqualizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(equalizer: EqualizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-equalizer');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const EqualizerSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const EqualizerSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('ExtrastereoSettings (extrastereo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(extrastereo: ExtrastereoSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(extrastereo: ExtrastereoSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-extrastereo');
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
    });
    group('FirequalizerSettings (firequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(firequalizer: FirequalizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(firequalizer: FirequalizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-firequalizer');
      });

      test('param `accuracy` lands in wire when set to a non-default value',
          () {
        final s =
            const FirequalizerSettings(enabled: true, accuracy: 10000000000.0);
        expect(s.toFilterString(), contains('accuracy='));
        expect(s.toFilterString(), contains('accuracy=10000000000.000'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s =
            const FirequalizerSettings(enabled: true, delay: 10000000000.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=10000000000.000'));
      });

      test('param `dumpfile` lands in wire when set to a non-default value',
          () {
        final s = const FirequalizerSettings(
            enabled: true, dumpfile: 'wire_test_alt');
        expect(s.toFilterString(), contains('dumpfile='));
      });

      test('param `dumpscale` lands in wire when set to a non-default value',
          () {
        final s = const FirequalizerSettings(
            enabled: true, dumpscale: FirequalizerScale.linlog);
        expect(s.toFilterString(), contains('dumpscale='));
        expect(s.toFilterString(), contains('dumpscale=linlog'));
      });

      test('param `fft2` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, fft2: true);
        expect(s.toFilterString(), contains('fft2='));
      });

      test('param `fixed` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, fixed: true);
        expect(s.toFilterString(), contains('fixed='));
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s =
            const FirequalizerSettings(enabled: true, gain: 'wire_test_alt');
        expect(s.toFilterString(), contains('gain='));
      });

      test('param `gain_entry` lands in wire when set to a non-default value',
          () {
        final s = const FirequalizerSettings(
            enabled: true, gain_entry: 'wire_test_alt');
        expect(s.toFilterString(), contains('gain_entry='));
      });

      test('param `min_phase` lands in wire when set to a non-default value',
          () {
        final s = const FirequalizerSettings(enabled: true, min_phase: true);
        expect(s.toFilterString(), contains('min_phase='));
      });

      test('param `multi` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(enabled: true, multi: true);
        expect(s.toFilterString(), contains('multi='));
      });

      test('param `scale` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
            enabled: true, scale: FirequalizerScale.linlog);
        expect(s.toFilterString(), contains('scale='));
        expect(s.toFilterString(), contains('scale=linlog'));
      });

      test('param `wfunc` lands in wire when set to a non-default value', () {
        final s = const FirequalizerSettings(
            enabled: true, wfunc: FirequalizerWfunc.hann);
        expect(s.toFilterString(), contains('wfunc='));
        expect(s.toFilterString(), contains('wfunc=hann'));
      });

      test('param `zero_phase` lands in wire when set to a non-default value',
          () {
        final s = const FirequalizerSettings(enabled: true, zero_phase: true);
        expect(s.toFilterString(), contains('zero_phase='));
      });
    });
    group('FlangerSettings (flanger)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(flanger: FlangerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(flanger: FlangerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-flanger');
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
            enabled: true, interp: FlangerItype.quadratic);
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
        final s = const FlangerSettings(enabled: true, shape: FlangerType.t);
        expect(s.toFilterString(), contains('shape='));
        expect(s.toFilterString(), contains('shape=t'));
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
    });
    group('HaasSettings (haas)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(haas: HaasSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(haas: HaasSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-haas');
      });

      test('param `left_balance` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, left_balance: 1.0);
        expect(s.toFilterString(), contains('left_balance='));
        expect(s.toFilterString(), contains('left_balance=1.000'));
      });

      test('param `left_delay` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, left_delay: 0.0);
        expect(s.toFilterString(), contains('left_delay='));
        expect(s.toFilterString(), contains('left_delay=0.000'));
      });

      test('param `left_gain` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, left_gain: 64.0);
        expect(s.toFilterString(), contains('left_gain='));
        expect(s.toFilterString(), contains('left_gain=64.000'));
      });

      test('param `left_phase` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, left_phase: true);
        expect(s.toFilterString(), contains('left_phase='));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `middle_phase` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, middle_phase: true);
        expect(s.toFilterString(), contains('middle_phase='));
      });

      test(
          'param `middle_source` lands in wire when set to a non-default value',
          () {
        final s =
            const HaasSettings(enabled: true, middle_source: HaasSource.left);
        expect(s.toFilterString(), contains('middle_source='));
        expect(s.toFilterString(), contains('middle_source=left'));
      });

      test(
          'param `right_balance` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, right_balance: -1.0);
        expect(s.toFilterString(), contains('right_balance='));
        expect(s.toFilterString(), contains('right_balance=-1.000'));
      });

      test('param `right_delay` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, right_delay: 0.0);
        expect(s.toFilterString(), contains('right_delay='));
        expect(s.toFilterString(), contains('right_delay=0.000'));
      });

      test('param `right_gain` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, right_gain: 64.0);
        expect(s.toFilterString(), contains('right_gain='));
        expect(s.toFilterString(), contains('right_gain=64.000'));
      });

      test('param `right_phase` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, right_phase: false);
        expect(s.toFilterString(), contains('right_phase='));
      });

      test('param `side_gain` lands in wire when set to a non-default value',
          () {
        final s = const HaasSettings(enabled: true, side_gain: 64.0);
        expect(s.toFilterString(), contains('side_gain='));
        expect(s.toFilterString(), contains('side_gain=64.000'));
      });
    });
    group('HdcdSettings (hdcd)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(hdcd: HdcdSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(hdcd: HdcdSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-hdcd');
      });

      test('param `analyze_mode` lands in wire when set to a non-default value',
          () {
        final s = const HdcdSettings(
            enabled: true, analyze_mode: HdcdAnalyzeMode.lle);
        expect(s.toFilterString(), contains('analyze_mode='));
        expect(s.toFilterString(), contains('analyze_mode=lle'));
      });

      test(
          'param `bits_per_sample` lands in wire when set to a non-default value',
          () {
        final s = const HdcdSettings(
            enabled: true, bits_per_sample: HdcdBitsPerSample.n20);
        expect(s.toFilterString(), contains('bits_per_sample='));
        expect(s.toFilterString(), contains('bits_per_sample=20'));
      });

      test('param `cdt_ms` lands in wire when set to a non-default value', () {
        final s = const HdcdSettings(enabled: true, cdt_ms: 60000);
        expect(s.toFilterString(), contains('cdt_ms='));
        expect(s.toFilterString(), contains('cdt_ms=60000'));
      });

      test(
          'param `disable_autoconvert` lands in wire when set to a non-default value',
          () {
        final s = const HdcdSettings(enabled: true, disable_autoconvert: false);
        expect(s.toFilterString(), contains('disable_autoconvert='));
      });

      test('param `force_pe` lands in wire when set to a non-default value',
          () {
        final s = const HdcdSettings(enabled: true, force_pe: true);
        expect(s.toFilterString(), contains('force_pe='));
      });

      test(
          'param `process_stereo` lands in wire when set to a non-default value',
          () {
        final s = const HdcdSettings(enabled: true, process_stereo: true);
        expect(s.toFilterString(), contains('process_stereo='));
      });
    });
    group('HeadphoneSettings (headphone)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(headphone: HeadphoneSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(headphone: HeadphoneSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-headphone');
      });

      test('param `gain` lands in wire when set to a non-default value', () {
        final s = const HeadphoneSettings(enabled: true, gain: 40.0);
        expect(s.toFilterString(), contains('gain='));
        expect(s.toFilterString(), contains('gain=40.000'));
      });

      test('param `hrir` lands in wire when set to a non-default value', () {
        final s =
            const HeadphoneSettings(enabled: true, hrir: HeadphoneHrir.multich);
        expect(s.toFilterString(), contains('hrir='));
        expect(s.toFilterString(), contains('hrir=multich'));
      });

      test('param `lfe` lands in wire when set to a non-default value', () {
        final s = const HeadphoneSettings(enabled: true, lfe: 40.0);
        expect(s.toFilterString(), contains('lfe='));
        expect(s.toFilterString(), contains('lfe=40.000'));
      });

      test('param `map` lands in wire when set to a non-default value', () {
        final s = const HeadphoneSettings(enabled: true, map: 'wire_test_alt');
        expect(s.toFilterString(), contains('map='));
      });

      test('param `size` lands in wire when set to a non-default value', () {
        final s = const HeadphoneSettings(enabled: true, size: 96000);
        expect(s.toFilterString(), contains('size='));
        expect(s.toFilterString(), contains('size=96000'));
      });

      test('param `type` lands in wire when set to a non-default value', () {
        final s =
            const HeadphoneSettings(enabled: true, type: HeadphoneType.time);
        expect(s.toFilterString(), contains('type='));
        expect(s.toFilterString(), contains('type=time'));
      });
    });
    group('HighpassSettings (highpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(highpass: HighpassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(highpass: HighpassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-highpass');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const HighpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const HighpassSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('HighshelfSettings (highshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(highshelf: HighshelfSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(highshelf: HighshelfSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-highshelf');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const HighshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const HighshelfSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('LoudnormSettings (loudnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(loudnorm: LoudnormSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(loudnorm: LoudnormSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-loudnorm');
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

      test('param `dual_mono` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, dual_mono: true);
        expect(s.toFilterString(), contains('dual_mono='));
      });

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

      test('param `measured_I` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_I: -99.0);
        expect(s.toFilterString(), contains('measured_I='));
        expect(s.toFilterString(), contains('measured_I=-99.000'));
      });

      test('param `measured_LRA` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_LRA: 99.0);
        expect(s.toFilterString(), contains('measured_LRA='));
        expect(s.toFilterString(), contains('measured_LRA=99.000'));
      });

      test('param `measured_TP` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_TP: -99.0);
        expect(s.toFilterString(), contains('measured_TP='));
        expect(s.toFilterString(), contains('measured_TP=-99.000'));
      });

      test('param `measured_i` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_i: -99.0);
        expect(s.toFilterString(), contains('measured_i='));
        expect(s.toFilterString(), contains('measured_i=-99.000'));
      });

      test('param `measured_lra` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_lra: 99.0);
        expect(s.toFilterString(), contains('measured_lra='));
        expect(s.toFilterString(), contains('measured_lra=99.000'));
      });

      test(
          'param `measured_thresh` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_thresh: 0.0);
        expect(s.toFilterString(), contains('measured_thresh='));
        expect(s.toFilterString(), contains('measured_thresh=0.000'));
      });

      test('param `measured_tp` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(enabled: true, measured_tp: -99.0);
        expect(s.toFilterString(), contains('measured_tp='));
        expect(s.toFilterString(), contains('measured_tp=-99.000'));
      });

      test('param `offset` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, offset: 99.0);
        expect(s.toFilterString(), contains('offset='));
        expect(s.toFilterString(), contains('offset=99.000'));
      });

      test('param `print_format` lands in wire when set to a non-default value',
          () {
        final s = const LoudnormSettings(
            enabled: true, print_format: LoudnormPrintFormat.json);
        expect(s.toFilterString(), contains('print_format='));
        expect(s.toFilterString(), contains('print_format=json'));
      });

      test('param `tp` lands in wire when set to a non-default value', () {
        final s = const LoudnormSettings(enabled: true, tp: 0.0);
        expect(s.toFilterString(), contains('tp='));
        expect(s.toFilterString(), contains('tp=0.000'));
      });
    });
    group('LowpassSettings (lowpass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(lowpass: LowpassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(lowpass: LowpassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-lowpass');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const LowpassSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const LowpassSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('LowshelfSettings (lowshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(lowshelf: LowshelfSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(lowshelf: LowshelfSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-lowshelf');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const LowshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const LowshelfSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('McompandSettings (mcompand)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(mcompand: McompandSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(mcompand: McompandSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-mcompand');
      });

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const McompandSettings(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('PanSettings (pan)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(pan: PanSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(pan: PanSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-pan');
      });

      test('param `args` lands in wire when set to a non-default value', () {
        final s = const PanSettings(enabled: true, args: 'wire_test_alt');
        expect(s.toFilterString(), contains('args='));
      });
    });
    group('ReplaygainSettings (replaygain)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(replaygain: ReplaygainSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(replaygain: ReplaygainSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-replaygain');
      });

      test('param `track_gain` lands in wire when set to a non-default value',
          () {
        final s = const ReplaygainSettings(enabled: true, track_gain: 1.0);
        expect(s.toFilterString(), contains('track_gain='));
        expect(s.toFilterString(), contains('track_gain=1.000'));
      });

      test('param `track_peak` lands in wire when set to a non-default value',
          () {
        final s = const ReplaygainSettings(enabled: true, track_peak: 1.0);
        expect(s.toFilterString(), contains('track_peak='));
        expect(s.toFilterString(), contains('track_peak=1.000'));
      });
    });
    group('RubberbandSettings (rubberband)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(rubberband: RubberbandSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(rubberband: RubberbandSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-rubberband');
      });

      test('param `channels` lands in wire when set to a non-default value',
          () {
        final s = const RubberbandSettings(
            enabled: true, channels: RubberbandChannels.together);
        expect(s.toFilterString(), contains('channels='));
        expect(s.toFilterString(), contains('channels=together'));
      });

      test('param `detector` lands in wire when set to a non-default value',
          () {
        final s = const RubberbandSettings(
            enabled: true, detector: RubberbandDetector.percussive);
        expect(s.toFilterString(), contains('detector='));
        expect(s.toFilterString(), contains('detector=percussive'));
      });

      test('param `formant` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
            enabled: true, formant: RubberbandFormant.preserved);
        expect(s.toFilterString(), contains('formant='));
        expect(s.toFilterString(), contains('formant=preserved'));
      });

      test('param `phase` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
            enabled: true, phase: RubberbandPhase.independent);
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
            enabled: true, pitchq: RubberbandPitch.speed);
        expect(s.toFilterString(), contains('pitchq='));
        expect(s.toFilterString(), contains('pitchq=speed'));
      });

      test('param `smoothing` lands in wire when set to a non-default value',
          () {
        final s = const RubberbandSettings(
            enabled: true, smoothing: RubberbandSmoothing.on_);
        expect(s.toFilterString(), contains('smoothing='));
        expect(s.toFilterString(), contains('smoothing=on'));
      });

      test('param `tempo` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(enabled: true, tempo: 100.0);
        expect(s.toFilterString(), contains('tempo='));
        expect(s.toFilterString(), contains('tempo=100.000'));
      });

      test('param `transients` lands in wire when set to a non-default value',
          () {
        final s = const RubberbandSettings(
            enabled: true, transients: RubberbandTransients.mixed);
        expect(s.toFilterString(), contains('transients='));
        expect(s.toFilterString(), contains('transients=mixed'));
      });

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const RubberbandSettings(
            enabled: true, window: RubberbandWindow.short);
        expect(s.toFilterString(), contains('window='));
        expect(s.toFilterString(), contains('window=short'));
      });
    });
    group('SilencedetectSettings (silencedetect)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(silencedetect: SilencedetectSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(silencedetect: SilencedetectSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-silencedetect');
      });

      test('param `d` lands in wire when set to a non-default value', () {
        final s = const SilencedetectSettings(
            enabled: true, d: const Duration(microseconds: 3000000));
        expect(s.toFilterString(), contains('d='));
      });

      test('param `duration` lands in wire when set to a non-default value',
          () {
        final s = const SilencedetectSettings(
            enabled: true, duration: const Duration(microseconds: 3000000));
        expect(s.toFilterString(), contains('duration='));
      });

      test('param `m` lands in wire when set to a non-default value', () {
        final s = const SilencedetectSettings(enabled: true, m: true);
        expect(s.toFilterString(), contains('m='));
      });

      test('param `mono` lands in wire when set to a non-default value', () {
        final s = const SilencedetectSettings(enabled: true, mono: true);
        expect(s.toFilterString(), contains('mono='));
      });

      test('param `n` lands in wire when set to a non-default value', () {
        final s = const SilencedetectSettings(enabled: true, n: 0.0);
        expect(s.toFilterString(), contains('n='));
        expect(s.toFilterString(), contains('n=0.000'));
      });

      test('param `noise` lands in wire when set to a non-default value', () {
        final s = const SilencedetectSettings(enabled: true, noise: 0.0);
        expect(s.toFilterString(), contains('noise='));
        expect(s.toFilterString(), contains('noise=0.000'));
      });
    });
    group('SilenceremoveSettings (silenceremove)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(silenceremove: SilenceremoveSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(silenceremove: SilenceremoveSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-silenceremove');
      });

      test('param `detection` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true, detection: SilenceremoveDetection.rms);
        expect(s.toFilterString(), contains('detection='));
        expect(s.toFilterString(), contains('detection=rms'));
      });

      test(
          'param `start_duration` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true,
            start_duration: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('start_duration='));
      });

      test('param `start_mode` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true, start_mode: SilenceremoveMode.all);
        expect(s.toFilterString(), contains('start_mode='));
        expect(s.toFilterString(), contains('start_mode=all'));
      });

      test(
          'param `start_periods` lands in wire when set to a non-default value',
          () {
        final s =
            const SilenceremoveSettings(enabled: true, start_periods: 9000);
        expect(s.toFilterString(), contains('start_periods='));
        expect(s.toFilterString(), contains('start_periods=9000'));
      });

      test(
          'param `start_silence` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true,
            start_silence: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('start_silence='));
      });

      test(
          'param `start_threshold` lands in wire when set to a non-default value',
          () {
        final s =
            const SilenceremoveSettings(enabled: true, start_threshold: 1.0);
        expect(s.toFilterString(), contains('start_threshold='));
        expect(s.toFilterString(), contains('start_threshold=1.000'));
      });

      test(
          'param `stop_duration` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true,
            stop_duration: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('stop_duration='));
      });

      test('param `stop_mode` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true, stop_mode: SilenceremoveMode.all);
        expect(s.toFilterString(), contains('stop_mode='));
        expect(s.toFilterString(), contains('stop_mode=all'));
      });

      test('param `stop_periods` lands in wire when set to a non-default value',
          () {
        final s =
            const SilenceremoveSettings(enabled: true, stop_periods: 9000);
        expect(s.toFilterString(), contains('stop_periods='));
        expect(s.toFilterString(), contains('stop_periods=9000'));
      });

      test('param `stop_silence` lands in wire when set to a non-default value',
          () {
        final s = const SilenceremoveSettings(
            enabled: true, stop_silence: const Duration(microseconds: 1000000));
        expect(s.toFilterString(), contains('stop_silence='));
      });

      test(
          'param `stop_threshold` lands in wire when set to a non-default value',
          () {
        final s =
            const SilenceremoveSettings(enabled: true, stop_threshold: 1.0);
        expect(s.toFilterString(), contains('stop_threshold='));
        expect(s.toFilterString(), contains('stop_threshold=1.000'));
      });

      test('param `window` lands in wire when set to a non-default value', () {
        final s = const SilenceremoveSettings(
            enabled: true, window: const Duration(microseconds: 1020000));
        expect(s.toFilterString(), contains('window='));
      });
    });
    group('SpeechnormSettings (speechnorm)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(speechnorm: SpeechnormSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(speechnorm: SpeechnormSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-speechnorm');
      });

      test('param `c` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, c: 50.0);
        expect(s.toFilterString(), contains('c='));
        expect(s.toFilterString(), contains('c=50.000'));
      });

      test('param `channels` lands in wire when set to a non-default value',
          () {
        final s =
            const SpeechnormSettings(enabled: true, channels: 'wire_test_alt');
        expect(s.toFilterString(), contains('channels='));
      });

      test('param `compression` lands in wire when set to a non-default value',
          () {
        final s = const SpeechnormSettings(enabled: true, compression: 50.0);
        expect(s.toFilterString(), contains('compression='));
        expect(s.toFilterString(), contains('compression=50.000'));
      });

      test('param `e` lands in wire when set to a non-default value', () {
        final s = const SpeechnormSettings(enabled: true, e: 50.0);
        expect(s.toFilterString(), contains('e='));
        expect(s.toFilterString(), contains('e=50.000'));
      });

      test('param `expansion` lands in wire when set to a non-default value',
          () {
        final s = const SpeechnormSettings(enabled: true, expansion: 50.0);
        expect(s.toFilterString(), contains('expansion='));
        expect(s.toFilterString(), contains('expansion=50.000'));
      });

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

      test('param `threshold` lands in wire when set to a non-default value',
          () {
        final s = const SpeechnormSettings(enabled: true, threshold: 1.0);
        expect(s.toFilterString(), contains('threshold='));
        expect(s.toFilterString(), contains('threshold=1.000'));
      });
    });
    group('StereotoolsSettings (stereotools)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(stereotools: StereotoolsSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(stereotools: StereotoolsSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-stereotools');
      });

      test('param `balance_in` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(enabled: true, balance_in: 1.0);
        expect(s.toFilterString(), contains('balance_in='));
        expect(s.toFilterString(), contains('balance_in=1.000'));
      });

      test('param `balance_out` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(enabled: true, balance_out: 1.0);
        expect(s.toFilterString(), contains('balance_out='));
        expect(s.toFilterString(), contains('balance_out=1.000'));
      });

      test('param `base` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, base: 1.0);
        expect(s.toFilterString(), contains('base='));
        expect(s.toFilterString(), contains('base=1.000'));
      });

      test('param `bmode_in` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(
            enabled: true, bmode_in: StereotoolsBmode.amplitude);
        expect(s.toFilterString(), contains('bmode_in='));
        expect(s.toFilterString(), contains('bmode_in=amplitude'));
      });

      test('param `bmode_out` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(
            enabled: true, bmode_out: StereotoolsBmode.amplitude);
        expect(s.toFilterString(), contains('bmode_out='));
        expect(s.toFilterString(), contains('bmode_out=amplitude'));
      });

      test('param `delay` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, delay: 20.0);
        expect(s.toFilterString(), contains('delay='));
        expect(s.toFilterString(), contains('delay=20.000'));
      });

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(enabled: true, level_in: 64.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=64.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(enabled: true, level_out: 64.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=64.000'));
      });

      test('param `mlev` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(enabled: true, mlev: 64.0);
        expect(s.toFilterString(), contains('mlev='));
        expect(s.toFilterString(), contains('mlev=64.000'));
      });

      test('param `mode` lands in wire when set to a non-default value', () {
        final s = const StereotoolsSettings(
            enabled: true, mode: StereotoolsMode.lr_to_ms);
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

      test('param `softclip` lands in wire when set to a non-default value',
          () {
        final s = const StereotoolsSettings(enabled: true, softclip: true);
        expect(s.toFilterString(), contains('softclip='));
      });
    });
    group('StereowidenSettings (stereowiden)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(stereowiden: StereowidenSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(stereowiden: StereowidenSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-stereowiden');
      });

      test('param `crossfeed` lands in wire when set to a non-default value',
          () {
        final s = const StereowidenSettings(enabled: true, crossfeed: 0.8);
        expect(s.toFilterString(), contains('crossfeed='));
        expect(s.toFilterString(), contains('crossfeed=0.800'));
      });

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

      test('param `feedback` lands in wire when set to a non-default value',
          () {
        final s = const StereowidenSettings(enabled: true, feedback: 0.9);
        expect(s.toFilterString(), contains('feedback='));
        expect(s.toFilterString(), contains('feedback=0.900'));
      });
    });
    group('SuperequalizerSettings (superequalizer)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(superequalizer: SuperequalizerSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(superequalizer: SuperequalizerSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-superequalizer');
      });

      test('digit-prefix param `10b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'10b': 20.0});
        expect(s.toFilterString(), contains('10b='));
        expect(s.toFilterString(), contains('10b=20.000'));
      });

      test('digit-prefix param `11b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'11b': 20.0});
        expect(s.toFilterString(), contains('11b='));
        expect(s.toFilterString(), contains('11b=20.000'));
      });

      test('digit-prefix param `12b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'12b': 20.0});
        expect(s.toFilterString(), contains('12b='));
        expect(s.toFilterString(), contains('12b=20.000'));
      });

      test('digit-prefix param `13b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'13b': 20.0});
        expect(s.toFilterString(), contains('13b='));
        expect(s.toFilterString(), contains('13b=20.000'));
      });

      test('digit-prefix param `14b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'14b': 20.0});
        expect(s.toFilterString(), contains('14b='));
        expect(s.toFilterString(), contains('14b=20.000'));
      });

      test('digit-prefix param `15b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'15b': 20.0});
        expect(s.toFilterString(), contains('15b='));
        expect(s.toFilterString(), contains('15b=20.000'));
      });

      test('digit-prefix param `16b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'16b': 20.0});
        expect(s.toFilterString(), contains('16b='));
        expect(s.toFilterString(), contains('16b=20.000'));
      });

      test('digit-prefix param `17b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'17b': 20.0});
        expect(s.toFilterString(), contains('17b='));
        expect(s.toFilterString(), contains('17b=20.000'));
      });

      test('digit-prefix param `18b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'18b': 20.0});
        expect(s.toFilterString(), contains('18b='));
        expect(s.toFilterString(), contains('18b=20.000'));
      });

      test('digit-prefix param `1b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'1b': 20.0});
        expect(s.toFilterString(), contains('1b='));
        expect(s.toFilterString(), contains('1b=20.000'));
      });

      test('digit-prefix param `2b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'2b': 20.0});
        expect(s.toFilterString(), contains('2b='));
        expect(s.toFilterString(), contains('2b=20.000'));
      });

      test('digit-prefix param `3b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'3b': 20.0});
        expect(s.toFilterString(), contains('3b='));
        expect(s.toFilterString(), contains('3b=20.000'));
      });

      test('digit-prefix param `4b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'4b': 20.0});
        expect(s.toFilterString(), contains('4b='));
        expect(s.toFilterString(), contains('4b=20.000'));
      });

      test('digit-prefix param `5b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'5b': 20.0});
        expect(s.toFilterString(), contains('5b='));
        expect(s.toFilterString(), contains('5b=20.000'));
      });

      test('digit-prefix param `6b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'6b': 20.0});
        expect(s.toFilterString(), contains('6b='));
        expect(s.toFilterString(), contains('6b=20.000'));
      });

      test('digit-prefix param `7b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'7b': 20.0});
        expect(s.toFilterString(), contains('7b='));
        expect(s.toFilterString(), contains('7b=20.000'));
      });

      test('digit-prefix param `8b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'8b': 20.0});
        expect(s.toFilterString(), contains('8b='));
        expect(s.toFilterString(), contains('8b=20.000'));
      });

      test('digit-prefix param `9b` lands in wire via params map', () {
        final s =
            const SuperequalizerSettings(enabled: true, params: {'9b': 20.0});
        expect(s.toFilterString(), contains('9b='));
        expect(s.toFilterString(), contains('9b=20.000'));
      });
    });
    group('SurroundSettings (surround)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(surround: SurroundSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(surround: SurroundSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-surround');
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
        final s =
            const SurroundSettings(enabled: true, chl_in: 'wire_test_alt');
        expect(s.toFilterString(), contains('chl_in='));
      });

      test('param `chl_out` lands in wire when set to a non-default value', () {
        final s =
            const SurroundSettings(enabled: true, chl_out: 'wire_test_alt');
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

      test('param `level_in` lands in wire when set to a non-default value',
          () {
        final s = const SurroundSettings(enabled: true, level_in: 10.0);
        expect(s.toFilterString(), contains('level_in='));
        expect(s.toFilterString(), contains('level_in=10.000'));
      });

      test('param `level_out` lands in wire when set to a non-default value',
          () {
        final s = const SurroundSettings(enabled: true, level_out: 10.0);
        expect(s.toFilterString(), contains('level_out='));
        expect(s.toFilterString(), contains('level_out=10.000'));
      });

      test('param `lfe` lands in wire when set to a non-default value', () {
        final s = const SurroundSettings(enabled: true, lfe: false);
        expect(s.toFilterString(), contains('lfe='));
      });

      test('param `lfe_high` lands in wire when set to a non-default value',
          () {
        final s = const SurroundSettings(enabled: true, lfe_high: 512);
        expect(s.toFilterString(), contains('lfe_high='));
        expect(s.toFilterString(), contains('lfe_high=512'));
      });

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

      test('param `lfe_mode` lands in wire when set to a non-default value',
          () {
        final s = const SurroundSettings(
            enabled: true, lfe_mode: SurroundLfeMode.sub);
        expect(s.toFilterString(), contains('lfe_mode='));
        expect(s.toFilterString(), contains('lfe_mode=sub'));
      });

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

      test('param `win_size` lands in wire when set to a non-default value',
          () {
        final s = const SurroundSettings(enabled: true, win_size: 65536);
        expect(s.toFilterString(), contains('win_size='));
        expect(s.toFilterString(), contains('win_size=65536'));
      });
    });
    group('TiltshelfSettings (tiltshelf)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(tiltshelf: TiltshelfSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(tiltshelf: TiltshelfSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-tiltshelf');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TiltshelfSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const TiltshelfSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('TrebleSettings (treble)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(treble: TrebleSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(treble: TrebleSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-treble');
      });

      test('param `f` lands in wire when set to a non-default value', () {
        final s = const TrebleSettings(enabled: true, f: 999999.0);
        expect(s.toFilterString(), contains('f='));
        expect(s.toFilterString(), contains('f=999999.000'));
      });

      test('param `frequency` lands in wire when set to a non-default value',
          () {
        final s = const TrebleSettings(enabled: true, frequency: 999999.0);
        expect(s.toFilterString(), contains('frequency='));
        expect(s.toFilterString(), contains('frequency=999999.000'));
      });

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
    });
    group('TremoloSettings (tremolo)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(tremolo: TremoloSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(tremolo: TremoloSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-tremolo');
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
    });
    group('VibratoSettings (vibrato)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(vibrato: VibratoSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(vibrato: VibratoSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-vibrato');
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
    });
    group('VirtualbassSettings (virtualbass)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(virtualbass: VirtualbassSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(virtualbass: VirtualbassSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-virtualbass');
      });

      test('param `cutoff` lands in wire when set to a non-default value', () {
        final s = const VirtualbassSettings(enabled: true, cutoff: 500.0);
        expect(s.toFilterString(), contains('cutoff='));
        expect(s.toFilterString(), contains('cutoff=500.000'));
      });

      test('param `strength` lands in wire when set to a non-default value',
          () {
        final s = const VirtualbassSettings(enabled: true, strength: 0.5);
        expect(s.toFilterString(), contains('strength='));
        expect(s.toFilterString(), contains('strength=0.500'));
      });
    });
    group('VolumeSettings (volume)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(volume: VolumeSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx = AudioEffects(volume: VolumeSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-volume');
      });

      test('param `eval` lands in wire when set to a non-default value', () {
        final s = const VolumeSettings(enabled: true, eval: VolumeEval.frame);
        expect(s.toFilterString(), contains('eval='));
        expect(s.toFilterString(), contains('eval=frame'));
      });

      test('param `precision` lands in wire when set to a non-default value',
          () {
        final s = const VolumeSettings(
            enabled: true, precision: VolumePrecision.float);
        expect(s.toFilterString(), contains('precision='));
        expect(s.toFilterString(), contains('precision=float'));
      });

      test('param `replaygain` lands in wire when set to a non-default value',
          () {
        final s = const VolumeSettings(
            enabled: true, replaygain: VolumeReplaygain.ignore);
        expect(s.toFilterString(), contains('replaygain='));
        expect(s.toFilterString(), contains('replaygain=ignore'));
      });

      test(
          'param `replaygain_noclip` lands in wire when set to a non-default value',
          () {
        final s = const VolumeSettings(enabled: true, replaygain_noclip: false);
        expect(s.toFilterString(), contains('replaygain_noclip='));
      });

      test(
          'param `replaygain_preamp` lands in wire when set to a non-default value',
          () {
        final s = const VolumeSettings(enabled: true, replaygain_preamp: 15.0);
        expect(s.toFilterString(), contains('replaygain_preamp='));
        expect(s.toFilterString(), contains('replaygain_preamp=15.000'));
      });

      test('param `volume` lands in wire when set to a non-default value', () {
        final s = const VolumeSettings(enabled: true, volume: 'wire_test_alt');
        expect(s.toFilterString(), contains('volume='));
      });
    });
    group('VolumedetectSettings (volumedetect)', () {
      test('disabled by default → drops out of toAfChain', () {
        const fx = AudioEffects(volumedetect: VolumedetectSettings());
        expect(fx.toAfChain(), '');
      });

      test('enabled with every param at default → bare lavfi name', () {
        const fx =
            AudioEffects(volumedetect: VolumedetectSettings(enabled: true));
        expect(fx.toAfChain(), 'lavfi-volumedetect');
      });
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
        expect(AcompressorDetection.fromMpv('this_will_never_match'),
            AcompressorDetection.peak);
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
        expect(AcompressorLink.fromMpv('this_will_never_match'),
            AcompressorLink.average);
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
        expect(AcompressorMode.fromMpv('this_will_never_match'),
            AcompressorMode.downward);
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
        expect(AdynamicequalizerAuto.fromMpv('this_will_never_match'),
            AdynamicequalizerAuto.disabled);
        expect(AdynamicequalizerAuto.fromMpv(null),
            AdynamicequalizerAuto.disabled);
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
        expect(AdynamicequalizerDftype.fromMpv('this_will_never_match'),
            AdynamicequalizerDftype.bandpass);
        expect(AdynamicequalizerDftype.fromMpv(null),
            AdynamicequalizerDftype.bandpass);
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
        expect(AdynamicequalizerMode.fromMpv('this_will_never_match'),
            AdynamicequalizerMode.listen);
        expect(
            AdynamicequalizerMode.fromMpv(null), AdynamicequalizerMode.listen);
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
        expect(AdynamicequalizerPrecision.fromMpv('this_will_never_match'),
            AdynamicequalizerPrecision.auto);
        expect(AdynamicequalizerPrecision.fromMpv(null),
            AdynamicequalizerPrecision.auto);
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
        expect(AdynamicequalizerTftype.fromMpv('this_will_never_match'),
            AdynamicequalizerTftype.bell);
        expect(AdynamicequalizerTftype.fromMpv(null),
            AdynamicequalizerTftype.bell);
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
        expect(AemphasisMode.fromMpv('this_will_never_match'),
            AemphasisMode.reproduction);
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
            AemphasisType.fromMpv('this_will_never_match'), AemphasisType.col);
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
            AfftdnSample.fromMpv('this_will_never_match'), AfftdnSample.none);
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
        expect(AgateDetection.fromMpv('this_will_never_match'),
            AgateDetection.peak);
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
            AiirPrecision.fromMpv('this_will_never_match'), AiirPrecision.dbl);
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
    group('AnequalizerFscale (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AnequalizerFscale.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AnequalizerFscale.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AnequalizerFscale.fromMpv('this_will_never_match'),
            AnequalizerFscale.lin);
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
    group('ApermsMode (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in ApermsMode.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(ApermsMode.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(ApermsMode.fromMpv('this_will_never_match'), ApermsMode.none);
        expect(ApermsMode.fromMpv(null), ApermsMode.none);
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
        expect(AphaserType.fromMpv('this_will_never_match'),
            AphaserType.triangular);
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
            ApulsatorMode.fromMpv('this_will_never_match'), ApulsatorMode.sine);
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
        expect(ApulsatorTiming.fromMpv('this_will_never_match'),
            ApulsatorTiming.bpm);
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
        expect(AsoftclipTypes.fromMpv('this_will_never_match'),
            AsoftclipTypes.hard);
        expect(AsoftclipTypes.fromMpv(null), AsoftclipTypes.hard);
      });
    });
    group('AspectralstatsMeasure (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AspectralstatsMeasure.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AspectralstatsMeasure.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(AspectralstatsMeasure.fromMpv('this_will_never_match'),
            AspectralstatsMeasure.none);
        expect(AspectralstatsMeasure.fromMpv(null), AspectralstatsMeasure.none);
      });
    });
    group('AstatsMeasure (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in AstatsMeasure.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(AstatsMeasure.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
            AstatsMeasure.fromMpv('this_will_never_match'), AstatsMeasure.none);
        expect(AstatsMeasure.fromMpv(null), AstatsMeasure.none);
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
        expect(Ebur128Gaugetype.fromMpv('this_will_never_match'),
            Ebur128Gaugetype.momentary);
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
            Ebur128Level.fromMpv('this_will_never_match'), Ebur128Level.quiet);
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
        expect(Ebur128Scaletype.fromMpv('this_will_never_match'),
            Ebur128Scaletype.absolute);
        expect(Ebur128Scaletype.fromMpv(null), Ebur128Scaletype.absolute);
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
        expect(FirequalizerScale.fromMpv('this_will_never_match'),
            FirequalizerScale.linlin);
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
        expect(FirequalizerWfunc.fromMpv('this_will_never_match'),
            FirequalizerWfunc.rectangular);
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
            FlangerItype.fromMpv('this_will_never_match'), FlangerItype.linear);
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
        expect(FlangerType.fromMpv('this_will_never_match'),
            FlangerType.triangular);
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
        expect(HdcdAnalyzeMode.fromMpv('this_will_never_match'),
            HdcdAnalyzeMode.off);
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
        expect(HdcdBitsPerSample.fromMpv('this_will_never_match'),
            HdcdBitsPerSample.n16);
        expect(HdcdBitsPerSample.fromMpv(null), HdcdBitsPerSample.n16);
      });
    });
    group('HeadphoneHrir (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HeadphoneHrir.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HeadphoneHrir.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(HeadphoneHrir.fromMpv('this_will_never_match'),
            HeadphoneHrir.stereo);
        expect(HeadphoneHrir.fromMpv(null), HeadphoneHrir.stereo);
      });
    });
    group('HeadphoneType (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in HeadphoneType.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(HeadphoneType.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(
            HeadphoneType.fromMpv('this_will_never_match'), HeadphoneType.time);
        expect(HeadphoneType.fromMpv(null), HeadphoneType.time);
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
        expect(LoudnormPrintFormat.fromMpv('this_will_never_match'),
            LoudnormPrintFormat.none);
        expect(LoudnormPrintFormat.fromMpv(null), LoudnormPrintFormat.none);
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
        expect(RubberbandChannels.fromMpv('this_will_never_match'),
            RubberbandChannels.apart);
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
        expect(RubberbandDetector.fromMpv('this_will_never_match'),
            RubberbandDetector.compound);
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
        expect(RubberbandFormant.fromMpv('this_will_never_match'),
            RubberbandFormant.shifted);
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
        expect(RubberbandPhase.fromMpv('this_will_never_match'),
            RubberbandPhase.laminar);
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
        expect(RubberbandPitch.fromMpv('this_will_never_match'),
            RubberbandPitch.quality);
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
        expect(RubberbandSmoothing.fromMpv('this_will_never_match'),
            RubberbandSmoothing.off);
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
        expect(RubberbandTransients.fromMpv('this_will_never_match'),
            RubberbandTransients.crisp);
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
        expect(RubberbandWindow.fromMpv('this_will_never_match'),
            RubberbandWindow.standard);
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
        expect(SilenceremoveDetection.fromMpv('this_will_never_match'),
            SilenceremoveDetection.avg);
        expect(
            SilenceremoveDetection.fromMpv(null), SilenceremoveDetection.avg);
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
        expect(SilenceremoveMode.fromMpv('this_will_never_match'),
            SilenceremoveMode.any);
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
        expect(SilenceremoveTimestamp.fromMpv('this_will_never_match'),
            SilenceremoveTimestamp.copy);
        expect(
            SilenceremoveTimestamp.fromMpv(null), SilenceremoveTimestamp.copy);
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
        expect(StereotoolsBmode.fromMpv('this_will_never_match'),
            StereotoolsBmode.balance);
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
        expect(StereotoolsMode.fromMpv('this_will_never_match'),
            StereotoolsMode.lr_to_lr);
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
        expect(SurroundLfeMode.fromMpv('this_will_never_match'),
            SurroundLfeMode.add);
        expect(SurroundLfeMode.fromMpv(null), SurroundLfeMode.add);
      });
    });
    group('VolumeEval (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in VolumeEval.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(VolumeEval.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(VolumeEval.fromMpv('this_will_never_match'), VolumeEval.once);
        expect(VolumeEval.fromMpv(null), VolumeEval.once);
      });
    });
    group('VolumePrecision (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in VolumePrecision.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(VolumePrecision.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(VolumePrecision.fromMpv('this_will_never_match'),
            VolumePrecision.fixed);
        expect(VolumePrecision.fromMpv(null), VolumePrecision.fixed);
      });
    });
    group('VolumeReplaygain (codegen enum)', () {
      test('every member round-trips via mpvValue / fromMpv', () {
        for (final v in VolumeReplaygain.values) {
          expect(v.mpvValue, isNotEmpty);
          expect(VolumeReplaygain.fromMpv(v.mpvValue), v);
        }
      });

      test('fromMpv unknown / null → first member (safe fallback)', () {
        expect(VolumeReplaygain.fromMpv('this_will_never_match'),
            VolumeReplaygain.drop);
        expect(VolumeReplaygain.fromMpv(null), VolumeReplaygain.drop);
      });
    });
  });
}
