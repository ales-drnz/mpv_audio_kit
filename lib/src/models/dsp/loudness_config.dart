// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'loudness_config.freezed.dart';

/// EBU R128 loudness normalization config (libavfilter `loudnorm`).
///
/// Targets a consistent perceived loudness across mixed-source playback
/// (broadcast, podcast, mixed-album streams). Operates in single-pass
/// mode under mpv. [enabled] toggles the filter in the chain; the
/// parameters are preserved while disabled.
///
/// Apply via [Player.setLoudness]. Read live via
/// [PlayerStream.loudness] or [PlayerState.loudness].
@freezed
abstract class LoudnessConfig with _$LoudnessConfig {
  const factory LoudnessConfig({
    @Default(false) bool enabled,

    /// Integrated loudness target in LUFS. Common values: -23 (EBU R128
    /// broadcast), -16 (typical streaming target), -14 (loud streaming
    /// target). Range: -70 to -5.
    @Default(-16.0) double integratedLoudness,

    /// Maximum true-peak level in dBTP. Range: -9 to 0.
    @Default(-1.5) double truePeak,

    /// Loudness range target in LU. Range: 1 to 50.
    @Default(11.0) double lra,
  }) = _LoudnessConfig;
}
