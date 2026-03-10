/// Current player state.
enum PlayerState {
  /// No file loaded, player ready.
  idle,

  /// The file is loading or buffering.
  buffering,

  /// The file is currently playing.
  playing,

  /// Playback is paused.
  paused,

  /// The end of the file has been reached.
  ended,

  /// An error occurred during playback.
  error,
}

/// Information about the currently loaded media file.
class MediaInfo {
  /// Total duration in seconds. `null` if not available (e.g., live streams).
  final double? duration;

  /// Title from ID3 tags or metadata.
  final String? title;

  /// Artist from ID3 tags or metadata.
  final String? artist;

  /// Album from ID3 tags or metadata.
  final String? album;

  /// Year from ID3 tags or metadata.
  final String? year;

  /// Bitrate in kbps if available.
  final int? bitrate;

  /// Sample rate in Hz if available.
  final int? sampleRate;

  /// Number of audio channels.
  final int? channels;

  /// Audio codec (e.g., "mp3", "aac").
  final String? codec;

  const MediaInfo({
    this.duration,
    this.title,
    this.artist,
    this.album,
    this.year,
    this.bitrate,
    this.sampleRate,
    this.channels,
    this.codec,
  });

  @override
  String toString() =>
      'MediaInfo(title: $title, artist: $artist, duration: $duration)';
}

/// Represents an audio output device detected by mpv.
class AudioDevice {
  /// Internal name of the device (useful for `setAudioDevice`).
  final String name;

  /// Human-readable description of the device.
  final String description;

  const AudioDevice({required this.name, required this.description});

  @override
  String toString() => 'AudioDevice($name, $description)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AudioDevice && name == other.name && description == other.description;

  @override
  int get hashCode => name.hashCode ^ description.hashCode;
}

/// Represents an audio filter applied to the mpv pipeline (lavfi/AF).
///
/// Each filter corresponds to a string in mpv's [--af] filter graph.
/// Examples:
/// ```dart
/// AudioFilter.equalizer([0, 0, 6, 0, -3, 0, 0, 0, 3, 0])
/// AudioFilter.custom('loudnorm')
/// AudioFilter.custom('acompressor=threshold=-20dB:ratio=4')
/// ```
class AudioFilter {
  /// The filter string in mpv/libavfilter format.
  final String value;

  const AudioFilter._(this.value);

  /// Custom filter: any valid string for `--af`.
  const AudioFilter.custom(this.value);

  /// 10-band equalizer (gains in dB, standard ISO center frequencies).
  ///
  /// [gains] must have exactly 10 elements corresponding to these bands:
  /// 31.25 Hz, 62.5 Hz, 125 Hz, 250 Hz, 500 Hz, 1 kHz, 2 kHz,
  /// 4 kHz, 8 kHz, 16 kHz.
  factory AudioFilter.equalizer(List<double> gains) {
    assert(gains.length == 10, 'equalizer requires exactly 10 gain values');
    const centers = [31.25, 62.5, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
    final parts = <String>[];
    for (var i = 0; i < 10; i++) {
      final g = gains[i].toStringAsFixed(2);
      // Using lavfi- prefix to ensure these FFmpeg filters are found
      parts.add('lavfi-equalizer=f=${centers[i]}:t=o:w=1:g=$g');
    }
    return AudioFilter._(parts.join(','));
  }

  /// Simple dynamic compressor.
  ///
  /// [threshold] in dB (e.g., -20), [ratio] (e.g., 4), [attack]/[release] in ms.
  factory AudioFilter.compressor({
    double threshold = -20,
    double ratio = 4,
    double attack = 20,
    double release = 250,
  }) {
    return AudioFilter._('lavfi-acompressor=threshold=${threshold}dB'
        ':ratio=$ratio'
        ':attack=$attack'
        ':release=$release');
  }

  /// EBU R128 loudness normalization using `loudnorm`.
  factory AudioFilter.loudnorm({
    double integratedLoudness = -16.0,
    double truePeak = -1.5,
    double lra = 11.0,
  }) {
    return AudioFilter._(
        'lavfi-loudnorm=I=$integratedLoudness:TP=$truePeak:LRA=$lra');
  }

  /// Pitch/tempo shift using Rubberband (if available in the mpv build).
  ///
  /// [pitch] is a factor (1.0 = original, 2.0 = octave up).
  /// [tempo] is a factor (1.0 = original, 0.5 = half speed).
  factory AudioFilter.scaleTempo({double pitch = 1.0, double tempo = 1.0}) {
    return AudioFilter._('rubberband=pitch=$pitch:tempo=$tempo');
  }



  /// Simple Echo/Reverb effect.
  /// [delay] in ms, [falloff] decay factor (0.0-1.0).
  factory AudioFilter.echo({int delay = 200, double falloff = 0.4}) {
    return AudioFilter._('lavfi-aecho=0.8:0.8:$delay:$falloff');
  }

  /// Stereo width expansion (ExtraStereo).
  /// [m] expansion factor (default 2.0).
  factory AudioFilter.extraStereo({double m = 2.0}) {
    return AudioFilter._('lavfi-extrastereo=m=$m');
  }

  /// Crystalizer: emphasizes harmonic details (lavfi).
  factory AudioFilter.crystalizer({double intensity = 2.0}) {
    return AudioFilter._('lavfi-crystalizer=i=$intensity');
  }

  @override
  String toString() => 'AudioFilter($value)';
}

/// Initial configuration for the player.
class PlayerConfig {
  /// If `true`, playback starts automatically after loading.
  final bool autoPlay;

  /// Initial volume level (0–100).
  final double initialVolume;

  /// mpv log level to redirect to the Dart logger.
  /// Valid values: 'no', 'fatal', 'error', 'warn', 'info', 'v', 'debug', 'trace'.
  final String logLevel;

  /// Preferred audio output driver for mpv's `--ao`.
  /// `null` = use mpv's default (recommended).
  final String? audioOutput;

  const PlayerConfig({
    this.autoPlay = false,
    this.initialVolume = 100.0,
    this.logLevel = 'warn',
    this.audioOutput,
  });
}
