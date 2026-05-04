// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Unit tests for `AudioEffects.toAfChain()` — the wire-output side of
// the auto-generated DSP bundle. Pin the EXACT chain string for a few
// representative filters so a renamed AVOption (e.g. ffmpeg upstream
// drops `slev` from stereotools) or an enum mpvValue regression is
// caught at unit-test speed without a real libmpv round-trip.
//
// Per-filter wire correctness (every parameter, every default) is
// covered by ffmpeg upstream's own AVOption tests; this file checks
// the codegen contract: typed enums round-trip via `mpvValue`,
// digit-prefix params route through `Map<String, T> params`,
// disabled stages drop out, the chain joins with `,`, and defaults
// are NOT emitted.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('AudioEffects.toAfChain — empty / disabled', () {
    test('empty bundle → empty string', () {
      expect(const AudioEffects().toAfChain(), '');
    });

    test('every Settings disabled → empty string', () {
      const fx = AudioEffects(
        acompressor: AcompressorSettings(),
        loudnorm: LoudnormSettings(),
        rubberband: RubberbandSettings(),
      );
      expect(fx.toAfChain(), '');
    });

    test('default-valued enabled stage emits bare filter name', () {
      const fx = AudioEffects(acompressor: AcompressorSettings(enabled: true));
      // No params differ from ffmpeg defaults → `lavfi-acompressor` only.
      expect(fx.toAfChain(), 'lavfi-acompressor');
    });
  });

  group('AudioEffects.toAfChain — per-filter wire output', () {
    test('acompressor non-default params land in the chain', () {
      const fx = AudioEffects(
        acompressor: AcompressorSettings(
          enabled: true,
          threshold: 0.1,
          ratio: 6.0,
        ),
      );
      // Defaults (level_in=1, attack=20, release=250, ...) MUST NOT show
      // up — only the modified fields. Order = alphabetical (the
      // codegen iterates the schema's params dict in sorted order).
      final af = fx.toAfChain();
      expect(af, startsWith('lavfi-acompressor='));
      expect(af, contains('threshold=0.100'));
      expect(af, contains('ratio=6.000'));
      expect(af, isNot(contains('level_in')));
      expect(af, isNot(contains('attack')));
    });

    test('loudnorm enabled with EBU R128 targets', () {
      // ffmpeg defaults: I=-24, TP=-2, LRA=7. We pick non-default values
      // so they all surface in the wire output.
      const fx = AudioEffects(
        loudnorm: LoudnormSettings(
          enabled: true,
          I: -16.0,
          TP: -1.0,
          LRA: 11.0,
        ),
      );
      final af = fx.toAfChain();
      expect(af, contains('I=-16.000'));
      expect(af, contains('TP=-1.000'));
      expect(af, contains('LRA=11.000'));
    });

    test('rubberband enabled with typed enum + numeric params', () {
      // The C source uses `{.i64=0}` for pitchq's default — but the
      // CONST entries reference symbols (`RubberBandOptionPitchHigh*`)
      // we cannot resolve at gen time, so the codegen falls back to
      // the first member as the @Default. `quality` happens to be
      // first; we pick `speed` for a guaranteed non-default value.
      // Same trick for `transients` (first member is `crisp`).
      const fx = AudioEffects(
        rubberband: RubberbandSettings(
          enabled: true,
          tempo: 0.95,
          pitchq: RubberbandPitch.speed,
          transients: RubberbandTransients.smooth,
        ),
      );
      // Enums emit via `mpvValue` (the exact ffmpeg CONST name), NOT
      // their integer index.
      final af = fx.toAfChain();
      expect(af, startsWith('lavfi-rubberband='));
      expect(af, contains('tempo=0.950'));
      expect(af, contains('pitchq=speed'));
      expect(af, contains('transients=smooth'));
    });

    test('aemphasis with typed enum default → omitted from chain', () {
      const fx = AudioEffects(
        aemphasis: AemphasisSettings(enabled: true, type: AemphasisType.cd),
      );
      // `type=cd` is the ffmpeg default, so it must NOT be emitted.
      expect(fx.toAfChain(), 'lavfi-aemphasis');
    });

    test('aemphasis with non-default enum → mpvValue in chain', () {
      const fx = AudioEffects(
        aemphasis: AemphasisSettings(
          enabled: true,
          type: AemphasisType.n50fm,
        ),
      );
      // The Dart member is `n50fm` (digit-prefix escaped); the wire
      // value is the raw ffmpeg name `50fm`.
      expect(fx.toAfChain(), 'lavfi-aemphasis=type=50fm');
    });

    test('superequalizer routes digit-prefix bands through `params` map', () {
      const fx = AudioEffects(
        superequalizer: SuperequalizerSettings(
          enabled: true,
          params: {'1b': 1.5, '5b': 0.8, '10b': 1.2, '18b': 0.5},
        ),
      );
      final af = fx.toAfChain();
      expect(af, startsWith('lavfi-superequalizer='));
      expect(af, contains('1b=1.500'));
      expect(af, contains('5b=0.800'));
      expect(af, contains('10b=1.200'));
      expect(af, contains('18b=0.500'));
    });
  });

  group('AudioEffects.toAfChain — custom raw passthroughs', () {
    test('custom entries emit verbatim at the head of the chain', () {
      const fx = AudioEffects(
        custom: ['lavfi-aeval=val(0)|val(1)', 'lavfi-pan=mono|c0=c0+c1'],
      );
      // Custom only — no typed stage enabled.
      expect(
        fx.toAfChain(),
        'lavfi-aeval=val(0)|val(1),lavfi-pan=mono|c0=c0+c1',
      );
    });

    test('custom precedes the typed rack', () {
      const fx = AudioEffects(
        custom: ['lavfi-aresample=48000'],
        acompressor: AcompressorSettings(enabled: true, threshold: 0.1),
      );
      final entries = fx.toAfChain().split(',');
      expect(entries.first, 'lavfi-aresample=48000');
      expect(entries.last, 'lavfi-acompressor=threshold=0.100');
    });

    test('empty / whitespace custom entries are dropped', () {
      const fx = AudioEffects(custom: ['', '   ', 'lavfi-volume=2']);
      expect(fx.toAfChain(), 'lavfi-volume=2');
    });
  });

  group('AudioEffects.toAfChain — chaining order', () {
    test('multiple enabled filters joined with `,` in declaration order', () {
      const fx = AudioEffects(
        acompressor: AcompressorSettings(enabled: true),
        loudnorm: LoudnormSettings(enabled: true),
        rubberband: RubberbandSettings(enabled: true, tempo: 0.9),
      );
      final entries = fx.toAfChain().split(',');
      expect(entries, hasLength(3));
      // AVOption-array order: acompressor < loudnorm < rubberband
      // (alphabetical by filter name in the bundle's declaration).
      expect(entries[0], 'lavfi-acompressor');
      expect(entries[1], 'lavfi-loudnorm');
      expect(entries[2], 'lavfi-rubberband=tempo=0.900');
    });

    test('disabled stages do NOT show up between enabled ones', () {
      const fx = AudioEffects(
        acompressor: AcompressorSettings(enabled: true),
        // aemphasis disabled (default) — must not appear.
        loudnorm: LoudnormSettings(enabled: true),
      );
      expect(fx.toAfChain(), 'lavfi-acompressor,lavfi-loudnorm');
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
