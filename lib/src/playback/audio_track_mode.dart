// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_track_mode.freezed.dart';

/// How [Player.setAudioTrack] should resolve mpv's `aid` property.
///
/// Sealed (rather than `enum`) because the [AudioTrackMode.id] variant
/// carries an `int` payload that enums cannot model. Every other
/// `*Mode` in the package is a plain enum; this one follows the same
/// naming convention but uses Freezed-generated sealed variants — so
/// equality, hashCode, and toString are derived automatically and
/// stay in sync with the variants.
@freezed
sealed class AudioTrackMode with _$AudioTrackMode {
  const AudioTrackMode._();

  /// Defer to mpv's automatic track choice (the container's
  /// default-flagged track, or the first audio track if none is
  /// flagged). Equivalent to mpv's `aid=auto`.
  const factory AudioTrackMode.auto() = AudioTrackModeAuto;

  /// Disable audio output entirely. Equivalent to mpv's `aid=no`.
  /// Useful for files where the consumer wants only metadata / cover
  /// art without playing audio.
  const factory AudioTrackMode.off() = AudioTrackModeOff;

  /// Select the audio track with the given mpv [trackId]. IDs match
  /// `MpvTrack.id` entries in `PlayerState.tracks`.
  const factory AudioTrackMode.id(int trackId) = AudioTrackModeId;

  /// The wire-level string mpv expects for the `aid` property.
  String get mpvValue => switch (this) {
        AudioTrackModeAuto() => 'auto',
        AudioTrackModeOff() => 'no',
        AudioTrackModeId(:final trackId) => trackId.toString(),
      };
}
