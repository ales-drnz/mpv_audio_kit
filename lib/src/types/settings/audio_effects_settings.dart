// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED — do not edit by hand.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures

import '../enums/audio_effects.dart';

// Sentinel used by every per-filter copyWith() to tell
// "not passed" apart from "explicitly set to null". Lets the
// consumer reset a nullable field to null via copyWith without
// having to reconstruct the whole Settings.
class _Unset {
  const _Unset();
}

const _Unset _unset = _Unset();

// Collection equality helpers used by the generated `==`. Kept
// inline to avoid a transitive `package:collection` dependency.
bool _setEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Configuration for the `abench` audio effect.
///
/// Benchmark part of a filtergraph.
///
/// The filter accepts the following options:
final class AbenchSettings {
  final bool enabled;

  const AbenchSettings({
    this.enabled = false,
  });

  AbenchSettings copyWith({
    bool? enabled,
  }) =>
      AbenchSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AbenchSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AbenchSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-abench';
  }
}

/// Configuration for the `acompressor` audio effect.
///
/// A compressor is mainly used to reduce the dynamic range of a signal.
/// Especially modern music is mostly compressed at a high ratio to
/// improve the overall loudness. It's done to get the highest attention
/// of a listener, "fatten" the sound and bring more "power" to the track.
/// If a signal is compressed too much it may sound dull or "dead"
/// afterwards or it may start to "pump" (which could be a powerful effect
/// but can also destroy a track completely).
/// The right compression is the key to reach a professional sound and is
/// the high art of mixing and mastering. Because of its complex settings
/// it may take a long time to get the right feeling for this kind of effect.
///
/// Compression is done by detecting the volume above a chosen level
/// `threshold` and dividing it by the factor set with `ratio`.
/// So if you set the threshold to -12dB and your signal reaches -6dB a ratio
/// of 2:1 will result in a signal at -9dB. Because an exact manipulation of
/// the signal would cause distortion of the waveform the reduction can be
/// levelled over the time. This is done by setting "Attack" and "Release".
/// `attack` determines how long the signal has to rise above the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to fall below the threshold to reduce the reduction again. Shorter signals
/// than the chosen attack time will be left untouched.
/// The overall reduction of the signal can be made up afterwards with the
/// `makeup` setting. So compressing the peaks of a signal about 6dB and
/// raising the makeup to this level results in a signal twice as loud than the
/// source. To gain a softer entry in the compression the `knee` flattens the
/// hard edge at the threshold in the range of the chosen decibels.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction starts. Default is 20. Range is between 0.01 and 2000. (range 0.01..2000, default 20)
/// - [detection]: Should the exact signal be taken in case of `peak` or an RMS one in case of `rms`. Default is `rms` which is mostly smoother. (range 0..1, default 1)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.82843. Range is between 1 and 8. (range 1..8, default 2.82843)
/// - [level_in]: Set input gain. Default is 1. Range is between 0.015625 and 64. (range 0.015625..64, default 1)
/// - [level_sc]: set sidechain gain (range 0.015625..64, default 1)
/// - [link]: Choose if the `average` level between all channels of input stream or the louder(`maximum`) channel of input stream affects the reduction. Default is `average`. (range 0..1, default 0)
/// - [makeup]: Set the amount by how much signal will be amplified after processing. Default is 1. Range is from 1 to 64. (range 1..64, default 1)
/// - [mix]: How much to use compressed signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1)
/// - [mode]: Set mode of compressor operation. Can be `upward` or `downward`. Default is `downward`. (range 0..1, default 0)
/// - [ratio]: Set a ratio by which the signal is reduced. 1:2 means that if the level rose 4dB above the threshold, it will be only 2dB above after the reduction. Default is 2. Range is between 1 and 20. (range 1..20, default 2)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before reduction is decreased again. Default is 250. Range is between 0.01 and 9000. (range 0.01..9000, default 250)
/// - [threshold]: If a signal of stream rises above this level it will affect the gain reduction. By default it is 0.125. Range is between 0.00097563 and 1. (range 0.000976563..1, default 0.125)
final class AcompressorSettings {
  final bool enabled;
  final double attack;
  final AcompressorDetection detection;
  final double knee;
  final double level_in;
  final double level_sc;
  final AcompressorLink link;
  final double makeup;
  final double mix;
  final AcompressorMode mode;
  final double ratio;
  final double release;
  final double threshold;

  const AcompressorSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.detection = AcompressorDetection.rms,
    this.knee = 2.82843,
    this.level_in = 1.0,
    this.level_sc = 1.0,
    this.link = AcompressorLink.average,
    this.makeup = 1.0,
    this.mix = 1.0,
    this.mode = AcompressorMode.downward,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  AcompressorSettings copyWith({
    bool? enabled,
    double? attack,
    AcompressorDetection? detection,
    double? knee,
    double? level_in,
    double? level_sc,
    AcompressorLink? link,
    double? makeup,
    double? mix,
    AcompressorMode? mode,
    double? ratio,
    double? release,
    double? threshold,
  }) =>
      AcompressorSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        detection: detection ?? this.detection,
        knee: knee ?? this.knee,
        level_in: level_in ?? this.level_in,
        level_sc: level_sc ?? this.level_sc,
        link: link ?? this.link,
        makeup: makeup ?? this.makeup,
        mix: mix ?? this.mix,
        mode: mode ?? this.mode,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcompressorSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.level_in == level_in &&
          other.level_sc == level_sc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mix == mix &&
          other.mode == mode &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(enabled, attack, detection, knee, level_in,
      level_sc, link, makeup, mix, mode, ratio, release, threshold);

  @override
  String toString() =>
      'AcompressorSettings(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, level_in: $level_in, level_sc: $level_sc, link: $link, makeup: $makeup, mix: $mix, mode: $mode, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= 0.01, 'acompressor.attack must be >= 0.01');
    assert(attack <= 2000, 'acompressor.attack must be <= 2000');
    assert(knee >= 1, 'acompressor.knee must be >= 1');
    assert(knee <= 8, 'acompressor.knee must be <= 8');
    assert(level_in >= 0.015625, 'acompressor.level_in must be >= 0.015625');
    assert(level_in <= 64, 'acompressor.level_in must be <= 64');
    assert(level_sc >= 0.015625, 'acompressor.level_sc must be >= 0.015625');
    assert(level_sc <= 64, 'acompressor.level_sc must be <= 64');
    assert(makeup >= 1, 'acompressor.makeup must be >= 1');
    assert(makeup <= 64, 'acompressor.makeup must be <= 64');
    assert(mix >= 0, 'acompressor.mix must be >= 0');
    assert(mix <= 1, 'acompressor.mix must be <= 1');
    assert(ratio >= 1, 'acompressor.ratio must be >= 1');
    assert(ratio <= 20, 'acompressor.ratio must be <= 20');
    assert(release >= 0.01, 'acompressor.release must be >= 0.01');
    assert(release <= 9000, 'acompressor.release must be <= 9000');
    assert(threshold >= 0.000976563,
        'acompressor.threshold must be >= 0.000976563');
    assert(threshold <= 1, 'acompressor.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + attack.toStringAsFixed(3));
    if (detection != AcompressorDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.82843) parts.add('knee=' + knee.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_sc != 1.0) parts.add('level_sc=' + level_sc.toStringAsFixed(3));
    if (link != AcompressorLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + makeup.toStringAsFixed(3));
    if (mix != 1.0) parts.add('mix=' + mix.toStringAsFixed(3));
    if (mode != AcompressorMode.downward) parts.add('mode=' + mode.mpvValue);
    if (ratio != 2.0) parts.add('ratio=' + ratio.toStringAsFixed(3));
    if (release != 250.0) parts.add('release=' + release.toStringAsFixed(3));
    if (threshold != 0.125)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-acompressor'
        : 'lavfi-acompressor=' + parts.join(':');
  }
}

/// Configuration for the `acontrast` audio effect.
///
/// Simple audio dynamic range compression/expansion filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [contrast]: Set contrast. Default is 33. Allowed range is between 0 and 100. (range 0..100, default 33)
final class AcontrastSettings {
  final bool enabled;
  final double contrast;

  const AcontrastSettings({
    this.enabled = false,
    this.contrast = 33.0,
  });

  AcontrastSettings copyWith({
    bool? enabled,
    double? contrast,
  }) =>
      AcontrastSettings(
        enabled: enabled ?? this.enabled,
        contrast: contrast ?? this.contrast,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcontrastSettings &&
          other.enabled == enabled &&
          other.contrast == contrast);

  @override
  int get hashCode => Object.hash(enabled, contrast);

  @override
  String toString() =>
      'AcontrastSettings(enabled: $enabled, contrast: $contrast)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(contrast >= 0, 'acontrast.contrast must be >= 0');
    assert(contrast <= 100, 'acontrast.contrast must be <= 100');
    final parts = <String>[];
    if (contrast != 33.0) parts.add('contrast=' + contrast.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-acontrast'
        : 'lavfi-acontrast=' + parts.join(':');
  }
}

/// Configuration for the `acopy` audio effect.
///
/// Copy the input audio source unchanged to the output. This is mainly useful for
/// testing purposes.
final class AcopySettings {
  final bool enabled;

  const AcopySettings({
    this.enabled = false,
  });

  AcopySettings copyWith({
    bool? enabled,
  }) =>
      AcopySettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcopySettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AcopySettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-acopy';
  }
}

/// Configuration for the `acrusher` audio effect.
///
/// Reduce audio bit resolution.
///
/// This filter is bit crusher with enhanced functionality. A bit crusher
/// is used to audibly reduce number of bits an audio signal is sampled
/// with. This doesn't change the bit depth at all, it just produces the
/// effect. Material reduced in bit depth sounds more harsh and "digital".
/// This filter is able to even round to continuous values instead of discrete
/// bit depths.
/// Additionally it has a D/C offset which results in different crushing of
/// the lower and the upper half of the signal.
/// An Anti-Aliasing setting is able to produce "softer" crushing sounds.
///
/// Another feature of this filter is the logarithmic mode.
/// This setting switches from linear distances between bits to logarithmic ones.
/// The result is a much more "natural" sounding crusher which doesn't gate low
/// signals for example. The human ear has a logarithmic perception,
/// so this kind of crushing is much more pleasant.
/// Logarithmic crushing is also able to get anti-aliased.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [aa]: Set anti-aliasing. (range 0..1, default .5)
/// - [bits]: Set bit reduction. (range 1..64, default 8)
/// - [dc]: Set DC. (default 1)
/// - [level_in]: Set level in. (range 0.015625..64, default 1)
/// - [level_out]: Set level out. (range 0.015625..64, default 1)
/// - [lfo]: Enable LFO. By default disabled. (range 0..1, default 0)
/// - [lforange]: Set LFO range. (range 1..250, default 20)
/// - [lforate]: Set LFO rate. (default .3)
/// - [mix]: Set mixing amount. (range 0..1, default .5)
/// - [mode]: Can be linear: `lin` or logarithmic: `log`. (range 0..1, default 0)
/// - [samples]: Set sample reduction. (range 1..250, default 1)
final class AcrusherSettings {
  final bool enabled;
  final double aa;
  final double bits;
  final double dc;
  final double level_in;
  final double level_out;
  final bool lfo;
  final double lforange;
  final double lforate;
  final double mix;
  final AcrusherMode mode;
  final double samples;

  const AcrusherSettings({
    this.enabled = false,
    this.aa = .5,
    this.bits = 8.0,
    this.dc = 1.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.lfo = false,
    this.lforange = 20.0,
    this.lforate = .3,
    this.mix = .5,
    this.mode = AcrusherMode.lin,
    this.samples = 1.0,
  });

  AcrusherSettings copyWith({
    bool? enabled,
    double? aa,
    double? bits,
    double? dc,
    double? level_in,
    double? level_out,
    bool? lfo,
    double? lforange,
    double? lforate,
    double? mix,
    AcrusherMode? mode,
    double? samples,
  }) =>
      AcrusherSettings(
        enabled: enabled ?? this.enabled,
        aa: aa ?? this.aa,
        bits: bits ?? this.bits,
        dc: dc ?? this.dc,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        lfo: lfo ?? this.lfo,
        lforange: lforange ?? this.lforange,
        lforate: lforate ?? this.lforate,
        mix: mix ?? this.mix,
        mode: mode ?? this.mode,
        samples: samples ?? this.samples,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcrusherSettings &&
          other.enabled == enabled &&
          other.aa == aa &&
          other.bits == bits &&
          other.dc == dc &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.lfo == lfo &&
          other.lforange == lforange &&
          other.lforate == lforate &&
          other.mix == mix &&
          other.mode == mode &&
          other.samples == samples);

  @override
  int get hashCode => Object.hash(enabled, aa, bits, dc, level_in, level_out,
      lfo, lforange, lforate, mix, mode, samples);

  @override
  String toString() =>
      'AcrusherSettings(enabled: $enabled, aa: $aa, bits: $bits, dc: $dc, level_in: $level_in, level_out: $level_out, lfo: $lfo, lforange: $lforange, lforate: $lforate, mix: $mix, mode: $mode, samples: $samples)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(aa >= 0, 'acrusher.aa must be >= 0');
    assert(aa <= 1, 'acrusher.aa must be <= 1');
    assert(bits >= 1, 'acrusher.bits must be >= 1');
    assert(bits <= 64, 'acrusher.bits must be <= 64');
    assert(level_in >= 0.015625, 'acrusher.level_in must be >= 0.015625');
    assert(level_in <= 64, 'acrusher.level_in must be <= 64');
    assert(level_out >= 0.015625, 'acrusher.level_out must be >= 0.015625');
    assert(level_out <= 64, 'acrusher.level_out must be <= 64');
    assert(lforange >= 1, 'acrusher.lforange must be >= 1');
    assert(lforange <= 250, 'acrusher.lforange must be <= 250');
    assert(mix >= 0, 'acrusher.mix must be >= 0');
    assert(mix <= 1, 'acrusher.mix must be <= 1');
    assert(samples >= 1, 'acrusher.samples must be >= 1');
    assert(samples <= 250, 'acrusher.samples must be <= 250');
    final parts = <String>[];
    if (aa != .5) parts.add('aa=' + aa.toStringAsFixed(3));
    if (bits != 8.0) parts.add('bits=' + bits.toStringAsFixed(3));
    if (dc != 1.0) parts.add('dc=' + dc.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (lfo != false) parts.add('lfo=' + (lfo ? '1' : '0'));
    if (lforange != 20.0) parts.add('lforange=' + lforange.toStringAsFixed(3));
    if (lforate != .3) parts.add('lforate=' + lforate.toStringAsFixed(3));
    if (mix != .5) parts.add('mix=' + mix.toStringAsFixed(3));
    if (mode != AcrusherMode.lin) parts.add('mode=' + mode.mpvValue);
    if (samples != 1.0) parts.add('samples=' + samples.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-acrusher'
        : 'lavfi-acrusher=' + parts.join(':');
  }
}

/// Configuration for the `acue` audio effect.
///
/// Delay audio filtering until a given wallclock timestamp. See the cue
/// filter.
///
/// Parameters:
/// - [buffer]: buffer duration in seconds (default 0)
/// - [preroll]: preroll duration in seconds (default 0)
final class AcueSettings {
  final bool enabled;
  final Duration buffer;
  final Duration preroll;

  const AcueSettings({
    this.enabled = false,
    this.buffer = const Duration(microseconds: 0),
    this.preroll = const Duration(microseconds: 0),
  });

  AcueSettings copyWith({
    bool? enabled,
    Duration? buffer,
    Duration? preroll,
  }) =>
      AcueSettings(
        enabled: enabled ?? this.enabled,
        buffer: buffer ?? this.buffer,
        preroll: preroll ?? this.preroll,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcueSettings &&
          other.enabled == enabled &&
          other.buffer == buffer &&
          other.preroll == preroll);

  @override
  int get hashCode => Object.hash(enabled, buffer, preroll);

  @override
  String toString() =>
      'AcueSettings(enabled: $enabled, buffer: $buffer, preroll: $preroll)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (buffer != const Duration(microseconds: 0))
      parts.add('buffer=' + (buffer.inMicroseconds / 1e6).toStringAsFixed(3));
    if (preroll != const Duration(microseconds: 0))
      parts.add('preroll=' + (preroll.inMicroseconds / 1e6).toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-acue' : 'lavfi-acue=' + parts.join(':');
  }
}

/// Configuration for the `adeclick` audio effect.
///
/// Remove impulsive noise from input audio.
///
/// Samples detected as impulsive noise are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [a]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [b]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [burst]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [m]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [o]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [t]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [w]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclickSettings {
  final bool enabled;
  final double a;
  final double arorder;
  final double b;
  final double burst;
  final AdeclickM m;
  final AdeclickM method;
  final double o;
  final double overlap;
  final double t;
  final double threshold;
  final double w;
  final double window;

  const AdeclickSettings({
    this.enabled = false,
    this.a = 2.0,
    this.arorder = 2.0,
    this.b = 2.0,
    this.burst = 2.0,
    this.m = AdeclickM.add,
    this.method = AdeclickM.add,
    this.o = 75.0,
    this.overlap = 75.0,
    this.t = 2.0,
    this.threshold = 2.0,
    this.w = 55.0,
    this.window = 55.0,
  });

  AdeclickSettings copyWith({
    bool? enabled,
    double? a,
    double? arorder,
    double? b,
    double? burst,
    AdeclickM? m,
    AdeclickM? method,
    double? o,
    double? overlap,
    double? t,
    double? threshold,
    double? w,
    double? window,
  }) =>
      AdeclickSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        arorder: arorder ?? this.arorder,
        b: b ?? this.b,
        burst: burst ?? this.burst,
        m: m ?? this.m,
        method: method ?? this.method,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
        w: w ?? this.w,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclickSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.arorder == arorder &&
          other.b == b &&
          other.burst == burst &&
          other.m == m &&
          other.method == method &&
          other.o == o &&
          other.overlap == overlap &&
          other.t == t &&
          other.threshold == threshold &&
          other.w == w &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, a, arorder, b, burst, m, method, o,
      overlap, t, threshold, w, window);

  @override
  String toString() =>
      'AdeclickSettings(enabled: $enabled, a: $a, arorder: $arorder, b: $b, burst: $burst, m: $m, method: $method, o: $o, overlap: $overlap, t: $t, threshold: $threshold, w: $w, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(a >= 0, 'adeclick.a must be >= 0');
    assert(a <= 25, 'adeclick.a must be <= 25');
    assert(arorder >= 0, 'adeclick.arorder must be >= 0');
    assert(arorder <= 25, 'adeclick.arorder must be <= 25');
    assert(b >= 0, 'adeclick.b must be >= 0');
    assert(b <= 10, 'adeclick.b must be <= 10');
    assert(burst >= 0, 'adeclick.burst must be >= 0');
    assert(burst <= 10, 'adeclick.burst must be <= 10');
    assert(o >= 50, 'adeclick.o must be >= 50');
    assert(o <= 95, 'adeclick.o must be <= 95');
    assert(overlap >= 50, 'adeclick.overlap must be >= 50');
    assert(overlap <= 95, 'adeclick.overlap must be <= 95');
    assert(t >= 1, 'adeclick.t must be >= 1');
    assert(t <= 100, 'adeclick.t must be <= 100');
    assert(threshold >= 1, 'adeclick.threshold must be >= 1');
    assert(threshold <= 100, 'adeclick.threshold must be <= 100');
    assert(w >= 10, 'adeclick.w must be >= 10');
    assert(w <= 100, 'adeclick.w must be <= 100');
    assert(window >= 10, 'adeclick.window must be >= 10');
    assert(window <= 100, 'adeclick.window must be <= 100');
    final parts = <String>[];
    if (a != 2.0) parts.add('a=' + a.toStringAsFixed(3));
    if (arorder != 2.0) parts.add('arorder=' + arorder.toStringAsFixed(3));
    if (b != 2.0) parts.add('b=' + b.toStringAsFixed(3));
    if (burst != 2.0) parts.add('burst=' + burst.toStringAsFixed(3));
    if (m != AdeclickM.add) parts.add('m=' + m.mpvValue);
    if (method != AdeclickM.add) parts.add('method=' + method.mpvValue);
    if (o != 75.0) parts.add('o=' + o.toStringAsFixed(3));
    if (overlap != 75.0) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (t != 2.0) parts.add('t=' + t.toStringAsFixed(3));
    if (threshold != 2.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    if (w != 55.0) parts.add('w=' + w.toStringAsFixed(3));
    if (window != 55.0) parts.add('window=' + window.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-adeclick'
        : 'lavfi-adeclick=' + parts.join(':');
  }
}

/// Configuration for the `adeclip` audio effect.
///
/// Remove clipped samples from input audio.
///
/// Samples detected as clipped are replaced by interpolated samples using
/// autoregressive modelling.
///
/// Parameters:
/// - [a]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [hsize]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [m]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [n]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [o]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [t]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [w]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclipSettings {
  final bool enabled;
  final double a;
  final double arorder;
  final int hsize;
  final AdeclipM m;
  final AdeclipM method;
  final int n;
  final double o;
  final double overlap;
  final double t;
  final double threshold;
  final double w;
  final double window;

  const AdeclipSettings({
    this.enabled = false,
    this.a = 8.0,
    this.arorder = 8.0,
    this.hsize = 1000,
    this.m = AdeclipM.add,
    this.method = AdeclipM.add,
    this.n = 1000,
    this.o = 75.0,
    this.overlap = 75.0,
    this.t = 10.0,
    this.threshold = 10.0,
    this.w = 55.0,
    this.window = 55.0,
  });

  AdeclipSettings copyWith({
    bool? enabled,
    double? a,
    double? arorder,
    int? hsize,
    AdeclipM? m,
    AdeclipM? method,
    int? n,
    double? o,
    double? overlap,
    double? t,
    double? threshold,
    double? w,
    double? window,
  }) =>
      AdeclipSettings(
        enabled: enabled ?? this.enabled,
        a: a ?? this.a,
        arorder: arorder ?? this.arorder,
        hsize: hsize ?? this.hsize,
        m: m ?? this.m,
        method: method ?? this.method,
        n: n ?? this.n,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
        w: w ?? this.w,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclipSettings &&
          other.enabled == enabled &&
          other.a == a &&
          other.arorder == arorder &&
          other.hsize == hsize &&
          other.m == m &&
          other.method == method &&
          other.n == n &&
          other.o == o &&
          other.overlap == overlap &&
          other.t == t &&
          other.threshold == threshold &&
          other.w == w &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, a, arorder, hsize, m, method, n, o,
      overlap, t, threshold, w, window);

  @override
  String toString() =>
      'AdeclipSettings(enabled: $enabled, a: $a, arorder: $arorder, hsize: $hsize, m: $m, method: $method, n: $n, o: $o, overlap: $overlap, t: $t, threshold: $threshold, w: $w, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(a >= 0, 'adeclip.a must be >= 0');
    assert(a <= 25, 'adeclip.a must be <= 25');
    assert(arorder >= 0, 'adeclip.arorder must be >= 0');
    assert(arorder <= 25, 'adeclip.arorder must be <= 25');
    assert(hsize >= 100, 'adeclip.hsize must be >= 100');
    assert(hsize <= 9999, 'adeclip.hsize must be <= 9999');
    assert(n >= 100, 'adeclip.n must be >= 100');
    assert(n <= 9999, 'adeclip.n must be <= 9999');
    assert(o >= 50, 'adeclip.o must be >= 50');
    assert(o <= 95, 'adeclip.o must be <= 95');
    assert(overlap >= 50, 'adeclip.overlap must be >= 50');
    assert(overlap <= 95, 'adeclip.overlap must be <= 95');
    assert(t >= 1, 'adeclip.t must be >= 1');
    assert(t <= 100, 'adeclip.t must be <= 100');
    assert(threshold >= 1, 'adeclip.threshold must be >= 1');
    assert(threshold <= 100, 'adeclip.threshold must be <= 100');
    assert(w >= 10, 'adeclip.w must be >= 10');
    assert(w <= 100, 'adeclip.w must be <= 100');
    assert(window >= 10, 'adeclip.window must be >= 10');
    assert(window <= 100, 'adeclip.window must be <= 100');
    final parts = <String>[];
    if (a != 8.0) parts.add('a=' + a.toStringAsFixed(3));
    if (arorder != 8.0) parts.add('arorder=' + arorder.toStringAsFixed(3));
    if (hsize != 1000) parts.add('hsize=' + hsize.toString());
    if (m != AdeclipM.add) parts.add('m=' + m.mpvValue);
    if (method != AdeclipM.add) parts.add('method=' + method.mpvValue);
    if (n != 1000) parts.add('n=' + n.toString());
    if (o != 75.0) parts.add('o=' + o.toStringAsFixed(3));
    if (overlap != 75.0) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (t != 10.0) parts.add('t=' + t.toStringAsFixed(3));
    if (threshold != 10.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    if (w != 55.0) parts.add('w=' + w.toStringAsFixed(3));
    if (window != 55.0) parts.add('window=' + window.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-adeclip' : 'lavfi-adeclip=' + parts.join(':');
  }
}

/// Configuration for the `adecorrelate` audio effect.
///
/// Apply decorrelation to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [stages]: Set decorrelation stages of filtering. Allowed range is from 1 to 16. Default value is 6. (default 6)
final class AdecorrelateSettings {
  final bool enabled;
  final int stages;

  const AdecorrelateSettings({
    this.enabled = false,
    this.stages = 6,
  });

  AdecorrelateSettings copyWith({
    bool? enabled,
    int? stages,
  }) =>
      AdecorrelateSettings(
        enabled: enabled ?? this.enabled,
        stages: stages ?? this.stages,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdecorrelateSettings &&
          other.enabled == enabled &&
          other.stages == stages);

  @override
  int get hashCode => Object.hash(enabled, stages);

  @override
  String toString() =>
      'AdecorrelateSettings(enabled: $enabled, stages: $stages)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(stages >= 1, 'adecorrelate.stages must be >= 1');
    final parts = <String>[];
    if (stages != 6) parts.add('stages=' + stages.toString());
    return parts.isEmpty
        ? 'lavfi-adecorrelate'
        : 'lavfi-adecorrelate=' + parts.join(':');
  }
}

/// Configuration for the `adelay` audio effect.
///
/// Delay one or more audio channels.
///
/// Samples in delayed channel are filled with silence.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [all]: Use last set delay for all remaining channels. By default is disabled. This option if enabled changes how option `delays` is interpreted. (range 0..1, default 0)
/// - [delays]: Set list of delays in milliseconds for each channel separated by '|'. Unused delays will be silently ignored. If number of given delays is smaller than number of channels all remaining channels will not be delayed. If you want to delay exact number of samples, append 'S' to number. If you want instead to delay in seconds, append 's' to number. (range 0..0)
final class AdelaySettings {
  final bool enabled;
  final bool all;
  final String? delays;

  const AdelaySettings({
    this.enabled = false,
    this.all = false,
    this.delays,
  });

  AdelaySettings copyWith({
    bool? enabled,
    bool? all,
    Object? delays = _unset,
  }) =>
      AdelaySettings(
        enabled: enabled ?? this.enabled,
        all: all ?? this.all,
        delays: identical(delays, _unset) ? this.delays : delays as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdelaySettings &&
          other.enabled == enabled &&
          other.all == all &&
          other.delays == delays);

  @override
  int get hashCode => Object.hash(enabled, all, delays);

  @override
  String toString() =>
      'AdelaySettings(enabled: $enabled, all: $all, delays: $delays)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (all != false) parts.add('all=' + (all ? '1' : '0'));
    if (delays != null) parts.add('delays=' + delays!);
    return parts.isEmpty ? 'lavfi-adelay' : 'lavfi-adelay=' + parts.join(':');
  }
}

/// Configuration for the `adenorm` audio effect.
///
/// Remedy denormals in audio by adding extremely low-level noise.
///
/// This filter shall be placed before any filter that can produce denormals.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [level]: Set level of added noise in dB. Default is `-351`. Allowed range is from -451 to -90. (range -451..-90, default -351)
/// - [type]: Set type of added noise.
final class AdenormSettings {
  final bool enabled;
  final double level;
  final AdenormType? type;

  const AdenormSettings({
    this.enabled = false,
    this.level = -351.0,
    this.type,
  });

  AdenormSettings copyWith({
    bool? enabled,
    double? level,
    Object? type = _unset,
  }) =>
      AdenormSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        type: identical(type, _unset) ? this.type : type as AdenormType?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdenormSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level, type);

  @override
  String toString() =>
      'AdenormSettings(enabled: $enabled, level: $level, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= -451, 'adenorm.level must be >= -451');
    assert(level <= -90, 'adenorm.level must be <= -90');
    final parts = <String>[];
    if (level != -351.0) parts.add('level=' + level.toStringAsFixed(3));
    if (type != null) parts.add('type=' + type!.mpvValue);
    return parts.isEmpty ? 'lavfi-adenorm' : 'lavfi-adenorm=' + parts.join(':');
  }
}

/// Configuration for the `aderivative` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AderivativeSettings {
  final bool enabled;

  const AderivativeSettings({
    this.enabled = false,
  });

  AderivativeSettings copyWith({
    bool? enabled,
  }) =>
      AderivativeSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AderivativeSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AderivativeSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aderivative';
  }
}

/// Configuration for the `adrc` audio effect.
///
/// Apply spectral dynamic range controller filter to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the attack in milliseconds. Default is `50` milliseconds. Allowed range is from 1 to 1000 milliseconds. (range 1..1000, default 50.)
/// - [channels]: Set which channels to filter, by default `all` channels in audio stream are filtered. (range 0..0, default "all")
/// - [release]: Set the release in milliseconds. Default is `100` milliseconds. Allowed range is from 5 to 2000 milliseconds. (range 5..2000, default 100.)
/// - [transfer]: Set the transfer expression.  The expression can contain the following constants: (range 0..0, default "p")
final class AdrcSettings {
  final bool enabled;
  final double attack;
  final String channels;
  final double release;
  final String transfer;

  const AdrcSettings({
    this.enabled = false,
    this.attack = 50.0,
    this.channels = 'all',
    this.release = 100.0,
    this.transfer = 'p',
  });

  AdrcSettings copyWith({
    bool? enabled,
    double? attack,
    String? channels,
    double? release,
    String? transfer,
  }) =>
      AdrcSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        channels: channels ?? this.channels,
        release: release ?? this.release,
        transfer: transfer ?? this.transfer,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdrcSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.channels == channels &&
          other.release == release &&
          other.transfer == transfer);

  @override
  int get hashCode => Object.hash(enabled, attack, channels, release, transfer);

  @override
  String toString() =>
      'AdrcSettings(enabled: $enabled, attack: $attack, channels: $channels, release: $release, transfer: $transfer)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= 1, 'adrc.attack must be >= 1');
    assert(attack <= 1000, 'adrc.attack must be <= 1000');
    assert(release >= 5, 'adrc.release must be >= 5');
    assert(release <= 2000, 'adrc.release must be <= 2000');
    final parts = <String>[];
    if (attack != 50.0) parts.add('attack=' + attack.toStringAsFixed(3));
    if (channels != 'all') parts.add('channels=' + channels);
    if (release != 100.0) parts.add('release=' + release.toStringAsFixed(3));
    if (transfer != 'p') parts.add('transfer=' + transfer);
    return parts.isEmpty ? 'lavfi-adrc' : 'lavfi-adrc=' + parts.join(':');
  }
}

/// Configuration for the `adynamicequalizer` audio effect.
///
/// Apply dynamic equalization to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the amount of milliseconds the signal from detection has to rise above the detection threshold before equalization starts. Default is 20. Allowed range is between 1 and 2000. (range 0.01..2000, default 20)
/// - [auto]: set auto threshold
/// - [dfrequency]: Set the detection frequency in Hz used for detection filter used to trigger equalization. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000)
/// - [dftype]: set detection filter type (range 0..3, default 0)
/// - [dqfactor]: Set the detection resonance factor for detection filter used to trigger equalization. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1)
/// - [makeup]: Set the makeup offset by which the equalization gain is raised. Default is 0. Allowed range is between 0 and 100. (range 0..1000, default 0)
/// - [mode]: Set the mode of filter operation, can be one of the following: (default 0)
/// - [precision]: set processing precision (range 0..2, default 0)
/// - [range]: Set the max allowed cut/boost amount. Default is 50. Allowed range is from 1 to 200. (range 1..2000, default 50)
/// - [ratio]: Set the ratio by which the equalization gain is raised. Default is 1. Allowed range is between 0 and 30. (range 0..30, default 1)
/// - [release]: Set the amount of milliseconds the signal from detection has to fall below the detection threshold before equalization ends. Default is 200. Allowed range is between 1 and 2000. (range 0.01..2000, default 200)
/// - [tfrequency]: Set the target frequency of equalization filter. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000)
/// - [tftype]: set target filter type (range 0..2, default 0)
/// - [threshold]: Set the detection threshold used to trigger equalization. Threshold detection is using detection filter. Default value is 0. Allowed range is from 0 to 100. (range 0..100, default 0)
/// - [tqfactor]: Set the target resonance factor for target equalization filter. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1)
final class AdynamicequalizerSettings {
  final bool enabled;
  final double attack;
  final AdynamicequalizerAuto? auto;
  final double dfrequency;
  final AdynamicequalizerDftype dftype;
  final double dqfactor;
  final double makeup;
  final AdynamicequalizerMode mode;
  final AdynamicequalizerPrecision precision;
  final double range;
  final double ratio;
  final double release;
  final double tfrequency;
  final AdynamicequalizerTftype tftype;
  final double threshold;
  final double tqfactor;

  const AdynamicequalizerSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.auto,
    this.dfrequency = 1000.0,
    this.dftype = AdynamicequalizerDftype.bandpass,
    this.dqfactor = 1.0,
    this.makeup = 0.0,
    this.mode = AdynamicequalizerMode.listen,
    this.precision = AdynamicequalizerPrecision.auto,
    this.range = 50.0,
    this.ratio = 1.0,
    this.release = 200.0,
    this.tfrequency = 1000.0,
    this.tftype = AdynamicequalizerTftype.bell,
    this.threshold = 0.0,
    this.tqfactor = 1.0,
  });

  AdynamicequalizerSettings copyWith({
    bool? enabled,
    double? attack,
    Object? auto = _unset,
    double? dfrequency,
    AdynamicequalizerDftype? dftype,
    double? dqfactor,
    double? makeup,
    AdynamicequalizerMode? mode,
    AdynamicequalizerPrecision? precision,
    double? range,
    double? ratio,
    double? release,
    double? tfrequency,
    AdynamicequalizerTftype? tftype,
    double? threshold,
    double? tqfactor,
  }) =>
      AdynamicequalizerSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        auto: identical(auto, _unset)
            ? this.auto
            : auto as AdynamicequalizerAuto?,
        dfrequency: dfrequency ?? this.dfrequency,
        dftype: dftype ?? this.dftype,
        dqfactor: dqfactor ?? this.dqfactor,
        makeup: makeup ?? this.makeup,
        mode: mode ?? this.mode,
        precision: precision ?? this.precision,
        range: range ?? this.range,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        tfrequency: tfrequency ?? this.tfrequency,
        tftype: tftype ?? this.tftype,
        threshold: threshold ?? this.threshold,
        tqfactor: tqfactor ?? this.tqfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicequalizerSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.auto == auto &&
          other.dfrequency == dfrequency &&
          other.dftype == dftype &&
          other.dqfactor == dqfactor &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.precision == precision &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.tfrequency == tfrequency &&
          other.tftype == tftype &&
          other.threshold == threshold &&
          other.tqfactor == tqfactor);

  @override
  int get hashCode => Object.hash(
      enabled,
      attack,
      auto,
      dfrequency,
      dftype,
      dqfactor,
      makeup,
      mode,
      precision,
      range,
      ratio,
      release,
      tfrequency,
      tftype,
      threshold,
      tqfactor);

  @override
  String toString() =>
      'AdynamicequalizerSettings(enabled: $enabled, attack: $attack, auto: $auto, dfrequency: $dfrequency, dftype: $dftype, dqfactor: $dqfactor, makeup: $makeup, mode: $mode, precision: $precision, range: $range, ratio: $ratio, release: $release, tfrequency: $tfrequency, tftype: $tftype, threshold: $threshold, tqfactor: $tqfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= 0.01, 'adynamicequalizer.attack must be >= 0.01');
    assert(attack <= 2000, 'adynamicequalizer.attack must be <= 2000');
    assert(dfrequency >= 2, 'adynamicequalizer.dfrequency must be >= 2');
    assert(dfrequency <= 1000000,
        'adynamicequalizer.dfrequency must be <= 1000000');
    assert(dqfactor >= 0.001, 'adynamicequalizer.dqfactor must be >= 0.001');
    assert(dqfactor <= 1000, 'adynamicequalizer.dqfactor must be <= 1000');
    assert(makeup >= 0, 'adynamicequalizer.makeup must be >= 0');
    assert(makeup <= 1000, 'adynamicequalizer.makeup must be <= 1000');
    assert(range >= 1, 'adynamicequalizer.range must be >= 1');
    assert(range <= 2000, 'adynamicequalizer.range must be <= 2000');
    assert(ratio >= 0, 'adynamicequalizer.ratio must be >= 0');
    assert(ratio <= 30, 'adynamicequalizer.ratio must be <= 30');
    assert(release >= 0.01, 'adynamicequalizer.release must be >= 0.01');
    assert(release <= 2000, 'adynamicequalizer.release must be <= 2000');
    assert(tfrequency >= 2, 'adynamicequalizer.tfrequency must be >= 2');
    assert(tfrequency <= 1000000,
        'adynamicequalizer.tfrequency must be <= 1000000');
    assert(threshold >= 0, 'adynamicequalizer.threshold must be >= 0');
    assert(threshold <= 100, 'adynamicequalizer.threshold must be <= 100');
    assert(tqfactor >= 0.001, 'adynamicequalizer.tqfactor must be >= 0.001');
    assert(tqfactor <= 1000, 'adynamicequalizer.tqfactor must be <= 1000');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + attack.toStringAsFixed(3));
    if (auto != null) parts.add('auto=' + auto!.mpvValue);
    if (dfrequency != 1000.0)
      parts.add('dfrequency=' + dfrequency.toStringAsFixed(3));
    if (dftype != AdynamicequalizerDftype.bandpass)
      parts.add('dftype=' + dftype.mpvValue);
    if (dqfactor != 1.0) parts.add('dqfactor=' + dqfactor.toStringAsFixed(3));
    if (makeup != 0.0) parts.add('makeup=' + makeup.toStringAsFixed(3));
    if (mode != AdynamicequalizerMode.listen)
      parts.add('mode=' + mode.mpvValue);
    if (precision != AdynamicequalizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (range != 50.0) parts.add('range=' + range.toStringAsFixed(3));
    if (ratio != 1.0) parts.add('ratio=' + ratio.toStringAsFixed(3));
    if (release != 200.0) parts.add('release=' + release.toStringAsFixed(3));
    if (tfrequency != 1000.0)
      parts.add('tfrequency=' + tfrequency.toStringAsFixed(3));
    if (tftype != AdynamicequalizerTftype.bell)
      parts.add('tftype=' + tftype.mpvValue);
    if (threshold != 0.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    if (tqfactor != 1.0) parts.add('tqfactor=' + tqfactor.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-adynamicequalizer'
        : 'lavfi-adynamicequalizer=' + parts.join(':');
  }
}

/// Configuration for the `adynamicsmooth` audio effect.
///
/// Apply dynamic smoothing to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [basefreq]: Set a base frequency for smoothing. Default value is 22050. Allowed range is from 2 to 1e+06. (range 2..1000000, default 22050)
/// - [sensitivity]: Set an amount of sensitivity to frequency fluctations. Default is 2. Allowed range is from 0 to 1e+06. (range 0..1000000, default 2)
final class AdynamicsmoothSettings {
  final bool enabled;
  final double basefreq;
  final double sensitivity;

  const AdynamicsmoothSettings({
    this.enabled = false,
    this.basefreq = 22050.0,
    this.sensitivity = 2.0,
  });

  AdynamicsmoothSettings copyWith({
    bool? enabled,
    double? basefreq,
    double? sensitivity,
  }) =>
      AdynamicsmoothSettings(
        enabled: enabled ?? this.enabled,
        basefreq: basefreq ?? this.basefreq,
        sensitivity: sensitivity ?? this.sensitivity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicsmoothSettings &&
          other.enabled == enabled &&
          other.basefreq == basefreq &&
          other.sensitivity == sensitivity);

  @override
  int get hashCode => Object.hash(enabled, basefreq, sensitivity);

  @override
  String toString() =>
      'AdynamicsmoothSettings(enabled: $enabled, basefreq: $basefreq, sensitivity: $sensitivity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(basefreq >= 2, 'adynamicsmooth.basefreq must be >= 2');
    assert(basefreq <= 1000000, 'adynamicsmooth.basefreq must be <= 1000000');
    assert(sensitivity >= 0, 'adynamicsmooth.sensitivity must be >= 0');
    assert(sensitivity <= 1000000,
        'adynamicsmooth.sensitivity must be <= 1000000');
    final parts = <String>[];
    if (basefreq != 22050.0)
      parts.add('basefreq=' + basefreq.toStringAsFixed(3));
    if (sensitivity != 2.0)
      parts.add('sensitivity=' + sensitivity.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-adynamicsmooth'
        : 'lavfi-adynamicsmooth=' + parts.join(':');
  }
}

/// Configuration for the `aecho` audio effect.
///
/// Apply echoing to the input audio.
///
/// Echoes are reflected sound and can occur naturally amongst mountains
/// (and sometimes large buildings) when talking or shouting; digital echo
/// effects emulate this behaviour and are often used to help fill out the
/// sound of a single instrument or vocal. The time difference between the
/// original signal and the reflection is the `delay`, and the
/// loudness of the reflected signal is the `decay`.
/// Multiple echoes can have different delays and decays.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decays]: Set list of loudness of reflected signals separated by '|'. Allowed range for each `decay` is `(0 - 1.0]`. Default is `0.5`. (range 0..0, default "0.5")
/// - [delays]: Set list of time intervals in milliseconds between original signal and reflections separated by '|'. Allowed range for each `delay` is `(0 - 90000.0]`. Default is `1000`. (range 0..0, default "1000")
/// - [in_gain]: Set input gain of reflected signal. Default is `0.6`. (range 0..1, default 0.6)
/// - [out_gain]: Set output gain of reflected signal. Default is `0.3`. (range 0..1, default 0.3)
final class AechoSettings {
  final bool enabled;
  final String decays;
  final String delays;
  final double in_gain;
  final double out_gain;

  const AechoSettings({
    this.enabled = false,
    this.decays = '0.5',
    this.delays = '1000',
    this.in_gain = 0.6,
    this.out_gain = 0.3,
  });

  AechoSettings copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    double? in_gain,
    double? out_gain,
  }) =>
      AechoSettings(
        enabled: enabled ?? this.enabled,
        decays: decays ?? this.decays,
        delays: delays ?? this.delays,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AechoSettings &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain);

  @override
  int get hashCode => Object.hash(enabled, decays, delays, in_gain, out_gain);

  @override
  String toString() =>
      'AechoSettings(enabled: $enabled, decays: $decays, delays: $delays, in_gain: $in_gain, out_gain: $out_gain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(in_gain >= 0, 'aecho.in_gain must be >= 0');
    assert(in_gain <= 1, 'aecho.in_gain must be <= 1');
    assert(out_gain >= 0, 'aecho.out_gain must be >= 0');
    assert(out_gain <= 1, 'aecho.out_gain must be <= 1');
    final parts = <String>[];
    if (decays != '0.5') parts.add('decays=' + decays);
    if (delays != '1000') parts.add('delays=' + delays);
    if (in_gain != 0.6) parts.add('in_gain=' + in_gain.toStringAsFixed(3));
    if (out_gain != 0.3) parts.add('out_gain=' + out_gain.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-aecho' : 'lavfi-aecho=' + parts.join(':');
  }
}

/// Configuration for the `aemphasis` audio effect.
///
/// Audio emphasis filter creates or restores material directly taken from LPs or
/// emphased CDs with different filter curves. E.g. to store music on vinyl the
/// signal has to be altered by a filter first to even out the disadvantages of
/// this recording medium.
/// Once the material is played back the inverse filter has to be applied to
/// restore the distortion of the frequency response.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level_in]: Set input gain. (range 0..64, default 1)
/// - [level_out]: Set output gain. (range 0..64, default 1)
/// - [mode]: Set filter mode. For restoring material use `reproduction` mode, otherwise use `production` mode. Default is `reproduction` mode. (range 0..1, default 0)
/// - [type]: Set filter type. Selects medium. Can be one of the following: (range 0..8, default 4)
final class AemphasisSettings {
  final bool enabled;
  final double level_in;
  final double level_out;
  final AemphasisMode mode;
  final AemphasisType type;

  const AemphasisSettings({
    this.enabled = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mode = AemphasisMode.reproduction,
    this.type = AemphasisType.cd,
  });

  AemphasisSettings copyWith({
    bool? enabled,
    double? level_in,
    double? level_out,
    AemphasisMode? mode,
    AemphasisType? type,
  }) =>
      AemphasisSettings(
        enabled: enabled ?? this.enabled,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mode: mode ?? this.mode,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AemphasisSettings &&
          other.enabled == enabled &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mode == mode &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level_in, level_out, mode, type);

  @override
  String toString() =>
      'AemphasisSettings(enabled: $enabled, level_in: $level_in, level_out: $level_out, mode: $mode, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level_in >= 0, 'aemphasis.level_in must be >= 0');
    assert(level_in <= 64, 'aemphasis.level_in must be <= 64');
    assert(level_out >= 0, 'aemphasis.level_out must be >= 0');
    assert(level_out <= 64, 'aemphasis.level_out must be <= 64');
    final parts = <String>[];
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (mode != AemphasisMode.reproduction) parts.add('mode=' + mode.mpvValue);
    if (type != AemphasisType.cd) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-aemphasis'
        : 'lavfi-aemphasis=' + parts.join(':');
  }
}

/// Configuration for the `aeval` audio effect.
///
/// Modify an audio signal according to the specified expressions.
///
/// This filter accepts one or more expressions (one for each channel),
/// which are evaluated and used to modify a corresponding audio signal.
///
/// It accepts the following parameters:
final class AevalSettings {
  final bool enabled;

  const AevalSettings({
    this.enabled = false,
  });

  AevalSettings copyWith({
    bool? enabled,
  }) =>
      AevalSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AevalSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AevalSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aeval';
  }
}

/// Configuration for the `aexciter` audio effect.
///
/// An exciter is used to produce high sound that is not present in the
/// original signal. This is done by creating harmonic distortions of the
/// signal which are restricted in range and added to the original signal.
/// An Exciter raises the upper end of an audio signal without simply raising
/// the higher frequencies like an equalizer would do to create a more
/// "crisp" or "brilliant" sound.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set the amount of harmonics added to original signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1)
/// - [blend]: Set the octave of newly created harmonics. Allowed range is from -10 to 10. Default value is 0. (range -10..10, default 0)
/// - [ceil]: Set the upper frequency limit of producing harmonics. Allowed range is from 9999 to 20000 Hz. If value is lower than 10000 Hz no limit is applied. (range 9999..20000, default 9999)
/// - [drive]: Set the amount of newly created harmonics. Allowed range is from 0.1 to 10. Default value is 8.5. (range 0.1..10, default 8.5)
/// - [freq]: Set the lower frequency limit of producing harmonics in Hz. Allowed range is from 2000 to 12000 Hz. Default is 7500 Hz. (range 2000..12000, default 7500)
/// - [level_in]: Set input level prior processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1)
/// - [level_out]: Set output level after processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1)
/// - [listen]: Mute the original signal and output only added harmonics. By default is disabled. (range 0..1, default 0)
final class AexciterSettings {
  final bool enabled;
  final double amount;
  final double blend;
  final double ceil;
  final double drive;
  final double freq;
  final double level_in;
  final double level_out;
  final bool listen;

  const AexciterSettings({
    this.enabled = false,
    this.amount = 1.0,
    this.blend = 0.0,
    this.ceil = 9999.0,
    this.drive = 8.5,
    this.freq = 7500.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.listen = false,
  });

  AexciterSettings copyWith({
    bool? enabled,
    double? amount,
    double? blend,
    double? ceil,
    double? drive,
    double? freq,
    double? level_in,
    double? level_out,
    bool? listen,
  }) =>
      AexciterSettings(
        enabled: enabled ?? this.enabled,
        amount: amount ?? this.amount,
        blend: blend ?? this.blend,
        ceil: ceil ?? this.ceil,
        drive: drive ?? this.drive,
        freq: freq ?? this.freq,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        listen: listen ?? this.listen,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AexciterSettings &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.blend == blend &&
          other.ceil == ceil &&
          other.drive == drive &&
          other.freq == freq &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.listen == listen);

  @override
  int get hashCode => Object.hash(
      enabled, amount, blend, ceil, drive, freq, level_in, level_out, listen);

  @override
  String toString() =>
      'AexciterSettings(enabled: $enabled, amount: $amount, blend: $blend, ceil: $ceil, drive: $drive, freq: $freq, level_in: $level_in, level_out: $level_out, listen: $listen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(amount >= 0, 'aexciter.amount must be >= 0');
    assert(amount <= 64, 'aexciter.amount must be <= 64');
    assert(blend >= -10, 'aexciter.blend must be >= -10');
    assert(blend <= 10, 'aexciter.blend must be <= 10');
    assert(ceil >= 9999, 'aexciter.ceil must be >= 9999');
    assert(ceil <= 20000, 'aexciter.ceil must be <= 20000');
    assert(drive >= 0.1, 'aexciter.drive must be >= 0.1');
    assert(drive <= 10, 'aexciter.drive must be <= 10');
    assert(freq >= 2000, 'aexciter.freq must be >= 2000');
    assert(freq <= 12000, 'aexciter.freq must be <= 12000');
    assert(level_in >= 0, 'aexciter.level_in must be >= 0');
    assert(level_in <= 64, 'aexciter.level_in must be <= 64');
    assert(level_out >= 0, 'aexciter.level_out must be >= 0');
    assert(level_out <= 64, 'aexciter.level_out must be <= 64');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + amount.toStringAsFixed(3));
    if (blend != 0.0) parts.add('blend=' + blend.toStringAsFixed(3));
    if (ceil != 9999.0) parts.add('ceil=' + ceil.toStringAsFixed(3));
    if (drive != 8.5) parts.add('drive=' + drive.toStringAsFixed(3));
    if (freq != 7500.0) parts.add('freq=' + freq.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (listen != false) parts.add('listen=' + (listen ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-aexciter'
        : 'lavfi-aexciter=' + parts.join(':');
  }
}

/// Configuration for the `afade` audio effect.
///
/// Apply fade-in/out effect to input audio.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [c]: set fade curve type
/// - [curve]: Set curve for fade transition.  It accepts the following values:
/// - [d]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (default 0)
/// - [duration]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (default 0)
/// - [silence]: Set the initial gain for fade-in or final gain for fade-out. Default value is `0.0`. (range 0..1, default 0)
/// - [st]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (default 0)
/// - [start_time]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (default 0)
/// - [t]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0)
/// - [type]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0)
/// - [unity]: Set the initial gain for fade-out or final gain for fade-in. Default value is `1.0`. (range 0..1, default 1)
final class AfadeSettings {
  final bool enabled;
  final AfadeCurve? c;
  final AfadeCurve? curve;
  final Duration d;
  final Duration duration;
  final double silence;
  final Duration st;
  final Duration start_time;
  final AfadeType t;
  final AfadeType type;
  final double unity;

  const AfadeSettings({
    this.enabled = false,
    this.c,
    this.curve,
    this.d = const Duration(microseconds: 0),
    this.duration = const Duration(microseconds: 0),
    this.silence = 0.0,
    this.st = const Duration(microseconds: 0),
    this.start_time = const Duration(microseconds: 0),
    this.t = AfadeType.in_,
    this.type = AfadeType.in_,
    this.unity = 1.0,
  });

  AfadeSettings copyWith({
    bool? enabled,
    Object? c = _unset,
    Object? curve = _unset,
    Duration? d,
    Duration? duration,
    double? silence,
    Duration? st,
    Duration? start_time,
    AfadeType? t,
    AfadeType? type,
    double? unity,
  }) =>
      AfadeSettings(
        enabled: enabled ?? this.enabled,
        c: identical(c, _unset) ? this.c : c as AfadeCurve?,
        curve: identical(curve, _unset) ? this.curve : curve as AfadeCurve?,
        d: d ?? this.d,
        duration: duration ?? this.duration,
        silence: silence ?? this.silence,
        st: st ?? this.st,
        start_time: start_time ?? this.start_time,
        t: t ?? this.t,
        type: type ?? this.type,
        unity: unity ?? this.unity,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfadeSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.curve == curve &&
          other.d == d &&
          other.duration == duration &&
          other.silence == silence &&
          other.st == st &&
          other.start_time == start_time &&
          other.t == t &&
          other.type == type &&
          other.unity == unity);

  @override
  int get hashCode => Object.hash(
      enabled, c, curve, d, duration, silence, st, start_time, t, type, unity);

  @override
  String toString() =>
      'AfadeSettings(enabled: $enabled, c: $c, curve: $curve, d: $d, duration: $duration, silence: $silence, st: $st, start_time: $start_time, t: $t, type: $type, unity: $unity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(silence >= 0, 'afade.silence must be >= 0');
    assert(silence <= 1, 'afade.silence must be <= 1');
    assert(unity >= 0, 'afade.unity must be >= 0');
    assert(unity <= 1, 'afade.unity must be <= 1');
    final parts = <String>[];
    if (c != null) parts.add('c=' + c!.mpvValue);
    if (curve != null) parts.add('curve=' + curve!.mpvValue);
    if (d != const Duration(microseconds: 0))
      parts.add('d=' + (d.inMicroseconds / 1e6).toStringAsFixed(3));
    if (duration != const Duration(microseconds: 0))
      parts.add(
          'duration=' + (duration.inMicroseconds / 1e6).toStringAsFixed(3));
    if (silence != 0.0) parts.add('silence=' + silence.toStringAsFixed(3));
    if (st != const Duration(microseconds: 0))
      parts.add('st=' + (st.inMicroseconds / 1e6).toStringAsFixed(3));
    if (start_time != const Duration(microseconds: 0))
      parts.add(
          'start_time=' + (start_time.inMicroseconds / 1e6).toStringAsFixed(3));
    if (t != AfadeType.in_) parts.add('t=' + t.mpvValue);
    if (type != AfadeType.in_) parts.add('type=' + type.mpvValue);
    if (unity != 1.0) parts.add('unity=' + unity.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-afade' : 'lavfi-afade=' + parts.join(':');
  }
}

/// Configuration for the `afftdn` audio effect.
///
/// Denoise audio samples with FFT.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [ad]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5)
/// - [adaptivity]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5)
/// - [band_multiplier]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [band_noise]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default 0)
/// - [bm]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [bn]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default 0)
/// - [floor_offset]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0)
/// - [fo]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0)
/// - [gain_smooth]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0)
/// - [gs]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0)
/// - [nf]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50)
/// - [nl]: Set the noise link used for multichannel audio.  It accepts the following values:
/// - [noise_floor]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50)
/// - [noise_link]: Set the noise link used for multichannel audio.  It accepts the following values:
/// - [noise_reduction]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (default 12)
/// - [noise_type]: Set the noise type.  It accepts the following values:
/// - [nr]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (default 12)
/// - [nt]: Set the noise type.  It accepts the following values:
/// - [om]: Set the output mode.  It accepts the following values:
/// - [output_mode]: Set the output mode.  It accepts the following values:
/// - [residual_floor]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38)
/// - [rf]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38)
/// - [sample_noise]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values:
/// - [sn]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values:
/// - [tn]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0)
/// - [tr]: Enable residual tracking. By default is disabled. (range 0..1, default 0)
/// - [track_noise]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0)
/// - [track_residual]: Enable residual tracking. By default is disabled. (range 0..1, default 0)
final class AfftdnSettings {
  final bool enabled;
  final double ad;
  final double adaptivity;
  final double band_multiplier;
  final String band_noise;
  final double bm;
  final String bn;
  final double floor_offset;
  final double fo;
  final int gain_smooth;
  final int gs;
  final double nf;
  final AfftdnLink? nl;
  final double noise_floor;
  final AfftdnLink? noise_link;
  final double noise_reduction;
  final AfftdnType? noise_type;
  final double nr;
  final AfftdnType? nt;
  final AfftdnMode? om;
  final AfftdnMode? output_mode;
  final double residual_floor;
  final double rf;
  final AfftdnSample? sample_noise;
  final AfftdnSample? sn;
  final bool tn;
  final bool tr;
  final bool track_noise;
  final bool track_residual;

  const AfftdnSettings({
    this.enabled = false,
    this.ad = 0.5,
    this.adaptivity = 0.5,
    this.band_multiplier = 1.25,
    this.band_noise = '0',
    this.bm = 1.25,
    this.bn = '0',
    this.floor_offset = 1.0,
    this.fo = 1.0,
    this.gain_smooth = 0,
    this.gs = 0,
    this.nf = -50.0,
    this.nl,
    this.noise_floor = -50.0,
    this.noise_link,
    this.noise_reduction = 12.0,
    this.noise_type,
    this.nr = 12.0,
    this.nt,
    this.om,
    this.output_mode,
    this.residual_floor = -38.0,
    this.rf = -38.0,
    this.sample_noise,
    this.sn,
    this.tn = false,
    this.tr = false,
    this.track_noise = false,
    this.track_residual = false,
  });

  AfftdnSettings copyWith({
    bool? enabled,
    double? ad,
    double? adaptivity,
    double? band_multiplier,
    String? band_noise,
    double? bm,
    String? bn,
    double? floor_offset,
    double? fo,
    int? gain_smooth,
    int? gs,
    double? nf,
    Object? nl = _unset,
    double? noise_floor,
    Object? noise_link = _unset,
    double? noise_reduction,
    Object? noise_type = _unset,
    double? nr,
    Object? nt = _unset,
    Object? om = _unset,
    Object? output_mode = _unset,
    double? residual_floor,
    double? rf,
    Object? sample_noise = _unset,
    Object? sn = _unset,
    bool? tn,
    bool? tr,
    bool? track_noise,
    bool? track_residual,
  }) =>
      AfftdnSettings(
        enabled: enabled ?? this.enabled,
        ad: ad ?? this.ad,
        adaptivity: adaptivity ?? this.adaptivity,
        band_multiplier: band_multiplier ?? this.band_multiplier,
        band_noise: band_noise ?? this.band_noise,
        bm: bm ?? this.bm,
        bn: bn ?? this.bn,
        floor_offset: floor_offset ?? this.floor_offset,
        fo: fo ?? this.fo,
        gain_smooth: gain_smooth ?? this.gain_smooth,
        gs: gs ?? this.gs,
        nf: nf ?? this.nf,
        nl: identical(nl, _unset) ? this.nl : nl as AfftdnLink?,
        noise_floor: noise_floor ?? this.noise_floor,
        noise_link: identical(noise_link, _unset)
            ? this.noise_link
            : noise_link as AfftdnLink?,
        noise_reduction: noise_reduction ?? this.noise_reduction,
        noise_type: identical(noise_type, _unset)
            ? this.noise_type
            : noise_type as AfftdnType?,
        nr: nr ?? this.nr,
        nt: identical(nt, _unset) ? this.nt : nt as AfftdnType?,
        om: identical(om, _unset) ? this.om : om as AfftdnMode?,
        output_mode: identical(output_mode, _unset)
            ? this.output_mode
            : output_mode as AfftdnMode?,
        residual_floor: residual_floor ?? this.residual_floor,
        rf: rf ?? this.rf,
        sample_noise: identical(sample_noise, _unset)
            ? this.sample_noise
            : sample_noise as AfftdnSample?,
        sn: identical(sn, _unset) ? this.sn : sn as AfftdnSample?,
        tn: tn ?? this.tn,
        tr: tr ?? this.tr,
        track_noise: track_noise ?? this.track_noise,
        track_residual: track_residual ?? this.track_residual,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftdnSettings &&
          other.enabled == enabled &&
          other.ad == ad &&
          other.adaptivity == adaptivity &&
          other.band_multiplier == band_multiplier &&
          other.band_noise == band_noise &&
          other.bm == bm &&
          other.bn == bn &&
          other.floor_offset == floor_offset &&
          other.fo == fo &&
          other.gain_smooth == gain_smooth &&
          other.gs == gs &&
          other.nf == nf &&
          other.nl == nl &&
          other.noise_floor == noise_floor &&
          other.noise_link == noise_link &&
          other.noise_reduction == noise_reduction &&
          other.noise_type == noise_type &&
          other.nr == nr &&
          other.nt == nt &&
          other.om == om &&
          other.output_mode == output_mode &&
          other.residual_floor == residual_floor &&
          other.rf == rf &&
          other.sample_noise == sample_noise &&
          other.sn == sn &&
          other.tn == tn &&
          other.tr == tr &&
          other.track_noise == track_noise &&
          other.track_residual == track_residual);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        ad,
        adaptivity,
        band_multiplier,
        band_noise,
        bm,
        bn,
        floor_offset,
        fo,
        gain_smooth,
        gs,
        nf,
        nl,
        noise_floor,
        noise_link,
        noise_reduction,
        noise_type,
        nr,
        nt,
        om,
        output_mode,
        residual_floor,
        rf,
        sample_noise,
        sn,
        tn,
        tr,
        track_noise,
        track_residual
      ]);

  @override
  String toString() =>
      'AfftdnSettings(enabled: $enabled, ad: $ad, adaptivity: $adaptivity, band_multiplier: $band_multiplier, band_noise: $band_noise, bm: $bm, bn: $bn, floor_offset: $floor_offset, fo: $fo, gain_smooth: $gain_smooth, gs: $gs, nf: $nf, nl: $nl, noise_floor: $noise_floor, noise_link: $noise_link, noise_reduction: $noise_reduction, noise_type: $noise_type, nr: $nr, nt: $nt, om: $om, output_mode: $output_mode, residual_floor: $residual_floor, rf: $rf, sample_noise: $sample_noise, sn: $sn, tn: $tn, tr: $tr, track_noise: $track_noise, track_residual: $track_residual)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(ad >= 0, 'afftdn.ad must be >= 0');
    assert(ad <= 1, 'afftdn.ad must be <= 1');
    assert(adaptivity >= 0, 'afftdn.adaptivity must be >= 0');
    assert(adaptivity <= 1, 'afftdn.adaptivity must be <= 1');
    assert(band_multiplier >= 0.2, 'afftdn.band_multiplier must be >= 0.2');
    assert(band_multiplier <= 5, 'afftdn.band_multiplier must be <= 5');
    assert(bm >= 0.2, 'afftdn.bm must be >= 0.2');
    assert(bm <= 5, 'afftdn.bm must be <= 5');
    assert(floor_offset >= -2, 'afftdn.floor_offset must be >= -2');
    assert(floor_offset <= 2, 'afftdn.floor_offset must be <= 2');
    assert(fo >= -2, 'afftdn.fo must be >= -2');
    assert(fo <= 2, 'afftdn.fo must be <= 2');
    assert(gain_smooth >= 0, 'afftdn.gain_smooth must be >= 0');
    assert(gain_smooth <= 50, 'afftdn.gain_smooth must be <= 50');
    assert(gs >= 0, 'afftdn.gs must be >= 0');
    assert(gs <= 50, 'afftdn.gs must be <= 50');
    assert(nf >= -80, 'afftdn.nf must be >= -80');
    assert(nf <= -20, 'afftdn.nf must be <= -20');
    assert(noise_floor >= -80, 'afftdn.noise_floor must be >= -80');
    assert(noise_floor <= -20, 'afftdn.noise_floor must be <= -20');
    assert(residual_floor >= -80, 'afftdn.residual_floor must be >= -80');
    assert(residual_floor <= -20, 'afftdn.residual_floor must be <= -20');
    assert(rf >= -80, 'afftdn.rf must be >= -80');
    assert(rf <= -20, 'afftdn.rf must be <= -20');
    final parts = <String>[];
    if (ad != 0.5) parts.add('ad=' + ad.toStringAsFixed(3));
    if (adaptivity != 0.5)
      parts.add('adaptivity=' + adaptivity.toStringAsFixed(3));
    if (band_multiplier != 1.25)
      parts.add('band_multiplier=' + band_multiplier.toStringAsFixed(3));
    if (band_noise != '0') parts.add('band_noise=' + band_noise);
    if (bm != 1.25) parts.add('bm=' + bm.toStringAsFixed(3));
    if (bn != '0') parts.add('bn=' + bn);
    if (floor_offset != 1.0)
      parts.add('floor_offset=' + floor_offset.toStringAsFixed(3));
    if (fo != 1.0) parts.add('fo=' + fo.toStringAsFixed(3));
    if (gain_smooth != 0) parts.add('gain_smooth=' + gain_smooth.toString());
    if (gs != 0) parts.add('gs=' + gs.toString());
    if (nf != -50.0) parts.add('nf=' + nf.toStringAsFixed(3));
    if (nl != null) parts.add('nl=' + nl!.mpvValue);
    if (noise_floor != -50.0)
      parts.add('noise_floor=' + noise_floor.toStringAsFixed(3));
    if (noise_link != null) parts.add('noise_link=' + noise_link!.mpvValue);
    if (noise_reduction != 12.0)
      parts.add('noise_reduction=' + noise_reduction.toStringAsFixed(3));
    if (noise_type != null) parts.add('noise_type=' + noise_type!.mpvValue);
    if (nr != 12.0) parts.add('nr=' + nr.toStringAsFixed(3));
    if (nt != null) parts.add('nt=' + nt!.mpvValue);
    if (om != null) parts.add('om=' + om!.mpvValue);
    if (output_mode != null) parts.add('output_mode=' + output_mode!.mpvValue);
    if (residual_floor != -38.0)
      parts.add('residual_floor=' + residual_floor.toStringAsFixed(3));
    if (rf != -38.0) parts.add('rf=' + rf.toStringAsFixed(3));
    if (sample_noise != null)
      parts.add('sample_noise=' + sample_noise!.mpvValue);
    if (sn != null) parts.add('sn=' + sn!.mpvValue);
    if (tn != false) parts.add('tn=' + (tn ? '1' : '0'));
    if (tr != false) parts.add('tr=' + (tr ? '1' : '0'));
    if (track_noise != false)
      parts.add('track_noise=' + (track_noise ? '1' : '0'));
    if (track_residual != false)
      parts.add('track_residual=' + (track_residual ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-afftdn' : 'lavfi-afftdn=' + parts.join(':');
  }
}

/// Configuration for the `afftfilt` audio effect.
///
/// Apply arbitrary expressions to samples in frequency domain.
///
/// Parameters:
/// - [imag]: Set frequency domain imaginary expression for each separate channel separated by '|'. Default is "im".  Each expression in `real` and `imag` can contain the following constants and functions: (range 0..0, default "im")
/// - [overlap]: set window overlap (range 0..1, default 0.75)
/// - [real]: Set frequency domain real expression for each separate channel separated by '|'. Default is "re". If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (range 0..0, default "re")
/// - [win_size]: Set window size. Allowed range is from 16 to 131072. Default is `4096` (range 16..131072, default 4096)
final class AfftfiltSettings {
  final bool enabled;
  final String imag;
  final double overlap;
  final String real;
  final int win_size;

  const AfftfiltSettings({
    this.enabled = false,
    this.imag = 'im',
    this.overlap = 0.75,
    this.real = 're',
    this.win_size = 4096,
  });

  AfftfiltSettings copyWith({
    bool? enabled,
    String? imag,
    double? overlap,
    String? real,
    int? win_size,
  }) =>
      AfftfiltSettings(
        enabled: enabled ?? this.enabled,
        imag: imag ?? this.imag,
        overlap: overlap ?? this.overlap,
        real: real ?? this.real,
        win_size: win_size ?? this.win_size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftfiltSettings &&
          other.enabled == enabled &&
          other.imag == imag &&
          other.overlap == overlap &&
          other.real == real &&
          other.win_size == win_size);

  @override
  int get hashCode => Object.hash(enabled, imag, overlap, real, win_size);

  @override
  String toString() =>
      'AfftfiltSettings(enabled: $enabled, imag: $imag, overlap: $overlap, real: $real, win_size: $win_size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(overlap >= 0, 'afftfilt.overlap must be >= 0');
    assert(overlap <= 1, 'afftfilt.overlap must be <= 1');
    assert(win_size >= 16, 'afftfilt.win_size must be >= 16');
    assert(win_size <= 131072, 'afftfilt.win_size must be <= 131072');
    final parts = <String>[];
    if (imag != 'im') parts.add('imag=' + imag);
    if (overlap != 0.75) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (real != 're') parts.add('real=' + real);
    if (win_size != 4096) parts.add('win_size=' + win_size.toString());
    return parts.isEmpty
        ? 'lavfi-afftfilt'
        : 'lavfi-afftfilt=' + parts.join(':');
  }
}

/// Configuration for the `aformat` audio effect.
///
/// Set output format constraints for the input audio. The framework will
/// negotiate the most appropriate format to minimize conversions.
///
/// It accepts the following parameters:
final class AformatSettings {
  final bool enabled;

  const AformatSettings({
    this.enabled = false,
  });

  AformatSettings copyWith({
    bool? enabled,
  }) =>
      AformatSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AformatSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AformatSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aformat';
  }
}

/// Configuration for the `afreqshift` audio effect.
///
/// Apply frequency shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (default 8)
/// - [shift]: Specify frequency shift. Allowed range is -INT_MAX to INT_MAX. Default value is 0.0. (default 0)
final class AfreqshiftSettings {
  final bool enabled;
  final double level;
  final int order;
  final double shift;

  const AfreqshiftSettings({
    this.enabled = false,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  AfreqshiftSettings copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) =>
      AfreqshiftSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        order: order ?? this.order,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfreqshiftSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AfreqshiftSettings(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= 0.0, 'afreqshift.level must be >= 0.0');
    assert(level <= 1.0, 'afreqshift.level must be <= 1.0');
    assert(order >= 1, 'afreqshift.order must be >= 1');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + shift.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-afreqshift'
        : 'lavfi-afreqshift=' + parts.join(':');
  }
}

/// Configuration for the `afwtdn` audio effect.
///
/// Reduce broadband noise from input samples using Wavelets.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [adaptive]: adaptive profiling of noise (range 0..1, default 0)
/// - [levels]: Set the number of wavelet levels of decomposition. Allowed range is from 1 to 12. Default value is 10. Setting this too low make denoising performance very poor. (default 10)
/// - [percent]: set percent of full denoising (range 0..100, default 85)
/// - [profile]: profile noise (range 0..1, default 0)
/// - [samples]: set frame size in number of samples (range 512..65536, default 8192)
/// - [sigma]: Set the noise sigma, allowed range is from 0 to 1. Default value is 0. This option controls strength of denoising applied to input samples. Most useful way to set this option is via decibels, eg. -45dB. (range 0..1, default 0)
/// - [softness]: set thresholding softness (range 0..10, default 1)
/// - [wavet]: Set wavelet type for decomposition of input frame. They are sorted by number of coefficients, from lowest to highest. More coefficients means worse filtering speed, but overall better quality. Available wavelets are:
final class AfwtdnSettings {
  final bool enabled;
  final bool adaptive;
  final int levels;
  final double percent;
  final bool profile;
  final int samples;
  final double sigma;
  final double softness;
  final AfwtdnWavet? wavet;

  const AfwtdnSettings({
    this.enabled = false,
    this.adaptive = false,
    this.levels = 10,
    this.percent = 85.0,
    this.profile = false,
    this.samples = 8192,
    this.sigma = 0.0,
    this.softness = 1.0,
    this.wavet,
  });

  AfwtdnSettings copyWith({
    bool? enabled,
    bool? adaptive,
    int? levels,
    double? percent,
    bool? profile,
    int? samples,
    double? sigma,
    double? softness,
    Object? wavet = _unset,
  }) =>
      AfwtdnSettings(
        enabled: enabled ?? this.enabled,
        adaptive: adaptive ?? this.adaptive,
        levels: levels ?? this.levels,
        percent: percent ?? this.percent,
        profile: profile ?? this.profile,
        samples: samples ?? this.samples,
        sigma: sigma ?? this.sigma,
        softness: softness ?? this.softness,
        wavet: identical(wavet, _unset) ? this.wavet : wavet as AfwtdnWavet?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfwtdnSettings &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.levels == levels &&
          other.percent == percent &&
          other.profile == profile &&
          other.samples == samples &&
          other.sigma == sigma &&
          other.softness == softness &&
          other.wavet == wavet);

  @override
  int get hashCode => Object.hash(enabled, adaptive, levels, percent, profile,
      samples, sigma, softness, wavet);

  @override
  String toString() =>
      'AfwtdnSettings(enabled: $enabled, adaptive: $adaptive, levels: $levels, percent: $percent, profile: $profile, samples: $samples, sigma: $sigma, softness: $softness, wavet: $wavet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(levels >= 1, 'afwtdn.levels must be >= 1');
    assert(percent >= 0, 'afwtdn.percent must be >= 0');
    assert(percent <= 100, 'afwtdn.percent must be <= 100');
    assert(samples >= 512, 'afwtdn.samples must be >= 512');
    assert(samples <= 65536, 'afwtdn.samples must be <= 65536');
    assert(sigma >= 0, 'afwtdn.sigma must be >= 0');
    assert(sigma <= 1, 'afwtdn.sigma must be <= 1');
    assert(softness >= 0, 'afwtdn.softness must be >= 0');
    assert(softness <= 10, 'afwtdn.softness must be <= 10');
    final parts = <String>[];
    if (adaptive != false) parts.add('adaptive=' + (adaptive ? '1' : '0'));
    if (levels != 10) parts.add('levels=' + levels.toString());
    if (percent != 85.0) parts.add('percent=' + percent.toStringAsFixed(3));
    if (profile != false) parts.add('profile=' + (profile ? '1' : '0'));
    if (samples != 8192) parts.add('samples=' + samples.toString());
    if (sigma != 0.0) parts.add('sigma=' + sigma.toStringAsFixed(3));
    if (softness != 1.0) parts.add('softness=' + softness.toStringAsFixed(3));
    if (wavet != null) parts.add('wavet=' + wavet!.mpvValue);
    return parts.isEmpty ? 'lavfi-afwtdn' : 'lavfi-afwtdn=' + parts.join(':');
  }
}

/// Configuration for the `agate` audio effect.
///
/// A gate is mainly used to reduce lower parts of a signal. This kind of signal
/// processing reduces disturbing noise between useful signals.
///
/// Gating is done by detecting the volume below a chosen level `threshold`
/// and dividing it by the factor set with `ratio`. The bottom of the noise
/// floor is set via `range`. Because an exact manipulation of the signal
/// would cause distortion of the waveform the reduction can be levelled over
/// time. This is done by setting `attack` and `release`.
///
/// `attack` determines how long the signal has to fall below the threshold
/// before any reduction will occur and `release` sets the time the signal
/// has to rise above the threshold to reduce the reduction again.
/// Shorter signals than the chosen attack time will be left untouched.
///
/// Parameters:
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction stops. Default is 20 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 20)
/// - [detection]: Choose if exact signal should be taken for detection or an RMS like one. Default is `rms`. Can be `peak` or `rms`. (range 0..1, default 1)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.828427125. Allowed range is from 1 to 8. (range 1..8, default 2.828427125)
/// - [level_in]: Set input level before filtering. Default is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1)
/// - [level_sc]: set sidechain gain (range 0.015625..64, default 1)
/// - [link]: Choose if the average level between all channels or the louder channel affects the reduction. Default is `average`. Can be `average` or `maximum`. (range 0..1, default 0)
/// - [makeup]: Set amount of amplification of signal after processing. Default is 1. Allowed range is from 1 to 64. (range 1..64, default 1)
/// - [mode]: Set the mode of operation. Can be `upward` or `downward`. Default is `downward`. If set to `upward` mode, higher parts of signal will be amplified, expanding dynamic range in upward direction. Otherwise, in case of `downward` lower parts of signal will be reduced. (range 0..1, default 0)
/// - [range]: Set the level of gain reduction when the signal is below the threshold. Default is 0.06125. Allowed range is from 0 to 1. Setting this to 0 disables reduction and then filter behaves like expander. (range 0..1, default 0.06125)
/// - [ratio]: Set a ratio by which the signal is reduced. Default is 2. Allowed range is from 1 to 9000. (range 1..9000, default 2)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before the reduction is increased again. Default is 250 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 250)
/// - [threshold]: If a signal rises above this level the gain reduction is released. Default is 0.125. Allowed range is from 0 to 1. (range 0..1, default 0.125)
final class AgateSettings {
  final bool enabled;
  final double attack;
  final AgateDetection detection;
  final double knee;
  final double level_in;
  final double level_sc;
  final AgateLink link;
  final double makeup;
  final AgateMode mode;
  final double range;
  final double ratio;
  final double release;
  final double threshold;

  const AgateSettings({
    this.enabled = false,
    this.attack = 20.0,
    this.detection = AgateDetection.rms,
    this.knee = 2.828427125,
    this.level_in = 1.0,
    this.level_sc = 1.0,
    this.link = AgateLink.average,
    this.makeup = 1.0,
    this.mode = AgateMode.downward,
    this.range = 0.06125,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  AgateSettings copyWith({
    bool? enabled,
    double? attack,
    AgateDetection? detection,
    double? knee,
    double? level_in,
    double? level_sc,
    AgateLink? link,
    double? makeup,
    AgateMode? mode,
    double? range,
    double? ratio,
    double? release,
    double? threshold,
  }) =>
      AgateSettings(
        enabled: enabled ?? this.enabled,
        attack: attack ?? this.attack,
        detection: detection ?? this.detection,
        knee: knee ?? this.knee,
        level_in: level_in ?? this.level_in,
        level_sc: level_sc ?? this.level_sc,
        link: link ?? this.link,
        makeup: makeup ?? this.makeup,
        mode: mode ?? this.mode,
        range: range ?? this.range,
        ratio: ratio ?? this.ratio,
        release: release ?? this.release,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AgateSettings &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.level_in == level_in &&
          other.level_sc == level_sc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(enabled, attack, detection, knee, level_in,
      level_sc, link, makeup, mode, range, ratio, release, threshold);

  @override
  String toString() =>
      'AgateSettings(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, level_in: $level_in, level_sc: $level_sc, link: $link, makeup: $makeup, mode: $mode, range: $range, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(attack >= 0.01, 'agate.attack must be >= 0.01');
    assert(attack <= 9000, 'agate.attack must be <= 9000');
    assert(knee >= 1, 'agate.knee must be >= 1');
    assert(knee <= 8, 'agate.knee must be <= 8');
    assert(level_in >= 0.015625, 'agate.level_in must be >= 0.015625');
    assert(level_in <= 64, 'agate.level_in must be <= 64');
    assert(level_sc >= 0.015625, 'agate.level_sc must be >= 0.015625');
    assert(level_sc <= 64, 'agate.level_sc must be <= 64');
    assert(makeup >= 1, 'agate.makeup must be >= 1');
    assert(makeup <= 64, 'agate.makeup must be <= 64');
    assert(range >= 0, 'agate.range must be >= 0');
    assert(range <= 1, 'agate.range must be <= 1');
    assert(ratio >= 1, 'agate.ratio must be >= 1');
    assert(ratio <= 9000, 'agate.ratio must be <= 9000');
    assert(release >= 0.01, 'agate.release must be >= 0.01');
    assert(release <= 9000, 'agate.release must be <= 9000');
    assert(threshold >= 0, 'agate.threshold must be >= 0');
    assert(threshold <= 1, 'agate.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + attack.toStringAsFixed(3));
    if (detection != AgateDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.828427125) parts.add('knee=' + knee.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_sc != 1.0) parts.add('level_sc=' + level_sc.toStringAsFixed(3));
    if (link != AgateLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + makeup.toStringAsFixed(3));
    if (mode != AgateMode.downward) parts.add('mode=' + mode.mpvValue);
    if (range != 0.06125) parts.add('range=' + range.toStringAsFixed(3));
    if (ratio != 2.0) parts.add('ratio=' + ratio.toStringAsFixed(3));
    if (release != 250.0) parts.add('release=' + release.toStringAsFixed(3));
    if (threshold != 0.125)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-agate' : 'lavfi-agate=' + parts.join(':');
  }
}

/// Configuration for the `aiir` audio effect.
///
/// Apply an arbitrary Infinite Impulse Response filter.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel]: set IR channel to display frequency response (range 0..1024, default 0)
/// - [dry]: set dry gain (range 0..1, default 1)
/// - [e]: set precision (range 0..3, default 0)
/// - [f]: Set coefficients format. (range -2..4, default 1)
/// - [format]: Set coefficients format. (range -2..4, default 1)
/// - [gains]: Set channels gains. (range 0..0, default "1|1")
/// - [k]: Set channels gains. (range 0..0, default "1|1")
/// - [mix]: set mix (range 0..1, default 1)
/// - [n]: normalize coefficients (range 0..1, default 1)
/// - [normalize]: normalize coefficients (range 0..1, default 1)
/// - [p]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [poles]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [precision]: set filtering precision (range 0..3, default 0)
/// - [process]: set kind of processing (range 0..2, default 1)
/// - [r]: set kind of processing (range 0..2, default 1)
/// - [response]: show IR frequency response (range 0..1, default 0)
/// - [wet]: set wet gain (range 0..1, default 1)
/// - [z]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
/// - [zeros]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
final class AiirSettings {
  final bool enabled;
  final int channel;
  final double dry;
  final AiirPrecision e;
  final AiirFormat f;
  final AiirFormat format;
  final String gains;
  final String k;
  final double mix;
  final bool n;
  final bool normalize;
  final String p;
  final String poles;
  final AiirPrecision precision;
  final AiirProcess process;
  final AiirProcess r;
  final bool response;
  final double wet;
  final String z;
  final String zeros;

  const AiirSettings({
    this.enabled = false,
    this.channel = 0,
    this.dry = 1.0,
    this.e = AiirPrecision.dbl,
    this.f = AiirFormat.zp,
    this.format = AiirFormat.zp,
    this.gains = '1|1',
    this.k = '1|1',
    this.mix = 1.0,
    this.n = true,
    this.normalize = true,
    this.p = '1+0i 1-0i',
    this.poles = '1+0i 1-0i',
    this.precision = AiirPrecision.dbl,
    this.process = AiirProcess.s,
    this.r = AiirProcess.s,
    this.response = false,
    this.wet = 1.0,
    this.z = '1+0i 1-0i',
    this.zeros = '1+0i 1-0i',
  });

  AiirSettings copyWith({
    bool? enabled,
    int? channel,
    double? dry,
    AiirPrecision? e,
    AiirFormat? f,
    AiirFormat? format,
    String? gains,
    String? k,
    double? mix,
    bool? n,
    bool? normalize,
    String? p,
    String? poles,
    AiirPrecision? precision,
    AiirProcess? process,
    AiirProcess? r,
    bool? response,
    double? wet,
    String? z,
    String? zeros,
  }) =>
      AiirSettings(
        enabled: enabled ?? this.enabled,
        channel: channel ?? this.channel,
        dry: dry ?? this.dry,
        e: e ?? this.e,
        f: f ?? this.f,
        format: format ?? this.format,
        gains: gains ?? this.gains,
        k: k ?? this.k,
        mix: mix ?? this.mix,
        n: n ?? this.n,
        normalize: normalize ?? this.normalize,
        p: p ?? this.p,
        poles: poles ?? this.poles,
        precision: precision ?? this.precision,
        process: process ?? this.process,
        r: r ?? this.r,
        response: response ?? this.response,
        wet: wet ?? this.wet,
        z: z ?? this.z,
        zeros: zeros ?? this.zeros,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiirSettings &&
          other.enabled == enabled &&
          other.channel == channel &&
          other.dry == dry &&
          other.e == e &&
          other.f == f &&
          other.format == format &&
          other.gains == gains &&
          other.k == k &&
          other.mix == mix &&
          other.n == n &&
          other.normalize == normalize &&
          other.p == p &&
          other.poles == poles &&
          other.precision == precision &&
          other.process == process &&
          other.r == r &&
          other.response == response &&
          other.wet == wet &&
          other.z == z &&
          other.zeros == zeros);

  @override
  int get hashCode => Object.hash(
      enabled,
      channel,
      dry,
      e,
      f,
      format,
      gains,
      k,
      mix,
      n,
      normalize,
      p,
      poles,
      precision,
      process,
      r,
      response,
      wet,
      z,
      zeros);

  @override
  String toString() =>
      'AiirSettings(enabled: $enabled, channel: $channel, dry: $dry, e: $e, f: $f, format: $format, gains: $gains, k: $k, mix: $mix, n: $n, normalize: $normalize, p: $p, poles: $poles, precision: $precision, process: $process, r: $r, response: $response, wet: $wet, z: $z, zeros: $zeros)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(channel >= 0, 'aiir.channel must be >= 0');
    assert(channel <= 1024, 'aiir.channel must be <= 1024');
    assert(dry >= 0, 'aiir.dry must be >= 0');
    assert(dry <= 1, 'aiir.dry must be <= 1');
    assert(mix >= 0, 'aiir.mix must be >= 0');
    assert(mix <= 1, 'aiir.mix must be <= 1');
    assert(wet >= 0, 'aiir.wet must be >= 0');
    assert(wet <= 1, 'aiir.wet must be <= 1');
    final parts = <String>[];
    if (channel != 0) parts.add('channel=' + channel.toString());
    if (dry != 1.0) parts.add('dry=' + dry.toStringAsFixed(3));
    if (e != AiirPrecision.dbl) parts.add('e=' + e.mpvValue);
    if (f != AiirFormat.zp) parts.add('f=' + f.mpvValue);
    if (format != AiirFormat.zp) parts.add('format=' + format.mpvValue);
    if (gains != '1|1') parts.add('gains=' + gains);
    if (k != '1|1') parts.add('k=' + k);
    if (mix != 1.0) parts.add('mix=' + mix.toStringAsFixed(3));
    if (n != true) parts.add('n=' + (n ? '1' : '0'));
    if (normalize != true) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (p != '1+0i 1-0i') parts.add('p=' + p);
    if (poles != '1+0i 1-0i') parts.add('poles=' + poles);
    if (precision != AiirPrecision.dbl)
      parts.add('precision=' + precision.mpvValue);
    if (process != AiirProcess.s) parts.add('process=' + process.mpvValue);
    if (r != AiirProcess.s) parts.add('r=' + r.mpvValue);
    if (response != false) parts.add('response=' + (response ? '1' : '0'));
    if (wet != 1.0) parts.add('wet=' + wet.toStringAsFixed(3));
    if (z != '1+0i 1-0i') parts.add('z=' + z);
    if (zeros != '1+0i 1-0i') parts.add('zeros=' + zeros);
    return parts.isEmpty ? 'lavfi-aiir' : 'lavfi-aiir=' + parts.join(':');
  }
}

/// Configuration for the `aintegral` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AintegralSettings {
  final bool enabled;

  const AintegralSettings({
    this.enabled = false,
  });

  AintegralSettings copyWith({
    bool? enabled,
  }) =>
      AintegralSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AintegralSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AintegralSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aintegral';
  }
}

/// Configuration for the `alatency` audio effect.
///
/// Measure filtering latency.
///
/// Report previous filter filtering latency, delay in number of audio samples for audio filters
/// or number of video frames for video filters.
///
/// On end of input stream, filter will report min and max measured latency for previous running filter
/// in filtergraph.
final class AlatencySettings {
  final bool enabled;

  const AlatencySettings({
    this.enabled = false,
  });

  AlatencySettings copyWith({
    bool? enabled,
  }) =>
      AlatencySettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlatencySettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AlatencySettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-alatency';
  }
}

/// Configuration for the `alimiter` audio effect.
///
/// The limiter prevents an input signal from rising over a desired threshold.
/// This limiter uses lookahead technology to prevent your signal from distorting.
/// It means that there is a small delay after the signal is processed. Keep in mind
/// that the delay it produces is the attack time you set.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [asc]: When gain reduction is always needed ASC takes care of releasing to an average reduction level rather than reaching a reduction of 0 in the release time. (range 0..1, default 0)
/// - [asc_level]: Select how much the release time is affected by ASC, 0 means nearly no changes in release time while 1 produces higher release times. (range 0..1, default 0.5)
/// - [attack]: The limiter will reach its attenuation level in this amount of time in milliseconds. Default is 5 milliseconds. (range 0.1..80, default 5)
/// - [latency]: Compensate the delay introduced by using the lookahead buffer set with attack parameter. Also flush the valid audio data in the lookahead buffer when the stream hits EOF. (range 0..1, default 0)
/// - [level]: Auto level output signal. Default is enabled. This normalizes audio back to 0dB if enabled. (range 0..1, default 1)
/// - [level_in]: Set input gain. Default is 1. (default 1)
/// - [level_out]: Set output gain. Default is 1. (default 1)
/// - [limit]: Don't let signals above this level pass the limiter. Default is 1. (range 0.0625..1, default 1)
/// - [release]: Come back from limiting to attenuation 1.0 in this amount of milliseconds. Default is 50 milliseconds. (range 1..8000, default 50)
final class AlimiterSettings {
  final bool enabled;
  final bool asc;
  final double asc_level;
  final double attack;
  final bool latency;
  final bool level;
  final double level_in;
  final double level_out;
  final double limit;
  final double release;

  const AlimiterSettings({
    this.enabled = false,
    this.asc = false,
    this.asc_level = 0.5,
    this.attack = 5.0,
    this.latency = false,
    this.level = true,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.limit = 1.0,
    this.release = 50.0,
  });

  AlimiterSettings copyWith({
    bool? enabled,
    bool? asc,
    double? asc_level,
    double? attack,
    bool? latency,
    bool? level,
    double? level_in,
    double? level_out,
    double? limit,
    double? release,
  }) =>
      AlimiterSettings(
        enabled: enabled ?? this.enabled,
        asc: asc ?? this.asc,
        asc_level: asc_level ?? this.asc_level,
        attack: attack ?? this.attack,
        latency: latency ?? this.latency,
        level: level ?? this.level,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        limit: limit ?? this.limit,
        release: release ?? this.release,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlimiterSettings &&
          other.enabled == enabled &&
          other.asc == asc &&
          other.asc_level == asc_level &&
          other.attack == attack &&
          other.latency == latency &&
          other.level == level &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.limit == limit &&
          other.release == release);

  @override
  int get hashCode => Object.hash(enabled, asc, asc_level, attack, latency,
      level, level_in, level_out, limit, release);

  @override
  String toString() =>
      'AlimiterSettings(enabled: $enabled, asc: $asc, asc_level: $asc_level, attack: $attack, latency: $latency, level: $level, level_in: $level_in, level_out: $level_out, limit: $limit, release: $release)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(asc_level >= 0, 'alimiter.asc_level must be >= 0');
    assert(asc_level <= 1, 'alimiter.asc_level must be <= 1');
    assert(attack >= 0.1, 'alimiter.attack must be >= 0.1');
    assert(attack <= 80, 'alimiter.attack must be <= 80');
    assert(limit >= 0.0625, 'alimiter.limit must be >= 0.0625');
    assert(limit <= 1, 'alimiter.limit must be <= 1');
    assert(release >= 1, 'alimiter.release must be >= 1');
    assert(release <= 8000, 'alimiter.release must be <= 8000');
    final parts = <String>[];
    if (asc != false) parts.add('asc=' + (asc ? '1' : '0'));
    if (asc_level != 0.5)
      parts.add('asc_level=' + asc_level.toStringAsFixed(3));
    if (attack != 5.0) parts.add('attack=' + attack.toStringAsFixed(3));
    if (latency != false) parts.add('latency=' + (latency ? '1' : '0'));
    if (level != true) parts.add('level=' + (level ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (limit != 1.0) parts.add('limit=' + limit.toStringAsFixed(3));
    if (release != 50.0) parts.add('release=' + release.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-alimiter'
        : 'lavfi-alimiter=' + parts.join(':');
  }
}

/// Configuration for the `allpass` audio effect.
///
/// Apply a two-pole all-pass filter with central frequency (in Hz)
/// `frequency`, and filter-width `width`.
/// An all-pass filter changes the audio's frequency to phase relationship
/// without changing its frequency to amplitude relationship.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set frequency in Hz. (range 0..999999, default 3000)
/// - [frequency]: Set frequency in Hz. (range 0..999999, default 3000)
/// - [o]: octave (range 1..2, default 2)
/// - [order]: Set the filter order, can be 1 or 2. Default is 2. (range 1..2, default 2)
final class AllpassSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final int o;
  final int order;

  const AllpassSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.o = 2,
    this.order = 2,
  });

  AllpassSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    int? o,
    int? order,
  }) =>
      AllpassSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        o: o ?? this.o,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllpassSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.o == o &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, o, order);

  @override
  String toString() =>
      'AllpassSettings(enabled: $enabled, f: $f, frequency: $frequency, o: $o, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'allpass.f must be >= 0');
    assert(f <= 999999, 'allpass.f must be <= 999999');
    assert(frequency >= 0, 'allpass.frequency must be >= 0');
    assert(frequency <= 999999, 'allpass.frequency must be <= 999999');
    assert(o >= 1, 'allpass.o must be >= 1');
    assert(o <= 2, 'allpass.o must be <= 2');
    assert(order >= 1, 'allpass.order must be >= 1');
    assert(order <= 2, 'allpass.order must be <= 2');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (o != 2) parts.add('o=' + o.toString());
    if (order != 2) parts.add('order=' + order.toString());
    return parts.isEmpty ? 'lavfi-allpass' : 'lavfi-allpass=' + parts.join(':');
  }
}

/// Configuration for the `aloop` audio effect.
///
/// Loop audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [loop]: Set the number of loops. Setting this value to -1 will result in infinite loops. Default is 0. (default 0)
/// - [time]: Set the time of loop start in seconds. Only used if option named `start` is set to `-1`.
final class AloopSettings {
  final bool enabled;
  final int loop;
  final Duration? time;

  const AloopSettings({
    this.enabled = false,
    this.loop = 0,
    this.time,
  });

  AloopSettings copyWith({
    bool? enabled,
    int? loop,
    Object? time = _unset,
  }) =>
      AloopSettings(
        enabled: enabled ?? this.enabled,
        loop: loop ?? this.loop,
        time: identical(time, _unset) ? this.time : time as Duration?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AloopSettings &&
          other.enabled == enabled &&
          other.loop == loop &&
          other.time == time);

  @override
  int get hashCode => Object.hash(enabled, loop, time);

  @override
  String toString() =>
      'AloopSettings(enabled: $enabled, loop: $loop, time: $time)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(loop >= -1, 'aloop.loop must be >= -1');
    final parts = <String>[];
    if (loop != 0) parts.add('loop=' + loop.toString());
    if (time != null)
      parts.add('time=' + (time!.inMicroseconds / 1e6).toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-aloop' : 'lavfi-aloop=' + parts.join(':');
  }
}

/// Configuration for the `ametadata` audio effect.
///
/// Manipulate frame metadata.
///
/// This filter accepts the following options:
final class AmetadataSettings {
  final bool enabled;

  const AmetadataSettings({
    this.enabled = false,
  });

  AmetadataSettings copyWith({
    bool? enabled,
  }) =>
      AmetadataSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AmetadataSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AmetadataSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-ametadata';
  }
}

/// Configuration for the `anequalizer` audio effect.
///
/// High-order parametric multiband equalizer for each channel.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [colors]: set channels curves colors (range 0..0, default "red|green|blue|yellow|orange|lime|pink|magenta|brown")
/// - [curves]: draw frequency response curves (range 0..1, default 0)
/// - [fscale]: set frequency scale (range 0..1, default 1)
/// - [mgain]: set max gain (range -900..900, default 60)
/// - [params]: This option string is in format: "c`chn` f=`cf` w=`w` g=`g` t=`f` | ..." Each equalizer band is separated by '|'. (range 0..0, default "")
final class AnequalizerSettings {
  final bool enabled;
  final String colors;
  final bool curves;
  final AnequalizerFscale fscale;
  final double mgain;
  final String params;

  const AnequalizerSettings({
    this.enabled = false,
    this.colors = 'red|green|blue|yellow|orange|lime|pink|magenta|brown',
    this.curves = false,
    this.fscale = AnequalizerFscale.log,
    this.mgain = 60.0,
    this.params = '',
  });

  AnequalizerSettings copyWith({
    bool? enabled,
    String? colors,
    bool? curves,
    AnequalizerFscale? fscale,
    double? mgain,
    String? params,
  }) =>
      AnequalizerSettings(
        enabled: enabled ?? this.enabled,
        colors: colors ?? this.colors,
        curves: curves ?? this.curves,
        fscale: fscale ?? this.fscale,
        mgain: mgain ?? this.mgain,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnequalizerSettings &&
          other.enabled == enabled &&
          other.colors == colors &&
          other.curves == curves &&
          other.fscale == fscale &&
          other.mgain == mgain &&
          other.params == params);

  @override
  int get hashCode =>
      Object.hash(enabled, colors, curves, fscale, mgain, params);

  @override
  String toString() =>
      'AnequalizerSettings(enabled: $enabled, colors: $colors, curves: $curves, fscale: $fscale, mgain: $mgain, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(mgain >= -900, 'anequalizer.mgain must be >= -900');
    assert(mgain <= 900, 'anequalizer.mgain must be <= 900');
    final parts = <String>[];
    if (colors != 'red|green|blue|yellow|orange|lime|pink|magenta|brown')
      parts.add('colors=' + colors);
    if (curves != false) parts.add('curves=' + (curves ? '1' : '0'));
    if (fscale != AnequalizerFscale.log) parts.add('fscale=' + fscale.mpvValue);
    if (mgain != 60.0) parts.add('mgain=' + mgain.toStringAsFixed(3));
    if (params != '') parts.add('params=' + params);
    return parts.isEmpty
        ? 'lavfi-anequalizer'
        : 'lavfi-anequalizer=' + parts.join(':');
  }
}

/// Configuration for the `anlmdn` audio effect.
///
/// Reduce broadband noise in audio samples using Non-Local Means algorithm.
///
/// Each sample is adjusted by looking for other samples with similar contexts. This
/// context similarity is defined by comparing their surrounding patches of size
/// @option{p}. Patches are searched in an area of @option{r} around the sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [m]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11.)
/// - [o]: Set the output mode.  It accepts the following values:
/// - [output]: Set the output mode.  It accepts the following values:
/// - [p]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000)
/// - [patch]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000)
/// - [r]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000)
/// - [research]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000)
/// - [s]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001)
/// - [smooth]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11.)
/// - [strength]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001)
final class AnlmdnSettings {
  final bool enabled;
  final double m;
  final AnlmdnMode? o;
  final AnlmdnMode? output;
  final Duration p;
  final Duration patch;
  final Duration r;
  final Duration research;
  final double s;
  final double smooth;
  final double strength;

  const AnlmdnSettings({
    this.enabled = false,
    this.m = 11.0,
    this.o,
    this.output,
    this.p = const Duration(microseconds: 2000),
    this.patch = const Duration(microseconds: 2000),
    this.r = const Duration(microseconds: 6000),
    this.research = const Duration(microseconds: 6000),
    this.s = 0.00001,
    this.smooth = 11.0,
    this.strength = 0.00001,
  });

  AnlmdnSettings copyWith({
    bool? enabled,
    double? m,
    Object? o = _unset,
    Object? output = _unset,
    Duration? p,
    Duration? patch,
    Duration? r,
    Duration? research,
    double? s,
    double? smooth,
    double? strength,
  }) =>
      AnlmdnSettings(
        enabled: enabled ?? this.enabled,
        m: m ?? this.m,
        o: identical(o, _unset) ? this.o : o as AnlmdnMode?,
        output: identical(output, _unset) ? this.output : output as AnlmdnMode?,
        p: p ?? this.p,
        patch: patch ?? this.patch,
        r: r ?? this.r,
        research: research ?? this.research,
        s: s ?? this.s,
        smooth: smooth ?? this.smooth,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnlmdnSettings &&
          other.enabled == enabled &&
          other.m == m &&
          other.o == o &&
          other.output == output &&
          other.p == p &&
          other.patch == patch &&
          other.r == r &&
          other.research == research &&
          other.s == s &&
          other.smooth == smooth &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
      enabled, m, o, output, p, patch, r, research, s, smooth, strength);

  @override
  String toString() =>
      'AnlmdnSettings(enabled: $enabled, m: $m, o: $o, output: $output, p: $p, patch: $patch, r: $r, research: $research, s: $s, smooth: $smooth, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(m >= 1, 'anlmdn.m must be >= 1');
    assert(m <= 1000, 'anlmdn.m must be <= 1000');
    assert(s >= 0.00001, 'anlmdn.s must be >= 0.00001');
    assert(s <= 10000, 'anlmdn.s must be <= 10000');
    assert(smooth >= 1, 'anlmdn.smooth must be >= 1');
    assert(smooth <= 1000, 'anlmdn.smooth must be <= 1000');
    assert(strength >= 0.00001, 'anlmdn.strength must be >= 0.00001');
    assert(strength <= 10000, 'anlmdn.strength must be <= 10000');
    final parts = <String>[];
    if (m != 11.0) parts.add('m=' + m.toStringAsFixed(3));
    if (o != null) parts.add('o=' + o!.mpvValue);
    if (output != null) parts.add('output=' + output!.mpvValue);
    if (p != const Duration(microseconds: 2000))
      parts.add('p=' + (p.inMicroseconds / 1e6).toStringAsFixed(3));
    if (patch != const Duration(microseconds: 2000))
      parts.add('patch=' + (patch.inMicroseconds / 1e6).toStringAsFixed(3));
    if (r != const Duration(microseconds: 6000))
      parts.add('r=' + (r.inMicroseconds / 1e6).toStringAsFixed(3));
    if (research != const Duration(microseconds: 6000))
      parts.add(
          'research=' + (research.inMicroseconds / 1e6).toStringAsFixed(3));
    if (s != 0.00001) parts.add('s=' + s.toStringAsFixed(3));
    if (smooth != 11.0) parts.add('smooth=' + smooth.toStringAsFixed(3));
    if (strength != 0.00001)
      parts.add('strength=' + strength.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-anlmdn' : 'lavfi-anlmdn=' + parts.join(':');
  }
}

/// Configuration for the `anull` audio effect.
///
/// Pass the audio source unchanged to the output.
final class AnullSettings {
  final bool enabled;

  const AnullSettings({
    this.enabled = false,
  });

  AnullSettings copyWith({
    bool? enabled,
  }) =>
      AnullSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnullSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AnullSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-anull';
  }
}

/// Configuration for the `apad` audio effect.
///
/// Pad the end of an audio stream with silence.
///
/// This can be used together with @command{ffmpeg} @option{-shortest} to
/// extend audio streams to the same length as the video stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [packet_size]: Set silence packet size. Default value is 4096. (default 4096)
/// - [pad_dur]: Specify the duration of samples of silence to add. See time duration syntax for the accepted syntax. Used only if set to non-negative value. (default -1)
/// - [whole_dur]: Specify the minimum total duration in the output audio stream. See time duration syntax for the accepted syntax. Used only if set to non-negative value. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_dur} (default -1)
final class ApadSettings {
  final bool enabled;
  final int packet_size;
  final Duration pad_dur;
  final Duration whole_dur;

  const ApadSettings({
    this.enabled = false,
    this.packet_size = 4096,
    this.pad_dur = const Duration(microseconds: -1),
    this.whole_dur = const Duration(microseconds: -1),
  });

  ApadSettings copyWith({
    bool? enabled,
    int? packet_size,
    Duration? pad_dur,
    Duration? whole_dur,
  }) =>
      ApadSettings(
        enabled: enabled ?? this.enabled,
        packet_size: packet_size ?? this.packet_size,
        pad_dur: pad_dur ?? this.pad_dur,
        whole_dur: whole_dur ?? this.whole_dur,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApadSettings &&
          other.enabled == enabled &&
          other.packet_size == packet_size &&
          other.pad_dur == pad_dur &&
          other.whole_dur == whole_dur);

  @override
  int get hashCode => Object.hash(enabled, packet_size, pad_dur, whole_dur);

  @override
  String toString() =>
      'ApadSettings(enabled: $enabled, packet_size: $packet_size, pad_dur: $pad_dur, whole_dur: $whole_dur)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(packet_size >= 0, 'apad.packet_size must be >= 0');
    final parts = <String>[];
    if (packet_size != 4096) parts.add('packet_size=' + packet_size.toString());
    if (pad_dur != const Duration(microseconds: -1))
      parts.add('pad_dur=' + (pad_dur.inMicroseconds / 1e6).toStringAsFixed(3));
    if (whole_dur != const Duration(microseconds: -1))
      parts.add(
          'whole_dur=' + (whole_dur.inMicroseconds / 1e6).toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-apad' : 'lavfi-apad=' + parts.join(':');
  }
}

/// Configuration for the `aperms` audio effect.
///
/// Set read/write permissions for the output frames.
///
/// These filters are mainly aimed at developers to test direct path in the
/// following filter in the filtergraph.
///
/// The filters accept the following options:
///
/// Parameters:
/// - [mode]: Select the permissions mode.  It accepts the following values:
final class ApermsSettings {
  final bool enabled;
  final ApermsMode? mode;

  const ApermsSettings({
    this.enabled = false,
    this.mode,
  });

  ApermsSettings copyWith({
    bool? enabled,
    Object? mode = _unset,
  }) =>
      ApermsSettings(
        enabled: enabled ?? this.enabled,
        mode: identical(mode, _unset) ? this.mode : mode as ApermsMode?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApermsSettings &&
          other.enabled == enabled &&
          other.mode == mode);

  @override
  int get hashCode => Object.hash(enabled, mode);

  @override
  String toString() => 'ApermsSettings(enabled: $enabled, mode: $mode)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (mode != null) parts.add('mode=' + mode!.mpvValue);
    return parts.isEmpty ? 'lavfi-aperms' : 'lavfi-aperms=' + parts.join(':');
  }
}

/// Configuration for the `aphaser` audio effect.
///
/// Add a phasing effect to the input audio.
///
/// A phaser filter creates series of peaks and troughs in the frequency spectrum.
/// The position of the peaks and troughs are modulated so that they vary over time, creating a sweeping effect.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [decay]: Set decay. Default is 0.4. (default .4)
/// - [delay]: Set delay in milliseconds. Default is 3.0. (range 0..5, default 3.)
/// - [in_gain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [out_gain]: Set output gain. Default is 0.74 (range 0..1e9, default .74)
/// - [speed]: Set modulation speed in Hz. Default is 0.5. (default .5)
/// - [type]: Set modulation type. Default is triangular.  It accepts the following values:
final class AphaserSettings {
  final bool enabled;
  final double decay;
  final double delay;
  final double in_gain;
  final double out_gain;
  final double speed;
  final AphaserType? type;

  const AphaserSettings({
    this.enabled = false,
    this.decay = .4,
    this.delay = 3.0,
    this.in_gain = .4,
    this.out_gain = .74,
    this.speed = .5,
    this.type,
  });

  AphaserSettings copyWith({
    bool? enabled,
    double? decay,
    double? delay,
    double? in_gain,
    double? out_gain,
    double? speed,
    Object? type = _unset,
  }) =>
      AphaserSettings(
        enabled: enabled ?? this.enabled,
        decay: decay ?? this.decay,
        delay: delay ?? this.delay,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
        speed: speed ?? this.speed,
        type: identical(type, _unset) ? this.type : type as AphaserType?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaserSettings &&
          other.enabled == enabled &&
          other.decay == decay &&
          other.delay == delay &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain &&
          other.speed == speed &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, decay, delay, in_gain, out_gain, speed, type);

  @override
  String toString() =>
      'AphaserSettings(enabled: $enabled, decay: $decay, delay: $delay, in_gain: $in_gain, out_gain: $out_gain, speed: $speed, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(decay >= 0, 'aphaser.decay must be >= 0');
    assert(delay >= 0, 'aphaser.delay must be >= 0');
    assert(delay <= 5, 'aphaser.delay must be <= 5');
    assert(in_gain >= 0, 'aphaser.in_gain must be >= 0');
    assert(in_gain <= 1, 'aphaser.in_gain must be <= 1');
    assert(out_gain >= 0, 'aphaser.out_gain must be >= 0');
    assert(out_gain <= 1e9, 'aphaser.out_gain must be <= 1e9');
    final parts = <String>[];
    if (decay != .4) parts.add('decay=' + decay.toStringAsFixed(3));
    if (delay != 3.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (in_gain != .4) parts.add('in_gain=' + in_gain.toStringAsFixed(3));
    if (out_gain != .74) parts.add('out_gain=' + out_gain.toStringAsFixed(3));
    if (speed != .5) parts.add('speed=' + speed.toStringAsFixed(3));
    if (type != null) parts.add('type=' + type!.mpvValue);
    return parts.isEmpty ? 'lavfi-aphaser' : 'lavfi-aphaser=' + parts.join(':');
  }
}

/// Configuration for the `aphaseshift` audio effect.
///
/// Apply phase shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (default 8)
/// - [shift]: Specify phase shift. Allowed range is from -1.0 to 1.0. Default value is 0.0. (range -1.0..1.0, default 0)
final class AphaseshiftSettings {
  final bool enabled;
  final double level;
  final int order;
  final double shift;

  const AphaseshiftSettings({
    this.enabled = false,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  AphaseshiftSettings copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) =>
      AphaseshiftSettings(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        order: order ?? this.order,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaseshiftSettings &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AphaseshiftSettings(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(level >= 0.0, 'aphaseshift.level must be >= 0.0');
    assert(level <= 1.0, 'aphaseshift.level must be <= 1.0');
    assert(order >= 1, 'aphaseshift.order must be >= 1');
    assert(shift >= -1.0, 'aphaseshift.shift must be >= -1.0');
    assert(shift <= 1.0, 'aphaseshift.shift must be <= 1.0');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + shift.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-aphaseshift'
        : 'lavfi-aphaseshift=' + parts.join(':');
  }
}

/// Configuration for the `apsyclip` audio effect.
///
/// Apply Psychoacoustic clipper to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [adaptive]: Set strength of adaptive distortion applied. Default value is 0.5. Allowed range is from 0 to 1. (range 0..1, default 0.5)
/// - [clip]: Set the clipping start value. Default value is 0dBFS or 1. (default 1)
/// - [diff]: Output only difference samples, useful to hear introduced distortions. By default is disabled. (range 0..1, default 0)
/// - [iterations]: Set number of iterations of psychoacoustic clipper. Allowed range is from 1 to 20. Default value is 10. (range 1..20, default 10)
/// - [level]: Auto level output signal. Default is disabled. This normalizes audio back to 0dBFS if enabled. (range 0..1, default 0)
/// - [level_in]: Set input gain. By default it is 1. Range is [0.015625 - 64]. (default 1)
/// - [level_out]: Set output gain. By default it is 1. Range is [0.015625 - 64]. (default 1)
final class ApsyclipSettings {
  final bool enabled;
  final double adaptive;
  final double clip;
  final bool diff;
  final int iterations;
  final bool level;
  final double level_in;
  final double level_out;

  const ApsyclipSettings({
    this.enabled = false,
    this.adaptive = 0.5,
    this.clip = 1.0,
    this.diff = false,
    this.iterations = 10,
    this.level = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
  });

  ApsyclipSettings copyWith({
    bool? enabled,
    double? adaptive,
    double? clip,
    bool? diff,
    int? iterations,
    bool? level,
    double? level_in,
    double? level_out,
  }) =>
      ApsyclipSettings(
        enabled: enabled ?? this.enabled,
        adaptive: adaptive ?? this.adaptive,
        clip: clip ?? this.clip,
        diff: diff ?? this.diff,
        iterations: iterations ?? this.iterations,
        level: level ?? this.level,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApsyclipSettings &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.clip == clip &&
          other.diff == diff &&
          other.iterations == iterations &&
          other.level == level &&
          other.level_in == level_in &&
          other.level_out == level_out);

  @override
  int get hashCode => Object.hash(
      enabled, adaptive, clip, diff, iterations, level, level_in, level_out);

  @override
  String toString() =>
      'ApsyclipSettings(enabled: $enabled, adaptive: $adaptive, clip: $clip, diff: $diff, iterations: $iterations, level: $level, level_in: $level_in, level_out: $level_out)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(adaptive >= 0, 'apsyclip.adaptive must be >= 0');
    assert(adaptive <= 1, 'apsyclip.adaptive must be <= 1');
    assert(clip >= 1, 'apsyclip.clip must be >= 1');
    assert(iterations >= 1, 'apsyclip.iterations must be >= 1');
    assert(iterations <= 20, 'apsyclip.iterations must be <= 20');
    final parts = <String>[];
    if (adaptive != 0.5) parts.add('adaptive=' + adaptive.toStringAsFixed(3));
    if (clip != 1.0) parts.add('clip=' + clip.toStringAsFixed(3));
    if (diff != false) parts.add('diff=' + (diff ? '1' : '0'));
    if (iterations != 10) parts.add('iterations=' + iterations.toString());
    if (level != false) parts.add('level=' + (level ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-apsyclip'
        : 'lavfi-apsyclip=' + parts.join(':');
  }
}

/// Configuration for the `apulsator` audio effect.
///
/// Audio pulsator is something between an autopanner and a tremolo.
/// But it can produce funny stereo effects as well. Pulsator changes the volume
/// of the left and right channel based on a LFO (low frequency oscillator) with
/// different waveforms and shifted phases.
/// This filter have the ability to define an offset between left and right
/// channel. An offset of 0 means that both LFO shapes match each other.
/// The left and right channel are altered equally - a conventional tremolo.
/// An offset of 50% means that the shape of the right channel is exactly shifted
/// in phase (or moved backwards about half of the frequency) - pulsator acts as
/// an autopanner. At 1 both curves match again. Every setting in between moves the
/// phase shift gapless between all stages and produces some "bypassing" sounds with
/// sine and triangle waveforms. The more you set the offset near 1 (starting from
/// the 0.5) the faster the signal passes from the left to the right speaker.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [amount]: Set modulation. Define how much of original signal is affected by the LFO. (range 0..1, default 1)
/// - [bpm]: Set bpm. Default is 120. Allowed range is [30 - 300]. Only used if timing is set to bpm. (range 30..300, default 120)
/// - [hz]: Set frequency in Hz. Default is 2. Allowed range is [0.01 - 100]. Only used if timing is set to hz. (range 0.01..100, default 2)
/// - [level_in]: Set input gain. By default it is 1. Range is [0.015625 - 64]. (range 0.015625..64, default 1)
/// - [level_out]: Set output gain. By default it is 1. Range is [0.015625 - 64]. (range 0.015625..64, default 1)
/// - [mode]: Set waveform shape the LFO will use. Can be one of: sine, triangle, square, sawup or sawdown. Default is sine.
/// - [ms]: Set ms. Default is 500. Allowed range is [10 - 2000]. Only used if timing is set to ms. (range 10..2000, default 500)
/// - [offset_l]: Set left channel offset. Default is 0. Allowed range is [0 - 1]. (range 0..1, default 0)
/// - [offset_r]: Set right channel offset. Default is 0.5. Allowed range is [0 - 1]. (range 0..1, default .5)
/// - [timing]: Set possible timing mode. Can be one of: bpm, ms or hz. Default is hz. (default 2)
/// - [width]: Set pulse width. Default is 1. Allowed range is [0 - 2]. (range 0..2, default 1)
final class ApulsatorSettings {
  final bool enabled;
  final double amount;
  final double bpm;
  final double hz;
  final double level_in;
  final double level_out;
  final ApulsatorMode? mode;
  final int ms;
  final double offset_l;
  final double offset_r;
  final ApulsatorTiming timing;
  final double width;

  const ApulsatorSettings({
    this.enabled = false,
    this.amount = 1.0,
    this.bpm = 120.0,
    this.hz = 2.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mode,
    this.ms = 500,
    this.offset_l = 0.0,
    this.offset_r = .5,
    this.timing = ApulsatorTiming.bpm,
    this.width = 1.0,
  });

  ApulsatorSettings copyWith({
    bool? enabled,
    double? amount,
    double? bpm,
    double? hz,
    double? level_in,
    double? level_out,
    Object? mode = _unset,
    int? ms,
    double? offset_l,
    double? offset_r,
    ApulsatorTiming? timing,
    double? width,
  }) =>
      ApulsatorSettings(
        enabled: enabled ?? this.enabled,
        amount: amount ?? this.amount,
        bpm: bpm ?? this.bpm,
        hz: hz ?? this.hz,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mode: identical(mode, _unset) ? this.mode : mode as ApulsatorMode?,
        ms: ms ?? this.ms,
        offset_l: offset_l ?? this.offset_l,
        offset_r: offset_r ?? this.offset_r,
        timing: timing ?? this.timing,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApulsatorSettings &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.bpm == bpm &&
          other.hz == hz &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mode == mode &&
          other.ms == ms &&
          other.offset_l == offset_l &&
          other.offset_r == offset_r &&
          other.timing == timing &&
          other.width == width);

  @override
  int get hashCode => Object.hash(enabled, amount, bpm, hz, level_in, level_out,
      mode, ms, offset_l, offset_r, timing, width);

  @override
  String toString() =>
      'ApulsatorSettings(enabled: $enabled, amount: $amount, bpm: $bpm, hz: $hz, level_in: $level_in, level_out: $level_out, mode: $mode, ms: $ms, offset_l: $offset_l, offset_r: $offset_r, timing: $timing, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(amount >= 0, 'apulsator.amount must be >= 0');
    assert(amount <= 1, 'apulsator.amount must be <= 1');
    assert(bpm >= 30, 'apulsator.bpm must be >= 30');
    assert(bpm <= 300, 'apulsator.bpm must be <= 300');
    assert(hz >= 0.01, 'apulsator.hz must be >= 0.01');
    assert(hz <= 100, 'apulsator.hz must be <= 100');
    assert(level_in >= 0.015625, 'apulsator.level_in must be >= 0.015625');
    assert(level_in <= 64, 'apulsator.level_in must be <= 64');
    assert(level_out >= 0.015625, 'apulsator.level_out must be >= 0.015625');
    assert(level_out <= 64, 'apulsator.level_out must be <= 64');
    assert(ms >= 10, 'apulsator.ms must be >= 10');
    assert(ms <= 2000, 'apulsator.ms must be <= 2000');
    assert(offset_l >= 0, 'apulsator.offset_l must be >= 0');
    assert(offset_l <= 1, 'apulsator.offset_l must be <= 1');
    assert(offset_r >= 0, 'apulsator.offset_r must be >= 0');
    assert(offset_r <= 1, 'apulsator.offset_r must be <= 1');
    assert(width >= 0, 'apulsator.width must be >= 0');
    assert(width <= 2, 'apulsator.width must be <= 2');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + amount.toStringAsFixed(3));
    if (bpm != 120.0) parts.add('bpm=' + bpm.toStringAsFixed(3));
    if (hz != 2.0) parts.add('hz=' + hz.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (mode != null) parts.add('mode=' + mode!.mpvValue);
    if (ms != 500) parts.add('ms=' + ms.toString());
    if (offset_l != 0.0) parts.add('offset_l=' + offset_l.toStringAsFixed(3));
    if (offset_r != .5) parts.add('offset_r=' + offset_r.toStringAsFixed(3));
    if (timing != ApulsatorTiming.bpm) parts.add('timing=' + timing.mpvValue);
    if (width != 1.0) parts.add('width=' + width.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-apulsator'
        : 'lavfi-apulsator=' + parts.join(':');
  }
}

/// Configuration for the `arealtime` audio effect.
///
/// Slow down filtering to match real time approximately.
///
/// These filters will pause the filtering for a variable amount of time to
/// match the output rate with the input timestamps.
/// They are similar to the @option{re} option to `ffmpeg`.
///
/// They accept the following options:
///
/// Parameters:
/// - [limit]: Time limit for the pauses. Any pause longer than that will be considered a timestamp discontinuity and reset the timer. Default is 2 seconds. (default 2000000)
/// - [speed]: Speed factor for processing. The value must be a float larger than zero. Values larger than 1.0 will result in faster than realtime processing, smaller will slow processing down. The `limit` is automatically adapted accordingly. Default is 1.0.  A processing speed faster than what is possible without these filters cannot be achieved. (default 1.0)
final class ArealtimeSettings {
  final bool enabled;
  final Duration limit;
  final double speed;

  const ArealtimeSettings({
    this.enabled = false,
    this.limit = const Duration(microseconds: 2000000),
    this.speed = 1.0,
  });

  ArealtimeSettings copyWith({
    bool? enabled,
    Duration? limit,
    double? speed,
  }) =>
      ArealtimeSettings(
        enabled: enabled ?? this.enabled,
        limit: limit ?? this.limit,
        speed: speed ?? this.speed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArealtimeSettings &&
          other.enabled == enabled &&
          other.limit == limit &&
          other.speed == speed);

  @override
  int get hashCode => Object.hash(enabled, limit, speed);

  @override
  String toString() =>
      'ArealtimeSettings(enabled: $enabled, limit: $limit, speed: $speed)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (limit != const Duration(microseconds: 2000000))
      parts.add('limit=' + (limit.inMicroseconds / 1e6).toStringAsFixed(3));
    if (speed != 1.0) parts.add('speed=' + speed.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-arealtime'
        : 'lavfi-arealtime=' + parts.join(':');
  }
}

/// Configuration for the `aresample` audio effect.
///
/// Resample the input audio to the specified parameters, using the
/// libswresample library. If none are specified then the filter will
/// automatically convert between its input and output.
///
/// This filter is also able to stretch/squeeze the audio data to make it match
/// the timestamps or to inject silence / cut out audio to make it match the
/// timestamps, do a combination of both or do neither.
///
/// The filter accepts the syntax
/// [`sample_rate`:]`resampler_options`, where `sample_rate`
/// expresses a sample rate and `resampler_options` is a list of
/// `key`=`value` pairs, separated by ":". See the
/// Resampler Options
/// for the complete list of supported options.
///
/// Resample the input audio to 44100Hz:
///
/// - Stretch/squeeze samples to the given timestamps, with a maximum of 1000
/// samples per second compensation:
///
/// Parameters:
/// - [sample_rate]:  (default 0)
final class AresampleSettings {
  final bool enabled;
  final int sample_rate;

  const AresampleSettings({
    this.enabled = false,
    this.sample_rate = 0,
  });

  AresampleSettings copyWith({
    bool? enabled,
    int? sample_rate,
  }) =>
      AresampleSettings(
        enabled: enabled ?? this.enabled,
        sample_rate: sample_rate ?? this.sample_rate,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AresampleSettings &&
          other.enabled == enabled &&
          other.sample_rate == sample_rate);

  @override
  int get hashCode => Object.hash(enabled, sample_rate);

  @override
  String toString() =>
      'AresampleSettings(enabled: $enabled, sample_rate: $sample_rate)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(sample_rate >= 0, 'aresample.sample_rate must be >= 0');
    final parts = <String>[];
    if (sample_rate != 0) parts.add('sample_rate=' + sample_rate.toString());
    return parts.isEmpty
        ? 'lavfi-aresample'
        : 'lavfi-aresample=' + parts.join(':');
  }
}

/// Configuration for the `areverse` audio effect.
///
/// Reverse an audio clip.
///
/// Warning: This filter requires memory to buffer the entire clip, so trimming
/// is suggested.
///
/// Take the first 5 seconds of a clip, and reverse it.
final class AreverseSettings {
  final bool enabled;

  const AreverseSettings({
    this.enabled = false,
  });

  AreverseSettings copyWith({
    bool? enabled,
  }) =>
      AreverseSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AreverseSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AreverseSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-areverse';
  }
}

/// Configuration for the `arnndn` audio effect.
///
/// Reduce noise from speech using Recurrent Neural Networks.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [m]: Set train model file to load. This option is always required. (range 0..0)
/// - [mix]: Set how much to mix filtered samples into final output. Allowed range is from -1 to 1. Default value is 1. Negative values are special, they set how much to keep filtered noise in the final filter output. Set this option to -1 to hear actual noise removed from input signal. (range -1..1, default 1.0)
/// - [model]: Set train model file to load. This option is always required. (range 0..0)
final class ArnndnSettings {
  final bool enabled;
  final String? m;
  final double mix;
  final String? model;

  const ArnndnSettings({
    this.enabled = false,
    this.m,
    this.mix = 1.0,
    this.model,
  });

  ArnndnSettings copyWith({
    bool? enabled,
    Object? m = _unset,
    double? mix,
    Object? model = _unset,
  }) =>
      ArnndnSettings(
        enabled: enabled ?? this.enabled,
        m: identical(m, _unset) ? this.m : m as String?,
        mix: mix ?? this.mix,
        model: identical(model, _unset) ? this.model : model as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArnndnSettings &&
          other.enabled == enabled &&
          other.m == m &&
          other.mix == mix &&
          other.model == model);

  @override
  int get hashCode => Object.hash(enabled, m, mix, model);

  @override
  String toString() =>
      'ArnndnSettings(enabled: $enabled, m: $m, mix: $mix, model: $model)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(mix >= -1, 'arnndn.mix must be >= -1');
    assert(mix <= 1, 'arnndn.mix must be <= 1');
    final parts = <String>[];
    if (m != null) parts.add('m=' + m!);
    if (mix != 1.0) parts.add('mix=' + mix.toStringAsFixed(3));
    if (model != null) parts.add('model=' + model!);
    return parts.isEmpty ? 'lavfi-arnndn' : 'lavfi-arnndn=' + parts.join(':');
  }
}

/// Configuration for the `asegment` audio effect.
///
/// Split single input stream into multiple streams.
///
/// This filter does opposite of concat filters.
///
/// `segment` works on video frames, `asegment` on audio samples.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [samples]: Exact frame/sample count to split the segments. (range 0..0)
final class AsegmentSettings {
  final bool enabled;
  final String? samples;

  const AsegmentSettings({
    this.enabled = false,
    this.samples,
  });

  AsegmentSettings copyWith({
    bool? enabled,
    Object? samples = _unset,
  }) =>
      AsegmentSettings(
        enabled: enabled ?? this.enabled,
        samples: identical(samples, _unset) ? this.samples : samples as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsegmentSettings &&
          other.enabled == enabled &&
          other.samples == samples);

  @override
  int get hashCode => Object.hash(enabled, samples);

  @override
  String toString() => 'AsegmentSettings(enabled: $enabled, samples: $samples)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (samples != null) parts.add('samples=' + samples!);
    return parts.isEmpty
        ? 'lavfi-asegment'
        : 'lavfi-asegment=' + parts.join(':');
  }
}

/// Configuration for the `aselect` audio effect.
///
/// Select frames to pass in output.
///
/// This filter accepts the following options:
final class AselectSettings {
  final bool enabled;

  const AselectSettings({
    this.enabled = false,
  });

  AselectSettings copyWith({
    bool? enabled,
  }) =>
      AselectSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AselectSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AselectSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-aselect';
  }
}

/// Configuration for the `asendcmd` audio effect.
///
/// Send commands to filters in the filtergraph.
///
/// These filters read commands to be sent to other filters in the
/// filtergraph.
///
/// `sendcmd` must be inserted between two video filters,
/// `asendcmd` must be inserted between two audio filters, but apart
/// from that they act the same way.
///
/// The specification of commands can be provided in the filter arguments
/// with the `commands` option, or in a file specified by the
/// `filename` option.
///
/// These filters accept the following options:
///
/// Parameters:
/// - [c]: Set the commands to be read and sent to the other filters. (range 0..0)
/// - [commands]: Set the commands to be read and sent to the other filters. (range 0..0)
/// - [f]: Set the filename of the commands to be read and sent to the other filters. (range 0..0)
/// - [filename]: Set the filename of the commands to be read and sent to the other filters. (range 0..0)
final class AsendcmdSettings {
  final bool enabled;
  final String? c;
  final String? commands;
  final String? f;
  final String? filename;

  const AsendcmdSettings({
    this.enabled = false,
    this.c,
    this.commands,
    this.f,
    this.filename,
  });

  AsendcmdSettings copyWith({
    bool? enabled,
    Object? c = _unset,
    Object? commands = _unset,
    Object? f = _unset,
    Object? filename = _unset,
  }) =>
      AsendcmdSettings(
        enabled: enabled ?? this.enabled,
        c: identical(c, _unset) ? this.c : c as String?,
        commands:
            identical(commands, _unset) ? this.commands : commands as String?,
        f: identical(f, _unset) ? this.f : f as String?,
        filename:
            identical(filename, _unset) ? this.filename : filename as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsendcmdSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.commands == commands &&
          other.f == f &&
          other.filename == filename);

  @override
  int get hashCode => Object.hash(enabled, c, commands, f, filename);

  @override
  String toString() =>
      'AsendcmdSettings(enabled: $enabled, c: $c, commands: $commands, f: $f, filename: $filename)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (c != null) parts.add('c=' + c!);
    if (commands != null) parts.add('commands=' + commands!);
    if (f != null) parts.add('f=' + f!);
    if (filename != null) parts.add('filename=' + filename!);
    return parts.isEmpty
        ? 'lavfi-asendcmd'
        : 'lavfi-asendcmd=' + parts.join(':');
  }
}

/// Configuration for the `asetnsamples` audio effect.
///
/// Set the number of samples per each output audio frame.
///
/// The last output packet may contain a different number of samples, as
/// the filter will flush all the remaining samples when the input audio
/// signals its end.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [n]: Set the number of frames per each output audio frame. The number is intended as the number of samples `per each channel`. Default value is 1024. (default 1024)
/// - [nb_out_samples]: Set the number of frames per each output audio frame. The number is intended as the number of samples `per each channel`. Default value is 1024. (default 1024)
/// - [p]: If set to 1, the filter will pad the last audio frame with zeroes, so that the last frame will contain the same number of samples as the previous ones. Default value is 1. (range 0..1, default 1)
/// - [pad]: If set to 1, the filter will pad the last audio frame with zeroes, so that the last frame will contain the same number of samples as the previous ones. Default value is 1. (range 0..1, default 1)
final class AsetnsamplesSettings {
  final bool enabled;
  final int n;
  final int nb_out_samples;
  final bool p;
  final bool pad;

  const AsetnsamplesSettings({
    this.enabled = false,
    this.n = 1024,
    this.nb_out_samples = 1024,
    this.p = true,
    this.pad = true,
  });

  AsetnsamplesSettings copyWith({
    bool? enabled,
    int? n,
    int? nb_out_samples,
    bool? p,
    bool? pad,
  }) =>
      AsetnsamplesSettings(
        enabled: enabled ?? this.enabled,
        n: n ?? this.n,
        nb_out_samples: nb_out_samples ?? this.nb_out_samples,
        p: p ?? this.p,
        pad: pad ?? this.pad,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsetnsamplesSettings &&
          other.enabled == enabled &&
          other.n == n &&
          other.nb_out_samples == nb_out_samples &&
          other.p == p &&
          other.pad == pad);

  @override
  int get hashCode => Object.hash(enabled, n, nb_out_samples, p, pad);

  @override
  String toString() =>
      'AsetnsamplesSettings(enabled: $enabled, n: $n, nb_out_samples: $nb_out_samples, p: $p, pad: $pad)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(n >= 1, 'asetnsamples.n must be >= 1');
    assert(nb_out_samples >= 1, 'asetnsamples.nb_out_samples must be >= 1');
    final parts = <String>[];
    if (n != 1024) parts.add('n=' + n.toString());
    if (nb_out_samples != 1024)
      parts.add('nb_out_samples=' + nb_out_samples.toString());
    if (p != true) parts.add('p=' + (p ? '1' : '0'));
    if (pad != true) parts.add('pad=' + (pad ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-asetnsamples'
        : 'lavfi-asetnsamples=' + parts.join(':');
  }
}

/// Configuration for the `asetpts` audio effect.
///
/// Change the PTS (presentation timestamp) of the input frames.
///
/// `setpts` works on video frames, `asetpts` on audio frames.
///
/// This filter accepts the following options:
final class AsetptsSettings {
  final bool enabled;

  const AsetptsSettings({
    this.enabled = false,
  });

  AsetptsSettings copyWith({
    bool? enabled,
  }) =>
      AsetptsSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsetptsSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsetptsSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-asetpts';
  }
}

/// Configuration for the `asetrate` audio effect.
///
/// Set the sample rate without altering the PCM data.
/// This will result in a change of speed and pitch.
///
/// The filter accepts the following options:
final class AsetrateSettings {
  final bool enabled;

  const AsetrateSettings({
    this.enabled = false,
  });

  AsetrateSettings copyWith({
    bool? enabled,
  }) =>
      AsetrateSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsetrateSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsetrateSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-asetrate';
  }
}

/// Configuration for the `asettb` audio effect.
///
/// Set the timebase to use for the output frames timestamps.
/// It is mainly useful for testing timebase configuration.
///
/// It accepts the following parameters:
final class AsettbSettings {
  final bool enabled;

  const AsettbSettings({
    this.enabled = false,
  });

  AsettbSettings copyWith({
    bool? enabled,
  }) =>
      AsettbSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsettbSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsettbSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-asettb';
  }
}

/// Configuration for the `ashowinfo` audio effect.
///
/// Show a line containing various information for each input audio frame.
/// The input audio is not modified.
///
/// The shown line contains a sequence of key/value pairs of the form
/// `key`:`value`.
///
/// The following values are shown in the output:
final class AshowinfoSettings {
  final bool enabled;

  const AshowinfoSettings({
    this.enabled = false,
  });

  AshowinfoSettings copyWith({
    bool? enabled,
  }) =>
      AshowinfoSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AshowinfoSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AshowinfoSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-ashowinfo';
  }
}

/// Configuration for the `asidedata` audio effect.
///
/// Delete frame side data, or select frames based on it.
///
/// This filter accepts the following options:
final class AsidedataSettings {
  final bool enabled;

  const AsidedataSettings({
    this.enabled = false,
  });

  AsidedataSettings copyWith({
    bool? enabled,
  }) =>
      AsidedataSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsidedataSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsidedataSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-asidedata';
  }
}

/// Configuration for the `asoftclip` audio effect.
///
/// Apply audio soft clipping.
///
/// Soft clipping is a type of distortion effect where the amplitude of a signal is saturated
/// along a smooth curve, rather than the abrupt shape of hard-clipping.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [output]: Set gain applied to output. Default value is 0dB or 1. (range 0.000001..16, default 1)
/// - [oversample]: Set oversampling factor. (default 1)
/// - [param]: Set additional parameter which controls sigmoid function. (range 0.01..3, default 1)
/// - [threshold]: Set threshold from where to start clipping. Default value is 0dB or 1. (range 0.000001..1, default 1)
/// - [type]: Set type of soft-clipping.  It accepts the following values: (default 0)
final class AsoftclipSettings {
  final bool enabled;
  final double output;
  final int oversample;
  final double param;
  final double threshold;
  final AsoftclipTypes type;

  const AsoftclipSettings({
    this.enabled = false,
    this.output = 1.0,
    this.oversample = 1,
    this.param = 1.0,
    this.threshold = 1.0,
    this.type = AsoftclipTypes.hard,
  });

  AsoftclipSettings copyWith({
    bool? enabled,
    double? output,
    int? oversample,
    double? param,
    double? threshold,
    AsoftclipTypes? type,
  }) =>
      AsoftclipSettings(
        enabled: enabled ?? this.enabled,
        output: output ?? this.output,
        oversample: oversample ?? this.oversample,
        param: param ?? this.param,
        threshold: threshold ?? this.threshold,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsoftclipSettings &&
          other.enabled == enabled &&
          other.output == output &&
          other.oversample == oversample &&
          other.param == param &&
          other.threshold == threshold &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, output, oversample, param, threshold, type);

  @override
  String toString() =>
      'AsoftclipSettings(enabled: $enabled, output: $output, oversample: $oversample, param: $param, threshold: $threshold, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(output >= 0.000001, 'asoftclip.output must be >= 0.000001');
    assert(output <= 16, 'asoftclip.output must be <= 16');
    assert(oversample >= 1, 'asoftclip.oversample must be >= 1');
    assert(param >= 0.01, 'asoftclip.param must be >= 0.01');
    assert(param <= 3, 'asoftclip.param must be <= 3');
    assert(threshold >= 0.000001, 'asoftclip.threshold must be >= 0.000001');
    assert(threshold <= 1, 'asoftclip.threshold must be <= 1');
    final parts = <String>[];
    if (output != 1.0) parts.add('output=' + output.toStringAsFixed(3));
    if (oversample != 1) parts.add('oversample=' + oversample.toString());
    if (param != 1.0) parts.add('param=' + param.toStringAsFixed(3));
    if (threshold != 1.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    if (type != AsoftclipTypes.hard) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-asoftclip'
        : 'lavfi-asoftclip=' + parts.join(':');
  }
}

/// Configuration for the `aspectralstats` audio effect.
///
/// Display frequency domain statistical information about the audio channels.
/// Statistics are calculated and stored as metadata for each audio channel and for each audio frame.
///
/// It accepts the following option:
///
/// Parameters:
/// - [measure]: select the parameters which are measured
/// - [overlap]: set window overlap (range 0..1, default 0.5)
/// - [win_size]: Set the window length in samples. Default value is 2048. Allowed range is from 32 to 65536. (range 32..65536, default 2048)
final class AspectralstatsSettings {
  final bool enabled;
  final Set<AspectralstatsMeasure> measure;
  final double overlap;
  final int win_size;

  const AspectralstatsSettings({
    this.enabled = false,
    this.measure = const <AspectralstatsMeasure>{},
    this.overlap = 0.5,
    this.win_size = 2048,
  });

  AspectralstatsSettings copyWith({
    bool? enabled,
    Set<AspectralstatsMeasure>? measure,
    double? overlap,
    int? win_size,
  }) =>
      AspectralstatsSettings(
        enabled: enabled ?? this.enabled,
        measure: measure ?? this.measure,
        overlap: overlap ?? this.overlap,
        win_size: win_size ?? this.win_size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AspectralstatsSettings &&
          other.enabled == enabled &&
          _setEq(measure, other.measure) &&
          other.overlap == overlap &&
          other.win_size == win_size);

  @override
  int get hashCode =>
      Object.hash(enabled, Object.hashAllUnordered(measure), overlap, win_size);

  @override
  String toString() =>
      'AspectralstatsSettings(enabled: $enabled, measure: $measure, overlap: $overlap, win_size: $win_size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(overlap >= 0, 'aspectralstats.overlap must be >= 0');
    assert(overlap <= 1, 'aspectralstats.overlap must be <= 1');
    assert(win_size >= 32, 'aspectralstats.win_size must be >= 32');
    assert(win_size <= 65536, 'aspectralstats.win_size must be <= 65536');
    final parts = <String>[];
    if (measure.isNotEmpty)
      parts.add('measure=' + measure.map((e) => e.mpvValue).join('+'));
    if (overlap != 0.5) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (win_size != 2048) parts.add('win_size=' + win_size.toString());
    return parts.isEmpty
        ? 'lavfi-aspectralstats'
        : 'lavfi-aspectralstats=' + parts.join(':');
  }
}

/// Configuration for the `astats` audio effect.
///
/// Display time domain statistical information about the audio channels.
/// Statistics are calculated and displayed for each audio channel and,
/// where applicable, an overall figure is also given.
///
/// It accepts the following option:
///
/// Parameters:
/// - [length]: Short window length in seconds, used for peak and trough RMS measurement. Default is `0.05` (50 milliseconds). Allowed range is `[0 - 10]`. (range 0..10, default .05)
/// - [measure_overall]: Select the parameters which are measured overall. The metadata keys can be used as flags, default is @option{all} which measures everything. @option{none} disables all overall measurement.
/// - [measure_perchannel]: Select the parameters which are measured per channel. The metadata keys can be used as flags, default is @option{all} which measures everything. @option{none} disables all per channel measurement.
/// - [metadata]: Set metadata injection. All the metadata keys are prefixed with `lavfi.astats.X`, where `X` is channel number starting from 1 or string `Overall`. Default is disabled.  Available keys for each channel are: `Bit_depth` `Crest_factor` `DC_offset` `Dynamic_range` `Entropy` `Flat_factor` `Max_difference` `Max_level` `Mean_difference` `Min_difference` `Min_level` `Noise_floor` `Noise_floor_count` `Number_of_Infs` `Number_of_NaNs` `Number_of_denormals` `Peak_count` `Abs_Peak_count` `Peak_level` `RMS_difference` `RMS_peak` `RMS_trough` `Zero_crossings` `Zero_crossings_rate`  and for `Overall`: `Bit_depth` `DC_offset` `Entropy` `Flat_factor` `Max_difference` `Max_level` `Mean_difference` `Min_difference` `Min_level` `Noise_floor` `Noise_floor_count` `Number_of_Infs` `Number_of_NaNs` `Number_of_denormals` `Number_of_samples` `Peak_count` `Abs_Peak_count` `Peak_level` `RMS_difference` `RMS_level` `RMS_peak` `RMS_trough`  For example, a full key looks like `lavfi.astats.1.DC_offset` or `lavfi.astats.Overall.Peak_count`.  Read below for the description of the keys. (range 0..1, default 0)
/// - [reset]: Set the number of frames over which cumulative stats are calculated before being reset. Default is disabled. (default 0)
final class AstatsSettings {
  final bool enabled;
  final double length;
  final Set<AstatsMeasure> measure_overall;
  final Set<AstatsMeasure> measure_perchannel;
  final bool metadata;
  final int reset;

  const AstatsSettings({
    this.enabled = false,
    this.length = .05,
    this.measure_overall = const <AstatsMeasure>{},
    this.measure_perchannel = const <AstatsMeasure>{},
    this.metadata = false,
    this.reset = 0,
  });

  AstatsSettings copyWith({
    bool? enabled,
    double? length,
    Set<AstatsMeasure>? measure_overall,
    Set<AstatsMeasure>? measure_perchannel,
    bool? metadata,
    int? reset,
  }) =>
      AstatsSettings(
        enabled: enabled ?? this.enabled,
        length: length ?? this.length,
        measure_overall: measure_overall ?? this.measure_overall,
        measure_perchannel: measure_perchannel ?? this.measure_perchannel,
        metadata: metadata ?? this.metadata,
        reset: reset ?? this.reset,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AstatsSettings &&
          other.enabled == enabled &&
          other.length == length &&
          _setEq(measure_overall, other.measure_overall) &&
          _setEq(measure_perchannel, other.measure_perchannel) &&
          other.metadata == metadata &&
          other.reset == reset);

  @override
  int get hashCode => Object.hash(
      enabled,
      length,
      Object.hashAllUnordered(measure_overall),
      Object.hashAllUnordered(measure_perchannel),
      metadata,
      reset);

  @override
  String toString() =>
      'AstatsSettings(enabled: $enabled, length: $length, measure_overall: $measure_overall, measure_perchannel: $measure_perchannel, metadata: $metadata, reset: $reset)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(length >= 0, 'astats.length must be >= 0');
    assert(length <= 10, 'astats.length must be <= 10');
    assert(reset >= 0, 'astats.reset must be >= 0');
    final parts = <String>[];
    if (length != .05) parts.add('length=' + length.toStringAsFixed(3));
    if (measure_overall.isNotEmpty)
      parts.add('measure_overall=' +
          measure_overall.map((e) => e.mpvValue).join('+'));
    if (measure_perchannel.isNotEmpty)
      parts.add('measure_perchannel=' +
          measure_perchannel.map((e) => e.mpvValue).join('+'));
    if (metadata != false) parts.add('metadata=' + (metadata ? '1' : '0'));
    if (reset != 0) parts.add('reset=' + reset.toString());
    return parts.isEmpty ? 'lavfi-astats' : 'lavfi-astats=' + parts.join(':');
  }
}

/// Configuration for the `astreamselect` audio effect.
///
/// Select video or audio streams.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [inputs]: Set number of inputs. Default is 2. (default 2)
/// - [map]: Set input indexes to remap to outputs.
final class AstreamselectSettings {
  final bool enabled;
  final int inputs;
  final String? map;

  const AstreamselectSettings({
    this.enabled = false,
    this.inputs = 2,
    this.map,
  });

  AstreamselectSettings copyWith({
    bool? enabled,
    int? inputs,
    Object? map = _unset,
  }) =>
      AstreamselectSettings(
        enabled: enabled ?? this.enabled,
        inputs: inputs ?? this.inputs,
        map: identical(map, _unset) ? this.map : map as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AstreamselectSettings &&
          other.enabled == enabled &&
          other.inputs == inputs &&
          other.map == map);

  @override
  int get hashCode => Object.hash(enabled, inputs, map);

  @override
  String toString() =>
      'AstreamselectSettings(enabled: $enabled, inputs: $inputs, map: $map)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(inputs >= 2, 'astreamselect.inputs must be >= 2');
    final parts = <String>[];
    if (inputs != 2) parts.add('inputs=' + inputs.toString());
    if (map != null) parts.add('map=' + map!);
    return parts.isEmpty
        ? 'lavfi-astreamselect'
        : 'lavfi-astreamselect=' + parts.join(':');
  }
}

/// Configuration for the `asubboost` audio effect.
///
/// Boost subwoofer frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [boost]: Set max boost factor. Allowed range is from 1 to 12. Default value is 2. (range 1..12, default 2.0)
/// - [channels]: Set the channels to process. Default value is all available. (range 0..0, default "all")
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 50 to 900. Default value is 100. (range 50..900, default 100)
/// - [decay]: Set delay line decay gain value. Allowed range is from 0 to 1. Default value is 0.0. (range 0..1, default 0.0)
/// - [delay]: Set delay. Allowed range is from 1 to 100. Default value is 20. (range 1..100, default 20)
/// - [dry]: Set dry gain, how much of original signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0)
/// - [feedback]: Set delay line feedback gain value. Allowed range is from 0 to 1. Default value is 0.9. (range 0..1, default 0.9)
/// - [slope]: Set slope amount for cutoff frequency. Allowed range is 0.0001 to 1. Default value is 0.5. (range 0.0001..1, default 0.5)
/// - [wet]: Set wet gain, how much of filtered signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0)
final class AsubboostSettings {
  final bool enabled;
  final double boost;
  final String channels;
  final double cutoff;
  final double decay;
  final double delay;
  final double dry;
  final double feedback;
  final double slope;
  final double wet;

  const AsubboostSettings({
    this.enabled = false,
    this.boost = 2.0,
    this.channels = 'all',
    this.cutoff = 100.0,
    this.decay = 0.0,
    this.delay = 20.0,
    this.dry = 1.0,
    this.feedback = 0.9,
    this.slope = 0.5,
    this.wet = 1.0,
  });

  AsubboostSettings copyWith({
    bool? enabled,
    double? boost,
    String? channels,
    double? cutoff,
    double? decay,
    double? delay,
    double? dry,
    double? feedback,
    double? slope,
    double? wet,
  }) =>
      AsubboostSettings(
        enabled: enabled ?? this.enabled,
        boost: boost ?? this.boost,
        channels: channels ?? this.channels,
        cutoff: cutoff ?? this.cutoff,
        decay: decay ?? this.decay,
        delay: delay ?? this.delay,
        dry: dry ?? this.dry,
        feedback: feedback ?? this.feedback,
        slope: slope ?? this.slope,
        wet: wet ?? this.wet,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubboostSettings &&
          other.enabled == enabled &&
          other.boost == boost &&
          other.channels == channels &&
          other.cutoff == cutoff &&
          other.decay == decay &&
          other.delay == delay &&
          other.dry == dry &&
          other.feedback == feedback &&
          other.slope == slope &&
          other.wet == wet);

  @override
  int get hashCode => Object.hash(enabled, boost, channels, cutoff, decay,
      delay, dry, feedback, slope, wet);

  @override
  String toString() =>
      'AsubboostSettings(enabled: $enabled, boost: $boost, channels: $channels, cutoff: $cutoff, decay: $decay, delay: $delay, dry: $dry, feedback: $feedback, slope: $slope, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(boost >= 1, 'asubboost.boost must be >= 1');
    assert(boost <= 12, 'asubboost.boost must be <= 12');
    assert(cutoff >= 50, 'asubboost.cutoff must be >= 50');
    assert(cutoff <= 900, 'asubboost.cutoff must be <= 900');
    assert(decay >= 0, 'asubboost.decay must be >= 0');
    assert(decay <= 1, 'asubboost.decay must be <= 1');
    assert(delay >= 1, 'asubboost.delay must be >= 1');
    assert(delay <= 100, 'asubboost.delay must be <= 100');
    assert(dry >= 0, 'asubboost.dry must be >= 0');
    assert(dry <= 1, 'asubboost.dry must be <= 1');
    assert(feedback >= 0, 'asubboost.feedback must be >= 0');
    assert(feedback <= 1, 'asubboost.feedback must be <= 1');
    assert(slope >= 0.0001, 'asubboost.slope must be >= 0.0001');
    assert(slope <= 1, 'asubboost.slope must be <= 1');
    assert(wet >= 0, 'asubboost.wet must be >= 0');
    assert(wet <= 1, 'asubboost.wet must be <= 1');
    final parts = <String>[];
    if (boost != 2.0) parts.add('boost=' + boost.toStringAsFixed(3));
    if (channels != 'all') parts.add('channels=' + channels);
    if (cutoff != 100.0) parts.add('cutoff=' + cutoff.toStringAsFixed(3));
    if (decay != 0.0) parts.add('decay=' + decay.toStringAsFixed(3));
    if (delay != 20.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (dry != 1.0) parts.add('dry=' + dry.toStringAsFixed(3));
    if (feedback != 0.9) parts.add('feedback=' + feedback.toStringAsFixed(3));
    if (slope != 0.5) parts.add('slope=' + slope.toStringAsFixed(3));
    if (wet != 1.0) parts.add('wet=' + wet.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-asubboost'
        : 'lavfi-asubboost=' + parts.join(':');
  }
}

/// Configuration for the `asubcut` audio effect.
///
/// Cut subwoofer frequencies.
///
/// This filter allows to set custom, steeper
/// roll off than highpass filter, and thus is able to more attenuate
/// frequency content in stop-band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 2 to 200. Default value is 20. (range 2..200, default 20)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1.)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10)
final class AsubcutSettings {
  final bool enabled;
  final double cutoff;
  final double level;
  final int order;

  const AsubcutSettings({
    this.enabled = false,
    this.cutoff = 20.0,
    this.level = 1.0,
    this.order = 10,
  });

  AsubcutSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) =>
      AsubcutSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        level: level ?? this.level,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubcutSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsubcutSettings(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= 2, 'asubcut.cutoff must be >= 2');
    assert(cutoff <= 200, 'asubcut.cutoff must be <= 200');
    assert(level >= 0.0, 'asubcut.level must be >= 0.0');
    assert(level <= 1.0, 'asubcut.level must be <= 1.0');
    assert(order >= 3, 'asubcut.order must be >= 3');
    assert(order <= 20, 'asubcut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20.0) parts.add('cutoff=' + cutoff.toStringAsFixed(3));
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty ? 'lavfi-asubcut' : 'lavfi-asubcut=' + parts.join(':');
  }
}

/// Configuration for the `asupercut` audio effect.
///
/// Cut super frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 20000 to 192000. Default value is 20000. (range 20000..192000, default 20000)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1.)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10)
final class AsupercutSettings {
  final bool enabled;
  final double cutoff;
  final double level;
  final int order;

  const AsupercutSettings({
    this.enabled = false,
    this.cutoff = 20000.0,
    this.level = 1.0,
    this.order = 10,
  });

  AsupercutSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) =>
      AsupercutSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        level: level ?? this.level,
        order: order ?? this.order,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsupercutSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsupercutSettings(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= 20000, 'asupercut.cutoff must be >= 20000');
    assert(cutoff <= 192000, 'asupercut.cutoff must be <= 192000');
    assert(level >= 0.0, 'asupercut.level must be >= 0.0');
    assert(level <= 1.0, 'asupercut.level must be <= 1.0');
    assert(order >= 3, 'asupercut.order must be >= 3');
    assert(order <= 20, 'asupercut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20000.0) parts.add('cutoff=' + cutoff.toStringAsFixed(3));
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty
        ? 'lavfi-asupercut'
        : 'lavfi-asupercut=' + parts.join(':');
  }
}

/// Configuration for the `asuperpass` audio effect.
///
/// Apply high order Butterworth band-pass filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1.)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1.)
final class AsuperpassSettings {
  final bool enabled;
  final double centerf;
  final double level;
  final int order;
  final double qfactor;

  const AsuperpassSettings({
    this.enabled = false,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  AsuperpassSettings copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) =>
      AsuperpassSettings(
        enabled: enabled ?? this.enabled,
        centerf: centerf ?? this.centerf,
        level: level ?? this.level,
        order: order ?? this.order,
        qfactor: qfactor ?? this.qfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperpassSettings &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperpassSettings(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(centerf >= 2, 'asuperpass.centerf must be >= 2');
    assert(centerf <= 999999, 'asuperpass.centerf must be <= 999999');
    assert(level >= 0.0, 'asuperpass.level must be >= 0.0');
    assert(level <= 2.0, 'asuperpass.level must be <= 2.0');
    assert(order >= 4, 'asuperpass.order must be >= 4');
    assert(order <= 20, 'asuperpass.order must be <= 20');
    assert(qfactor >= 0.01, 'asuperpass.qfactor must be >= 0.01');
    assert(qfactor <= 100.0, 'asuperpass.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + centerf.toStringAsFixed(3));
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + qfactor.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-asuperpass'
        : 'lavfi-asuperpass=' + parts.join(':');
  }
}

/// Configuration for the `asuperstop` audio effect.
///
/// Apply high order Butterworth band-stop filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1.)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1.)
final class AsuperstopSettings {
  final bool enabled;
  final double centerf;
  final double level;
  final int order;
  final double qfactor;

  const AsuperstopSettings({
    this.enabled = false,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  AsuperstopSettings copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) =>
      AsuperstopSettings(
        enabled: enabled ?? this.enabled,
        centerf: centerf ?? this.centerf,
        level: level ?? this.level,
        order: order ?? this.order,
        qfactor: qfactor ?? this.qfactor,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperstopSettings &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperstopSettings(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(centerf >= 2, 'asuperstop.centerf must be >= 2');
    assert(centerf <= 999999, 'asuperstop.centerf must be <= 999999');
    assert(level >= 0.0, 'asuperstop.level must be >= 0.0');
    assert(level <= 2.0, 'asuperstop.level must be <= 2.0');
    assert(order >= 4, 'asuperstop.order must be >= 4');
    assert(order <= 20, 'asuperstop.order must be <= 20');
    assert(qfactor >= 0.01, 'asuperstop.qfactor must be >= 0.01');
    assert(qfactor <= 100.0, 'asuperstop.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + centerf.toStringAsFixed(3));
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + qfactor.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-asuperstop'
        : 'lavfi-asuperstop=' + parts.join(':');
  }
}

/// Configuration for the `atempo` audio effect.
///
/// Adjust audio tempo.
///
/// The filter accepts exactly one parameter, the audio tempo. If not
/// specified then the filter will assume nominal 1.0 tempo. Tempo must
/// be in the [0.5, 100.0] range.
///
/// Note that tempo greater than 2 will skip some samples rather than
/// blend them in.  If for any reason this is a concern it is always
/// possible to daisy-chain several instances of atempo to achieve the
/// desired product tempo.
///
/// Slow down audio to 80% tempo:
///
/// - To speed up audio to 300% tempo:
///
/// - To speed up audio to 300% tempo by daisy-chaining two atempo instances:
///
/// This filter supports the following commands:
///
/// Parameters:
/// - [tempo]: Change filter tempo scale factor. Syntax for the command is : "`tempo`" (default 1.0)
final class AtempoSettings {
  final bool enabled;
  final double tempo;

  const AtempoSettings({
    this.enabled = false,
    this.tempo = 1.0,
  });

  AtempoSettings copyWith({
    bool? enabled,
    double? tempo,
  }) =>
      AtempoSettings(
        enabled: enabled ?? this.enabled,
        tempo: tempo ?? this.tempo,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtempoSettings &&
          other.enabled == enabled &&
          other.tempo == tempo);

  @override
  int get hashCode => Object.hash(enabled, tempo);

  @override
  String toString() => 'AtempoSettings(enabled: $enabled, tempo: $tempo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (tempo != 1.0) parts.add('tempo=' + tempo.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-atempo' : 'lavfi-atempo=' + parts.join(':');
  }
}

/// Configuration for the `atilt` audio effect.
///
/// Apply spectral tilt filter to audio stream.
///
/// This filter apply any spectral roll-off slope over any specified frequency band.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [freq]: Set central frequency of tilt in Hz. Default is 10000 Hz. (range 20..192000, default 10000)
/// - [level]: Set input volume level. Allowed range is from 0 to 4. Default is 1. (range 0.0..4.0, default 1.)
/// - [order]: Set order of tilt filter. (default 5)
/// - [slope]: Set slope direction of tilt. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0)
/// - [width]: Set width of tilt. Default is 1000. Allowed range is from 100 to 10000. (range 100..10000, default 1000)
final class AtiltSettings {
  final bool enabled;
  final double freq;
  final double level;
  final int order;
  final double slope;
  final double width;

  const AtiltSettings({
    this.enabled = false,
    this.freq = 10000.0,
    this.level = 1.0,
    this.order = 5,
    this.slope = 0.0,
    this.width = 1000.0,
  });

  AtiltSettings copyWith({
    bool? enabled,
    double? freq,
    double? level,
    int? order,
    double? slope,
    double? width,
  }) =>
      AtiltSettings(
        enabled: enabled ?? this.enabled,
        freq: freq ?? this.freq,
        level: level ?? this.level,
        order: order ?? this.order,
        slope: slope ?? this.slope,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtiltSettings &&
          other.enabled == enabled &&
          other.freq == freq &&
          other.level == level &&
          other.order == order &&
          other.slope == slope &&
          other.width == width);

  @override
  int get hashCode => Object.hash(enabled, freq, level, order, slope, width);

  @override
  String toString() =>
      'AtiltSettings(enabled: $enabled, freq: $freq, level: $level, order: $order, slope: $slope, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(freq >= 20, 'atilt.freq must be >= 20');
    assert(freq <= 192000, 'atilt.freq must be <= 192000');
    assert(level >= 0.0, 'atilt.level must be >= 0.0');
    assert(level <= 4.0, 'atilt.level must be <= 4.0');
    assert(order >= 2, 'atilt.order must be >= 2');
    assert(slope >= -1, 'atilt.slope must be >= -1');
    assert(slope <= 1, 'atilt.slope must be <= 1');
    assert(width >= 100, 'atilt.width must be >= 100');
    assert(width <= 10000, 'atilt.width must be <= 10000');
    final parts = <String>[];
    if (freq != 10000.0) parts.add('freq=' + freq.toStringAsFixed(3));
    if (level != 1.0) parts.add('level=' + level.toStringAsFixed(3));
    if (order != 5) parts.add('order=' + order.toString());
    if (slope != 0.0) parts.add('slope=' + slope.toStringAsFixed(3));
    if (width != 1000.0) parts.add('width=' + width.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-atilt' : 'lavfi-atilt=' + parts.join(':');
  }
}

/// Configuration for the `atrim` audio effect.
///
/// Trim the input so that the output contains one continuous subpart of the input.
///
/// It accepts the following parameters:
final class AtrimSettings {
  final bool enabled;

  const AtrimSettings({
    this.enabled = false,
  });

  AtrimSettings copyWith({
    bool? enabled,
  }) =>
      AtrimSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtrimSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AtrimSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-atrim';
  }
}

/// Configuration for the `bandpass` audio effect.
///
/// Apply a two-pole Butterworth band-pass filter with central
/// frequency `frequency`, and (3dB-point) band-width width.
/// The `csg` option selects a constant skirt gain (peak gain = Q)
/// instead of the default: constant 0dB peak gain.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [csg]: Constant skirt gain if set to 1. Defaults to 0. (range 0..1, default 0)
/// - [f]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000)
final class BandpassSettings {
  final bool enabled;
  final bool csg;
  final double f;
  final double frequency;

  const BandpassSettings({
    this.enabled = false,
    this.csg = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
  });

  BandpassSettings copyWith({
    bool? enabled,
    bool? csg,
    double? f,
    double? frequency,
  }) =>
      BandpassSettings(
        enabled: enabled ?? this.enabled,
        csg: csg ?? this.csg,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandpassSettings &&
          other.enabled == enabled &&
          other.csg == csg &&
          other.f == f &&
          other.frequency == frequency);

  @override
  int get hashCode => Object.hash(enabled, csg, f, frequency);

  @override
  String toString() =>
      'BandpassSettings(enabled: $enabled, csg: $csg, f: $f, frequency: $frequency)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'bandpass.f must be >= 0');
    assert(f <= 999999, 'bandpass.f must be <= 999999');
    assert(frequency >= 0, 'bandpass.frequency must be >= 0');
    assert(frequency <= 999999, 'bandpass.frequency must be <= 999999');
    final parts = <String>[];
    if (csg != false) parts.add('csg=' + (csg ? '1' : '0'));
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-bandpass'
        : 'lavfi-bandpass=' + parts.join(':');
  }
}

/// Configuration for the `bandreject` audio effect.
///
/// Apply a two-pole Butterworth band-reject filter with central
/// frequency `frequency`, and (3dB-point) band-width `width`.
/// The filter roll off at 6dB per octave (20dB per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000)
final class BandrejectSettings {
  final bool enabled;
  final double f;
  final double frequency;

  const BandrejectSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
  });

  BandrejectSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
  }) =>
      BandrejectSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandrejectSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency);

  @override
  int get hashCode => Object.hash(enabled, f, frequency);

  @override
  String toString() =>
      'BandrejectSettings(enabled: $enabled, f: $f, frequency: $frequency)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'bandreject.f must be >= 0');
    assert(f <= 999999, 'bandreject.f must be <= 999999');
    assert(frequency >= 0, 'bandreject.frequency must be >= 0');
    assert(frequency <= 999999, 'bandreject.frequency must be <= 999999');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-bandreject'
        : 'lavfi-bandreject=' + parts.join(':');
  }
}

/// Configuration for the `bass` audio effect.
///
/// Boost or cut the bass (lower) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class BassSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;
  final int p;
  final int poles;

  const BassSettings({
    this.enabled = false,
    this.f = 100.0,
    this.frequency = 100.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.p = 2,
    this.poles = 2,
  });

  BassSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    int? p,
    int? poles,
  }) =>
      BassSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BassSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain, p, poles);

  @override
  String toString() =>
      'BassSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'bass.f must be >= 0');
    assert(f <= 999999, 'bass.f must be <= 999999');
    assert(frequency >= 0, 'bass.frequency must be >= 0');
    assert(frequency <= 999999, 'bass.frequency must be <= 999999');
    assert(g >= -900, 'bass.g must be >= -900');
    assert(g <= 900, 'bass.g must be <= 900');
    assert(gain >= -900, 'bass.gain must be >= -900');
    assert(gain <= 900, 'bass.gain must be <= 900');
    assert(p >= 1, 'bass.p must be >= 1');
    assert(p <= 2, 'bass.p must be <= 2');
    assert(poles >= 1, 'bass.poles must be >= 1');
    assert(poles <= 2, 'bass.poles must be <= 2');
    final parts = <String>[];
    if (f != 100.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 100.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty ? 'lavfi-bass' : 'lavfi-bass=' + parts.join(':');
  }
}

/// Configuration for the `biquad` audio effect.
///
/// Apply a biquad IIR filter with the given coefficients.
/// Where `b0`, `b1`, `b2` and `a0`, `a1`, `a2`
/// are the numerator and denominator coefficients respectively.
/// and `channels`, `c` specify which channels to filter, by default all
/// available are filtered.
///
/// This filter supports the following commands:
///
/// Parameters:
/// - [a0]:  (default 1)
/// - [a1]:  (default 0)
/// - [a2]:  (default 0)
/// - [b0]:  (default 0)
/// - [b1]:  (default 0)
/// - [b2]: Change biquad parameter. Syntax for the command is : "`value`" (default 0)
final class BiquadSettings {
  final bool enabled;
  final double a0;
  final double a1;
  final double a2;
  final double b0;
  final double b1;
  final double b2;

  const BiquadSettings({
    this.enabled = false,
    this.a0 = 1.0,
    this.a1 = 0.0,
    this.a2 = 0.0,
    this.b0 = 0.0,
    this.b1 = 0.0,
    this.b2 = 0.0,
  });

  BiquadSettings copyWith({
    bool? enabled,
    double? a0,
    double? a1,
    double? a2,
    double? b0,
    double? b1,
    double? b2,
  }) =>
      BiquadSettings(
        enabled: enabled ?? this.enabled,
        a0: a0 ?? this.a0,
        a1: a1 ?? this.a1,
        a2: a2 ?? this.a2,
        b0: b0 ?? this.b0,
        b1: b1 ?? this.b1,
        b2: b2 ?? this.b2,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiquadSettings &&
          other.enabled == enabled &&
          other.a0 == a0 &&
          other.a1 == a1 &&
          other.a2 == a2 &&
          other.b0 == b0 &&
          other.b1 == b1 &&
          other.b2 == b2);

  @override
  int get hashCode => Object.hash(enabled, a0, a1, a2, b0, b1, b2);

  @override
  String toString() =>
      'BiquadSettings(enabled: $enabled, a0: $a0, a1: $a1, a2: $a2, b0: $b0, b1: $b1, b2: $b2)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (a0 != 1.0) parts.add('a0=' + a0.toStringAsFixed(3));
    if (a1 != 0.0) parts.add('a1=' + a1.toStringAsFixed(3));
    if (a2 != 0.0) parts.add('a2=' + a2.toStringAsFixed(3));
    if (b0 != 0.0) parts.add('b0=' + b0.toStringAsFixed(3));
    if (b1 != 0.0) parts.add('b1=' + b1.toStringAsFixed(3));
    if (b2 != 0.0) parts.add('b2=' + b2.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-biquad' : 'lavfi-biquad=' + parts.join(':');
  }
}

/// Configuration for the `channelmap` audio effect.
///
/// Remap input channels to new locations.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channel_layout]: The channel layout of the output stream. If not specified, then filter will guess it based on the `out_channel` names or the number of mappings. Guessed layouts will not necessarily contain channels in the order of the mappings.
/// - [map]: Map channels from input to output. The argument is a '|'-separated list of mappings, each in the `@var{in_channel`-`out_channel`} or `@var{in_channel`} form. `in_channel` can be either the name of the input channel (e.g. FL for front left) or its index in the input channel layout. `out_channel` is the name of the output channel or its index in the output channel layout. If `out_channel` is not given then it is implicitly an index, starting with zero and increasing by one for each mapping. Mixing different types of mappings is not allowed and will result in a parse error.
final class ChannelmapSettings {
  final bool enabled;
  final String? channel_layout;
  final String? map;

  const ChannelmapSettings({
    this.enabled = false,
    this.channel_layout,
    this.map,
  });

  ChannelmapSettings copyWith({
    bool? enabled,
    Object? channel_layout = _unset,
    Object? map = _unset,
  }) =>
      ChannelmapSettings(
        enabled: enabled ?? this.enabled,
        channel_layout: identical(channel_layout, _unset)
            ? this.channel_layout
            : channel_layout as String?,
        map: identical(map, _unset) ? this.map : map as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelmapSettings &&
          other.enabled == enabled &&
          other.channel_layout == channel_layout &&
          other.map == map);

  @override
  int get hashCode => Object.hash(enabled, channel_layout, map);

  @override
  String toString() =>
      'ChannelmapSettings(enabled: $enabled, channel_layout: $channel_layout, map: $map)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (channel_layout != null) parts.add('channel_layout=' + channel_layout!);
    if (map != null) parts.add('map=' + map!);
    return parts.isEmpty
        ? 'lavfi-channelmap'
        : 'lavfi-channelmap=' + parts.join(':');
  }
}

/// Configuration for the `chorus` audio effect.
///
/// Add a chorus effect to the audio.
///
/// Can make a single vocal sound like a chorus, but can also be applied to instrumentation.
///
/// Chorus resembles an echo effect with a short delay, but whereas with echo the delay is
/// constant, with chorus, it is varied using using sinusoidal or triangular modulation.
/// The modulation depth defines the range the modulated delay is played before or after
/// the delay. Hence the delayed sound will sound slower or faster, that is the delayed
/// sound tuned around the original one, like in a chorus where some vocals are slightly
/// off key.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [decays]: Set decays. (range 0..0)
/// - [delays]: Set delays. A typical delay is around 40ms to 60ms. (range 0..0)
/// - [depths]: Set depths. (range 0..0)
/// - [in_gain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [out_gain]: Set output gain. Default is 0.4. (range 0..1, default .4)
/// - [speeds]: Set speeds. (range 0..0)
final class ChorusSettings {
  final bool enabled;
  final String? decays;
  final String? delays;
  final String? depths;
  final double in_gain;
  final double out_gain;
  final String? speeds;

  const ChorusSettings({
    this.enabled = false,
    this.decays,
    this.delays,
    this.depths,
    this.in_gain = .4,
    this.out_gain = .4,
    this.speeds,
  });

  ChorusSettings copyWith({
    bool? enabled,
    Object? decays = _unset,
    Object? delays = _unset,
    Object? depths = _unset,
    double? in_gain,
    double? out_gain,
    Object? speeds = _unset,
  }) =>
      ChorusSettings(
        enabled: enabled ?? this.enabled,
        decays: identical(decays, _unset) ? this.decays : decays as String?,
        delays: identical(delays, _unset) ? this.delays : delays as String?,
        depths: identical(depths, _unset) ? this.depths : depths as String?,
        in_gain: in_gain ?? this.in_gain,
        out_gain: out_gain ?? this.out_gain,
        speeds: identical(speeds, _unset) ? this.speeds : speeds as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChorusSettings &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.depths == depths &&
          other.in_gain == in_gain &&
          other.out_gain == out_gain &&
          other.speeds == speeds);

  @override
  int get hashCode =>
      Object.hash(enabled, decays, delays, depths, in_gain, out_gain, speeds);

  @override
  String toString() =>
      'ChorusSettings(enabled: $enabled, decays: $decays, delays: $delays, depths: $depths, in_gain: $in_gain, out_gain: $out_gain, speeds: $speeds)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(in_gain >= 0, 'chorus.in_gain must be >= 0');
    assert(in_gain <= 1, 'chorus.in_gain must be <= 1');
    assert(out_gain >= 0, 'chorus.out_gain must be >= 0');
    assert(out_gain <= 1, 'chorus.out_gain must be <= 1');
    final parts = <String>[];
    if (decays != null) parts.add('decays=' + decays!);
    if (delays != null) parts.add('delays=' + delays!);
    if (depths != null) parts.add('depths=' + depths!);
    if (in_gain != .4) parts.add('in_gain=' + in_gain.toStringAsFixed(3));
    if (out_gain != .4) parts.add('out_gain=' + out_gain.toStringAsFixed(3));
    if (speeds != null) parts.add('speeds=' + speeds!);
    return parts.isEmpty ? 'lavfi-chorus' : 'lavfi-chorus=' + parts.join(':');
  }
}

/// Configuration for the `compand` audio effect.
///
/// Compress or expand the audio's dynamic range.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [attacks]: set time over which increase of volume is determined (range 0..0, default "0")
/// - [decays]: A list of times in seconds for each channel over which the instantaneous level of the input signal is averaged to determine its volume. `attacks` refers to increase of volume and `decays` refers to decrease of volume. For most situations, the attack time (response to the audio getting louder) should be shorter than the decay time, because the human ear is more sensitive to sudden loud audio than sudden soft audio. A typical value for attack is 0.3 seconds and a typical value for decay is 0.8 seconds. If specified number of attacks & decays is lower than number of channels, the last set attack/decay will be used for all remaining channels. (range 0..0, default "0.8")
/// - [delay]: Set a delay, in seconds. The input audio is analyzed immediately, but audio is delayed before being fed to the volume adjuster. Specifying a delay approximately equal to the attack/decay times allows the filter to effectively operate in predictive rather than reactive mode. It defaults to 0. (range 0..20, default 0)
/// - [gain]: Set the additional gain in dB to be applied at all points on the transfer function. This allows for easy adjustment of the overall gain. It defaults to 0. (range -900..900, default 0)
/// - [points]: A list of points for the transfer function, specified in dB relative to the maximum possible signal amplitude. Each key points list must be defined using the following syntax: `x0/y0|x1/y1|x2/y2|....` or `x0/y0 x1/y1 x2/y2 ....`  The input values must be in strictly increasing order but the transfer function does not have to be monotonically rising. The point `0/0` is assumed but may be overridden (by `0/out-dBn`). Typical values for the transfer function are `-70/-70|-60/-20|1/0`. (range 0..0, default "-70/-70|-60/-20|1/0")
/// - [volume]: Set an initial volume, in dB, to be assumed for each channel when filtering starts. This permits the user to supply a nominal level initially, so that, for example, a very large gain is not applied to initial signal levels before the companding has begun to operate. A typical value for audio which is initially quiet is -90 dB. It defaults to 0. (range -900..0, default 0)
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `soft-knee`: Set the curve radius in dB for all joints. It defaults to 0.01. (range 0.01..900, default 0.01)
final class CompandSettings {
  final bool enabled;
  final String attacks;
  final String decays;
  final double delay;
  final double gain;
  final String points;
  final double volume;
  final Map<String, double> params;

  const CompandSettings({
    this.enabled = false,
    this.attacks = '0',
    this.decays = '0.8',
    this.delay = 0.0,
    this.gain = 0.0,
    this.points = '-70/-70|-60/-20|1/0',
    this.volume = 0.0,
    this.params = const <String, double>{},
  });

  CompandSettings copyWith({
    bool? enabled,
    String? attacks,
    String? decays,
    double? delay,
    double? gain,
    String? points,
    double? volume,
    Map<String, double>? params,
  }) =>
      CompandSettings(
        enabled: enabled ?? this.enabled,
        attacks: attacks ?? this.attacks,
        decays: decays ?? this.decays,
        delay: delay ?? this.delay,
        gain: gain ?? this.gain,
        points: points ?? this.points,
        volume: volume ?? this.volume,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompandSettings &&
          other.enabled == enabled &&
          other.attacks == attacks &&
          other.decays == decays &&
          other.delay == delay &&
          other.gain == gain &&
          other.points == points &&
          other.volume == volume &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
      enabled,
      attacks,
      decays,
      delay,
      gain,
      points,
      volume,
      Object.hashAllUnordered(
          params.entries.map((e) => Object.hash(e.key, e.value))));

  @override
  String toString() =>
      'CompandSettings(enabled: $enabled, attacks: $attacks, decays: $decays, delay: $delay, gain: $gain, points: $points, volume: $volume, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(delay >= 0, 'compand.delay must be >= 0');
    assert(delay <= 20, 'compand.delay must be <= 20');
    assert(gain >= -900, 'compand.gain must be >= -900');
    assert(gain <= 900, 'compand.gain must be <= 900');
    assert(volume >= -900, 'compand.volume must be >= -900');
    assert(volume <= 0, 'compand.volume must be <= 0');
    final parts = <String>[];
    if (attacks != '0') parts.add('attacks=' + attacks);
    if (decays != '0.8') parts.add('decays=' + decays);
    if (delay != 0.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (points != '-70/-70|-60/-20|1/0') parts.add('points=' + points);
    if (volume != 0.0) parts.add('volume=' + volume.toStringAsFixed(3));
    params.forEach((k, v) => parts.add('$k=' + v.toStringAsFixed(3)));
    return parts.isEmpty ? 'lavfi-compand' : 'lavfi-compand=' + parts.join(':');
  }
}

/// Configuration for the `compensationdelay` audio effect.
///
/// Compensation Delay Line is a metric based delay to compensate differing
/// positions of microphones or speakers.
///
/// For example, you have recorded guitar with two microphones placed in
/// different locations. Because the front of sound wave has fixed speed in
/// normal conditions, the phasing of microphones can vary and depends on
/// their location and interposition. The best sound mix can be achieved when
/// these microphones are in phase (synchronized). Note that a distance of
/// ~30 cm between microphones makes one microphone capture the signal in
/// antiphase to the other microphone. That makes the final mix sound moody.
/// This filter helps to solve phasing problems by adding different delays
/// to each microphone track and make them synchronized.
///
/// The best result can be reached when you take one track as base and
/// synchronize other tracks one by one with it.
/// Remember that synchronization/delay tolerance depends on sample rate, too.
/// Higher sample rates will give more tolerance.
///
/// The filter accepts the following parameters:
///
/// Parameters:
/// - [cm]: Set cm distance. This is compensation distance for tightening distance setup. Default is 0. (range 0..100, default 0)
/// - [dry]: Set dry amount. Amount of unprocessed (dry) signal. Default is 0. (range 0..1, default 0)
/// - [m]: Set meters distance. This is compensation distance for hard distance setup. Default is 0. (range 0..100, default 0)
/// - [mm]: Set millimeters distance. This is compensation distance for fine tuning. Default is 0. (range 0..10, default 0)
/// - [temp]: Set temperature in degrees Celsius. This is the temperature of the environment. Default is 20. (range -50..50, default 20)
/// - [wet]: Set wet amount. Amount of processed (wet) signal. Default is 1. (range 0..1, default 1)
final class CompensationdelaySettings {
  final bool enabled;
  final int cm;
  final double dry;
  final int m;
  final int mm;
  final int temp;
  final double wet;

  const CompensationdelaySettings({
    this.enabled = false,
    this.cm = 0,
    this.dry = 0.0,
    this.m = 0,
    this.mm = 0,
    this.temp = 20,
    this.wet = 1.0,
  });

  CompensationdelaySettings copyWith({
    bool? enabled,
    int? cm,
    double? dry,
    int? m,
    int? mm,
    int? temp,
    double? wet,
  }) =>
      CompensationdelaySettings(
        enabled: enabled ?? this.enabled,
        cm: cm ?? this.cm,
        dry: dry ?? this.dry,
        m: m ?? this.m,
        mm: mm ?? this.mm,
        temp: temp ?? this.temp,
        wet: wet ?? this.wet,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompensationdelaySettings &&
          other.enabled == enabled &&
          other.cm == cm &&
          other.dry == dry &&
          other.m == m &&
          other.mm == mm &&
          other.temp == temp &&
          other.wet == wet);

  @override
  int get hashCode => Object.hash(enabled, cm, dry, m, mm, temp, wet);

  @override
  String toString() =>
      'CompensationdelaySettings(enabled: $enabled, cm: $cm, dry: $dry, m: $m, mm: $mm, temp: $temp, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cm >= 0, 'compensationdelay.cm must be >= 0');
    assert(cm <= 100, 'compensationdelay.cm must be <= 100');
    assert(dry >= 0, 'compensationdelay.dry must be >= 0');
    assert(dry <= 1, 'compensationdelay.dry must be <= 1');
    assert(m >= 0, 'compensationdelay.m must be >= 0');
    assert(m <= 100, 'compensationdelay.m must be <= 100');
    assert(mm >= 0, 'compensationdelay.mm must be >= 0');
    assert(mm <= 10, 'compensationdelay.mm must be <= 10');
    assert(temp >= -50, 'compensationdelay.temp must be >= -50');
    assert(temp <= 50, 'compensationdelay.temp must be <= 50');
    assert(wet >= 0, 'compensationdelay.wet must be >= 0');
    assert(wet <= 1, 'compensationdelay.wet must be <= 1');
    final parts = <String>[];
    if (cm != 0) parts.add('cm=' + cm.toString());
    if (dry != 0.0) parts.add('dry=' + dry.toStringAsFixed(3));
    if (m != 0) parts.add('m=' + m.toString());
    if (mm != 0) parts.add('mm=' + mm.toString());
    if (temp != 20) parts.add('temp=' + temp.toString());
    if (wet != 1.0) parts.add('wet=' + wet.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-compensationdelay'
        : 'lavfi-compensationdelay=' + parts.join(':');
  }
}

/// Configuration for the `crossfeed` audio effect.
///
/// Apply headphone crossfeed filter.
///
/// Crossfeed is the process of blending the left and right channels of stereo
/// audio recording.
/// It is mainly used to reduce extreme stereo separation of low frequencies.
///
/// The intent is to produce more speaker like sound to the listener.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [block_size]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [level_in]: Set input gain. Default is 0.9. (range 0..1, default .9)
/// - [level_out]: Set output gain. Default is 1. (range 0..1, default 1.)
/// - [range]: Set soundstage wideness. Default is 0.5. Allowed range is from 0 to 1. This sets cut off frequency of low shelf filter. Default is cut off near 1550 Hz. With range set to 1 cut off frequency is set to 2100 Hz. (range 0..1, default .5)
/// - [slope]: Set curve slope of low shelf filter. Default is 0.5. Allowed range is from 0.01 to 1. (default .5)
/// - [strength]: Set strength of crossfeed. Default is 0.2. Allowed range is from 0 to 1. This sets gain of low shelf filter for side part of stereo image. Default is -6dB. Max allowed is -30db when strength is set to 1. (range 0..1, default .2)
final class CrossfeedSettings {
  final bool enabled;
  final int block_size;
  final double level_in;
  final double level_out;
  final double range;
  final double slope;
  final double strength;

  const CrossfeedSettings({
    this.enabled = false,
    this.block_size = 0,
    this.level_in = .9,
    this.level_out = 1.0,
    this.range = .5,
    this.slope = .5,
    this.strength = .2,
  });

  CrossfeedSettings copyWith({
    bool? enabled,
    int? block_size,
    double? level_in,
    double? level_out,
    double? range,
    double? slope,
    double? strength,
  }) =>
      CrossfeedSettings(
        enabled: enabled ?? this.enabled,
        block_size: block_size ?? this.block_size,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        range: range ?? this.range,
        slope: slope ?? this.slope,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfeedSettings &&
          other.enabled == enabled &&
          other.block_size == block_size &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.range == range &&
          other.slope == slope &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
      enabled, block_size, level_in, level_out, range, slope, strength);

  @override
  String toString() =>
      'CrossfeedSettings(enabled: $enabled, block_size: $block_size, level_in: $level_in, level_out: $level_out, range: $range, slope: $slope, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(block_size >= 0, 'crossfeed.block_size must be >= 0');
    assert(block_size <= 32768, 'crossfeed.block_size must be <= 32768');
    assert(level_in >= 0, 'crossfeed.level_in must be >= 0');
    assert(level_in <= 1, 'crossfeed.level_in must be <= 1');
    assert(level_out >= 0, 'crossfeed.level_out must be >= 0');
    assert(level_out <= 1, 'crossfeed.level_out must be <= 1');
    assert(range >= 0, 'crossfeed.range must be >= 0');
    assert(range <= 1, 'crossfeed.range must be <= 1');
    assert(strength >= 0, 'crossfeed.strength must be >= 0');
    assert(strength <= 1, 'crossfeed.strength must be <= 1');
    final parts = <String>[];
    if (block_size != 0) parts.add('block_size=' + block_size.toString());
    if (level_in != .9) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (range != .5) parts.add('range=' + range.toStringAsFixed(3));
    if (slope != .5) parts.add('slope=' + slope.toStringAsFixed(3));
    if (strength != .2) parts.add('strength=' + strength.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-crossfeed'
        : 'lavfi-crossfeed=' + parts.join(':');
  }
}

/// Configuration for the `crystalizer` audio effect.
///
/// Simple algorithm for audio noise sharpening.
///
/// This filter linearly increases differences between each audio sample.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1)
/// - [i]: Sets the intensity of effect (default: 2.0). Must be in range between -10.0 to 0 (unchanged sound) to 10.0 (maximum effect). To inverse filtering use negative value. (range -10..10, default 2.0)
final class CrystalizerSettings {
  final bool enabled;
  final bool c;
  final double i;

  const CrystalizerSettings({
    this.enabled = false,
    this.c = true,
    this.i = 2.0,
  });

  CrystalizerSettings copyWith({
    bool? enabled,
    bool? c,
    double? i,
  }) =>
      CrystalizerSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        i: i ?? this.i,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrystalizerSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.i == i);

  @override
  int get hashCode => Object.hash(enabled, c, i);

  @override
  String toString() => 'CrystalizerSettings(enabled: $enabled, c: $c, i: $i)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(i >= -10, 'crystalizer.i must be >= -10');
    assert(i <= 10, 'crystalizer.i must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (i != 2.0) parts.add('i=' + i.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-crystalizer'
        : 'lavfi-crystalizer=' + parts.join(':');
  }
}

/// Configuration for the `dcshift` audio effect.
///
/// Apply a DC shift to the audio.
///
/// This can be useful to remove a DC offset (caused perhaps by a hardware problem
/// in the recording chain) from the audio. The effect of a DC offset is reduced
/// headroom and hence volume. The astats filter can be used to determine if
/// a signal has a DC offset.
///
/// Parameters:
/// - [limitergain]: Optional. It should have a value much less than 1 (e.g. 0.05 or 0.02) and is used to prevent clipping. (range 0..1, default 0)
/// - [shift]: Set the DC shift, allowed range is [-1, 1]. It indicates the amount to shift the audio. (range -1..1, default 0)
final class DcshiftSettings {
  final bool enabled;
  final double limitergain;
  final double shift;

  const DcshiftSettings({
    this.enabled = false,
    this.limitergain = 0.0,
    this.shift = 0.0,
  });

  DcshiftSettings copyWith({
    bool? enabled,
    double? limitergain,
    double? shift,
  }) =>
      DcshiftSettings(
        enabled: enabled ?? this.enabled,
        limitergain: limitergain ?? this.limitergain,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DcshiftSettings &&
          other.enabled == enabled &&
          other.limitergain == limitergain &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, limitergain, shift);

  @override
  String toString() =>
      'DcshiftSettings(enabled: $enabled, limitergain: $limitergain, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(limitergain >= 0, 'dcshift.limitergain must be >= 0');
    assert(limitergain <= 1, 'dcshift.limitergain must be <= 1');
    assert(shift >= -1, 'dcshift.shift must be >= -1');
    assert(shift <= 1, 'dcshift.shift must be <= 1');
    final parts = <String>[];
    if (limitergain != 0.0)
      parts.add('limitergain=' + limitergain.toStringAsFixed(3));
    if (shift != 0.0) parts.add('shift=' + shift.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-dcshift' : 'lavfi-dcshift=' + parts.join(':');
  }
}

/// Configuration for the `deesser` audio effect.
///
/// Apply de-essing to the audio samples.
///
/// Parameters:
/// - [f]: How much of original frequency content to keep when de-essing. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [i]: Set intensity for triggering de-essing. Allowed range is from 0 to 1. Default is 0. (range 0.0..1.0, default 0.0)
/// - [m]: Set amount of ducking on treble part of sound. Allowed range is from 0 to 1. Default is 0.5. (range 0.0..1.0, default 0.5)
/// - [s]: Set the output mode.  It accepts the following values:
final class DeesserSettings {
  final bool enabled;
  final double f;
  final double i;
  final double m;
  final DeesserMode? s;

  const DeesserSettings({
    this.enabled = false,
    this.f = 0.5,
    this.i = 0.0,
    this.m = 0.5,
    this.s,
  });

  DeesserSettings copyWith({
    bool? enabled,
    double? f,
    double? i,
    double? m,
    Object? s = _unset,
  }) =>
      DeesserSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        i: i ?? this.i,
        m: m ?? this.m,
        s: identical(s, _unset) ? this.s : s as DeesserMode?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeesserSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.i == i &&
          other.m == m &&
          other.s == s);

  @override
  int get hashCode => Object.hash(enabled, f, i, m, s);

  @override
  String toString() =>
      'DeesserSettings(enabled: $enabled, f: $f, i: $i, m: $m, s: $s)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0.0, 'deesser.f must be >= 0.0');
    assert(f <= 1.0, 'deesser.f must be <= 1.0');
    assert(i >= 0.0, 'deesser.i must be >= 0.0');
    assert(i <= 1.0, 'deesser.i must be <= 1.0');
    assert(m >= 0.0, 'deesser.m must be >= 0.0');
    assert(m <= 1.0, 'deesser.m must be <= 1.0');
    final parts = <String>[];
    if (f != 0.5) parts.add('f=' + f.toStringAsFixed(3));
    if (i != 0.0) parts.add('i=' + i.toStringAsFixed(3));
    if (m != 0.5) parts.add('m=' + m.toStringAsFixed(3));
    if (s != null) parts.add('s=' + s!.mpvValue);
    return parts.isEmpty ? 'lavfi-deesser' : 'lavfi-deesser=' + parts.join(':');
  }
}

/// Configuration for the `dialoguenhance` audio effect.
///
/// Enhance dialogue in stereo audio.
///
/// This filter accepts stereo input and produce surround (3.0) channels output.
/// The newly produced front center channel have enhanced speech dialogue originally
/// available in both stereo channels.
/// This filter outputs front left and front right channels same as available in stereo input.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [enhance]: Set the dialogue enhance factor to put in front center channel output. Allowed range is from 0 to 3. Default value is 1. (range 0..3, default 1)
/// - [original]: Set the original center factor to keep in front center channel output. Allowed range is from 0 to 1. Default value is 1. (range 0..1, default 1)
/// - [voice]: Set the voice detection factor. Allowed range is from 2 to 32. Default value is 2. (range 2..32, default 2)
final class DialoguenhanceSettings {
  final bool enabled;
  final double enhance;
  final double original;
  final double voice;

  const DialoguenhanceSettings({
    this.enabled = false,
    this.enhance = 1.0,
    this.original = 1.0,
    this.voice = 2.0,
  });

  DialoguenhanceSettings copyWith({
    bool? enabled,
    double? enhance,
    double? original,
    double? voice,
  }) =>
      DialoguenhanceSettings(
        enabled: enabled ?? this.enabled,
        enhance: enhance ?? this.enhance,
        original: original ?? this.original,
        voice: voice ?? this.voice,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialoguenhanceSettings &&
          other.enabled == enabled &&
          other.enhance == enhance &&
          other.original == original &&
          other.voice == voice);

  @override
  int get hashCode => Object.hash(enabled, enhance, original, voice);

  @override
  String toString() =>
      'DialoguenhanceSettings(enabled: $enabled, enhance: $enhance, original: $original, voice: $voice)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(enhance >= 0, 'dialoguenhance.enhance must be >= 0');
    assert(enhance <= 3, 'dialoguenhance.enhance must be <= 3');
    assert(original >= 0, 'dialoguenhance.original must be >= 0');
    assert(original <= 1, 'dialoguenhance.original must be <= 1');
    assert(voice >= 2, 'dialoguenhance.voice must be >= 2');
    assert(voice <= 32, 'dialoguenhance.voice must be <= 32');
    final parts = <String>[];
    if (enhance != 1.0) parts.add('enhance=' + enhance.toStringAsFixed(3));
    if (original != 1.0) parts.add('original=' + original.toStringAsFixed(3));
    if (voice != 2.0) parts.add('voice=' + voice.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-dialoguenhance'
        : 'lavfi-dialoguenhance=' + parts.join(':');
  }
}

/// Configuration for the `drmeter` audio effect.
///
/// Measure audio dynamic range.
///
/// DR values of 14 and higher is found in very dynamic material. DR of 8 to 13
/// is found in transition material. And anything less that 8 have very poor dynamics
/// and is very compressed.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [length]: Set window length in seconds used to split audio into segments of equal length. Default is 3 seconds. (default 3)
final class DrmeterSettings {
  final bool enabled;
  final double length;

  const DrmeterSettings({
    this.enabled = false,
    this.length = 3.0,
  });

  DrmeterSettings copyWith({
    bool? enabled,
    double? length,
  }) =>
      DrmeterSettings(
        enabled: enabled ?? this.enabled,
        length: length ?? this.length,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrmeterSettings &&
          other.enabled == enabled &&
          other.length == length);

  @override
  int get hashCode => Object.hash(enabled, length);

  @override
  String toString() => 'DrmeterSettings(enabled: $enabled, length: $length)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (length != 3.0) parts.add('length=' + length.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-drmeter' : 'lavfi-drmeter=' + parts.join(':');
  }
}

/// Configuration for the `dynaudnorm` audio effect.
///
/// Dynamic Audio Normalizer.
///
/// This filter applies a certain amount of gain to the input audio in order
/// to bring its peak magnitude to a target level (e.g. 0 dBFS). However, in
/// contrast to more "simple" normalization algorithms, the Dynamic Audio
/// Normalizer *dynamically* re-adjusts the gain factor to the input audio.
/// This allows for applying extra gain to the "quiet" sections of the audio
/// while avoiding distortions or clipping the "loud" sections. In other words:
/// The Dynamic Audio Normalizer will "even out" the volume of quiet and loud
/// sections, in the sense that the volume of each section is brought to the
/// same target level. Note, however, that the Dynamic Audio Normalizer achieves
/// this goal *without* applying "dynamic range compressing". It will retain 100%
/// of the dynamic range *within* each section of the audio file.
///
/// Parameters:
/// - [altboundary]: Enable alternative boundary mode. By default is disabled. The Dynamic Audio Normalizer takes into account a certain neighbourhood around each frame. This includes the preceding frames as well as the subsequent frames. However, for the "boundary" frames, located at the very beginning and at the very end of the audio file, not all neighbouring frames are available. In particular, for the first few frames in the audio file, the preceding frames are not known. And, similarly, for the last few frames in the audio file, the subsequent frames are not known. Thus, the question arises which gain factors should be assumed for the missing frames in the "boundary" region. The Dynamic Audio Normalizer implements two modes to deal with this situation. The default boundary mode assumes a gain factor of exactly 1.0 for the missing frames, resulting in a smooth "fade in" and "fade out" at the beginning and at the end of the input, respectively. (range 0..1, default 0)
/// - [b]: Enable alternative boundary mode. By default is disabled. The Dynamic Audio Normalizer takes into account a certain neighbourhood around each frame. This includes the preceding frames as well as the subsequent frames. However, for the "boundary" frames, located at the very beginning and at the very end of the audio file, not all neighbouring frames are available. In particular, for the first few frames in the audio file, the preceding frames are not known. And, similarly, for the last few frames in the audio file, the subsequent frames are not known. Thus, the question arises which gain factors should be assumed for the missing frames in the "boundary" region. The Dynamic Audio Normalizer implements two modes to deal with this situation. The default boundary mode assumes a gain factor of exactly 1.0 for the missing frames, resulting in a smooth "fade in" and "fade out" at the beginning and at the end of the input, respectively. (range 0..1, default 0)
/// - [c]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0)
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all")
/// - [compress]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0)
/// - [correctdc]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0)
/// - [coupling]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1)
/// - [curve]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants:
/// - [f]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500)
/// - [framelen]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500)
/// - [g]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31)
/// - [gausssize]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31)
/// - [h]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all")
/// - [m]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0)
/// - [maxgain]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0)
/// - [n]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1)
/// - [o]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0)
/// - [overlap]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0)
/// - [p]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95)
/// - [peak]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95)
/// - [r]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0)
/// - [s]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0)
/// - [t]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0)
/// - [targetrms]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0)
/// - [threshold]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0)
/// - [v]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants:
final class DynaudnormSettings {
  final bool enabled;
  final bool altboundary;
  final bool b;
  final bool c;
  final String channels;
  final double compress;
  final bool correctdc;
  final bool coupling;
  final String? curve;
  final int f;
  final int framelen;
  final int g;
  final int gausssize;
  final String h;
  final double m;
  final double maxgain;
  final bool n;
  final double o;
  final double overlap;
  final double p;
  final double peak;
  final double r;
  final double s;
  final double t;
  final double targetrms;
  final double threshold;
  final String? v;

  const DynaudnormSettings({
    this.enabled = false,
    this.altboundary = false,
    this.b = false,
    this.c = false,
    this.channels = 'all',
    this.compress = 0.0,
    this.correctdc = false,
    this.coupling = true,
    this.curve,
    this.f = 500,
    this.framelen = 500,
    this.g = 31,
    this.gausssize = 31,
    this.h = 'all',
    this.m = 10.0,
    this.maxgain = 10.0,
    this.n = true,
    this.o = .0,
    this.overlap = .0,
    this.p = 0.95,
    this.peak = 0.95,
    this.r = 0.0,
    this.s = 0.0,
    this.t = 0.0,
    this.targetrms = 0.0,
    this.threshold = 0.0,
    this.v,
  });

  DynaudnormSettings copyWith({
    bool? enabled,
    bool? altboundary,
    bool? b,
    bool? c,
    String? channels,
    double? compress,
    bool? correctdc,
    bool? coupling,
    Object? curve = _unset,
    int? f,
    int? framelen,
    int? g,
    int? gausssize,
    String? h,
    double? m,
    double? maxgain,
    bool? n,
    double? o,
    double? overlap,
    double? p,
    double? peak,
    double? r,
    double? s,
    double? t,
    double? targetrms,
    double? threshold,
    Object? v = _unset,
  }) =>
      DynaudnormSettings(
        enabled: enabled ?? this.enabled,
        altboundary: altboundary ?? this.altboundary,
        b: b ?? this.b,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        compress: compress ?? this.compress,
        correctdc: correctdc ?? this.correctdc,
        coupling: coupling ?? this.coupling,
        curve: identical(curve, _unset) ? this.curve : curve as String?,
        f: f ?? this.f,
        framelen: framelen ?? this.framelen,
        g: g ?? this.g,
        gausssize: gausssize ?? this.gausssize,
        h: h ?? this.h,
        m: m ?? this.m,
        maxgain: maxgain ?? this.maxgain,
        n: n ?? this.n,
        o: o ?? this.o,
        overlap: overlap ?? this.overlap,
        p: p ?? this.p,
        peak: peak ?? this.peak,
        r: r ?? this.r,
        s: s ?? this.s,
        t: t ?? this.t,
        targetrms: targetrms ?? this.targetrms,
        threshold: threshold ?? this.threshold,
        v: identical(v, _unset) ? this.v : v as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DynaudnormSettings &&
          other.enabled == enabled &&
          other.altboundary == altboundary &&
          other.b == b &&
          other.c == c &&
          other.channels == channels &&
          other.compress == compress &&
          other.correctdc == correctdc &&
          other.coupling == coupling &&
          other.curve == curve &&
          other.f == f &&
          other.framelen == framelen &&
          other.g == g &&
          other.gausssize == gausssize &&
          other.h == h &&
          other.m == m &&
          other.maxgain == maxgain &&
          other.n == n &&
          other.o == o &&
          other.overlap == overlap &&
          other.p == p &&
          other.peak == peak &&
          other.r == r &&
          other.s == s &&
          other.t == t &&
          other.targetrms == targetrms &&
          other.threshold == threshold &&
          other.v == v);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        altboundary,
        b,
        c,
        channels,
        compress,
        correctdc,
        coupling,
        curve,
        f,
        framelen,
        g,
        gausssize,
        h,
        m,
        maxgain,
        n,
        o,
        overlap,
        p,
        peak,
        r,
        s,
        t,
        targetrms,
        threshold,
        v
      ]);

  @override
  String toString() =>
      'DynaudnormSettings(enabled: $enabled, altboundary: $altboundary, b: $b, c: $c, channels: $channels, compress: $compress, correctdc: $correctdc, coupling: $coupling, curve: $curve, f: $f, framelen: $framelen, g: $g, gausssize: $gausssize, h: $h, m: $m, maxgain: $maxgain, n: $n, o: $o, overlap: $overlap, p: $p, peak: $peak, r: $r, s: $s, t: $t, targetrms: $targetrms, threshold: $threshold, v: $v)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(compress >= 0.0, 'dynaudnorm.compress must be >= 0.0');
    assert(compress <= 30.0, 'dynaudnorm.compress must be <= 30.0');
    assert(f >= 10, 'dynaudnorm.f must be >= 10');
    assert(f <= 8000, 'dynaudnorm.f must be <= 8000');
    assert(framelen >= 10, 'dynaudnorm.framelen must be >= 10');
    assert(framelen <= 8000, 'dynaudnorm.framelen must be <= 8000');
    assert(g >= 3, 'dynaudnorm.g must be >= 3');
    assert(g <= 301, 'dynaudnorm.g must be <= 301');
    assert(gausssize >= 3, 'dynaudnorm.gausssize must be >= 3');
    assert(gausssize <= 301, 'dynaudnorm.gausssize must be <= 301');
    assert(m >= 1.0, 'dynaudnorm.m must be >= 1.0');
    assert(m <= 100.0, 'dynaudnorm.m must be <= 100.0');
    assert(maxgain >= 1.0, 'dynaudnorm.maxgain must be >= 1.0');
    assert(maxgain <= 100.0, 'dynaudnorm.maxgain must be <= 100.0');
    assert(o >= 0.0, 'dynaudnorm.o must be >= 0.0');
    assert(o <= 1.0, 'dynaudnorm.o must be <= 1.0');
    assert(overlap >= 0.0, 'dynaudnorm.overlap must be >= 0.0');
    assert(overlap <= 1.0, 'dynaudnorm.overlap must be <= 1.0');
    assert(p >= 0.0, 'dynaudnorm.p must be >= 0.0');
    assert(p <= 1.0, 'dynaudnorm.p must be <= 1.0');
    assert(peak >= 0.0, 'dynaudnorm.peak must be >= 0.0');
    assert(peak <= 1.0, 'dynaudnorm.peak must be <= 1.0');
    assert(r >= 0.0, 'dynaudnorm.r must be >= 0.0');
    assert(r <= 1.0, 'dynaudnorm.r must be <= 1.0');
    assert(s >= 0.0, 'dynaudnorm.s must be >= 0.0');
    assert(s <= 30.0, 'dynaudnorm.s must be <= 30.0');
    assert(t >= 0.0, 'dynaudnorm.t must be >= 0.0');
    assert(t <= 1.0, 'dynaudnorm.t must be <= 1.0');
    assert(targetrms >= 0.0, 'dynaudnorm.targetrms must be >= 0.0');
    assert(targetrms <= 1.0, 'dynaudnorm.targetrms must be <= 1.0');
    assert(threshold >= 0.0, 'dynaudnorm.threshold must be >= 0.0');
    assert(threshold <= 1.0, 'dynaudnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (altboundary != false)
      parts.add('altboundary=' + (altboundary ? '1' : '0'));
    if (b != false) parts.add('b=' + (b ? '1' : '0'));
    if (c != false) parts.add('c=' + (c ? '1' : '0'));
    if (channels != 'all') parts.add('channels=' + channels);
    if (compress != 0.0) parts.add('compress=' + compress.toStringAsFixed(3));
    if (correctdc != false) parts.add('correctdc=' + (correctdc ? '1' : '0'));
    if (coupling != true) parts.add('coupling=' + (coupling ? '1' : '0'));
    if (curve != null) parts.add('curve=' + curve!);
    if (f != 500) parts.add('f=' + f.toString());
    if (framelen != 500) parts.add('framelen=' + framelen.toString());
    if (g != 31) parts.add('g=' + g.toString());
    if (gausssize != 31) parts.add('gausssize=' + gausssize.toString());
    if (h != 'all') parts.add('h=' + h);
    if (m != 10.0) parts.add('m=' + m.toStringAsFixed(3));
    if (maxgain != 10.0) parts.add('maxgain=' + maxgain.toStringAsFixed(3));
    if (n != true) parts.add('n=' + (n ? '1' : '0'));
    if (o != .0) parts.add('o=' + o.toStringAsFixed(3));
    if (overlap != .0) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (p != 0.95) parts.add('p=' + p.toStringAsFixed(3));
    if (peak != 0.95) parts.add('peak=' + peak.toStringAsFixed(3));
    if (r != 0.0) parts.add('r=' + r.toStringAsFixed(3));
    if (s != 0.0) parts.add('s=' + s.toStringAsFixed(3));
    if (t != 0.0) parts.add('t=' + t.toStringAsFixed(3));
    if (targetrms != 0.0)
      parts.add('targetrms=' + targetrms.toStringAsFixed(3));
    if (threshold != 0.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    if (v != null) parts.add('v=' + v!);
    return parts.isEmpty
        ? 'lavfi-dynaudnorm'
        : 'lavfi-dynaudnorm=' + parts.join(':');
  }
}

/// Configuration for the `earwax` audio effect.
///
/// Make audio easier to listen to on headphones.
///
/// This filter adds `cues' to 44.1kHz stereo (i.e. audio CD format) audio
/// so that when listened to on headphones the stereo image is moved from
/// inside your head (standard for headphones) to outside and in front of
/// the listener (standard for speakers).
///
/// Ported from SoX.
final class EarwaxSettings {
  final bool enabled;

  const EarwaxSettings({
    this.enabled = false,
  });

  EarwaxSettings copyWith({
    bool? enabled,
  }) =>
      EarwaxSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarwaxSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'EarwaxSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-earwax';
  }
}

/// Configuration for the `ebur128` audio effect.
///
/// EBU R128 scanner filter. This filter takes an audio stream and analyzes its loudness
/// level. By default, it logs a message at a frequency of 10Hz with the
/// Momentary loudness (identified by `M`), Short-term loudness (`S`),
/// Integrated loudness (`I`) and Loudness Range (`LRA`).
///
/// The filter can only analyze streams which have
/// sample format is double-precision floating point. The input stream will be converted to
/// this specification, if needed. Users may need to insert aformat and/or aresample filters
/// after this filter to obtain the original parameters.
///
/// The filter also has a video output (see the `video` option) with a real
/// time graph to observe the loudness evolution. The graphic contains the logged
/// message mentioned above, so it is not printed anymore when this option is set,
/// unless the verbose logging is set. The main graphing area contains the
/// short-term loudness (3 seconds of analysis), and the gauge on the right is for
/// the momentary loudness (400 milliseconds), but can optionally be configured
/// to instead display short-term loudness (see `gauge`).
///
/// The green area marks a  +/- 1LU target range around the target loudness
/// (-23LUFS by default, unless modified through `target`).
///
/// More information about the Loudness Recommendation EBU R128 on
/// http://tech.ebu.ch/loudness.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [dualmono]: treat mono input files as dual-mono (range 0..1, default 0)
/// - [framelog]: Force the frame logging level.  Available values are: (default -1)
/// - [gauge]: set gauge display type (default 0)
/// - [integrated]: integrated loudness (LUFS) (default 0)
/// - [lra_high]: LRA high (LUFS) (default 0)
/// - [lra_low]: LRA low (LUFS) (default 0)
/// - [metadata]: Set metadata injection. If set to `1`, the audio input will be segmented into 100ms output frames, each of them containing various loudness information in metadata.  All the metadata keys are prefixed with `lavfi.r128.`.  Default is `0`. (range 0..1, default 0)
/// - [meter]: Set the EBU scale meter. Default is `9`. Common values are `9` and `18`, respectively for EBU scale meter +9 and EBU scale meter +18. Any other integer value between this range is allowed. (range 9..18, default 9)
/// - [panlaw]: set a specific pan law for dual-mono files (range -10.0..0.0, default -3.01029995663978)
/// - [peak]: set peak mode
/// - [range]: loudness range (LU) (default 0)
/// - [sample_peak]: sample peak (dBFS) (default 0)
/// - [scale]: sets display method for the stats (default 0)
/// - [target]: set a specific target level in LUFS (-23 to 0) (range -23..0, default -23)
/// - [true_peak]: true peak (dBFS) (default 0)
/// - [video]: Activate the video output. The audio stream is passed unchanged whether this option is set or no. The video stream will be the first output stream if activated. Default is `0`. (range 0..1, default 0)
final class Ebur128Settings {
  final bool enabled;
  final bool dualmono;
  final Ebur128Level framelog;
  final Ebur128Gaugetype gauge;
  final double integrated;
  final double lra_high;
  final double lra_low;
  final bool metadata;
  final int meter;
  final double panlaw;
  final Set<Ebur128Mode> peak;
  final double range;
  final double sample_peak;
  final Ebur128Scaletype scale;
  final int target;
  final double true_peak;
  final bool video;

  const Ebur128Settings({
    this.enabled = false,
    this.dualmono = false,
    this.framelog = Ebur128Level.quiet,
    this.gauge = Ebur128Gaugetype.momentary,
    this.integrated = 0.0,
    this.lra_high = 0.0,
    this.lra_low = 0.0,
    this.metadata = false,
    this.meter = 9,
    this.panlaw = -3.01029995663978,
    this.peak = const <Ebur128Mode>{},
    this.range = 0.0,
    this.sample_peak = 0.0,
    this.scale = Ebur128Scaletype.absolute,
    this.target = -23,
    this.true_peak = 0.0,
    this.video = false,
  });

  Ebur128Settings copyWith({
    bool? enabled,
    bool? dualmono,
    Ebur128Level? framelog,
    Ebur128Gaugetype? gauge,
    double? integrated,
    double? lra_high,
    double? lra_low,
    bool? metadata,
    int? meter,
    double? panlaw,
    Set<Ebur128Mode>? peak,
    double? range,
    double? sample_peak,
    Ebur128Scaletype? scale,
    int? target,
    double? true_peak,
    bool? video,
  }) =>
      Ebur128Settings(
        enabled: enabled ?? this.enabled,
        dualmono: dualmono ?? this.dualmono,
        framelog: framelog ?? this.framelog,
        gauge: gauge ?? this.gauge,
        integrated: integrated ?? this.integrated,
        lra_high: lra_high ?? this.lra_high,
        lra_low: lra_low ?? this.lra_low,
        metadata: metadata ?? this.metadata,
        meter: meter ?? this.meter,
        panlaw: panlaw ?? this.panlaw,
        peak: peak ?? this.peak,
        range: range ?? this.range,
        sample_peak: sample_peak ?? this.sample_peak,
        scale: scale ?? this.scale,
        target: target ?? this.target,
        true_peak: true_peak ?? this.true_peak,
        video: video ?? this.video,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ebur128Settings &&
          other.enabled == enabled &&
          other.dualmono == dualmono &&
          other.framelog == framelog &&
          other.gauge == gauge &&
          other.integrated == integrated &&
          other.lra_high == lra_high &&
          other.lra_low == lra_low &&
          other.metadata == metadata &&
          other.meter == meter &&
          other.panlaw == panlaw &&
          _setEq(peak, other.peak) &&
          other.range == range &&
          other.sample_peak == sample_peak &&
          other.scale == scale &&
          other.target == target &&
          other.true_peak == true_peak &&
          other.video == video);

  @override
  int get hashCode => Object.hash(
      enabled,
      dualmono,
      framelog,
      gauge,
      integrated,
      lra_high,
      lra_low,
      metadata,
      meter,
      panlaw,
      Object.hashAllUnordered(peak),
      range,
      sample_peak,
      scale,
      target,
      true_peak,
      video);

  @override
  String toString() =>
      'Ebur128Settings(enabled: $enabled, dualmono: $dualmono, framelog: $framelog, gauge: $gauge, integrated: $integrated, lra_high: $lra_high, lra_low: $lra_low, metadata: $metadata, meter: $meter, panlaw: $panlaw, peak: $peak, range: $range, sample_peak: $sample_peak, scale: $scale, target: $target, true_peak: $true_peak, video: $video)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(meter >= 9, 'ebur128.meter must be >= 9');
    assert(meter <= 18, 'ebur128.meter must be <= 18');
    assert(panlaw >= -10.0, 'ebur128.panlaw must be >= -10.0');
    assert(panlaw <= 0.0, 'ebur128.panlaw must be <= 0.0');
    assert(target >= -23, 'ebur128.target must be >= -23');
    assert(target <= 0, 'ebur128.target must be <= 0');
    final parts = <String>[];
    if (dualmono != false) parts.add('dualmono=' + (dualmono ? '1' : '0'));
    if (framelog != Ebur128Level.quiet)
      parts.add('framelog=' + framelog.mpvValue);
    if (gauge != Ebur128Gaugetype.momentary)
      parts.add('gauge=' + gauge.mpvValue);
    if (integrated != 0.0)
      parts.add('integrated=' + integrated.toStringAsFixed(3));
    if (lra_high != 0.0) parts.add('lra_high=' + lra_high.toStringAsFixed(3));
    if (lra_low != 0.0) parts.add('lra_low=' + lra_low.toStringAsFixed(3));
    if (metadata != false) parts.add('metadata=' + (metadata ? '1' : '0'));
    if (meter != 9) parts.add('meter=' + meter.toString());
    if (panlaw != -3.01029995663978)
      parts.add('panlaw=' + panlaw.toStringAsFixed(3));
    if (peak.isNotEmpty)
      parts.add('peak=' + peak.map((e) => e.mpvValue).join('+'));
    if (range != 0.0) parts.add('range=' + range.toStringAsFixed(3));
    if (sample_peak != 0.0)
      parts.add('sample_peak=' + sample_peak.toStringAsFixed(3));
    if (scale != Ebur128Scaletype.absolute)
      parts.add('scale=' + scale.mpvValue);
    if (target != -23) parts.add('target=' + target.toString());
    if (true_peak != 0.0)
      parts.add('true_peak=' + true_peak.toStringAsFixed(3));
    if (video != false) parts.add('video=' + (video ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-ebur128' : 'lavfi-ebur128=' + parts.join(':');
  }
}

/// Configuration for the `equalizer` audio effect.
///
/// Apply a two-pole peaking equalisation (EQ) filter. With this
/// filter, the signal-level at and around a selected frequency can
/// be increased or decreased, whilst (unlike bandpass and bandreject
/// filters) that at all other frequencies is unchanged.
///
/// In order to produce complex equalisation curves, this filter can
/// be given several times, each with a different central frequency.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency in Hz. (range 0..999999, default 0)
/// - [frequency]: Set the filter's central frequency in Hz. (range 0..999999, default 0)
/// - [g]: Set the required gain or attenuation in dB. Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Set the required gain or attenuation in dB. Beware of clipping when using a positive gain. (range -900..900, default 0)
final class EqualizerSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;

  const EqualizerSettings({
    this.enabled = false,
    this.f = 0.0,
    this.frequency = 0.0,
    this.g = 0.0,
    this.gain = 0.0,
  });

  EqualizerSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
  }) =>
      EqualizerSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain);

  @override
  String toString() =>
      'EqualizerSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'equalizer.f must be >= 0');
    assert(f <= 999999, 'equalizer.f must be <= 999999');
    assert(frequency >= 0, 'equalizer.frequency must be >= 0');
    assert(frequency <= 999999, 'equalizer.frequency must be <= 999999');
    assert(g >= -900, 'equalizer.g must be >= -900');
    assert(g <= 900, 'equalizer.g must be <= 900');
    assert(gain >= -900, 'equalizer.gain must be >= -900');
    assert(gain <= 900, 'equalizer.gain must be <= 900');
    final parts = <String>[];
    if (f != 0.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 0.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-equalizer'
        : 'lavfi-equalizer=' + parts.join(':');
  }
}

/// Configuration for the `extrastereo` audio effect.
///
/// Linearly increases the difference between left and right channels which
/// adds some sort of "live" effect to playback.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1)
/// - [m]: Sets the difference coefficient (default: 2.5). 0.0 means mono sound (average of both channels), with 1.0 sound will be unchanged, with -1.0 left and right channels will be swapped. (range -10..10, default 2.5)
final class ExtrastereoSettings {
  final bool enabled;
  final bool c;
  final double m;

  const ExtrastereoSettings({
    this.enabled = false,
    this.c = true,
    this.m = 2.5,
  });

  ExtrastereoSettings copyWith({
    bool? enabled,
    bool? c,
    double? m,
  }) =>
      ExtrastereoSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        m: m ?? this.m,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtrastereoSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.m == m);

  @override
  int get hashCode => Object.hash(enabled, c, m);

  @override
  String toString() => 'ExtrastereoSettings(enabled: $enabled, c: $c, m: $m)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(m >= -10, 'extrastereo.m must be >= -10');
    assert(m <= 10, 'extrastereo.m must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (m != 2.5) parts.add('m=' + m.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-extrastereo'
        : 'lavfi-extrastereo=' + parts.join(':');
  }
}

/// Configuration for the `firequalizer` audio effect.
///
/// Apply FIR Equalization using arbitrary frequency response.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [accuracy]: Set filter accuracy in Hz. Lower value means more accurate. Default is `5`. (range 0.0..1e10, default 5.0)
/// - [delay]: Set filter delay in seconds. Higher value means more accurate. Default is `0.01`. (range 0.0..1e10, default 0.01)
/// - [dumpfile]: Set file for dumping, suitable for gnuplot. (range 0..0)
/// - [dumpscale]: Set scale for dumpfile. Acceptable values are same with scale option. Default is linlog.
/// - [fft2]: Enable 2-channel convolution using complex FFT. This improves speed significantly. Default is disabled. (range 0..1, default 0)
/// - [fixed]: If enabled, use fixed number of audio samples. This improves speed when filtering with large delay. Default is disabled. (range 0..1, default 0)
/// - [gain]: Set gain curve equation (in dB). The expression can contain variables: (range 0..0, default "gain_interpolate(f)")
/// - [gain_entry]: Set gain entry for gain_interpolate function. The expression can contain functions: (range 0..0)
/// - [min_phase]: Enable minimum phase impulse response. Default is disabled. (range 0..1, default 0)
/// - [multi]: Enable multichannels evaluation on gain. Default is disabled. (range 0..1, default 0)
/// - [scale]: Set scale used by gain. Acceptable values are:
/// - [wfunc]: Set window function. Acceptable values are:
/// - [zero_phase]: Enable zero phase mode by subtracting timestamp to compensate delay. Default is disabled. (range 0..1, default 0)
final class FirequalizerSettings {
  final bool enabled;
  final double accuracy;
  final double delay;
  final String? dumpfile;
  final FirequalizerScale? dumpscale;
  final bool fft2;
  final bool fixed;
  final String gain;
  final String? gain_entry;
  final bool min_phase;
  final bool multi;
  final FirequalizerScale? scale;
  final FirequalizerWfunc? wfunc;
  final bool zero_phase;

  const FirequalizerSettings({
    this.enabled = false,
    this.accuracy = 5.0,
    this.delay = 0.01,
    this.dumpfile,
    this.dumpscale,
    this.fft2 = false,
    this.fixed = false,
    this.gain = 'gain_interpolate(f)',
    this.gain_entry,
    this.min_phase = false,
    this.multi = false,
    this.scale,
    this.wfunc,
    this.zero_phase = false,
  });

  FirequalizerSettings copyWith({
    bool? enabled,
    double? accuracy,
    double? delay,
    Object? dumpfile = _unset,
    Object? dumpscale = _unset,
    bool? fft2,
    bool? fixed,
    String? gain,
    Object? gain_entry = _unset,
    bool? min_phase,
    bool? multi,
    Object? scale = _unset,
    Object? wfunc = _unset,
    bool? zero_phase,
  }) =>
      FirequalizerSettings(
        enabled: enabled ?? this.enabled,
        accuracy: accuracy ?? this.accuracy,
        delay: delay ?? this.delay,
        dumpfile:
            identical(dumpfile, _unset) ? this.dumpfile : dumpfile as String?,
        dumpscale: identical(dumpscale, _unset)
            ? this.dumpscale
            : dumpscale as FirequalizerScale?,
        fft2: fft2 ?? this.fft2,
        fixed: fixed ?? this.fixed,
        gain: gain ?? this.gain,
        gain_entry: identical(gain_entry, _unset)
            ? this.gain_entry
            : gain_entry as String?,
        min_phase: min_phase ?? this.min_phase,
        multi: multi ?? this.multi,
        scale:
            identical(scale, _unset) ? this.scale : scale as FirequalizerScale?,
        wfunc:
            identical(wfunc, _unset) ? this.wfunc : wfunc as FirequalizerWfunc?,
        zero_phase: zero_phase ?? this.zero_phase,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirequalizerSettings &&
          other.enabled == enabled &&
          other.accuracy == accuracy &&
          other.delay == delay &&
          other.dumpfile == dumpfile &&
          other.dumpscale == dumpscale &&
          other.fft2 == fft2 &&
          other.fixed == fixed &&
          other.gain == gain &&
          other.gain_entry == gain_entry &&
          other.min_phase == min_phase &&
          other.multi == multi &&
          other.scale == scale &&
          other.wfunc == wfunc &&
          other.zero_phase == zero_phase);

  @override
  int get hashCode => Object.hash(
      enabled,
      accuracy,
      delay,
      dumpfile,
      dumpscale,
      fft2,
      fixed,
      gain,
      gain_entry,
      min_phase,
      multi,
      scale,
      wfunc,
      zero_phase);

  @override
  String toString() =>
      'FirequalizerSettings(enabled: $enabled, accuracy: $accuracy, delay: $delay, dumpfile: $dumpfile, dumpscale: $dumpscale, fft2: $fft2, fixed: $fixed, gain: $gain, gain_entry: $gain_entry, min_phase: $min_phase, multi: $multi, scale: $scale, wfunc: $wfunc, zero_phase: $zero_phase)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(accuracy >= 0.0, 'firequalizer.accuracy must be >= 0.0');
    assert(accuracy <= 1e10, 'firequalizer.accuracy must be <= 1e10');
    assert(delay >= 0.0, 'firequalizer.delay must be >= 0.0');
    assert(delay <= 1e10, 'firequalizer.delay must be <= 1e10');
    final parts = <String>[];
    if (accuracy != 5.0) parts.add('accuracy=' + accuracy.toStringAsFixed(3));
    if (delay != 0.01) parts.add('delay=' + delay.toStringAsFixed(3));
    if (dumpfile != null) parts.add('dumpfile=' + dumpfile!);
    if (dumpscale != null) parts.add('dumpscale=' + dumpscale!.mpvValue);
    if (fft2 != false) parts.add('fft2=' + (fft2 ? '1' : '0'));
    if (fixed != false) parts.add('fixed=' + (fixed ? '1' : '0'));
    if (gain != 'gain_interpolate(f)') parts.add('gain=' + gain);
    if (gain_entry != null) parts.add('gain_entry=' + gain_entry!);
    if (min_phase != false) parts.add('min_phase=' + (min_phase ? '1' : '0'));
    if (multi != false) parts.add('multi=' + (multi ? '1' : '0'));
    if (scale != null) parts.add('scale=' + scale!.mpvValue);
    if (wfunc != null) parts.add('wfunc=' + wfunc!.mpvValue);
    if (zero_phase != false)
      parts.add('zero_phase=' + (zero_phase ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-firequalizer'
        : 'lavfi-firequalizer=' + parts.join(':');
  }
}

/// Configuration for the `flanger` audio effect.
///
/// Apply a flanging effect to the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [delay]: Set base delay in milliseconds. Range from 0 to 30. Default value is 0. (range 0..30, default 0)
/// - [depth]: Set added sweep delay in milliseconds. Range from 0 to 10. Default value is 2. (range 0..10, default 2)
/// - [interp]: Set delay-line interpolation, `linear` or `quadratic`. Default is `linear`. (range 0..1, default 0)
/// - [phase]: Set swept wave percentage-shift for multi channel. Range from 0 to 100. Default value is 25. (range 0..100, default 25)
/// - [regen]: Set percentage regeneration (delayed signal feedback). Range from -95 to 95. Default value is 0. (range -95..95, default 0)
/// - [shape]: Set swept wave shape, can be `triangular` or `sinusoidal`. Default value is `sinusoidal`.
/// - [speed]: Set sweeps per second (Hz). Range from 0.1 to 10. Default value is 0.5. (range 0.1..10, default 0.5)
/// - [width]: Set percentage of delayed signal mixed with original. Range from 0 to 100. Default value is 71. (range 0..100, default 71)
final class FlangerSettings {
  final bool enabled;
  final double delay;
  final double depth;
  final FlangerItype interp;
  final double phase;
  final double regen;
  final FlangerType? shape;
  final double speed;
  final double width;

  const FlangerSettings({
    this.enabled = false,
    this.delay = 0.0,
    this.depth = 2.0,
    this.interp = FlangerItype.linear,
    this.phase = 25.0,
    this.regen = 0.0,
    this.shape,
    this.speed = 0.5,
    this.width = 71.0,
  });

  FlangerSettings copyWith({
    bool? enabled,
    double? delay,
    double? depth,
    FlangerItype? interp,
    double? phase,
    double? regen,
    Object? shape = _unset,
    double? speed,
    double? width,
  }) =>
      FlangerSettings(
        enabled: enabled ?? this.enabled,
        delay: delay ?? this.delay,
        depth: depth ?? this.depth,
        interp: interp ?? this.interp,
        phase: phase ?? this.phase,
        regen: regen ?? this.regen,
        shape: identical(shape, _unset) ? this.shape : shape as FlangerType?,
        speed: speed ?? this.speed,
        width: width ?? this.width,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlangerSettings &&
          other.enabled == enabled &&
          other.delay == delay &&
          other.depth == depth &&
          other.interp == interp &&
          other.phase == phase &&
          other.regen == regen &&
          other.shape == shape &&
          other.speed == speed &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
      enabled, delay, depth, interp, phase, regen, shape, speed, width);

  @override
  String toString() =>
      'FlangerSettings(enabled: $enabled, delay: $delay, depth: $depth, interp: $interp, phase: $phase, regen: $regen, shape: $shape, speed: $speed, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(delay >= 0, 'flanger.delay must be >= 0');
    assert(delay <= 30, 'flanger.delay must be <= 30');
    assert(depth >= 0, 'flanger.depth must be >= 0');
    assert(depth <= 10, 'flanger.depth must be <= 10');
    assert(phase >= 0, 'flanger.phase must be >= 0');
    assert(phase <= 100, 'flanger.phase must be <= 100');
    assert(regen >= -95, 'flanger.regen must be >= -95');
    assert(regen <= 95, 'flanger.regen must be <= 95');
    assert(speed >= 0.1, 'flanger.speed must be >= 0.1');
    assert(speed <= 10, 'flanger.speed must be <= 10');
    assert(width >= 0, 'flanger.width must be >= 0');
    assert(width <= 100, 'flanger.width must be <= 100');
    final parts = <String>[];
    if (delay != 0.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (depth != 2.0) parts.add('depth=' + depth.toStringAsFixed(3));
    if (interp != FlangerItype.linear) parts.add('interp=' + interp.mpvValue);
    if (phase != 25.0) parts.add('phase=' + phase.toStringAsFixed(3));
    if (regen != 0.0) parts.add('regen=' + regen.toStringAsFixed(3));
    if (shape != null) parts.add('shape=' + shape!.mpvValue);
    if (speed != 0.5) parts.add('speed=' + speed.toStringAsFixed(3));
    if (width != 71.0) parts.add('width=' + width.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-flanger' : 'lavfi-flanger=' + parts.join(':');
  }
}

/// Configuration for the `haas` audio effect.
///
/// Apply Haas effect to audio.
///
/// Note that this makes most sense to apply on mono signals.
/// With this filter applied to mono signals it give some directionality and
/// stretches its stereo image.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [left_balance]: set left balance (range -1..1, default -1.0)
/// - [left_delay]: set left delay (default 2.05)
/// - [left_gain]: set left gain (range 0.015625..64, default 1)
/// - [left_phase]: set left phase (range 0..1, default 0)
/// - [level_in]: Set input level. By default is `1`, or 0dB (range 0.015625..64, default 1)
/// - [level_out]: Set output level. By default is `1`, or 0dB. (range 0.015625..64, default 1)
/// - [middle_phase]: set middle phase (range 0..1, default 0)
/// - [middle_source]: Set kind of middle source. Can be one of the following: (range 0..3, default 2)
/// - [right_balance]: set right balance (range -1..1, default 1)
/// - [right_delay]: set right delay (default 2.12)
/// - [right_gain]: set right gain (range 0.015625..64, default 1)
/// - [right_phase]: set right phase (range 0..1, default 1)
/// - [side_gain]: Set gain applied to side part of signal. By default is `1`. (range 0.015625..64, default 1)
final class HaasSettings {
  final bool enabled;
  final double left_balance;
  final double left_delay;
  final double left_gain;
  final bool left_phase;
  final double level_in;
  final double level_out;
  final bool middle_phase;
  final HaasSource middle_source;
  final double right_balance;
  final double right_delay;
  final double right_gain;
  final bool right_phase;
  final double side_gain;

  const HaasSettings({
    this.enabled = false,
    this.left_balance = -1.0,
    this.left_delay = 2.05,
    this.left_gain = 1.0,
    this.left_phase = false,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.middle_phase = false,
    this.middle_source = HaasSource.mid,
    this.right_balance = 1.0,
    this.right_delay = 2.12,
    this.right_gain = 1.0,
    this.right_phase = true,
    this.side_gain = 1.0,
  });

  HaasSettings copyWith({
    bool? enabled,
    double? left_balance,
    double? left_delay,
    double? left_gain,
    bool? left_phase,
    double? level_in,
    double? level_out,
    bool? middle_phase,
    HaasSource? middle_source,
    double? right_balance,
    double? right_delay,
    double? right_gain,
    bool? right_phase,
    double? side_gain,
  }) =>
      HaasSettings(
        enabled: enabled ?? this.enabled,
        left_balance: left_balance ?? this.left_balance,
        left_delay: left_delay ?? this.left_delay,
        left_gain: left_gain ?? this.left_gain,
        left_phase: left_phase ?? this.left_phase,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        middle_phase: middle_phase ?? this.middle_phase,
        middle_source: middle_source ?? this.middle_source,
        right_balance: right_balance ?? this.right_balance,
        right_delay: right_delay ?? this.right_delay,
        right_gain: right_gain ?? this.right_gain,
        right_phase: right_phase ?? this.right_phase,
        side_gain: side_gain ?? this.side_gain,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HaasSettings &&
          other.enabled == enabled &&
          other.left_balance == left_balance &&
          other.left_delay == left_delay &&
          other.left_gain == left_gain &&
          other.left_phase == left_phase &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.middle_phase == middle_phase &&
          other.middle_source == middle_source &&
          other.right_balance == right_balance &&
          other.right_delay == right_delay &&
          other.right_gain == right_gain &&
          other.right_phase == right_phase &&
          other.side_gain == side_gain);

  @override
  int get hashCode => Object.hash(
      enabled,
      left_balance,
      left_delay,
      left_gain,
      left_phase,
      level_in,
      level_out,
      middle_phase,
      middle_source,
      right_balance,
      right_delay,
      right_gain,
      right_phase,
      side_gain);

  @override
  String toString() =>
      'HaasSettings(enabled: $enabled, left_balance: $left_balance, left_delay: $left_delay, left_gain: $left_gain, left_phase: $left_phase, level_in: $level_in, level_out: $level_out, middle_phase: $middle_phase, middle_source: $middle_source, right_balance: $right_balance, right_delay: $right_delay, right_gain: $right_gain, right_phase: $right_phase, side_gain: $side_gain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(left_balance >= -1, 'haas.left_balance must be >= -1');
    assert(left_balance <= 1, 'haas.left_balance must be <= 1');
    assert(left_delay >= 0, 'haas.left_delay must be >= 0');
    assert(left_gain >= 0.015625, 'haas.left_gain must be >= 0.015625');
    assert(left_gain <= 64, 'haas.left_gain must be <= 64');
    assert(level_in >= 0.015625, 'haas.level_in must be >= 0.015625');
    assert(level_in <= 64, 'haas.level_in must be <= 64');
    assert(level_out >= 0.015625, 'haas.level_out must be >= 0.015625');
    assert(level_out <= 64, 'haas.level_out must be <= 64');
    assert(right_balance >= -1, 'haas.right_balance must be >= -1');
    assert(right_balance <= 1, 'haas.right_balance must be <= 1');
    assert(right_delay >= 0, 'haas.right_delay must be >= 0');
    assert(right_gain >= 0.015625, 'haas.right_gain must be >= 0.015625');
    assert(right_gain <= 64, 'haas.right_gain must be <= 64');
    assert(side_gain >= 0.015625, 'haas.side_gain must be >= 0.015625');
    assert(side_gain <= 64, 'haas.side_gain must be <= 64');
    final parts = <String>[];
    if (left_balance != -1.0)
      parts.add('left_balance=' + left_balance.toStringAsFixed(3));
    if (left_delay != 2.05)
      parts.add('left_delay=' + left_delay.toStringAsFixed(3));
    if (left_gain != 1.0)
      parts.add('left_gain=' + left_gain.toStringAsFixed(3));
    if (left_phase != false)
      parts.add('left_phase=' + (left_phase ? '1' : '0'));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (middle_phase != false)
      parts.add('middle_phase=' + (middle_phase ? '1' : '0'));
    if (middle_source != HaasSource.mid)
      parts.add('middle_source=' + middle_source.mpvValue);
    if (right_balance != 1.0)
      parts.add('right_balance=' + right_balance.toStringAsFixed(3));
    if (right_delay != 2.12)
      parts.add('right_delay=' + right_delay.toStringAsFixed(3));
    if (right_gain != 1.0)
      parts.add('right_gain=' + right_gain.toStringAsFixed(3));
    if (right_phase != true)
      parts.add('right_phase=' + (right_phase ? '1' : '0'));
    if (side_gain != 1.0)
      parts.add('side_gain=' + side_gain.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-haas' : 'lavfi-haas=' + parts.join(':');
  }
}

/// Configuration for the `hdcd` audio effect.
///
/// Decodes High Definition Compatible Digital (HDCD) data. A 16-bit PCM stream with
/// embedded HDCD codes is expanded into a 20-bit PCM stream.
///
/// The filter supports the Peak Extend and Low-level Gain Adjustment features
/// of HDCD, and detects the Transient Filter flag.
///
/// When using the filter with wav, note the default encoding for wav is 16-bit,
/// so the resulting 20-bit stream will be truncated back to 16-bit. Use something
/// like @command{-acodec pcm_s24le} after the filter to get 24-bit PCM output.
///
/// ffmpeg -i HDCD16.wav -af hdcd -c:a pcm_s24le OUT24.wav
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [analyze_mode]: Replace audio with a solid tone and adjust the amplitude to signal some specific aspect of the decoding process. The output file can be loaded in an audio editor alongside the original to aid analysis.  `analyze_mode=pe:force_pe=true` can be used to see all samples above the PE level.  Modes are:
/// - [bits_per_sample]: Valid bits per sample (location of the true LSB). (range 16..24, default 16)
/// - [cdt_ms]: Set the code detect timer period in ms. (range 100..60000, default 2000)
/// - [disable_autoconvert]: Disable any automatic format conversion or resampling in the filter graph. (range 0..1, default 1)
/// - [force_pe]: Always extend peaks above -3dBFS even if PE isn't signaled. (range 0..1, default 0)
/// - [process_stereo]: Process the stereo channels together. If target_gain does not match between channels, consider it invalid and use the last valid target_gain. (range 0..1)
final class HdcdSettings {
  final bool enabled;
  final HdcdAnalyzeMode? analyze_mode;
  final HdcdBitsPerSample bits_per_sample;
  final int cdt_ms;
  final bool disable_autoconvert;
  final bool force_pe;
  final bool? process_stereo;

  const HdcdSettings({
    this.enabled = false,
    this.analyze_mode,
    this.bits_per_sample = HdcdBitsPerSample.n16,
    this.cdt_ms = 2000,
    this.disable_autoconvert = true,
    this.force_pe = false,
    this.process_stereo,
  });

  HdcdSettings copyWith({
    bool? enabled,
    Object? analyze_mode = _unset,
    HdcdBitsPerSample? bits_per_sample,
    int? cdt_ms,
    bool? disable_autoconvert,
    bool? force_pe,
    Object? process_stereo = _unset,
  }) =>
      HdcdSettings(
        enabled: enabled ?? this.enabled,
        analyze_mode: identical(analyze_mode, _unset)
            ? this.analyze_mode
            : analyze_mode as HdcdAnalyzeMode?,
        bits_per_sample: bits_per_sample ?? this.bits_per_sample,
        cdt_ms: cdt_ms ?? this.cdt_ms,
        disable_autoconvert: disable_autoconvert ?? this.disable_autoconvert,
        force_pe: force_pe ?? this.force_pe,
        process_stereo: identical(process_stereo, _unset)
            ? this.process_stereo
            : process_stereo as bool?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HdcdSettings &&
          other.enabled == enabled &&
          other.analyze_mode == analyze_mode &&
          other.bits_per_sample == bits_per_sample &&
          other.cdt_ms == cdt_ms &&
          other.disable_autoconvert == disable_autoconvert &&
          other.force_pe == force_pe &&
          other.process_stereo == process_stereo);

  @override
  int get hashCode => Object.hash(enabled, analyze_mode, bits_per_sample,
      cdt_ms, disable_autoconvert, force_pe, process_stereo);

  @override
  String toString() =>
      'HdcdSettings(enabled: $enabled, analyze_mode: $analyze_mode, bits_per_sample: $bits_per_sample, cdt_ms: $cdt_ms, disable_autoconvert: $disable_autoconvert, force_pe: $force_pe, process_stereo: $process_stereo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cdt_ms >= 100, 'hdcd.cdt_ms must be >= 100');
    assert(cdt_ms <= 60000, 'hdcd.cdt_ms must be <= 60000');
    final parts = <String>[];
    if (analyze_mode != null)
      parts.add('analyze_mode=' + analyze_mode!.mpvValue);
    if (bits_per_sample != HdcdBitsPerSample.n16)
      parts.add('bits_per_sample=' + bits_per_sample.mpvValue);
    if (cdt_ms != 2000) parts.add('cdt_ms=' + cdt_ms.toString());
    if (disable_autoconvert != true)
      parts.add('disable_autoconvert=' + (disable_autoconvert ? '1' : '0'));
    if (force_pe != false) parts.add('force_pe=' + (force_pe ? '1' : '0'));
    if (process_stereo != null)
      parts.add('process_stereo=' + (process_stereo! ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-hdcd' : 'lavfi-hdcd=' + parts.join(':');
  }
}

/// Configuration for the `headphone` audio effect.
///
/// Apply head-related transfer functions (HRTFs) to create virtual
/// loudspeakers around the user for binaural listening via headphones.
/// The HRIRs are provided via additional streams, for each channel
/// one stereo input stream is needed.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [gain]: Set gain applied to audio. Value is in dB. Default is 0. (range -20..40, default 0)
/// - [hrir]: Set format of hrir stream. Default value is `stereo`. Alternative value is `multich`. If value is set to `stereo`, number of additional streams should be greater or equal to number of input channels in first input stream. Also each additional stream should have stereo number of channels. If value is set to `multich`, number of additional streams should be exactly one. Also number of input channels of additional stream should be equal or greater than twice number of channels of first input stream. (range 0..1)
/// - [lfe]: Set custom gain for LFE channels. Value is in dB. Default is 0. (range -20..40, default 0)
/// - [map]: Set mapping of input streams for convolution. The argument is a '|'-separated list of channel names in order as they are given as additional stream inputs for filter. This also specify number of input streams. Number of input streams must be not less than number of channels in first stream plus one.
/// - [size]: Set size of frame in number of samples which will be processed at once. Default value is `1024`. Allowed range is from 1024 to 96000. (range 1024..96000, default 1024)
/// - [type]: Set processing type. Can be `time` or `freq`. `time` is processing audio in time domain which is slow. `freq` is processing audio in frequency domain which is fast. Default is `freq`. (range 0..1, default 1)
final class HeadphoneSettings {
  final bool enabled;
  final double gain;
  final HeadphoneHrir? hrir;
  final double lfe;
  final String? map;
  final int size;
  final HeadphoneType type;

  const HeadphoneSettings({
    this.enabled = false,
    this.gain = 0.0,
    this.hrir,
    this.lfe = 0.0,
    this.map,
    this.size = 1024,
    this.type = HeadphoneType.freq,
  });

  HeadphoneSettings copyWith({
    bool? enabled,
    double? gain,
    Object? hrir = _unset,
    double? lfe,
    Object? map = _unset,
    int? size,
    HeadphoneType? type,
  }) =>
      HeadphoneSettings(
        enabled: enabled ?? this.enabled,
        gain: gain ?? this.gain,
        hrir: identical(hrir, _unset) ? this.hrir : hrir as HeadphoneHrir?,
        lfe: lfe ?? this.lfe,
        map: identical(map, _unset) ? this.map : map as String?,
        size: size ?? this.size,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HeadphoneSettings &&
          other.enabled == enabled &&
          other.gain == gain &&
          other.hrir == hrir &&
          other.lfe == lfe &&
          other.map == map &&
          other.size == size &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, gain, hrir, lfe, map, size, type);

  @override
  String toString() =>
      'HeadphoneSettings(enabled: $enabled, gain: $gain, hrir: $hrir, lfe: $lfe, map: $map, size: $size, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(gain >= -20, 'headphone.gain must be >= -20');
    assert(gain <= 40, 'headphone.gain must be <= 40');
    assert(lfe >= -20, 'headphone.lfe must be >= -20');
    assert(lfe <= 40, 'headphone.lfe must be <= 40');
    assert(size >= 1024, 'headphone.size must be >= 1024');
    assert(size <= 96000, 'headphone.size must be <= 96000');
    final parts = <String>[];
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (hrir != null) parts.add('hrir=' + hrir!.mpvValue);
    if (lfe != 0.0) parts.add('lfe=' + lfe.toStringAsFixed(3));
    if (map != null) parts.add('map=' + map!);
    if (size != 1024) parts.add('size=' + size.toString());
    if (type != HeadphoneType.freq) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-headphone'
        : 'lavfi-headphone=' + parts.join(':');
  }
}

/// Configuration for the `highpass` audio effect.
///
/// Apply a high-pass filter with 3dB point frequency.
/// The filter can be either single-pole, or double-pole (the default).
/// The filter roll off at 6dB per pole per octave (20dB per pole per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000)
/// - [frequency]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class HighpassSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final int p;
  final int poles;

  const HighpassSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.p = 2,
    this.poles = 2,
  });

  HighpassSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    int? p,
    int? poles,
  }) =>
      HighpassSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighpassSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, p, poles);

  @override
  String toString() =>
      'HighpassSettings(enabled: $enabled, f: $f, frequency: $frequency, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'highpass.f must be >= 0');
    assert(f <= 999999, 'highpass.f must be <= 999999');
    assert(frequency >= 0, 'highpass.frequency must be >= 0');
    assert(frequency <= 999999, 'highpass.frequency must be <= 999999');
    assert(p >= 1, 'highpass.p must be >= 1');
    assert(p <= 2, 'highpass.p must be <= 2');
    assert(poles >= 1, 'highpass.poles must be >= 1');
    assert(poles <= 2, 'highpass.poles must be <= 2');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty
        ? 'lavfi-highpass'
        : 'lavfi-highpass=' + parts.join(':');
  }
}

/// Configuration for the `highshelf` audio effect.
///
/// Boost or cut treble (upper) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [g]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class HighshelfSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;
  final int p;
  final int poles;

  const HighshelfSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.p = 2,
    this.poles = 2,
  });

  HighshelfSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    int? p,
    int? poles,
  }) =>
      HighshelfSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighshelfSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain, p, poles);

  @override
  String toString() =>
      'HighshelfSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'highshelf.f must be >= 0');
    assert(f <= 999999, 'highshelf.f must be <= 999999');
    assert(frequency >= 0, 'highshelf.frequency must be >= 0');
    assert(frequency <= 999999, 'highshelf.frequency must be <= 999999');
    assert(g >= -900, 'highshelf.g must be >= -900');
    assert(g <= 900, 'highshelf.g must be <= 900');
    assert(gain >= -900, 'highshelf.gain must be >= -900');
    assert(gain <= 900, 'highshelf.gain must be <= 900');
    assert(p >= 1, 'highshelf.p must be >= 1');
    assert(p <= 2, 'highshelf.p must be <= 2');
    assert(poles >= 1, 'highshelf.poles must be >= 1');
    assert(poles <= 2, 'highshelf.poles must be <= 2');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty
        ? 'lavfi-highshelf'
        : 'lavfi-highshelf=' + parts.join(':');
  }
}

/// Configuration for the `loudnorm` audio effect.
///
/// EBU R128 loudness normalization. Includes both dynamic and linear normalization modes.
/// Support for both single pass (livestreams, files) and double pass (files) modes.
/// This algorithm can target IL, LRA, and maximum true peak. In dynamic mode, to accurately
/// detect true peaks, the audio stream will be upsampled to 192 kHz.
/// Use the `-ar` option or `aresample` filter to explicitly set an output sample rate.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [I]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [LRA]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [TP]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
/// - [dual_mono]: Treat mono input files as "dual-mono". If a mono file is intended for playback on a stereo system, its EBU R128 measurement will be perceptually incorrect. If set to `true`, this option will compensate for this effect. Multi-channel input files are not affected by this option. Options are true or false. Default is false. (range 0..1, default 0)
/// - [i]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [linear]: Normalize by linearly scaling the source audio. `measured_I`, `measured_LRA`, `measured_TP`, and `measured_thresh` must all be specified. Target LRA shouldn't be lower than source LRA and the change in integrated loudness shouldn't result in a true peak which exceeds the target TP. If any of these conditions aren't met, normalization mode will revert to `dynamic`. Options are `true` or `false`. Default is `true`. (range 0..1, default 1)
/// - [lra]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [measured_I]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measured_LRA]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measured_TP]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [measured_i]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measured_lra]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measured_thresh]: Measured threshold of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default -70.)
/// - [measured_tp]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [offset]: Set offset gain. Gain is applied before the true-peak limiter. Range is  -99.0 - +99.0. Default is +0.0. (range -99.0..99.0, default 0.)
/// - [print_format]: Set print format for stats. Options are summary, json, or none. Default value is none.
/// - [tp]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
final class LoudnormSettings {
  final bool enabled;
  final double I;
  final double LRA;
  final double TP;
  final bool dual_mono;
  final double i;
  final bool linear;
  final double lra;
  final double measured_I;
  final double measured_LRA;
  final double measured_TP;
  final double measured_i;
  final double measured_lra;
  final double measured_thresh;
  final double measured_tp;
  final double offset;
  final LoudnormPrintFormat? print_format;
  final double tp;

  const LoudnormSettings({
    this.enabled = false,
    this.I = -24.0,
    this.LRA = 7.0,
    this.TP = -2.0,
    this.dual_mono = false,
    this.i = -24.0,
    this.linear = true,
    this.lra = 7.0,
    this.measured_I = 0.0,
    this.measured_LRA = 0.0,
    this.measured_TP = 99.0,
    this.measured_i = 0.0,
    this.measured_lra = 0.0,
    this.measured_thresh = -70.0,
    this.measured_tp = 99.0,
    this.offset = 0.0,
    this.print_format,
    this.tp = -2.0,
  });

  LoudnormSettings copyWith({
    bool? enabled,
    double? I,
    double? LRA,
    double? TP,
    bool? dual_mono,
    double? i,
    bool? linear,
    double? lra,
    double? measured_I,
    double? measured_LRA,
    double? measured_TP,
    double? measured_i,
    double? measured_lra,
    double? measured_thresh,
    double? measured_tp,
    double? offset,
    Object? print_format = _unset,
    double? tp,
  }) =>
      LoudnormSettings(
        enabled: enabled ?? this.enabled,
        I: I ?? this.I,
        LRA: LRA ?? this.LRA,
        TP: TP ?? this.TP,
        dual_mono: dual_mono ?? this.dual_mono,
        i: i ?? this.i,
        linear: linear ?? this.linear,
        lra: lra ?? this.lra,
        measured_I: measured_I ?? this.measured_I,
        measured_LRA: measured_LRA ?? this.measured_LRA,
        measured_TP: measured_TP ?? this.measured_TP,
        measured_i: measured_i ?? this.measured_i,
        measured_lra: measured_lra ?? this.measured_lra,
        measured_thresh: measured_thresh ?? this.measured_thresh,
        measured_tp: measured_tp ?? this.measured_tp,
        offset: offset ?? this.offset,
        print_format: identical(print_format, _unset)
            ? this.print_format
            : print_format as LoudnormPrintFormat?,
        tp: tp ?? this.tp,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnormSettings &&
          other.enabled == enabled &&
          other.I == I &&
          other.LRA == LRA &&
          other.TP == TP &&
          other.dual_mono == dual_mono &&
          other.i == i &&
          other.linear == linear &&
          other.lra == lra &&
          other.measured_I == measured_I &&
          other.measured_LRA == measured_LRA &&
          other.measured_TP == measured_TP &&
          other.measured_i == measured_i &&
          other.measured_lra == measured_lra &&
          other.measured_thresh == measured_thresh &&
          other.measured_tp == measured_tp &&
          other.offset == offset &&
          other.print_format == print_format &&
          other.tp == tp);

  @override
  int get hashCode => Object.hash(
      enabled,
      I,
      LRA,
      TP,
      dual_mono,
      i,
      linear,
      lra,
      measured_I,
      measured_LRA,
      measured_TP,
      measured_i,
      measured_lra,
      measured_thresh,
      measured_tp,
      offset,
      print_format,
      tp);

  @override
  String toString() =>
      'LoudnormSettings(enabled: $enabled, I: $I, LRA: $LRA, TP: $TP, dual_mono: $dual_mono, i: $i, linear: $linear, lra: $lra, measured_I: $measured_I, measured_LRA: $measured_LRA, measured_TP: $measured_TP, measured_i: $measured_i, measured_lra: $measured_lra, measured_thresh: $measured_thresh, measured_tp: $measured_tp, offset: $offset, print_format: $print_format, tp: $tp)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(I >= -70.0, 'loudnorm.I must be >= -70.0');
    assert(I <= -5.0, 'loudnorm.I must be <= -5.0');
    assert(LRA >= 1.0, 'loudnorm.LRA must be >= 1.0');
    assert(LRA <= 50.0, 'loudnorm.LRA must be <= 50.0');
    assert(TP >= -9.0, 'loudnorm.TP must be >= -9.0');
    assert(TP <= 0.0, 'loudnorm.TP must be <= 0.0');
    assert(i >= -70.0, 'loudnorm.i must be >= -70.0');
    assert(i <= -5.0, 'loudnorm.i must be <= -5.0');
    assert(lra >= 1.0, 'loudnorm.lra must be >= 1.0');
    assert(lra <= 50.0, 'loudnorm.lra must be <= 50.0');
    assert(measured_I >= -99.0, 'loudnorm.measured_I must be >= -99.0');
    assert(measured_I <= 0.0, 'loudnorm.measured_I must be <= 0.0');
    assert(measured_LRA >= 0.0, 'loudnorm.measured_LRA must be >= 0.0');
    assert(measured_LRA <= 99.0, 'loudnorm.measured_LRA must be <= 99.0');
    assert(measured_TP >= -99.0, 'loudnorm.measured_TP must be >= -99.0');
    assert(measured_TP <= 99.0, 'loudnorm.measured_TP must be <= 99.0');
    assert(measured_i >= -99.0, 'loudnorm.measured_i must be >= -99.0');
    assert(measured_i <= 0.0, 'loudnorm.measured_i must be <= 0.0');
    assert(measured_lra >= 0.0, 'loudnorm.measured_lra must be >= 0.0');
    assert(measured_lra <= 99.0, 'loudnorm.measured_lra must be <= 99.0');
    assert(
        measured_thresh >= -99.0, 'loudnorm.measured_thresh must be >= -99.0');
    assert(measured_thresh <= 0.0, 'loudnorm.measured_thresh must be <= 0.0');
    assert(measured_tp >= -99.0, 'loudnorm.measured_tp must be >= -99.0');
    assert(measured_tp <= 99.0, 'loudnorm.measured_tp must be <= 99.0');
    assert(offset >= -99.0, 'loudnorm.offset must be >= -99.0');
    assert(offset <= 99.0, 'loudnorm.offset must be <= 99.0');
    assert(tp >= -9.0, 'loudnorm.tp must be >= -9.0');
    assert(tp <= 0.0, 'loudnorm.tp must be <= 0.0');
    final parts = <String>[];
    if (I != -24.0) parts.add('I=' + I.toStringAsFixed(3));
    if (LRA != 7.0) parts.add('LRA=' + LRA.toStringAsFixed(3));
    if (TP != -2.0) parts.add('TP=' + TP.toStringAsFixed(3));
    if (dual_mono != false) parts.add('dual_mono=' + (dual_mono ? '1' : '0'));
    if (i != -24.0) parts.add('i=' + i.toStringAsFixed(3));
    if (linear != true) parts.add('linear=' + (linear ? '1' : '0'));
    if (lra != 7.0) parts.add('lra=' + lra.toStringAsFixed(3));
    if (measured_I != 0.0)
      parts.add('measured_I=' + measured_I.toStringAsFixed(3));
    if (measured_LRA != 0.0)
      parts.add('measured_LRA=' + measured_LRA.toStringAsFixed(3));
    if (measured_TP != 99.0)
      parts.add('measured_TP=' + measured_TP.toStringAsFixed(3));
    if (measured_i != 0.0)
      parts.add('measured_i=' + measured_i.toStringAsFixed(3));
    if (measured_lra != 0.0)
      parts.add('measured_lra=' + measured_lra.toStringAsFixed(3));
    if (measured_thresh != -70.0)
      parts.add('measured_thresh=' + measured_thresh.toStringAsFixed(3));
    if (measured_tp != 99.0)
      parts.add('measured_tp=' + measured_tp.toStringAsFixed(3));
    if (offset != 0.0) parts.add('offset=' + offset.toStringAsFixed(3));
    if (print_format != null)
      parts.add('print_format=' + print_format!.mpvValue);
    if (tp != -2.0) parts.add('tp=' + tp.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-loudnorm'
        : 'lavfi-loudnorm=' + parts.join(':');
  }
}

/// Configuration for the `lowpass` audio effect.
///
/// Apply a low-pass filter with 3dB point frequency.
/// The filter can be either single-pole or double-pole (the default).
/// The filter roll off at 6dB per pole per octave (20dB per pole per decade).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set frequency in Hz. Default is 500. (range 0..999999, default 500)
/// - [frequency]: Set frequency in Hz. Default is 500. (range 0..999999, default 500)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class LowpassSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final int p;
  final int poles;

  const LowpassSettings({
    this.enabled = false,
    this.f = 500.0,
    this.frequency = 500.0,
    this.p = 2,
    this.poles = 2,
  });

  LowpassSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    int? p,
    int? poles,
  }) =>
      LowpassSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowpassSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, p, poles);

  @override
  String toString() =>
      'LowpassSettings(enabled: $enabled, f: $f, frequency: $frequency, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'lowpass.f must be >= 0');
    assert(f <= 999999, 'lowpass.f must be <= 999999');
    assert(frequency >= 0, 'lowpass.frequency must be >= 0');
    assert(frequency <= 999999, 'lowpass.frequency must be <= 999999');
    assert(p >= 1, 'lowpass.p must be >= 1');
    assert(p <= 2, 'lowpass.p must be <= 2');
    assert(poles >= 1, 'lowpass.poles must be >= 1');
    assert(poles <= 2, 'lowpass.poles must be <= 2');
    final parts = <String>[];
    if (f != 500.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 500.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty ? 'lavfi-lowpass' : 'lavfi-lowpass=' + parts.join(':');
  }
}

/// Configuration for the `lowshelf` audio effect.
///
/// Boost or cut the bass (lower) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class LowshelfSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;
  final int p;
  final int poles;

  const LowshelfSettings({
    this.enabled = false,
    this.f = 100.0,
    this.frequency = 100.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.p = 2,
    this.poles = 2,
  });

  LowshelfSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    int? p,
    int? poles,
  }) =>
      LowshelfSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowshelfSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain, p, poles);

  @override
  String toString() =>
      'LowshelfSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'lowshelf.f must be >= 0');
    assert(f <= 999999, 'lowshelf.f must be <= 999999');
    assert(frequency >= 0, 'lowshelf.frequency must be >= 0');
    assert(frequency <= 999999, 'lowshelf.frequency must be <= 999999');
    assert(g >= -900, 'lowshelf.g must be >= -900');
    assert(g <= 900, 'lowshelf.g must be <= 900');
    assert(gain >= -900, 'lowshelf.gain must be >= -900');
    assert(gain <= 900, 'lowshelf.gain must be <= 900');
    assert(p >= 1, 'lowshelf.p must be >= 1');
    assert(p <= 2, 'lowshelf.p must be <= 2');
    assert(poles >= 1, 'lowshelf.poles must be >= 1');
    assert(poles <= 2, 'lowshelf.poles must be <= 2');
    final parts = <String>[];
    if (f != 100.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 100.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty
        ? 'lavfi-lowshelf'
        : 'lavfi-lowshelf=' + parts.join(':');
  }
}

/// Configuration for the `mcompand` audio effect.
///
/// Multiband Compress or expand the audio's dynamic range.
///
/// The input audio is divided into bands using 4th order Linkwitz-Riley IIRs.
/// This is akin to the crossover of a loudspeaker, and results in flat frequency
/// response when absent compander action.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [args]: This option syntax is: attack,decay,[attack,decay..] soft-knee points crossover_frequency [delay [initial_volume [gain]]] | attack,decay ... For explanation of each item refer to compand filter documentation. (range 0..0, default "0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000")
final class McompandSettings {
  final bool enabled;
  final String args;

  const McompandSettings({
    this.enabled = false,
    this.args =
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000',
  });

  McompandSettings copyWith({
    bool? enabled,
    String? args,
  }) =>
      McompandSettings(
        enabled: enabled ?? this.enabled,
        args: args ?? this.args,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McompandSettings &&
          other.enabled == enabled &&
          other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'McompandSettings(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (args !=
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000')
      parts.add('args=' + args);
    return parts.isEmpty
        ? 'lavfi-mcompand'
        : 'lavfi-mcompand=' + parts.join(':');
  }
}

/// Configuration for the `pan` audio effect.
///
/// Mix channels with specific gain levels. The filter accepts the output
/// channel layout followed by a set of channels definitions.
///
/// This filter is also designed to efficiently remap the channels of an audio
/// stream.
///
/// The filter accepts parameters of the form:
/// "`l`|`outdef`|`outdef`|..."
///
/// Parameters:
/// - [args]:  (range 0..0)
final class PanSettings {
  final bool enabled;
  final String? args;

  const PanSettings({
    this.enabled = false,
    this.args,
  });

  PanSettings copyWith({
    bool? enabled,
    Object? args = _unset,
  }) =>
      PanSettings(
        enabled: enabled ?? this.enabled,
        args: identical(args, _unset) ? this.args : args as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanSettings && other.enabled == enabled && other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'PanSettings(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (args != null) parts.add('args=' + args!);
    return parts.isEmpty ? 'lavfi-pan' : 'lavfi-pan=' + parts.join(':');
  }
}

/// Configuration for the `replaygain` audio effect.
///
/// ReplayGain scanner filter. This filter takes an audio stream as an input and
/// outputs it unchanged.
/// At end of filtering it displays `track_gain` and `track_peak`.
///
/// The filter accepts the following exported read-only options:
///
/// Parameters:
/// - [track_gain]: Exported track gain in dB at end of stream. (default 0)
/// - [track_peak]: Exported track peak at end of stream. (default 0)
final class ReplaygainSettings {
  final bool enabled;
  final double track_gain;
  final double track_peak;

  const ReplaygainSettings({
    this.enabled = false,
    this.track_gain = 0.0,
    this.track_peak = 0.0,
  });

  ReplaygainSettings copyWith({
    bool? enabled,
    double? track_gain,
    double? track_peak,
  }) =>
      ReplaygainSettings(
        enabled: enabled ?? this.enabled,
        track_gain: track_gain ?? this.track_gain,
        track_peak: track_peak ?? this.track_peak,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReplaygainSettings &&
          other.enabled == enabled &&
          other.track_gain == track_gain &&
          other.track_peak == track_peak);

  @override
  int get hashCode => Object.hash(enabled, track_gain, track_peak);

  @override
  String toString() =>
      'ReplaygainSettings(enabled: $enabled, track_gain: $track_gain, track_peak: $track_peak)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    if (track_gain != 0.0)
      parts.add('track_gain=' + track_gain.toStringAsFixed(3));
    if (track_peak != 0.0)
      parts.add('track_peak=' + track_peak.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-replaygain'
        : 'lavfi-replaygain=' + parts.join(':');
  }
}

/// Configuration for the `rubberband` audio effect.
///
/// Apply time-stretching and pitch-shifting with librubberband.
///
/// To enable compilation of this filter, you need to configure FFmpeg with
/// `--enable-librubberband`.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [channels]: set channels (default 0)
/// - [detector]: set detector (default 0)
/// - [formant]: set formant (default 0)
/// - [phase]: set phase (default 0)
/// - [pitch]: Set pitch scale factor. (range 0.01..100, default 1)
/// - [pitchq]: set pitch quality (default 0)
/// - [smoothing]: set smoothing (default 0)
/// - [tempo]: Set tempo scale factor. (range 0.01..100, default 1)
/// - [transients]: Set transients detector. Possible values are: (default 0)
/// - [window]: set window (default 0)
final class RubberbandSettings {
  final bool enabled;
  final RubberbandChannels channels;
  final RubberbandDetector detector;
  final RubberbandFormant formant;
  final RubberbandPhase phase;
  final double pitch;
  final RubberbandPitch pitchq;
  final RubberbandSmoothing smoothing;
  final double tempo;
  final RubberbandTransients transients;
  final RubberbandWindow window;

  const RubberbandSettings({
    this.enabled = false,
    this.channels = RubberbandChannels.apart,
    this.detector = RubberbandDetector.compound,
    this.formant = RubberbandFormant.shifted,
    this.phase = RubberbandPhase.laminar,
    this.pitch = 1.0,
    this.pitchq = RubberbandPitch.quality,
    this.smoothing = RubberbandSmoothing.off,
    this.tempo = 1.0,
    this.transients = RubberbandTransients.crisp,
    this.window = RubberbandWindow.standard,
  });

  RubberbandSettings copyWith({
    bool? enabled,
    RubberbandChannels? channels,
    RubberbandDetector? detector,
    RubberbandFormant? formant,
    RubberbandPhase? phase,
    double? pitch,
    RubberbandPitch? pitchq,
    RubberbandSmoothing? smoothing,
    double? tempo,
    RubberbandTransients? transients,
    RubberbandWindow? window,
  }) =>
      RubberbandSettings(
        enabled: enabled ?? this.enabled,
        channels: channels ?? this.channels,
        detector: detector ?? this.detector,
        formant: formant ?? this.formant,
        phase: phase ?? this.phase,
        pitch: pitch ?? this.pitch,
        pitchq: pitchq ?? this.pitchq,
        smoothing: smoothing ?? this.smoothing,
        tempo: tempo ?? this.tempo,
        transients: transients ?? this.transients,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RubberbandSettings &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.detector == detector &&
          other.formant == formant &&
          other.phase == phase &&
          other.pitch == pitch &&
          other.pitchq == pitchq &&
          other.smoothing == smoothing &&
          other.tempo == tempo &&
          other.transients == transients &&
          other.window == window);

  @override
  int get hashCode => Object.hash(enabled, channels, detector, formant, phase,
      pitch, pitchq, smoothing, tempo, transients, window);

  @override
  String toString() =>
      'RubberbandSettings(enabled: $enabled, channels: $channels, detector: $detector, formant: $formant, phase: $phase, pitch: $pitch, pitchq: $pitchq, smoothing: $smoothing, tempo: $tempo, transients: $transients, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(pitch >= 0.01, 'rubberband.pitch must be >= 0.01');
    assert(pitch <= 100, 'rubberband.pitch must be <= 100');
    assert(tempo >= 0.01, 'rubberband.tempo must be >= 0.01');
    assert(tempo <= 100, 'rubberband.tempo must be <= 100');
    final parts = <String>[];
    if (channels != RubberbandChannels.apart)
      parts.add('channels=' + channels.mpvValue);
    if (detector != RubberbandDetector.compound)
      parts.add('detector=' + detector.mpvValue);
    if (formant != RubberbandFormant.shifted)
      parts.add('formant=' + formant.mpvValue);
    if (phase != RubberbandPhase.laminar) parts.add('phase=' + phase.mpvValue);
    if (pitch != 1.0) parts.add('pitch=' + pitch.toStringAsFixed(3));
    if (pitchq != RubberbandPitch.quality)
      parts.add('pitchq=' + pitchq.mpvValue);
    if (smoothing != RubberbandSmoothing.off)
      parts.add('smoothing=' + smoothing.mpvValue);
    if (tempo != 1.0) parts.add('tempo=' + tempo.toStringAsFixed(3));
    if (transients != RubberbandTransients.crisp)
      parts.add('transients=' + transients.mpvValue);
    if (window != RubberbandWindow.standard)
      parts.add('window=' + window.mpvValue);
    return parts.isEmpty
        ? 'lavfi-rubberband'
        : 'lavfi-rubberband=' + parts.join(':');
  }
}

/// Configuration for the `silencedetect` audio effect.
///
/// Detect silence in an audio stream.
///
/// This filter logs a message when it detects that the input audio volume is less
/// or equal to a noise tolerance value for a duration greater or equal to the
/// minimum detected noise duration.
///
/// The printed times and duration are expressed in seconds. The
/// `lavfi.silence_start` or `lavfi.silence_start.X` metadata key
/// is set on the first frame whose timestamp equals or exceeds the detection
/// duration and it contains the timestamp of the first frame of the silence.
///
/// The `lavfi.silence_duration` or `lavfi.silence_duration.X`
/// and `lavfi.silence_end` or `lavfi.silence_end.X` metadata
/// keys are set on the first frame after the silence. If @option{mono} is
/// enabled, and each channel is evaluated separately, the `.X`
/// suffixed keys are used, and `X` corresponds to the channel number.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Set silence duration until notification (default is 2 seconds). See time duration syntax for the accepted syntax. (default 2000000)
/// - [duration]: Set silence duration until notification (default is 2 seconds). See time duration syntax for the accepted syntax. (default 2000000)
/// - [m]: Process each channel separately, instead of combined. By default is disabled. (range 0..1, default 0)
/// - [mono]: Process each channel separately, instead of combined. By default is disabled. (range 0..1, default 0)
/// - [n]: Set noise tolerance. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default is -60dB, or 0.001. (default 0.001)
/// - [noise]: Set noise tolerance. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default is -60dB, or 0.001. (default 0.001)
final class SilencedetectSettings {
  final bool enabled;
  final Duration d;
  final Duration duration;
  final bool m;
  final bool mono;
  final double n;
  final double noise;

  const SilencedetectSettings({
    this.enabled = false,
    this.d = const Duration(microseconds: 2000000),
    this.duration = const Duration(microseconds: 2000000),
    this.m = false,
    this.mono = false,
    this.n = 0.001,
    this.noise = 0.001,
  });

  SilencedetectSettings copyWith({
    bool? enabled,
    Duration? d,
    Duration? duration,
    bool? m,
    bool? mono,
    double? n,
    double? noise,
  }) =>
      SilencedetectSettings(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        duration: duration ?? this.duration,
        m: m ?? this.m,
        mono: mono ?? this.mono,
        n: n ?? this.n,
        noise: noise ?? this.noise,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilencedetectSettings &&
          other.enabled == enabled &&
          other.d == d &&
          other.duration == duration &&
          other.m == m &&
          other.mono == mono &&
          other.n == n &&
          other.noise == noise);

  @override
  int get hashCode => Object.hash(enabled, d, duration, m, mono, n, noise);

  @override
  String toString() =>
      'SilencedetectSettings(enabled: $enabled, d: $d, duration: $duration, m: $m, mono: $mono, n: $n, noise: $noise)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(n >= 0, 'silencedetect.n must be >= 0');
    assert(noise >= 0, 'silencedetect.noise must be >= 0');
    final parts = <String>[];
    if (d != const Duration(microseconds: 2000000))
      parts.add('d=' + (d.inMicroseconds / 1e6).toStringAsFixed(3));
    if (duration != const Duration(microseconds: 2000000))
      parts.add(
          'duration=' + (duration.inMicroseconds / 1e6).toStringAsFixed(3));
    if (m != false) parts.add('m=' + (m ? '1' : '0'));
    if (mono != false) parts.add('mono=' + (mono ? '1' : '0'));
    if (n != 0.001) parts.add('n=' + n.toStringAsFixed(3));
    if (noise != 0.001) parts.add('noise=' + noise.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-silencedetect'
        : 'lavfi-silencedetect=' + parts.join(':');
  }
}

/// Configuration for the `silenceremove` audio effect.
///
/// Remove silence from the beginning, middle or end of the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [detection]: Set how is silence detected.
/// - [start_duration]: Specify the amount of time that non-silence must be detected before it stops trimming audio. By increasing the duration, bursts of noises can be treated as silence and trimmed off. Default value is `0`. (default 0)
/// - [start_mode]: Specify mode of detection of silence end at start of multi-channel audio. Can be `any` or `all`. Default is `any`. With `any`, any sample from any channel that is detected as non-silence will trigger end of silence trimming at start of audio stream. With `all`, only if every sample from every channel is detected as non-silence will trigger end of silence trimming at start of audio stream, limited usage.
/// - [start_periods]: This value is used to indicate if audio should be trimmed at beginning of the audio. A value of zero indicates no silence should be trimmed from the beginning. When specifying a non-zero value, it trims audio up until it finds non-silence. Normally, when trimming silence from beginning of audio the `start_periods` will be `1` but it can be increased to higher values to trim all audio up to specific count of non-silence periods. Default value is `0`. (range 0..9000, default 0)
/// - [start_silence]: Specify max duration of silence at beginning that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (default 0)
/// - [start_threshold]: This indicates what sample value should be treated as silence. For digital audio, a value of `0` may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (default 0)
/// - [stop_duration]: Specify a duration of silence that must exist before audio is not copied any more. By specifying a higher duration, silence that is wanted can be left in the audio. Default value is `0`. (default 0)
/// - [stop_mode]: Specify mode of detection of silence start after start of multi-channel audio. Can be `any` or `all`. Default is `all`. With `any`, any sample from any channel that is detected as silence will trigger start of silence trimming after start of audio stream, limited usage. With `all`, only if every sample from every channel is detected as silence will trigger start of silence trimming after start of audio stream.
/// - [stop_periods]: Set the count for trimming silence from the end of audio. When specifying a positive value, it trims audio after it finds specified silence period. To remove silence from the middle of a file, specify a `stop_periods` that is negative. This value is then treated as a positive value and is used to indicate the effect should restart processing as specified by `stop_periods`, making it suitable for removing periods of silence in the middle of the audio. Default value is `0`. (range -9000..9000, default 0)
/// - [stop_silence]: Specify max duration of silence at end that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (default 0)
/// - [stop_threshold]: This is the same as @option{start_threshold} but for trimming silence from the end of audio. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (default 0)
/// - [timestamp]: Set processing mode of every audio frame output timestamp.
/// - [window]: Set duration in number of seconds used to calculate size of window in number of samples for detecting silence. Using `0` will effectively disable any windowing and use only single sample per channel for silence detection. In that case it may be needed to also set @option{start_silence} and/or @option{stop_silence} to nonzero values with also @option{start_duration} and/or @option{stop_duration} to nonzero values. Default value is `0.02`. Allowed range is from `0` to `10`. (range 0..100000000, default 20000)
final class SilenceremoveSettings {
  final bool enabled;
  final SilenceremoveDetection? detection;
  final Duration start_duration;
  final SilenceremoveMode? start_mode;
  final int start_periods;
  final Duration start_silence;
  final double start_threshold;
  final Duration stop_duration;
  final SilenceremoveMode? stop_mode;
  final int stop_periods;
  final Duration stop_silence;
  final double stop_threshold;
  final SilenceremoveTimestamp? timestamp;
  final Duration window;

  const SilenceremoveSettings({
    this.enabled = false,
    this.detection,
    this.start_duration = const Duration(microseconds: 0),
    this.start_mode,
    this.start_periods = 0,
    this.start_silence = const Duration(microseconds: 0),
    this.start_threshold = 0.0,
    this.stop_duration = const Duration(microseconds: 0),
    this.stop_mode,
    this.stop_periods = 0,
    this.stop_silence = const Duration(microseconds: 0),
    this.stop_threshold = 0.0,
    this.timestamp,
    this.window = const Duration(microseconds: 20000),
  });

  SilenceremoveSettings copyWith({
    bool? enabled,
    Object? detection = _unset,
    Duration? start_duration,
    Object? start_mode = _unset,
    int? start_periods,
    Duration? start_silence,
    double? start_threshold,
    Duration? stop_duration,
    Object? stop_mode = _unset,
    int? stop_periods,
    Duration? stop_silence,
    double? stop_threshold,
    Object? timestamp = _unset,
    Duration? window,
  }) =>
      SilenceremoveSettings(
        enabled: enabled ?? this.enabled,
        detection: identical(detection, _unset)
            ? this.detection
            : detection as SilenceremoveDetection?,
        start_duration: start_duration ?? this.start_duration,
        start_mode: identical(start_mode, _unset)
            ? this.start_mode
            : start_mode as SilenceremoveMode?,
        start_periods: start_periods ?? this.start_periods,
        start_silence: start_silence ?? this.start_silence,
        start_threshold: start_threshold ?? this.start_threshold,
        stop_duration: stop_duration ?? this.stop_duration,
        stop_mode: identical(stop_mode, _unset)
            ? this.stop_mode
            : stop_mode as SilenceremoveMode?,
        stop_periods: stop_periods ?? this.stop_periods,
        stop_silence: stop_silence ?? this.stop_silence,
        stop_threshold: stop_threshold ?? this.stop_threshold,
        timestamp: identical(timestamp, _unset)
            ? this.timestamp
            : timestamp as SilenceremoveTimestamp?,
        window: window ?? this.window,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilenceremoveSettings &&
          other.enabled == enabled &&
          other.detection == detection &&
          other.start_duration == start_duration &&
          other.start_mode == start_mode &&
          other.start_periods == start_periods &&
          other.start_silence == start_silence &&
          other.start_threshold == start_threshold &&
          other.stop_duration == stop_duration &&
          other.stop_mode == stop_mode &&
          other.stop_periods == stop_periods &&
          other.stop_silence == stop_silence &&
          other.stop_threshold == stop_threshold &&
          other.timestamp == timestamp &&
          other.window == window);

  @override
  int get hashCode => Object.hash(
      enabled,
      detection,
      start_duration,
      start_mode,
      start_periods,
      start_silence,
      start_threshold,
      stop_duration,
      stop_mode,
      stop_periods,
      stop_silence,
      stop_threshold,
      timestamp,
      window);

  @override
  String toString() =>
      'SilenceremoveSettings(enabled: $enabled, detection: $detection, start_duration: $start_duration, start_mode: $start_mode, start_periods: $start_periods, start_silence: $start_silence, start_threshold: $start_threshold, stop_duration: $stop_duration, stop_mode: $stop_mode, stop_periods: $stop_periods, stop_silence: $stop_silence, stop_threshold: $stop_threshold, timestamp: $timestamp, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(start_periods >= 0, 'silenceremove.start_periods must be >= 0');
    assert(
        start_periods <= 9000, 'silenceremove.start_periods must be <= 9000');
    assert(start_threshold >= 0, 'silenceremove.start_threshold must be >= 0');
    assert(
        stop_periods >= -9000, 'silenceremove.stop_periods must be >= -9000');
    assert(stop_periods <= 9000, 'silenceremove.stop_periods must be <= 9000');
    assert(stop_threshold >= 0, 'silenceremove.stop_threshold must be >= 0');
    final parts = <String>[];
    if (detection != null) parts.add('detection=' + detection!.mpvValue);
    if (start_duration != const Duration(microseconds: 0))
      parts.add('start_duration=' +
          (start_duration.inMicroseconds / 1e6).toStringAsFixed(3));
    if (start_mode != null) parts.add('start_mode=' + start_mode!.mpvValue);
    if (start_periods != 0)
      parts.add('start_periods=' + start_periods.toString());
    if (start_silence != const Duration(microseconds: 0))
      parts.add('start_silence=' +
          (start_silence.inMicroseconds / 1e6).toStringAsFixed(3));
    if (start_threshold != 0.0)
      parts.add('start_threshold=' + start_threshold.toStringAsFixed(3));
    if (stop_duration != const Duration(microseconds: 0))
      parts.add('stop_duration=' +
          (stop_duration.inMicroseconds / 1e6).toStringAsFixed(3));
    if (stop_mode != null) parts.add('stop_mode=' + stop_mode!.mpvValue);
    if (stop_periods != 0) parts.add('stop_periods=' + stop_periods.toString());
    if (stop_silence != const Duration(microseconds: 0))
      parts.add('stop_silence=' +
          (stop_silence.inMicroseconds / 1e6).toStringAsFixed(3));
    if (stop_threshold != 0.0)
      parts.add('stop_threshold=' + stop_threshold.toStringAsFixed(3));
    if (timestamp != null) parts.add('timestamp=' + timestamp!.mpvValue);
    if (window != const Duration(microseconds: 20000))
      parts.add('window=' + (window.inMicroseconds / 1e6).toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-silenceremove'
        : 'lavfi-silenceremove=' + parts.join(':');
  }
}

/// Configuration for the `speechnorm` audio effect.
///
/// Speech Normalizer.
///
/// This filter expands or compresses each half-cycle of audio samples
/// (local set of samples all above or all below zero and between two nearest zero crossings) depending
/// on threshold value, so audio reaches target peak value under conditions controlled by below options.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [c]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0)
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all")
/// - [compression]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0)
/// - [e]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0)
/// - [expansion]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0)
/// - [f]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001)
/// - [fall]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001)
/// - [h]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all")
/// - [i]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0)
/// - [invert]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0)
/// - [l]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0)
/// - [link]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0)
/// - [m]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0)
/// - [p]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95)
/// - [peak]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95)
/// - [r]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001)
/// - [raise]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001)
/// - [rms]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0)
/// - [t]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0)
/// - [threshold]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0)
final class SpeechnormSettings {
  final bool enabled;
  final double c;
  final String channels;
  final double compression;
  final double e;
  final double expansion;
  final double f;
  final double fall;
  final String h;
  final bool i;
  final bool invert;
  final bool l;
  final bool link;
  final double m;
  final double p;
  final double peak;
  final double r;
  final double raise;
  final double rms;
  final double t;
  final double threshold;

  const SpeechnormSettings({
    this.enabled = false,
    this.c = 2.0,
    this.channels = 'all',
    this.compression = 2.0,
    this.e = 2.0,
    this.expansion = 2.0,
    this.f = 0.001,
    this.fall = 0.001,
    this.h = 'all',
    this.i = false,
    this.invert = false,
    this.l = false,
    this.link = false,
    this.m = 0.0,
    this.p = 0.95,
    this.peak = 0.95,
    this.r = 0.001,
    this.raise = 0.001,
    this.rms = 0.0,
    this.t = 0.0,
    this.threshold = 0.0,
  });

  SpeechnormSettings copyWith({
    bool? enabled,
    double? c,
    String? channels,
    double? compression,
    double? e,
    double? expansion,
    double? f,
    double? fall,
    String? h,
    bool? i,
    bool? invert,
    bool? l,
    bool? link,
    double? m,
    double? p,
    double? peak,
    double? r,
    double? raise,
    double? rms,
    double? t,
    double? threshold,
  }) =>
      SpeechnormSettings(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        channels: channels ?? this.channels,
        compression: compression ?? this.compression,
        e: e ?? this.e,
        expansion: expansion ?? this.expansion,
        f: f ?? this.f,
        fall: fall ?? this.fall,
        h: h ?? this.h,
        i: i ?? this.i,
        invert: invert ?? this.invert,
        l: l ?? this.l,
        link: link ?? this.link,
        m: m ?? this.m,
        p: p ?? this.p,
        peak: peak ?? this.peak,
        r: r ?? this.r,
        raise: raise ?? this.raise,
        rms: rms ?? this.rms,
        t: t ?? this.t,
        threshold: threshold ?? this.threshold,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeechnormSettings &&
          other.enabled == enabled &&
          other.c == c &&
          other.channels == channels &&
          other.compression == compression &&
          other.e == e &&
          other.expansion == expansion &&
          other.f == f &&
          other.fall == fall &&
          other.h == h &&
          other.i == i &&
          other.invert == invert &&
          other.l == l &&
          other.link == link &&
          other.m == m &&
          other.p == p &&
          other.peak == peak &&
          other.r == r &&
          other.raise == raise &&
          other.rms == rms &&
          other.t == t &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        c,
        channels,
        compression,
        e,
        expansion,
        f,
        fall,
        h,
        i,
        invert,
        l,
        link,
        m,
        p,
        peak,
        r,
        raise,
        rms,
        t,
        threshold
      ]);

  @override
  String toString() =>
      'SpeechnormSettings(enabled: $enabled, c: $c, channels: $channels, compression: $compression, e: $e, expansion: $expansion, f: $f, fall: $fall, h: $h, i: $i, invert: $invert, l: $l, link: $link, m: $m, p: $p, peak: $peak, r: $r, raise: $raise, rms: $rms, t: $t, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(c >= 1.0, 'speechnorm.c must be >= 1.0');
    assert(c <= 50.0, 'speechnorm.c must be <= 50.0');
    assert(compression >= 1.0, 'speechnorm.compression must be >= 1.0');
    assert(compression <= 50.0, 'speechnorm.compression must be <= 50.0');
    assert(e >= 1.0, 'speechnorm.e must be >= 1.0');
    assert(e <= 50.0, 'speechnorm.e must be <= 50.0');
    assert(expansion >= 1.0, 'speechnorm.expansion must be >= 1.0');
    assert(expansion <= 50.0, 'speechnorm.expansion must be <= 50.0');
    assert(f >= 0.0, 'speechnorm.f must be >= 0.0');
    assert(f <= 1.0, 'speechnorm.f must be <= 1.0');
    assert(fall >= 0.0, 'speechnorm.fall must be >= 0.0');
    assert(fall <= 1.0, 'speechnorm.fall must be <= 1.0');
    assert(m >= 0.0, 'speechnorm.m must be >= 0.0');
    assert(m <= 1.0, 'speechnorm.m must be <= 1.0');
    assert(p >= 0.0, 'speechnorm.p must be >= 0.0');
    assert(p <= 1.0, 'speechnorm.p must be <= 1.0');
    assert(peak >= 0.0, 'speechnorm.peak must be >= 0.0');
    assert(peak <= 1.0, 'speechnorm.peak must be <= 1.0');
    assert(r >= 0.0, 'speechnorm.r must be >= 0.0');
    assert(r <= 1.0, 'speechnorm.r must be <= 1.0');
    assert(raise >= 0.0, 'speechnorm.raise must be >= 0.0');
    assert(raise <= 1.0, 'speechnorm.raise must be <= 1.0');
    assert(rms >= 0.0, 'speechnorm.rms must be >= 0.0');
    assert(rms <= 1.0, 'speechnorm.rms must be <= 1.0');
    assert(t >= 0.0, 'speechnorm.t must be >= 0.0');
    assert(t <= 1.0, 'speechnorm.t must be <= 1.0');
    assert(threshold >= 0.0, 'speechnorm.threshold must be >= 0.0');
    assert(threshold <= 1.0, 'speechnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (c != 2.0) parts.add('c=' + c.toStringAsFixed(3));
    if (channels != 'all') parts.add('channels=' + channels);
    if (compression != 2.0)
      parts.add('compression=' + compression.toStringAsFixed(3));
    if (e != 2.0) parts.add('e=' + e.toStringAsFixed(3));
    if (expansion != 2.0)
      parts.add('expansion=' + expansion.toStringAsFixed(3));
    if (f != 0.001) parts.add('f=' + f.toStringAsFixed(3));
    if (fall != 0.001) parts.add('fall=' + fall.toStringAsFixed(3));
    if (h != 'all') parts.add('h=' + h);
    if (i != false) parts.add('i=' + (i ? '1' : '0'));
    if (invert != false) parts.add('invert=' + (invert ? '1' : '0'));
    if (l != false) parts.add('l=' + (l ? '1' : '0'));
    if (link != false) parts.add('link=' + (link ? '1' : '0'));
    if (m != 0.0) parts.add('m=' + m.toStringAsFixed(3));
    if (p != 0.95) parts.add('p=' + p.toStringAsFixed(3));
    if (peak != 0.95) parts.add('peak=' + peak.toStringAsFixed(3));
    if (r != 0.001) parts.add('r=' + r.toStringAsFixed(3));
    if (raise != 0.001) parts.add('raise=' + raise.toStringAsFixed(3));
    if (rms != 0.0) parts.add('rms=' + rms.toStringAsFixed(3));
    if (t != 0.0) parts.add('t=' + t.toStringAsFixed(3));
    if (threshold != 0.0)
      parts.add('threshold=' + threshold.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-speechnorm'
        : 'lavfi-speechnorm=' + parts.join(':');
  }
}

/// Configuration for the `stereotools` audio effect.
///
/// This filter has some handy utilities to manage stereo signals, for converting
/// M/S stereo recordings to L/R signal while having control over the parameters
/// or spreading the stereo image of master track.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [balance_in]: Set input balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0)
/// - [balance_out]: Set output balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0)
/// - [base]: set stereo base (range -1..1, default 0)
/// - [bmode_in]: set balance in mode (range 0..2, default 0)
/// - [bmode_out]: set balance out mode (range 0..2, default 0)
/// - [delay]: set delay (range -20..20, default 0)
/// - [level_in]: Set input level before filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1)
/// - [level_out]: Set output level after filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1)
/// - [mlev]: set middle level (range 0.015625..64, default 1)
/// - [mode]: Set stereo mode. Available values are: (range 0..10, default 0)
/// - [mpan]: set middle pan (range -1..1, default 0)
/// - [mutel]: Mute the left channel. Disabled by default. (range 0..1, default 0)
/// - [muter]: Mute the right channel. Disabled by default. (range 0..1, default 0)
/// - [phase]: set stereo phase (range 0..360, default 0)
/// - [phasel]: Change the phase of the left channel. Disabled by default. (range 0..1, default 0)
/// - [phaser]: Change the phase of the right channel. Disabled by default. (range 0..1, default 0)
/// - [sbal]: set side balance (range -1..1, default 0)
/// - [sclevel]: set S/C level (range 1..100, default 1)
/// - [slev]: set side level (range 0.015625..64, default 1)
/// - [softclip]: Enable softclipping. Results in analog distortion instead of harsh digital 0dB clipping. Disabled by default. (range 0..1, default 0)
final class StereotoolsSettings {
  final bool enabled;
  final double balance_in;
  final double balance_out;
  final double base;
  final StereotoolsBmode bmode_in;
  final StereotoolsBmode bmode_out;
  final double delay;
  final double level_in;
  final double level_out;
  final double mlev;
  final StereotoolsMode mode;
  final double mpan;
  final bool mutel;
  final bool muter;
  final double phase;
  final bool phasel;
  final bool phaser;
  final double sbal;
  final double sclevel;
  final double slev;
  final bool softclip;

  const StereotoolsSettings({
    this.enabled = false,
    this.balance_in = 0.0,
    this.balance_out = 0.0,
    this.base = 0.0,
    this.bmode_in = StereotoolsBmode.balance,
    this.bmode_out = StereotoolsBmode.balance,
    this.delay = 0.0,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.mlev = 1.0,
    this.mode = StereotoolsMode.lr_to_lr,
    this.mpan = 0.0,
    this.mutel = false,
    this.muter = false,
    this.phase = 0.0,
    this.phasel = false,
    this.phaser = false,
    this.sbal = 0.0,
    this.sclevel = 1.0,
    this.slev = 1.0,
    this.softclip = false,
  });

  StereotoolsSettings copyWith({
    bool? enabled,
    double? balance_in,
    double? balance_out,
    double? base,
    StereotoolsBmode? bmode_in,
    StereotoolsBmode? bmode_out,
    double? delay,
    double? level_in,
    double? level_out,
    double? mlev,
    StereotoolsMode? mode,
    double? mpan,
    bool? mutel,
    bool? muter,
    double? phase,
    bool? phasel,
    bool? phaser,
    double? sbal,
    double? sclevel,
    double? slev,
    bool? softclip,
  }) =>
      StereotoolsSettings(
        enabled: enabled ?? this.enabled,
        balance_in: balance_in ?? this.balance_in,
        balance_out: balance_out ?? this.balance_out,
        base: base ?? this.base,
        bmode_in: bmode_in ?? this.bmode_in,
        bmode_out: bmode_out ?? this.bmode_out,
        delay: delay ?? this.delay,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        mlev: mlev ?? this.mlev,
        mode: mode ?? this.mode,
        mpan: mpan ?? this.mpan,
        mutel: mutel ?? this.mutel,
        muter: muter ?? this.muter,
        phase: phase ?? this.phase,
        phasel: phasel ?? this.phasel,
        phaser: phaser ?? this.phaser,
        sbal: sbal ?? this.sbal,
        sclevel: sclevel ?? this.sclevel,
        slev: slev ?? this.slev,
        softclip: softclip ?? this.softclip,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereotoolsSettings &&
          other.enabled == enabled &&
          other.balance_in == balance_in &&
          other.balance_out == balance_out &&
          other.base == base &&
          other.bmode_in == bmode_in &&
          other.bmode_out == bmode_out &&
          other.delay == delay &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.mlev == mlev &&
          other.mode == mode &&
          other.mpan == mpan &&
          other.mutel == mutel &&
          other.muter == muter &&
          other.phase == phase &&
          other.phasel == phasel &&
          other.phaser == phaser &&
          other.sbal == sbal &&
          other.sclevel == sclevel &&
          other.slev == slev &&
          other.softclip == softclip);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        balance_in,
        balance_out,
        base,
        bmode_in,
        bmode_out,
        delay,
        level_in,
        level_out,
        mlev,
        mode,
        mpan,
        mutel,
        muter,
        phase,
        phasel,
        phaser,
        sbal,
        sclevel,
        slev,
        softclip
      ]);

  @override
  String toString() =>
      'StereotoolsSettings(enabled: $enabled, balance_in: $balance_in, balance_out: $balance_out, base: $base, bmode_in: $bmode_in, bmode_out: $bmode_out, delay: $delay, level_in: $level_in, level_out: $level_out, mlev: $mlev, mode: $mode, mpan: $mpan, mutel: $mutel, muter: $muter, phase: $phase, phasel: $phasel, phaser: $phaser, sbal: $sbal, sclevel: $sclevel, slev: $slev, softclip: $softclip)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(balance_in >= -1, 'stereotools.balance_in must be >= -1');
    assert(balance_in <= 1, 'stereotools.balance_in must be <= 1');
    assert(balance_out >= -1, 'stereotools.balance_out must be >= -1');
    assert(balance_out <= 1, 'stereotools.balance_out must be <= 1');
    assert(base >= -1, 'stereotools.base must be >= -1');
    assert(base <= 1, 'stereotools.base must be <= 1');
    assert(delay >= -20, 'stereotools.delay must be >= -20');
    assert(delay <= 20, 'stereotools.delay must be <= 20');
    assert(level_in >= 0.015625, 'stereotools.level_in must be >= 0.015625');
    assert(level_in <= 64, 'stereotools.level_in must be <= 64');
    assert(level_out >= 0.015625, 'stereotools.level_out must be >= 0.015625');
    assert(level_out <= 64, 'stereotools.level_out must be <= 64');
    assert(mlev >= 0.015625, 'stereotools.mlev must be >= 0.015625');
    assert(mlev <= 64, 'stereotools.mlev must be <= 64');
    assert(mpan >= -1, 'stereotools.mpan must be >= -1');
    assert(mpan <= 1, 'stereotools.mpan must be <= 1');
    assert(phase >= 0, 'stereotools.phase must be >= 0');
    assert(phase <= 360, 'stereotools.phase must be <= 360');
    assert(sbal >= -1, 'stereotools.sbal must be >= -1');
    assert(sbal <= 1, 'stereotools.sbal must be <= 1');
    assert(sclevel >= 1, 'stereotools.sclevel must be >= 1');
    assert(sclevel <= 100, 'stereotools.sclevel must be <= 100');
    assert(slev >= 0.015625, 'stereotools.slev must be >= 0.015625');
    assert(slev <= 64, 'stereotools.slev must be <= 64');
    final parts = <String>[];
    if (balance_in != 0.0)
      parts.add('balance_in=' + balance_in.toStringAsFixed(3));
    if (balance_out != 0.0)
      parts.add('balance_out=' + balance_out.toStringAsFixed(3));
    if (base != 0.0) parts.add('base=' + base.toStringAsFixed(3));
    if (bmode_in != StereotoolsBmode.balance)
      parts.add('bmode_in=' + bmode_in.mpvValue);
    if (bmode_out != StereotoolsBmode.balance)
      parts.add('bmode_out=' + bmode_out.mpvValue);
    if (delay != 0.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (mlev != 1.0) parts.add('mlev=' + mlev.toStringAsFixed(3));
    if (mode != StereotoolsMode.lr_to_lr) parts.add('mode=' + mode.mpvValue);
    if (mpan != 0.0) parts.add('mpan=' + mpan.toStringAsFixed(3));
    if (mutel != false) parts.add('mutel=' + (mutel ? '1' : '0'));
    if (muter != false) parts.add('muter=' + (muter ? '1' : '0'));
    if (phase != 0.0) parts.add('phase=' + phase.toStringAsFixed(3));
    if (phasel != false) parts.add('phasel=' + (phasel ? '1' : '0'));
    if (phaser != false) parts.add('phaser=' + (phaser ? '1' : '0'));
    if (sbal != 0.0) parts.add('sbal=' + sbal.toStringAsFixed(3));
    if (sclevel != 1.0) parts.add('sclevel=' + sclevel.toStringAsFixed(3));
    if (slev != 1.0) parts.add('slev=' + slev.toStringAsFixed(3));
    if (softclip != false) parts.add('softclip=' + (softclip ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-stereotools'
        : 'lavfi-stereotools=' + parts.join(':');
  }
}

/// Configuration for the `stereowiden` audio effect.
///
/// This filter enhance the stereo effect by suppressing signal common to both
/// channels and by delaying the signal of left into right and vice versa,
/// thereby widening the stereo effect.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [crossfeed]: Cross feed of left into right with inverted phase. This helps in suppressing the mono. If the value is 1 it will cancel all the signal common to both channels. Default is 0.3. (range 0..0.8, default .3)
/// - [delay]: Time in milliseconds of the delay of left signal into right and vice versa. Default is 20 milliseconds. (range 1..100, default 20)
/// - [drymix]: Set level of input signal of original channel. Default is 0.8. (range 0..1.0, default .8)
/// - [feedback]: Amount of gain in delayed signal into right and vice versa. Gives a delay effect of left signal in right output and vice versa which gives widening effect. Default is 0.3. (range 0..0.9, default .3)
final class StereowidenSettings {
  final bool enabled;
  final double crossfeed;
  final double delay;
  final double drymix;
  final double feedback;

  const StereowidenSettings({
    this.enabled = false,
    this.crossfeed = .3,
    this.delay = 20.0,
    this.drymix = .8,
    this.feedback = .3,
  });

  StereowidenSettings copyWith({
    bool? enabled,
    double? crossfeed,
    double? delay,
    double? drymix,
    double? feedback,
  }) =>
      StereowidenSettings(
        enabled: enabled ?? this.enabled,
        crossfeed: crossfeed ?? this.crossfeed,
        delay: delay ?? this.delay,
        drymix: drymix ?? this.drymix,
        feedback: feedback ?? this.feedback,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereowidenSettings &&
          other.enabled == enabled &&
          other.crossfeed == crossfeed &&
          other.delay == delay &&
          other.drymix == drymix &&
          other.feedback == feedback);

  @override
  int get hashCode => Object.hash(enabled, crossfeed, delay, drymix, feedback);

  @override
  String toString() =>
      'StereowidenSettings(enabled: $enabled, crossfeed: $crossfeed, delay: $delay, drymix: $drymix, feedback: $feedback)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(crossfeed >= 0, 'stereowiden.crossfeed must be >= 0');
    assert(crossfeed <= 0.8, 'stereowiden.crossfeed must be <= 0.8');
    assert(delay >= 1, 'stereowiden.delay must be >= 1');
    assert(delay <= 100, 'stereowiden.delay must be <= 100');
    assert(drymix >= 0, 'stereowiden.drymix must be >= 0');
    assert(drymix <= 1.0, 'stereowiden.drymix must be <= 1.0');
    assert(feedback >= 0, 'stereowiden.feedback must be >= 0');
    assert(feedback <= 0.9, 'stereowiden.feedback must be <= 0.9');
    final parts = <String>[];
    if (crossfeed != .3) parts.add('crossfeed=' + crossfeed.toStringAsFixed(3));
    if (delay != 20.0) parts.add('delay=' + delay.toStringAsFixed(3));
    if (drymix != .8) parts.add('drymix=' + drymix.toStringAsFixed(3));
    if (feedback != .3) parts.add('feedback=' + feedback.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-stereowiden'
        : 'lavfi-stereowiden=' + parts.join(':');
  }
}

/// Configuration for the `superequalizer` audio effect.
///
/// Apply 18 band equalizer.
///
/// The filter accepts the following options:
///
/// Parameters whose names start with a digit, addressed by
/// their original key in the [params] map:
/// - `10b`: Set 1480Hz band gain. (range 0..20, default 1)
/// - `11b`: Set 2093Hz band gain. (range 0..20, default 1)
/// - `12b`: Set 2960Hz band gain. (range 0..20, default 1)
/// - `13b`: Set 4186Hz band gain. (range 0..20, default 1)
/// - `14b`: Set 5920Hz band gain. (range 0..20, default 1)
/// - `15b`: Set 8372Hz band gain. (range 0..20, default 1)
/// - `16b`: Set 11840Hz band gain. (range 0..20, default 1)
/// - `17b`: Set 16744Hz band gain. (range 0..20, default 1)
/// - `18b`: Set 20000Hz band gain. (range 0..20, default 1)
/// - `1b`: Set 65Hz band gain. (range 0..20, default 1)
/// - `2b`: Set 92Hz band gain. (range 0..20, default 1)
/// - `3b`: Set 131Hz band gain. (range 0..20, default 1)
/// - `4b`: Set 185Hz band gain. (range 0..20, default 1)
/// - `5b`: Set 262Hz band gain. (range 0..20, default 1)
/// - `6b`: Set 370Hz band gain. (range 0..20, default 1)
/// - `7b`: Set 523Hz band gain. (range 0..20, default 1)
/// - `8b`: Set 740Hz band gain. (range 0..20, default 1)
/// - `9b`: Set 1047Hz band gain. (range 0..20, default 1)
final class SuperequalizerSettings {
  final bool enabled;
  final Map<String, double> params;

  const SuperequalizerSettings({
    this.enabled = false,
    this.params = const <String, double>{},
  });

  SuperequalizerSettings copyWith({
    bool? enabled,
    Map<String, double>? params,
  }) =>
      SuperequalizerSettings(
        enabled: enabled ?? this.enabled,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuperequalizerSettings &&
          other.enabled == enabled &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
      enabled,
      Object.hashAllUnordered(
          params.entries.map((e) => Object.hash(e.key, e.value))));

  @override
  String toString() =>
      'SuperequalizerSettings(enabled: $enabled, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    final parts = <String>[];
    params.forEach((k, v) => parts.add('$k=' + v.toStringAsFixed(3)));
    return parts.isEmpty
        ? 'lavfi-superequalizer'
        : 'lavfi-superequalizer=' + parts.join(':');
  }
}

/// Configuration for the `surround` audio effect.
///
/// Apply audio surround upmix filter.
///
/// This filter allows to produce multichannel output from audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [allx]: Set spread usage of stereo image across X axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1)
/// - [ally]: Set spread usage of stereo image across Y axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1)
/// - [angle]: Set angle of stereo surround transform, Allowed range is from `0` to `360`. Default is `90`. (range 0..360, default 90)
/// - [bc_in]: Set back center input volume. By default, this is `1`. (range 0..10, default 1)
/// - [bc_out]: Set back center output volume. By default, this is `1`. (range 0..10, default 1)
/// - [bcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [bcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [bl_in]: Set back left input volume. By default, this is `1`. (range 0..10, default 1)
/// - [bl_out]: Set back left output volume. By default, this is `1`. (range 0..10, default 1)
/// - [blx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [bly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [br_in]: Set back right input volume. By default, this is `1`. (range 0..10, default 1)
/// - [br_out]: Set back right output volume. By default, this is `1`. (range 0..10, default 1)
/// - [brx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [bry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [chl_in]: Set input channel layout. By default, this is `stereo`.  See channel layout syntax for the required syntax. (range 0..0, default "stereo")
/// - [chl_out]: Set output channel layout. By default, this is `5.1`.  See channel layout syntax for the required syntax. (range 0..0, default "5.1")
/// - [fc_in]: Set front center input volume. By default, this is `1`. (range 0..10, default 1)
/// - [fc_out]: Set front center output volume. By default, this is `1`. (range 0..10, default 1)
/// - [fcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [fcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [fl_in]: Set front left input volume. By default, this is `1`. (range 0..10, default 1)
/// - [fl_out]: Set front left output volume. By default, this is `1`. (range 0..10, default 1)
/// - [flx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [fly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [focus]: Set focus of stereo surround transform, Allowed range is from `-1` to `1`. Default is `0`. (range -1..1, default 0)
/// - [fr_in]: Set front right input volume. By default, this is `1`. (range 0..10, default 1)
/// - [fr_out]: Set front right output volume. By default, this is `1`. (range 0..10, default 1)
/// - [frx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [fry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [level_in]: Set input volume level. By default, this is `1`. (range 0..10, default 1)
/// - [level_out]: Set output volume level. By default, this is `1`. (range 0..10, default 1)
/// - [lfe]: Enable LFE channel output if output channel layout has it. By default, this is enabled. (range 0..1, default 1)
/// - [lfe_high]: Set LFE high cut off frequency. By default, this is `256` Hz. (range 0..512, default 256)
/// - [lfe_in]: Set LFE input volume. By default, this is `1`. (range 0..10, default 1)
/// - [lfe_low]: Set LFE low cut off frequency. By default, this is `128` Hz. (range 0..256, default 128)
/// - [lfe_mode]: Set LFE mode, can be `add` or `sub`. Default is `add`. In `add` mode, LFE channel is created from input audio and added to output. In `sub` mode, LFE channel is created from input audio and added to output but also all non-LFE output channels are subtracted with output LFE channel. (range 0..1, default 0)
/// - [lfe_out]: Set LFE output volume. By default, this is `1`. (range 0..10, default 1)
/// - [overlap]: set window overlap (range 0..1, default 0.5)
/// - [sl_in]: Set side left input volume. By default, this is `1`. (range 0..10, default 1)
/// - [sl_out]: Set side left output volume. By default, this is `1`. (range 0..10, default 1)
/// - [slx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [sly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [smooth]: Set temporal smoothness strength, used to gradually change factors when transforming stereo sound in time. Allowed range is from `0.0` to `1.0`. Useful to improve output quality with `focus` option values greater than `0.0`. Default is `0.0`. Only values inside this range and without edges are effective. (range 0..1, default 0)
/// - [sr_in]: Set side right input volume. By default, this is `1`. (range 0..10, default 1)
/// - [sr_out]: Set side right output volume. By default, this is `1`. (range 0..10, default 1)
/// - [srx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [sry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (default 0.5)
/// - [win_size]: Set window size. Allowed range is from `1024` to `65536`. Default size is `4096`. (range 1024..65536, default 4096)
final class SurroundSettings {
  final bool enabled;
  final double allx;
  final double ally;
  final double angle;
  final double bc_in;
  final double bc_out;
  final double bcx;
  final double bcy;
  final double bl_in;
  final double bl_out;
  final double blx;
  final double bly;
  final double br_in;
  final double br_out;
  final double brx;
  final double bry;
  final String chl_in;
  final String chl_out;
  final double fc_in;
  final double fc_out;
  final double fcx;
  final double fcy;
  final double fl_in;
  final double fl_out;
  final double flx;
  final double fly;
  final double focus;
  final double fr_in;
  final double fr_out;
  final double frx;
  final double fry;
  final double level_in;
  final double level_out;
  final bool lfe;
  final int lfe_high;
  final double lfe_in;
  final int lfe_low;
  final SurroundLfeMode lfe_mode;
  final double lfe_out;
  final double overlap;
  final double sl_in;
  final double sl_out;
  final double slx;
  final double sly;
  final double smooth;
  final double sr_in;
  final double sr_out;
  final double srx;
  final double sry;
  final int win_size;

  const SurroundSettings({
    this.enabled = false,
    this.allx = -1.0,
    this.ally = -1.0,
    this.angle = 90.0,
    this.bc_in = 1.0,
    this.bc_out = 1.0,
    this.bcx = 0.5,
    this.bcy = 0.5,
    this.bl_in = 1.0,
    this.bl_out = 1.0,
    this.blx = 0.5,
    this.bly = 0.5,
    this.br_in = 1.0,
    this.br_out = 1.0,
    this.brx = 0.5,
    this.bry = 0.5,
    this.chl_in = "stereo",
    this.chl_out = "5.1",
    this.fc_in = 1.0,
    this.fc_out = 1.0,
    this.fcx = 0.5,
    this.fcy = 0.5,
    this.fl_in = 1.0,
    this.fl_out = 1.0,
    this.flx = 0.5,
    this.fly = 0.5,
    this.focus = 0.0,
    this.fr_in = 1.0,
    this.fr_out = 1.0,
    this.frx = 0.5,
    this.fry = 0.5,
    this.level_in = 1.0,
    this.level_out = 1.0,
    this.lfe = true,
    this.lfe_high = 256,
    this.lfe_in = 1.0,
    this.lfe_low = 128,
    this.lfe_mode = SurroundLfeMode.add,
    this.lfe_out = 1.0,
    this.overlap = 0.5,
    this.sl_in = 1.0,
    this.sl_out = 1.0,
    this.slx = 0.5,
    this.sly = 0.5,
    this.smooth = 0.0,
    this.sr_in = 1.0,
    this.sr_out = 1.0,
    this.srx = 0.5,
    this.sry = 0.5,
    this.win_size = 4096,
  });

  SurroundSettings copyWith({
    bool? enabled,
    double? allx,
    double? ally,
    double? angle,
    double? bc_in,
    double? bc_out,
    double? bcx,
    double? bcy,
    double? bl_in,
    double? bl_out,
    double? blx,
    double? bly,
    double? br_in,
    double? br_out,
    double? brx,
    double? bry,
    String? chl_in,
    String? chl_out,
    double? fc_in,
    double? fc_out,
    double? fcx,
    double? fcy,
    double? fl_in,
    double? fl_out,
    double? flx,
    double? fly,
    double? focus,
    double? fr_in,
    double? fr_out,
    double? frx,
    double? fry,
    double? level_in,
    double? level_out,
    bool? lfe,
    int? lfe_high,
    double? lfe_in,
    int? lfe_low,
    SurroundLfeMode? lfe_mode,
    double? lfe_out,
    double? overlap,
    double? sl_in,
    double? sl_out,
    double? slx,
    double? sly,
    double? smooth,
    double? sr_in,
    double? sr_out,
    double? srx,
    double? sry,
    int? win_size,
  }) =>
      SurroundSettings(
        enabled: enabled ?? this.enabled,
        allx: allx ?? this.allx,
        ally: ally ?? this.ally,
        angle: angle ?? this.angle,
        bc_in: bc_in ?? this.bc_in,
        bc_out: bc_out ?? this.bc_out,
        bcx: bcx ?? this.bcx,
        bcy: bcy ?? this.bcy,
        bl_in: bl_in ?? this.bl_in,
        bl_out: bl_out ?? this.bl_out,
        blx: blx ?? this.blx,
        bly: bly ?? this.bly,
        br_in: br_in ?? this.br_in,
        br_out: br_out ?? this.br_out,
        brx: brx ?? this.brx,
        bry: bry ?? this.bry,
        chl_in: chl_in ?? this.chl_in,
        chl_out: chl_out ?? this.chl_out,
        fc_in: fc_in ?? this.fc_in,
        fc_out: fc_out ?? this.fc_out,
        fcx: fcx ?? this.fcx,
        fcy: fcy ?? this.fcy,
        fl_in: fl_in ?? this.fl_in,
        fl_out: fl_out ?? this.fl_out,
        flx: flx ?? this.flx,
        fly: fly ?? this.fly,
        focus: focus ?? this.focus,
        fr_in: fr_in ?? this.fr_in,
        fr_out: fr_out ?? this.fr_out,
        frx: frx ?? this.frx,
        fry: fry ?? this.fry,
        level_in: level_in ?? this.level_in,
        level_out: level_out ?? this.level_out,
        lfe: lfe ?? this.lfe,
        lfe_high: lfe_high ?? this.lfe_high,
        lfe_in: lfe_in ?? this.lfe_in,
        lfe_low: lfe_low ?? this.lfe_low,
        lfe_mode: lfe_mode ?? this.lfe_mode,
        lfe_out: lfe_out ?? this.lfe_out,
        overlap: overlap ?? this.overlap,
        sl_in: sl_in ?? this.sl_in,
        sl_out: sl_out ?? this.sl_out,
        slx: slx ?? this.slx,
        sly: sly ?? this.sly,
        smooth: smooth ?? this.smooth,
        sr_in: sr_in ?? this.sr_in,
        sr_out: sr_out ?? this.sr_out,
        srx: srx ?? this.srx,
        sry: sry ?? this.sry,
        win_size: win_size ?? this.win_size,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurroundSettings &&
          other.enabled == enabled &&
          other.allx == allx &&
          other.ally == ally &&
          other.angle == angle &&
          other.bc_in == bc_in &&
          other.bc_out == bc_out &&
          other.bcx == bcx &&
          other.bcy == bcy &&
          other.bl_in == bl_in &&
          other.bl_out == bl_out &&
          other.blx == blx &&
          other.bly == bly &&
          other.br_in == br_in &&
          other.br_out == br_out &&
          other.brx == brx &&
          other.bry == bry &&
          other.chl_in == chl_in &&
          other.chl_out == chl_out &&
          other.fc_in == fc_in &&
          other.fc_out == fc_out &&
          other.fcx == fcx &&
          other.fcy == fcy &&
          other.fl_in == fl_in &&
          other.fl_out == fl_out &&
          other.flx == flx &&
          other.fly == fly &&
          other.focus == focus &&
          other.fr_in == fr_in &&
          other.fr_out == fr_out &&
          other.frx == frx &&
          other.fry == fry &&
          other.level_in == level_in &&
          other.level_out == level_out &&
          other.lfe == lfe &&
          other.lfe_high == lfe_high &&
          other.lfe_in == lfe_in &&
          other.lfe_low == lfe_low &&
          other.lfe_mode == lfe_mode &&
          other.lfe_out == lfe_out &&
          other.overlap == overlap &&
          other.sl_in == sl_in &&
          other.sl_out == sl_out &&
          other.slx == slx &&
          other.sly == sly &&
          other.smooth == smooth &&
          other.sr_in == sr_in &&
          other.sr_out == sr_out &&
          other.srx == srx &&
          other.sry == sry &&
          other.win_size == win_size);

  @override
  int get hashCode => Object.hashAll([
        enabled,
        allx,
        ally,
        angle,
        bc_in,
        bc_out,
        bcx,
        bcy,
        bl_in,
        bl_out,
        blx,
        bly,
        br_in,
        br_out,
        brx,
        bry,
        chl_in,
        chl_out,
        fc_in,
        fc_out,
        fcx,
        fcy,
        fl_in,
        fl_out,
        flx,
        fly,
        focus,
        fr_in,
        fr_out,
        frx,
        fry,
        level_in,
        level_out,
        lfe,
        lfe_high,
        lfe_in,
        lfe_low,
        lfe_mode,
        lfe_out,
        overlap,
        sl_in,
        sl_out,
        slx,
        sly,
        smooth,
        sr_in,
        sr_out,
        srx,
        sry,
        win_size
      ]);

  @override
  String toString() =>
      'SurroundSettings(enabled: $enabled, allx: $allx, ally: $ally, angle: $angle, bc_in: $bc_in, bc_out: $bc_out, bcx: $bcx, bcy: $bcy, bl_in: $bl_in, bl_out: $bl_out, blx: $blx, bly: $bly, br_in: $br_in, br_out: $br_out, brx: $brx, bry: $bry, chl_in: $chl_in, chl_out: $chl_out, fc_in: $fc_in, fc_out: $fc_out, fcx: $fcx, fcy: $fcy, fl_in: $fl_in, fl_out: $fl_out, flx: $flx, fly: $fly, focus: $focus, fr_in: $fr_in, fr_out: $fr_out, frx: $frx, fry: $fry, level_in: $level_in, level_out: $level_out, lfe: $lfe, lfe_high: $lfe_high, lfe_in: $lfe_in, lfe_low: $lfe_low, lfe_mode: $lfe_mode, lfe_out: $lfe_out, overlap: $overlap, sl_in: $sl_in, sl_out: $sl_out, slx: $slx, sly: $sly, smooth: $smooth, sr_in: $sr_in, sr_out: $sr_out, srx: $srx, sry: $sry, win_size: $win_size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(allx >= -1, 'surround.allx must be >= -1');
    assert(allx <= 15, 'surround.allx must be <= 15');
    assert(ally >= -1, 'surround.ally must be >= -1');
    assert(ally <= 15, 'surround.ally must be <= 15');
    assert(angle >= 0, 'surround.angle must be >= 0');
    assert(angle <= 360, 'surround.angle must be <= 360');
    assert(bc_in >= 0, 'surround.bc_in must be >= 0');
    assert(bc_in <= 10, 'surround.bc_in must be <= 10');
    assert(bc_out >= 0, 'surround.bc_out must be >= 0');
    assert(bc_out <= 10, 'surround.bc_out must be <= 10');
    assert(bl_in >= 0, 'surround.bl_in must be >= 0');
    assert(bl_in <= 10, 'surround.bl_in must be <= 10');
    assert(bl_out >= 0, 'surround.bl_out must be >= 0');
    assert(bl_out <= 10, 'surround.bl_out must be <= 10');
    assert(br_in >= 0, 'surround.br_in must be >= 0');
    assert(br_in <= 10, 'surround.br_in must be <= 10');
    assert(br_out >= 0, 'surround.br_out must be >= 0');
    assert(br_out <= 10, 'surround.br_out must be <= 10');
    assert(fc_in >= 0, 'surround.fc_in must be >= 0');
    assert(fc_in <= 10, 'surround.fc_in must be <= 10');
    assert(fc_out >= 0, 'surround.fc_out must be >= 0');
    assert(fc_out <= 10, 'surround.fc_out must be <= 10');
    assert(fl_in >= 0, 'surround.fl_in must be >= 0');
    assert(fl_in <= 10, 'surround.fl_in must be <= 10');
    assert(fl_out >= 0, 'surround.fl_out must be >= 0');
    assert(fl_out <= 10, 'surround.fl_out must be <= 10');
    assert(focus >= -1, 'surround.focus must be >= -1');
    assert(focus <= 1, 'surround.focus must be <= 1');
    assert(fr_in >= 0, 'surround.fr_in must be >= 0');
    assert(fr_in <= 10, 'surround.fr_in must be <= 10');
    assert(fr_out >= 0, 'surround.fr_out must be >= 0');
    assert(fr_out <= 10, 'surround.fr_out must be <= 10');
    assert(level_in >= 0, 'surround.level_in must be >= 0');
    assert(level_in <= 10, 'surround.level_in must be <= 10');
    assert(level_out >= 0, 'surround.level_out must be >= 0');
    assert(level_out <= 10, 'surround.level_out must be <= 10');
    assert(lfe_high >= 0, 'surround.lfe_high must be >= 0');
    assert(lfe_high <= 512, 'surround.lfe_high must be <= 512');
    assert(lfe_in >= 0, 'surround.lfe_in must be >= 0');
    assert(lfe_in <= 10, 'surround.lfe_in must be <= 10');
    assert(lfe_low >= 0, 'surround.lfe_low must be >= 0');
    assert(lfe_low <= 256, 'surround.lfe_low must be <= 256');
    assert(lfe_out >= 0, 'surround.lfe_out must be >= 0');
    assert(lfe_out <= 10, 'surround.lfe_out must be <= 10');
    assert(overlap >= 0, 'surround.overlap must be >= 0');
    assert(overlap <= 1, 'surround.overlap must be <= 1');
    assert(sl_in >= 0, 'surround.sl_in must be >= 0');
    assert(sl_in <= 10, 'surround.sl_in must be <= 10');
    assert(sl_out >= 0, 'surround.sl_out must be >= 0');
    assert(sl_out <= 10, 'surround.sl_out must be <= 10');
    assert(smooth >= 0, 'surround.smooth must be >= 0');
    assert(smooth <= 1, 'surround.smooth must be <= 1');
    assert(sr_in >= 0, 'surround.sr_in must be >= 0');
    assert(sr_in <= 10, 'surround.sr_in must be <= 10');
    assert(sr_out >= 0, 'surround.sr_out must be >= 0');
    assert(sr_out <= 10, 'surround.sr_out must be <= 10');
    assert(win_size >= 1024, 'surround.win_size must be >= 1024');
    assert(win_size <= 65536, 'surround.win_size must be <= 65536');
    final parts = <String>[];
    if (allx != -1.0) parts.add('allx=' + allx.toStringAsFixed(3));
    if (ally != -1.0) parts.add('ally=' + ally.toStringAsFixed(3));
    if (angle != 90.0) parts.add('angle=' + angle.toStringAsFixed(3));
    if (bc_in != 1.0) parts.add('bc_in=' + bc_in.toStringAsFixed(3));
    if (bc_out != 1.0) parts.add('bc_out=' + bc_out.toStringAsFixed(3));
    if (bcx != 0.5) parts.add('bcx=' + bcx.toStringAsFixed(3));
    if (bcy != 0.5) parts.add('bcy=' + bcy.toStringAsFixed(3));
    if (bl_in != 1.0) parts.add('bl_in=' + bl_in.toStringAsFixed(3));
    if (bl_out != 1.0) parts.add('bl_out=' + bl_out.toStringAsFixed(3));
    if (blx != 0.5) parts.add('blx=' + blx.toStringAsFixed(3));
    if (bly != 0.5) parts.add('bly=' + bly.toStringAsFixed(3));
    if (br_in != 1.0) parts.add('br_in=' + br_in.toStringAsFixed(3));
    if (br_out != 1.0) parts.add('br_out=' + br_out.toStringAsFixed(3));
    if (brx != 0.5) parts.add('brx=' + brx.toStringAsFixed(3));
    if (bry != 0.5) parts.add('bry=' + bry.toStringAsFixed(3));
    if (chl_in != "stereo") parts.add('chl_in=' + chl_in);
    if (chl_out != "5.1") parts.add('chl_out=' + chl_out);
    if (fc_in != 1.0) parts.add('fc_in=' + fc_in.toStringAsFixed(3));
    if (fc_out != 1.0) parts.add('fc_out=' + fc_out.toStringAsFixed(3));
    if (fcx != 0.5) parts.add('fcx=' + fcx.toStringAsFixed(3));
    if (fcy != 0.5) parts.add('fcy=' + fcy.toStringAsFixed(3));
    if (fl_in != 1.0) parts.add('fl_in=' + fl_in.toStringAsFixed(3));
    if (fl_out != 1.0) parts.add('fl_out=' + fl_out.toStringAsFixed(3));
    if (flx != 0.5) parts.add('flx=' + flx.toStringAsFixed(3));
    if (fly != 0.5) parts.add('fly=' + fly.toStringAsFixed(3));
    if (focus != 0.0) parts.add('focus=' + focus.toStringAsFixed(3));
    if (fr_in != 1.0) parts.add('fr_in=' + fr_in.toStringAsFixed(3));
    if (fr_out != 1.0) parts.add('fr_out=' + fr_out.toStringAsFixed(3));
    if (frx != 0.5) parts.add('frx=' + frx.toStringAsFixed(3));
    if (fry != 0.5) parts.add('fry=' + fry.toStringAsFixed(3));
    if (level_in != 1.0) parts.add('level_in=' + level_in.toStringAsFixed(3));
    if (level_out != 1.0)
      parts.add('level_out=' + level_out.toStringAsFixed(3));
    if (lfe != true) parts.add('lfe=' + (lfe ? '1' : '0'));
    if (lfe_high != 256) parts.add('lfe_high=' + lfe_high.toString());
    if (lfe_in != 1.0) parts.add('lfe_in=' + lfe_in.toStringAsFixed(3));
    if (lfe_low != 128) parts.add('lfe_low=' + lfe_low.toString());
    if (lfe_mode != SurroundLfeMode.add)
      parts.add('lfe_mode=' + lfe_mode.mpvValue);
    if (lfe_out != 1.0) parts.add('lfe_out=' + lfe_out.toStringAsFixed(3));
    if (overlap != 0.5) parts.add('overlap=' + overlap.toStringAsFixed(3));
    if (sl_in != 1.0) parts.add('sl_in=' + sl_in.toStringAsFixed(3));
    if (sl_out != 1.0) parts.add('sl_out=' + sl_out.toStringAsFixed(3));
    if (slx != 0.5) parts.add('slx=' + slx.toStringAsFixed(3));
    if (sly != 0.5) parts.add('sly=' + sly.toStringAsFixed(3));
    if (smooth != 0.0) parts.add('smooth=' + smooth.toStringAsFixed(3));
    if (sr_in != 1.0) parts.add('sr_in=' + sr_in.toStringAsFixed(3));
    if (sr_out != 1.0) parts.add('sr_out=' + sr_out.toStringAsFixed(3));
    if (srx != 0.5) parts.add('srx=' + srx.toStringAsFixed(3));
    if (sry != 0.5) parts.add('sry=' + sry.toStringAsFixed(3));
    if (win_size != 4096) parts.add('win_size=' + win_size.toString());
    return parts.isEmpty
        ? 'lavfi-surround'
        : 'lavfi-surround=' + parts.join(':');
  }
}

/// Configuration for the `tiltshelf` audio effect.
///
/// Boost or cut the lower frequencies and cut or boost higher frequencies
/// of the audio using a two-pole shelving filter with a response similar to
/// that of a standard hi-fi's tone-controls.
/// This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [g]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class TiltshelfSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;
  final int p;
  final int poles;

  const TiltshelfSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.p = 2,
    this.poles = 2,
  });

  TiltshelfSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    int? p,
    int? poles,
  }) =>
      TiltshelfSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiltshelfSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain, p, poles);

  @override
  String toString() =>
      'TiltshelfSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'tiltshelf.f must be >= 0');
    assert(f <= 999999, 'tiltshelf.f must be <= 999999');
    assert(frequency >= 0, 'tiltshelf.frequency must be >= 0');
    assert(frequency <= 999999, 'tiltshelf.frequency must be <= 999999');
    assert(g >= -900, 'tiltshelf.g must be >= -900');
    assert(g <= 900, 'tiltshelf.g must be <= 900');
    assert(gain >= -900, 'tiltshelf.gain must be >= -900');
    assert(gain <= 900, 'tiltshelf.gain must be <= 900');
    assert(p >= 1, 'tiltshelf.p must be >= 1');
    assert(p <= 2, 'tiltshelf.p must be <= 2');
    assert(poles >= 1, 'tiltshelf.poles must be >= 1');
    assert(poles <= 2, 'tiltshelf.poles must be <= 2');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty
        ? 'lavfi-tiltshelf'
        : 'lavfi-tiltshelf=' + parts.join(':');
  }
}

/// Configuration for the `treble` audio effect.
///
/// Boost or cut treble (upper) frequencies of the audio using a two-pole
/// shelving filter with a response similar to that of a standard
/// hi-fi's tone-controls. This is also known as shelving equalisation (EQ).
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [f]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000)
/// - [g]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0)
/// - [p]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
final class TrebleSettings {
  final bool enabled;
  final double f;
  final double frequency;
  final double g;
  final double gain;
  final int p;
  final int poles;

  const TrebleSettings({
    this.enabled = false,
    this.f = 3000.0,
    this.frequency = 3000.0,
    this.g = 0.0,
    this.gain = 0.0,
    this.p = 2,
    this.poles = 2,
  });

  TrebleSettings copyWith({
    bool? enabled,
    double? f,
    double? frequency,
    double? g,
    double? gain,
    int? p,
    int? poles,
  }) =>
      TrebleSettings(
        enabled: enabled ?? this.enabled,
        f: f ?? this.f,
        frequency: frequency ?? this.frequency,
        g: g ?? this.g,
        gain: gain ?? this.gain,
        p: p ?? this.p,
        poles: poles ?? this.poles,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrebleSettings &&
          other.enabled == enabled &&
          other.f == f &&
          other.frequency == frequency &&
          other.g == g &&
          other.gain == gain &&
          other.p == p &&
          other.poles == poles);

  @override
  int get hashCode => Object.hash(enabled, f, frequency, g, gain, p, poles);

  @override
  String toString() =>
      'TrebleSettings(enabled: $enabled, f: $f, frequency: $frequency, g: $g, gain: $gain, p: $p, poles: $poles)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(f >= 0, 'treble.f must be >= 0');
    assert(f <= 999999, 'treble.f must be <= 999999');
    assert(frequency >= 0, 'treble.frequency must be >= 0');
    assert(frequency <= 999999, 'treble.frequency must be <= 999999');
    assert(g >= -900, 'treble.g must be >= -900');
    assert(g <= 900, 'treble.g must be <= 900');
    assert(gain >= -900, 'treble.gain must be >= -900');
    assert(gain <= 900, 'treble.gain must be <= 900');
    assert(p >= 1, 'treble.p must be >= 1');
    assert(p <= 2, 'treble.p must be <= 2');
    assert(poles >= 1, 'treble.poles must be >= 1');
    assert(poles <= 2, 'treble.poles must be <= 2');
    final parts = <String>[];
    if (f != 3000.0) parts.add('f=' + f.toStringAsFixed(3));
    if (frequency != 3000.0)
      parts.add('frequency=' + frequency.toStringAsFixed(3));
    if (g != 0.0) parts.add('g=' + g.toStringAsFixed(3));
    if (gain != 0.0) parts.add('gain=' + gain.toStringAsFixed(3));
    if (p != 2) parts.add('p=' + p.toString());
    if (poles != 2) parts.add('poles=' + poles.toString());
    return parts.isEmpty ? 'lavfi-treble' : 'lavfi-treble=' + parts.join(':');
  }
}

/// Configuration for the `tremolo` audio effect.
///
/// Sinusoidal amplitude modulation.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Depth of modulation as a percentage. Range is 0.0 - 1.0. Default value is 0.5. (range 0.0..1.0, default 0.5)
/// - [f]: Modulation frequency in Hertz. Modulation frequencies in the subharmonic range (20 Hz or lower) will result in a tremolo effect. This filter may also be used as a ring modulator by specifying a modulation frequency higher than 20 Hz. Range is 0.1 - 20000.0. Default value is 5.0 Hz. (range 0.1..20000.0, default 5.0)
final class TremoloSettings {
  final bool enabled;
  final double d;
  final double f;

  const TremoloSettings({
    this.enabled = false,
    this.d = 0.5,
    this.f = 5.0,
  });

  TremoloSettings copyWith({
    bool? enabled,
    double? d,
    double? f,
  }) =>
      TremoloSettings(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TremoloSettings &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'TremoloSettings(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(d >= 0.0, 'tremolo.d must be >= 0.0');
    assert(d <= 1.0, 'tremolo.d must be <= 1.0');
    assert(f >= 0.1, 'tremolo.f must be >= 0.1');
    assert(f <= 20000.0, 'tremolo.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + d.toStringAsFixed(3));
    if (f != 5.0) parts.add('f=' + f.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-tremolo' : 'lavfi-tremolo=' + parts.join(':');
  }
}

/// Configuration for the `vibrato` audio effect.
///
/// Sinusoidal phase modulation.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [d]: Depth of modulation as a percentage. Range is 0.0 - 1.0. Default value is 0.5. (range 0.00..1.0, default 0.5)
/// - [f]: Modulation frequency in Hertz. Range is 0.1 - 20000.0. Default value is 5.0 Hz. (range 0.1..20000.0, default 5.0)
final class VibratoSettings {
  final bool enabled;
  final double d;
  final double f;

  const VibratoSettings({
    this.enabled = false,
    this.d = 0.5,
    this.f = 5.0,
  });

  VibratoSettings copyWith({
    bool? enabled,
    double? d,
    double? f,
  }) =>
      VibratoSettings(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VibratoSettings &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'VibratoSettings(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(d >= 0.00, 'vibrato.d must be >= 0.00');
    assert(d <= 1.0, 'vibrato.d must be <= 1.0');
    assert(f >= 0.1, 'vibrato.f must be >= 0.1');
    assert(f <= 20000.0, 'vibrato.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + d.toStringAsFixed(3));
    if (f != 5.0) parts.add('f=' + f.toStringAsFixed(3));
    return parts.isEmpty ? 'lavfi-vibrato' : 'lavfi-vibrato=' + parts.join(':');
  }
}

/// Configuration for the `virtualbass` audio effect.
///
/// Apply audio Virtual Bass filter.
///
/// This filter accepts stereo input and produce stereo with LFE (2.1) channels output.
/// The newly produced LFE channel have enhanced virtual bass originally obtained from both stereo channels.
/// This filter outputs front left and front right channels unchanged as available in stereo input.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set the virtual bass cutoff frequency. Default value is 250 Hz. Allowed range is from 100 to 500 Hz. (range 100..500, default 250)
/// - [strength]: Set the virtual bass strength. Allowed range is from 0.5 to 3. Default value is 3. (range 0.5..3, default 3)
final class VirtualbassSettings {
  final bool enabled;
  final double cutoff;
  final double strength;

  const VirtualbassSettings({
    this.enabled = false,
    this.cutoff = 250.0,
    this.strength = 3.0,
  });

  VirtualbassSettings copyWith({
    bool? enabled,
    double? cutoff,
    double? strength,
  }) =>
      VirtualbassSettings(
        enabled: enabled ?? this.enabled,
        cutoff: cutoff ?? this.cutoff,
        strength: strength ?? this.strength,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualbassSettings &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(enabled, cutoff, strength);

  @override
  String toString() =>
      'VirtualbassSettings(enabled: $enabled, cutoff: $cutoff, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(cutoff >= 100, 'virtualbass.cutoff must be >= 100');
    assert(cutoff <= 500, 'virtualbass.cutoff must be <= 500');
    assert(strength >= 0.5, 'virtualbass.strength must be >= 0.5');
    assert(strength <= 3, 'virtualbass.strength must be <= 3');
    final parts = <String>[];
    if (cutoff != 250.0) parts.add('cutoff=' + cutoff.toStringAsFixed(3));
    if (strength != 3.0) parts.add('strength=' + strength.toStringAsFixed(3));
    return parts.isEmpty
        ? 'lavfi-virtualbass'
        : 'lavfi-virtualbass=' + parts.join(':');
  }
}

/// Configuration for the `volume` audio effect.
///
/// Adjust the input audio volume.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [eval]: Set when the volume expression is evaluated.  It accepts the following values:
/// - [precision]: This parameter represents the mathematical precision.  It determines which input sample formats will be allowed, which affects the precision of the volume scaling.
/// - [replaygain]: Choose the behaviour on encountering ReplayGain side data in input frames.
/// - [replaygain_noclip]: Prevent clipping by limiting the gain applied.  Default value for `replaygain_noclip` is 1. (range 0..1, default 1)
/// - [replaygain_preamp]: Pre-amplification gain in dB to apply to the selected replaygain gain.  Default value for `replaygain_preamp` is 0.0. (range -15.0..15.0, default 0.0)
/// - [volume]: Set audio volume expression.  Output values are clipped to the maximum value.  The output audio volume is given by the relation:  The default value for `volume` is "1.0". (default "1.0")
final class VolumeSettings {
  final bool enabled;
  final VolumeEval? eval;
  final VolumePrecision? precision;
  final VolumeReplaygain? replaygain;
  final bool replaygain_noclip;
  final double replaygain_preamp;
  final String volume;

  const VolumeSettings({
    this.enabled = false,
    this.eval,
    this.precision,
    this.replaygain,
    this.replaygain_noclip = true,
    this.replaygain_preamp = 0.0,
    this.volume = '1.0',
  });

  VolumeSettings copyWith({
    bool? enabled,
    Object? eval = _unset,
    Object? precision = _unset,
    Object? replaygain = _unset,
    bool? replaygain_noclip,
    double? replaygain_preamp,
    String? volume,
  }) =>
      VolumeSettings(
        enabled: enabled ?? this.enabled,
        eval: identical(eval, _unset) ? this.eval : eval as VolumeEval?,
        precision: identical(precision, _unset)
            ? this.precision
            : precision as VolumePrecision?,
        replaygain: identical(replaygain, _unset)
            ? this.replaygain
            : replaygain as VolumeReplaygain?,
        replaygain_noclip: replaygain_noclip ?? this.replaygain_noclip,
        replaygain_preamp: replaygain_preamp ?? this.replaygain_preamp,
        volume: volume ?? this.volume,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VolumeSettings &&
          other.enabled == enabled &&
          other.eval == eval &&
          other.precision == precision &&
          other.replaygain == replaygain &&
          other.replaygain_noclip == replaygain_noclip &&
          other.replaygain_preamp == replaygain_preamp &&
          other.volume == volume);

  @override
  int get hashCode => Object.hash(enabled, eval, precision, replaygain,
      replaygain_noclip, replaygain_preamp, volume);

  @override
  String toString() =>
      'VolumeSettings(enabled: $enabled, eval: $eval, precision: $precision, replaygain: $replaygain, replaygain_noclip: $replaygain_noclip, replaygain_preamp: $replaygain_preamp, volume: $volume)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    assert(replaygain_preamp >= -15.0,
        'volume.replaygain_preamp must be >= -15.0');
    assert(
        replaygain_preamp <= 15.0, 'volume.replaygain_preamp must be <= 15.0');
    final parts = <String>[];
    if (eval != null) parts.add('eval=' + eval!.mpvValue);
    if (precision != null) parts.add('precision=' + precision!.mpvValue);
    if (replaygain != null) parts.add('replaygain=' + replaygain!.mpvValue);
    if (replaygain_noclip != true)
      parts.add('replaygain_noclip=' + (replaygain_noclip ? '1' : '0'));
    if (replaygain_preamp != 0.0)
      parts.add('replaygain_preamp=' + replaygain_preamp.toStringAsFixed(3));
    if (volume != '1.0') parts.add('volume=' + volume);
    return parts.isEmpty ? 'lavfi-volume' : 'lavfi-volume=' + parts.join(':');
  }
}

/// Configuration for the `volumedetect` audio effect.
///
/// Detect the volume of the input video.
///
/// The filter has no parameters. It supports only 16-bit signed integer samples,
/// so the input will be converted when needed. Statistics about the volume will
/// be printed in the log when the input stream end is reached.
///
/// In particular it will show the mean volume (root mean square), maximum
/// volume (on a per-sample basis), and the beginning of a histogram of the
/// registered volume values (from the maximum value to a cumulated 1/1000 of
/// the samples).
///
/// All volumes are in decibels relative to the maximum PCM value.
///
/// Here is an excerpt of the output:
///
/// [Parsed_volumedetect_0 @ 0xa23120] max_volume: -4 dB
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_4db: 6
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_5db: 62
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_6db: 286
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_7db: 1042
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_8db: 2551
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_9db: 4609
/// [Parsed_volumedetect_0 @ 0xa23120] histogram_10db: 8409
///
/// It means that:
///
/// The mean square energy is approximately -27 dB, or 10^-2.7.
/// - The largest sample is at -4 dB, or more precisely between -4 dB and -5 dB.
/// - There are 6 samples at -4 dB, 62 at -5 dB, 286 at -6 dB, etc.
///
/// In other words, raising the volume by +4 dB does not cause any clipping,
/// raising it by +5 dB causes clipping for 6 samples, etc.
///
/// Below is a description of the currently available audio sources.
final class VolumedetectSettings {
  final bool enabled;

  const VolumedetectSettings({
    this.enabled = false,
  });

  VolumedetectSettings copyWith({
    bool? enabled,
  }) =>
      VolumedetectSettings(
        enabled: enabled ?? this.enabled,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VolumedetectSettings && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'VolumedetectSettings(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  String toFilterString() {
    return 'lavfi-volumedetect';
  }
}

/// All audio effects bundled into a single atomic configuration
/// applied via `Player.setAudioEffects` / `Player.updateAudioEffects`.
///
/// Each effect has its own `XxxSettings` field defaulting to disabled.
/// Flip `enabled: true` and tweak parameters to insert that stage in
/// the audio chain.
///
/// `custom` carries raw lavfi-style filter strings (e.g.
/// `'lavfi-aeval=val(0)|val(1)'`) emitted at the head of the chain,
/// before any typed stage. Use it for expression-based filters or
/// experimental ffmpeg filters that don't have a typed equivalent.
final class AudioEffects {
  final List<String> custom;
  final AbenchSettings abench;
  final AcompressorSettings acompressor;
  final AcontrastSettings acontrast;
  final AcopySettings acopy;
  final AcrusherSettings acrusher;
  final AcueSettings acue;
  final AdeclickSettings adeclick;
  final AdeclipSettings adeclip;
  final AdecorrelateSettings adecorrelate;
  final AdelaySettings adelay;
  final AdenormSettings adenorm;
  final AderivativeSettings aderivative;
  final AdrcSettings adrc;
  final AdynamicequalizerSettings adynamicequalizer;
  final AdynamicsmoothSettings adynamicsmooth;
  final AechoSettings aecho;
  final AemphasisSettings aemphasis;
  final AevalSettings aeval;
  final AexciterSettings aexciter;
  final AfadeSettings afade;
  final AfftdnSettings afftdn;
  final AfftfiltSettings afftfilt;
  final AformatSettings aformat;
  final AfreqshiftSettings afreqshift;
  final AfwtdnSettings afwtdn;
  final AgateSettings agate;
  final AiirSettings aiir;
  final AintegralSettings aintegral;
  final AlatencySettings alatency;
  final AlimiterSettings alimiter;
  final AllpassSettings allpass;
  final AloopSettings aloop;
  final AmetadataSettings ametadata;
  final AnequalizerSettings anequalizer;
  final AnlmdnSettings anlmdn;
  final AnullSettings anull;
  final ApadSettings apad;
  final ApermsSettings aperms;
  final AphaserSettings aphaser;
  final AphaseshiftSettings aphaseshift;
  final ApsyclipSettings apsyclip;
  final ApulsatorSettings apulsator;
  final ArealtimeSettings arealtime;
  final AresampleSettings aresample;
  final AreverseSettings areverse;
  final ArnndnSettings arnndn;
  final AsegmentSettings asegment;
  final AselectSettings aselect;
  final AsendcmdSettings asendcmd;
  final AsetnsamplesSettings asetnsamples;
  final AsetptsSettings asetpts;
  final AsetrateSettings asetrate;
  final AsettbSettings asettb;
  final AshowinfoSettings ashowinfo;
  final AsidedataSettings asidedata;
  final AsoftclipSettings asoftclip;
  final AspectralstatsSettings aspectralstats;
  final AstatsSettings astats;
  final AstreamselectSettings astreamselect;
  final AsubboostSettings asubboost;
  final AsubcutSettings asubcut;
  final AsupercutSettings asupercut;
  final AsuperpassSettings asuperpass;
  final AsuperstopSettings asuperstop;
  final AtempoSettings atempo;
  final AtiltSettings atilt;
  final AtrimSettings atrim;
  final BandpassSettings bandpass;
  final BandrejectSettings bandreject;
  final BassSettings bass;
  final BiquadSettings biquad;
  final ChannelmapSettings channelmap;
  final ChorusSettings chorus;
  final CompandSettings compand;
  final CompensationdelaySettings compensationdelay;
  final CrossfeedSettings crossfeed;
  final CrystalizerSettings crystalizer;
  final DcshiftSettings dcshift;
  final DeesserSettings deesser;
  final DialoguenhanceSettings dialoguenhance;
  final DrmeterSettings drmeter;
  final DynaudnormSettings dynaudnorm;
  final EarwaxSettings earwax;
  final Ebur128Settings ebur128;
  final EqualizerSettings equalizer;
  final ExtrastereoSettings extrastereo;
  final FirequalizerSettings firequalizer;
  final FlangerSettings flanger;
  final HaasSettings haas;
  final HdcdSettings hdcd;
  final HeadphoneSettings headphone;
  final HighpassSettings highpass;
  final HighshelfSettings highshelf;
  final LoudnormSettings loudnorm;
  final LowpassSettings lowpass;
  final LowshelfSettings lowshelf;
  final McompandSettings mcompand;
  final PanSettings pan;
  final ReplaygainSettings replaygain;
  final RubberbandSettings rubberband;
  final SilencedetectSettings silencedetect;
  final SilenceremoveSettings silenceremove;
  final SpeechnormSettings speechnorm;
  final StereotoolsSettings stereotools;
  final StereowidenSettings stereowiden;
  final SuperequalizerSettings superequalizer;
  final SurroundSettings surround;
  final TiltshelfSettings tiltshelf;
  final TrebleSettings treble;
  final TremoloSettings tremolo;
  final VibratoSettings vibrato;
  final VirtualbassSettings virtualbass;
  final VolumeSettings volume;
  final VolumedetectSettings volumedetect;

  const AudioEffects({
    this.custom = const <String>[],
    this.abench = const AbenchSettings(),
    this.acompressor = const AcompressorSettings(),
    this.acontrast = const AcontrastSettings(),
    this.acopy = const AcopySettings(),
    this.acrusher = const AcrusherSettings(),
    this.acue = const AcueSettings(),
    this.adeclick = const AdeclickSettings(),
    this.adeclip = const AdeclipSettings(),
    this.adecorrelate = const AdecorrelateSettings(),
    this.adelay = const AdelaySettings(),
    this.adenorm = const AdenormSettings(),
    this.aderivative = const AderivativeSettings(),
    this.adrc = const AdrcSettings(),
    this.adynamicequalizer = const AdynamicequalizerSettings(),
    this.adynamicsmooth = const AdynamicsmoothSettings(),
    this.aecho = const AechoSettings(),
    this.aemphasis = const AemphasisSettings(),
    this.aeval = const AevalSettings(),
    this.aexciter = const AexciterSettings(),
    this.afade = const AfadeSettings(),
    this.afftdn = const AfftdnSettings(),
    this.afftfilt = const AfftfiltSettings(),
    this.aformat = const AformatSettings(),
    this.afreqshift = const AfreqshiftSettings(),
    this.afwtdn = const AfwtdnSettings(),
    this.agate = const AgateSettings(),
    this.aiir = const AiirSettings(),
    this.aintegral = const AintegralSettings(),
    this.alatency = const AlatencySettings(),
    this.alimiter = const AlimiterSettings(),
    this.allpass = const AllpassSettings(),
    this.aloop = const AloopSettings(),
    this.ametadata = const AmetadataSettings(),
    this.anequalizer = const AnequalizerSettings(),
    this.anlmdn = const AnlmdnSettings(),
    this.anull = const AnullSettings(),
    this.apad = const ApadSettings(),
    this.aperms = const ApermsSettings(),
    this.aphaser = const AphaserSettings(),
    this.aphaseshift = const AphaseshiftSettings(),
    this.apsyclip = const ApsyclipSettings(),
    this.apulsator = const ApulsatorSettings(),
    this.arealtime = const ArealtimeSettings(),
    this.aresample = const AresampleSettings(),
    this.areverse = const AreverseSettings(),
    this.arnndn = const ArnndnSettings(),
    this.asegment = const AsegmentSettings(),
    this.aselect = const AselectSettings(),
    this.asendcmd = const AsendcmdSettings(),
    this.asetnsamples = const AsetnsamplesSettings(),
    this.asetpts = const AsetptsSettings(),
    this.asetrate = const AsetrateSettings(),
    this.asettb = const AsettbSettings(),
    this.ashowinfo = const AshowinfoSettings(),
    this.asidedata = const AsidedataSettings(),
    this.asoftclip = const AsoftclipSettings(),
    this.aspectralstats = const AspectralstatsSettings(),
    this.astats = const AstatsSettings(),
    this.astreamselect = const AstreamselectSettings(),
    this.asubboost = const AsubboostSettings(),
    this.asubcut = const AsubcutSettings(),
    this.asupercut = const AsupercutSettings(),
    this.asuperpass = const AsuperpassSettings(),
    this.asuperstop = const AsuperstopSettings(),
    this.atempo = const AtempoSettings(),
    this.atilt = const AtiltSettings(),
    this.atrim = const AtrimSettings(),
    this.bandpass = const BandpassSettings(),
    this.bandreject = const BandrejectSettings(),
    this.bass = const BassSettings(),
    this.biquad = const BiquadSettings(),
    this.channelmap = const ChannelmapSettings(),
    this.chorus = const ChorusSettings(),
    this.compand = const CompandSettings(),
    this.compensationdelay = const CompensationdelaySettings(),
    this.crossfeed = const CrossfeedSettings(),
    this.crystalizer = const CrystalizerSettings(),
    this.dcshift = const DcshiftSettings(),
    this.deesser = const DeesserSettings(),
    this.dialoguenhance = const DialoguenhanceSettings(),
    this.drmeter = const DrmeterSettings(),
    this.dynaudnorm = const DynaudnormSettings(),
    this.earwax = const EarwaxSettings(),
    this.ebur128 = const Ebur128Settings(),
    this.equalizer = const EqualizerSettings(),
    this.extrastereo = const ExtrastereoSettings(),
    this.firequalizer = const FirequalizerSettings(),
    this.flanger = const FlangerSettings(),
    this.haas = const HaasSettings(),
    this.hdcd = const HdcdSettings(),
    this.headphone = const HeadphoneSettings(),
    this.highpass = const HighpassSettings(),
    this.highshelf = const HighshelfSettings(),
    this.loudnorm = const LoudnormSettings(),
    this.lowpass = const LowpassSettings(),
    this.lowshelf = const LowshelfSettings(),
    this.mcompand = const McompandSettings(),
    this.pan = const PanSettings(),
    this.replaygain = const ReplaygainSettings(),
    this.rubberband = const RubberbandSettings(),
    this.silencedetect = const SilencedetectSettings(),
    this.silenceremove = const SilenceremoveSettings(),
    this.speechnorm = const SpeechnormSettings(),
    this.stereotools = const StereotoolsSettings(),
    this.stereowiden = const StereowidenSettings(),
    this.superequalizer = const SuperequalizerSettings(),
    this.surround = const SurroundSettings(),
    this.tiltshelf = const TiltshelfSettings(),
    this.treble = const TrebleSettings(),
    this.tremolo = const TremoloSettings(),
    this.vibrato = const VibratoSettings(),
    this.virtualbass = const VirtualbassSettings(),
    this.volume = const VolumeSettings(),
    this.volumedetect = const VolumedetectSettings(),
  });

  AudioEffects copyWith({
    List<String>? custom,
    AbenchSettings? abench,
    AcompressorSettings? acompressor,
    AcontrastSettings? acontrast,
    AcopySettings? acopy,
    AcrusherSettings? acrusher,
    AcueSettings? acue,
    AdeclickSettings? adeclick,
    AdeclipSettings? adeclip,
    AdecorrelateSettings? adecorrelate,
    AdelaySettings? adelay,
    AdenormSettings? adenorm,
    AderivativeSettings? aderivative,
    AdrcSettings? adrc,
    AdynamicequalizerSettings? adynamicequalizer,
    AdynamicsmoothSettings? adynamicsmooth,
    AechoSettings? aecho,
    AemphasisSettings? aemphasis,
    AevalSettings? aeval,
    AexciterSettings? aexciter,
    AfadeSettings? afade,
    AfftdnSettings? afftdn,
    AfftfiltSettings? afftfilt,
    AformatSettings? aformat,
    AfreqshiftSettings? afreqshift,
    AfwtdnSettings? afwtdn,
    AgateSettings? agate,
    AiirSettings? aiir,
    AintegralSettings? aintegral,
    AlatencySettings? alatency,
    AlimiterSettings? alimiter,
    AllpassSettings? allpass,
    AloopSettings? aloop,
    AmetadataSettings? ametadata,
    AnequalizerSettings? anequalizer,
    AnlmdnSettings? anlmdn,
    AnullSettings? anull,
    ApadSettings? apad,
    ApermsSettings? aperms,
    AphaserSettings? aphaser,
    AphaseshiftSettings? aphaseshift,
    ApsyclipSettings? apsyclip,
    ApulsatorSettings? apulsator,
    ArealtimeSettings? arealtime,
    AresampleSettings? aresample,
    AreverseSettings? areverse,
    ArnndnSettings? arnndn,
    AsegmentSettings? asegment,
    AselectSettings? aselect,
    AsendcmdSettings? asendcmd,
    AsetnsamplesSettings? asetnsamples,
    AsetptsSettings? asetpts,
    AsetrateSettings? asetrate,
    AsettbSettings? asettb,
    AshowinfoSettings? ashowinfo,
    AsidedataSettings? asidedata,
    AsoftclipSettings? asoftclip,
    AspectralstatsSettings? aspectralstats,
    AstatsSettings? astats,
    AstreamselectSettings? astreamselect,
    AsubboostSettings? asubboost,
    AsubcutSettings? asubcut,
    AsupercutSettings? asupercut,
    AsuperpassSettings? asuperpass,
    AsuperstopSettings? asuperstop,
    AtempoSettings? atempo,
    AtiltSettings? atilt,
    AtrimSettings? atrim,
    BandpassSettings? bandpass,
    BandrejectSettings? bandreject,
    BassSettings? bass,
    BiquadSettings? biquad,
    ChannelmapSettings? channelmap,
    ChorusSettings? chorus,
    CompandSettings? compand,
    CompensationdelaySettings? compensationdelay,
    CrossfeedSettings? crossfeed,
    CrystalizerSettings? crystalizer,
    DcshiftSettings? dcshift,
    DeesserSettings? deesser,
    DialoguenhanceSettings? dialoguenhance,
    DrmeterSettings? drmeter,
    DynaudnormSettings? dynaudnorm,
    EarwaxSettings? earwax,
    Ebur128Settings? ebur128,
    EqualizerSettings? equalizer,
    ExtrastereoSettings? extrastereo,
    FirequalizerSettings? firequalizer,
    FlangerSettings? flanger,
    HaasSettings? haas,
    HdcdSettings? hdcd,
    HeadphoneSettings? headphone,
    HighpassSettings? highpass,
    HighshelfSettings? highshelf,
    LoudnormSettings? loudnorm,
    LowpassSettings? lowpass,
    LowshelfSettings? lowshelf,
    McompandSettings? mcompand,
    PanSettings? pan,
    ReplaygainSettings? replaygain,
    RubberbandSettings? rubberband,
    SilencedetectSettings? silencedetect,
    SilenceremoveSettings? silenceremove,
    SpeechnormSettings? speechnorm,
    StereotoolsSettings? stereotools,
    StereowidenSettings? stereowiden,
    SuperequalizerSettings? superequalizer,
    SurroundSettings? surround,
    TiltshelfSettings? tiltshelf,
    TrebleSettings? treble,
    TremoloSettings? tremolo,
    VibratoSettings? vibrato,
    VirtualbassSettings? virtualbass,
    VolumeSettings? volume,
    VolumedetectSettings? volumedetect,
  }) =>
      AudioEffects(
        custom: custom ?? this.custom,
        abench: abench ?? this.abench,
        acompressor: acompressor ?? this.acompressor,
        acontrast: acontrast ?? this.acontrast,
        acopy: acopy ?? this.acopy,
        acrusher: acrusher ?? this.acrusher,
        acue: acue ?? this.acue,
        adeclick: adeclick ?? this.adeclick,
        adeclip: adeclip ?? this.adeclip,
        adecorrelate: adecorrelate ?? this.adecorrelate,
        adelay: adelay ?? this.adelay,
        adenorm: adenorm ?? this.adenorm,
        aderivative: aderivative ?? this.aderivative,
        adrc: adrc ?? this.adrc,
        adynamicequalizer: adynamicequalizer ?? this.adynamicequalizer,
        adynamicsmooth: adynamicsmooth ?? this.adynamicsmooth,
        aecho: aecho ?? this.aecho,
        aemphasis: aemphasis ?? this.aemphasis,
        aeval: aeval ?? this.aeval,
        aexciter: aexciter ?? this.aexciter,
        afade: afade ?? this.afade,
        afftdn: afftdn ?? this.afftdn,
        afftfilt: afftfilt ?? this.afftfilt,
        aformat: aformat ?? this.aformat,
        afreqshift: afreqshift ?? this.afreqshift,
        afwtdn: afwtdn ?? this.afwtdn,
        agate: agate ?? this.agate,
        aiir: aiir ?? this.aiir,
        aintegral: aintegral ?? this.aintegral,
        alatency: alatency ?? this.alatency,
        alimiter: alimiter ?? this.alimiter,
        allpass: allpass ?? this.allpass,
        aloop: aloop ?? this.aloop,
        ametadata: ametadata ?? this.ametadata,
        anequalizer: anequalizer ?? this.anequalizer,
        anlmdn: anlmdn ?? this.anlmdn,
        anull: anull ?? this.anull,
        apad: apad ?? this.apad,
        aperms: aperms ?? this.aperms,
        aphaser: aphaser ?? this.aphaser,
        aphaseshift: aphaseshift ?? this.aphaseshift,
        apsyclip: apsyclip ?? this.apsyclip,
        apulsator: apulsator ?? this.apulsator,
        arealtime: arealtime ?? this.arealtime,
        aresample: aresample ?? this.aresample,
        areverse: areverse ?? this.areverse,
        arnndn: arnndn ?? this.arnndn,
        asegment: asegment ?? this.asegment,
        aselect: aselect ?? this.aselect,
        asendcmd: asendcmd ?? this.asendcmd,
        asetnsamples: asetnsamples ?? this.asetnsamples,
        asetpts: asetpts ?? this.asetpts,
        asetrate: asetrate ?? this.asetrate,
        asettb: asettb ?? this.asettb,
        ashowinfo: ashowinfo ?? this.ashowinfo,
        asidedata: asidedata ?? this.asidedata,
        asoftclip: asoftclip ?? this.asoftclip,
        aspectralstats: aspectralstats ?? this.aspectralstats,
        astats: astats ?? this.astats,
        astreamselect: astreamselect ?? this.astreamselect,
        asubboost: asubboost ?? this.asubboost,
        asubcut: asubcut ?? this.asubcut,
        asupercut: asupercut ?? this.asupercut,
        asuperpass: asuperpass ?? this.asuperpass,
        asuperstop: asuperstop ?? this.asuperstop,
        atempo: atempo ?? this.atempo,
        atilt: atilt ?? this.atilt,
        atrim: atrim ?? this.atrim,
        bandpass: bandpass ?? this.bandpass,
        bandreject: bandreject ?? this.bandreject,
        bass: bass ?? this.bass,
        biquad: biquad ?? this.biquad,
        channelmap: channelmap ?? this.channelmap,
        chorus: chorus ?? this.chorus,
        compand: compand ?? this.compand,
        compensationdelay: compensationdelay ?? this.compensationdelay,
        crossfeed: crossfeed ?? this.crossfeed,
        crystalizer: crystalizer ?? this.crystalizer,
        dcshift: dcshift ?? this.dcshift,
        deesser: deesser ?? this.deesser,
        dialoguenhance: dialoguenhance ?? this.dialoguenhance,
        drmeter: drmeter ?? this.drmeter,
        dynaudnorm: dynaudnorm ?? this.dynaudnorm,
        earwax: earwax ?? this.earwax,
        ebur128: ebur128 ?? this.ebur128,
        equalizer: equalizer ?? this.equalizer,
        extrastereo: extrastereo ?? this.extrastereo,
        firequalizer: firequalizer ?? this.firequalizer,
        flanger: flanger ?? this.flanger,
        haas: haas ?? this.haas,
        hdcd: hdcd ?? this.hdcd,
        headphone: headphone ?? this.headphone,
        highpass: highpass ?? this.highpass,
        highshelf: highshelf ?? this.highshelf,
        loudnorm: loudnorm ?? this.loudnorm,
        lowpass: lowpass ?? this.lowpass,
        lowshelf: lowshelf ?? this.lowshelf,
        mcompand: mcompand ?? this.mcompand,
        pan: pan ?? this.pan,
        replaygain: replaygain ?? this.replaygain,
        rubberband: rubberband ?? this.rubberband,
        silencedetect: silencedetect ?? this.silencedetect,
        silenceremove: silenceremove ?? this.silenceremove,
        speechnorm: speechnorm ?? this.speechnorm,
        stereotools: stereotools ?? this.stereotools,
        stereowiden: stereowiden ?? this.stereowiden,
        superequalizer: superequalizer ?? this.superequalizer,
        surround: surround ?? this.surround,
        tiltshelf: tiltshelf ?? this.tiltshelf,
        treble: treble ?? this.treble,
        tremolo: tremolo ?? this.tremolo,
        vibrato: vibrato ?? this.vibrato,
        virtualbass: virtualbass ?? this.virtualbass,
        volume: volume ?? this.volume,
        volumedetect: volumedetect ?? this.volumedetect,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioEffects &&
          _listEq(custom, other.custom) &&
          other.abench == abench &&
          other.acompressor == acompressor &&
          other.acontrast == acontrast &&
          other.acopy == acopy &&
          other.acrusher == acrusher &&
          other.acue == acue &&
          other.adeclick == adeclick &&
          other.adeclip == adeclip &&
          other.adecorrelate == adecorrelate &&
          other.adelay == adelay &&
          other.adenorm == adenorm &&
          other.aderivative == aderivative &&
          other.adrc == adrc &&
          other.adynamicequalizer == adynamicequalizer &&
          other.adynamicsmooth == adynamicsmooth &&
          other.aecho == aecho &&
          other.aemphasis == aemphasis &&
          other.aeval == aeval &&
          other.aexciter == aexciter &&
          other.afade == afade &&
          other.afftdn == afftdn &&
          other.afftfilt == afftfilt &&
          other.aformat == aformat &&
          other.afreqshift == afreqshift &&
          other.afwtdn == afwtdn &&
          other.agate == agate &&
          other.aiir == aiir &&
          other.aintegral == aintegral &&
          other.alatency == alatency &&
          other.alimiter == alimiter &&
          other.allpass == allpass &&
          other.aloop == aloop &&
          other.ametadata == ametadata &&
          other.anequalizer == anequalizer &&
          other.anlmdn == anlmdn &&
          other.anull == anull &&
          other.apad == apad &&
          other.aperms == aperms &&
          other.aphaser == aphaser &&
          other.aphaseshift == aphaseshift &&
          other.apsyclip == apsyclip &&
          other.apulsator == apulsator &&
          other.arealtime == arealtime &&
          other.aresample == aresample &&
          other.areverse == areverse &&
          other.arnndn == arnndn &&
          other.asegment == asegment &&
          other.aselect == aselect &&
          other.asendcmd == asendcmd &&
          other.asetnsamples == asetnsamples &&
          other.asetpts == asetpts &&
          other.asetrate == asetrate &&
          other.asettb == asettb &&
          other.ashowinfo == ashowinfo &&
          other.asidedata == asidedata &&
          other.asoftclip == asoftclip &&
          other.aspectralstats == aspectralstats &&
          other.astats == astats &&
          other.astreamselect == astreamselect &&
          other.asubboost == asubboost &&
          other.asubcut == asubcut &&
          other.asupercut == asupercut &&
          other.asuperpass == asuperpass &&
          other.asuperstop == asuperstop &&
          other.atempo == atempo &&
          other.atilt == atilt &&
          other.atrim == atrim &&
          other.bandpass == bandpass &&
          other.bandreject == bandreject &&
          other.bass == bass &&
          other.biquad == biquad &&
          other.channelmap == channelmap &&
          other.chorus == chorus &&
          other.compand == compand &&
          other.compensationdelay == compensationdelay &&
          other.crossfeed == crossfeed &&
          other.crystalizer == crystalizer &&
          other.dcshift == dcshift &&
          other.deesser == deesser &&
          other.dialoguenhance == dialoguenhance &&
          other.drmeter == drmeter &&
          other.dynaudnorm == dynaudnorm &&
          other.earwax == earwax &&
          other.ebur128 == ebur128 &&
          other.equalizer == equalizer &&
          other.extrastereo == extrastereo &&
          other.firequalizer == firequalizer &&
          other.flanger == flanger &&
          other.haas == haas &&
          other.hdcd == hdcd &&
          other.headphone == headphone &&
          other.highpass == highpass &&
          other.highshelf == highshelf &&
          other.loudnorm == loudnorm &&
          other.lowpass == lowpass &&
          other.lowshelf == lowshelf &&
          other.mcompand == mcompand &&
          other.pan == pan &&
          other.replaygain == replaygain &&
          other.rubberband == rubberband &&
          other.silencedetect == silencedetect &&
          other.silenceremove == silenceremove &&
          other.speechnorm == speechnorm &&
          other.stereotools == stereotools &&
          other.stereowiden == stereowiden &&
          other.superequalizer == superequalizer &&
          other.surround == surround &&
          other.tiltshelf == tiltshelf &&
          other.treble == treble &&
          other.tremolo == tremolo &&
          other.vibrato == vibrato &&
          other.virtualbass == virtualbass &&
          other.volume == volume &&
          other.volumedetect == volumedetect);

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(custom),
        abench,
        acompressor,
        acontrast,
        acopy,
        acrusher,
        acue,
        adeclick,
        adeclip,
        adecorrelate,
        adelay,
        adenorm,
        aderivative,
        adrc,
        adynamicequalizer,
        adynamicsmooth,
        aecho,
        aemphasis,
        aeval,
        aexciter,
        afade,
        afftdn,
        afftfilt,
        aformat,
        afreqshift,
        afwtdn,
        agate,
        aiir,
        aintegral,
        alatency,
        alimiter,
        allpass,
        aloop,
        ametadata,
        anequalizer,
        anlmdn,
        anull,
        apad,
        aperms,
        aphaser,
        aphaseshift,
        apsyclip,
        apulsator,
        arealtime,
        aresample,
        areverse,
        arnndn,
        asegment,
        aselect,
        asendcmd,
        asetnsamples,
        asetpts,
        asetrate,
        asettb,
        ashowinfo,
        asidedata,
        asoftclip,
        aspectralstats,
        astats,
        astreamselect,
        asubboost,
        asubcut,
        asupercut,
        asuperpass,
        asuperstop,
        atempo,
        atilt,
        atrim,
        bandpass,
        bandreject,
        bass,
        biquad,
        channelmap,
        chorus,
        compand,
        compensationdelay,
        crossfeed,
        crystalizer,
        dcshift,
        deesser,
        dialoguenhance,
        drmeter,
        dynaudnorm,
        earwax,
        ebur128,
        equalizer,
        extrastereo,
        firequalizer,
        flanger,
        haas,
        hdcd,
        headphone,
        highpass,
        highshelf,
        loudnorm,
        lowpass,
        lowshelf,
        mcompand,
        pan,
        replaygain,
        rubberband,
        silencedetect,
        silenceremove,
        speechnorm,
        stereotools,
        stereowiden,
        superequalizer,
        surround,
        tiltshelf,
        treble,
        tremolo,
        vibrato,
        virtualbass,
        volume,
        volumedetect,
      ]);

  @override
  String toString() {
    final enabled = <String>[];
    if (abench.enabled) enabled.add('abench');
    if (acompressor.enabled) enabled.add('acompressor');
    if (acontrast.enabled) enabled.add('acontrast');
    if (acopy.enabled) enabled.add('acopy');
    if (acrusher.enabled) enabled.add('acrusher');
    if (acue.enabled) enabled.add('acue');
    if (adeclick.enabled) enabled.add('adeclick');
    if (adeclip.enabled) enabled.add('adeclip');
    if (adecorrelate.enabled) enabled.add('adecorrelate');
    if (adelay.enabled) enabled.add('adelay');
    if (adenorm.enabled) enabled.add('adenorm');
    if (aderivative.enabled) enabled.add('aderivative');
    if (adrc.enabled) enabled.add('adrc');
    if (adynamicequalizer.enabled) enabled.add('adynamicequalizer');
    if (adynamicsmooth.enabled) enabled.add('adynamicsmooth');
    if (aecho.enabled) enabled.add('aecho');
    if (aemphasis.enabled) enabled.add('aemphasis');
    if (aeval.enabled) enabled.add('aeval');
    if (aexciter.enabled) enabled.add('aexciter');
    if (afade.enabled) enabled.add('afade');
    if (afftdn.enabled) enabled.add('afftdn');
    if (afftfilt.enabled) enabled.add('afftfilt');
    if (aformat.enabled) enabled.add('aformat');
    if (afreqshift.enabled) enabled.add('afreqshift');
    if (afwtdn.enabled) enabled.add('afwtdn');
    if (agate.enabled) enabled.add('agate');
    if (aiir.enabled) enabled.add('aiir');
    if (aintegral.enabled) enabled.add('aintegral');
    if (alatency.enabled) enabled.add('alatency');
    if (alimiter.enabled) enabled.add('alimiter');
    if (allpass.enabled) enabled.add('allpass');
    if (aloop.enabled) enabled.add('aloop');
    if (ametadata.enabled) enabled.add('ametadata');
    if (anequalizer.enabled) enabled.add('anequalizer');
    if (anlmdn.enabled) enabled.add('anlmdn');
    if (anull.enabled) enabled.add('anull');
    if (apad.enabled) enabled.add('apad');
    if (aperms.enabled) enabled.add('aperms');
    if (aphaser.enabled) enabled.add('aphaser');
    if (aphaseshift.enabled) enabled.add('aphaseshift');
    if (apsyclip.enabled) enabled.add('apsyclip');
    if (apulsator.enabled) enabled.add('apulsator');
    if (arealtime.enabled) enabled.add('arealtime');
    if (aresample.enabled) enabled.add('aresample');
    if (areverse.enabled) enabled.add('areverse');
    if (arnndn.enabled) enabled.add('arnndn');
    if (asegment.enabled) enabled.add('asegment');
    if (aselect.enabled) enabled.add('aselect');
    if (asendcmd.enabled) enabled.add('asendcmd');
    if (asetnsamples.enabled) enabled.add('asetnsamples');
    if (asetpts.enabled) enabled.add('asetpts');
    if (asetrate.enabled) enabled.add('asetrate');
    if (asettb.enabled) enabled.add('asettb');
    if (ashowinfo.enabled) enabled.add('ashowinfo');
    if (asidedata.enabled) enabled.add('asidedata');
    if (asoftclip.enabled) enabled.add('asoftclip');
    if (aspectralstats.enabled) enabled.add('aspectralstats');
    if (astats.enabled) enabled.add('astats');
    if (astreamselect.enabled) enabled.add('astreamselect');
    if (asubboost.enabled) enabled.add('asubboost');
    if (asubcut.enabled) enabled.add('asubcut');
    if (asupercut.enabled) enabled.add('asupercut');
    if (asuperpass.enabled) enabled.add('asuperpass');
    if (asuperstop.enabled) enabled.add('asuperstop');
    if (atempo.enabled) enabled.add('atempo');
    if (atilt.enabled) enabled.add('atilt');
    if (atrim.enabled) enabled.add('atrim');
    if (bandpass.enabled) enabled.add('bandpass');
    if (bandreject.enabled) enabled.add('bandreject');
    if (bass.enabled) enabled.add('bass');
    if (biquad.enabled) enabled.add('biquad');
    if (channelmap.enabled) enabled.add('channelmap');
    if (chorus.enabled) enabled.add('chorus');
    if (compand.enabled) enabled.add('compand');
    if (compensationdelay.enabled) enabled.add('compensationdelay');
    if (crossfeed.enabled) enabled.add('crossfeed');
    if (crystalizer.enabled) enabled.add('crystalizer');
    if (dcshift.enabled) enabled.add('dcshift');
    if (deesser.enabled) enabled.add('deesser');
    if (dialoguenhance.enabled) enabled.add('dialoguenhance');
    if (drmeter.enabled) enabled.add('drmeter');
    if (dynaudnorm.enabled) enabled.add('dynaudnorm');
    if (earwax.enabled) enabled.add('earwax');
    if (ebur128.enabled) enabled.add('ebur128');
    if (equalizer.enabled) enabled.add('equalizer');
    if (extrastereo.enabled) enabled.add('extrastereo');
    if (firequalizer.enabled) enabled.add('firequalizer');
    if (flanger.enabled) enabled.add('flanger');
    if (haas.enabled) enabled.add('haas');
    if (hdcd.enabled) enabled.add('hdcd');
    if (headphone.enabled) enabled.add('headphone');
    if (highpass.enabled) enabled.add('highpass');
    if (highshelf.enabled) enabled.add('highshelf');
    if (loudnorm.enabled) enabled.add('loudnorm');
    if (lowpass.enabled) enabled.add('lowpass');
    if (lowshelf.enabled) enabled.add('lowshelf');
    if (mcompand.enabled) enabled.add('mcompand');
    if (pan.enabled) enabled.add('pan');
    if (replaygain.enabled) enabled.add('replaygain');
    if (rubberband.enabled) enabled.add('rubberband');
    if (silencedetect.enabled) enabled.add('silencedetect');
    if (silenceremove.enabled) enabled.add('silenceremove');
    if (speechnorm.enabled) enabled.add('speechnorm');
    if (stereotools.enabled) enabled.add('stereotools');
    if (stereowiden.enabled) enabled.add('stereowiden');
    if (superequalizer.enabled) enabled.add('superequalizer');
    if (surround.enabled) enabled.add('surround');
    if (tiltshelf.enabled) enabled.add('tiltshelf');
    if (treble.enabled) enabled.add('treble');
    if (tremolo.enabled) enabled.add('tremolo');
    if (vibrato.enabled) enabled.add('vibrato');
    if (virtualbass.enabled) enabled.add('virtualbass');
    if (volume.enabled) enabled.add('volume');
    if (volumedetect.enabled) enabled.add('volumedetect');
    return 'AudioEffects(custom: \$custom, enabled: \$enabled)';
  }

  /// Builds the audio chain string from this bundle.
  ///
  /// Returns the empty string when nothing is enabled. Raw entries
  /// from [custom] are emitted first (in declaration order), then
  /// every enabled typed stage. All entries are joined with `,`.
  String toAfChain() {
    final parts = <String>[];
    for (final raw in custom) {
      final t = raw.trim();
      if (t.isNotEmpty) parts.add(t);
    }
    if (abench.enabled) parts.add(abench.toFilterString());
    if (acompressor.enabled) parts.add(acompressor.toFilterString());
    if (acontrast.enabled) parts.add(acontrast.toFilterString());
    if (acopy.enabled) parts.add(acopy.toFilterString());
    if (acrusher.enabled) parts.add(acrusher.toFilterString());
    if (acue.enabled) parts.add(acue.toFilterString());
    if (adeclick.enabled) parts.add(adeclick.toFilterString());
    if (adeclip.enabled) parts.add(adeclip.toFilterString());
    if (adecorrelate.enabled) parts.add(adecorrelate.toFilterString());
    if (adelay.enabled) parts.add(adelay.toFilterString());
    if (adenorm.enabled) parts.add(adenorm.toFilterString());
    if (aderivative.enabled) parts.add(aderivative.toFilterString());
    if (adrc.enabled) parts.add(adrc.toFilterString());
    if (adynamicequalizer.enabled)
      parts.add(adynamicequalizer.toFilterString());
    if (adynamicsmooth.enabled) parts.add(adynamicsmooth.toFilterString());
    if (aecho.enabled) parts.add(aecho.toFilterString());
    if (aemphasis.enabled) parts.add(aemphasis.toFilterString());
    if (aeval.enabled) parts.add(aeval.toFilterString());
    if (aexciter.enabled) parts.add(aexciter.toFilterString());
    if (afade.enabled) parts.add(afade.toFilterString());
    if (afftdn.enabled) parts.add(afftdn.toFilterString());
    if (afftfilt.enabled) parts.add(afftfilt.toFilterString());
    if (aformat.enabled) parts.add(aformat.toFilterString());
    if (afreqshift.enabled) parts.add(afreqshift.toFilterString());
    if (afwtdn.enabled) parts.add(afwtdn.toFilterString());
    if (agate.enabled) parts.add(agate.toFilterString());
    if (aiir.enabled) parts.add(aiir.toFilterString());
    if (aintegral.enabled) parts.add(aintegral.toFilterString());
    if (alatency.enabled) parts.add(alatency.toFilterString());
    if (alimiter.enabled) parts.add(alimiter.toFilterString());
    if (allpass.enabled) parts.add(allpass.toFilterString());
    if (aloop.enabled) parts.add(aloop.toFilterString());
    if (ametadata.enabled) parts.add(ametadata.toFilterString());
    if (anequalizer.enabled) parts.add(anequalizer.toFilterString());
    if (anlmdn.enabled) parts.add(anlmdn.toFilterString());
    if (anull.enabled) parts.add(anull.toFilterString());
    if (apad.enabled) parts.add(apad.toFilterString());
    if (aperms.enabled) parts.add(aperms.toFilterString());
    if (aphaser.enabled) parts.add(aphaser.toFilterString());
    if (aphaseshift.enabled) parts.add(aphaseshift.toFilterString());
    if (apsyclip.enabled) parts.add(apsyclip.toFilterString());
    if (apulsator.enabled) parts.add(apulsator.toFilterString());
    if (arealtime.enabled) parts.add(arealtime.toFilterString());
    if (aresample.enabled) parts.add(aresample.toFilterString());
    if (areverse.enabled) parts.add(areverse.toFilterString());
    if (arnndn.enabled) parts.add(arnndn.toFilterString());
    if (asegment.enabled) parts.add(asegment.toFilterString());
    if (aselect.enabled) parts.add(aselect.toFilterString());
    if (asendcmd.enabled) parts.add(asendcmd.toFilterString());
    if (asetnsamples.enabled) parts.add(asetnsamples.toFilterString());
    if (asetpts.enabled) parts.add(asetpts.toFilterString());
    if (asetrate.enabled) parts.add(asetrate.toFilterString());
    if (asettb.enabled) parts.add(asettb.toFilterString());
    if (ashowinfo.enabled) parts.add(ashowinfo.toFilterString());
    if (asidedata.enabled) parts.add(asidedata.toFilterString());
    if (asoftclip.enabled) parts.add(asoftclip.toFilterString());
    if (aspectralstats.enabled) parts.add(aspectralstats.toFilterString());
    if (astats.enabled) parts.add(astats.toFilterString());
    if (astreamselect.enabled) parts.add(astreamselect.toFilterString());
    if (asubboost.enabled) parts.add(asubboost.toFilterString());
    if (asubcut.enabled) parts.add(asubcut.toFilterString());
    if (asupercut.enabled) parts.add(asupercut.toFilterString());
    if (asuperpass.enabled) parts.add(asuperpass.toFilterString());
    if (asuperstop.enabled) parts.add(asuperstop.toFilterString());
    if (atempo.enabled) parts.add(atempo.toFilterString());
    if (atilt.enabled) parts.add(atilt.toFilterString());
    if (atrim.enabled) parts.add(atrim.toFilterString());
    if (bandpass.enabled) parts.add(bandpass.toFilterString());
    if (bandreject.enabled) parts.add(bandreject.toFilterString());
    if (bass.enabled) parts.add(bass.toFilterString());
    if (biquad.enabled) parts.add(biquad.toFilterString());
    if (channelmap.enabled) parts.add(channelmap.toFilterString());
    if (chorus.enabled) parts.add(chorus.toFilterString());
    if (compand.enabled) parts.add(compand.toFilterString());
    if (compensationdelay.enabled)
      parts.add(compensationdelay.toFilterString());
    if (crossfeed.enabled) parts.add(crossfeed.toFilterString());
    if (crystalizer.enabled) parts.add(crystalizer.toFilterString());
    if (dcshift.enabled) parts.add(dcshift.toFilterString());
    if (deesser.enabled) parts.add(deesser.toFilterString());
    if (dialoguenhance.enabled) parts.add(dialoguenhance.toFilterString());
    if (drmeter.enabled) parts.add(drmeter.toFilterString());
    if (dynaudnorm.enabled) parts.add(dynaudnorm.toFilterString());
    if (earwax.enabled) parts.add(earwax.toFilterString());
    if (ebur128.enabled) parts.add(ebur128.toFilterString());
    if (equalizer.enabled) parts.add(equalizer.toFilterString());
    if (extrastereo.enabled) parts.add(extrastereo.toFilterString());
    if (firequalizer.enabled) parts.add(firequalizer.toFilterString());
    if (flanger.enabled) parts.add(flanger.toFilterString());
    if (haas.enabled) parts.add(haas.toFilterString());
    if (hdcd.enabled) parts.add(hdcd.toFilterString());
    if (headphone.enabled) parts.add(headphone.toFilterString());
    if (highpass.enabled) parts.add(highpass.toFilterString());
    if (highshelf.enabled) parts.add(highshelf.toFilterString());
    if (loudnorm.enabled) parts.add(loudnorm.toFilterString());
    if (lowpass.enabled) parts.add(lowpass.toFilterString());
    if (lowshelf.enabled) parts.add(lowshelf.toFilterString());
    if (mcompand.enabled) parts.add(mcompand.toFilterString());
    if (pan.enabled) parts.add(pan.toFilterString());
    if (replaygain.enabled) parts.add(replaygain.toFilterString());
    if (rubberband.enabled) parts.add(rubberband.toFilterString());
    if (silencedetect.enabled) parts.add(silencedetect.toFilterString());
    if (silenceremove.enabled) parts.add(silenceremove.toFilterString());
    if (speechnorm.enabled) parts.add(speechnorm.toFilterString());
    if (stereotools.enabled) parts.add(stereotools.toFilterString());
    if (stereowiden.enabled) parts.add(stereowiden.toFilterString());
    if (superequalizer.enabled) parts.add(superequalizer.toFilterString());
    if (surround.enabled) parts.add(surround.toFilterString());
    if (tiltshelf.enabled) parts.add(tiltshelf.toFilterString());
    if (treble.enabled) parts.add(treble.toFilterString());
    if (tremolo.enabled) parts.add(tremolo.toFilterString());
    if (vibrato.enabled) parts.add(vibrato.toFilterString());
    if (virtualbass.enabled) parts.add(virtualbass.toFilterString());
    if (volume.enabled) parts.add(volume.toFilterString());
    if (volumedetect.enabled) parts.add(volumedetect.toFilterString());
    return parts.join(',');
  }
}
