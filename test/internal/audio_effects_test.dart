// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Unit tests for the effects chain model: `audioEffectsChain` (the `af`
// string an ordered effect list builds) and `audioEffectsDiff` (the live
// `af-command` updates between two lists). Pin the EXACT chain string for
// a few representative filters so a renamed AVOption or an enum mpvValue
// regression is caught at unit-test speed without a real libmpv.
//
// Per-filter wire correctness (every parameter, every default) is covered
// by the generated coverage test; this file checks the model's contract:
// list order is chain order, a filter may repeat and each instance gets
// its own label, disabled stages drop out but keep their label slot, raw
// stages go in verbatim, defaults are NOT emitted, and only same-shape
// parameter changes on command-capable filters update live.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/generated/audio_effects_settings.dart'
    show audioEffectLabels, audioEffectsChain, audioEffectsDiff;
import 'package:test/test.dart';

void main() {
  group('audioEffectsChain — empty / disabled', () {
    test('empty list → empty string', () {
      expect(audioEffectsChain(const []), '');
    });

    test('every stage disabled → empty string', () {
      expect(audioEffectsChain(const [AcompressorEffect(enabled: false)]), '');
    });

    test('default-valued stage emits the bare filter name', () {
      // No params differ from ffmpeg defaults → `lavfi-acompressor` only.
      expect(
        audioEffectsChain(const [AcompressorEffect()]),
        '@aek_acompressor_0:lavfi-acompressor',
      );
    });
  });

  group('audioEffectsChain — per-filter wire output', () {
    test('acompressor non-default params land in the chain', () {
      final af = audioEffectsChain(const [
        AcompressorEffect(threshold: 0.1, ratio: 6.0),
      ]);
      // Defaults (level_in=1, attack=20, release=250, ...) MUST NOT show up.
      expect(af, startsWith('@aek_acompressor_0:lavfi-acompressor='));
      expect(af, contains('threshold=0.100'));
      expect(af, contains('ratio=6.000'));
      expect(af, isNot(contains('level_in')));
      expect(af, isNot(contains('attack')));
    });

    test('camelCase fields write their ffmpeg option names', () {
      final af = audioEffectsChain(const [
        AcompressorEffect(levelIn: 2.0, levelSc: 0.5),
      ]);
      expect(af, contains('level_in=2.000'));
      expect(af, contains('level_sc=0.500'));
    });

    test('loudnorm targets, through the lowercase option aliases', () {
      // ffmpeg declares I/i, TP/tp, LRA/lra as aliases of one field; the
      // effect exposes the lowercase ones.
      final af = audioEffectsChain(const [
        LoudnormEffect(i: -16.0, tp: -1.0, lra: 11.0),
      ]);
      expect(af, contains('i=-16.000'));
      expect(af, contains('tp=-1.000'));
      expect(af, contains('lra=11.000'));
    });

    test('rubberband with typed enum + numeric params', () {
      final af = audioEffectsChain(const [
        RubberbandEffect(
          tempo: 0.95,
          pitchq: RubberbandPitch.speed,
          transients: RubberbandTransients.smooth,
        ),
      ]);
      // Enums emit via `mpvValue` (the exact ffmpeg CONST name).
      expect(af, startsWith('@aek_rubberband_0:lavfi-rubberband='));
      expect(af, contains('tempo=0.950'));
      expect(af, contains('pitchq=speed'));
      expect(af, contains('transients=smooth'));
    });

    test('aemphasis: default enum omitted, other values by mpvValue', () {
      expect(
        audioEffectsChain(const [AemphasisEffect()]),
        '@aek_aemphasis_0:lavfi-aemphasis',
      );
      // The Dart member is `n50fm` (digit-prefix escaped); the wire value
      // is the raw ffmpeg name `50fm`.
      expect(
        audioEffectsChain(const [AemphasisEffect(type: AemphasisType.n50fm)]),
        '@aek_aemphasis_0:lavfi-aemphasis=type=50fm',
      );
    });

    test('superequalizer routes digit-prefix bands through `params`', () {
      final af = audioEffectsChain(const [
        SuperequalizerEffect(
          params: {'1b': 1.5, '5b': 0.8, '10b': 1.2, '18b': 0.5},
        ),
      ]);
      expect(af, startsWith('@aek_superequalizer_0:lavfi-superequalizer='));
      expect(af, contains('1b=1.500'));
      expect(af, contains('5b=0.800'));
      expect(af, contains('10b=1.200'));
      expect(af, contains('18b=0.500'));
    });
  });

  group('audioEffectsChain — order and repeated filters', () {
    test('list order is chain order', () {
      final entries = audioEffectsChain(const [
        RubberbandEffect(tempo: 0.9),
        AcompressorEffect(),
        LoudnormEffect(),
      ]).split(',');
      expect(entries, [
        '@aek_rubberband_0:lavfi-rubberband=tempo=0.900',
        '@aek_acompressor_0:lavfi-acompressor',
        '@aek_loudnorm_0:lavfi-loudnorm',
      ]);
    });

    test('a repeated filter gets one label per instance', () {
      final entries = audioEffectsChain(const [
        EqualizerEffect(frequency: 100, gain: 3),
        AcompressorEffect(),
        EqualizerEffect(frequency: 8000, gain: -2),
      ]).split(',');
      expect(entries[0], startsWith('@aek_equalizer_0:lavfi-equalizer='));
      expect(entries[1], '@aek_acompressor_0:lavfi-acompressor');
      expect(entries[2], startsWith('@aek_equalizer_1:lavfi-equalizer='));
    });

    test('a disabled stage drops out but keeps its instance number', () {
      // Toggling the first equalizer must not relabel the second: its
      // af-metadata, taps and live updates all key on the label.
      expect(
        audioEffectsChain(const [
          EqualizerEffect(frequency: 100, gain: 3, enabled: false),
          EqualizerEffect(frequency: 8000, gain: -2),
        ]),
        startsWith('@aek_equalizer_1:'),
      );
      expect(
        audioEffectLabels(const [
          EqualizerEffect(enabled: false),
          EqualizerEffect(),
        ]),
        ['aek_equalizer_0', 'aek_equalizer_1'],
      );
    });
  });

  group('RawAudioEffect', () {
    test('goes in verbatim, unlabelled, where it sits in the list', () {
      expect(
        audioEffectsChain(const [
          RawAudioEffect('lavfi-aresample=48000'),
          AcompressorEffect(threshold: 0.1),
          RawAudioEffect('lavfi-pan=mono|c0=c0+c1'),
        ]),
        'lavfi-aresample=48000,'
        '@aek_acompressor_0:lavfi-acompressor=threshold=0.100,'
        'lavfi-pan=mono|c0=c0+c1',
      );
    });

    test('blank or disabled raw stages are dropped', () {
      expect(
        audioEffectsChain(const [
          RawAudioEffect(''),
          RawAudioEffect('   '),
          RawAudioEffect('lavfi-aecho', enabled: false),
          RawAudioEffect('lavfi-volume=2'),
        ]),
        'lavfi-volume=2',
      );
    });

    test('filterName reads the lavfi filter out of the entry', () {
      expect(const RawAudioEffect('lavfi-aeval=val(0)').filterName, 'aeval');
      expect(const RawAudioEffect('aecho').filterName, 'aecho');
      expect(const RawAudioEffect('lavfi-aecho').filter, isNull);
    });
  });

  group('audioEffectsDiff', () {
    test('identical lists → no commands', () {
      const fx = [EqualizerEffect(gain: 3)];
      expect(audioEffectsDiff(fx, fx), isEmpty);
      expect(audioEffectsDiff(fx, const [EqualizerEffect(gain: 3)]), isEmpty);
    });

    test('a runtime-tunable change updates the right instance live', () {
      final cmds = audioEffectsDiff(
        const [EqualizerEffect(gain: 3), EqualizerEffect(gain: -2)],
        const [EqualizerEffect(gain: 3), EqualizerEffect(gain: -4)],
      );
      expect(cmds, isNotNull);
      expect(cmds, hasLength(1));
      expect(cmds!.single.label, 'aek_equalizer_1');
      expect(cmds.single.option, 'gain');
      expect(cmds.single.filterName, 'equalizer');
    });

    test('shape changes need a rebuild', () {
      const a = [EqualizerEffect(), AcompressorEffect()];
      // Added, removed, reordered, toggled.
      expect(audioEffectsDiff(a, const [...a, AlimiterEffect()]), isNull);
      expect(audioEffectsDiff(a, const [EqualizerEffect()]), isNull);
      expect(
        audioEffectsDiff(a, const [AcompressorEffect(), EqualizerEffect()]),
        isNull,
      );
      expect(
        audioEffectsDiff(a, const [
          EqualizerEffect(enabled: false),
          AcompressorEffect(),
        ]),
        isNull,
      );
    });

    test('a changed raw stage needs a rebuild', () {
      expect(
        audioEffectsDiff(
          const [RawAudioEffect('lavfi-volume=2')],
          const [RawAudioEffect('lavfi-volume=3')],
        ),
        isNull,
      );
    });

    test('a disabled stage can change freely without touching the chain', () {
      expect(
        audioEffectsDiff(
          const [EqualizerEffect(enabled: false, gain: 1)],
          const [EqualizerEffect(enabled: false, gain: 5)],
        ),
        isEmpty,
      );
    });
  });

  group('Enum.fromMpv non-throwing fallback', () {
    test('AemphasisType.fromMpv unknown → first member', () {
      expect(AemphasisType.fromMpv('not_a_real_value'), AemphasisType.col);
      expect(AemphasisType.fromMpv(null), AemphasisType.col);
    });

    test('AemphasisType.fromMpv valid → matching member', () {
      expect(AemphasisType.fromMpv('50fm'), AemphasisType.n50fm);
      expect(AemphasisType.fromMpv('cd'), AemphasisType.cd);
    });

    test('mpvValue round-trips through fromMpv for every member', () {
      for (final v in AemphasisType.values) {
        expect(AemphasisType.fromMpv(v.mpvValue), v);
      }
      for (final v in RubberbandPitch.values) {
        expect(RubberbandPitch.fromMpv(v.mpvValue), v);
      }
    });
  });
}
