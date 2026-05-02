// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:mpv_audio_kit/src/types/enums/replay_gain.dart';

part 'replay_gain_settings.freezed.dart';

/// Aggregate of mpv's four ReplayGain properties (`replaygain`,
/// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`).
///
/// Apply atomically via [Player.setReplayGain]. For one-off tweaks
/// use `state.replayGain.copyWith(preamp: -3)`. Read the current
/// configuration via [PlayerState.replayGain] or observe live changes
/// via [PlayerStream.replayGain].
@freezed
abstract class ReplayGainSettings with _$ReplayGainSettings {
  const factory ReplayGainSettings({
    /// Normalization mode (off / per-track / per-album).
    @Default(ReplayGain.no) ReplayGain mode,

    /// Pre-amplification in dB applied before normalization.
    @Default(0.0) double preamp,

    /// Whether to allow output clipping when normalizing loud tracks.
    @Default(false) bool clip,

    /// Gain in dB applied to files without ReplayGain tags.
    @Default(0.0) double fallback,
  }) = _ReplayGainSettings;
}
