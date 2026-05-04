// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

const _Unset _unset = _Unset();

class _Unset {
  const _Unset();
}

/// Audio format parameters reported by mpv. Used both for the decoder
/// side (`audio-params` + `audio-codec*`) and for the hardware output
/// side (`audio-out-params`).
final class AudioParams {
  /// Sample format string (e.g. `"floatp"`, `"s16"`).
  final String? format;

  /// Sample rate in Hz.
  final int? sampleRate;

  /// Channel layout string in mpv notation (e.g. `"stereo"`, `"5.1"`).
  final String? channels;

  /// Number of audio channels.
  final int? channelCount;

  /// Human-readable channel layout description.
  final String? hrChannels;

  /// Raw value of mpv's `audio-codec` property. The exact form
  /// (short id vs descriptive name) varies by mpv build and codec
  /// (`mp3` vs `mp3float`, `aac` vs `aac_lc`, `FLAC` vs
  /// `FLAC (Free Lossless Audio Codec)`); treat as an opaque hint.
  /// For reliable codec-family matching, do a case-insensitive
  /// substring check against BOTH [codec] and [codecName].
  final String? codec;

  /// Raw value of mpv's `audio-codec-name` property. Same volatility
  /// caveat as [codec] — the short/descriptive split is not stable
  /// across mpv versions, and one of the two may be absent on a
  /// given file.
  final String? codecName;

  const AudioParams({
    this.format,
    this.sampleRate,
    this.channels,
    this.channelCount,
    this.hrChannels,
    this.codec,
    this.codecName,
  });

  AudioParams copyWith({
    Object? format = _unset,
    Object? sampleRate = _unset,
    Object? channels = _unset,
    Object? channelCount = _unset,
    Object? hrChannels = _unset,
    Object? codec = _unset,
    Object? codecName = _unset,
  }) =>
      AudioParams(
        format: identical(format, _unset) ? this.format : format as String?,
        sampleRate: identical(sampleRate, _unset)
            ? this.sampleRate
            : sampleRate as int?,
        channels:
            identical(channels, _unset) ? this.channels : channels as String?,
        channelCount: identical(channelCount, _unset)
            ? this.channelCount
            : channelCount as int?,
        hrChannels: identical(hrChannels, _unset)
            ? this.hrChannels
            : hrChannels as String?,
        codec: identical(codec, _unset) ? this.codec : codec as String?,
        codecName: identical(codecName, _unset)
            ? this.codecName
            : codecName as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioParams &&
          other.format == format &&
          other.sampleRate == sampleRate &&
          other.channels == channels &&
          other.channelCount == channelCount &&
          other.hrChannels == hrChannels &&
          other.codec == codec &&
          other.codecName == codecName);

  @override
  int get hashCode => Object.hash(
        format,
        sampleRate,
        channels,
        channelCount,
        hrChannels,
        codec,
        codecName,
      );

  @override
  String toString() => 'AudioParams(format: $format, sampleRate: $sampleRate, '
      'channels: $channels, channelCount: $channelCount, '
      'hrChannels: $hrChannels, codec: $codec, codecName: $codecName)';
}
