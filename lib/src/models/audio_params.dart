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

  const AudioParams({
    this.format,
    this.sampleRate,
    this.channels,
    this.channelCount,
    this.hrChannels,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioParams &&
          format == other.format &&
          sampleRate == other.sampleRate &&
          channels == other.channels &&
          channelCount == other.channelCount &&
          hrChannels == other.hrChannels;

  @override
  int get hashCode =>
      format.hashCode ^
      sampleRate.hashCode ^
      channels.hashCode ^
      channelCount.hashCode ^
      hrChannels.hashCode;

  @override
  String toString() => 'AudioParams('
      'format: $format, '
      'sampleRate: $sampleRate, '
      'channels: $channels, '
      'channelCount: $channelCount, '
      'hrChannels: $hrChannels)';
}
