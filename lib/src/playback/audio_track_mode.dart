// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// How [Player.setAudioTrack] should resolve mpv's `aid` property.
///
/// Sealed (rather than `enum`) because the [AudioTrackMode.id] variant
/// carries a payload Dart enums cannot model. The dominant pattern in
/// the rest of the package uses an `enum` with a `mpvValue` getter; this
/// type follows the same shape — `mpvValue` returns the string mpv
/// expects on the wire — but switches on `sealed` instead of enum
/// variants for exhaustiveness.
sealed class AudioTrackMode {
  const AudioTrackMode._();

  /// Defer to mpv's automatic track choice (the container's
  /// default-flagged track, or the first audio track if none is
  /// flagged). Equivalent to mpv's `aid=auto`.
  const factory AudioTrackMode.auto() = _AudioTrackAuto;

  /// Disable audio output entirely. Equivalent to mpv's `aid=no`.
  /// Useful for files where the consumer wants only metadata / cover
  /// art without playing audio.
  const factory AudioTrackMode.off() = _AudioTrackOff;

  /// Select the audio track with the given mpv [trackId]. IDs match
  /// `MpvTrack.id` entries in `PlayerState.tracks`.
  const factory AudioTrackMode.id(int trackId) = _AudioTrackId;

  /// The wire-level string mpv expects for the `aid` property.
  String get mpvValue => switch (this) {
        _AudioTrackAuto() => 'auto',
        _AudioTrackOff() => 'no',
        _AudioTrackId(:final trackId) => trackId.toString(),
      };
}

class _AudioTrackAuto extends AudioTrackMode {
  const _AudioTrackAuto() : super._();
  @override
  bool operator ==(Object other) => other is _AudioTrackAuto;
  @override
  int get hashCode => 0xa55ec707;
  @override
  String toString() => 'AudioTrackMode.auto()';
}

class _AudioTrackOff extends AudioTrackMode {
  const _AudioTrackOff() : super._();
  @override
  bool operator ==(Object other) => other is _AudioTrackOff;
  @override
  int get hashCode => 0x0ff;
  @override
  String toString() => 'AudioTrackMode.off()';
}

class _AudioTrackId extends AudioTrackMode {
  const _AudioTrackId(this.trackId) : super._();
  final int trackId;
  @override
  bool operator ==(Object other) =>
      other is _AudioTrackId && other.trackId == trackId;
  @override
  int get hashCode => trackId.hashCode;
  @override
  String toString() => 'AudioTrackMode.id($trackId)';
}
