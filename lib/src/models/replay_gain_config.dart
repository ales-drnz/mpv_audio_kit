// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'replay_gain_config.freezed.dart';

/// Aggregate of mpv's four ReplayGain properties.
///
/// Useful when restoring a saved preset or applying a complete change
/// in one shot via [Player.setReplayGain] — the wrapper writes the
/// four backing properties (`replaygain`, `replaygain-preamp`,
/// `replaygain-clip`, `replaygain-fallback`) atomically.
///
/// For one-off tweaks, modify a single field via
/// `state.replayGain.copyWith(preamp: -3)` and pass the result to
/// [Player.setReplayGain].
///
/// Read the current configuration via [PlayerState.replayGain] or
/// observe live changes via [PlayerStream.replayGain].
@freezed
abstract class ReplayGainConfig with _$ReplayGainConfig {
  const factory ReplayGainConfig({
    /// Normalization mode (off / per-track / per-album).
    @Default(ReplayGainMode.no) ReplayGainMode mode,

    /// Pre-amplification in dB applied before normalization.
    @Default(0.0) double preamp,

    /// Whether to allow output clipping when normalizing loud tracks.
    @Default(false) bool clip,

    /// Gain in dB applied to files without ReplayGain tags.
    @Default(0.0) double fallback,
  }) = _ReplayGainConfig;
}
