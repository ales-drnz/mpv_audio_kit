// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// An audio filter applied to the mpv filter graph (`--af`).
///
/// Filters use mpv's libavfilter notation. Named constructors cover the most
/// common use-cases; for anything else use [AudioFilter.custom].
///
/// ```dart
/// // 10-band EQ with a + 6 dB boost at 1 kHz:
/// AudioFilter.equalizer([0, 0, 0, 0, 0, 6, 0, 0, 0, 0])
///
/// // Loud-norm for radio / podcast streams:
/// AudioFilter.loudnorm()
///
/// // Raw string, any valid mpv --af value:
/// AudioFilter.custom('lavfi-aresample=48000')
/// ```
class AudioFilter {
  /// The raw filter string passed to mpv's `--af` option.
  final String value;

  const AudioFilter._(this.value);

  /// Any valid string for mpv's `--af` option.
  const AudioFilter.custom(this.value);

  // ── Named presets ────────────────────────────────────────────────────────

  /// 10-band graphic equalizer using ISO standard center frequencies.
  ///
  /// [gains] must have exactly 10 elements (dB, positive = boost):
  /// 31.25 Hz, 62.5 Hz, 125 Hz, 250 Hz, 500 Hz,
  /// 1 kHz, 2 kHz, 4 kHz, 8 kHz, 16 kHz.
  factory AudioFilter.equalizer(List<double> gains) {
    if (gains.length != 10) {
      throw ArgumentError.value(
          gains.length, 'gains', 'equalizer requires exactly 10 gain values');
    }
    const centers = [
      31.25,
      62.5,
      125.0,
      250.0,
      500.0,
      1000.0,
      2000.0,
      4000.0,
      8000.0,
      16000.0
    ];
    final parts = <String>[];
    for (var i = 0; i < 10; i++) {
      final g = gains[i].toStringAsFixed(2);
      parts.add('lavfi-equalizer=f=${centers[i]}:t=o:w=1:g=$g');
    }
    return AudioFilter._(parts.join(','));
  }

  /// Dynamic range compressor.
  ///
  /// - [threshold] — onset level in dB (e.g. `-20`).
  /// - [ratio] — compression ratio (e.g. `4` means 4:1).
  /// - [attack] / [release] — timing in milliseconds.
  factory AudioFilter.compressor({
    double threshold = -20,
    double ratio = 4,
    double attack = 20,
    double release = 250,
  }) {
    return AudioFilter._('lavfi-acompressor='
        'threshold=${threshold}dB'
        ':ratio=$ratio'
        ':attack=$attack'
        ':release=$release');
  }

  /// EBU R128 loudness normalization.
  ///
  /// - [integratedLoudness] — target LUFS (default: `-16`).
  /// - [truePeak] — maximum true-peak level in dBTP (default: `-1.5`).
  /// - [lra] — loudness range target in LU (default: `11`).
  factory AudioFilter.loudnorm({
    double integratedLoudness = -16.0,
    double truePeak = -1.5,
    double lra = 11.0,
  }) {
    return AudioFilter._(
        'lavfi-loudnorm=I=$integratedLoudness:TP=$truePeak:LRA=$lra');
  }

  /// Pitch / tempo shift via Rubberband (requires a Rubberband-enabled build).
  ///
  /// - [pitch] — pitch factor (1.0 = original, 2.0 = one octave up).
  /// - [tempo] — tempo factor (1.0 = original, 0.5 = half speed).
  factory AudioFilter.scaleTempo({double pitch = 1.0, double tempo = 1.0}) {
    return AudioFilter._('rubberband=pitch=$pitch:tempo=$tempo');
  }

  /// Simple delay / echo effect.
  ///
  /// - [delay] — delay in milliseconds.
  /// - [falloff] — decay factor (0.0–1.0).
  factory AudioFilter.echo({int delay = 200, double falloff = 0.4}) {
    return AudioFilter._('lavfi-aecho=0.8:0.8:$delay:$falloff');
  }

  /// Stereo width expansion using ExtraStereo.
  ///
  /// [m] — expansion factor (default `2.0`; `1.0` = no change, `0.0` = mono).
  factory AudioFilter.extraStereo({double m = 2.0}) {
    return AudioFilter._('lavfi-extrastereo=m=$m');
  }

  /// Crystalizer — emphasizes harmonic details and transients.
  ///
  /// [intensity] — effect intensity (default `2.0`).
  factory AudioFilter.crystalizer({double intensity = 2.0}) {
    return AudioFilter._('lavfi-crystalizer=i=$intensity');
  }

  /// Crossfeed — simulates loudspeakers on headphones for reduced listening fatigue.
  ///
  /// Uses libavfilter's crossfeed DSP to bridge the stereo image.
  factory AudioFilter.crossfeed() {
    return AudioFilter._('lavfi-crossfeed');
  }

  @override
  String toString() => 'AudioFilter($value)';
}
