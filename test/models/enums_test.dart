// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/types/state/audio_output_state.dart';
import 'package:mpv_audio_kit/src/types/enums/cover.dart';
import 'package:mpv_audio_kit/src/types/enums/gapless.dart';
import 'package:mpv_audio_kit/src/types/enums/cache.dart';
import 'package:mpv_audio_kit/src/types/enums/replay_gain.dart';

/// Pairs every enum the wrapper exposes via `setX(...)` / `state.X` / mpv
/// property dispatch with its documented fallback variant. The fallback
/// is what the parser returns on an unknown wire value — load-bearing
/// because mpv may ship new option values in any release and we don't
/// want a property change to crash the app.
final _typed = <(List<dynamic>, dynamic Function(String), dynamic, String)>[
  (
    Gapless.values,
    Gapless.fromMpv,
    Gapless.weak,
    'Gapless',
  ),
  (
    ReplayGain.values,
    ReplayGain.fromMpv,
    ReplayGain.no,
    'ReplayGain',
  ),
  (
    Cover.values,
    Cover.fromMpv,
    Cover.no,
    'Cover',
  ),
  (
    Cache.values,
    Cache.fromMpv,
    Cache.auto,
    'Cache',
  ),
  (
    AudioOutputState.values,
    AudioOutputState.fromMpv,
    AudioOutputState.closed,
    'AudioOutputState',
  ),
];

void main() {
  group('Enum wire-format contract', () {
    test('round-trip fromMpv ↔ mpvValue is identity for every variant', () {
      for (final (variants, fromMpv, _, name) in _typed) {
        for (final v in variants) {
          // Each enum has a `mpvValue` getter via its const constructor.
          final wire = (v as dynamic).mpvValue as String;
          expect(fromMpv(wire), v, reason: '$name: $v round-trip');
        }
      }
    });

    test('unknown values fall back to the documented default variant', () {
      for (final (_, fromMpv, fallback, name) in _typed) {
        expect(fromMpv('totally-bogus-${name.toLowerCase()}'), fallback,
            reason: '$name fallback');
        expect(fromMpv(''), fallback, reason: '$name empty fallback');
      }
    });
  });
}
