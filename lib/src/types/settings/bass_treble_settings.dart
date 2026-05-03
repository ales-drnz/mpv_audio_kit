// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'bass_treble_settings.freezed.dart';

/// Two-band tone-control config: low-shelf bass + high-shelf treble.
///
/// Wraps libavfilter's `bass` and `treble` shelving EQs in a single
/// stage. [enabled] toggles the pair in the filter chain; the parameters
/// are preserved while disabled.
///
/// Bands are independent — set [bassDb] to 0 to bypass the low-shelf
/// while still applying the treble shelf, and vice-versa. Combining
/// with [EqualizerSettings] is fine: the 10-band EQ runs in series
/// after the tone control.
@freezed
abstract class BassTrebleSettings with _$BassTrebleSettings {
  const factory BassTrebleSettings({
    /// Whether the stage is inserted into mpv's filter chain. Disabling
    /// preserves the configuration.
    @Default(false) bool enabled,

    /// Bass shelf gain in dB. ffmpeg accepts -900 to +900; musically
    /// usable range is roughly -20 to +20 dB. 0 = bypass the bass band.
    @Default(0.0) double bassDb,

    /// Bass shelf cutoff frequency in Hz. Frequencies below this point
    /// are boosted/cut by [bassDb]. ffmpeg accepts 0–999999 Hz; typical
    /// range 80–250 Hz. Default 100 Hz matches ffmpeg's `bass` default.
    @Default(100.0) double bassFrequency,

    /// Treble shelf gain in dB. ffmpeg accepts -900 to +900; musically
    /// usable range is roughly -20 to +20 dB. 0 = bypass the treble
    /// band.
    @Default(0.0) double trebleDb,

    /// Treble shelf cutoff frequency in Hz. Frequencies above this point
    /// are boosted/cut by [trebleDb]. ffmpeg accepts 0–999999 Hz;
    /// typical range 3000–8000 Hz. Default 3000 Hz matches ffmpeg's
    /// `treble` default.
    @Default(3000.0) double trebleFrequency,
  }) = _BassTrebleSettings;
}
