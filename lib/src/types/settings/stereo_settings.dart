// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'stereo_settings.freezed.dart';

/// Stereo image control: L/R balance + perceived width.
///
/// Wraps libavfilter's `stereotools` filter — the most flexible of
/// ffmpeg's stereo manipulators. [enabled] toggles the stage in the
/// filter chain; the parameters are preserved while disabled.
///
/// [width] = 1.0 leaves the stereo field untouched. Values < 1.0 narrow
/// toward mono (0.0 = full mono mixdown). Values > 1.0 widen via
/// mid-side processing — useful for re-energising flat mixes, but
/// audible artefacts can appear above ~1.5.
///
/// [balance] = 0 is centred. Negative values pan toward the left
/// channel, positive toward the right. Hard range -1 to +1.
@freezed
abstract class StereoSettings with _$StereoSettings {
  const factory StereoSettings({
    /// Whether the stage is inserted into mpv's filter chain. Disabling
    /// preserves the configuration.
    @Default(false) bool enabled,

    /// Stereo width multiplier (mapped to ffmpeg's `slev`). 1.0 =
    /// unchanged, < 1.0 narrows toward mono, > 1.0 widens. ffmpeg
    /// accepts 0.015625–64; musically usable range is roughly 0.0–4.0.
    /// 0.0 collapses to mono. Values above ~2.0 introduce audible
    /// side-channel artefacts.
    @Default(1.0) double width,

    /// Left/right balance (ffmpeg's `balance_in`). 0.0 = centred. Hard
    /// range -1.0 (full left) to +1.0 (full right).
    @Default(0.0) double balance,
  }) = _StereoSettings;
}
