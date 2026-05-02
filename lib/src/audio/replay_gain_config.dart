// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'replay_gain_config.freezed.dart';

/// ReplayGain normalization mode, mirroring `--replaygain=<no|track|album>`.
enum ReplayGainMode {
  /// Disabled — no normalization.
  no('no'),

  /// Per-track ReplayGain.
  track('track'),

  /// Per-album ReplayGain. Useful for cohesive albums where inter-track
  /// dynamics matter.
  album('album');

  const ReplayGainMode(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [no].
  static ReplayGainMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'track' => track,
        'album' => album,
        _ => no,
      };
}

/// Aggregate of mpv's four ReplayGain properties (`replaygain`,
/// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`).
///
/// Apply atomically via [Player.setReplayGain]. For one-off tweaks
/// use `state.replayGain.copyWith(preamp: -3)`. Read the current
/// configuration via [PlayerState.replayGain] or observe live changes
/// via [PlayerStream.replayGain].
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
