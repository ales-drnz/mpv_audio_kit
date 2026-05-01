// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/cover/audio_display_mode.dart';
import 'package:mpv_audio_kit/src/audio/audio_output_state.dart';
import 'package:mpv_audio_kit/src/cover/cover_art_auto_mode.dart';
import 'package:mpv_audio_kit/src/audio/gapless_mode.dart';
import 'package:mpv_audio_kit/src/network/cache_config.dart' show CacheMode;
import 'package:mpv_audio_kit/src/audio/replay_gain_config.dart'
    show ReplayGainMode;

/// Pairs every enum the wrapper exposes via `setX(...)` / `state.X` / mpv
/// property dispatch with its documented fallback variant. The fallback
/// is what the parser returns on an unknown wire value — load-bearing
/// because mpv may ship new option values in any release and we don't
/// want a property change to crash the app.
final _typed = <(List<dynamic>, dynamic Function(String), dynamic, String)>[
  (
    GaplessMode.values,
    GaplessMode.fromMpv,
    GaplessMode.weak,
    'GaplessMode',
  ),
  (
    ReplayGainMode.values,
    ReplayGainMode.fromMpv,
    ReplayGainMode.no,
    'ReplayGainMode',
  ),
  (
    AudioDisplayMode.values,
    AudioDisplayMode.fromMpv,
    AudioDisplayMode.embeddedFirst,
    'AudioDisplayMode',
  ),
  (
    CoverArtAutoMode.values,
    CoverArtAutoMode.fromMpv,
    CoverArtAutoMode.no,
    'CoverArtAutoMode',
  ),
  (
    CacheMode.values,
    CacheMode.fromMpv,
    CacheMode.auto,
    'CacheMode',
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

    test('mpvValue uses kebab-case for multi-word variants', () {
      // Spot-check: kebab-case is the contract for mpv option strings.
      // Single-word variants are uniformly lowercase, no test needed.
      expect(AudioDisplayMode.embeddedFirst.mpvValue, 'embedded-first');
      expect(AudioDisplayMode.externalFirst.mpvValue, 'external-first');
    });
  });
}
