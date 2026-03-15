// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Audio format parameters as reported by the mpv audio output pipeline.
class AudioParams {
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

  /// The codec identifier (e.g. `"flac"`, `"mp3"`).
  final String? codec;

  /// Descriptive codec name (e.g. `"FLAC (Free Lossless Audio Codec)"`).
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

  /// Creates a copy of this object with the given fields replaced with the new values.
  AudioParams copyWith({
    String? format,
    int? sampleRate,
    String? channels,
    int? channelCount,
    String? hrChannels,
    String? codec,
    String? codecName,
  }) {
    return AudioParams(
      format: format ?? this.format,
      sampleRate: sampleRate ?? this.sampleRate,
      channels: channels ?? this.channels,
      channelCount: channelCount ?? this.channelCount,
      hrChannels: hrChannels ?? this.hrChannels,
      codec: codec ?? this.codec,
      codecName: codecName ?? this.codecName,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioParams &&
          format == other.format &&
          sampleRate == other.sampleRate &&
          channels == other.channels &&
          channelCount == other.channelCount &&
          hrChannels == other.hrChannels &&
          codec == other.codec &&
          codecName == other.codecName;

  @override
  int get hashCode =>
      format.hashCode ^
      sampleRate.hashCode ^
      channels.hashCode ^
      channelCount.hashCode ^
      hrChannels.hashCode ^
      codec.hashCode ^
      codecName.hashCode;

  @override
  String toString() => 'AudioParams('
      'format: $format, '
      'sampleRate: $sampleRate, '
      'channels: $channels, '
      'channelCount: $channelCount, '
      'hrChannels: $hrChannels, '
      'codec: $codec, '
      'codecName: $codecName)';
}
