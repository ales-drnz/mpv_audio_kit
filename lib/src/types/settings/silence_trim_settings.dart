// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'silence_trim_settings.freezed.dart';

/// Auto-trim silence at the start and/or end of a track.
///
/// Wraps libavfilter's `silenceremove` filter. Common in podcast and
/// audiobook apps: dead air before the first word and after the last
/// disappears without the consumer needing to seek manually.
///
/// [trimStart] / [trimEnd] gate which side(s) get trimmed. Both off =
/// the stage is not inserted in the chain (equivalent to `enabled =
/// false` on other settings).
///
/// [thresholdDb] is the level below which audio is considered silent.
/// Floor closer to -90 dB to be conservative on noisy recordings;
/// raise toward -40 dB for cleaner studio masters where ambient noise
/// is already low.
@freezed
abstract class SilenceTrimSettings with _$SilenceTrimSettings {
  const factory SilenceTrimSettings({
    /// Trim leading silence (between file start and the first sample
    /// above [thresholdDb]).
    @Default(false) bool trimStart,

    /// Trim trailing silence (after the last sample above [thresholdDb]).
    @Default(false) bool trimEnd,

    /// Silence threshold in dB (passed to ffmpeg's
    /// `start_threshold` / `stop_threshold` with the `dB` unit suffix).
    /// Samples below this level count as silence. Musically usable
    /// range: -90 dB (very conservative) to -20 dB (aggressive).
    @Default(-50.0) double thresholdDb,

    /// Minimum continuous silence duration that counts as "silence" —
    /// briefer gaps are preserved. Maps to ffmpeg's
    /// `start_duration` / `stop_duration`. Default 250 ms (ffmpeg's
    /// own default is 0, i.e. trim any silence regardless of length —
    /// we pick 250 ms because real-world recordings often contain
    /// sub-100 ms quiet moments that should not be removed).
    @Default(Duration(milliseconds: 250)) Duration minDuration,
  }) = _SilenceTrimSettings;
}
