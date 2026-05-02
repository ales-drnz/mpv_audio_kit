// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'pitch_tempo_config.freezed.dart';

/// Pitch / tempo shifter config (librubberband via mpv's `rubberband`
/// filter).
///
/// High-quality time-stretching and pitch-shifting independent of each
/// other. [pitch] = 1.0 keeps original pitch; 2.0 raises one octave;
/// 0.5 lowers one octave. [tempo] = 1.0 keeps original speed; 2.0 plays
/// twice as fast; 0.5 plays half speed. CPU cost is non-trivial vs the
/// default `scaletempo` engine; enable only when the consumer needs the
/// extra quality.
///
/// Note: this is independent of [Player.setRate] (which uses mpv's
/// built-in scaletempo). Combine sparingly to avoid stacking
/// time-stretchers.
///
/// Apply via [Player.setPitchTempo]. Read live via
/// [PlayerStream.pitchTempo] or [PlayerState.pitchTempo].
@freezed
abstract class PitchTempoConfig with _$PitchTempoConfig {
  const factory PitchTempoConfig({
    /// Whether the stage is inserted into mpv's filter chain. Disabling
    /// preserves the configuration.
    @Default(false) bool enabled,

    /// Pitch multiplier. Hard range 0.01–100. Practical sweet spot
    /// 0.25–4.0 (two octaves down to two octaves up). 1.0 = unchanged.
    @Default(1.0) double pitch,

    /// Tempo multiplier. Hard range 0.01–100. Practical sweet spot
    /// 0.25–4.0. 1.0 = unchanged.
    @Default(1.0) double tempo,
  }) = _PitchTempoConfig;
}
