// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Unit tests for `composeAfChain` and `extractCustomFilters` — the
// internal helpers that translate an `AudioEffects` bundle into mpv's
// `--af` string and back. Pin the EXACT output for each effect so a
// renamed parameter (e.g. `mlev` → `slev`) or a missing label is
// caught at unit-test speed without a real libmpv round-trip.
//
// Reference: ffmpeg 7.1.1 libavfilter — bass / treble (af_biquads.c),
// stereotools (af_stereotools.c), bs2b (af_bs2b.c), silenceremove
// (af_silenceremove.c), acompressor / equalizer / rubberband /
// loudnorm / acrossfade.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/audio_filter_chain.dart';

void main() {
  group('composeAfChain — empty / disabled effects', () {
    test('empty bundle → empty string', () {
      expect(composeAfChain(const AudioEffects()), '');
    });

    test('all effects present but disabled → empty string', () {
      final fx = AudioEffects(
        equalizer: const EqualizerSettings(),
        compressor: const CompressorSettings(),
        loudness: const LoudnessSettings(),
        pitchTempo: const PitchTempoSettings(),
        bassTreble: const BassTrebleSettings(),
        stereo: const StereoSettings(),
        crossfeed: const CrossfeedSettings(),
        silenceTrim: const SilenceTrimSettings(),
      );
      expect(composeAfChain(fx), '');
    });

    test('crossfade null → not in chain', () {
      const fx = AudioEffects(crossfade: null);
      expect(composeAfChain(fx), '');
    });

    test('crossfade Duration.zero → not in chain', () {
      const fx = AudioEffects(crossfade: Duration.zero);
      expect(composeAfChain(fx), '');
    });
  });

  group('composeAfChain — per-effect output', () {
    test('compressor enabled emits acompressor with dB threshold', () {
      const fx = AudioEffects(
        compressor: CompressorSettings(
          enabled: true,
          threshold: -24.0,
          ratio: 6.0,
          attack: Duration(milliseconds: 5),
          release: Duration(milliseconds: 200),
        ),
      );
      expect(
        composeAfChain(fx),
        '@_mak_comp:lavfi-acompressor='
        'threshold=-24.000dB:ratio=6.000:attack=5.000:release=200.000',
      );
    });

    test('equalizer enabled emits 10 lavfi-equalizer bands at ISO centres', () {
      final fx = AudioEffects(
        equalizer: EqualizerSettings(
          enabled: true,
          gains: const [3, 2, 1, 0, -1, -2, -3, 0, 2, 4],
        ),
      );
      final af = composeAfChain(fx);
      expect(af.split(',').length, 10);
      expect(af, contains('@_mak_eq:lavfi-equalizer=f=31.25:t=o:w=1:g=3.00'));
      expect(af,
          contains('@_mak_eq:lavfi-equalizer=f=1000.0:t=o:w=1:g=-2.00'));
      expect(af,
          contains('@_mak_eq:lavfi-equalizer=f=16000.0:t=o:w=1:g=4.00'));
    });

    test('bassTreble enabled emits both bass + treble shelves', () {
      const fx = AudioEffects(
        bassTreble: BassTrebleSettings(
          enabled: true,
          bassDb: 4.0,
          bassFrequency: 120.0,
          trebleDb: -2.0,
          trebleFrequency: 5000.0,
        ),
      );
      expect(
        composeAfChain(fx),
        '@_mak_bt:lavfi-bass=g=4.000:f=120.000,'
        '@_mak_bt:lavfi-treble=g=-2.000:f=5000.000',
      );
    });

    test(
        'stereo enabled emits stereotools with slev (NOT mlev) for width — '
        'pinning the post-bug behaviour', () {
      const fx = AudioEffects(
        stereo: StereoSettings(enabled: true, width: 1.5, balance: -0.2),
      );
      final af = composeAfChain(fx);
      expect(af, startsWith('@_mak_st:lavfi-stereotools='));
      expect(af, contains('slev=1.500'));
      expect(af, contains('mlev=1.0')); // middle level pinned at 1
      expect(af, contains('balance_in=-0.200'));
      // Make sure we DIDN'T put width in the wrong slot.
      expect(af, isNot(contains('mlev=1.500')));
    });

    test('crossfeed enabled emits bs2b with the ffmpeg profile token', () {
      const fx = AudioEffects(
        crossfeed: CrossfeedSettings(
          enabled: true,
          intensity: CrossfeedIntensity.jmeier,
        ),
      );
      expect(
        composeAfChain(fx),
        '@_mak_cf:lavfi-bs2b=profile=jmeier',
      );
    });

    test(
        'silenceTrim with both ends enabled emits start_* + stop_* with dB '
        'suffix on threshold', () {
      const fx = AudioEffects(
        silenceTrim: SilenceTrimSettings(
          trimStart: true,
          trimEnd: true,
          thresholdDb: -55.0,
          minDuration: Duration(milliseconds: 300),
        ),
      );
      final af = composeAfChain(fx);
      expect(af, startsWith('@_mak_str:lavfi-silenceremove='));
      expect(af, contains('start_periods=1'));
      expect(af, contains('start_duration=0.300'));
      expect(af, contains('start_threshold=-55.000dB'));
      expect(af, contains('stop_periods=1'));
      expect(af, contains('stop_duration=0.300'));
      expect(af, contains('stop_threshold=-55.000dB'));
    });

    test('silenceTrim with only start emits ONLY the start_* group', () {
      const fx = AudioEffects(
        silenceTrim: SilenceTrimSettings(trimStart: true, trimEnd: false),
      );
      final af = composeAfChain(fx);
      expect(af, contains('start_periods=1'));
      expect(af, isNot(contains('stop_periods=1')));
    });

    test('silenceTrim with only end emits ONLY the stop_* group', () {
      const fx = AudioEffects(
        silenceTrim: SilenceTrimSettings(trimStart: false, trimEnd: true),
      );
      final af = composeAfChain(fx);
      expect(af, isNot(contains('start_periods=1')));
      expect(af, contains('stop_periods=1'));
    });

    test('silenceTrim with both flags off → not in chain', () {
      const fx = AudioEffects(
        silenceTrim: SilenceTrimSettings(),
      );
      expect(composeAfChain(fx), '');
    });

    test('pitchTempo enabled emits rubberband (NOT lavfi-rubberband)', () {
      const fx = AudioEffects(
        pitchTempo: PitchTempoSettings(
          enabled: true,
          pitch: 1.05,
          tempo: 0.95,
        ),
      );
      expect(
        composeAfChain(fx),
        '@_mak_pt:rubberband=pitch=1.050:tempo=0.950',
      );
    });

    test('crossfade non-zero Duration emits acrossfade with seconds', () {
      const fx = AudioEffects(crossfade: Duration(milliseconds: 2500));
      expect(
        composeAfChain(fx),
        '@_mak_xf:lavfi-acrossfade=d=2.500',
      );
    });

    test('loudness enabled emits loudnorm with EBU R128 params', () {
      const fx = AudioEffects(
        loudness: LoudnessSettings(
          enabled: true,
          integratedLoudness: -16.0,
          truePeak: -1.0,
          lra: 7.0,
        ),
      );
      expect(
        composeAfChain(fx),
        '@_mak_loud:lavfi-loudnorm=I=-16.000:TP=-1.000:LRA=7.000',
      );
    });
  });

  group('composeAfChain — order & combinations', () {
    test('chain order: custom → compressor → eq → bassTreble → stereo → '
        'crossfeed → silenceTrim → pitchTempo → crossfade → loudness', () {
      final fx = AudioEffects(
        custom: const ['lavfi-volume=2'],
        compressor: const CompressorSettings(enabled: true),
        equalizer: const EqualizerSettings(enabled: true),
        bassTreble: const BassTrebleSettings(enabled: true),
        stereo: const StereoSettings(enabled: true),
        crossfeed: const CrossfeedSettings(enabled: true),
        silenceTrim: const SilenceTrimSettings(trimStart: true),
        pitchTempo: const PitchTempoSettings(enabled: true),
        crossfade: const Duration(seconds: 1),
        loudness: const LoudnessSettings(enabled: true),
      );
      final entries = composeAfChain(fx).split(',');
      // First entry = the user's custom (no managed prefix).
      expect(entries.first, 'lavfi-volume=2');
      // Find the index of each managed label in the order they appear.
      int firstIndexOf(String label) =>
          entries.indexWhere((e) => e.startsWith('@$label:'));
      final order = [
        '_mak_comp',
        '_mak_eq',
        '_mak_bt',
        '_mak_st',
        '_mak_cf',
        '_mak_str',
        '_mak_pt',
        '_mak_xf',
        '_mak_loud',
      ];
      var prev = -1;
      for (final l in order) {
        final i = firstIndexOf(l);
        expect(i, greaterThan(prev),
            reason: '$l must come after the previous label');
        prev = i;
      }
    });

    test('multiple custom entries preserved in order at the head', () {
      final fx = AudioEffects(
        custom: const ['lavfi-aphaser=type=t', 'lavfi-aecho=0.8:0.5:50:0.4'],
        equalizer: const EqualizerSettings(enabled: true),
      );
      final entries = composeAfChain(fx).split(',');
      expect(entries[0], 'lavfi-aphaser=type=t');
      expect(entries[1], 'lavfi-aecho=0.8:0.5:50:0.4');
      expect(entries[2], startsWith('@_mak_eq:'));
    });

    test('all-default bundle but with crossfade emits ONLY the crossfade', () {
      const fx = AudioEffects(crossfade: Duration(seconds: 2));
      expect(composeAfChain(fx), '@_mak_xf:lavfi-acrossfade=d=2.000');
    });
  });

  group('extractCustomFilters — inverse path', () {
    test('empty af → empty list', () {
      expect(extractCustomFilters(''), const <String>[]);
      expect(extractCustomFilters('   '), const <String>[]);
    });

    test('only managed entries → empty list', () {
      const af =
          '@_mak_eq:lavfi-equalizer=f=1000:t=o:w=1:g=2,@_mak_loud:lavfi-loudnorm=I=-16';
      expect(extractCustomFilters(af), const <String>[]);
    });

    test('only custom entries → all surfaced', () {
      const af = 'lavfi-volume=2,lavfi-aphaser=type=t';
      expect(extractCustomFilters(af),
          ['lavfi-volume=2', 'lavfi-aphaser=type=t']);
    });

    test('mixed: managed entries dropped, custom surfaced', () {
      const af =
          'lavfi-volume=2,@_mak_eq:lavfi-equalizer=f=1000:t=o:w=1:g=2,lavfi-aphaser=type=t,@_mak_loud:lavfi-loudnorm=I=-16';
      expect(extractCustomFilters(af),
          ['lavfi-volume=2', 'lavfi-aphaser=type=t']);
    });

    test('user-labelled (non-reserved) entries are kept as custom', () {
      const af = '@my_label:lavfi-volume=2,@_mak_eq:lavfi-equalizer=f=1000:g=2';
      expect(extractCustomFilters(af), ['@my_label:lavfi-volume=2']);
    });

    test('parens are not split on top-level commas', () {
      const af = 'pan=stereo|c0=c0+c1|c1=c0+c1,@_mak_eq:lavfi-equalizer=f=1000:g=0';
      expect(extractCustomFilters(af), ['pan=stereo|c0=c0+c1|c1=c0+c1']);
    });
  });
}
