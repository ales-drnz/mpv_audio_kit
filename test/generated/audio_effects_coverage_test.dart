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
// The cases are data, in _audio_effects_coverage_cases.dart; this file runs them.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/generated/audio_effects_settings.dart'
    show audioEffectsChain;

part '_audio_effects_coverage_cases.dart';

void main() {
  group('Per-filter wire coverage', () {
    for (final f in _filters) {
      group('${f.cls} (${f.name})', () {
        final label = '@aek_${f.name}_0:lavfi-${f.name}';
        test('disabled → drops out of the chain', () {
          expect(audioEffectsChain([f.disabled]), '');
        });

        if (f.required.isEmpty) {
          test('enabled with every param at default → bare lavfi name', () {
            expect(audioEffectsChain([f.enabled]), label);
          });
        } else {
          test('enabled with required params → wire carries the filter name '
              'and required options', () {
            expect(audioEffectsChain([f.enabled]), startsWith(label));
            for (final p in f.required) {
              expect(audioEffectsChain([f.enabled]), contains('$p='));
            }
          });
        }

        for (final (param, effect, wire) in f.wire) {
          test(
            'param `$param` lands in wire when set to a non-default value',
            () {
              expect(effect.toFilterString(), contains(wire));
            },
          );
        }

        for (final (param, bound, effect) in f.bounds) {
          test(
            'param `$param` const `$bound` is accepted by toFilterString',
            () {
              expect(effect.toFilterString, returnsNormally);
            },
          );
        }

        for (final (param, effect, wire) in f.digits) {
          test('digit-prefix param `$param` lands in wire via params map', () {
            expect(effect.toFilterString(), contains(wire));
          });
        }
      });
    }
  });

  group('Per-enum round-trip coverage', () {
    for (final e in _enums) {
      group('${e.name} (codegen enum)', e.run);
    }
  });
}
