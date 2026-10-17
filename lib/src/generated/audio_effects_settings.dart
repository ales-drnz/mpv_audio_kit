// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license
// that can be found in the LICENSE file.
//
// AUTO-GENERATED: do not edit by hand.
// ignore_for_file: non_constant_identifier_names, constant_identifier_names, camel_case_types, curly_braces_in_flow_control_structures, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings

import 'package:meta/meta.dart';

import '../internals/unset_sentinel.dart';
import 'audio_effects.dart';

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

/// Wire-format a double for the lavfi af-chain. Uses 3-decimal
/// fixed-point when that is exact, 6 decimals when it is not (so
/// `0.0014` keeps its digits), and an exponential for tiny values
/// that would otherwise round to `0.000` (e.g. `1e-6` for
/// `asoftclip.threshold`'s minimum).
/// `toStringAsExponential()` is deterministic across runtimes
/// (Dart's `toString()` chooses between decimal and exponential
/// based on magnitude and platform), and mpv's AVOption parser
/// accepts exponential floats natively.
String _wireDouble(double v) {
  final fixed = v.toStringAsFixed(3);
  if (v == 0 || double.parse(fixed) == v) return fixed;
  if (v.abs() < 0.001) return v.toStringAsExponential();
  return v.toStringAsFixed(6);
}

/// One stage of the audio effects chain: an entry of the ordered list given
/// to `Player.setAudioEffects`. Stages run in list order, and the same
/// filter may appear more than once.
///
/// Every typed `XxxEffect` extends it; [RawAudioEffect] carries a lavfi
/// entry written by hand.
sealed class AudioEffect {
  const AudioEffect();

  /// Whether this stage is applied. `false` keeps it in the list, with
  /// its settings, without inserting it in the chain.
  bool get enabled;

  /// The lavfi filter this stage runs, e.g. `equalizer`.
  String get filterName;

  /// The filter this stage runs, as a typed identifier (`null` for a
  /// [RawAudioEffect]).
  AudioFilter? get filter;

  /// The chain entry for this stage.
  String toFilterString();

  /// Runtime-tunable option diff against [prev], the same filter one
  /// step earlier: the `(option, wire value)` pairs the live graph can
  /// apply via `af-command`, or `null` when the change needs a rebuild.
  List<(String, String)>? _runtimeDiff(covariant AudioEffect prev) =>
      this == prev ? const [] : null;
}

/// A chain stage written as a raw lavfi entry, for filters or option
/// forms the typed effects do not cover, e.g.
/// `RawAudioEffect('lavfi-aeval=val(0)*0.5|val(1)*0.5')`.
///
/// It is inserted as is, without a chain label, so it is never updated
/// live: any change rebuilds the chain.
final class RawAudioEffect extends AudioEffect {
  /// Creates a raw chain stage from [entry].
  const RawAudioEffect(this.entry, {this.enabled = true});

  /// The lavfi entry, inserted verbatim.
  final String entry;

  @override
  final bool enabled;

  @override
  String get filterName {
    final start = entry.startsWith('lavfi-') ? 'lavfi-'.length : 0;
    final end = entry.indexOf('=', start);
    return entry.substring(start, end < 0 ? entry.length : end);
  }

  @override
  AudioFilter? get filter => null;

  @override
  String toFilterString() => entry;

  /// Returns a copy with the given fields replaced.
  RawAudioEffect copyWith({String? entry, bool? enabled}) =>
      RawAudioEffect(entry ?? this.entry, enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RawAudioEffect &&
          other.entry == entry &&
          other.enabled == enabled);

  @override
  int get hashCode => Object.hash(entry, enabled);

  @override
  String toString() => 'RawAudioEffect($entry, enabled: $enabled)';
}

/// One incremental `af-command` update produced by [audioEffectsDiff]:
/// applies [option] = [value] to the live chain stage labelled [label]
/// (an instance of the ffmpeg filter [filterName]).
typedef AfCommand = ({
  String label,
  String option,
  String value,
  String filterName,
});

/// The chain label of the [instance]th [filterName] stage in a list
/// (0 for the first), e.g. `aek_equalizer_1`.
@internal
String audioEffectLabel(String filterName, int instance) =>
    'aek_${filterName}_$instance';

/// The chain labels of [effects], in order; `null` for raw stages,
/// which carry none.
@internal
List<String?> audioEffectLabels(List<AudioEffect> effects) {
  final seen = <String, int>{};
  return [
    for (final e in effects)
      if (e is RawAudioEffect)
        null
      else
        audioEffectLabel(
          e.filterName,
          seen.update(e.filterName, (i) => i + 1, ifAbsent: () => 0),
        ),
  ];
}

/// The `af` chain for [effects]: every enabled stage in list order,
/// typed stages under their [audioEffectLabels]. A blank raw stage is
/// skipped, since an empty chain entry is a syntax error for mpv.
@internal
String audioEffectsChain(List<AudioEffect> effects) {
  final labels = audioEffectLabels(effects);
  return [
    for (var i = 0; i < effects.length; i++)
      if (effects[i].enabled && effects[i].toFilterString().trim().isNotEmpty)
        labels[i] == null
            ? effects[i].toFilterString()
            : '@${labels[i]}:${effects[i].toFilterString()}',
  ].join(',');
}

/// The incremental `af-command` updates that turn the live chain built
/// from [prev] into the one for [next], or `null` when only a rebuild
/// can: a stage was added, removed, reordered, enabled or disabled, a
/// non-runtime-tunable option changed, or the filter takes no live
/// commands. Empty when the two lists build the same chain.
@internal
List<AfCommand>? audioEffectsDiff(
  List<AudioEffect> prev,
  List<AudioEffect> next,
) {
  if (prev.length != next.length) return null;
  final labels = audioEffectLabels(next);
  final out = <AfCommand>[];
  for (var i = 0; i < next.length; i++) {
    final a = prev[i];
    final b = next[i];
    if (identical(a, b)) continue;
    if (a.runtimeType != b.runtimeType || a.enabled != b.enabled) return null;
    if (b is RawAudioEffect) {
      if (a != b) return null;
      continue;
    }
    if (!b.enabled) continue;
    final d = b._runtimeDiff(a);
    if (d == null) return null;
    for (final (option, value) in d) {
      out.add((
        label: labels[i]!,
        option: option,
        value: value,
        filterName: b.filterName,
      ));
    }
  }
  return out;
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
/// - [attack]: Amount of milliseconds the signal has to rise above the threshold before gain reduction starts. Default is 20. Range is between 0.01 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [detection]: Should the exact signal be taken in case of `peak` or an RMS one in case of `rms`. Default is `rms` which is mostly smoother. (range 0..1, default 1, runtime-tunable)
/// - [knee]: Curve the sharp knee around the threshold to enter gain reduction more softly. Default is 2.82843. Range is between 1 and 8. (range 1..8, default 2.82843, runtime-tunable)
/// - [levelIn]: Set input gain. Default is 1. Range is between 0.015625 and 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelSc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the `average` level between all channels of input stream or the louder(`maximum`) channel of input stream affects the reduction. Default is `average`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set the amount by how much signal will be amplified after processing. Default is 1. Range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mix]: How much to use compressed signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [mode]: Set mode of compressor operation. Can be `upward` or `downward`. Default is `downward`. (range 0..1, default 0, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. 1:2 means that if the level rose 4dB above the threshold, it will be only 2dB above after the reduction. Default is 2. Range is between 1 and 20. (range 1..20, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before reduction is decreased again. Default is 250. Range is between 0.01 and 9000. (range 0.01..9000, default 250, runtime-tunable)
/// - [threshold]: If a signal of stream rises above this level it will affect the gain reduction. By default it is 0.125. Range is between 0.00097563 and 1. (range 0.000976563..1, default 0.125, runtime-tunable)
final class AcompressorEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.82843;

  /// Minimum value for [knee].
  static const double kneeMin = 1.0;

  /// Maximum value for [knee].
  static const double kneeMax = 8.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelSc].
  static const double levelScDefault = 1.0;

  /// Minimum value for [levelSc].
  static const double levelScMin = 0.015625;

  /// Maximum value for [levelSc].
  static const double levelScMax = 64.0;

  /// Default value for [makeup].
  static const double makeupDefault = 1.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 1.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 64.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 20.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000976563;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AcompressorDetection detection;

  /// set knee
  final double knee;

  /// set input gain
  final double levelIn;

  /// set sidechain gain
  final double levelSc;

  /// set link type
  final AcompressorLink link;

  /// set make up gain
  final double makeup;

  /// set mix
  final double mix;

  /// set mode
  final AcompressorMode mode;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AcompressorEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcompressorEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.detection = AcompressorDetection.rms,
    this.knee = 2.82843,
    this.levelIn = 1.0,
    this.levelSc = 1.0,
    this.link = AcompressorLink.average,
    this.makeup = 1.0,
    this.mix = 1.0,
    this.mode = AcompressorMode.downward,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  @override
  String get filterName => 'acompressor';

  @override
  AudioFilter get filter => AudioFilter.acompressor;

  /// Returns a copy of this [AcompressorEffect] with the given fields replaced.
  AcompressorEffect copyWith({
    bool? enabled,
    double? attack,
    AcompressorDetection? detection,
    double? knee,
    double? levelIn,
    double? levelSc,
    AcompressorLink? link,
    double? makeup,
    double? mix,
    AcompressorMode? mode,
    double? ratio,
    double? release,
    double? threshold,
  }) => AcompressorEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    detection: detection ?? this.detection,
    knee: knee ?? this.knee,
    levelIn: levelIn ?? this.levelIn,
    levelSc: levelSc ?? this.levelSc,
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
      (other is AcompressorEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.levelIn == levelIn &&
          other.levelSc == levelSc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mix == mix &&
          other.mode == mode &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    attack,
    detection,
    knee,
    levelIn,
    levelSc,
    link,
    makeup,
    mix,
    mode,
    ratio,
    release,
    threshold,
  );

  @override
  String toString() =>
      'AcompressorEffect(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, levelIn: $levelIn, levelSc: $levelSc, link: $link, makeup: $makeup, mix: $mix, mode: $mode, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'acompressor.attack must be >= 0.01');
    assert(attack <= attackMax, 'acompressor.attack must be <= 2000');
    assert(knee >= kneeMin, 'acompressor.knee must be >= 1');
    assert(knee <= kneeMax, 'acompressor.knee must be <= 8');
    assert(levelIn >= levelInMin, 'acompressor.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'acompressor.level_in must be <= 64');
    assert(levelSc >= levelScMin, 'acompressor.level_sc must be >= 0.015625');
    assert(levelSc <= levelScMax, 'acompressor.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'acompressor.makeup must be >= 1');
    assert(makeup <= makeupMax, 'acompressor.makeup must be <= 64');
    assert(mix >= mixMin, 'acompressor.mix must be >= 0');
    assert(mix <= mixMax, 'acompressor.mix must be <= 1');
    assert(ratio >= ratioMin, 'acompressor.ratio must be >= 1');
    assert(ratio <= ratioMax, 'acompressor.ratio must be <= 20');
    assert(release >= releaseMin, 'acompressor.release must be >= 0.01');
    assert(release <= releaseMax, 'acompressor.release must be <= 9000');
    assert(
      threshold >= thresholdMin,
      'acompressor.threshold must be >= 0.000976563',
    );
    assert(threshold <= thresholdMax, 'acompressor.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AcompressorDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.82843) parts.add('knee=' + _wireDouble(knee));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelSc != 1.0) parts.add('level_sc=' + _wireDouble(levelSc));
    if (link != AcompressorLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcompressorMode.downward) parts.add('mode=' + mode.mpvValue);
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-acompressor'
        : 'lavfi-acompressor=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AcompressorEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (detection != prev.detection) {
      out.add(('detection', detection.mpvValue));
    }
    if (knee != prev.knee) {
      out.add(('knee', _wireDouble(knee)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelSc != prev.levelSc) {
      out.add(('level_sc', _wireDouble(levelSc)));
    }
    if (link != prev.link) {
      out.add(('link', link.mpvValue));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
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
final class AcontrastEffect extends AudioEffect {
  /// Default value for [contrast].
  static const double contrastDefault = 33.0;

  /// Minimum value for [contrast].
  static const double contrastMin = 0.0;

  /// Maximum value for [contrast].
  static const double contrastMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set contrast
  final double contrast;

  /// Creates an [AcontrastEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcontrastEffect({this.enabled = true, this.contrast = 33.0});

  @override
  String get filterName => 'acontrast';

  @override
  AudioFilter get filter => AudioFilter.acontrast;

  /// Returns a copy of this [AcontrastEffect] with the given fields replaced.
  AcontrastEffect copyWith({bool? enabled, double? contrast}) =>
      AcontrastEffect(
        enabled: enabled ?? this.enabled,
        contrast: contrast ?? this.contrast,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AcontrastEffect &&
          other.enabled == enabled &&
          other.contrast == contrast);

  @override
  int get hashCode => Object.hash(enabled, contrast);

  @override
  String toString() =>
      'AcontrastEffect(enabled: $enabled, contrast: $contrast)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(contrast >= contrastMin, 'acontrast.contrast must be >= 0');
    assert(contrast <= contrastMax, 'acontrast.contrast must be <= 100');
    final parts = <String>[];
    if (contrast != 33.0) parts.add('contrast=' + _wireDouble(contrast));
    return parts.isEmpty
        ? 'lavfi-acontrast'
        : 'lavfi-acontrast=' + parts.join(':');
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
/// - [aa]: Set anti-aliasing. (range 0..1, default .5, runtime-tunable)
/// - [bits]: Set bit reduction. (range 1..64, default 8, runtime-tunable)
/// - [dc]: Set DC. (range .25..4, default 1, runtime-tunable)
/// - [levelIn]: Set level in. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set level out. (range 0.015625..64, default 1, runtime-tunable)
/// - [lfo]: Enable LFO. By default disabled. (range 0..1, default 0, runtime-tunable)
/// - [lforange]: Set LFO range. (range 1..250, default 20, runtime-tunable)
/// - [lforate]: Set LFO rate. (range .01..200, default .3, runtime-tunable)
/// - [mix]: Set mixing amount. (range 0..1, default .5, runtime-tunable)
/// - [mode]: Can be linear: `lin` or logarithmic: `log`. (range 0..1, default 0, runtime-tunable)
/// - [samples]: Set sample reduction. (range 1..250, default 1, runtime-tunable)
final class AcrusherEffect extends AudioEffect {
  /// Default value for [aa].
  static const double aaDefault = .5;

  /// Minimum value for [aa].
  static const double aaMin = 0.0;

  /// Maximum value for [aa].
  static const double aaMax = 1.0;

  /// Default value for [bits].
  static const double bitsDefault = 8.0;

  /// Minimum value for [bits].
  static const double bitsMin = 1.0;

  /// Maximum value for [bits].
  static const double bitsMax = 64.0;

  /// Default value for [dc].
  static const double dcDefault = 1.0;

  /// Minimum value for [dc].
  static const double dcMin = .25;

  /// Maximum value for [dc].
  static const double dcMax = 4.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [lforange].
  static const double lforangeDefault = 20.0;

  /// Minimum value for [lforange].
  static const double lforangeMin = 1.0;

  /// Maximum value for [lforange].
  static const double lforangeMax = 250.0;

  /// Default value for [lforate].
  static const double lforateDefault = .3;

  /// Minimum value for [lforate].
  static const double lforateMin = .01;

  /// Maximum value for [lforate].
  static const double lforateMax = 200.0;

  /// Default value for [mix].
  static const double mixDefault = .5;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [samples].
  static const double samplesDefault = 1.0;

  /// Minimum value for [samples].
  static const double samplesMin = 1.0;

  /// Maximum value for [samples].
  static const double samplesMax = 250.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set anti-aliasing
  final double aa;

  /// set bit reduction
  final double bits;

  /// set DC
  final double dc;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// enable LFO
  final bool lfo;

  /// set LFO depth
  final double lforange;

  /// set LFO rate
  final double lforate;

  /// set mix
  final double mix;

  /// set mode
  final AcrusherMode mode;

  /// set sample reduction
  final double samples;

  /// Creates an [AcrusherEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AcrusherEffect({
    this.enabled = true,
    this.aa = .5,
    this.bits = 8.0,
    this.dc = 1.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.lfo = false,
    this.lforange = 20.0,
    this.lforate = .3,
    this.mix = .5,
    this.mode = AcrusherMode.lin,
    this.samples = 1.0,
  });

  @override
  String get filterName => 'acrusher';

  @override
  AudioFilter get filter => AudioFilter.acrusher;

  /// Returns a copy of this [AcrusherEffect] with the given fields replaced.
  AcrusherEffect copyWith({
    bool? enabled,
    double? aa,
    double? bits,
    double? dc,
    double? levelIn,
    double? levelOut,
    bool? lfo,
    double? lforange,
    double? lforate,
    double? mix,
    AcrusherMode? mode,
    double? samples,
  }) => AcrusherEffect(
    enabled: enabled ?? this.enabled,
    aa: aa ?? this.aa,
    bits: bits ?? this.bits,
    dc: dc ?? this.dc,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
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
      (other is AcrusherEffect &&
          other.enabled == enabled &&
          other.aa == aa &&
          other.bits == bits &&
          other.dc == dc &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.lfo == lfo &&
          other.lforange == lforange &&
          other.lforate == lforate &&
          other.mix == mix &&
          other.mode == mode &&
          other.samples == samples);

  @override
  int get hashCode => Object.hash(
    enabled,
    aa,
    bits,
    dc,
    levelIn,
    levelOut,
    lfo,
    lforange,
    lforate,
    mix,
    mode,
    samples,
  );

  @override
  String toString() =>
      'AcrusherEffect(enabled: $enabled, aa: $aa, bits: $bits, dc: $dc, levelIn: $levelIn, levelOut: $levelOut, lfo: $lfo, lforange: $lforange, lforate: $lforate, mix: $mix, mode: $mode, samples: $samples)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(aa >= aaMin, 'acrusher.aa must be >= 0');
    assert(aa <= aaMax, 'acrusher.aa must be <= 1');
    assert(bits >= bitsMin, 'acrusher.bits must be >= 1');
    assert(bits <= bitsMax, 'acrusher.bits must be <= 64');
    assert(levelIn >= levelInMin, 'acrusher.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'acrusher.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'acrusher.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'acrusher.level_out must be <= 64');
    assert(lforange >= lforangeMin, 'acrusher.lforange must be >= 1');
    assert(lforange <= lforangeMax, 'acrusher.lforange must be <= 250');
    assert(lforate >= lforateMin, 'acrusher.lforate must be >= .01');
    assert(lforate <= lforateMax, 'acrusher.lforate must be <= 200');
    assert(mix >= mixMin, 'acrusher.mix must be >= 0');
    assert(mix <= mixMax, 'acrusher.mix must be <= 1');
    assert(samples >= samplesMin, 'acrusher.samples must be >= 1');
    assert(samples <= samplesMax, 'acrusher.samples must be <= 250');
    final parts = <String>[];
    if (aa != .5) parts.add('aa=' + _wireDouble(aa));
    if (bits != 8.0) parts.add('bits=' + _wireDouble(bits));
    if (dc != 1.0) parts.add('dc=' + _wireDouble(dc));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (lfo != false) parts.add('lfo=' + (lfo ? '1' : '0'));
    if (lforange != 20.0) parts.add('lforange=' + _wireDouble(lforange));
    if (lforate != .3) parts.add('lforate=' + _wireDouble(lforate));
    if (mix != .5) parts.add('mix=' + _wireDouble(mix));
    if (mode != AcrusherMode.lin) parts.add('mode=' + mode.mpvValue);
    if (samples != 1.0) parts.add('samples=' + _wireDouble(samples));
    return parts.isEmpty
        ? 'lavfi-acrusher'
        : 'lavfi-acrusher=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AcrusherEffect prev) {
    final out = <(String, String)>[];
    if (aa != prev.aa) {
      out.add(('aa', _wireDouble(aa)));
    }
    if (bits != prev.bits) {
      out.add(('bits', _wireDouble(bits)));
    }
    if (dc != prev.dc) {
      out.add(('dc', _wireDouble(dc)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (lfo != prev.lfo) {
      out.add(('lfo', (lfo ? '1' : '0')));
    }
    if (lforange != prev.lforange) {
      out.add(('lforange', _wireDouble(lforange)));
    }
    if (lforate != prev.lforate) {
      out.add(('lforate', _wireDouble(lforate)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (samples != prev.samples) {
      out.add(('samples', _wireDouble(samples)));
    }
    return out;
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
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `2` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 2)
/// - [burst]: Set burst fusion, in percentage of window size. Allowed range is `0` to `10`. Default value is `2`. If any two samples detected as noise are spaced less than this value then any sample between those two samples will be also detected as noise. (range 0..10, default 2)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. Setting this to a very high value increases impulsive noise removal but makes whole process much slower. (range 50..95, default 75)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `2`. This controls the strength of impulsive noise which is going to be removed. The lower value, the more samples will be detected as impulsive noise. (range 1..100, default 2)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclickEffect extends AudioEffect {
  /// Default value for [arorder].
  static const double arorderDefault = 2.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [burst].
  static const double burstDefault = 2.0;

  /// Minimum value for [burst].
  static const double burstMin = 0.0;

  /// Maximum value for [burst].
  static const double burstMax = 10.0;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 2.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 1.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [window].
  static const double windowDefault = 55.0;

  /// Minimum value for [window].
  static const double windowMin = 10.0;

  /// Maximum value for [window].
  static const double windowMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set autoregression order
  final double arorder;

  /// set burst fusion
  final double burst;

  /// set overlap method
  final AdeclickM method;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double threshold;

  /// set window size
  final double window;

  /// Creates an [AdeclickEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdeclickEffect({
    this.enabled = true,
    this.arorder = 2.0,
    this.burst = 2.0,
    this.method = AdeclickM.add,
    this.overlap = 75.0,
    this.threshold = 2.0,
    this.window = 55.0,
  });

  @override
  String get filterName => 'adeclick';

  @override
  AudioFilter get filter => AudioFilter.adeclick;

  /// Returns a copy of this [AdeclickEffect] with the given fields replaced.
  AdeclickEffect copyWith({
    bool? enabled,
    double? arorder,
    double? burst,
    AdeclickM? method,
    double? overlap,
    double? threshold,
    double? window,
  }) => AdeclickEffect(
    enabled: enabled ?? this.enabled,
    arorder: arorder ?? this.arorder,
    burst: burst ?? this.burst,
    method: method ?? this.method,
    overlap: overlap ?? this.overlap,
    threshold: threshold ?? this.threshold,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclickEffect &&
          other.enabled == enabled &&
          other.arorder == arorder &&
          other.burst == burst &&
          other.method == method &&
          other.overlap == overlap &&
          other.threshold == threshold &&
          other.window == window);

  @override
  int get hashCode =>
      Object.hash(enabled, arorder, burst, method, overlap, threshold, window);

  @override
  String toString() =>
      'AdeclickEffect(enabled: $enabled, arorder: $arorder, burst: $burst, method: $method, overlap: $overlap, threshold: $threshold, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(arorder >= arorderMin, 'adeclick.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclick.arorder must be <= 25');
    assert(burst >= burstMin, 'adeclick.burst must be >= 0');
    assert(burst <= burstMax, 'adeclick.burst must be <= 10');
    assert(overlap >= overlapMin, 'adeclick.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclick.overlap must be <= 95');
    assert(threshold >= thresholdMin, 'adeclick.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclick.threshold must be <= 100');
    assert(window >= windowMin, 'adeclick.window must be >= 10');
    assert(window <= windowMax, 'adeclick.window must be <= 100');
    final parts = <String>[];
    if (arorder != 2.0) parts.add('arorder=' + _wireDouble(arorder));
    if (burst != 2.0) parts.add('burst=' + _wireDouble(burst));
    if (method != AdeclickM.add) parts.add('method=' + method.mpvValue);
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (threshold != 2.0) parts.add('threshold=' + _wireDouble(threshold));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
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
/// - [arorder]: Set autoregression order, in percentage of window size. Allowed range is from `0` to `25`. Default value is `8` percent. This option also controls quality of interpolated samples using neighbour good samples. (range 0..25, default 8)
/// - [hsize]: Set size of histogram used to detect clips. Allowed range is from `100` to `9999`. Default value is `1000`. Higher values make clip detection less aggressive. (range 100..9999, default 1000)
/// - [method]: Set overlap method.  It accepts the following values: (range 0..1, default 0)
/// - [overlap]: Set window overlap, in percentage of window size. Allowed range is from `50` to `95`. Default value is `75` percent. (range 50..95, default 75)
/// - [threshold]: Set threshold value. Allowed range is from `1` to `100`. Default value is `10`. Higher values make clip detection less aggressive. (range 1..100, default 10)
/// - [window]: Set window size, in milliseconds. Allowed range is from `10` to `100`. Default value is `55` milliseconds. This sets size of window which will be processed at once. (range 10..100, default 55)
final class AdeclipEffect extends AudioEffect {
  /// Default value for [arorder].
  static const double arorderDefault = 8.0;

  /// Minimum value for [arorder].
  static const double arorderMin = 0.0;

  /// Maximum value for [arorder].
  static const double arorderMax = 25.0;

  /// Default value for [hsize].
  static const int hsizeDefault = 1000;

  /// Minimum value for [hsize].
  static const int hsizeMin = 100;

  /// Maximum value for [hsize].
  static const int hsizeMax = 9999;

  /// Default value for [overlap].
  static const double overlapDefault = 75.0;

  /// Minimum value for [overlap].
  static const double overlapMin = 50.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 95.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 10.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 1.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [window].
  static const double windowDefault = 55.0;

  /// Minimum value for [window].
  static const double windowMin = 10.0;

  /// Maximum value for [window].
  static const double windowMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set autoregression order
  final double arorder;

  /// set histogram size
  final int hsize;

  /// set overlap method
  final AdeclipM method;

  /// set window overlap
  final double overlap;

  /// set threshold
  final double threshold;

  /// set window size
  final double window;

  /// Creates an [AdeclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdeclipEffect({
    this.enabled = true,
    this.arorder = 8.0,
    this.hsize = 1000,
    this.method = AdeclipM.add,
    this.overlap = 75.0,
    this.threshold = 10.0,
    this.window = 55.0,
  });

  @override
  String get filterName => 'adeclip';

  @override
  AudioFilter get filter => AudioFilter.adeclip;

  /// Returns a copy of this [AdeclipEffect] with the given fields replaced.
  AdeclipEffect copyWith({
    bool? enabled,
    double? arorder,
    int? hsize,
    AdeclipM? method,
    double? overlap,
    double? threshold,
    double? window,
  }) => AdeclipEffect(
    enabled: enabled ?? this.enabled,
    arorder: arorder ?? this.arorder,
    hsize: hsize ?? this.hsize,
    method: method ?? this.method,
    overlap: overlap ?? this.overlap,
    threshold: threshold ?? this.threshold,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdeclipEffect &&
          other.enabled == enabled &&
          other.arorder == arorder &&
          other.hsize == hsize &&
          other.method == method &&
          other.overlap == overlap &&
          other.threshold == threshold &&
          other.window == window);

  @override
  int get hashCode =>
      Object.hash(enabled, arorder, hsize, method, overlap, threshold, window);

  @override
  String toString() =>
      'AdeclipEffect(enabled: $enabled, arorder: $arorder, hsize: $hsize, method: $method, overlap: $overlap, threshold: $threshold, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(arorder >= arorderMin, 'adeclip.arorder must be >= 0');
    assert(arorder <= arorderMax, 'adeclip.arorder must be <= 25');
    assert(hsize >= hsizeMin, 'adeclip.hsize must be >= 100');
    assert(hsize <= hsizeMax, 'adeclip.hsize must be <= 9999');
    assert(overlap >= overlapMin, 'adeclip.overlap must be >= 50');
    assert(overlap <= overlapMax, 'adeclip.overlap must be <= 95');
    assert(threshold >= thresholdMin, 'adeclip.threshold must be >= 1');
    assert(threshold <= thresholdMax, 'adeclip.threshold must be <= 100');
    assert(window >= windowMin, 'adeclip.window must be >= 10');
    assert(window <= windowMax, 'adeclip.window must be <= 100');
    final parts = <String>[];
    if (arorder != 8.0) parts.add('arorder=' + _wireDouble(arorder));
    if (hsize != 1000) parts.add('hsize=' + hsize.toString());
    if (method != AdeclipM.add) parts.add('method=' + method.mpvValue);
    if (overlap != 75.0) parts.add('overlap=' + _wireDouble(overlap));
    if (threshold != 10.0) parts.add('threshold=' + _wireDouble(threshold));
    if (window != 55.0) parts.add('window=' + _wireDouble(window));
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
/// - [seed]: Set random seed used for setting delay in samples across channels. (range -1..4294967295, default -1)
/// - [stages]: Set decorrelation stages of filtering. Allowed range is from 1 to 16. Default value is 6. (range 1..16, default 6)
final class AdecorrelateEffect extends AudioEffect {
  /// Default value for [seed].
  static const int seedDefault = -1;

  /// Minimum value for [seed].
  static const int seedMin = -1;

  /// Maximum value for [seed].
  static const int seedMax = 4294967295;

  /// Default value for [stages].
  static const int stagesDefault = 6;

  /// Minimum value for [stages].
  static const int stagesMin = 1;

  /// Maximum value for [stages].
  static const int stagesMax = 16;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set random seed
  final int seed;

  /// set filtering stages
  final int stages;

  /// Creates an [AdecorrelateEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdecorrelateEffect({
    this.enabled = true,
    this.seed = -1,
    this.stages = 6,
  });

  @override
  String get filterName => 'adecorrelate';

  @override
  AudioFilter get filter => AudioFilter.adecorrelate;

  /// Returns a copy of this [AdecorrelateEffect] with the given fields replaced.
  AdecorrelateEffect copyWith({bool? enabled, int? seed, int? stages}) =>
      AdecorrelateEffect(
        enabled: enabled ?? this.enabled,
        seed: seed ?? this.seed,
        stages: stages ?? this.stages,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdecorrelateEffect &&
          other.enabled == enabled &&
          other.seed == seed &&
          other.stages == stages);

  @override
  int get hashCode => Object.hash(enabled, seed, stages);

  @override
  String toString() =>
      'AdecorrelateEffect(enabled: $enabled, seed: $seed, stages: $stages)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(seed >= seedMin, 'adecorrelate.seed must be >= -1');
    assert(seed <= seedMax, 'adecorrelate.seed must be <= 4294967295');
    assert(stages >= stagesMin, 'adecorrelate.stages must be >= 1');
    assert(stages <= stagesMax, 'adecorrelate.stages must be <= 16');
    final parts = <String>[];
    if (seed != -1) parts.add('seed=' + seed.toString());
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
/// - [delays]: Set list of delays in milliseconds for each channel separated by '|'. Unused delays will be silently ignored. If number of given delays is smaller than number of channels all remaining channels will not be delayed. If you want to delay exact number of samples, append 'S' to number. If you want instead to delay in seconds, append 's' to number. (range 0..0, default "", runtime-tunable)
final class AdelayEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// use last available delay for remained channels
  final bool all;

  /// set list of delays for each channel
  final String delays;

  /// Creates an [AdelayEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdelayEffect({this.enabled = true, this.all = false, this.delays = ''});

  @override
  String get filterName => 'adelay';

  @override
  AudioFilter get filter => AudioFilter.adelay;

  /// Returns a copy of this [AdelayEffect] with the given fields replaced.
  AdelayEffect copyWith({bool? enabled, bool? all, String? delays}) =>
      AdelayEffect(
        enabled: enabled ?? this.enabled,
        all: all ?? this.all,
        delays: delays ?? this.delays,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdelayEffect &&
          other.enabled == enabled &&
          other.all == all &&
          other.delays == delays);

  @override
  int get hashCode => Object.hash(enabled, all, delays);

  @override
  String toString() =>
      'AdelayEffect(enabled: $enabled, all: $all, delays: $delays)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (all != false) parts.add('all=' + (all ? '1' : '0'));
    if (delays != '') parts.add('delays=' + '[' + delays + ']');
    return parts.isEmpty ? 'lavfi-adelay' : 'lavfi-adelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdelayEffect prev) {
    final out = <(String, String)>[];
    if (all != prev.all) return null;
    if (delays != prev.delays) {
      out.add(('delays', delays));
    }
    return out;
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
/// - [level]: Set level of added noise in dB. Default is `-351`. Allowed range is from -451 to -90. (range -451..-90, default -351, runtime-tunable)
/// - [type]: Set type of added noise. (range 0..3, default DC_TYPE, runtime-tunable)
final class AdenormEffect extends AudioEffect {
  /// Default value for [level].
  static const double levelDefault = -351.0;

  /// Minimum value for [level].
  static const double levelMin = -451.0;

  /// Maximum value for [level].
  static const double levelMax = -90.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set level
  final double level;

  /// set type
  final AdenormType type;

  /// Creates an [AdenormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdenormEffect({
    this.enabled = true,
    this.level = -351.0,
    this.type = AdenormType.dc,
  });

  @override
  String get filterName => 'adenorm';

  @override
  AudioFilter get filter => AudioFilter.adenorm;

  /// Returns a copy of this [AdenormEffect] with the given fields replaced.
  AdenormEffect copyWith({bool? enabled, double? level, AdenormType? type}) =>
      AdenormEffect(
        enabled: enabled ?? this.enabled,
        level: level ?? this.level,
        type: type ?? this.type,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdenormEffect &&
          other.enabled == enabled &&
          other.level == level &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, level, type);

  @override
  String toString() =>
      'AdenormEffect(enabled: $enabled, level: $level, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(level >= levelMin, 'adenorm.level must be >= -451');
    assert(level <= levelMax, 'adenorm.level must be <= -90');
    final parts = <String>[];
    if (level != -351.0) parts.add('level=' + _wireDouble(level));
    if (type != AdenormType.dc) parts.add('type=' + type.mpvValue);
    return parts.isEmpty ? 'lavfi-adenorm' : 'lavfi-adenorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdenormEffect prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `aderivative` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AderivativeEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Creates an [AderivativeEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AderivativeEffect({this.enabled = true});

  @override
  String get filterName => 'aderivative';

  @override
  AudioFilter get filter => AudioFilter.aderivative;

  /// Returns a copy of this [AderivativeEffect] with the given fields replaced.
  AderivativeEffect copyWith({bool? enabled}) =>
      AderivativeEffect(enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AderivativeEffect && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AderivativeEffect(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
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
/// - [attack]: Set the attack in milliseconds. Default is `50` milliseconds. Allowed range is from 1 to 1000 milliseconds. (range 1..1000, default 50., runtime-tunable)
/// - [channels]: Set which channels to filter, by default `all` channels in audio stream are filtered. (range 0..0, default "all", runtime-tunable)
/// - [release]: Set the release in milliseconds. Default is `100` milliseconds. Allowed range is from 5 to 2000 milliseconds. (range 5..2000, default 100., runtime-tunable)
/// - [transfer]: Set the transfer expression.  The expression can contain the following constants: (range 0..0, default "p", runtime-tunable)
final class AdrcEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 50.0;

  /// Minimum value for [attack].
  static const double attackMin = 1.0;

  /// Maximum value for [attack].
  static const double attackMax = 1000.0;

  /// Default value for [release].
  static const double releaseDefault = 100.0;

  /// Minimum value for [release].
  static const double releaseMin = 5.0;

  /// Maximum value for [release].
  static const double releaseMax = 2000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the attack
  final double attack;

  /// set channels to filter
  final String channels;

  /// set the release
  final double release;

  /// set the transfer expression
  final String transfer;

  /// Creates an [AdrcEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdrcEffect({
    this.enabled = true,
    this.attack = 50.0,
    this.channels = 'all',
    this.release = 100.0,
    this.transfer = 'p',
  });

  @override
  String get filterName => 'adrc';

  @override
  AudioFilter get filter => AudioFilter.adrc;

  /// Returns a copy of this [AdrcEffect] with the given fields replaced.
  AdrcEffect copyWith({
    bool? enabled,
    double? attack,
    String? channels,
    double? release,
    String? transfer,
  }) => AdrcEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    channels: channels ?? this.channels,
    release: release ?? this.release,
    transfer: transfer ?? this.transfer,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdrcEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.channels == channels &&
          other.release == release &&
          other.transfer == transfer);

  @override
  int get hashCode => Object.hash(enabled, attack, channels, release, transfer);

  @override
  String toString() =>
      'AdrcEffect(enabled: $enabled, attack: $attack, channels: $channels, release: $release, transfer: $transfer)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'adrc.attack must be >= 1');
    assert(attack <= attackMax, 'adrc.attack must be <= 1000');
    assert(release >= releaseMin, 'adrc.release must be >= 5');
    assert(release <= releaseMax, 'adrc.release must be <= 2000');
    final parts = <String>[];
    if (attack != 50.0) parts.add('attack=' + _wireDouble(attack));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (release != 100.0) parts.add('release=' + _wireDouble(release));
    if (transfer != 'p') parts.add('transfer=' + '[' + transfer + ']');
    return parts.isEmpty ? 'lavfi-adrc' : 'lavfi-adrc=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdrcEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (transfer != prev.transfer) {
      out.add(('transfer', transfer));
    }
    return out;
  }
}

/// Configuration for the `adynamicequalizer` audio effect.
///
/// Apply dynamic equalization to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [attack]: Set the amount of milliseconds the signal from detection has to rise above the detection threshold before equalization starts. Default is 20. Allowed range is between 1 and 2000. (range 0.01..2000, default 20, runtime-tunable)
/// - [auto]: set auto threshold (range 1..4, default DET_OFF, runtime-tunable)
/// - [dfrequency]: Set the detection frequency in Hz used for detection filter used to trigger equalization. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [dftype]: set detection filter type (range 0..3, default 0, runtime-tunable)
/// - [dqfactor]: Set the detection resonance factor for detection filter used to trigger equalization. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
/// - [makeup]: Set the makeup offset by which the equalization gain is raised. Default is 0. Allowed range is between 0 and 100. (range 0..1000, default 0, runtime-tunable)
/// - [mode]: Set the mode of filter operation, can be one of the following: (range -1..3, default 0, runtime-tunable)
/// - [precision]: set processing precision (range 0..2, default 0)
/// - [range]: Set the max allowed cut/boost amount. Default is 50. Allowed range is from 1 to 200. (range 1..2000, default 50, runtime-tunable)
/// - [ratio]: Set the ratio by which the equalization gain is raised. Default is 1. Allowed range is between 0 and 30. (range 0..30, default 1, runtime-tunable)
/// - [release]: Set the amount of milliseconds the signal from detection has to fall below the detection threshold before equalization ends. Default is 200. Allowed range is between 1 and 2000. (range 0.01..2000, default 200, runtime-tunable)
/// - [tfrequency]: Set the target frequency of equalization filter. Default value is 1000 Hz. Allowed range is between 2 and 1000000 Hz. (range 2..1000000, default 1000, runtime-tunable)
/// - [tftype]: set target filter type (range 0..2, default 0, runtime-tunable)
/// - [threshold]: Set the detection threshold used to trigger equalization. Threshold detection is using detection filter. Default value is 0. Allowed range is from 0 to 100. (range 0..100, default 0, runtime-tunable)
/// - [tqfactor]: Set the target resonance factor for target equalization filter. Default value is 1. Allowed range is from 0.001 to 1000. (range 0.001..1000, default 1, runtime-tunable)
final class AdynamicequalizerEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 2000.0;

  /// Default value for [dfrequency].
  static const double dfrequencyDefault = 1000.0;

  /// Minimum value for [dfrequency].
  static const double dfrequencyMin = 2.0;

  /// Maximum value for [dfrequency].
  static const double dfrequencyMax = 1000000.0;

  /// Default value for [dqfactor].
  static const double dqfactorDefault = 1.0;

  /// Minimum value for [dqfactor].
  static const double dqfactorMin = 0.001;

  /// Maximum value for [dqfactor].
  static const double dqfactorMax = 1000.0;

  /// Default value for [makeup].
  static const double makeupDefault = 0.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 0.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 1000.0;

  /// Default value for [range].
  static const double rangeDefault = 50.0;

  /// Minimum value for [range].
  static const double rangeMin = 1.0;

  /// Maximum value for [range].
  static const double rangeMax = 2000.0;

  /// Default value for [ratio].
  static const double ratioDefault = 1.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 0.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 30.0;

  /// Default value for [release].
  static const double releaseDefault = 200.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 2000.0;

  /// Default value for [tfrequency].
  static const double tfrequencyDefault = 1000.0;

  /// Minimum value for [tfrequency].
  static const double tfrequencyMin = 2.0;

  /// Maximum value for [tfrequency].
  static const double tfrequencyMax = 1000000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 100.0;

  /// Default value for [tqfactor].
  static const double tqfactorDefault = 1.0;

  /// Minimum value for [tqfactor].
  static const double tqfactorMin = 0.001;

  /// Maximum value for [tqfactor].
  static const double tqfactorMax = 1000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set detection attack duration
  final double attack;

  /// set auto threshold
  final AdynamicequalizerAuto auto;

  /// set detection frequency
  final double dfrequency;

  /// set detection filter type
  final AdynamicequalizerDftype dftype;

  /// set detection Q factor
  final double dqfactor;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AdynamicequalizerMode mode;

  /// set processing precision
  final AdynamicequalizerPrecision precision;

  /// set max gain
  final double range;

  /// set ratio factor
  final double ratio;

  /// set detection release duration
  final double release;

  /// set target frequency
  final double tfrequency;

  /// set target filter type
  final AdynamicequalizerTftype tftype;

  /// set detection threshold
  final double threshold;

  /// set target Q factor
  final double tqfactor;

  /// Creates an [AdynamicequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdynamicequalizerEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.auto = AdynamicequalizerAuto.off,
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

  @override
  String get filterName => 'adynamicequalizer';

  @override
  AudioFilter get filter => AudioFilter.adynamicequalizer;

  /// Returns a copy of this [AdynamicequalizerEffect] with the given fields replaced.
  AdynamicequalizerEffect copyWith({
    bool? enabled,
    double? attack,
    AdynamicequalizerAuto? auto,
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
  }) => AdynamicequalizerEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    auto: auto ?? this.auto,
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
      (other is AdynamicequalizerEffect &&
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
    tqfactor,
  );

  @override
  String toString() =>
      'AdynamicequalizerEffect(enabled: $enabled, attack: $attack, auto: $auto, dfrequency: $dfrequency, dftype: $dftype, dqfactor: $dqfactor, makeup: $makeup, mode: $mode, precision: $precision, range: $range, ratio: $ratio, release: $release, tfrequency: $tfrequency, tftype: $tftype, threshold: $threshold, tqfactor: $tqfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'adynamicequalizer.attack must be >= 0.01');
    assert(attack <= attackMax, 'adynamicequalizer.attack must be <= 2000');
    assert(
      dfrequency >= dfrequencyMin,
      'adynamicequalizer.dfrequency must be >= 2',
    );
    assert(
      dfrequency <= dfrequencyMax,
      'adynamicequalizer.dfrequency must be <= 1000000',
    );
    assert(
      dqfactor >= dqfactorMin,
      'adynamicequalizer.dqfactor must be >= 0.001',
    );
    assert(
      dqfactor <= dqfactorMax,
      'adynamicequalizer.dqfactor must be <= 1000',
    );
    assert(makeup >= makeupMin, 'adynamicequalizer.makeup must be >= 0');
    assert(makeup <= makeupMax, 'adynamicequalizer.makeup must be <= 1000');
    assert(range >= rangeMin, 'adynamicequalizer.range must be >= 1');
    assert(range <= rangeMax, 'adynamicequalizer.range must be <= 2000');
    assert(ratio >= ratioMin, 'adynamicequalizer.ratio must be >= 0');
    assert(ratio <= ratioMax, 'adynamicequalizer.ratio must be <= 30');
    assert(release >= releaseMin, 'adynamicequalizer.release must be >= 0.01');
    assert(release <= releaseMax, 'adynamicequalizer.release must be <= 2000');
    assert(
      tfrequency >= tfrequencyMin,
      'adynamicequalizer.tfrequency must be >= 2',
    );
    assert(
      tfrequency <= tfrequencyMax,
      'adynamicequalizer.tfrequency must be <= 1000000',
    );
    assert(
      threshold >= thresholdMin,
      'adynamicequalizer.threshold must be >= 0',
    );
    assert(
      threshold <= thresholdMax,
      'adynamicequalizer.threshold must be <= 100',
    );
    assert(
      tqfactor >= tqfactorMin,
      'adynamicequalizer.tqfactor must be >= 0.001',
    );
    assert(
      tqfactor <= tqfactorMax,
      'adynamicequalizer.tqfactor must be <= 1000',
    );
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (auto != AdynamicequalizerAuto.off) parts.add('auto=' + auto.mpvValue);
    if (dfrequency != 1000.0)
      parts.add('dfrequency=' + _wireDouble(dfrequency));
    if (dftype != AdynamicequalizerDftype.bandpass)
      parts.add('dftype=' + dftype.mpvValue);
    if (dqfactor != 1.0) parts.add('dqfactor=' + _wireDouble(dqfactor));
    if (makeup != 0.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AdynamicequalizerMode.listen)
      parts.add('mode=' + mode.mpvValue);
    if (precision != AdynamicequalizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (range != 50.0) parts.add('range=' + _wireDouble(range));
    if (ratio != 1.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 200.0) parts.add('release=' + _wireDouble(release));
    if (tfrequency != 1000.0)
      parts.add('tfrequency=' + _wireDouble(tfrequency));
    if (tftype != AdynamicequalizerTftype.bell)
      parts.add('tftype=' + tftype.mpvValue);
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    if (tqfactor != 1.0) parts.add('tqfactor=' + _wireDouble(tqfactor));
    return parts.isEmpty
        ? 'lavfi-adynamicequalizer'
        : 'lavfi-adynamicequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdynamicequalizerEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) {
      out.add(('attack', _wireDouble(attack)));
    }
    if (auto != prev.auto) {
      out.add(('auto', auto.mpvValue));
    }
    if (dfrequency != prev.dfrequency) {
      out.add(('dfrequency', _wireDouble(dfrequency)));
    }
    if (dftype != prev.dftype) {
      out.add(('dftype', dftype.mpvValue));
    }
    if (dqfactor != prev.dqfactor) {
      out.add(('dqfactor', _wireDouble(dqfactor)));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (precision != prev.precision) return null;
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) {
      out.add(('release', _wireDouble(release)));
    }
    if (tfrequency != prev.tfrequency) {
      out.add(('tfrequency', _wireDouble(tfrequency)));
    }
    if (tftype != prev.tftype) {
      out.add(('tftype', tftype.mpvValue));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (tqfactor != prev.tqfactor) {
      out.add(('tqfactor', _wireDouble(tqfactor)));
    }
    return out;
  }
}

/// Configuration for the `adynamicsmooth` audio effect.
///
/// Apply dynamic smoothing to input audio stream.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [basefreq]: Set a base frequency for smoothing. Default value is 22050. Allowed range is from 2 to 1e+06. (range 2..1000000, default 22050, runtime-tunable)
/// - [sensitivity]: Set an amount of sensitivity to frequency fluctations. Default is 2. Allowed range is from 0 to 1e+06. (range 0..1000000, default 2, runtime-tunable)
final class AdynamicsmoothEffect extends AudioEffect {
  /// Default value for [basefreq].
  static const double basefreqDefault = 22050.0;

  /// Minimum value for [basefreq].
  static const double basefreqMin = 2.0;

  /// Maximum value for [basefreq].
  static const double basefreqMax = 1000000.0;

  /// Default value for [sensitivity].
  static const double sensitivityDefault = 2.0;

  /// Minimum value for [sensitivity].
  static const double sensitivityMin = 0.0;

  /// Maximum value for [sensitivity].
  static const double sensitivityMax = 1000000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set base frequency
  final double basefreq;

  /// set smooth sensitivity
  final double sensitivity;

  /// Creates an [AdynamicsmoothEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AdynamicsmoothEffect({
    this.enabled = true,
    this.basefreq = 22050.0,
    this.sensitivity = 2.0,
  });

  @override
  String get filterName => 'adynamicsmooth';

  @override
  AudioFilter get filter => AudioFilter.adynamicsmooth;

  /// Returns a copy of this [AdynamicsmoothEffect] with the given fields replaced.
  AdynamicsmoothEffect copyWith({
    bool? enabled,
    double? basefreq,
    double? sensitivity,
  }) => AdynamicsmoothEffect(
    enabled: enabled ?? this.enabled,
    basefreq: basefreq ?? this.basefreq,
    sensitivity: sensitivity ?? this.sensitivity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdynamicsmoothEffect &&
          other.enabled == enabled &&
          other.basefreq == basefreq &&
          other.sensitivity == sensitivity);

  @override
  int get hashCode => Object.hash(enabled, basefreq, sensitivity);

  @override
  String toString() =>
      'AdynamicsmoothEffect(enabled: $enabled, basefreq: $basefreq, sensitivity: $sensitivity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(basefreq >= basefreqMin, 'adynamicsmooth.basefreq must be >= 2');
    assert(
      basefreq <= basefreqMax,
      'adynamicsmooth.basefreq must be <= 1000000',
    );
    assert(
      sensitivity >= sensitivityMin,
      'adynamicsmooth.sensitivity must be >= 0',
    );
    assert(
      sensitivity <= sensitivityMax,
      'adynamicsmooth.sensitivity must be <= 1000000',
    );
    final parts = <String>[];
    if (basefreq != 22050.0) parts.add('basefreq=' + _wireDouble(basefreq));
    if (sensitivity != 2.0)
      parts.add('sensitivity=' + _wireDouble(sensitivity));
    return parts.isEmpty
        ? 'lavfi-adynamicsmooth'
        : 'lavfi-adynamicsmooth=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AdynamicsmoothEffect prev) {
    final out = <(String, String)>[];
    if (basefreq != prev.basefreq) {
      out.add(('basefreq', _wireDouble(basefreq)));
    }
    if (sensitivity != prev.sensitivity) {
      out.add(('sensitivity', _wireDouble(sensitivity)));
    }
    return out;
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
/// - [inGain]: Set input gain of reflected signal. Default is `0.6`. (range 0..1, default 0.6)
/// - [outGain]: Set output gain of reflected signal. Default is `0.3`. (range 0..1, default 0.3)
final class AechoEffect extends AudioEffect {
  /// Default value for [inGain].
  static const double inGainDefault = 0.6;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = 0.3;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set list of signal decays
  final String decays;

  /// set list of signal delays
  final String delays;

  /// set signal input gain
  final double inGain;

  /// set signal output gain
  final double outGain;

  /// Creates an [AechoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AechoEffect({
    this.enabled = true,
    this.decays = '0.5',
    this.delays = '1000',
    this.inGain = 0.6,
    this.outGain = 0.3,
  });

  @override
  String get filterName => 'aecho';

  @override
  AudioFilter get filter => AudioFilter.aecho;

  /// Returns a copy of this [AechoEffect] with the given fields replaced.
  AechoEffect copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    double? inGain,
    double? outGain,
  }) => AechoEffect(
    enabled: enabled ?? this.enabled,
    decays: decays ?? this.decays,
    delays: delays ?? this.delays,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AechoEffect &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.inGain == inGain &&
          other.outGain == outGain);

  @override
  int get hashCode => Object.hash(enabled, decays, delays, inGain, outGain);

  @override
  String toString() =>
      'AechoEffect(enabled: $enabled, decays: $decays, delays: $delays, inGain: $inGain, outGain: $outGain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(inGain >= inGainMin, 'aecho.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'aecho.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'aecho.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'aecho.out_gain must be <= 1');
    final parts = <String>[];
    if (decays != '0.5') parts.add('decays=' + '[' + decays + ']');
    if (delays != '1000') parts.add('delays=' + '[' + delays + ']');
    if (inGain != 0.6) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != 0.3) parts.add('out_gain=' + _wireDouble(outGain));
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
/// - [levelIn]: Set input gain. (range 0..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. (range 0..64, default 1, runtime-tunable)
/// - [mode]: Set filter mode. For restoring material use `reproduction` mode, otherwise use `production` mode. Default is `reproduction` mode. (range 0..1, default 0, runtime-tunable)
/// - [type]: Set filter type. Selects medium. Can be one of the following: (range 0..8, default 4, runtime-tunable)
final class AemphasisEffect extends AudioEffect {
  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set input gain
  final double levelIn;

  /// set output gain
  final double levelOut;

  /// set filter mode
  final AemphasisMode mode;

  /// set filter type
  final AemphasisType type;

  /// Creates an [AemphasisEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AemphasisEffect({
    this.enabled = true,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mode = AemphasisMode.reproduction,
    this.type = AemphasisType.cd,
  });

  @override
  String get filterName => 'aemphasis';

  @override
  AudioFilter get filter => AudioFilter.aemphasis;

  /// Returns a copy of this [AemphasisEffect] with the given fields replaced.
  AemphasisEffect copyWith({
    bool? enabled,
    double? levelIn,
    double? levelOut,
    AemphasisMode? mode,
    AemphasisType? type,
  }) => AemphasisEffect(
    enabled: enabled ?? this.enabled,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    mode: mode ?? this.mode,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AemphasisEffect &&
          other.enabled == enabled &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.mode == mode &&
          other.type == type);

  @override
  int get hashCode => Object.hash(enabled, levelIn, levelOut, mode, type);

  @override
  String toString() =>
      'AemphasisEffect(enabled: $enabled, levelIn: $levelIn, levelOut: $levelOut, mode: $mode, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(levelIn >= levelInMin, 'aemphasis.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'aemphasis.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'aemphasis.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'aemphasis.level_out must be <= 64');
    final parts = <String>[];
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mode != AemphasisMode.reproduction) parts.add('mode=' + mode.mpvValue);
    if (type != AemphasisType.cd) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-aemphasis'
        : 'lavfi-aemphasis=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AemphasisEffect prev) {
    final out = <(String, String)>[];
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
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
///
/// Parameters:
/// - [channelLayout]: Set output channel layout. If not specified, the channel layout is specified by the number of expressions. If set to `same`, it will use by default the same input channel layout. (range 0..0, default "")
/// - [exprs]: Set the '|'-separated expressions list for each separate channel. If the number of input channels is greater than the number of expressions, the last specified expression is used for the remaining output channels. (default "")
final class AevalEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channel layout
  final String channelLayout;

  /// set the '|'-separated list of channels expressions
  final String exprs;

  /// Creates an [AevalEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AevalEffect({
    this.enabled = true,
    this.channelLayout = '',
    required this.exprs,
  });

  @override
  String get filterName => 'aeval';

  @override
  AudioFilter get filter => AudioFilter.aeval;

  /// Returns a copy of this [AevalEffect] with the given fields replaced.
  AevalEffect copyWith({bool? enabled, String? channelLayout, String? exprs}) =>
      AevalEffect(
        enabled: enabled ?? this.enabled,
        channelLayout: channelLayout ?? this.channelLayout,
        exprs: exprs ?? this.exprs,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AevalEffect &&
          other.enabled == enabled &&
          other.channelLayout == channelLayout &&
          other.exprs == exprs);

  @override
  int get hashCode => Object.hash(enabled, channelLayout, exprs);

  @override
  String toString() =>
      'AevalEffect(enabled: $enabled, channelLayout: $channelLayout, exprs: $exprs)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayout != '')
      parts.add('channel_layout=' + '[' + channelLayout + ']');
    parts.add('exprs=' + '[' + exprs + ']');
    return parts.isEmpty ? 'lavfi-aeval' : 'lavfi-aeval=' + parts.join(':');
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
/// - [amount]: Set the amount of harmonics added to original signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [blend]: Set the octave of newly created harmonics. Allowed range is from -10 to 10. Default value is 0. (range -10..10, default 0, runtime-tunable)
/// - [ceil]: Set the upper frequency limit of producing harmonics. Allowed range is from 9999 to 20000 Hz. If value is lower than 10000 Hz no limit is applied. (range 9999..20000, default 9999, runtime-tunable)
/// - [drive]: Set the amount of newly created harmonics. Allowed range is from 0.1 to 10. Default value is 8.5. (range 0.1..10, default 8.5, runtime-tunable)
/// - [freq]: Set the lower frequency limit of producing harmonics in Hz. Allowed range is from 2000 to 12000 Hz. Default is 7500 Hz. (range 2000..12000, default 7500, runtime-tunable)
/// - [levelIn]: Set input level prior processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [levelOut]: Set output level after processing of signal. Allowed range is from 0 to 64. Default value is 1. (range 0..64, default 1, runtime-tunable)
/// - [listen]: Mute the original signal and output only added harmonics. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AexciterEffect extends AudioEffect {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 64.0;

  /// Default value for [blend].
  static const double blendDefault = 0.0;

  /// Minimum value for [blend].
  static const double blendMin = -10.0;

  /// Maximum value for [blend].
  static const double blendMax = 10.0;

  /// Default value for [ceil].
  static const double ceilDefault = 9999.0;

  /// Minimum value for [ceil].
  static const double ceilMin = 9999.0;

  /// Maximum value for [ceil].
  static const double ceilMax = 20000.0;

  /// Default value for [drive].
  static const double driveDefault = 8.5;

  /// Minimum value for [drive].
  static const double driveMin = 0.1;

  /// Maximum value for [drive].
  static const double driveMax = 10.0;

  /// Default value for [freq].
  static const double freqDefault = 7500.0;

  /// Minimum value for [freq].
  static const double freqMin = 2000.0;

  /// Maximum value for [freq].
  static const double freqMax = 12000.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set amount
  final double amount;

  /// set blend harmonics
  final double blend;

  /// set ceiling
  final double ceil;

  /// set harmonics
  final double drive;

  /// set scope
  final double freq;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// enable listen mode
  final bool listen;

  /// Creates an [AexciterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AexciterEffect({
    this.enabled = true,
    this.amount = 1.0,
    this.blend = 0.0,
    this.ceil = 9999.0,
    this.drive = 8.5,
    this.freq = 7500.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.listen = false,
  });

  @override
  String get filterName => 'aexciter';

  @override
  AudioFilter get filter => AudioFilter.aexciter;

  /// Returns a copy of this [AexciterEffect] with the given fields replaced.
  AexciterEffect copyWith({
    bool? enabled,
    double? amount,
    double? blend,
    double? ceil,
    double? drive,
    double? freq,
    double? levelIn,
    double? levelOut,
    bool? listen,
  }) => AexciterEffect(
    enabled: enabled ?? this.enabled,
    amount: amount ?? this.amount,
    blend: blend ?? this.blend,
    ceil: ceil ?? this.ceil,
    drive: drive ?? this.drive,
    freq: freq ?? this.freq,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    listen: listen ?? this.listen,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AexciterEffect &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.blend == blend &&
          other.ceil == ceil &&
          other.drive == drive &&
          other.freq == freq &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.listen == listen);

  @override
  int get hashCode => Object.hash(
    enabled,
    amount,
    blend,
    ceil,
    drive,
    freq,
    levelIn,
    levelOut,
    listen,
  );

  @override
  String toString() =>
      'AexciterEffect(enabled: $enabled, amount: $amount, blend: $blend, ceil: $ceil, drive: $drive, freq: $freq, levelIn: $levelIn, levelOut: $levelOut, listen: $listen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(amount >= amountMin, 'aexciter.amount must be >= 0');
    assert(amount <= amountMax, 'aexciter.amount must be <= 64');
    assert(blend >= blendMin, 'aexciter.blend must be >= -10');
    assert(blend <= blendMax, 'aexciter.blend must be <= 10');
    assert(ceil >= ceilMin, 'aexciter.ceil must be >= 9999');
    assert(ceil <= ceilMax, 'aexciter.ceil must be <= 20000');
    assert(drive >= driveMin, 'aexciter.drive must be >= 0.1');
    assert(drive <= driveMax, 'aexciter.drive must be <= 10');
    assert(freq >= freqMin, 'aexciter.freq must be >= 2000');
    assert(freq <= freqMax, 'aexciter.freq must be <= 12000');
    assert(levelIn >= levelInMin, 'aexciter.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'aexciter.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'aexciter.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'aexciter.level_out must be <= 64');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (blend != 0.0) parts.add('blend=' + _wireDouble(blend));
    if (ceil != 9999.0) parts.add('ceil=' + _wireDouble(ceil));
    if (drive != 8.5) parts.add('drive=' + _wireDouble(drive));
    if (freq != 7500.0) parts.add('freq=' + _wireDouble(freq));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (listen != false) parts.add('listen=' + (listen ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-aexciter'
        : 'lavfi-aexciter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AexciterEffect prev) {
    final out = <(String, String)>[];
    if (amount != prev.amount) {
      out.add(('amount', _wireDouble(amount)));
    }
    if (blend != prev.blend) {
      out.add(('blend', _wireDouble(blend)));
    }
    if (ceil != prev.ceil) {
      out.add(('ceil', _wireDouble(ceil)));
    }
    if (drive != prev.drive) {
      out.add(('drive', _wireDouble(drive)));
    }
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (listen != prev.listen) {
      out.add(('listen', (listen ? '1' : '0')));
    }
    return out;
  }
}

/// Configuration for the `afade` audio effect.
///
/// Apply fade-in/out effect to input audio.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [curve]: Set curve for fade transition.  It accepts the following values: (range -1..22, default TRI, runtime-tunable)
/// - [duration]: Specify the duration of the fade effect. See time duration syntax for the accepted syntax. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. By default the duration is determined by `nb_samples`. If set this option is used instead of `nb_samples`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [nbSamples]: Specify the number of samples for which the fade effect has to last. At the end of the fade-in effect the output audio will have the same volume as the input audio, at the end of the fade-out transition the output audio will be silence. Default is 44100. (range 1..9223372036854775807, default 44100, runtime-tunable)
/// - [silence]: Set the initial gain for fade-in or final gain for fade-out. Default value is `0.0`. (range 0..1, default 0, runtime-tunable)
/// - [startSample]: Specify the number of the start sample for starting to apply the fade effect. Default is 0. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [startTime]: Specify the start time of the fade effect. Default is 0. The value must be specified as a time duration; see time duration syntax for the accepted syntax. If set this option is used instead of `start_sample`. (range 0..9223372036854775807, default 0, runtime-tunable)
/// - [type]: Specify the effect type, can be either `in` for fade-in, or `out` for a fade-out effect. Default is `in`. (range 0..1, default 0, runtime-tunable)
/// - [unity]: Set the initial gain for fade-out or final gain for fade-in. Default value is `1.0`. (range 0..1, default 1, runtime-tunable)
final class AfadeEffect extends AudioEffect {
  /// Default value for [nbSamples].
  static const int nbSamplesDefault = 44100;

  /// Minimum value for [nbSamples].
  static const int nbSamplesMin = 1;

  /// Maximum value for [nbSamples].
  static const int nbSamplesMax = 9223372036854775807;

  /// Default value for [silence].
  static const double silenceDefault = 0.0;

  /// Minimum value for [silence].
  static const double silenceMin = 0.0;

  /// Maximum value for [silence].
  static const double silenceMax = 1.0;

  /// Default value for [startSample].
  static const int startSampleDefault = 0;

  /// Minimum value for [startSample].
  static const int startSampleMin = 0;

  /// Maximum value for [startSample].
  static const int startSampleMax = 9223372036854775807;

  /// Default value for [unity].
  static const double unityDefault = 1.0;

  /// Minimum value for [unity].
  static const double unityMin = 0.0;

  /// Maximum value for [unity].
  static const double unityMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set fade curve type
  final AfadeCurve curve;

  /// set fade duration
  final Duration duration;

  /// set number of samples for fade duration
  final int nbSamples;

  /// set the silence gain
  final double silence;

  /// set number of first sample to start fading
  final int startSample;

  /// set time to start fading
  final Duration startTime;

  /// set the fade direction
  final AfadeType type;

  /// set the unity gain
  final double unity;

  /// Creates an [AfadeEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfadeEffect({
    this.enabled = true,
    this.curve = AfadeCurve.tri,
    this.duration = Duration.zero,
    this.nbSamples = 44100,
    this.silence = 0.0,
    this.startSample = 0,
    this.startTime = Duration.zero,
    this.type = AfadeType.in_,
    this.unity = 1.0,
  });

  @override
  String get filterName => 'afade';

  @override
  AudioFilter get filter => AudioFilter.afade;

  /// Returns a copy of this [AfadeEffect] with the given fields replaced.
  AfadeEffect copyWith({
    bool? enabled,
    AfadeCurve? curve,
    Duration? duration,
    int? nbSamples,
    double? silence,
    int? startSample,
    Duration? startTime,
    AfadeType? type,
    double? unity,
  }) => AfadeEffect(
    enabled: enabled ?? this.enabled,
    curve: curve ?? this.curve,
    duration: duration ?? this.duration,
    nbSamples: nbSamples ?? this.nbSamples,
    silence: silence ?? this.silence,
    startSample: startSample ?? this.startSample,
    startTime: startTime ?? this.startTime,
    type: type ?? this.type,
    unity: unity ?? this.unity,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfadeEffect &&
          other.enabled == enabled &&
          other.curve == curve &&
          other.duration == duration &&
          other.nbSamples == nbSamples &&
          other.silence == silence &&
          other.startSample == startSample &&
          other.startTime == startTime &&
          other.type == type &&
          other.unity == unity);

  @override
  int get hashCode => Object.hash(
    enabled,
    curve,
    duration,
    nbSamples,
    silence,
    startSample,
    startTime,
    type,
    unity,
  );

  @override
  String toString() =>
      'AfadeEffect(enabled: $enabled, curve: $curve, duration: $duration, nbSamples: $nbSamples, silence: $silence, startSample: $startSample, startTime: $startTime, type: $type, unity: $unity)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(nbSamples >= nbSamplesMin, 'afade.nb_samples must be >= 1');
    assert(
      nbSamples <= nbSamplesMax,
      'afade.nb_samples must be <= 9223372036854775807',
    );
    assert(silence >= silenceMin, 'afade.silence must be >= 0');
    assert(silence <= silenceMax, 'afade.silence must be <= 1');
    assert(startSample >= startSampleMin, 'afade.start_sample must be >= 0');
    assert(
      startSample <= startSampleMax,
      'afade.start_sample must be <= 9223372036854775807',
    );
    assert(unity >= unityMin, 'afade.unity must be >= 0');
    assert(unity <= unityMax, 'afade.unity must be <= 1');
    final parts = <String>[];
    if (curve != AfadeCurve.tri) parts.add('curve=' + curve.mpvValue);
    if (duration != Duration.zero)
      parts.add('duration=' + _wireDouble(duration.inMicroseconds / 1e6));
    if (nbSamples != 44100) parts.add('nb_samples=' + nbSamples.toString());
    if (silence != 0.0) parts.add('silence=' + _wireDouble(silence));
    if (startSample != 0) parts.add('start_sample=' + startSample.toString());
    if (startTime != Duration.zero)
      parts.add('start_time=' + _wireDouble(startTime.inMicroseconds / 1e6));
    if (type != AfadeType.in_) parts.add('type=' + type.mpvValue);
    if (unity != 1.0) parts.add('unity=' + _wireDouble(unity));
    return parts.isEmpty ? 'lavfi-afade' : 'lavfi-afade=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfadeEffect prev) {
    final out = <(String, String)>[];
    if (curve != prev.curve) {
      out.add(('curve', curve.mpvValue));
    }
    if (duration != prev.duration) {
      out.add(('duration', _wireDouble(duration.inMicroseconds / 1e6)));
    }
    if (nbSamples != prev.nbSamples) {
      out.add(('nb_samples', nbSamples.toString()));
    }
    if (silence != prev.silence) {
      out.add(('silence', _wireDouble(silence)));
    }
    if (startSample != prev.startSample) {
      out.add(('start_sample', startSample.toString()));
    }
    if (startTime != prev.startTime) {
      out.add(('start_time', _wireDouble(startTime.inMicroseconds / 1e6)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    if (unity != prev.unity) {
      out.add(('unity', _wireDouble(unity)));
    }
    return out;
  }
}

/// Configuration for the `afftdn` audio effect.
///
/// Denoise audio samples with FFT.
///
/// A description of the accepted parameters follows.
///
/// Parameters:
/// - [adaptivity]: Set the adaptivity factor, used how fast to adapt gains adjustments per each frequency bin. Value `0` enables instant adaptation, while higher values react much slower. Allowed range is from `0` to `1`. Default value is `0.5`. (range 0..1, default 0.5, runtime-tunable)
/// - [bandMultiplier]: Set the band multiplier factor, used how much to spread bands across frequency bins. Allowed range is from `0.2` to `5`. Default value is `1.25`. (range 0.2..5, default 1.25)
/// - [bandNoise]: Set custom band noise profile for every one of 15 bands. Bands are separated by ' ' or '|'. (range 0..0, default "")
/// - [floorOffset]: Set the noise floor offset factor. This option is used to adjust offset applied to measured noise floor. It is only effective when noise floor tracking is enabled. Allowed range is from `-2.0` to `2.0`. Default value is `1.0`. (range -2..2, default 1.0, runtime-tunable)
/// - [gainSmooth]: Set gain smooth spatial radius, used to smooth gains applied to each frequency bin. Useful to reduce random music noise artefacts. Higher values increases smoothing of gains. Allowed range is from `0` to `50`. Default value is `0`. (range 0..50, default 0, runtime-tunable)
/// - [noiseFloor]: Set the noise floor in dB, allowed range is -80 to -20. Default value is -50 dB. (range -80..-20, default -50, runtime-tunable)
/// - [noiseLink]: Set the noise link used for multichannel audio.  It accepts the following values: (range 0..3, default MIN_LINK, runtime-tunable)
/// - [noiseReduction]: Set the noise reduction in dB, allowed range is 0.01 to 97. Default value is 12 dB. (range .01..97, default 12, runtime-tunable)
/// - [noiseType]: Set the noise type.  It accepts the following values: (range 0..3, default WHITE_NOISE)
/// - [outputMode]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [residualFloor]: Set the residual floor in dB, allowed range is -80 to -20. Default value is -38 dB. (range -80..-20, default -38, runtime-tunable)
/// - [sampleNoise]: Toggle capturing and measurement of noise profile from input audio.  It accepts the following values: (range 0..2, default SAMPLE_NONE, runtime-tunable)
/// - [trackNoise]: Enable noise floor tracking. By default is disabled. With this enabled, noise floor is automatically adjusted. (range 0..1, default 0, runtime-tunable)
/// - [trackResidual]: Enable residual tracking. By default is disabled. (range 0..1, default 0, runtime-tunable)
final class AfftdnEffect extends AudioEffect {
  /// Default value for [adaptivity].
  static const double adaptivityDefault = 0.5;

  /// Minimum value for [adaptivity].
  static const double adaptivityMin = 0.0;

  /// Maximum value for [adaptivity].
  static const double adaptivityMax = 1.0;

  /// Default value for [bandMultiplier].
  static const double bandMultiplierDefault = 1.25;

  /// Minimum value for [bandMultiplier].
  static const double bandMultiplierMin = 0.2;

  /// Maximum value for [bandMultiplier].
  static const double bandMultiplierMax = 5.0;

  /// Default value for [floorOffset].
  static const double floorOffsetDefault = 1.0;

  /// Minimum value for [floorOffset].
  static const double floorOffsetMin = -2.0;

  /// Maximum value for [floorOffset].
  static const double floorOffsetMax = 2.0;

  /// Default value for [gainSmooth].
  static const int gainSmoothDefault = 0;

  /// Minimum value for [gainSmooth].
  static const int gainSmoothMin = 0;

  /// Maximum value for [gainSmooth].
  static const int gainSmoothMax = 50;

  /// Default value for [noiseFloor].
  static const double noiseFloorDefault = -50.0;

  /// Minimum value for [noiseFloor].
  static const double noiseFloorMin = -80.0;

  /// Maximum value for [noiseFloor].
  static const double noiseFloorMax = -20.0;

  /// Default value for [noiseReduction].
  static const double noiseReductionDefault = 12.0;

  /// Minimum value for [noiseReduction].
  static const double noiseReductionMin = .01;

  /// Maximum value for [noiseReduction].
  static const double noiseReductionMax = 97.0;

  /// Default value for [residualFloor].
  static const double residualFloorDefault = -38.0;

  /// Minimum value for [residualFloor].
  static const double residualFloorMin = -80.0;

  /// Maximum value for [residualFloor].
  static const double residualFloorMax = -20.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set adaptivity factor
  final double adaptivity;

  /// set band multiplier
  final double bandMultiplier;

  /// set the custom bands noise
  final String bandNoise;

  /// set noise floor offset factor
  final double floorOffset;

  /// set gain smooth radius
  final int gainSmooth;

  /// set the noise floor
  final double noiseFloor;

  /// set the noise floor link
  final AfftdnLink noiseLink;

  /// set the noise reduction
  final double noiseReduction;

  /// set the noise type
  final AfftdnType noiseType;

  /// set output mode
  final AfftdnMode outputMode;

  /// set the residual floor
  final double residualFloor;

  /// set sample noise mode
  final AfftdnSample sampleNoise;

  /// track noise
  final bool trackNoise;

  /// track residual
  final bool trackResidual;

  /// Creates an [AfftdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfftdnEffect({
    this.enabled = true,
    this.adaptivity = 0.5,
    this.bandMultiplier = 1.25,
    this.bandNoise = '',
    this.floorOffset = 1.0,
    this.gainSmooth = 0,
    this.noiseFloor = -50.0,
    this.noiseLink = AfftdnLink.min,
    this.noiseReduction = 12.0,
    this.noiseType = AfftdnType.white,
    this.outputMode = AfftdnMode.output,
    this.residualFloor = -38.0,
    this.sampleNoise = AfftdnSample.none,
    this.trackNoise = false,
    this.trackResidual = false,
  });

  @override
  String get filterName => 'afftdn';

  @override
  AudioFilter get filter => AudioFilter.afftdn;

  /// Returns a copy of this [AfftdnEffect] with the given fields replaced.
  AfftdnEffect copyWith({
    bool? enabled,
    double? adaptivity,
    double? bandMultiplier,
    String? bandNoise,
    double? floorOffset,
    int? gainSmooth,
    double? noiseFloor,
    AfftdnLink? noiseLink,
    double? noiseReduction,
    AfftdnType? noiseType,
    AfftdnMode? outputMode,
    double? residualFloor,
    AfftdnSample? sampleNoise,
    bool? trackNoise,
    bool? trackResidual,
  }) => AfftdnEffect(
    enabled: enabled ?? this.enabled,
    adaptivity: adaptivity ?? this.adaptivity,
    bandMultiplier: bandMultiplier ?? this.bandMultiplier,
    bandNoise: bandNoise ?? this.bandNoise,
    floorOffset: floorOffset ?? this.floorOffset,
    gainSmooth: gainSmooth ?? this.gainSmooth,
    noiseFloor: noiseFloor ?? this.noiseFloor,
    noiseLink: noiseLink ?? this.noiseLink,
    noiseReduction: noiseReduction ?? this.noiseReduction,
    noiseType: noiseType ?? this.noiseType,
    outputMode: outputMode ?? this.outputMode,
    residualFloor: residualFloor ?? this.residualFloor,
    sampleNoise: sampleNoise ?? this.sampleNoise,
    trackNoise: trackNoise ?? this.trackNoise,
    trackResidual: trackResidual ?? this.trackResidual,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftdnEffect &&
          other.enabled == enabled &&
          other.adaptivity == adaptivity &&
          other.bandMultiplier == bandMultiplier &&
          other.bandNoise == bandNoise &&
          other.floorOffset == floorOffset &&
          other.gainSmooth == gainSmooth &&
          other.noiseFloor == noiseFloor &&
          other.noiseLink == noiseLink &&
          other.noiseReduction == noiseReduction &&
          other.noiseType == noiseType &&
          other.outputMode == outputMode &&
          other.residualFloor == residualFloor &&
          other.sampleNoise == sampleNoise &&
          other.trackNoise == trackNoise &&
          other.trackResidual == trackResidual);

  @override
  int get hashCode => Object.hash(
    enabled,
    adaptivity,
    bandMultiplier,
    bandNoise,
    floorOffset,
    gainSmooth,
    noiseFloor,
    noiseLink,
    noiseReduction,
    noiseType,
    outputMode,
    residualFloor,
    sampleNoise,
    trackNoise,
    trackResidual,
  );

  @override
  String toString() =>
      'AfftdnEffect(enabled: $enabled, adaptivity: $adaptivity, bandMultiplier: $bandMultiplier, bandNoise: $bandNoise, floorOffset: $floorOffset, gainSmooth: $gainSmooth, noiseFloor: $noiseFloor, noiseLink: $noiseLink, noiseReduction: $noiseReduction, noiseType: $noiseType, outputMode: $outputMode, residualFloor: $residualFloor, sampleNoise: $sampleNoise, trackNoise: $trackNoise, trackResidual: $trackResidual)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(adaptivity >= adaptivityMin, 'afftdn.adaptivity must be >= 0');
    assert(adaptivity <= adaptivityMax, 'afftdn.adaptivity must be <= 1');
    assert(
      bandMultiplier >= bandMultiplierMin,
      'afftdn.band_multiplier must be >= 0.2',
    );
    assert(
      bandMultiplier <= bandMultiplierMax,
      'afftdn.band_multiplier must be <= 5',
    );
    assert(floorOffset >= floorOffsetMin, 'afftdn.floor_offset must be >= -2');
    assert(floorOffset <= floorOffsetMax, 'afftdn.floor_offset must be <= 2');
    assert(gainSmooth >= gainSmoothMin, 'afftdn.gain_smooth must be >= 0');
    assert(gainSmooth <= gainSmoothMax, 'afftdn.gain_smooth must be <= 50');
    assert(noiseFloor >= noiseFloorMin, 'afftdn.noise_floor must be >= -80');
    assert(noiseFloor <= noiseFloorMax, 'afftdn.noise_floor must be <= -20');
    assert(
      noiseReduction >= noiseReductionMin,
      'afftdn.noise_reduction must be >= .01',
    );
    assert(
      noiseReduction <= noiseReductionMax,
      'afftdn.noise_reduction must be <= 97',
    );
    assert(
      residualFloor >= residualFloorMin,
      'afftdn.residual_floor must be >= -80',
    );
    assert(
      residualFloor <= residualFloorMax,
      'afftdn.residual_floor must be <= -20',
    );
    final parts = <String>[];
    if (adaptivity != 0.5) parts.add('adaptivity=' + _wireDouble(adaptivity));
    if (bandMultiplier != 1.25)
      parts.add('band_multiplier=' + _wireDouble(bandMultiplier));
    if (bandNoise != '') parts.add('band_noise=' + '[' + bandNoise + ']');
    if (floorOffset != 1.0)
      parts.add('floor_offset=' + _wireDouble(floorOffset));
    if (gainSmooth != 0) parts.add('gain_smooth=' + gainSmooth.toString());
    if (noiseFloor != -50.0)
      parts.add('noise_floor=' + _wireDouble(noiseFloor));
    if (noiseLink != AfftdnLink.min)
      parts.add('noise_link=' + noiseLink.mpvValue);
    if (noiseReduction != 12.0)
      parts.add('noise_reduction=' + _wireDouble(noiseReduction));
    if (noiseType != AfftdnType.white)
      parts.add('noise_type=' + noiseType.mpvValue);
    if (outputMode != AfftdnMode.output)
      parts.add('output_mode=' + outputMode.mpvValue);
    if (residualFloor != -38.0)
      parts.add('residual_floor=' + _wireDouble(residualFloor));
    if (sampleNoise != AfftdnSample.none)
      parts.add('sample_noise=' + sampleNoise.mpvValue);
    if (trackNoise != false)
      parts.add('track_noise=' + (trackNoise ? '1' : '0'));
    if (trackResidual != false)
      parts.add('track_residual=' + (trackResidual ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-afftdn' : 'lavfi-afftdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfftdnEffect prev) {
    final out = <(String, String)>[];
    if (adaptivity != prev.adaptivity) {
      out.add(('adaptivity', _wireDouble(adaptivity)));
    }
    if (bandMultiplier != prev.bandMultiplier) return null;
    if (bandNoise != prev.bandNoise) return null;
    if (floorOffset != prev.floorOffset) {
      out.add(('floor_offset', _wireDouble(floorOffset)));
    }
    if (gainSmooth != prev.gainSmooth) {
      out.add(('gain_smooth', gainSmooth.toString()));
    }
    if (noiseFloor != prev.noiseFloor) {
      out.add(('noise_floor', _wireDouble(noiseFloor)));
    }
    if (noiseLink != prev.noiseLink) {
      out.add(('noise_link', noiseLink.mpvValue));
    }
    if (noiseReduction != prev.noiseReduction) {
      out.add(('noise_reduction', _wireDouble(noiseReduction)));
    }
    if (noiseType != prev.noiseType) return null;
    if (outputMode != prev.outputMode) {
      out.add(('output_mode', outputMode.mpvValue));
    }
    if (residualFloor != prev.residualFloor) {
      out.add(('residual_floor', _wireDouble(residualFloor)));
    }
    if (sampleNoise != prev.sampleNoise) {
      out.add(('sample_noise', sampleNoise.mpvValue));
    }
    if (trackNoise != prev.trackNoise) {
      out.add(('track_noise', (trackNoise ? '1' : '0')));
    }
    if (trackResidual != prev.trackResidual) {
      out.add(('track_residual', (trackResidual ? '1' : '0')));
    }
    return out;
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
/// - [winFunc]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [winSize]: Set window size. Allowed range is from 16 to 131072. Default is `4096` (range 16..131072, default 4096)
final class AfftfiltEffect extends AudioEffect {
  /// Default value for [overlap].
  static const double overlapDefault = 0.75;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [winSize].
  static const int winSizeDefault = 4096;

  /// Minimum value for [winSize].
  static const int winSizeMin = 16;

  /// Maximum value for [winSize].
  static const int winSizeMax = 131072;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels imaginary expressions
  final String imag;

  /// set window overlap
  final double overlap;

  /// set channels real expressions
  final String real;

  /// set window function
  final AfftfiltWinFunc winFunc;

  /// set window size
  final int winSize;

  /// Creates an [AfftfiltEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfftfiltEffect({
    this.enabled = true,
    this.imag = 'im',
    this.overlap = 0.75,
    this.real = 're',
    this.winFunc = AfftfiltWinFunc.hann,
    this.winSize = 4096,
  });

  @override
  String get filterName => 'afftfilt';

  @override
  AudioFilter get filter => AudioFilter.afftfilt;

  /// Returns a copy of this [AfftfiltEffect] with the given fields replaced.
  AfftfiltEffect copyWith({
    bool? enabled,
    String? imag,
    double? overlap,
    String? real,
    AfftfiltWinFunc? winFunc,
    int? winSize,
  }) => AfftfiltEffect(
    enabled: enabled ?? this.enabled,
    imag: imag ?? this.imag,
    overlap: overlap ?? this.overlap,
    real: real ?? this.real,
    winFunc: winFunc ?? this.winFunc,
    winSize: winSize ?? this.winSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfftfiltEffect &&
          other.enabled == enabled &&
          other.imag == imag &&
          other.overlap == overlap &&
          other.real == real &&
          other.winFunc == winFunc &&
          other.winSize == winSize);

  @override
  int get hashCode =>
      Object.hash(enabled, imag, overlap, real, winFunc, winSize);

  @override
  String toString() =>
      'AfftfiltEffect(enabled: $enabled, imag: $imag, overlap: $overlap, real: $real, winFunc: $winFunc, winSize: $winSize)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(overlap >= overlapMin, 'afftfilt.overlap must be >= 0');
    assert(overlap <= overlapMax, 'afftfilt.overlap must be <= 1');
    assert(winSize >= winSizeMin, 'afftfilt.win_size must be >= 16');
    assert(winSize <= winSizeMax, 'afftfilt.win_size must be <= 131072');
    final parts = <String>[];
    if (imag != 'im') parts.add('imag=' + '[' + imag + ']');
    if (overlap != 0.75) parts.add('overlap=' + _wireDouble(overlap));
    if (real != 're') parts.add('real=' + '[' + real + ']');
    if (winFunc != AfftfiltWinFunc.hann)
      parts.add('win_func=' + winFunc.mpvValue);
    if (winSize != 4096) parts.add('win_size=' + winSize.toString());
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
///
/// Parameters:
/// - [channelLayouts]: A '|'-separated list of requested channel layouts.  See channel layout syntax for the required syntax. (array, base=AV_OPT_TYPE_CHLAYOUT, sep='|')
/// - [sampleFmts]: A '|'-separated list of requested sample formats. (array, base=AV_OPT_TYPE_SAMPLE_FMT, sep='|')
/// - [sampleRates]: A '|'-separated list of requested sample rates. (range 1..2147483647, array, base=AV_OPT_TYPE_INT, sep='|')
final class AformatEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// A '|'-separated list of channel layouts.
  final String? channelLayouts;

  /// A '|'-separated list of sample formats.
  final String? sampleFmts;

  /// A '|'-separated list of sample rates.
  final String? sampleRates;

  /// Creates an [AformatEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AformatEffect({
    this.enabled = true,
    this.channelLayouts,
    this.sampleFmts,
    this.sampleRates,
  });

  @override
  String get filterName => 'aformat';

  @override
  AudioFilter get filter => AudioFilter.aformat;

  /// Returns a copy of this [AformatEffect] with the given fields replaced.
  AformatEffect copyWith({
    bool? enabled,
    Object? channelLayouts = unset,
    Object? sampleFmts = unset,
    Object? sampleRates = unset,
  }) => AformatEffect(
    enabled: enabled ?? this.enabled,
    channelLayouts: identical(channelLayouts, unset)
        ? this.channelLayouts
        : channelLayouts as String?,
    sampleFmts: identical(sampleFmts, unset)
        ? this.sampleFmts
        : sampleFmts as String?,
    sampleRates: identical(sampleRates, unset)
        ? this.sampleRates
        : sampleRates as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AformatEffect &&
          other.enabled == enabled &&
          other.channelLayouts == channelLayouts &&
          other.sampleFmts == sampleFmts &&
          other.sampleRates == sampleRates);

  @override
  int get hashCode =>
      Object.hash(enabled, channelLayouts, sampleFmts, sampleRates);

  @override
  String toString() =>
      'AformatEffect(enabled: $enabled, channelLayouts: $channelLayouts, sampleFmts: $sampleFmts, sampleRates: $sampleRates)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayouts != null)
      parts.add('channel_layouts=' + '[' + channelLayouts! + ']');
    if (sampleFmts != null) parts.add('sample_fmts=' + '[' + sampleFmts! + ']');
    if (sampleRates != null)
      parts.add('sample_rates=' + '[' + sampleRates! + ']');
    return parts.isEmpty ? 'lavfi-aformat' : 'lavfi-aformat=' + parts.join(':');
  }
}

/// Configuration for the `afreqshift` audio effect.
///
/// Apply frequency shift to input audio samples.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1, runtime-tunable)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (range 1..16, default 8)
/// - [shift]: Specify frequency shift. Allowed range is -INT_MAX to INT_MAX. Default value is 0.0. (range -2147483647..2147483647, default 0, runtime-tunable)
final class AfreqshiftEffect extends AudioEffect {
  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 8;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 16;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -2147483647.0;

  /// Maximum value for [shift].
  static const double shiftMax = 2147483647.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output level
  final double level;

  /// set filter order
  final int order;

  /// set frequency shift
  final double shift;

  /// Creates an [AfreqshiftEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfreqshiftEffect({
    this.enabled = true,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  @override
  String get filterName => 'afreqshift';

  @override
  AudioFilter get filter => AudioFilter.afreqshift;

  /// Returns a copy of this [AfreqshiftEffect] with the given fields replaced.
  AfreqshiftEffect copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) => AfreqshiftEffect(
    enabled: enabled ?? this.enabled,
    level: level ?? this.level,
    order: order ?? this.order,
    shift: shift ?? this.shift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfreqshiftEffect &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AfreqshiftEffect(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(level >= levelMin, 'afreqshift.level must be >= 0.0');
    assert(level <= levelMax, 'afreqshift.level must be <= 1.0');
    assert(order >= orderMin, 'afreqshift.order must be >= 1');
    assert(order <= orderMax, 'afreqshift.order must be <= 16');
    assert(shift >= shiftMin, 'afreqshift.shift must be >= -2147483647');
    assert(shift <= shiftMax, 'afreqshift.shift must be <= 2147483647');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty
        ? 'lavfi-afreqshift'
        : 'lavfi-afreqshift=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfreqshiftEffect prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) return null;
    if (shift != prev.shift) {
      out.add(('shift', _wireDouble(shift)));
    }
    return out;
  }
}

/// Configuration for the `afwtdn` audio effect.
///
/// Reduce broadband noise from input samples using Wavelets.
///
/// A description of the accepted options follows.
///
/// Parameters:
/// - [adaptive]: adaptive profiling of noise (range 0..1, default 0, runtime-tunable)
/// - [levels]: Set the number of wavelet levels of decomposition. Allowed range is from 1 to 12. Default value is 10. Setting this too low make denoising performance very poor. (range 1..12, default 10)
/// - [percent]: set percent of full denoising (range 0..100, default 85, runtime-tunable)
/// - [profile]: profile noise (range 0..1, default 0, runtime-tunable)
/// - [samples]: set frame size in number of samples (range 512..65536, default 8192)
/// - [sigma]: Set the noise sigma, allowed range is from 0 to 1. Default value is 0. This option controls strength of denoising applied to input samples. Most useful way to set this option is via decibels, eg. -45dB. (range 0..1, default 0, runtime-tunable)
/// - [softness]: set thresholding softness (range 0..10, default 1, runtime-tunable)
/// - [wavet]: Set wavelet type for decomposition of input frame. They are sorted by number of coefficients, from lowest to highest. More coefficients means worse filtering speed, but overall better quality. Available wavelets are: (range 0..6, default SYM10)
final class AfwtdnEffect extends AudioEffect {
  /// Default value for [levels].
  static const int levelsDefault = 10;

  /// Minimum value for [levels].
  static const int levelsMin = 1;

  /// Maximum value for [levels].
  static const int levelsMax = 12;

  /// Default value for [percent].
  static const double percentDefault = 85.0;

  /// Minimum value for [percent].
  static const double percentMin = 0.0;

  /// Maximum value for [percent].
  static const double percentMax = 100.0;

  /// Default value for [samples].
  static const int samplesDefault = 8192;

  /// Minimum value for [samples].
  static const int samplesMin = 512;

  /// Maximum value for [samples].
  static const int samplesMax = 65536;

  /// Default value for [sigma].
  static const double sigmaDefault = 0.0;

  /// Minimum value for [sigma].
  static const double sigmaMin = 0.0;

  /// Maximum value for [sigma].
  static const double sigmaMax = 1.0;

  /// Default value for [softness].
  static const double softnessDefault = 1.0;

  /// Minimum value for [softness].
  static const double softnessMin = 0.0;

  /// Maximum value for [softness].
  static const double softnessMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// adaptive profiling of noise
  final bool adaptive;

  /// set number of wavelet levels
  final int levels;

  /// set percent of full denoising
  final double percent;

  /// profile noise
  final bool profile;

  /// set frame size in number of samples
  final int samples;

  /// set noise sigma
  final double sigma;

  /// set thresholding softness
  final double softness;

  /// set wavelet type
  final AfwtdnWavet wavet;

  /// Creates an [AfwtdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AfwtdnEffect({
    this.enabled = true,
    this.adaptive = false,
    this.levels = 10,
    this.percent = 85.0,
    this.profile = false,
    this.samples = 8192,
    this.sigma = 0.0,
    this.softness = 1.0,
    this.wavet = AfwtdnWavet.sym10,
  });

  @override
  String get filterName => 'afwtdn';

  @override
  AudioFilter get filter => AudioFilter.afwtdn;

  /// Returns a copy of this [AfwtdnEffect] with the given fields replaced.
  AfwtdnEffect copyWith({
    bool? enabled,
    bool? adaptive,
    int? levels,
    double? percent,
    bool? profile,
    int? samples,
    double? sigma,
    double? softness,
    AfwtdnWavet? wavet,
  }) => AfwtdnEffect(
    enabled: enabled ?? this.enabled,
    adaptive: adaptive ?? this.adaptive,
    levels: levels ?? this.levels,
    percent: percent ?? this.percent,
    profile: profile ?? this.profile,
    samples: samples ?? this.samples,
    sigma: sigma ?? this.sigma,
    softness: softness ?? this.softness,
    wavet: wavet ?? this.wavet,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AfwtdnEffect &&
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
  int get hashCode => Object.hash(
    enabled,
    adaptive,
    levels,
    percent,
    profile,
    samples,
    sigma,
    softness,
    wavet,
  );

  @override
  String toString() =>
      'AfwtdnEffect(enabled: $enabled, adaptive: $adaptive, levels: $levels, percent: $percent, profile: $profile, samples: $samples, sigma: $sigma, softness: $softness, wavet: $wavet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(levels >= levelsMin, 'afwtdn.levels must be >= 1');
    assert(levels <= levelsMax, 'afwtdn.levels must be <= 12');
    assert(percent >= percentMin, 'afwtdn.percent must be >= 0');
    assert(percent <= percentMax, 'afwtdn.percent must be <= 100');
    assert(samples >= samplesMin, 'afwtdn.samples must be >= 512');
    assert(samples <= samplesMax, 'afwtdn.samples must be <= 65536');
    assert(sigma >= sigmaMin, 'afwtdn.sigma must be >= 0');
    assert(sigma <= sigmaMax, 'afwtdn.sigma must be <= 1');
    assert(softness >= softnessMin, 'afwtdn.softness must be >= 0');
    assert(softness <= softnessMax, 'afwtdn.softness must be <= 10');
    final parts = <String>[];
    if (adaptive != false) parts.add('adaptive=' + (adaptive ? '1' : '0'));
    if (levels != 10) parts.add('levels=' + levels.toString());
    if (percent != 85.0) parts.add('percent=' + _wireDouble(percent));
    if (profile != false) parts.add('profile=' + (profile ? '1' : '0'));
    if (samples != 8192) parts.add('samples=' + samples.toString());
    if (sigma != 0.0) parts.add('sigma=' + _wireDouble(sigma));
    if (softness != 1.0) parts.add('softness=' + _wireDouble(softness));
    if (wavet != AfwtdnWavet.sym10) parts.add('wavet=' + wavet.mpvValue);
    return parts.isEmpty ? 'lavfi-afwtdn' : 'lavfi-afwtdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AfwtdnEffect prev) {
    final out = <(String, String)>[];
    if (adaptive != prev.adaptive) {
      out.add(('adaptive', (adaptive ? '1' : '0')));
    }
    if (levels != prev.levels) return null;
    if (percent != prev.percent) {
      out.add(('percent', _wireDouble(percent)));
    }
    if (profile != prev.profile) {
      out.add(('profile', (profile ? '1' : '0')));
    }
    if (samples != prev.samples) return null;
    if (sigma != prev.sigma) {
      out.add(('sigma', _wireDouble(sigma)));
    }
    if (softness != prev.softness) {
      out.add(('softness', _wireDouble(softness)));
    }
    if (wavet != prev.wavet) return null;
    return out;
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
/// - [levelIn]: Set input level before filtering. Default is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelSc]: set sidechain gain (range 0.015625..64, default 1, runtime-tunable)
/// - [link]: Choose if the average level between all channels or the louder channel affects the reduction. Default is `average`. Can be `average` or `maximum`. (range 0..1, default 0, runtime-tunable)
/// - [makeup]: Set amount of amplification of signal after processing. Default is 1. Allowed range is from 1 to 64. (range 1..64, default 1, runtime-tunable)
/// - [mode]: Set the mode of operation. Can be `upward` or `downward`. Default is `downward`. If set to `upward` mode, higher parts of signal will be amplified, expanding dynamic range in upward direction. Otherwise, in case of `downward` lower parts of signal will be reduced. (range 0..1, default 0, runtime-tunable)
/// - [range]: Set the level of gain reduction when the signal is below the threshold. Default is 0.06125. Allowed range is from 0 to 1. Setting this to 0 disables reduction and then filter behaves like expander. (range 0..1, default 0.06125, runtime-tunable)
/// - [ratio]: Set a ratio by which the signal is reduced. Default is 2. Allowed range is from 1 to 9000. (range 1..9000, default 2, runtime-tunable)
/// - [release]: Amount of milliseconds the signal has to fall below the threshold before the reduction is increased again. Default is 250 milliseconds. Allowed range is from 0.01 to 9000. (range 0.01..9000, default 250)
/// - [threshold]: If a signal rises above this level the gain reduction is released. Default is 0.125. Allowed range is from 0 to 1. (range 0..1, default 0.125)
final class AgateEffect extends AudioEffect {
  /// Default value for [attack].
  static const double attackDefault = 20.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.01;

  /// Maximum value for [attack].
  static const double attackMax = 9000.0;

  /// Default value for [knee].
  static const double kneeDefault = 2.828427125;

  /// Minimum value for [knee].
  static const double kneeMin = 1.0;

  /// Maximum value for [knee].
  static const double kneeMax = 8.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelSc].
  static const double levelScDefault = 1.0;

  /// Minimum value for [levelSc].
  static const double levelScMin = 0.015625;

  /// Maximum value for [levelSc].
  static const double levelScMax = 64.0;

  /// Default value for [makeup].
  static const double makeupDefault = 1.0;

  /// Minimum value for [makeup].
  static const double makeupMin = 1.0;

  /// Maximum value for [makeup].
  static const double makeupMax = 64.0;

  /// Default value for [range].
  static const double rangeDefault = 0.06125;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [ratio].
  static const double ratioDefault = 2.0;

  /// Minimum value for [ratio].
  static const double ratioMin = 1.0;

  /// Maximum value for [ratio].
  static const double ratioMax = 9000.0;

  /// Default value for [release].
  static const double releaseDefault = 250.0;

  /// Minimum value for [release].
  static const double releaseMin = 0.01;

  /// Maximum value for [release].
  static const double releaseMax = 9000.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.125;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set attack
  final double attack;

  /// set detection
  final AgateDetection detection;

  /// set knee
  final double knee;

  /// set input level
  final double levelIn;

  /// set sidechain gain
  final double levelSc;

  /// set link
  final AgateLink link;

  /// set makeup gain
  final double makeup;

  /// set mode
  final AgateMode mode;

  /// set max gain reduction
  final double range;

  /// set ratio
  final double ratio;

  /// set release
  final double release;

  /// set threshold
  final double threshold;

  /// Creates an [AgateEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AgateEffect({
    this.enabled = true,
    this.attack = 20.0,
    this.detection = AgateDetection.rms,
    this.knee = 2.828427125,
    this.levelIn = 1.0,
    this.levelSc = 1.0,
    this.link = AgateLink.average,
    this.makeup = 1.0,
    this.mode = AgateMode.downward,
    this.range = 0.06125,
    this.ratio = 2.0,
    this.release = 250.0,
    this.threshold = 0.125,
  });

  @override
  String get filterName => 'agate';

  @override
  AudioFilter get filter => AudioFilter.agate;

  /// Returns a copy of this [AgateEffect] with the given fields replaced.
  AgateEffect copyWith({
    bool? enabled,
    double? attack,
    AgateDetection? detection,
    double? knee,
    double? levelIn,
    double? levelSc,
    AgateLink? link,
    double? makeup,
    AgateMode? mode,
    double? range,
    double? ratio,
    double? release,
    double? threshold,
  }) => AgateEffect(
    enabled: enabled ?? this.enabled,
    attack: attack ?? this.attack,
    detection: detection ?? this.detection,
    knee: knee ?? this.knee,
    levelIn: levelIn ?? this.levelIn,
    levelSc: levelSc ?? this.levelSc,
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
      (other is AgateEffect &&
          other.enabled == enabled &&
          other.attack == attack &&
          other.detection == detection &&
          other.knee == knee &&
          other.levelIn == levelIn &&
          other.levelSc == levelSc &&
          other.link == link &&
          other.makeup == makeup &&
          other.mode == mode &&
          other.range == range &&
          other.ratio == ratio &&
          other.release == release &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    attack,
    detection,
    knee,
    levelIn,
    levelSc,
    link,
    makeup,
    mode,
    range,
    ratio,
    release,
    threshold,
  );

  @override
  String toString() =>
      'AgateEffect(enabled: $enabled, attack: $attack, detection: $detection, knee: $knee, levelIn: $levelIn, levelSc: $levelSc, link: $link, makeup: $makeup, mode: $mode, range: $range, ratio: $ratio, release: $release, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(attack >= attackMin, 'agate.attack must be >= 0.01');
    assert(attack <= attackMax, 'agate.attack must be <= 9000');
    assert(knee >= kneeMin, 'agate.knee must be >= 1');
    assert(knee <= kneeMax, 'agate.knee must be <= 8');
    assert(levelIn >= levelInMin, 'agate.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'agate.level_in must be <= 64');
    assert(levelSc >= levelScMin, 'agate.level_sc must be >= 0.015625');
    assert(levelSc <= levelScMax, 'agate.level_sc must be <= 64');
    assert(makeup >= makeupMin, 'agate.makeup must be >= 1');
    assert(makeup <= makeupMax, 'agate.makeup must be <= 64');
    assert(range >= rangeMin, 'agate.range must be >= 0');
    assert(range <= rangeMax, 'agate.range must be <= 1');
    assert(ratio >= ratioMin, 'agate.ratio must be >= 1');
    assert(ratio <= ratioMax, 'agate.ratio must be <= 9000');
    assert(release >= releaseMin, 'agate.release must be >= 0.01');
    assert(release <= releaseMax, 'agate.release must be <= 9000');
    assert(threshold >= thresholdMin, 'agate.threshold must be >= 0');
    assert(threshold <= thresholdMax, 'agate.threshold must be <= 1');
    final parts = <String>[];
    if (attack != 20.0) parts.add('attack=' + _wireDouble(attack));
    if (detection != AgateDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (knee != 2.828427125) parts.add('knee=' + _wireDouble(knee));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelSc != 1.0) parts.add('level_sc=' + _wireDouble(levelSc));
    if (link != AgateLink.average) parts.add('link=' + link.mpvValue);
    if (makeup != 1.0) parts.add('makeup=' + _wireDouble(makeup));
    if (mode != AgateMode.downward) parts.add('mode=' + mode.mpvValue);
    if (range != 0.06125) parts.add('range=' + _wireDouble(range));
    if (ratio != 2.0) parts.add('ratio=' + _wireDouble(ratio));
    if (release != 250.0) parts.add('release=' + _wireDouble(release));
    if (threshold != 0.125) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty ? 'lavfi-agate' : 'lavfi-agate=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AgateEffect prev) {
    final out = <(String, String)>[];
    if (attack != prev.attack) return null;
    if (detection != prev.detection) return null;
    if (knee != prev.knee) return null;
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelSc != prev.levelSc) {
      out.add(('level_sc', _wireDouble(levelSc)));
    }
    if (link != prev.link) {
      out.add(('link', link.mpvValue));
    }
    if (makeup != prev.makeup) {
      out.add(('makeup', _wireDouble(makeup)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (ratio != prev.ratio) {
      out.add(('ratio', _wireDouble(ratio)));
    }
    if (release != prev.release) return null;
    if (threshold != prev.threshold) return null;
    return out;
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
/// - [format]: Set coefficients format. (range -2..4, default 1)
/// - [gains]: Set channels gains. (range 0..0, default "1|1")
/// - [mix]: set mix (range 0..1, default 1)
/// - [normalize]: normalize coefficients (range 0..1, default 1)
/// - [poles]: Set A/denominator/poles/ladder coefficients. (range 0..0, default "1+0i 1-0i")
/// - [precision]: set filtering precision (range 0..3, default 0)
/// - [process]: set kind of processing (range 0..2, default 1)
/// - [rate]: set video rate (range 0..2147483647, default "25")
/// - [response]: show IR frequency response (range 0..1, default 0)
/// - [size]: set video size (range 0..0, default "hd720")
/// - [wet]: set wet gain (range 0..1, default 1)
/// - [zeros]: Set B/numerator/zeros/reflection coefficients. (range 0..0, default "1+0i 1-0i")
final class AiirEffect extends AudioEffect {
  /// Default value for [channel].
  static const int channelDefault = 0;

  /// Minimum value for [channel].
  static const int channelMin = 0;

  /// Maximum value for [channel].
  static const int channelMax = 1024;

  /// Default value for [dry].
  static const double dryDefault = 1.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set IR channel to display frequency response
  final int channel;

  /// set dry gain
  final double dry;

  /// set coefficients format
  final AiirFormat format;

  /// set channels gains
  final String gains;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set A/denominator/poles/ladder coefficients
  final String poles;

  /// set filtering precision
  final AiirPrecision precision;

  /// set kind of processing
  final AiirProcess process;

  /// set video rate
  final String rate;

  /// show IR frequency response
  final bool response;

  /// set video size
  final String size;

  /// set wet gain
  final double wet;

  /// set B/numerator/zeros/reflection coefficients
  final String zeros;

  /// Creates an [AiirEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AiirEffect({
    this.enabled = true,
    this.channel = 0,
    this.dry = 1.0,
    this.format = AiirFormat.zp,
    this.gains = '1|1',
    this.mix = 1.0,
    this.normalize = true,
    this.poles = '1+0i 1-0i',
    this.precision = AiirPrecision.dbl,
    this.process = AiirProcess.s,
    this.rate = '25',
    this.response = false,
    this.size = 'hd720',
    this.wet = 1.0,
    this.zeros = '1+0i 1-0i',
  });

  @override
  String get filterName => 'aiir';

  @override
  AudioFilter get filter => AudioFilter.aiir;

  /// Returns a copy of this [AiirEffect] with the given fields replaced.
  AiirEffect copyWith({
    bool? enabled,
    int? channel,
    double? dry,
    AiirFormat? format,
    String? gains,
    double? mix,
    bool? normalize,
    String? poles,
    AiirPrecision? precision,
    AiirProcess? process,
    String? rate,
    bool? response,
    String? size,
    double? wet,
    String? zeros,
  }) => AiirEffect(
    enabled: enabled ?? this.enabled,
    channel: channel ?? this.channel,
    dry: dry ?? this.dry,
    format: format ?? this.format,
    gains: gains ?? this.gains,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    process: process ?? this.process,
    rate: rate ?? this.rate,
    response: response ?? this.response,
    size: size ?? this.size,
    wet: wet ?? this.wet,
    zeros: zeros ?? this.zeros,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiirEffect &&
          other.enabled == enabled &&
          other.channel == channel &&
          other.dry == dry &&
          other.format == format &&
          other.gains == gains &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.process == process &&
          other.rate == rate &&
          other.response == response &&
          other.size == size &&
          other.wet == wet &&
          other.zeros == zeros);

  @override
  int get hashCode => Object.hash(
    enabled,
    channel,
    dry,
    format,
    gains,
    mix,
    normalize,
    poles,
    precision,
    process,
    rate,
    response,
    size,
    wet,
    zeros,
  );

  @override
  String toString() =>
      'AiirEffect(enabled: $enabled, channel: $channel, dry: $dry, format: $format, gains: $gains, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, process: $process, rate: $rate, response: $response, size: $size, wet: $wet, zeros: $zeros)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(channel >= channelMin, 'aiir.channel must be >= 0');
    assert(channel <= channelMax, 'aiir.channel must be <= 1024');
    assert(dry >= dryMin, 'aiir.dry must be >= 0');
    assert(dry <= dryMax, 'aiir.dry must be <= 1');
    assert(mix >= mixMin, 'aiir.mix must be >= 0');
    assert(mix <= mixMax, 'aiir.mix must be <= 1');
    assert(wet >= wetMin, 'aiir.wet must be >= 0');
    assert(wet <= wetMax, 'aiir.wet must be <= 1');
    final parts = <String>[];
    if (channel != 0) parts.add('channel=' + channel.toString());
    if (dry != 1.0) parts.add('dry=' + _wireDouble(dry));
    if (format != AiirFormat.zp) parts.add('format=' + format.mpvValue);
    if (gains != '1|1') parts.add('gains=' + '[' + gains + ']');
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != true) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != '1+0i 1-0i') parts.add('poles=' + '[' + poles + ']');
    if (precision != AiirPrecision.dbl)
      parts.add('precision=' + precision.mpvValue);
    if (process != AiirProcess.s) parts.add('process=' + process.mpvValue);
    if (rate != '25') parts.add('rate=' + '[' + rate + ']');
    if (response != false) parts.add('response=' + (response ? '1' : '0'));
    if (size != 'hd720') parts.add('size=' + '[' + size + ']');
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    if (zeros != '1+0i 1-0i') parts.add('zeros=' + '[' + zeros + ']');
    return parts.isEmpty ? 'lavfi-aiir' : 'lavfi-aiir=' + parts.join(':');
  }
}

/// Configuration for the `aintegral` audio effect.
///
/// Compute derivative/integral of audio stream.
///
/// Applying both filters one after another produces original audio.
final class AintegralEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Creates an [AintegralEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AintegralEffect({this.enabled = true});

  @override
  String get filterName => 'aintegral';

  @override
  AudioFilter get filter => AudioFilter.aintegral;

  /// Returns a copy of this [AintegralEffect] with the given fields replaced.
  AintegralEffect copyWith({bool? enabled}) =>
      AintegralEffect(enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AintegralEffect && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AintegralEffect(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    return 'lavfi-aintegral';
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
/// - [asc]: When gain reduction is always needed ASC takes care of releasing to an average reduction level rather than reaching a reduction of 0 in the release time. (range 0..1, default 0, runtime-tunable)
/// - [ascLevel]: Select how much the release time is affected by ASC, 0 means nearly no changes in release time while 1 produces higher release times. (range 0..1, default 0.5)
/// - [attack]: The limiter will reach its attenuation level in this amount of time in milliseconds. Default is 5 milliseconds. (range 0.1..80, default 5)
/// - [latency]: Compensate the delay introduced by using the lookahead buffer set with attack parameter. Also flush the valid audio data in the lookahead buffer when the stream hits EOF. (range 0..1, default 0)
/// - [level]: Auto level output signal. Default is enabled. This normalizes audio back to 0dB if enabled. (range 0..1, default 1, runtime-tunable)
/// - [levelIn]: Set input gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. Default is 1. (range .015625..64, default 1, runtime-tunable)
/// - [limit]: Don't let signals above this level pass the limiter. Default is 1. (range 0.0625..1, default 1, runtime-tunable)
/// - [release]: Come back from limiting to attenuation 1.0 in this amount of milliseconds. Default is 50 milliseconds. (range 1..8000, default 50)
final class AlimiterEffect extends AudioEffect {
  /// Default value for [ascLevel].
  static const double ascLevelDefault = 0.5;

  /// Minimum value for [ascLevel].
  static const double ascLevelMin = 0.0;

  /// Maximum value for [ascLevel].
  static const double ascLevelMax = 1.0;

  /// Default value for [attack].
  static const double attackDefault = 5.0;

  /// Minimum value for [attack].
  static const double attackMin = 0.1;

  /// Maximum value for [attack].
  static const double attackMax = 80.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = .015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = .015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [limit].
  static const double limitDefault = 1.0;

  /// Minimum value for [limit].
  static const double limitMin = 0.0625;

  /// Maximum value for [limit].
  static const double limitMax = 1.0;

  /// Default value for [release].
  static const double releaseDefault = 50.0;

  /// Minimum value for [release].
  static const double releaseMin = 1.0;

  /// Maximum value for [release].
  static const double releaseMax = 8000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable asc
  final bool asc;

  /// set asc level
  final double ascLevel;

  /// set attack
  final double attack;

  /// compensate delay
  final bool latency;

  /// auto level
  final bool level;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// set limit
  final double limit;

  /// set release
  final double release;

  /// Creates an [AlimiterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AlimiterEffect({
    this.enabled = true,
    this.asc = false,
    this.ascLevel = 0.5,
    this.attack = 5.0,
    this.latency = false,
    this.level = true,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.limit = 1.0,
    this.release = 50.0,
  });

  @override
  String get filterName => 'alimiter';

  @override
  AudioFilter get filter => AudioFilter.alimiter;

  /// Returns a copy of this [AlimiterEffect] with the given fields replaced.
  AlimiterEffect copyWith({
    bool? enabled,
    bool? asc,
    double? ascLevel,
    double? attack,
    bool? latency,
    bool? level,
    double? levelIn,
    double? levelOut,
    double? limit,
    double? release,
  }) => AlimiterEffect(
    enabled: enabled ?? this.enabled,
    asc: asc ?? this.asc,
    ascLevel: ascLevel ?? this.ascLevel,
    attack: attack ?? this.attack,
    latency: latency ?? this.latency,
    level: level ?? this.level,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    limit: limit ?? this.limit,
    release: release ?? this.release,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AlimiterEffect &&
          other.enabled == enabled &&
          other.asc == asc &&
          other.ascLevel == ascLevel &&
          other.attack == attack &&
          other.latency == latency &&
          other.level == level &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.limit == limit &&
          other.release == release);

  @override
  int get hashCode => Object.hash(
    enabled,
    asc,
    ascLevel,
    attack,
    latency,
    level,
    levelIn,
    levelOut,
    limit,
    release,
  );

  @override
  String toString() =>
      'AlimiterEffect(enabled: $enabled, asc: $asc, ascLevel: $ascLevel, attack: $attack, latency: $latency, level: $level, levelIn: $levelIn, levelOut: $levelOut, limit: $limit, release: $release)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(ascLevel >= ascLevelMin, 'alimiter.asc_level must be >= 0');
    assert(ascLevel <= ascLevelMax, 'alimiter.asc_level must be <= 1');
    assert(attack >= attackMin, 'alimiter.attack must be >= 0.1');
    assert(attack <= attackMax, 'alimiter.attack must be <= 80');
    assert(levelIn >= levelInMin, 'alimiter.level_in must be >= .015625');
    assert(levelIn <= levelInMax, 'alimiter.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'alimiter.level_out must be >= .015625');
    assert(levelOut <= levelOutMax, 'alimiter.level_out must be <= 64');
    assert(limit >= limitMin, 'alimiter.limit must be >= 0.0625');
    assert(limit <= limitMax, 'alimiter.limit must be <= 1');
    assert(release >= releaseMin, 'alimiter.release must be >= 1');
    assert(release <= releaseMax, 'alimiter.release must be <= 8000');
    final parts = <String>[];
    if (asc != false) parts.add('asc=' + (asc ? '1' : '0'));
    if (ascLevel != 0.5) parts.add('asc_level=' + _wireDouble(ascLevel));
    if (attack != 5.0) parts.add('attack=' + _wireDouble(attack));
    if (latency != false) parts.add('latency=' + (latency ? '1' : '0'));
    if (level != true) parts.add('level=' + (level ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (limit != 1.0) parts.add('limit=' + _wireDouble(limit));
    if (release != 50.0) parts.add('release=' + _wireDouble(release));
    return parts.isEmpty
        ? 'lavfi-alimiter'
        : 'lavfi-alimiter=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AlimiterEffect prev) {
    final out = <(String, String)>[];
    if (asc != prev.asc) {
      out.add(('asc', (asc ? '1' : '0')));
    }
    if (ascLevel != prev.ascLevel) return null;
    if (attack != prev.attack) return null;
    if (latency != prev.latency) return null;
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (limit != prev.limit) {
      out.add(('limit', _wireDouble(limit)));
    }
    if (release != prev.release) return null;
    return out;
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
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set frequency in Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [order]: Set the filter order, can be 1 or 2. Default is 2. (range 1..2, default 2, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.707, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class AllpassEffect extends AudioEffect {
  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 2;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filter order
  final int order;

  /// set filtering precision
  final AllpassPrecision precision;

  /// set transform type
  final AllpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final AllpassWidthType widthType;

  /// Creates an [AllpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AllpassEffect({
    this.enabled = true,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.order = 2,
    this.precision = AllpassPrecision.auto,
    this.transform = AllpassTransformType.di,
    this.width = 0.707,
    this.widthType = AllpassWidthType.q,
  });

  @override
  String get filterName => 'allpass';

  @override
  AudioFilter get filter => AudioFilter.allpass;

  /// Returns a copy of this [AllpassEffect] with the given fields replaced.
  AllpassEffect copyWith({
    bool? enabled,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    int? order,
    AllpassPrecision? precision,
    AllpassTransformType? transform,
    double? width,
    AllpassWidthType? widthType,
  }) => AllpassEffect(
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    order: order ?? this.order,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AllpassEffect &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.order == order &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    channels,
    frequency,
    mix,
    normalize,
    order,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'AllpassEffect(enabled: $enabled, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, order: $order, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(frequency >= frequencyMin, 'allpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'allpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'allpass.mix must be >= 0');
    assert(mix <= mixMax, 'allpass.mix must be <= 1');
    assert(order >= orderMin, 'allpass.order must be >= 1');
    assert(order <= orderMax, 'allpass.order must be <= 2');
    assert(width >= widthMin, 'allpass.width must be >= 0');
    assert(width <= widthMax, 'allpass.width must be <= 99999');
    final parts = <String>[];
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (order != 2) parts.add('order=' + order.toString());
    if (precision != AllpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != AllpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (widthType != AllpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty ? 'lavfi-allpass' : 'lavfi-allpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AllpassEffect prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [size]: set video size (range 0..0, default "hd720")
final class AnequalizerEffect extends AudioEffect {
  /// Default value for [mgain].
  static const double mgainDefault = 60.0;

  /// Minimum value for [mgain].
  static const double mgainMin = -900.0;

  /// Maximum value for [mgain].
  static const double mgainMax = 900.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels curves colors
  final String colors;

  /// draw frequency response curves
  final bool curves;

  /// set frequency scale
  final AnequalizerFscale fscale;

  /// set max gain
  final double mgain;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final String params;

  /// set video size
  final String size;

  /// Creates an [AnequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AnequalizerEffect({
    this.enabled = true,
    this.colors = 'red|green|blue|yellow|orange|lime|pink|magenta|brown',
    this.curves = false,
    this.fscale = AnequalizerFscale.log,
    this.mgain = 60.0,
    this.params = '',
    this.size = 'hd720',
  });

  @override
  String get filterName => 'anequalizer';

  @override
  AudioFilter get filter => AudioFilter.anequalizer;

  /// Returns a copy of this [AnequalizerEffect] with the given fields replaced.
  AnequalizerEffect copyWith({
    bool? enabled,
    String? colors,
    bool? curves,
    AnequalizerFscale? fscale,
    double? mgain,
    String? params,
    String? size,
  }) => AnequalizerEffect(
    enabled: enabled ?? this.enabled,
    colors: colors ?? this.colors,
    curves: curves ?? this.curves,
    fscale: fscale ?? this.fscale,
    mgain: mgain ?? this.mgain,
    params: params ?? this.params,
    size: size ?? this.size,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnequalizerEffect &&
          other.enabled == enabled &&
          other.colors == colors &&
          other.curves == curves &&
          other.fscale == fscale &&
          other.mgain == mgain &&
          other.params == params &&
          other.size == size);

  @override
  int get hashCode =>
      Object.hash(enabled, colors, curves, fscale, mgain, params, size);

  @override
  String toString() =>
      'AnequalizerEffect(enabled: $enabled, colors: $colors, curves: $curves, fscale: $fscale, mgain: $mgain, params: $params, size: $size)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(mgain >= mgainMin, 'anequalizer.mgain must be >= -900');
    assert(mgain <= mgainMax, 'anequalizer.mgain must be <= 900');
    final parts = <String>[];
    if (colors != 'red|green|blue|yellow|orange|lime|pink|magenta|brown')
      parts.add('colors=' + '[' + colors + ']');
    if (curves != false) parts.add('curves=' + (curves ? '1' : '0'));
    if (fscale != AnequalizerFscale.log) parts.add('fscale=' + fscale.mpvValue);
    if (mgain != 60.0) parts.add('mgain=' + _wireDouble(mgain));
    if (params != '') parts.add('params=' + '[' + params + ']');
    if (size != 'hd720') parts.add('size=' + '[' + size + ']');
    return parts.isEmpty
        ? 'lavfi-anequalizer'
        : 'lavfi-anequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AnequalizerEffect prev) {
    final out = <(String, String)>[];
    if (colors != prev.colors) return null;
    if (curves != prev.curves) return null;
    if (fscale != prev.fscale) return null;
    if (mgain != prev.mgain) return null;
    if (params != prev.params) return null;
    if (size != prev.size) return null;
    return out;
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
/// - [output]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE, runtime-tunable)
/// - [patch]: Set patch radius duration. Allowed range is from 1 to 100 milliseconds. Default value is 2 milliseconds. (range 1000..100000, default 2000, runtime-tunable)
/// - [research]: Set research radius duration. Allowed range is from 2 to 300 milliseconds. Default value is 6 milliseconds. (range 2000..300000, default 6000, runtime-tunable)
/// - [smooth]: Set smooth factor. Default value is `11`. Allowed range is from `1` to `1000`. (range 1..1000, default 11., runtime-tunable)
/// - [strength]: Set denoising strength. Allowed range is from 0.00001 to 10000. Default value is 0.00001. (range 0.00001..10000, default 0.00001, runtime-tunable)
final class AnlmdnEffect extends AudioEffect {
  /// Default value for [smooth].
  static const double smoothDefault = 11.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 1.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1000.0;

  /// Default value for [strength].
  static const double strengthDefault = 0.00001;

  /// Minimum value for [strength].
  static const double strengthMin = 0.00001;

  /// Maximum value for [strength].
  static const double strengthMax = 10000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output mode
  final AnlmdnMode output;

  /// set patch duration
  final Duration patch;

  /// set research duration
  final Duration research;

  /// set smooth factor
  final double smooth;

  /// set denoising strength
  final double strength;

  /// Creates an [AnlmdnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AnlmdnEffect({
    this.enabled = true,
    this.output = AnlmdnMode.o,
    this.patch = const Duration(microseconds: 2000),
    this.research = const Duration(microseconds: 6000),
    this.smooth = 11.0,
    this.strength = 0.00001,
  });

  @override
  String get filterName => 'anlmdn';

  @override
  AudioFilter get filter => AudioFilter.anlmdn;

  /// Returns a copy of this [AnlmdnEffect] with the given fields replaced.
  AnlmdnEffect copyWith({
    bool? enabled,
    AnlmdnMode? output,
    Duration? patch,
    Duration? research,
    double? smooth,
    double? strength,
  }) => AnlmdnEffect(
    enabled: enabled ?? this.enabled,
    output: output ?? this.output,
    patch: patch ?? this.patch,
    research: research ?? this.research,
    smooth: smooth ?? this.smooth,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnlmdnEffect &&
          other.enabled == enabled &&
          other.output == output &&
          other.patch == patch &&
          other.research == research &&
          other.smooth == smooth &&
          other.strength == strength);

  @override
  int get hashCode =>
      Object.hash(enabled, output, patch, research, smooth, strength);

  @override
  String toString() =>
      'AnlmdnEffect(enabled: $enabled, output: $output, patch: $patch, research: $research, smooth: $smooth, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(smooth >= smoothMin, 'anlmdn.smooth must be >= 1');
    assert(smooth <= smoothMax, 'anlmdn.smooth must be <= 1000');
    assert(strength >= strengthMin, 'anlmdn.strength must be >= 0.00001');
    assert(strength <= strengthMax, 'anlmdn.strength must be <= 10000');
    final parts = <String>[];
    if (output != AnlmdnMode.o) parts.add('output=' + output.mpvValue);
    if (patch != const Duration(microseconds: 2000))
      parts.add('patch=' + _wireDouble(patch.inMicroseconds / 1e6));
    if (research != const Duration(microseconds: 6000))
      parts.add('research=' + _wireDouble(research.inMicroseconds / 1e6));
    if (smooth != 11.0) parts.add('smooth=' + _wireDouble(smooth));
    if (strength != 0.00001) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty ? 'lavfi-anlmdn' : 'lavfi-anlmdn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AnlmdnEffect prev) {
    final out = <(String, String)>[];
    if (output != prev.output) {
      out.add(('output', output.mpvValue));
    }
    if (patch != prev.patch) {
      out.add(('patch', _wireDouble(patch.inMicroseconds / 1e6)));
    }
    if (research != prev.research) {
      out.add(('research', _wireDouble(research.inMicroseconds / 1e6)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
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
/// - [packetSize]: Set silence packet size. Default value is 4096. (range 0..2147483647, default 4096)
/// - [padDur]: Specify the duration of samples of silence to add. See time duration syntax for the accepted syntax. Used only if set to non-negative value. (range -1..9223372036854775807, default -1)
/// - [padLen]: Set the number of samples of silence to add to the end. After the value is reached, the stream is terminated. This option is mutually exclusive with @option{whole_len}. (range -1..9223372036854775807, default -1)
/// - [wholeDur]: Specify the minimum total duration in the output audio stream. See time duration syntax for the accepted syntax. Used only if set to non-negative value. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_dur} (range -1..9223372036854775807, default -1)
/// - [wholeLen]: Set the minimum total number of samples in the output audio stream. If the value is longer than the input audio length, silence is added to the end, until the value is reached. This option is mutually exclusive with @option{pad_len}. (range -1..9223372036854775807, default -1)
final class ApadEffect extends AudioEffect {
  /// Default value for [packetSize].
  static const int packetSizeDefault = 4096;

  /// Minimum value for [packetSize].
  static const int packetSizeMin = 0;

  /// Maximum value for [packetSize].
  static const int packetSizeMax = 2147483647;

  /// Default value for [padLen].
  static const int padLenDefault = -1;

  /// Minimum value for [padLen].
  static const int padLenMin = -1;

  /// Maximum value for [padLen].
  static const int padLenMax = 9223372036854775807;

  /// Default value for [wholeLen].
  static const int wholeLenDefault = -1;

  /// Minimum value for [wholeLen].
  static const int wholeLenMin = -1;

  /// Maximum value for [wholeLen].
  static const int wholeLenMax = 9223372036854775807;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set silence packet size
  final int packetSize;

  /// set duration of silence to add
  final Duration padDur;

  /// set number of samples of silence to add
  final int padLen;

  /// set minimum target duration in the audio stream
  final Duration wholeDur;

  /// set minimum target number of samples in the audio stream
  final int wholeLen;

  /// Creates an [ApadEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApadEffect({
    this.enabled = true,
    this.packetSize = 4096,
    this.padDur = const Duration(microseconds: -1),
    this.padLen = -1,
    this.wholeDur = const Duration(microseconds: -1),
    this.wholeLen = -1,
  });

  @override
  String get filterName => 'apad';

  @override
  AudioFilter get filter => AudioFilter.apad;

  /// Returns a copy of this [ApadEffect] with the given fields replaced.
  ApadEffect copyWith({
    bool? enabled,
    int? packetSize,
    Duration? padDur,
    int? padLen,
    Duration? wholeDur,
    int? wholeLen,
  }) => ApadEffect(
    enabled: enabled ?? this.enabled,
    packetSize: packetSize ?? this.packetSize,
    padDur: padDur ?? this.padDur,
    padLen: padLen ?? this.padLen,
    wholeDur: wholeDur ?? this.wholeDur,
    wholeLen: wholeLen ?? this.wholeLen,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApadEffect &&
          other.enabled == enabled &&
          other.packetSize == packetSize &&
          other.padDur == padDur &&
          other.padLen == padLen &&
          other.wholeDur == wholeDur &&
          other.wholeLen == wholeLen);

  @override
  int get hashCode =>
      Object.hash(enabled, packetSize, padDur, padLen, wholeDur, wholeLen);

  @override
  String toString() =>
      'ApadEffect(enabled: $enabled, packetSize: $packetSize, padDur: $padDur, padLen: $padLen, wholeDur: $wholeDur, wholeLen: $wholeLen)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(packetSize >= packetSizeMin, 'apad.packet_size must be >= 0');
    assert(
      packetSize <= packetSizeMax,
      'apad.packet_size must be <= 2147483647',
    );
    assert(padLen >= padLenMin, 'apad.pad_len must be >= -1');
    assert(padLen <= padLenMax, 'apad.pad_len must be <= 9223372036854775807');
    assert(wholeLen >= wholeLenMin, 'apad.whole_len must be >= -1');
    assert(
      wholeLen <= wholeLenMax,
      'apad.whole_len must be <= 9223372036854775807',
    );
    final parts = <String>[];
    if (packetSize != 4096) parts.add('packet_size=' + packetSize.toString());
    if (padDur != const Duration(microseconds: -1))
      parts.add('pad_dur=' + _wireDouble(padDur.inMicroseconds / 1e6));
    if (padLen != -1) parts.add('pad_len=' + padLen.toString());
    if (wholeDur != const Duration(microseconds: -1))
      parts.add('whole_dur=' + _wireDouble(wholeDur.inMicroseconds / 1e6));
    if (wholeLen != -1) parts.add('whole_len=' + wholeLen.toString());
    return parts.isEmpty ? 'lavfi-apad' : 'lavfi-apad=' + parts.join(':');
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
/// - [decay]: Set decay. Default is 0.4. (range 0...99, default .4)
/// - [delay]: Set delay in milliseconds. Default is 3.0. (range 0.1..5, default 3.)
/// - [inGain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [outGain]: Set output gain. Default is 0.74 (range 0..1e9, default .74)
/// - [speed]: Set modulation speed in Hz. Default is 0.5. (range .1..2, default .5)
/// - [type]: Set modulation type. Default is triangular.  It accepts the following values: (default WAVE_TRI)
final class AphaserEffect extends AudioEffect {
  /// Default value for [decay].
  static const double decayDefault = .4;

  /// Minimum value for [decay].
  static const double decayMin = 0.0;

  /// Maximum value for [decay].
  static const double decayMax = .99;

  /// Default value for [delay].
  static const double delayDefault = 3.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.1;

  /// Maximum value for [delay].
  static const double delayMax = 5.0;

  /// Default value for [inGain].
  static const double inGainDefault = .4;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = .74;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1e9;

  /// Default value for [speed].
  static const double speedDefault = .5;

  /// Minimum value for [speed].
  static const double speedMin = .1;

  /// Maximum value for [speed].
  static const double speedMax = 2.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set decay
  final double decay;

  /// set delay in milliseconds
  final double delay;

  /// set input gain
  final double inGain;

  /// set output gain
  final double outGain;

  /// set modulation speed
  final double speed;

  /// set modulation type
  final AphaserType type;

  /// Creates an [AphaserEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AphaserEffect({
    this.enabled = true,
    this.decay = .4,
    this.delay = 3.0,
    this.inGain = .4,
    this.outGain = .74,
    this.speed = .5,
    this.type = AphaserType.triangular,
  });

  @override
  String get filterName => 'aphaser';

  @override
  AudioFilter get filter => AudioFilter.aphaser;

  /// Returns a copy of this [AphaserEffect] with the given fields replaced.
  AphaserEffect copyWith({
    bool? enabled,
    double? decay,
    double? delay,
    double? inGain,
    double? outGain,
    double? speed,
    AphaserType? type,
  }) => AphaserEffect(
    enabled: enabled ?? this.enabled,
    decay: decay ?? this.decay,
    delay: delay ?? this.delay,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
    speed: speed ?? this.speed,
    type: type ?? this.type,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaserEffect &&
          other.enabled == enabled &&
          other.decay == decay &&
          other.delay == delay &&
          other.inGain == inGain &&
          other.outGain == outGain &&
          other.speed == speed &&
          other.type == type);

  @override
  int get hashCode =>
      Object.hash(enabled, decay, delay, inGain, outGain, speed, type);

  @override
  String toString() =>
      'AphaserEffect(enabled: $enabled, decay: $decay, delay: $delay, inGain: $inGain, outGain: $outGain, speed: $speed, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(decay >= decayMin, 'aphaser.decay must be >= 0');
    assert(decay <= decayMax, 'aphaser.decay must be <= .99');
    assert(delay >= delayMin, 'aphaser.delay must be >= 0.1');
    assert(delay <= delayMax, 'aphaser.delay must be <= 5');
    assert(inGain >= inGainMin, 'aphaser.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'aphaser.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'aphaser.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'aphaser.out_gain must be <= 1e9');
    assert(speed >= speedMin, 'aphaser.speed must be >= .1');
    assert(speed <= speedMax, 'aphaser.speed must be <= 2');
    final parts = <String>[];
    if (decay != .4) parts.add('decay=' + _wireDouble(decay));
    if (delay != 3.0) parts.add('delay=' + _wireDouble(delay));
    if (inGain != .4) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != .74) parts.add('out_gain=' + _wireDouble(outGain));
    if (speed != .5) parts.add('speed=' + _wireDouble(speed));
    if (type != AphaserType.triangular) parts.add('type=' + type.mpvValue);
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
/// - [level]: Set output gain applied to final output. Allowed range is from 0.0 to 1.0. Default value is 1.0. (range 0.0..1.0, default 1, runtime-tunable)
/// - [order]: Set filter order used for filtering. Allowed range is from 1 to 16. Default value is 8. (range 1..16, default 8)
/// - [shift]: Specify phase shift. Allowed range is from -1.0 to 1.0. Default value is 0.0. (range -1.0..1.0, default 0, runtime-tunable)
final class AphaseshiftEffect extends AudioEffect {
  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 8;

  /// Minimum value for [order].
  static const int orderMin = 1;

  /// Maximum value for [order].
  static const int orderMax = 16;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -1.0;

  /// Maximum value for [shift].
  static const double shiftMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output level
  final double level;

  /// set filter order
  final int order;

  /// set phase shift
  final double shift;

  /// Creates an [AphaseshiftEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AphaseshiftEffect({
    this.enabled = true,
    this.level = 1.0,
    this.order = 8,
    this.shift = 0.0,
  });

  @override
  String get filterName => 'aphaseshift';

  @override
  AudioFilter get filter => AudioFilter.aphaseshift;

  /// Returns a copy of this [AphaseshiftEffect] with the given fields replaced.
  AphaseshiftEffect copyWith({
    bool? enabled,
    double? level,
    int? order,
    double? shift,
  }) => AphaseshiftEffect(
    enabled: enabled ?? this.enabled,
    level: level ?? this.level,
    order: order ?? this.order,
    shift: shift ?? this.shift,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AphaseshiftEffect &&
          other.enabled == enabled &&
          other.level == level &&
          other.order == order &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, level, order, shift);

  @override
  String toString() =>
      'AphaseshiftEffect(enabled: $enabled, level: $level, order: $order, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(level >= levelMin, 'aphaseshift.level must be >= 0.0');
    assert(level <= levelMax, 'aphaseshift.level must be <= 1.0');
    assert(order >= orderMin, 'aphaseshift.order must be >= 1');
    assert(order <= orderMax, 'aphaseshift.order must be <= 16');
    assert(shift >= shiftMin, 'aphaseshift.shift must be >= -1.0');
    assert(shift <= shiftMax, 'aphaseshift.shift must be <= 1.0');
    final parts = <String>[];
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 8) parts.add('order=' + order.toString());
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
    return parts.isEmpty
        ? 'lavfi-aphaseshift'
        : 'lavfi-aphaseshift=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AphaseshiftEffect prev) {
    final out = <(String, String)>[];
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) return null;
    if (shift != prev.shift) {
      out.add(('shift', _wireDouble(shift)));
    }
    return out;
  }
}

/// Configuration for the `apsyclip` audio effect.
///
/// Apply Psychoacoustic clipper to input audio stream.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [adaptive]: Set strength of adaptive distortion applied. Default value is 0.5. Allowed range is from 0 to 1. (range 0..1, default 0.5, runtime-tunable)
/// - [clip]: Set the clipping start value. Default value is 0dBFS or 1. (range .015625..1, default 1, runtime-tunable)
/// - [diff]: Output only difference samples, useful to hear introduced distortions. By default is disabled. (range 0..1, default 0, runtime-tunable)
/// - [iterations]: Set number of iterations of psychoacoustic clipper. Allowed range is from 1 to 20. Default value is 10. (range 1..20, default 10, runtime-tunable)
/// - [level]: Auto level output signal. Default is disabled. This normalizes audio back to 0dBFS if enabled. (range 0..1, default 0, runtime-tunable)
/// - [levelIn]: Set input gain. By default it is 1. Range is \[0.015625 - 64\]. (range .015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output gain. By default it is 1. Range is \[0.015625 - 64\]. (range .015625..64, default 1, runtime-tunable)
final class ApsyclipEffect extends AudioEffect {
  /// Default value for [adaptive].
  static const double adaptiveDefault = 0.5;

  /// Minimum value for [adaptive].
  static const double adaptiveMin = 0.0;

  /// Maximum value for [adaptive].
  static const double adaptiveMax = 1.0;

  /// Default value for [clip].
  static const double clipDefault = 1.0;

  /// Minimum value for [clip].
  static const double clipMin = .015625;

  /// Maximum value for [clip].
  static const double clipMax = 1.0;

  /// Default value for [iterations].
  static const int iterationsDefault = 10;

  /// Minimum value for [iterations].
  static const int iterationsMin = 1;

  /// Maximum value for [iterations].
  static const int iterationsMax = 20;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = .015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = .015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set adaptive distortion
  final double adaptive;

  /// set clip level
  final double clip;

  /// enable difference
  final bool diff;

  /// set iterations
  final int iterations;

  /// set auto level
  final bool level;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// Creates an [ApsyclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApsyclipEffect({
    this.enabled = true,
    this.adaptive = 0.5,
    this.clip = 1.0,
    this.diff = false,
    this.iterations = 10,
    this.level = false,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
  });

  @override
  String get filterName => 'apsyclip';

  @override
  AudioFilter get filter => AudioFilter.apsyclip;

  /// Returns a copy of this [ApsyclipEffect] with the given fields replaced.
  ApsyclipEffect copyWith({
    bool? enabled,
    double? adaptive,
    double? clip,
    bool? diff,
    int? iterations,
    bool? level,
    double? levelIn,
    double? levelOut,
  }) => ApsyclipEffect(
    enabled: enabled ?? this.enabled,
    adaptive: adaptive ?? this.adaptive,
    clip: clip ?? this.clip,
    diff: diff ?? this.diff,
    iterations: iterations ?? this.iterations,
    level: level ?? this.level,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApsyclipEffect &&
          other.enabled == enabled &&
          other.adaptive == adaptive &&
          other.clip == clip &&
          other.diff == diff &&
          other.iterations == iterations &&
          other.level == level &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut);

  @override
  int get hashCode => Object.hash(
    enabled,
    adaptive,
    clip,
    diff,
    iterations,
    level,
    levelIn,
    levelOut,
  );

  @override
  String toString() =>
      'ApsyclipEffect(enabled: $enabled, adaptive: $adaptive, clip: $clip, diff: $diff, iterations: $iterations, level: $level, levelIn: $levelIn, levelOut: $levelOut)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(adaptive >= adaptiveMin, 'apsyclip.adaptive must be >= 0');
    assert(adaptive <= adaptiveMax, 'apsyclip.adaptive must be <= 1');
    assert(clip >= clipMin, 'apsyclip.clip must be >= .015625');
    assert(clip <= clipMax, 'apsyclip.clip must be <= 1');
    assert(iterations >= iterationsMin, 'apsyclip.iterations must be >= 1');
    assert(iterations <= iterationsMax, 'apsyclip.iterations must be <= 20');
    assert(levelIn >= levelInMin, 'apsyclip.level_in must be >= .015625');
    assert(levelIn <= levelInMax, 'apsyclip.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'apsyclip.level_out must be >= .015625');
    assert(levelOut <= levelOutMax, 'apsyclip.level_out must be <= 64');
    final parts = <String>[];
    if (adaptive != 0.5) parts.add('adaptive=' + _wireDouble(adaptive));
    if (clip != 1.0) parts.add('clip=' + _wireDouble(clip));
    if (diff != false) parts.add('diff=' + (diff ? '1' : '0'));
    if (iterations != 10) parts.add('iterations=' + iterations.toString());
    if (level != false) parts.add('level=' + (level ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    return parts.isEmpty
        ? 'lavfi-apsyclip'
        : 'lavfi-apsyclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant ApsyclipEffect prev) {
    final out = <(String, String)>[];
    if (adaptive != prev.adaptive) {
      out.add(('adaptive', _wireDouble(adaptive)));
    }
    if (clip != prev.clip) {
      out.add(('clip', _wireDouble(clip)));
    }
    if (diff != prev.diff) {
      out.add(('diff', (diff ? '1' : '0')));
    }
    if (iterations != prev.iterations) {
      out.add(('iterations', iterations.toString()));
    }
    if (level != prev.level) {
      out.add(('level', (level ? '1' : '0')));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    return out;
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
/// - [bpm]: Set bpm. Default is 120. Allowed range is \[30 - 300\]. Only used if timing is set to bpm. (range 30..300, default 120)
/// - [hz]: Set frequency in Hz. Default is 2. Allowed range is \[0.01 - 100\]. Only used if timing is set to hz. (range 0.01..100, default 2)
/// - [levelIn]: Set input gain. By default it is 1. Range is \[0.015625 - 64\]. (range 0.015625..64, default 1)
/// - [levelOut]: Set output gain. By default it is 1. Range is \[0.015625 - 64\]. (range 0.015625..64, default 1)
/// - [mode]: Set waveform shape the LFO will use. Can be one of: sine, triangle, square, sawup or sawdown. Default is sine. (range 0..4, default SINE)
/// - [ms]: Set ms. Default is 500. Allowed range is \[10 - 2000\]. Only used if timing is set to ms. (range 10..2000, default 500)
/// - [offsetL]: Set left channel offset. Default is 0. Allowed range is \[0 - 1\]. (range 0..1, default 0)
/// - [offsetR]: Set right channel offset. Default is 0.5. Allowed range is \[0 - 1\]. (range 0..1, default .5)
/// - [timing]: Set possible timing mode. Can be one of: bpm, ms or hz. Default is hz. (range 0..2, default 2)
/// - [width]: Set pulse width. Default is 1. Allowed range is \[0 - 2\]. (range 0..2, default 1)
final class ApulsatorEffect extends AudioEffect {
  /// Default value for [amount].
  static const double amountDefault = 1.0;

  /// Minimum value for [amount].
  static const double amountMin = 0.0;

  /// Maximum value for [amount].
  static const double amountMax = 1.0;

  /// Default value for [bpm].
  static const double bpmDefault = 120.0;

  /// Minimum value for [bpm].
  static const double bpmMin = 30.0;

  /// Maximum value for [bpm].
  static const double bpmMax = 300.0;

  /// Default value for [hz].
  static const double hzDefault = 2.0;

  /// Minimum value for [hz].
  static const double hzMin = 0.01;

  /// Maximum value for [hz].
  static const double hzMax = 100.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [ms].
  static const int msDefault = 500;

  /// Minimum value for [ms].
  static const int msMin = 10;

  /// Maximum value for [ms].
  static const int msMax = 2000;

  /// Default value for [offsetL].
  static const double offsetLDefault = 0.0;

  /// Minimum value for [offsetL].
  static const double offsetLMin = 0.0;

  /// Maximum value for [offsetL].
  static const double offsetLMax = 1.0;

  /// Default value for [offsetR].
  static const double offsetRDefault = .5;

  /// Minimum value for [offsetR].
  static const double offsetRMin = 0.0;

  /// Maximum value for [offsetR].
  static const double offsetRMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 2.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set modulation
  final double amount;

  /// set BPM
  final double bpm;

  /// set frequency
  final double hz;

  /// set input gain
  final double levelIn;

  /// set output gain
  final double levelOut;

  /// set mode
  final ApulsatorMode mode;

  /// set ms
  final int ms;

  /// set offset L
  final double offsetL;

  /// set offset R
  final double offsetR;

  /// set timing
  final ApulsatorTiming timing;

  /// set pulse width
  final double width;

  /// Creates an [ApulsatorEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ApulsatorEffect({
    this.enabled = true,
    this.amount = 1.0,
    this.bpm = 120.0,
    this.hz = 2.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mode = ApulsatorMode.sine,
    this.ms = 500,
    this.offsetL = 0.0,
    this.offsetR = .5,
    this.timing = ApulsatorTiming.hz,
    this.width = 1.0,
  });

  @override
  String get filterName => 'apulsator';

  @override
  AudioFilter get filter => AudioFilter.apulsator;

  /// Returns a copy of this [ApulsatorEffect] with the given fields replaced.
  ApulsatorEffect copyWith({
    bool? enabled,
    double? amount,
    double? bpm,
    double? hz,
    double? levelIn,
    double? levelOut,
    ApulsatorMode? mode,
    int? ms,
    double? offsetL,
    double? offsetR,
    ApulsatorTiming? timing,
    double? width,
  }) => ApulsatorEffect(
    enabled: enabled ?? this.enabled,
    amount: amount ?? this.amount,
    bpm: bpm ?? this.bpm,
    hz: hz ?? this.hz,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    mode: mode ?? this.mode,
    ms: ms ?? this.ms,
    offsetL: offsetL ?? this.offsetL,
    offsetR: offsetR ?? this.offsetR,
    timing: timing ?? this.timing,
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApulsatorEffect &&
          other.enabled == enabled &&
          other.amount == amount &&
          other.bpm == bpm &&
          other.hz == hz &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.mode == mode &&
          other.ms == ms &&
          other.offsetL == offsetL &&
          other.offsetR == offsetR &&
          other.timing == timing &&
          other.width == width);

  @override
  int get hashCode => Object.hash(
    enabled,
    amount,
    bpm,
    hz,
    levelIn,
    levelOut,
    mode,
    ms,
    offsetL,
    offsetR,
    timing,
    width,
  );

  @override
  String toString() =>
      'ApulsatorEffect(enabled: $enabled, amount: $amount, bpm: $bpm, hz: $hz, levelIn: $levelIn, levelOut: $levelOut, mode: $mode, ms: $ms, offsetL: $offsetL, offsetR: $offsetR, timing: $timing, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(amount >= amountMin, 'apulsator.amount must be >= 0');
    assert(amount <= amountMax, 'apulsator.amount must be <= 1');
    assert(bpm >= bpmMin, 'apulsator.bpm must be >= 30');
    assert(bpm <= bpmMax, 'apulsator.bpm must be <= 300');
    assert(hz >= hzMin, 'apulsator.hz must be >= 0.01');
    assert(hz <= hzMax, 'apulsator.hz must be <= 100');
    assert(levelIn >= levelInMin, 'apulsator.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'apulsator.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'apulsator.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'apulsator.level_out must be <= 64');
    assert(ms >= msMin, 'apulsator.ms must be >= 10');
    assert(ms <= msMax, 'apulsator.ms must be <= 2000');
    assert(offsetL >= offsetLMin, 'apulsator.offset_l must be >= 0');
    assert(offsetL <= offsetLMax, 'apulsator.offset_l must be <= 1');
    assert(offsetR >= offsetRMin, 'apulsator.offset_r must be >= 0');
    assert(offsetR <= offsetRMax, 'apulsator.offset_r must be <= 1');
    assert(width >= widthMin, 'apulsator.width must be >= 0');
    assert(width <= widthMax, 'apulsator.width must be <= 2');
    final parts = <String>[];
    if (amount != 1.0) parts.add('amount=' + _wireDouble(amount));
    if (bpm != 120.0) parts.add('bpm=' + _wireDouble(bpm));
    if (hz != 2.0) parts.add('hz=' + _wireDouble(hz));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mode != ApulsatorMode.sine) parts.add('mode=' + mode.mpvValue);
    if (ms != 500) parts.add('ms=' + ms.toString());
    if (offsetL != 0.0) parts.add('offset_l=' + _wireDouble(offsetL));
    if (offsetR != .5) parts.add('offset_r=' + _wireDouble(offsetR));
    if (timing != ApulsatorTiming.hz) parts.add('timing=' + timing.mpvValue);
    if (width != 1.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty
        ? 'lavfi-apulsator'
        : 'lavfi-apulsator=' + parts.join(':');
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
/// \[`sample_rate`:\]`resampler_options`, where `sample_rate`
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
/// - [sampleRate]:  (range 0..768000, default 0)
final class AresampleEffect extends AudioEffect {
  /// Default value for [sampleRate].
  static const int sampleRateDefault = 0;

  /// Minimum value for [sampleRate].
  static const int sampleRateMin = 0;

  /// Maximum value for [sampleRate].
  static const int sampleRateMax = 768000;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `sampleRate` parameter.
  final int sampleRate;

  /// Creates an [AresampleEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AresampleEffect({this.enabled = true, this.sampleRate = 0});

  @override
  String get filterName => 'aresample';

  @override
  AudioFilter get filter => AudioFilter.aresample;

  /// Returns a copy of this [AresampleEffect] with the given fields replaced.
  AresampleEffect copyWith({bool? enabled, int? sampleRate}) => AresampleEffect(
    enabled: enabled ?? this.enabled,
    sampleRate: sampleRate ?? this.sampleRate,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AresampleEffect &&
          other.enabled == enabled &&
          other.sampleRate == sampleRate);

  @override
  int get hashCode => Object.hash(enabled, sampleRate);

  @override
  String toString() =>
      'AresampleEffect(enabled: $enabled, sampleRate: $sampleRate)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(sampleRate >= sampleRateMin, 'aresample.sample_rate must be >= 0');
    assert(
      sampleRate <= sampleRateMax,
      'aresample.sample_rate must be <= 768000',
    );
    final parts = <String>[];
    if (sampleRate != 0) parts.add('sample_rate=' + sampleRate.toString());
    return parts.isEmpty
        ? 'lavfi-aresample'
        : 'lavfi-aresample=' + parts.join(':');
  }
}

/// Configuration for the `arnndn` audio effect.
///
/// Reduce noise from speech using Recurrent Neural Networks.
///
/// This filter accepts the following options:
///
/// Parameters:
/// - [mix]: Set how much to mix filtered samples into final output. Allowed range is from -1 to 1. Default value is 1. Negative values are special, they set how much to keep filtered noise in the final filter output. Set this option to -1 to hear actual noise removed from input signal. (range -1..1, default 1.0, runtime-tunable)
/// - [model]: Set train model file to load. This option is always required. (range 0..0, default "", runtime-tunable)
final class ArnndnEffect extends AudioEffect {
  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = -1.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set output vs input mix
  final double mix;

  /// set model name
  final String model;

  /// Creates an [ArnndnEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ArnndnEffect({
    this.enabled = true,
    this.mix = 1.0,
    required this.model,
  });

  @override
  String get filterName => 'arnndn';

  @override
  AudioFilter get filter => AudioFilter.arnndn;

  /// Returns a copy of this [ArnndnEffect] with the given fields replaced.
  ArnndnEffect copyWith({bool? enabled, double? mix, String? model}) =>
      ArnndnEffect(
        enabled: enabled ?? this.enabled,
        mix: mix ?? this.mix,
        model: model ?? this.model,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArnndnEffect &&
          other.enabled == enabled &&
          other.mix == mix &&
          other.model == model);

  @override
  int get hashCode => Object.hash(enabled, mix, model);

  @override
  String toString() =>
      'ArnndnEffect(enabled: $enabled, mix: $mix, model: $model)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(mix >= mixMin, 'arnndn.mix must be >= -1');
    assert(mix <= mixMax, 'arnndn.mix must be <= 1');
    final parts = <String>[];
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    parts.add('model=' + '[' + model + ']');
    return parts.isEmpty ? 'lavfi-arnndn' : 'lavfi-arnndn=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant ArnndnEffect prev) {
    final out = <(String, String)>[];
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (model != prev.model) {
      out.add(('model', model));
    }
    return out;
  }
}

/// Configuration for the `asetrate` audio effect.
///
/// Set the sample rate without altering the PCM data.
/// This will result in a change of speed and pitch.
///
/// The filter accepts the following options:
final class AsetrateEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Creates an [AsetrateEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsetrateEffect({this.enabled = true});

  @override
  String get filterName => 'asetrate';

  @override
  AudioFilter get filter => AudioFilter.asetrate;

  /// Returns a copy of this [AsetrateEffect] with the given fields replaced.
  AsetrateEffect copyWith({bool? enabled}) =>
      AsetrateEffect(enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsetrateEffect && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'AsetrateEffect(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    return 'lavfi-asetrate';
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
/// - [output]: Set gain applied to output. Default value is 0dB or 1. (range 0.000001..16, default 1, runtime-tunable)
/// - [oversample]: Set oversampling factor. (range 1..64, default 1, runtime-tunable)
/// - [param]: Set additional parameter which controls sigmoid function. (range 0.01..3, default 1, runtime-tunable)
/// - [threshold]: Set threshold from where to start clipping. Default value is 0dB or 1. (range 0.000001..1, default 1, runtime-tunable)
/// - [type]: Set type of soft-clipping.  It accepts the following values: (range -1..7, default 0, runtime-tunable)
final class AsoftclipEffect extends AudioEffect {
  /// Default value for [output].
  static const double outputDefault = 1.0;

  /// Minimum value for [output].
  static const double outputMin = 0.000001;

  /// Maximum value for [output].
  static const double outputMax = 16.0;

  /// Default value for [oversample].
  static const int oversampleDefault = 1;

  /// Minimum value for [oversample].
  static const int oversampleMin = 1;

  /// Maximum value for [oversample].
  static const int oversampleMax = 64;

  /// Default value for [param].
  static const double paramDefault = 1.0;

  /// Minimum value for [param].
  static const double paramMin = 0.01;

  /// Maximum value for [param].
  static const double paramMax = 3.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 1.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.000001;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set softclip output gain
  final double output;

  /// set oversample factor
  final int oversample;

  /// set softclip parameter
  final double param;

  /// set softclip threshold
  final double threshold;

  /// set softclip type
  final AsoftclipTypes type;

  /// Creates an [AsoftclipEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsoftclipEffect({
    this.enabled = true,
    this.output = 1.0,
    this.oversample = 1,
    this.param = 1.0,
    this.threshold = 1.0,
    this.type = AsoftclipTypes.hard,
  });

  @override
  String get filterName => 'asoftclip';

  @override
  AudioFilter get filter => AudioFilter.asoftclip;

  /// Returns a copy of this [AsoftclipEffect] with the given fields replaced.
  AsoftclipEffect copyWith({
    bool? enabled,
    double? output,
    int? oversample,
    double? param,
    double? threshold,
    AsoftclipTypes? type,
  }) => AsoftclipEffect(
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
      (other is AsoftclipEffect &&
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
      'AsoftclipEffect(enabled: $enabled, output: $output, oversample: $oversample, param: $param, threshold: $threshold, type: $type)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(output >= outputMin, 'asoftclip.output must be >= 0.000001');
    assert(output <= outputMax, 'asoftclip.output must be <= 16');
    assert(oversample >= oversampleMin, 'asoftclip.oversample must be >= 1');
    assert(oversample <= oversampleMax, 'asoftclip.oversample must be <= 64');
    assert(param >= paramMin, 'asoftclip.param must be >= 0.01');
    assert(param <= paramMax, 'asoftclip.param must be <= 3');
    assert(
      threshold >= thresholdMin,
      'asoftclip.threshold must be >= 0.000001',
    );
    assert(threshold <= thresholdMax, 'asoftclip.threshold must be <= 1');
    final parts = <String>[];
    if (output != 1.0) parts.add('output=' + _wireDouble(output));
    if (oversample != 1) parts.add('oversample=' + oversample.toString());
    if (param != 1.0) parts.add('param=' + _wireDouble(param));
    if (threshold != 1.0) parts.add('threshold=' + _wireDouble(threshold));
    if (type != AsoftclipTypes.hard) parts.add('type=' + type.mpvValue);
    return parts.isEmpty
        ? 'lavfi-asoftclip'
        : 'lavfi-asoftclip=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsoftclipEffect prev) {
    final out = <(String, String)>[];
    if (output != prev.output) {
      out.add(('output', _wireDouble(output)));
    }
    if (oversample != prev.oversample) {
      out.add(('oversample', oversample.toString()));
    }
    if (param != prev.param) {
      out.add(('param', _wireDouble(param)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    if (type != prev.type) {
      out.add(('type', type.mpvValue));
    }
    return out;
  }
}

/// Configuration for the `asubboost` audio effect.
///
/// Boost subwoofer frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [boost]: Set max boost factor. Allowed range is from 1 to 12. Default value is 2. (range 1..12, default 2.0, runtime-tunable)
/// - [channels]: Set the channels to process. Default value is all available. (range 0..0, default "all", runtime-tunable)
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 50 to 900. Default value is 100. (range 50..900, default 100, runtime-tunable)
/// - [decay]: Set delay line decay gain value. Allowed range is from 0 to 1. Default value is 0.0. (range 0..1, default 0.0, runtime-tunable)
/// - [delay]: Set delay. Allowed range is from 1 to 100. Default value is 20. (range 1..100, default 20, runtime-tunable)
/// - [dry]: Set dry gain, how much of original signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0, runtime-tunable)
/// - [feedback]: Set delay line feedback gain value. Allowed range is from 0 to 1. Default value is 0.9. (range 0..1, default 0.9, runtime-tunable)
/// - [slope]: Set slope amount for cutoff frequency. Allowed range is 0.0001 to 1. Default value is 0.5. (range 0.0001..1, default 0.5, runtime-tunable)
/// - [wet]: Set wet gain, how much of filtered signal is kept. Allowed range is from 0 to 1. Default value is 1.0. (range 0..1, default 1.0, runtime-tunable)
final class AsubboostEffect extends AudioEffect {
  /// Default value for [boost].
  static const double boostDefault = 2.0;

  /// Minimum value for [boost].
  static const double boostMin = 1.0;

  /// Maximum value for [boost].
  static const double boostMax = 12.0;

  /// Default value for [cutoff].
  static const double cutoffDefault = 100.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 50.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 900.0;

  /// Default value for [decay].
  static const double decayDefault = 0.0;

  /// Minimum value for [decay].
  static const double decayMin = 0.0;

  /// Maximum value for [decay].
  static const double decayMax = 1.0;

  /// Default value for [delay].
  static const double delayDefault = 20.0;

  /// Minimum value for [delay].
  static const double delayMin = 1.0;

  /// Maximum value for [delay].
  static const double delayMax = 100.0;

  /// Default value for [dry].
  static const double dryDefault = 1.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [feedback].
  static const double feedbackDefault = 0.9;

  /// Minimum value for [feedback].
  static const double feedbackMin = 0.0;

  /// Maximum value for [feedback].
  static const double feedbackMax = 1.0;

  /// Default value for [slope].
  static const double slopeDefault = 0.5;

  /// Minimum value for [slope].
  static const double slopeMin = 0.0001;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set max boost
  final double boost;

  /// set channels to filter
  final String channels;

  /// set cutoff
  final double cutoff;

  /// set decay
  final double decay;

  /// set delay
  final double delay;

  /// set dry gain
  final double dry;

  /// set feedback
  final double feedback;

  /// set slope
  final double slope;

  /// set wet gain
  final double wet;

  /// Creates an [AsubboostEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsubboostEffect({
    this.enabled = true,
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

  @override
  String get filterName => 'asubboost';

  @override
  AudioFilter get filter => AudioFilter.asubboost;

  /// Returns a copy of this [AsubboostEffect] with the given fields replaced.
  AsubboostEffect copyWith({
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
  }) => AsubboostEffect(
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
      (other is AsubboostEffect &&
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
  int get hashCode => Object.hash(
    enabled,
    boost,
    channels,
    cutoff,
    decay,
    delay,
    dry,
    feedback,
    slope,
    wet,
  );

  @override
  String toString() =>
      'AsubboostEffect(enabled: $enabled, boost: $boost, channels: $channels, cutoff: $cutoff, decay: $decay, delay: $delay, dry: $dry, feedback: $feedback, slope: $slope, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(boost >= boostMin, 'asubboost.boost must be >= 1');
    assert(boost <= boostMax, 'asubboost.boost must be <= 12');
    assert(cutoff >= cutoffMin, 'asubboost.cutoff must be >= 50');
    assert(cutoff <= cutoffMax, 'asubboost.cutoff must be <= 900');
    assert(decay >= decayMin, 'asubboost.decay must be >= 0');
    assert(decay <= decayMax, 'asubboost.decay must be <= 1');
    assert(delay >= delayMin, 'asubboost.delay must be >= 1');
    assert(delay <= delayMax, 'asubboost.delay must be <= 100');
    assert(dry >= dryMin, 'asubboost.dry must be >= 0');
    assert(dry <= dryMax, 'asubboost.dry must be <= 1');
    assert(feedback >= feedbackMin, 'asubboost.feedback must be >= 0');
    assert(feedback <= feedbackMax, 'asubboost.feedback must be <= 1');
    assert(slope >= slopeMin, 'asubboost.slope must be >= 0.0001');
    assert(slope <= slopeMax, 'asubboost.slope must be <= 1');
    assert(wet >= wetMin, 'asubboost.wet must be >= 0');
    assert(wet <= wetMax, 'asubboost.wet must be <= 1');
    final parts = <String>[];
    if (boost != 2.0) parts.add('boost=' + _wireDouble(boost));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (cutoff != 100.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (decay != 0.0) parts.add('decay=' + _wireDouble(decay));
    if (delay != 20.0) parts.add('delay=' + _wireDouble(delay));
    if (dry != 1.0) parts.add('dry=' + _wireDouble(dry));
    if (feedback != 0.9) parts.add('feedback=' + _wireDouble(feedback));
    if (slope != 0.5) parts.add('slope=' + _wireDouble(slope));
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    return parts.isEmpty
        ? 'lavfi-asubboost'
        : 'lavfi-asubboost=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsubboostEffect prev) {
    final out = <(String, String)>[];
    if (boost != prev.boost) {
      out.add(('boost', _wireDouble(boost)));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (decay != prev.decay) {
      out.add(('decay', _wireDouble(decay)));
    }
    if (delay != prev.delay) {
      out.add(('delay', _wireDouble(delay)));
    }
    if (dry != prev.dry) {
      out.add(('dry', _wireDouble(dry)));
    }
    if (feedback != prev.feedback) {
      out.add(('feedback', _wireDouble(feedback)));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (wet != prev.wet) {
      out.add(('wet', _wireDouble(wet)));
    }
    return out;
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
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 2 to 200. Default value is 20. (range 2..200, default 20, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10, runtime-tunable)
final class AsubcutEffect extends AudioEffect {
  /// Default value for [cutoff].
  static const double cutoffDefault = 20.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 2.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 200.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 10;

  /// Minimum value for [order].
  static const int orderMin = 3;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cutoff frequency
  final double cutoff;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// Creates an [AsubcutEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsubcutEffect({
    this.enabled = true,
    this.cutoff = 20.0,
    this.level = 1.0,
    this.order = 10,
  });

  @override
  String get filterName => 'asubcut';

  @override
  AudioFilter get filter => AudioFilter.asubcut;

  /// Returns a copy of this [AsubcutEffect] with the given fields replaced.
  AsubcutEffect copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) => AsubcutEffect(
    enabled: enabled ?? this.enabled,
    cutoff: cutoff ?? this.cutoff,
    level: level ?? this.level,
    order: order ?? this.order,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsubcutEffect &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsubcutEffect(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'asubcut.cutoff must be >= 2');
    assert(cutoff <= cutoffMax, 'asubcut.cutoff must be <= 200');
    assert(level >= levelMin, 'asubcut.level must be >= 0.0');
    assert(level <= levelMax, 'asubcut.level must be <= 1.0');
    assert(order >= orderMin, 'asubcut.order must be >= 3');
    assert(order <= orderMax, 'asubcut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty ? 'lavfi-asubcut' : 'lavfi-asubcut=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsubcutEffect prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    return out;
  }
}

/// Configuration for the `asupercut` audio effect.
///
/// Cut super frequencies.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [cutoff]: Set cutoff frequency in Hertz. Allowed range is 20000 to 192000. Default value is 20000. (range 20000..192000, default 20000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 1. Default value is 1. (range 0.0..1.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 3 to 20. Default value is 10. (range 3..20, default 10, runtime-tunable)
final class AsupercutEffect extends AudioEffect {
  /// Default value for [cutoff].
  static const double cutoffDefault = 20000.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 20000.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 192000.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 1.0;

  /// Default value for [order].
  static const int orderDefault = 10;

  /// Minimum value for [order].
  static const int orderMin = 3;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cutoff frequency
  final double cutoff;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// Creates an [AsupercutEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsupercutEffect({
    this.enabled = true,
    this.cutoff = 20000.0,
    this.level = 1.0,
    this.order = 10,
  });

  @override
  String get filterName => 'asupercut';

  @override
  AudioFilter get filter => AudioFilter.asupercut;

  /// Returns a copy of this [AsupercutEffect] with the given fields replaced.
  AsupercutEffect copyWith({
    bool? enabled,
    double? cutoff,
    double? level,
    int? order,
  }) => AsupercutEffect(
    enabled: enabled ?? this.enabled,
    cutoff: cutoff ?? this.cutoff,
    level: level ?? this.level,
    order: order ?? this.order,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsupercutEffect &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.level == level &&
          other.order == order);

  @override
  int get hashCode => Object.hash(enabled, cutoff, level, order);

  @override
  String toString() =>
      'AsupercutEffect(enabled: $enabled, cutoff: $cutoff, level: $level, order: $order)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'asupercut.cutoff must be >= 20000');
    assert(cutoff <= cutoffMax, 'asupercut.cutoff must be <= 192000');
    assert(level >= levelMin, 'asupercut.level must be >= 0.0');
    assert(level <= levelMax, 'asupercut.level must be <= 1.0');
    assert(order >= orderMin, 'asupercut.order must be >= 3');
    assert(order <= orderMax, 'asupercut.order must be <= 20');
    final parts = <String>[];
    if (cutoff != 20000.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 10) parts.add('order=' + order.toString());
    return parts.isEmpty
        ? 'lavfi-asupercut'
        : 'lavfi-asupercut=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsupercutEffect prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) {
      out.add(('cutoff', _wireDouble(cutoff)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    return out;
  }
}

/// Configuration for the `asuperpass` audio effect.
///
/// Apply high order Butterworth band-pass filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4, runtime-tunable)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1., runtime-tunable)
final class AsuperpassEffect extends AudioEffect {
  /// Default value for [centerf].
  static const double centerfDefault = 1000.0;

  /// Minimum value for [centerf].
  static const double centerfMin = 2.0;

  /// Maximum value for [centerf].
  static const double centerfMax = 999999.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 2.0;

  /// Default value for [order].
  static const int orderDefault = 4;

  /// Minimum value for [order].
  static const int orderMin = 4;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Default value for [qfactor].
  static const double qfactorDefault = 1.0;

  /// Minimum value for [qfactor].
  static const double qfactorMin = 0.01;

  /// Maximum value for [qfactor].
  static const double qfactorMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set center frequency
  final double centerf;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set Q-factor
  final double qfactor;

  /// Creates an [AsuperpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsuperpassEffect({
    this.enabled = true,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  @override
  String get filterName => 'asuperpass';

  @override
  AudioFilter get filter => AudioFilter.asuperpass;

  /// Returns a copy of this [AsuperpassEffect] with the given fields replaced.
  AsuperpassEffect copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) => AsuperpassEffect(
    enabled: enabled ?? this.enabled,
    centerf: centerf ?? this.centerf,
    level: level ?? this.level,
    order: order ?? this.order,
    qfactor: qfactor ?? this.qfactor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperpassEffect &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperpassEffect(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(centerf >= centerfMin, 'asuperpass.centerf must be >= 2');
    assert(centerf <= centerfMax, 'asuperpass.centerf must be <= 999999');
    assert(level >= levelMin, 'asuperpass.level must be >= 0.0');
    assert(level <= levelMax, 'asuperpass.level must be <= 2.0');
    assert(order >= orderMin, 'asuperpass.order must be >= 4');
    assert(order <= orderMax, 'asuperpass.order must be <= 20');
    assert(qfactor >= qfactorMin, 'asuperpass.qfactor must be >= 0.01');
    assert(qfactor <= qfactorMax, 'asuperpass.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + _wireDouble(centerf));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + _wireDouble(qfactor));
    return parts.isEmpty
        ? 'lavfi-asuperpass'
        : 'lavfi-asuperpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsuperpassEffect prev) {
    final out = <(String, String)>[];
    if (centerf != prev.centerf) {
      out.add(('centerf', _wireDouble(centerf)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (qfactor != prev.qfactor) {
      out.add(('qfactor', _wireDouble(qfactor)));
    }
    return out;
  }
}

/// Configuration for the `asuperstop` audio effect.
///
/// Apply high order Butterworth band-stop filter.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [centerf]: Set center frequency in Hertz. Allowed range is 2 to 999999. Default value is 1000. (range 2..999999, default 1000, runtime-tunable)
/// - [level]: Set input gain level. Allowed range is from 0 to 2. Default value is 1. (range 0.0..2.0, default 1., runtime-tunable)
/// - [order]: Set filter order. Available values are from 4 to 20. Default value is 4. (range 4..20, default 4, runtime-tunable)
/// - [qfactor]: Set Q-factor. Allowed range is from 0.01 to 100. Default value is 1. (range 0.01..100.0, default 1., runtime-tunable)
final class AsuperstopEffect extends AudioEffect {
  /// Default value for [centerf].
  static const double centerfDefault = 1000.0;

  /// Minimum value for [centerf].
  static const double centerfMin = 2.0;

  /// Maximum value for [centerf].
  static const double centerfMax = 999999.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 2.0;

  /// Default value for [order].
  static const int orderDefault = 4;

  /// Minimum value for [order].
  static const int orderMin = 4;

  /// Maximum value for [order].
  static const int orderMax = 20;

  /// Default value for [qfactor].
  static const double qfactorDefault = 1.0;

  /// Minimum value for [qfactor].
  static const double qfactorMin = 0.01;

  /// Maximum value for [qfactor].
  static const double qfactorMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set center frequency
  final double centerf;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set Q-factor
  final double qfactor;

  /// Creates an [AsuperstopEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AsuperstopEffect({
    this.enabled = true,
    this.centerf = 1000.0,
    this.level = 1.0,
    this.order = 4,
    this.qfactor = 1.0,
  });

  @override
  String get filterName => 'asuperstop';

  @override
  AudioFilter get filter => AudioFilter.asuperstop;

  /// Returns a copy of this [AsuperstopEffect] with the given fields replaced.
  AsuperstopEffect copyWith({
    bool? enabled,
    double? centerf,
    double? level,
    int? order,
    double? qfactor,
  }) => AsuperstopEffect(
    enabled: enabled ?? this.enabled,
    centerf: centerf ?? this.centerf,
    level: level ?? this.level,
    order: order ?? this.order,
    qfactor: qfactor ?? this.qfactor,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AsuperstopEffect &&
          other.enabled == enabled &&
          other.centerf == centerf &&
          other.level == level &&
          other.order == order &&
          other.qfactor == qfactor);

  @override
  int get hashCode => Object.hash(enabled, centerf, level, order, qfactor);

  @override
  String toString() =>
      'AsuperstopEffect(enabled: $enabled, centerf: $centerf, level: $level, order: $order, qfactor: $qfactor)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(centerf >= centerfMin, 'asuperstop.centerf must be >= 2');
    assert(centerf <= centerfMax, 'asuperstop.centerf must be <= 999999');
    assert(level >= levelMin, 'asuperstop.level must be >= 0.0');
    assert(level <= levelMax, 'asuperstop.level must be <= 2.0');
    assert(order >= orderMin, 'asuperstop.order must be >= 4');
    assert(order <= orderMax, 'asuperstop.order must be <= 20');
    assert(qfactor >= qfactorMin, 'asuperstop.qfactor must be >= 0.01');
    assert(qfactor <= qfactorMax, 'asuperstop.qfactor must be <= 100.0');
    final parts = <String>[];
    if (centerf != 1000.0) parts.add('centerf=' + _wireDouble(centerf));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 4) parts.add('order=' + order.toString());
    if (qfactor != 1.0) parts.add('qfactor=' + _wireDouble(qfactor));
    return parts.isEmpty
        ? 'lavfi-asuperstop'
        : 'lavfi-asuperstop=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AsuperstopEffect prev) {
    final out = <(String, String)>[];
    if (centerf != prev.centerf) {
      out.add(('centerf', _wireDouble(centerf)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (qfactor != prev.qfactor) {
      out.add(('qfactor', _wireDouble(qfactor)));
    }
    return out;
  }
}

/// Configuration for the `atempo` audio effect.
///
/// Adjust audio tempo.
///
/// The filter accepts exactly one parameter, the audio tempo. If not
/// specified then the filter will assume nominal 1.0 tempo. Tempo must
/// be in the \[0.5, 100.0\] range.
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
/// - [tempo]: Change filter tempo scale factor. Syntax for the command is : "`tempo`" (range 0.5..100.0, default 1.0, runtime-tunable)
final class AtempoEffect extends AudioEffect {
  /// Default value for [tempo].
  static const double tempoDefault = 1.0;

  /// Minimum value for [tempo].
  static const double tempoMin = 0.5;

  /// Maximum value for [tempo].
  static const double tempoMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set tempo scale factor
  final double tempo;

  /// Creates an [AtempoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AtempoEffect({this.enabled = true, this.tempo = 1.0});

  @override
  String get filterName => 'atempo';

  @override
  AudioFilter get filter => AudioFilter.atempo;

  /// Returns a copy of this [AtempoEffect] with the given fields replaced.
  AtempoEffect copyWith({bool? enabled, double? tempo}) => AtempoEffect(
    enabled: enabled ?? this.enabled,
    tempo: tempo ?? this.tempo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AtempoEffect &&
          other.enabled == enabled &&
          other.tempo == tempo);

  @override
  int get hashCode => Object.hash(enabled, tempo);

  @override
  String toString() => 'AtempoEffect(enabled: $enabled, tempo: $tempo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(tempo >= tempoMin, 'atempo.tempo must be >= 0.5');
    assert(tempo <= tempoMax, 'atempo.tempo must be <= 100.0');
    final parts = <String>[];
    if (tempo != 1.0) parts.add('tempo=' + _wireDouble(tempo));
    return parts.isEmpty ? 'lavfi-atempo' : 'lavfi-atempo=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AtempoEffect prev) {
    final out = <(String, String)>[];
    if (tempo != prev.tempo) {
      out.add(('tempo', _wireDouble(tempo)));
    }
    return out;
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
/// - [freq]: Set central frequency of tilt in Hz. Default is 10000 Hz. (range 20..192000, default 10000, runtime-tunable)
/// - [level]: Set input volume level. Allowed range is from 0 to 4. Default is 1. (range 0.0..4.0, default 1., runtime-tunable)
/// - [order]: Set order of tilt filter. (range 2..30, default 5, runtime-tunable)
/// - [slope]: Set slope direction of tilt. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [width]: Set width of tilt. Default is 1000. Allowed range is from 100 to 10000. (range 100..10000, default 1000, runtime-tunable)
final class AtiltEffect extends AudioEffect {
  /// Default value for [freq].
  static const double freqDefault = 10000.0;

  /// Minimum value for [freq].
  static const double freqMin = 20.0;

  /// Maximum value for [freq].
  static const double freqMax = 192000.0;

  /// Default value for [level].
  static const double levelDefault = 1.0;

  /// Minimum value for [level].
  static const double levelMin = 0.0;

  /// Maximum value for [level].
  static const double levelMax = 4.0;

  /// Default value for [order].
  static const int orderDefault = 5;

  /// Minimum value for [order].
  static const int orderMin = 2;

  /// Maximum value for [order].
  static const int orderMax = 30;

  /// Default value for [slope].
  static const double slopeDefault = 0.0;

  /// Minimum value for [slope].
  static const double slopeMin = -1.0;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1000.0;

  /// Minimum value for [width].
  static const double widthMin = 100.0;

  /// Maximum value for [width].
  static const double widthMax = 10000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set central frequency
  final double freq;

  /// set input level
  final double level;

  /// set filter order
  final int order;

  /// set filter slope
  final double slope;

  /// set filter width
  final double width;

  /// Creates an [AtiltEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const AtiltEffect({
    this.enabled = true,
    this.freq = 10000.0,
    this.level = 1.0,
    this.order = 5,
    this.slope = 0.0,
    this.width = 1000.0,
  });

  @override
  String get filterName => 'atilt';

  @override
  AudioFilter get filter => AudioFilter.atilt;

  /// Returns a copy of this [AtiltEffect] with the given fields replaced.
  AtiltEffect copyWith({
    bool? enabled,
    double? freq,
    double? level,
    int? order,
    double? slope,
    double? width,
  }) => AtiltEffect(
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
      (other is AtiltEffect &&
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
      'AtiltEffect(enabled: $enabled, freq: $freq, level: $level, order: $order, slope: $slope, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(freq >= freqMin, 'atilt.freq must be >= 20');
    assert(freq <= freqMax, 'atilt.freq must be <= 192000');
    assert(level >= levelMin, 'atilt.level must be >= 0.0');
    assert(level <= levelMax, 'atilt.level must be <= 4.0');
    assert(order >= orderMin, 'atilt.order must be >= 2');
    assert(order <= orderMax, 'atilt.order must be <= 30');
    assert(slope >= slopeMin, 'atilt.slope must be >= -1');
    assert(slope <= slopeMax, 'atilt.slope must be <= 1');
    assert(width >= widthMin, 'atilt.width must be >= 100');
    assert(width <= widthMax, 'atilt.width must be <= 10000');
    final parts = <String>[];
    if (freq != 10000.0) parts.add('freq=' + _wireDouble(freq));
    if (level != 1.0) parts.add('level=' + _wireDouble(level));
    if (order != 5) parts.add('order=' + order.toString());
    if (slope != 0.0) parts.add('slope=' + _wireDouble(slope));
    if (width != 1000.0) parts.add('width=' + _wireDouble(width));
    return parts.isEmpty ? 'lavfi-atilt' : 'lavfi-atilt=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant AtiltEffect prev) {
    final out = <(String, String)>[];
    if (freq != prev.freq) {
      out.add(('freq', _wireDouble(freq)));
    }
    if (level != prev.level) {
      out.add(('level', _wireDouble(level)));
    }
    if (order != prev.order) {
      out.add(('order', order.toString()));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [csg]: Constant skirt gain if set to 1. Defaults to 0. (range 0..1, default 0, runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandpassEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// use constant skirt gain
  final bool csg;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandpassPrecision precision;

  /// set transform type
  final BandpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final BandpassWidthType widthType;

  /// Creates an [BandpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BandpassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.csg = false,
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BandpassPrecision.auto,
    this.transform = BandpassTransformType.di,
    this.width = 0.5,
    this.widthType = BandpassWidthType.q,
  });

  @override
  String get filterName => 'bandpass';

  @override
  AudioFilter get filter => AudioFilter.bandpass;

  /// Returns a copy of this [BandpassEffect] with the given fields replaced.
  BandpassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    bool? csg,
    double? frequency,
    double? mix,
    bool? normalize,
    BandpassPrecision? precision,
    BandpassTransformType? transform,
    double? width,
    BandpassWidthType? widthType,
  }) => BandpassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    csg: csg ?? this.csg,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandpassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.csg == csg &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    csg,
    frequency,
    mix,
    normalize,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'BandpassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, csg: $csg, frequency: $frequency, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'bandpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandpass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'bandpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'bandpass.mix must be >= 0');
    assert(mix <= mixMax, 'bandpass.mix must be <= 1');
    assert(width >= widthMin, 'bandpass.width must be >= 0');
    assert(width <= widthMax, 'bandpass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (csg != false) parts.add('csg=' + (csg ? '1' : '0'));
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BandpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != BandpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandpass'
        : 'lavfi-bandpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BandpassEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (csg != prev.csg) {
      out.add(('csg', (csg ? '1' : '0')));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency. Default is `3000`. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BandrejectEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BandrejectPrecision precision;

  /// set transform type
  final BandrejectTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final BandrejectWidthType widthType;

  /// Creates an [BandrejectEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BandrejectEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BandrejectPrecision.auto,
    this.transform = BandrejectTransformType.di,
    this.width = 0.5,
    this.widthType = BandrejectWidthType.q,
  });

  @override
  String get filterName => 'bandreject';

  @override
  AudioFilter get filter => AudioFilter.bandreject;

  /// Returns a copy of this [BandrejectEffect] with the given fields replaced.
  BandrejectEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    BandrejectPrecision? precision,
    BandrejectTransformType? transform,
    double? width,
    BandrejectWidthType? widthType,
  }) => BandrejectEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BandrejectEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    mix,
    normalize,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'BandrejectEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'bandreject.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bandreject.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'bandreject.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bandreject.frequency must be <= 999999');
    assert(mix >= mixMin, 'bandreject.mix must be >= 0');
    assert(mix <= mixMax, 'bandreject.mix must be <= 1');
    assert(width >= widthMin, 'bandreject.width must be >= 0');
    assert(width <= widthMax, 'bandreject.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BandrejectPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BandrejectTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != BandrejectWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-bandreject'
        : 'lavfi-bandreject=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BandrejectEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class BassEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 100.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final BassPrecision precision;

  /// set transform type
  final BassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final BassWidthType widthType;

  /// Creates an [BassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 100.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = BassPrecision.auto,
    this.transform = BassTransformType.di,
    this.width = 0.5,
    this.widthType = BassWidthType.q,
  });

  @override
  String get filterName => 'bass';

  @override
  AudioFilter get filter => AudioFilter.bass;

  /// Returns a copy of this [BassEffect] with the given fields replaced.
  BassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    int? poles,
    BassPrecision? precision,
    BassTransformType? transform,
    double? width,
    BassWidthType? widthType,
  }) => BassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'BassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'bass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'bass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'bass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'bass.frequency must be <= 999999');
    assert(gain >= gainMin, 'bass.gain must be >= -900');
    assert(gain <= gainMax, 'bass.gain must be <= 900');
    assert(mix >= mixMin, 'bass.mix must be >= 0');
    assert(mix <= mixMax, 'bass.mix must be <= 1');
    assert(poles >= polesMin, 'bass.poles must be >= 1');
    assert(poles <= polesMax, 'bass.poles must be <= 2');
    assert(width >= widthMin, 'bass.width must be >= 0');
    assert(width <= widthMax, 'bass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 100.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != BassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != BassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty ? 'lavfi-bass' : 'lavfi-bass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BassEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [a0]:  (range -2147483648..2147483647, default 1, runtime-tunable)
/// - [a1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [a2]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b0]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b1]:  (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [b2]: Change biquad parameter. Syntax for the command is : "`value`" (range -2147483648..2147483647, default 0, runtime-tunable)
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
final class BiquadEffect extends AudioEffect {
  /// Default value for [a0].
  static const double a0Default = 1.0;

  /// Minimum value for [a0].
  static const double a0Min = -2147483648.0;

  /// Maximum value for [a0].
  static const double a0Max = 2147483647.0;

  /// Default value for [a1].
  static const double a1Default = 0.0;

  /// Minimum value for [a1].
  static const double a1Min = -2147483648.0;

  /// Maximum value for [a1].
  static const double a1Max = 2147483647.0;

  /// Default value for [a2].
  static const double a2Default = 0.0;

  /// Minimum value for [a2].
  static const double a2Min = -2147483648.0;

  /// Maximum value for [a2].
  static const double a2Max = 2147483647.0;

  /// Default value for [b0].
  static const double b0Default = 0.0;

  /// Minimum value for [b0].
  static const double b0Min = -2147483648.0;

  /// Maximum value for [b0].
  static const double b0Max = 2147483647.0;

  /// Default value for [b1].
  static const double b1Default = 0.0;

  /// Minimum value for [b1].
  static const double b1Min = -2147483648.0;

  /// Maximum value for [b1].
  static const double b1Max = 2147483647.0;

  /// Default value for [b2].
  static const double b2Default = 0.0;

  /// Minimum value for [b2].
  static const double b2Min = -2147483648.0;

  /// Maximum value for [b2].
  static const double b2Max = 2147483647.0;

  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `a0` parameter.
  final double a0;

  /// The `a1` parameter.
  final double a1;

  /// The `a2` parameter.
  final double a2;

  /// The `b0` parameter.
  final double b0;

  /// The `b1` parameter.
  final double b1;

  /// The `b2` parameter.
  final double b2;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final BiquadPrecision precision;

  /// set transform type
  final BiquadTransformType transform;

  /// Creates an [BiquadEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const BiquadEffect({
    this.enabled = true,
    this.a0 = 1.0,
    this.a1 = 0.0,
    this.a2 = 0.0,
    this.b0 = 0.0,
    this.b1 = 0.0,
    this.b2 = 0.0,
    this.blocksize = 0,
    this.channels = 'all',
    this.mix = 1.0,
    this.normalize = false,
    this.precision = BiquadPrecision.auto,
    this.transform = BiquadTransformType.di,
  });

  @override
  String get filterName => 'biquad';

  @override
  AudioFilter get filter => AudioFilter.biquad;

  /// Returns a copy of this [BiquadEffect] with the given fields replaced.
  BiquadEffect copyWith({
    bool? enabled,
    double? a0,
    double? a1,
    double? a2,
    double? b0,
    double? b1,
    double? b2,
    int? blocksize,
    String? channels,
    double? mix,
    bool? normalize,
    BiquadPrecision? precision,
    BiquadTransformType? transform,
  }) => BiquadEffect(
    enabled: enabled ?? this.enabled,
    a0: a0 ?? this.a0,
    a1: a1 ?? this.a1,
    a2: a2 ?? this.a2,
    b0: b0 ?? this.b0,
    b1: b1 ?? this.b1,
    b2: b2 ?? this.b2,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiquadEffect &&
          other.enabled == enabled &&
          other.a0 == a0 &&
          other.a1 == a1 &&
          other.a2 == a2 &&
          other.b0 == b0 &&
          other.b1 == b1 &&
          other.b2 == b2 &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform);

  @override
  int get hashCode => Object.hash(
    enabled,
    a0,
    a1,
    a2,
    b0,
    b1,
    b2,
    blocksize,
    channels,
    mix,
    normalize,
    precision,
    transform,
  );

  @override
  String toString() =>
      'BiquadEffect(enabled: $enabled, a0: $a0, a1: $a1, a2: $a2, b0: $b0, b1: $b1, b2: $b2, blocksize: $blocksize, channels: $channels, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(a0 >= a0Min, 'biquad.a0 must be >= -2147483648');
    assert(a0 <= a0Max, 'biquad.a0 must be <= 2147483647');
    assert(a1 >= a1Min, 'biquad.a1 must be >= -2147483648');
    assert(a1 <= a1Max, 'biquad.a1 must be <= 2147483647');
    assert(a2 >= a2Min, 'biquad.a2 must be >= -2147483648');
    assert(a2 <= a2Max, 'biquad.a2 must be <= 2147483647');
    assert(b0 >= b0Min, 'biquad.b0 must be >= -2147483648');
    assert(b0 <= b0Max, 'biquad.b0 must be <= 2147483647');
    assert(b1 >= b1Min, 'biquad.b1 must be >= -2147483648');
    assert(b1 <= b1Max, 'biquad.b1 must be <= 2147483647');
    assert(b2 >= b2Min, 'biquad.b2 must be >= -2147483648');
    assert(b2 <= b2Max, 'biquad.b2 must be <= 2147483647');
    assert(blocksize >= blocksizeMin, 'biquad.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'biquad.blocksize must be <= 32768');
    assert(mix >= mixMin, 'biquad.mix must be >= 0');
    assert(mix <= mixMax, 'biquad.mix must be <= 1');
    final parts = <String>[];
    if (a0 != 1.0) parts.add('a0=' + _wireDouble(a0));
    if (a1 != 0.0) parts.add('a1=' + _wireDouble(a1));
    if (a2 != 0.0) parts.add('a2=' + _wireDouble(a2));
    if (b0 != 0.0) parts.add('b0=' + _wireDouble(b0));
    if (b1 != 0.0) parts.add('b1=' + _wireDouble(b1));
    if (b2 != 0.0) parts.add('b2=' + _wireDouble(b2));
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != BiquadPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != BiquadTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    return parts.isEmpty ? 'lavfi-biquad' : 'lavfi-biquad=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant BiquadEffect prev) {
    final out = <(String, String)>[];
    if (a0 != prev.a0) {
      out.add(('a0', _wireDouble(a0)));
    }
    if (a1 != prev.a1) {
      out.add(('a1', _wireDouble(a1)));
    }
    if (a2 != prev.a2) {
      out.add(('a2', _wireDouble(a2)));
    }
    if (b0 != prev.b0) {
      out.add(('b0', _wireDouble(b0)));
    }
    if (b1 != prev.b1) {
      out.add(('b1', _wireDouble(b1)));
    }
    if (b2 != prev.b2) {
      out.add(('b2', _wireDouble(b2)));
    }
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    return out;
  }
}

/// Configuration for the `channelmap` audio effect.
///
/// Remap input channels to new locations.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [channelLayout]: The channel layout of the output stream. If not specified, then filter will guess it based on the `out_channel` names or the number of mappings. Guessed layouts will not necessarily contain channels in the order of the mappings.
/// - [map]: Map channels from input to output. The argument is a '|'-separated list of mappings, each in the `@var{in_channel`-`out_channel`} or `@var{in_channel`} form. `in_channel` can be either the name of the input channel (e.g. FL for front left) or its index in the input channel layout. `out_channel` is the name of the output channel or its index in the output channel layout. If `out_channel` is not given then it is implicitly an index, starting with zero and increasing by one for each mapping. Mixing different types of mappings is not allowed and will result in a parse error.
final class ChannelmapEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Output channel layout.
  final String? channelLayout;

  /// A comma-separated list of input channel numbers in output order.
  final String map;

  /// Creates an [ChannelmapEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ChannelmapEffect({
    this.enabled = true,
    this.channelLayout,
    required this.map,
  });

  @override
  String get filterName => 'channelmap';

  @override
  AudioFilter get filter => AudioFilter.channelmap;

  /// Returns a copy of this [ChannelmapEffect] with the given fields replaced.
  ChannelmapEffect copyWith({
    bool? enabled,
    Object? channelLayout = unset,
    String? map,
  }) => ChannelmapEffect(
    enabled: enabled ?? this.enabled,
    channelLayout: identical(channelLayout, unset)
        ? this.channelLayout
        : channelLayout as String?,
    map: map ?? this.map,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChannelmapEffect &&
          other.enabled == enabled &&
          other.channelLayout == channelLayout &&
          other.map == map);

  @override
  int get hashCode => Object.hash(enabled, channelLayout, map);

  @override
  String toString() =>
      'ChannelmapEffect(enabled: $enabled, channelLayout: $channelLayout, map: $map)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (channelLayout != null)
      parts.add('channel_layout=' + '[' + channelLayout! + ']');
    parts.add('map=' + '[' + map + ']');
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
/// constant, with chorus, it is varied using sinusoidal or triangular modulation.
/// The modulation depth defines the range the modulated delay is played before or after
/// the delay. Hence the delayed sound will sound slower or faster, that is the delayed
/// sound tuned around the original one, like in a chorus where some vocals are slightly
/// off key.
///
/// It accepts the following parameters:
///
/// Parameters:
/// - [decays]: Set decays. (range 0..0, default "")
/// - [delays]: Set delays. A typical delay is around 40ms to 60ms. (range 0..0, default "")
/// - [depths]: Set depths. (range 0..0, default "")
/// - [inGain]: Set input gain. Default is 0.4. (range 0..1, default .4)
/// - [outGain]: Set output gain. Default is 0.4. (range 0..1, default .4)
/// - [speeds]: Set speeds. (range 0..0, default "")
final class ChorusEffect extends AudioEffect {
  /// Default value for [inGain].
  static const double inGainDefault = .4;

  /// Minimum value for [inGain].
  static const double inGainMin = 0.0;

  /// Maximum value for [inGain].
  static const double inGainMax = 1.0;

  /// Default value for [outGain].
  static const double outGainDefault = .4;

  /// Minimum value for [outGain].
  static const double outGainMin = 0.0;

  /// Maximum value for [outGain].
  static const double outGainMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set decays
  final String decays;

  /// set delays
  final String delays;

  /// set depths
  final String depths;

  /// set input gain
  final double inGain;

  /// set output gain
  final double outGain;

  /// set speeds
  final String speeds;

  /// Creates an [ChorusEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ChorusEffect({
    this.enabled = true,
    required this.decays,
    required this.delays,
    required this.depths,
    this.inGain = .4,
    this.outGain = .4,
    required this.speeds,
  });

  @override
  String get filterName => 'chorus';

  @override
  AudioFilter get filter => AudioFilter.chorus;

  /// Returns a copy of this [ChorusEffect] with the given fields replaced.
  ChorusEffect copyWith({
    bool? enabled,
    String? decays,
    String? delays,
    String? depths,
    double? inGain,
    double? outGain,
    String? speeds,
  }) => ChorusEffect(
    enabled: enabled ?? this.enabled,
    decays: decays ?? this.decays,
    delays: delays ?? this.delays,
    depths: depths ?? this.depths,
    inGain: inGain ?? this.inGain,
    outGain: outGain ?? this.outGain,
    speeds: speeds ?? this.speeds,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChorusEffect &&
          other.enabled == enabled &&
          other.decays == decays &&
          other.delays == delays &&
          other.depths == depths &&
          other.inGain == inGain &&
          other.outGain == outGain &&
          other.speeds == speeds);

  @override
  int get hashCode =>
      Object.hash(enabled, decays, delays, depths, inGain, outGain, speeds);

  @override
  String toString() =>
      'ChorusEffect(enabled: $enabled, decays: $decays, delays: $delays, depths: $depths, inGain: $inGain, outGain: $outGain, speeds: $speeds)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(inGain >= inGainMin, 'chorus.in_gain must be >= 0');
    assert(inGain <= inGainMax, 'chorus.in_gain must be <= 1');
    assert(outGain >= outGainMin, 'chorus.out_gain must be >= 0');
    assert(outGain <= outGainMax, 'chorus.out_gain must be <= 1');
    final parts = <String>[];
    parts.add('decays=' + '[' + decays + ']');
    parts.add('delays=' + '[' + delays + ']');
    parts.add('depths=' + '[' + depths + ']');
    if (inGain != .4) parts.add('in_gain=' + _wireDouble(inGain));
    if (outGain != .4) parts.add('out_gain=' + _wireDouble(outGain));
    parts.add('speeds=' + '[' + speeds + ']');
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
final class CompandEffect extends AudioEffect {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [volume].
  static const double volumeDefault = 0.0;

  /// Minimum value for [volume].
  static const double volumeMin = -900.0;

  /// Maximum value for [volume].
  static const double volumeMax = 0.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set time over which increase of volume is determined
  final String attacks;

  /// set time over which decrease of volume is determined
  final String decays;

  /// set delay for samples before sending them to volume adjuster
  final double delay;

  /// set output gain
  final double gain;

  /// set points of transfer function
  final String points;

  /// set initial volume
  final double volume;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [CompandEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CompandEffect({
    this.enabled = true,
    this.attacks = '0',
    this.decays = '0.8',
    this.delay = 0.0,
    this.gain = 0.0,
    this.points = '-70/-70|-60/-20|1/0',
    this.volume = 0.0,
    this.params = const <String, double>{},
  });

  @override
  String get filterName => 'compand';

  @override
  AudioFilter get filter => AudioFilter.compand;

  /// Returns a copy of this [CompandEffect] with the given fields replaced.
  CompandEffect copyWith({
    bool? enabled,
    String? attacks,
    String? decays,
    double? delay,
    double? gain,
    String? points,
    double? volume,
    Map<String, double>? params,
  }) => CompandEffect(
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
      (other is CompandEffect &&
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
      params.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'CompandEffect(enabled: $enabled, attacks: $attacks, decays: $decays, delay: $delay, gain: $gain, points: $points, volume: $volume, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(delay >= delayMin, 'compand.delay must be >= 0');
    assert(delay <= delayMax, 'compand.delay must be <= 20');
    assert(gain >= gainMin, 'compand.gain must be >= -900');
    assert(gain <= gainMax, 'compand.gain must be <= 900');
    assert(volume >= volumeMin, 'compand.volume must be >= -900');
    assert(volume <= volumeMax, 'compand.volume must be <= 0');
    final parts = <String>[];
    if (attacks != '0') parts.add('attacks=' + '[' + attacks + ']');
    if (decays != '0.8') parts.add('decays=' + '[' + decays + ']');
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (points != '-70/-70|-60/-20|1/0')
      parts.add('points=' + '[' + points + ']');
    if (volume != 0.0) parts.add('volume=' + _wireDouble(volume));
    params.forEach((k, v) => parts.add('$k=' + _wireDouble(v)));
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
final class CompensationdelayEffect extends AudioEffect {
  /// Default value for [cm].
  static const int cmDefault = 0;

  /// Minimum value for [cm].
  static const int cmMin = 0;

  /// Maximum value for [cm].
  static const int cmMax = 100;

  /// Default value for [dry].
  static const double dryDefault = 0.0;

  /// Minimum value for [dry].
  static const double dryMin = 0.0;

  /// Maximum value for [dry].
  static const double dryMax = 1.0;

  /// Default value for [m].
  static const int mDefault = 0;

  /// Minimum value for [m].
  static const int mMin = 0;

  /// Maximum value for [m].
  static const int mMax = 100;

  /// Default value for [mm].
  static const int mmDefault = 0;

  /// Minimum value for [mm].
  static const int mmMin = 0;

  /// Maximum value for [mm].
  static const int mmMax = 10;

  /// Default value for [temp].
  static const int tempDefault = 20;

  /// Minimum value for [temp].
  static const int tempMin = -50;

  /// Maximum value for [temp].
  static const int tempMax = 50;

  /// Default value for [wet].
  static const double wetDefault = 1.0;

  /// Minimum value for [wet].
  static const double wetMin = 0.0;

  /// Maximum value for [wet].
  static const double wetMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cm distance
  final int cm;

  /// set dry amount
  final double dry;

  /// set meter distance
  final int m;

  /// set mm distance
  final int mm;

  /// set temperature °C
  final int temp;

  /// set wet amount
  final double wet;

  /// Creates an [CompensationdelayEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CompensationdelayEffect({
    this.enabled = true,
    this.cm = 0,
    this.dry = 0.0,
    this.m = 0,
    this.mm = 0,
    this.temp = 20,
    this.wet = 1.0,
  });

  @override
  String get filterName => 'compensationdelay';

  @override
  AudioFilter get filter => AudioFilter.compensationdelay;

  /// Returns a copy of this [CompensationdelayEffect] with the given fields replaced.
  CompensationdelayEffect copyWith({
    bool? enabled,
    int? cm,
    double? dry,
    int? m,
    int? mm,
    int? temp,
    double? wet,
  }) => CompensationdelayEffect(
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
      (other is CompensationdelayEffect &&
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
      'CompensationdelayEffect(enabled: $enabled, cm: $cm, dry: $dry, m: $m, mm: $mm, temp: $temp, wet: $wet)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cm >= cmMin, 'compensationdelay.cm must be >= 0');
    assert(cm <= cmMax, 'compensationdelay.cm must be <= 100');
    assert(dry >= dryMin, 'compensationdelay.dry must be >= 0');
    assert(dry <= dryMax, 'compensationdelay.dry must be <= 1');
    assert(m >= mMin, 'compensationdelay.m must be >= 0');
    assert(m <= mMax, 'compensationdelay.m must be <= 100');
    assert(mm >= mmMin, 'compensationdelay.mm must be >= 0');
    assert(mm <= mmMax, 'compensationdelay.mm must be <= 10');
    assert(temp >= tempMin, 'compensationdelay.temp must be >= -50');
    assert(temp <= tempMax, 'compensationdelay.temp must be <= 50');
    assert(wet >= wetMin, 'compensationdelay.wet must be >= 0');
    assert(wet <= wetMax, 'compensationdelay.wet must be <= 1');
    final parts = <String>[];
    if (cm != 0) parts.add('cm=' + cm.toString());
    if (dry != 0.0) parts.add('dry=' + _wireDouble(dry));
    if (m != 0) parts.add('m=' + m.toString());
    if (mm != 0) parts.add('mm=' + mm.toString());
    if (temp != 20) parts.add('temp=' + temp.toString());
    if (wet != 1.0) parts.add('wet=' + _wireDouble(wet));
    return parts.isEmpty
        ? 'lavfi-compensationdelay'
        : 'lavfi-compensationdelay=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CompensationdelayEffect prev) {
    final out = <(String, String)>[];
    if (cm != prev.cm) return null;
    if (dry != prev.dry) return null;
    if (m != prev.m) return null;
    if (mm != prev.mm) return null;
    if (temp != prev.temp) return null;
    if (wet != prev.wet) return null;
    return out;
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
/// - [blockSize]: Set block size used for reverse IIR processing. If this value is set to high enough value (higher than impulse response length truncated when reaches near zero values) filtering will become linear phase otherwise if not big enough it will just produce nasty artifacts.  Note that filter delay will be exactly this many samples when set to non-zero value. (range 0..32768, default 0)
/// - [levelIn]: Set input gain. Default is 0.9. (range 0..1, default .9, runtime-tunable)
/// - [levelOut]: Set output gain. Default is 1. (range 0..1, default 1., runtime-tunable)
/// - [range]: Set soundstage wideness. Default is 0.5. Allowed range is from 0 to 1. This sets cut off frequency of low shelf filter. Default is cut off near 1550 Hz. With range set to 1 cut off frequency is set to 2100 Hz. (range 0..1, default .5, runtime-tunable)
/// - [slope]: Set curve slope of low shelf filter. Default is 0.5. Allowed range is from 0.01 to 1. (range .01..1, default .5, runtime-tunable)
/// - [strength]: Set strength of crossfeed. Default is 0.2. Allowed range is from 0 to 1. This sets gain of low shelf filter for side part of stereo image. Default is -6dB. Max allowed is -30db when strength is set to 1. (range 0..1, default .2, runtime-tunable)
final class CrossfeedEffect extends AudioEffect {
  /// Default value for [blockSize].
  static const int blockSizeDefault = 0;

  /// Minimum value for [blockSize].
  static const int blockSizeMin = 0;

  /// Maximum value for [blockSize].
  static const int blockSizeMax = 32768;

  /// Default value for [levelIn].
  static const double levelInDefault = .9;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 1.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 1.0;

  /// Default value for [range].
  static const double rangeDefault = .5;

  /// Minimum value for [range].
  static const double rangeMin = 0.0;

  /// Maximum value for [range].
  static const double rangeMax = 1.0;

  /// Default value for [slope].
  static const double slopeDefault = .5;

  /// Minimum value for [slope].
  static const double slopeMin = .01;

  /// Maximum value for [slope].
  static const double slopeMax = 1.0;

  /// Default value for [strength].
  static const double strengthDefault = .2;

  /// Minimum value for [strength].
  static const double strengthMin = 0.0;

  /// Maximum value for [strength].
  static const double strengthMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blockSize;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set soundstage wideness
  final double range;

  /// set curve slope
  final double slope;

  /// set crossfeed strength
  final double strength;

  /// Creates an [CrossfeedEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CrossfeedEffect({
    this.enabled = true,
    this.blockSize = 0,
    this.levelIn = .9,
    this.levelOut = 1.0,
    this.range = .5,
    this.slope = .5,
    this.strength = .2,
  });

  @override
  String get filterName => 'crossfeed';

  @override
  AudioFilter get filter => AudioFilter.crossfeed;

  /// Returns a copy of this [CrossfeedEffect] with the given fields replaced.
  CrossfeedEffect copyWith({
    bool? enabled,
    int? blockSize,
    double? levelIn,
    double? levelOut,
    double? range,
    double? slope,
    double? strength,
  }) => CrossfeedEffect(
    enabled: enabled ?? this.enabled,
    blockSize: blockSize ?? this.blockSize,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    range: range ?? this.range,
    slope: slope ?? this.slope,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrossfeedEffect &&
          other.enabled == enabled &&
          other.blockSize == blockSize &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.range == range &&
          other.slope == slope &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(
    enabled,
    blockSize,
    levelIn,
    levelOut,
    range,
    slope,
    strength,
  );

  @override
  String toString() =>
      'CrossfeedEffect(enabled: $enabled, blockSize: $blockSize, levelIn: $levelIn, levelOut: $levelOut, range: $range, slope: $slope, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blockSize >= blockSizeMin, 'crossfeed.block_size must be >= 0');
    assert(blockSize <= blockSizeMax, 'crossfeed.block_size must be <= 32768');
    assert(levelIn >= levelInMin, 'crossfeed.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'crossfeed.level_in must be <= 1');
    assert(levelOut >= levelOutMin, 'crossfeed.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'crossfeed.level_out must be <= 1');
    assert(range >= rangeMin, 'crossfeed.range must be >= 0');
    assert(range <= rangeMax, 'crossfeed.range must be <= 1');
    assert(slope >= slopeMin, 'crossfeed.slope must be >= .01');
    assert(slope <= slopeMax, 'crossfeed.slope must be <= 1');
    assert(strength >= strengthMin, 'crossfeed.strength must be >= 0');
    assert(strength <= strengthMax, 'crossfeed.strength must be <= 1');
    final parts = <String>[];
    if (blockSize != 0) parts.add('block_size=' + blockSize.toString());
    if (levelIn != .9) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (range != .5) parts.add('range=' + _wireDouble(range));
    if (slope != .5) parts.add('slope=' + _wireDouble(slope));
    if (strength != .2) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-crossfeed'
        : 'lavfi-crossfeed=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CrossfeedEffect prev) {
    final out = <(String, String)>[];
    if (blockSize != prev.blockSize) return null;
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (range != prev.range) {
      out.add(('range', _wireDouble(range)));
    }
    if (slope != prev.slope) {
      out.add(('slope', _wireDouble(slope)));
    }
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
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
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [i]: Sets the intensity of effect (default: 2.0). Must be in range between -10.0 to 0 (unchanged sound) to 10.0 (maximum effect). To inverse filtering use negative value. (range -10..10, default 2.0, runtime-tunable)
final class CrystalizerEffect extends AudioEffect {
  /// Default value for [i].
  static const double iDefault = 2.0;

  /// Minimum value for [i].
  static const double iMin = -10.0;

  /// Maximum value for [i].
  static const double iMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set intensity
  final double i;

  /// Creates an [CrystalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const CrystalizerEffect({this.enabled = true, this.c = true, this.i = 2.0});

  @override
  String get filterName => 'crystalizer';

  @override
  AudioFilter get filter => AudioFilter.crystalizer;

  /// Returns a copy of this [CrystalizerEffect] with the given fields replaced.
  CrystalizerEffect copyWith({bool? enabled, bool? c, double? i}) =>
      CrystalizerEffect(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        i: i ?? this.i,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CrystalizerEffect &&
          other.enabled == enabled &&
          other.c == c &&
          other.i == i);

  @override
  int get hashCode => Object.hash(enabled, c, i);

  @override
  String toString() => 'CrystalizerEffect(enabled: $enabled, c: $c, i: $i)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(i >= iMin, 'crystalizer.i must be >= -10');
    assert(i <= iMax, 'crystalizer.i must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (i != 2.0) parts.add('i=' + _wireDouble(i));
    return parts.isEmpty
        ? 'lavfi-crystalizer'
        : 'lavfi-crystalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant CrystalizerEffect prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (i != prev.i) {
      out.add(('i', _wireDouble(i)));
    }
    return out;
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
/// - [shift]: Set the DC shift, allowed range is \[-1, 1\]. It indicates the amount to shift the audio. (range -1..1, default 0)
final class DcshiftEffect extends AudioEffect {
  /// Default value for [limitergain].
  static const double limitergainDefault = 0.0;

  /// Minimum value for [limitergain].
  static const double limitergainMin = 0.0;

  /// Maximum value for [limitergain].
  static const double limitergainMax = 1.0;

  /// Default value for [shift].
  static const double shiftDefault = 0.0;

  /// Minimum value for [shift].
  static const double shiftMin = -1.0;

  /// Maximum value for [shift].
  static const double shiftMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set limiter gain
  final double limitergain;

  /// set DC shift
  final double shift;

  /// Creates an [DcshiftEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DcshiftEffect({
    this.enabled = true,
    this.limitergain = 0.0,
    this.shift = 0.0,
  });

  @override
  String get filterName => 'dcshift';

  @override
  AudioFilter get filter => AudioFilter.dcshift;

  /// Returns a copy of this [DcshiftEffect] with the given fields replaced.
  DcshiftEffect copyWith({bool? enabled, double? limitergain, double? shift}) =>
      DcshiftEffect(
        enabled: enabled ?? this.enabled,
        limitergain: limitergain ?? this.limitergain,
        shift: shift ?? this.shift,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DcshiftEffect &&
          other.enabled == enabled &&
          other.limitergain == limitergain &&
          other.shift == shift);

  @override
  int get hashCode => Object.hash(enabled, limitergain, shift);

  @override
  String toString() =>
      'DcshiftEffect(enabled: $enabled, limitergain: $limitergain, shift: $shift)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(limitergain >= limitergainMin, 'dcshift.limitergain must be >= 0');
    assert(limitergain <= limitergainMax, 'dcshift.limitergain must be <= 1');
    assert(shift >= shiftMin, 'dcshift.shift must be >= -1');
    assert(shift <= shiftMax, 'dcshift.shift must be <= 1');
    final parts = <String>[];
    if (limitergain != 0.0)
      parts.add('limitergain=' + _wireDouble(limitergain));
    if (shift != 0.0) parts.add('shift=' + _wireDouble(shift));
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
/// - [s]: Set the output mode.  It accepts the following values: (range 0..2, default OUT_MODE)
final class DeesserEffect extends AudioEffect {
  /// Default value for [f].
  static const double fDefault = 0.5;

  /// Minimum value for [f].
  static const double fMin = 0.0;

  /// Maximum value for [f].
  static const double fMax = 1.0;

  /// Default value for [i].
  static const double iDefault = 0.0;

  /// Minimum value for [i].
  static const double iMin = 0.0;

  /// Maximum value for [i].
  static const double iMax = 1.0;

  /// Default value for [m].
  static const double mDefault = 0.5;

  /// Minimum value for [m].
  static const double mMin = 0.0;

  /// Maximum value for [m].
  static const double mMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set frequency
  final double f;

  /// set intensity
  final double i;

  /// set max deessing
  final double m;

  /// set output mode
  final DeesserMode s;

  /// Creates an [DeesserEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DeesserEffect({
    this.enabled = true,
    this.f = 0.5,
    this.i = 0.0,
    this.m = 0.5,
    this.s = DeesserMode.o,
  });

  @override
  String get filterName => 'deesser';

  @override
  AudioFilter get filter => AudioFilter.deesser;

  /// Returns a copy of this [DeesserEffect] with the given fields replaced.
  DeesserEffect copyWith({
    bool? enabled,
    double? f,
    double? i,
    double? m,
    DeesserMode? s,
  }) => DeesserEffect(
    enabled: enabled ?? this.enabled,
    f: f ?? this.f,
    i: i ?? this.i,
    m: m ?? this.m,
    s: s ?? this.s,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeesserEffect &&
          other.enabled == enabled &&
          other.f == f &&
          other.i == i &&
          other.m == m &&
          other.s == s);

  @override
  int get hashCode => Object.hash(enabled, f, i, m, s);

  @override
  String toString() =>
      'DeesserEffect(enabled: $enabled, f: $f, i: $i, m: $m, s: $s)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(f >= fMin, 'deesser.f must be >= 0.0');
    assert(f <= fMax, 'deesser.f must be <= 1.0');
    assert(i >= iMin, 'deesser.i must be >= 0.0');
    assert(i <= iMax, 'deesser.i must be <= 1.0');
    assert(m >= mMin, 'deesser.m must be >= 0.0');
    assert(m <= mMax, 'deesser.m must be <= 1.0');
    final parts = <String>[];
    if (f != 0.5) parts.add('f=' + _wireDouble(f));
    if (i != 0.0) parts.add('i=' + _wireDouble(i));
    if (m != 0.5) parts.add('m=' + _wireDouble(m));
    if (s != DeesserMode.o) parts.add('s=' + s.mpvValue);
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
/// - [enhance]: Set the dialogue enhance factor to put in front center channel output. Allowed range is from 0 to 3. Default value is 1. (range 0..3, default 1, runtime-tunable)
/// - [original]: Set the original center factor to keep in front center channel output. Allowed range is from 0 to 1. Default value is 1. (range 0..1, default 1, runtime-tunable)
/// - [voice]: Set the voice detection factor. Allowed range is from 2 to 32. Default value is 2. (range 2..32, default 2, runtime-tunable)
final class DialoguenhanceEffect extends AudioEffect {
  /// Default value for [enhance].
  static const double enhanceDefault = 1.0;

  /// Minimum value for [enhance].
  static const double enhanceMin = 0.0;

  /// Maximum value for [enhance].
  static const double enhanceMax = 3.0;

  /// Default value for [original].
  static const double originalDefault = 1.0;

  /// Minimum value for [original].
  static const double originalMin = 0.0;

  /// Maximum value for [original].
  static const double originalMax = 1.0;

  /// Default value for [voice].
  static const double voiceDefault = 2.0;

  /// Minimum value for [voice].
  static const double voiceMin = 2.0;

  /// Maximum value for [voice].
  static const double voiceMax = 32.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set dialogue enhance factor
  final double enhance;

  /// set original center factor
  final double original;

  /// set voice detection factor
  final double voice;

  /// Creates an [DialoguenhanceEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DialoguenhanceEffect({
    this.enabled = true,
    this.enhance = 1.0,
    this.original = 1.0,
    this.voice = 2.0,
  });

  @override
  String get filterName => 'dialoguenhance';

  @override
  AudioFilter get filter => AudioFilter.dialoguenhance;

  /// Returns a copy of this [DialoguenhanceEffect] with the given fields replaced.
  DialoguenhanceEffect copyWith({
    bool? enabled,
    double? enhance,
    double? original,
    double? voice,
  }) => DialoguenhanceEffect(
    enabled: enabled ?? this.enabled,
    enhance: enhance ?? this.enhance,
    original: original ?? this.original,
    voice: voice ?? this.voice,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DialoguenhanceEffect &&
          other.enabled == enabled &&
          other.enhance == enhance &&
          other.original == original &&
          other.voice == voice);

  @override
  int get hashCode => Object.hash(enabled, enhance, original, voice);

  @override
  String toString() =>
      'DialoguenhanceEffect(enabled: $enabled, enhance: $enhance, original: $original, voice: $voice)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(enhance >= enhanceMin, 'dialoguenhance.enhance must be >= 0');
    assert(enhance <= enhanceMax, 'dialoguenhance.enhance must be <= 3');
    assert(original >= originalMin, 'dialoguenhance.original must be >= 0');
    assert(original <= originalMax, 'dialoguenhance.original must be <= 1');
    assert(voice >= voiceMin, 'dialoguenhance.voice must be >= 2');
    assert(voice <= voiceMax, 'dialoguenhance.voice must be <= 32');
    final parts = <String>[];
    if (enhance != 1.0) parts.add('enhance=' + _wireDouble(enhance));
    if (original != 1.0) parts.add('original=' + _wireDouble(original));
    if (voice != 2.0) parts.add('voice=' + _wireDouble(voice));
    return parts.isEmpty
        ? 'lavfi-dialoguenhance'
        : 'lavfi-dialoguenhance=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant DialoguenhanceEffect prev) {
    final out = <(String, String)>[];
    if (enhance != prev.enhance) {
      out.add(('enhance', _wireDouble(enhance)));
    }
    if (original != prev.original) {
      out.add(('original', _wireDouble(original)));
    }
    if (voice != prev.voice) {
      out.add(('voice', _wireDouble(voice)));
    }
    return out;
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
/// - [length]: Set window length in seconds used to split audio into segments of equal length. Default is 3 seconds. (range .01..10, default 3)
final class DrmeterEffect extends AudioEffect {
  /// Default value for [length].
  static const double lengthDefault = 3.0;

  /// Minimum value for [length].
  static const double lengthMin = .01;

  /// Maximum value for [length].
  static const double lengthMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the window length
  final double length;

  /// Creates an [DrmeterEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DrmeterEffect({this.enabled = true, this.length = 3.0});

  @override
  String get filterName => 'drmeter';

  @override
  AudioFilter get filter => AudioFilter.drmeter;

  /// Returns a copy of this [DrmeterEffect] with the given fields replaced.
  DrmeterEffect copyWith({bool? enabled, double? length}) => DrmeterEffect(
    enabled: enabled ?? this.enabled,
    length: length ?? this.length,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DrmeterEffect &&
          other.enabled == enabled &&
          other.length == length);

  @override
  int get hashCode => Object.hash(enabled, length);

  @override
  String toString() => 'DrmeterEffect(enabled: $enabled, length: $length)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(length >= lengthMin, 'drmeter.length must be >= .01');
    assert(length <= lengthMax, 'drmeter.length must be <= 10');
    final parts = <String>[];
    if (length != 3.0) parts.add('length=' + _wireDouble(length));
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
/// - [altboundary]: Enable alternative boundary mode. By default is disabled. The Dynamic Audio Normalizer takes into account a certain neighbourhood around each frame. This includes the preceding frames as well as the subsequent frames. However, for the "boundary" frames, located at the very beginning and at the very end of the audio file, not all neighbouring frames are available. In particular, for the first few frames in the audio file, the preceding frames are not known. And, similarly, for the last few frames in the audio file, the subsequent frames are not known. Thus, the question arises which gain factors should be assumed for the missing frames in the "boundary" region. The Dynamic Audio Normalizer implements two modes to deal with this situation. The default boundary mode assumes a gain factor of exactly 1.0 for the missing frames, resulting in a smooth "fade in" and "fade out" at the beginning and at the end of the input, respectively. (range 0..1, default 0, runtime-tunable)
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compress]: Set the compress factor. In range from 0.0 to 30.0. Default is 0.0. By default, the Dynamic Audio Normalizer does not apply "traditional" compression. This means that signal peaks will not be pruned and thus the full dynamic range will be retained within each local neighbourhood. However, in some cases it may be desirable to combine the Dynamic Audio Normalizer's normalization algorithm with a more "traditional" compression. For this purpose, the Dynamic Audio Normalizer provides an optional compression (thresholding) function. If (and only if) the compression feature is enabled, all input frames will be processed by a soft knee thresholding function prior to the actual normalization process. Put simply, the thresholding function is going to prune all samples whose magnitude exceeds a certain threshold value. However, the Dynamic Audio Normalizer does not simply apply a fixed threshold value. Instead, the threshold value will be adjusted for each individual frame. In general, smaller parameters result in stronger compression, and vice versa. Values below 3.0 are not recommended, because audible distortion may appear. (range 0.0..30.0, default 0.0, runtime-tunable)
/// - [correctdc]: Enable DC bias correction. By default is disabled. An audio signal (in the time domain) is a sequence of sample values. In the Dynamic Audio Normalizer these sample values are represented in the -1.0 to 1.0 range, regardless of the original input format. Normally, the audio signal, or "waveform", should be centered around the zero point. That means if we calculate the mean value of all samples in a file, or in a single frame, then the result should be 0.0 or at least very close to that value. If, however, there is a significant deviation of the mean value from 0.0, in either positive or negative direction, this is referred to as a DC bias or DC offset. Since a DC bias is clearly undesirable, the Dynamic Audio Normalizer provides optional DC bias correction. With DC bias correction enabled, the Dynamic Audio Normalizer will determine the mean value, or "DC correction" offset, of each input frame and subtract that value from all of the frame's sample values which ensures those samples are centered around 0.0 again. Also, in order to avoid "gaps" at the frame boundaries, the DC correction offset values will be interpolated smoothly between neighbouring frames. (range 0..1, default 0, runtime-tunable)
/// - [coupling]: Enable channels coupling. By default is enabled. By default, the Dynamic Audio Normalizer will amplify all channels by the same amount. This means the same gain factor will be applied to all channels, i.e. the maximum possible gain factor is determined by the "loudest" channel. However, in some recordings, it may happen that the volume of the different channels is uneven, e.g. one channel may be "quieter" than the other one(s). In this case, this option can be used to disable the channel coupling. This way, the gain factor will be determined independently for each channel, depending only on the individual channel's highest magnitude sample. This allows for harmonizing the volume of the different channels. (range 0..1, default 1, runtime-tunable)
/// - [curve]: Specify the peak mapping curve expression which is going to be used when calculating gain applied to frames. The max output frame gain will still be limited by other options mentioned previously for this filter.  The expression can contain the following constants: (default "", runtime-tunable)
/// - [framelen]: Set the frame length in milliseconds. In range from 10 to 8000 milliseconds. Default is 500 milliseconds. The Dynamic Audio Normalizer processes the input audio in small chunks, referred to as frames. This is required, because a peak magnitude has no meaning for just a single sample value. Instead, we need to determine the peak magnitude for a contiguous sequence of sample values. While a "standard" normalizer would simply use the peak magnitude of the complete file, the Dynamic Audio Normalizer determines the peak magnitude individually for each frame. The length of a frame is specified in milliseconds. By default, the Dynamic Audio Normalizer uses a frame length of 500 milliseconds, which has been found to give good results with most files. Note that the exact frame length, in number of samples, will be determined automatically, based on the sampling rate of the individual input audio file. (range 10..8000, default 500, runtime-tunable)
/// - [gausssize]: Set the Gaussian filter window size. In range from 3 to 301, must be odd number. Default is 31. Probably the most important parameter of the Dynamic Audio Normalizer is the `window size` of the Gaussian smoothing filter. The filter's window size is specified in frames, centered around the current frame. For the sake of simplicity, this must be an odd number. Consequently, the default value of 31 takes into account the current frame, as well as the 15 preceding frames and the 15 subsequent frames. Using a larger window results in a stronger smoothing effect and thus in less gain variation, i.e. slower gain adaptation. Conversely, using a smaller window results in a weaker smoothing effect and thus in more gain variation, i.e. faster gain adaptation. In other words, the more you increase this value, the more the Dynamic Audio Normalizer will behave like a "traditional" normalization filter. On the contrary, the more you decrease this value, the more the Dynamic Audio Normalizer will behave like a dynamic range compressor. (range 3..301, default 31, runtime-tunable)
/// - [maxgain]: Set the maximum gain factor. In range from 1.0 to 100.0. Default is 10.0. The Dynamic Audio Normalizer determines the maximum possible (local) gain factor for each input frame, i.e. the maximum gain factor that does not result in clipping or distortion. The maximum gain factor is determined by the frame's highest magnitude sample. However, the Dynamic Audio Normalizer additionally bounds the frame's maximum gain factor by a predetermined (global) maximum gain factor. This is done in order to avoid excessive gain factors in "silent" or almost silent frames. By default, the maximum gain factor is 10.0, For most inputs the default value should be sufficient and it usually is not recommended to increase this value. Though, for input with an extremely low overall volume level, it may be necessary to allow even higher gain factors. Note, however, that the Dynamic Audio Normalizer does not simply apply a "hard" threshold (i.e. cut off values above the threshold). Instead, a "sigmoid" threshold function will be applied. This way, the gain factors will smoothly approach the threshold value, but never exceed that value. (range 1.0..100.0, default 10.0, runtime-tunable)
/// - [overlap]: Specify overlap for frames. If set to 0 (default) no frame overlapping is done. Using >0 and <1 values will make less conservative gain adjustments, like when framelen option is set to smaller value, if framelen option value is compensated for non-zero overlap then gain adjustments will be smoother across time compared to zero overlap case. (range 0.0..1.0, default .0, runtime-tunable)
/// - [peak]: Set the target peak value. This specifies the highest permissible magnitude level for the normalized audio input. This filter will try to approach the target peak magnitude as closely as possible, but at the same time it also makes sure that the normalized signal will never exceed the peak magnitude. A frame's maximum local gain factor is imposed directly by the target peak magnitude. The default value is 0.95 and thus leaves a headroom of 5%*. It is not recommended to go above this value. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [targetrms]: Set the target RMS. In range from 0.0 to 1.0. Default is 0.0 - disabled. By default, the Dynamic Audio Normalizer performs "peak" normalization. This means that the maximum local gain factor for each frame is defined (only) by the frame's highest magnitude sample. This way, the samples can be amplified as much as possible without exceeding the maximum signal level, i.e. without clipping. Optionally, however, the Dynamic Audio Normalizer can also take into account the frame's root mean square, abbreviated RMS. In electrical engineering, the RMS is commonly used to determine the power of a time-varying signal. It is therefore considered that the RMS is a better approximation of the "perceived loudness" than just looking at the signal's peak magnitude. Consequently, by adjusting all frames to a constant RMS value, a uniform "perceived loudness" can be established. If a target RMS value has been specified, a frame's local gain factor is defined as the factor that would result in exactly that RMS value. Note, however, that the maximum local gain factor is still restricted by the frame's highest magnitude sample, in order to prevent clipping. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [threshold]: Set the target threshold value. This specifies the lowest permissible magnitude level for the audio input which will be normalized. If input frame volume is above this value frame will be normalized. Otherwise frame may not be normalized at all. The default value is set to 0, which means all input frames will be normalized. This option is mostly useful if digital noise is not wanted to be amplified. (range 0.0..1.0, default 0.0, runtime-tunable)
final class DynaudnormEffect extends AudioEffect {
  /// Default value for [compress].
  static const double compressDefault = 0.0;

  /// Minimum value for [compress].
  static const double compressMin = 0.0;

  /// Maximum value for [compress].
  static const double compressMax = 30.0;

  /// Default value for [framelen].
  static const int framelenDefault = 500;

  /// Minimum value for [framelen].
  static const int framelenMin = 10;

  /// Maximum value for [framelen].
  static const int framelenMax = 8000;

  /// Default value for [gausssize].
  static const int gausssizeDefault = 31;

  /// Minimum value for [gausssize].
  static const int gausssizeMin = 3;

  /// Maximum value for [gausssize].
  static const int gausssizeMax = 301;

  /// Default value for [maxgain].
  static const double maxgainDefault = 10.0;

  /// Minimum value for [maxgain].
  static const double maxgainMin = 1.0;

  /// Maximum value for [maxgain].
  static const double maxgainMax = 100.0;

  /// Default value for [overlap].
  static const double overlapDefault = .0;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

  /// Default value for [targetrms].
  static const double targetrmsDefault = 0.0;

  /// Minimum value for [targetrms].
  static const double targetrmsMin = 0.0;

  /// Maximum value for [targetrms].
  static const double targetrmsMax = 1.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set alternative boundary mode
  final bool altboundary;

  /// set channels to filter
  final String channels;

  /// set the compress factor
  final double compress;

  /// set DC correction
  final bool correctdc;

  /// set channel coupling
  final bool coupling;

  /// set the custom peak mapping curve
  final String curve;

  /// set the frame length in msec
  final int framelen;

  /// set the filter size
  final int gausssize;

  /// set the max amplification
  final double maxgain;

  /// set the frame overlap
  final double overlap;

  /// set the peak value
  final double peak;

  /// set the target RMS
  final double targetrms;

  /// set the threshold value
  final double threshold;

  /// Creates an [DynaudnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const DynaudnormEffect({
    this.enabled = true,
    this.altboundary = false,
    this.channels = 'all',
    this.compress = 0.0,
    this.correctdc = false,
    this.coupling = true,
    this.curve = '',
    this.framelen = 500,
    this.gausssize = 31,
    this.maxgain = 10.0,
    this.overlap = .0,
    this.peak = 0.95,
    this.targetrms = 0.0,
    this.threshold = 0.0,
  });

  @override
  String get filterName => 'dynaudnorm';

  @override
  AudioFilter get filter => AudioFilter.dynaudnorm;

  /// Returns a copy of this [DynaudnormEffect] with the given fields replaced.
  DynaudnormEffect copyWith({
    bool? enabled,
    bool? altboundary,
    String? channels,
    double? compress,
    bool? correctdc,
    bool? coupling,
    String? curve,
    int? framelen,
    int? gausssize,
    double? maxgain,
    double? overlap,
    double? peak,
    double? targetrms,
    double? threshold,
  }) => DynaudnormEffect(
    enabled: enabled ?? this.enabled,
    altboundary: altboundary ?? this.altboundary,
    channels: channels ?? this.channels,
    compress: compress ?? this.compress,
    correctdc: correctdc ?? this.correctdc,
    coupling: coupling ?? this.coupling,
    curve: curve ?? this.curve,
    framelen: framelen ?? this.framelen,
    gausssize: gausssize ?? this.gausssize,
    maxgain: maxgain ?? this.maxgain,
    overlap: overlap ?? this.overlap,
    peak: peak ?? this.peak,
    targetrms: targetrms ?? this.targetrms,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DynaudnormEffect &&
          other.enabled == enabled &&
          other.altboundary == altboundary &&
          other.channels == channels &&
          other.compress == compress &&
          other.correctdc == correctdc &&
          other.coupling == coupling &&
          other.curve == curve &&
          other.framelen == framelen &&
          other.gausssize == gausssize &&
          other.maxgain == maxgain &&
          other.overlap == overlap &&
          other.peak == peak &&
          other.targetrms == targetrms &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    altboundary,
    channels,
    compress,
    correctdc,
    coupling,
    curve,
    framelen,
    gausssize,
    maxgain,
    overlap,
    peak,
    targetrms,
    threshold,
  );

  @override
  String toString() =>
      'DynaudnormEffect(enabled: $enabled, altboundary: $altboundary, channels: $channels, compress: $compress, correctdc: $correctdc, coupling: $coupling, curve: $curve, framelen: $framelen, gausssize: $gausssize, maxgain: $maxgain, overlap: $overlap, peak: $peak, targetrms: $targetrms, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(compress >= compressMin, 'dynaudnorm.compress must be >= 0.0');
    assert(compress <= compressMax, 'dynaudnorm.compress must be <= 30.0');
    assert(framelen >= framelenMin, 'dynaudnorm.framelen must be >= 10');
    assert(framelen <= framelenMax, 'dynaudnorm.framelen must be <= 8000');
    assert(gausssize >= gausssizeMin, 'dynaudnorm.gausssize must be >= 3');
    assert(gausssize <= gausssizeMax, 'dynaudnorm.gausssize must be <= 301');
    assert(maxgain >= maxgainMin, 'dynaudnorm.maxgain must be >= 1.0');
    assert(maxgain <= maxgainMax, 'dynaudnorm.maxgain must be <= 100.0');
    assert(overlap >= overlapMin, 'dynaudnorm.overlap must be >= 0.0');
    assert(overlap <= overlapMax, 'dynaudnorm.overlap must be <= 1.0');
    assert(peak >= peakMin, 'dynaudnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'dynaudnorm.peak must be <= 1.0');
    assert(targetrms >= targetrmsMin, 'dynaudnorm.targetrms must be >= 0.0');
    assert(targetrms <= targetrmsMax, 'dynaudnorm.targetrms must be <= 1.0');
    assert(threshold >= thresholdMin, 'dynaudnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'dynaudnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (altboundary != false)
      parts.add('altboundary=' + (altboundary ? '1' : '0'));
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (compress != 0.0) parts.add('compress=' + _wireDouble(compress));
    if (correctdc != false) parts.add('correctdc=' + (correctdc ? '1' : '0'));
    if (coupling != true) parts.add('coupling=' + (coupling ? '1' : '0'));
    if (curve != '') parts.add('curve=' + '[' + curve + ']');
    if (framelen != 500) parts.add('framelen=' + framelen.toString());
    if (gausssize != 31) parts.add('gausssize=' + gausssize.toString());
    if (maxgain != 10.0) parts.add('maxgain=' + _wireDouble(maxgain));
    if (overlap != .0) parts.add('overlap=' + _wireDouble(overlap));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (targetrms != 0.0) parts.add('targetrms=' + _wireDouble(targetrms));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-dynaudnorm'
        : 'lavfi-dynaudnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant DynaudnormEffect prev) {
    final out = <(String, String)>[];
    if (altboundary != prev.altboundary) {
      out.add(('altboundary', (altboundary ? '1' : '0')));
    }
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (compress != prev.compress) {
      out.add(('compress', _wireDouble(compress)));
    }
    if (correctdc != prev.correctdc) {
      out.add(('correctdc', (correctdc ? '1' : '0')));
    }
    if (coupling != prev.coupling) {
      out.add(('coupling', (coupling ? '1' : '0')));
    }
    if (curve != prev.curve) {
      out.add(('curve', curve));
    }
    if (framelen != prev.framelen) {
      out.add(('framelen', framelen.toString()));
    }
    if (gausssize != prev.gausssize) {
      out.add(('gausssize', gausssize.toString()));
    }
    if (maxgain != prev.maxgain) {
      out.add(('maxgain', _wireDouble(maxgain)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (targetrms != prev.targetrms) {
      out.add(('targetrms', _wireDouble(targetrms)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
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
final class EarwaxEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Creates an [EarwaxEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const EarwaxEffect({this.enabled = true});

  @override
  String get filterName => 'earwax';

  @override
  AudioFilter get filter => AudioFilter.earwax;

  /// Returns a copy of this [EarwaxEffect] with the given fields replaced.
  EarwaxEffect copyWith({bool? enabled}) =>
      EarwaxEffect(enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EarwaxEffect && other.enabled == enabled);

  @override
  int get hashCode => enabled.hashCode;

  @override
  String toString() => 'EarwaxEffect(enabled: $enabled)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
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
/// - [framelog]: Force the frame logging level.  Available values are: (range -2147483648..2147483647, default -1)
/// - [gauge]: set gauge display type (range 0..1, default 0)
/// - [metadata]: Set metadata injection. If set to `1`, the audio input will be segmented into 100ms output frames, each of them containing various loudness information in metadata.  All the metadata keys are prefixed with `lavfi.r128.`.  Default is `0`. (range 0..1, default 0)
/// - [meter]: Set the EBU scale meter. Default is `9`. Common values are `9` and `18`, respectively for EBU scale meter +9 and EBU scale meter +18. Any other integer value between this range is allowed. (range 9..18, default 9)
/// - [panlaw]: set a specific pan law for dual-mono files (range -10.0..0.0, default -3.01029995663978)
/// - [peak]: set peak mode (range 0..2147483647, default PEAK_MODE_NONE)
/// - [scale]: sets display method for the stats (range 0..1, default 0)
/// - [size]: Set the video size. This option is for video only. For the syntax of this option, check the video size syntax. Default and minimum resolution is `640x480`. (range 0..0, default "640x480")
/// - [target]: set a specific target level in LUFS (-23 to 0) (range -23..0, default -23)
/// - [video]: Activate the video output. The audio stream is passed unchanged whether this option is set or no. The video stream will be the first output stream if activated. Default is `0`. (range 0..1, default 0)
final class Ebur128Effect extends AudioEffect {
  /// Default value for [meter].
  static const int meterDefault = 9;

  /// Minimum value for [meter].
  static const int meterMin = 9;

  /// Maximum value for [meter].
  static const int meterMax = 18;

  /// Default value for [panlaw].
  static const double panlawDefault = -3.01029995663978;

  /// Minimum value for [panlaw].
  static const double panlawMin = -10.0;

  /// Maximum value for [panlaw].
  static const double panlawMax = 0.0;

  /// Default value for [target].
  static const int targetDefault = -23;

  /// Minimum value for [target].
  static const int targetMin = -23;

  /// Maximum value for [target].
  static const int targetMax = 0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// treat mono input files as dual-mono
  final bool dualmono;

  /// force frame logging level
  final Ebur128Level? framelog;

  /// set gauge display type
  final Ebur128Gaugetype gauge;

  /// inject metadata in the filtergraph
  final bool metadata;

  /// set scale meter (+9 to +18)
  final int meter;

  /// set a specific pan law for dual-mono files
  final double panlaw;

  /// set peak mode
  final Set<Ebur128Mode> peak;

  /// sets display method for the stats
  final Ebur128Scaletype scale;

  /// set video size
  final String size;

  /// set a specific target level in LUFS (-23 to 0)
  final int target;

  /// set video output
  final bool video;

  /// Creates an [Ebur128Effect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const Ebur128Effect({
    this.enabled = true,
    this.dualmono = false,
    this.framelog,
    this.gauge = Ebur128Gaugetype.momentary,
    this.metadata = false,
    this.meter = 9,
    this.panlaw = -3.01029995663978,
    this.peak = const <Ebur128Mode>{},
    this.scale = Ebur128Scaletype.absolute,
    this.size = '640x480',
    this.target = -23,
    this.video = false,
  });

  @override
  String get filterName => 'ebur128';

  @override
  AudioFilter get filter => AudioFilter.ebur128;

  /// Returns a copy of this [Ebur128Effect] with the given fields replaced.
  Ebur128Effect copyWith({
    bool? enabled,
    bool? dualmono,
    Object? framelog = unset,
    Ebur128Gaugetype? gauge,
    bool? metadata,
    int? meter,
    double? panlaw,
    Set<Ebur128Mode>? peak,
    Ebur128Scaletype? scale,
    String? size,
    int? target,
    bool? video,
  }) => Ebur128Effect(
    enabled: enabled ?? this.enabled,
    dualmono: dualmono ?? this.dualmono,
    framelog: identical(framelog, unset)
        ? this.framelog
        : framelog as Ebur128Level?,
    gauge: gauge ?? this.gauge,
    metadata: metadata ?? this.metadata,
    meter: meter ?? this.meter,
    panlaw: panlaw ?? this.panlaw,
    peak: peak ?? this.peak,
    scale: scale ?? this.scale,
    size: size ?? this.size,
    target: target ?? this.target,
    video: video ?? this.video,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Ebur128Effect &&
          other.enabled == enabled &&
          other.dualmono == dualmono &&
          other.framelog == framelog &&
          other.gauge == gauge &&
          other.metadata == metadata &&
          other.meter == meter &&
          other.panlaw == panlaw &&
          _setEq(peak, other.peak) &&
          other.scale == scale &&
          other.size == size &&
          other.target == target &&
          other.video == video);

  @override
  int get hashCode => Object.hash(
    enabled,
    dualmono,
    framelog,
    gauge,
    metadata,
    meter,
    panlaw,
    Object.hashAllUnordered(peak),
    scale,
    size,
    target,
    video,
  );

  @override
  String toString() =>
      'Ebur128Effect(enabled: $enabled, dualmono: $dualmono, framelog: $framelog, gauge: $gauge, metadata: $metadata, meter: $meter, panlaw: $panlaw, peak: $peak, scale: $scale, size: $size, target: $target, video: $video)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(meter >= meterMin, 'ebur128.meter must be >= 9');
    assert(meter <= meterMax, 'ebur128.meter must be <= 18');
    assert(panlaw >= panlawMin, 'ebur128.panlaw must be >= -10.0');
    assert(panlaw <= panlawMax, 'ebur128.panlaw must be <= 0.0');
    assert(target >= targetMin, 'ebur128.target must be >= -23');
    assert(target <= targetMax, 'ebur128.target must be <= 0');
    final parts = <String>[];
    if (dualmono != false) parts.add('dualmono=' + (dualmono ? '1' : '0'));
    if (framelog != null) parts.add('framelog=' + framelog!.mpvValue);
    if (gauge != Ebur128Gaugetype.momentary)
      parts.add('gauge=' + gauge.mpvValue);
    if (metadata != false) parts.add('metadata=' + (metadata ? '1' : '0'));
    if (meter != 9) parts.add('meter=' + meter.toString());
    if (panlaw != -3.01029995663978) parts.add('panlaw=' + _wireDouble(panlaw));
    if (peak.isNotEmpty)
      parts.add('peak=' + peak.map((e) => e.mpvValue).join('+'));
    if (scale != Ebur128Scaletype.absolute)
      parts.add('scale=' + scale.mpvValue);
    if (size != '640x480') parts.add('size=' + '[' + size + ']');
    if (target != -23) parts.add('target=' + target.toString());
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency in Hz. (range 0..999999, default 0, runtime-tunable)
/// - [gain]: Set the required gain or attenuation in dB. Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. (range 0..99999, default 1.0, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class EqualizerEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 0.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [width].
  static const double widthDefault = 1.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set filtering precision
  final EqualizerPrecision precision;

  /// set transform type
  final EqualizerTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final EqualizerWidthType widthType;

  /// Creates an [EqualizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const EqualizerEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 0.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.precision = EqualizerPrecision.auto,
    this.transform = EqualizerTransformType.di,
    this.width = 1.0,
    this.widthType = EqualizerWidthType.q,
  });

  @override
  String get filterName => 'equalizer';

  @override
  AudioFilter get filter => AudioFilter.equalizer;

  /// Returns a copy of this [EqualizerEffect] with the given fields replaced.
  EqualizerEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    EqualizerPrecision? precision,
    EqualizerTransformType? transform,
    double? width,
    EqualizerWidthType? widthType,
  }) => EqualizerEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EqualizerEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'EqualizerEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'equalizer.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'equalizer.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'equalizer.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'equalizer.frequency must be <= 999999');
    assert(gain >= gainMin, 'equalizer.gain must be >= -900');
    assert(gain <= gainMax, 'equalizer.gain must be <= 900');
    assert(mix >= mixMin, 'equalizer.mix must be >= 0');
    assert(mix <= mixMax, 'equalizer.mix must be <= 1');
    assert(width >= widthMin, 'equalizer.width must be >= 0');
    assert(width <= widthMax, 'equalizer.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 0.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (precision != EqualizerPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != EqualizerTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 1.0) parts.add('width=' + _wireDouble(width));
    if (widthType != EqualizerWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-equalizer'
        : 'lavfi-equalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant EqualizerEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [c]: Enable clipping. By default is enabled. (range 0..1, default 1, runtime-tunable)
/// - [m]: Sets the difference coefficient (default: 2.5). 0.0 means mono sound (average of both channels), with 1.0 sound will be unchanged, with -1.0 left and right channels will be swapped. (range -10..10, default 2.5, runtime-tunable)
final class ExtrastereoEffect extends AudioEffect {
  /// Default value for [m].
  static const double mDefault = 2.5;

  /// Minimum value for [m].
  static const double mMin = -10.0;

  /// Maximum value for [m].
  static const double mMax = 10.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// enable clipping
  final bool c;

  /// set the difference coefficient
  final double m;

  /// Creates an [ExtrastereoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const ExtrastereoEffect({this.enabled = true, this.c = true, this.m = 2.5});

  @override
  String get filterName => 'extrastereo';

  @override
  AudioFilter get filter => AudioFilter.extrastereo;

  /// Returns a copy of this [ExtrastereoEffect] with the given fields replaced.
  ExtrastereoEffect copyWith({bool? enabled, bool? c, double? m}) =>
      ExtrastereoEffect(
        enabled: enabled ?? this.enabled,
        c: c ?? this.c,
        m: m ?? this.m,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExtrastereoEffect &&
          other.enabled == enabled &&
          other.c == c &&
          other.m == m);

  @override
  int get hashCode => Object.hash(enabled, c, m);

  @override
  String toString() => 'ExtrastereoEffect(enabled: $enabled, c: $c, m: $m)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(m >= mMin, 'extrastereo.m must be >= -10');
    assert(m <= mMax, 'extrastereo.m must be <= 10');
    final parts = <String>[];
    if (c != true) parts.add('c=' + (c ? '1' : '0'));
    if (m != 2.5) parts.add('m=' + _wireDouble(m));
    return parts.isEmpty
        ? 'lavfi-extrastereo'
        : 'lavfi-extrastereo=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant ExtrastereoEffect prev) {
    final out = <(String, String)>[];
    if (c != prev.c) {
      out.add(('c', (c ? '1' : '0')));
    }
    if (m != prev.m) {
      out.add(('m', _wireDouble(m)));
    }
    return out;
  }
}

/// Configuration for the `firequalizer` audio effect.
///
/// Apply FIR Equalization using arbitrary frequency response.
///
/// The filter accepts the following option:
///
/// Parameters:
/// - [accuracy]: Set filter accuracy in Hz. Lower value means more accurate. Default is `5`. (range 3..1e10, default 5.0)
/// - [delay]: Set filter delay in seconds. Higher value means more accurate. Default is `0.01`. (range 0.0..1e10, default 0.01)
/// - [dumpfile]: Set file for dumping, suitable for gnuplot. (range 0..0, default "")
/// - [dumpscale]: Set scale for dumpfile. Acceptable values are same with scale option. Default is linlog. (range 0..3, default SCALE_LINLOG)
/// - [fft2]: Enable 2-channel convolution using complex FFT. This improves speed significantly. Default is disabled. (range 0..1, default 0)
/// - [fixed]: If enabled, use fixed number of audio samples. This improves speed when filtering with large delay. Default is disabled. (range 0..1, default 0)
/// - [gain]: Set gain curve equation (in dB). The expression can contain variables: (range 0..0, default "gain_interpolate(f)", runtime-tunable)
/// - [gainEntry]: Set gain entry for gain_interpolate function. The expression can contain functions: (range 0..0, default "", runtime-tunable)
/// - [minPhase]: Enable minimum phase impulse response. Default is disabled. (range 0..1, default 0)
/// - [multi]: Enable multichannels evaluation on gain. Default is disabled. (range 0..1, default 0)
/// - [scale]: Set scale used by gain. Acceptable values are: (range 0..3, default SCALE_LINLOG)
/// - [wfunc]: Set window function. Acceptable values are: (range 0..9, default WFUNC_HANN)
/// - [zeroPhase]: Enable zero phase mode by subtracting timestamp to compensate delay. Default is disabled. (range 0..1, default 0)
final class FirequalizerEffect extends AudioEffect {
  /// Default value for [accuracy].
  static const double accuracyDefault = 5.0;

  /// Minimum value for [accuracy].
  static const double accuracyMin = 3.0;

  /// Maximum value for [accuracy].
  static const double accuracyMax = 1e10;

  /// Default value for [delay].
  static const double delayDefault = 0.01;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 1e10;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set accuracy
  final double accuracy;

  /// set delay
  final double delay;

  /// set dump file
  final String dumpfile;

  /// set dump scale
  final FirequalizerScale dumpscale;

  /// set 2-channels fft
  final bool fft2;

  /// set fixed frame samples
  final bool fixed;

  /// set gain curve
  final String gain;

  /// set gain entry
  final String gainEntry;

  /// set minimum phase mode
  final bool minPhase;

  /// set multi channels mode
  final bool multi;

  /// set gain scale
  final FirequalizerScale scale;

  /// set window function
  final FirequalizerWfunc wfunc;

  /// set zero phase mode
  final bool zeroPhase;

  /// Creates an [FirequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const FirequalizerEffect({
    this.enabled = true,
    this.accuracy = 5.0,
    this.delay = 0.01,
    this.dumpfile = '',
    this.dumpscale = FirequalizerScale.linlog,
    this.fft2 = false,
    this.fixed = false,
    this.gain = 'gain_interpolate(f)',
    this.gainEntry = '',
    this.minPhase = false,
    this.multi = false,
    this.scale = FirequalizerScale.linlog,
    this.wfunc = FirequalizerWfunc.hann,
    this.zeroPhase = false,
  });

  @override
  String get filterName => 'firequalizer';

  @override
  AudioFilter get filter => AudioFilter.firequalizer;

  /// Returns a copy of this [FirequalizerEffect] with the given fields replaced.
  FirequalizerEffect copyWith({
    bool? enabled,
    double? accuracy,
    double? delay,
    String? dumpfile,
    FirequalizerScale? dumpscale,
    bool? fft2,
    bool? fixed,
    String? gain,
    String? gainEntry,
    bool? minPhase,
    bool? multi,
    FirequalizerScale? scale,
    FirequalizerWfunc? wfunc,
    bool? zeroPhase,
  }) => FirequalizerEffect(
    enabled: enabled ?? this.enabled,
    accuracy: accuracy ?? this.accuracy,
    delay: delay ?? this.delay,
    dumpfile: dumpfile ?? this.dumpfile,
    dumpscale: dumpscale ?? this.dumpscale,
    fft2: fft2 ?? this.fft2,
    fixed: fixed ?? this.fixed,
    gain: gain ?? this.gain,
    gainEntry: gainEntry ?? this.gainEntry,
    minPhase: minPhase ?? this.minPhase,
    multi: multi ?? this.multi,
    scale: scale ?? this.scale,
    wfunc: wfunc ?? this.wfunc,
    zeroPhase: zeroPhase ?? this.zeroPhase,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FirequalizerEffect &&
          other.enabled == enabled &&
          other.accuracy == accuracy &&
          other.delay == delay &&
          other.dumpfile == dumpfile &&
          other.dumpscale == dumpscale &&
          other.fft2 == fft2 &&
          other.fixed == fixed &&
          other.gain == gain &&
          other.gainEntry == gainEntry &&
          other.minPhase == minPhase &&
          other.multi == multi &&
          other.scale == scale &&
          other.wfunc == wfunc &&
          other.zeroPhase == zeroPhase);

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
    gainEntry,
    minPhase,
    multi,
    scale,
    wfunc,
    zeroPhase,
  );

  @override
  String toString() =>
      'FirequalizerEffect(enabled: $enabled, accuracy: $accuracy, delay: $delay, dumpfile: $dumpfile, dumpscale: $dumpscale, fft2: $fft2, fixed: $fixed, gain: $gain, gainEntry: $gainEntry, minPhase: $minPhase, multi: $multi, scale: $scale, wfunc: $wfunc, zeroPhase: $zeroPhase)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(accuracy >= accuracyMin, 'firequalizer.accuracy must be >= 3');
    assert(accuracy <= accuracyMax, 'firequalizer.accuracy must be <= 1e10');
    assert(delay >= delayMin, 'firequalizer.delay must be >= 0.0');
    assert(delay <= delayMax, 'firequalizer.delay must be <= 1e10');
    final parts = <String>[];
    if (accuracy != 5.0) parts.add('accuracy=' + _wireDouble(accuracy));
    if (delay != 0.01) parts.add('delay=' + _wireDouble(delay));
    if (dumpfile != '') parts.add('dumpfile=' + '[' + dumpfile + ']');
    if (dumpscale != FirequalizerScale.linlog)
      parts.add('dumpscale=' + dumpscale.mpvValue);
    if (fft2 != false) parts.add('fft2=' + (fft2 ? '1' : '0'));
    if (fixed != false) parts.add('fixed=' + (fixed ? '1' : '0'));
    if (gain != 'gain_interpolate(f)') parts.add('gain=' + '[' + gain + ']');
    if (gainEntry != '') parts.add('gain_entry=' + '[' + gainEntry + ']');
    if (minPhase != false) parts.add('min_phase=' + (minPhase ? '1' : '0'));
    if (multi != false) parts.add('multi=' + (multi ? '1' : '0'));
    if (scale != FirequalizerScale.linlog) parts.add('scale=' + scale.mpvValue);
    if (wfunc != FirequalizerWfunc.hann) parts.add('wfunc=' + wfunc.mpvValue);
    if (zeroPhase != false) parts.add('zero_phase=' + (zeroPhase ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-firequalizer'
        : 'lavfi-firequalizer=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant FirequalizerEffect prev) {
    final out = <(String, String)>[];
    if (accuracy != prev.accuracy) return null;
    if (delay != prev.delay) return null;
    if (dumpfile != prev.dumpfile) return null;
    if (dumpscale != prev.dumpscale) return null;
    if (fft2 != prev.fft2) return null;
    if (fixed != prev.fixed) return null;
    if (gain != prev.gain) {
      out.add(('gain', gain));
    }
    if (gainEntry != prev.gainEntry) {
      out.add(('gain_entry', gainEntry));
    }
    if (minPhase != prev.minPhase) return null;
    if (multi != prev.multi) return null;
    if (scale != prev.scale) return null;
    if (wfunc != prev.wfunc) return null;
    if (zeroPhase != prev.zeroPhase) return null;
    return out;
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
/// - [shape]: Set swept wave shape, can be `triangular` or `sinusoidal`. Default value is `sinusoidal`. (default WAVE_SIN)
/// - [speed]: Set sweeps per second (Hz). Range from 0.1 to 10. Default value is 0.5. (range 0.1..10, default 0.5)
/// - [width]: Set percentage of delayed signal mixed with original. Range from 0 to 100. Default value is 71. (range 0..100, default 71)
final class FlangerEffect extends AudioEffect {
  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = 0.0;

  /// Maximum value for [delay].
  static const double delayMax = 30.0;

  /// Default value for [depth].
  static const double depthDefault = 2.0;

  /// Minimum value for [depth].
  static const double depthMin = 0.0;

  /// Maximum value for [depth].
  static const double depthMax = 10.0;

  /// Default value for [phase].
  static const double phaseDefault = 25.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 100.0;

  /// Default value for [regen].
  static const double regenDefault = 0.0;

  /// Minimum value for [regen].
  static const double regenMin = -95.0;

  /// Maximum value for [regen].
  static const double regenMax = 95.0;

  /// Default value for [speed].
  static const double speedDefault = 0.5;

  /// Minimum value for [speed].
  static const double speedMin = 0.1;

  /// Maximum value for [speed].
  static const double speedMax = 10.0;

  /// Default value for [width].
  static const double widthDefault = 71.0;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// base delay in milliseconds
  final double delay;

  /// added swept delay in milliseconds
  final double depth;

  /// delay-line interpolation
  final FlangerItype interp;

  /// swept wave percentage phase-shift for multi-channel
  final double phase;

  /// percentage regeneration (delayed signal feedback)
  final double regen;

  /// swept wave shape
  final FlangerType shape;

  /// sweeps per second (Hz)
  final double speed;

  /// percentage of delayed signal mixed with original
  final double width;

  /// Creates an [FlangerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const FlangerEffect({
    this.enabled = true,
    this.delay = 0.0,
    this.depth = 2.0,
    this.interp = FlangerItype.linear,
    this.phase = 25.0,
    this.regen = 0.0,
    this.shape = FlangerType.sinusoidal,
    this.speed = 0.5,
    this.width = 71.0,
  });

  @override
  String get filterName => 'flanger';

  @override
  AudioFilter get filter => AudioFilter.flanger;

  /// Returns a copy of this [FlangerEffect] with the given fields replaced.
  FlangerEffect copyWith({
    bool? enabled,
    double? delay,
    double? depth,
    FlangerItype? interp,
    double? phase,
    double? regen,
    FlangerType? shape,
    double? speed,
    double? width,
  }) => FlangerEffect(
    enabled: enabled ?? this.enabled,
    delay: delay ?? this.delay,
    depth: depth ?? this.depth,
    interp: interp ?? this.interp,
    phase: phase ?? this.phase,
    regen: regen ?? this.regen,
    shape: shape ?? this.shape,
    speed: speed ?? this.speed,
    width: width ?? this.width,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FlangerEffect &&
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
    enabled,
    delay,
    depth,
    interp,
    phase,
    regen,
    shape,
    speed,
    width,
  );

  @override
  String toString() =>
      'FlangerEffect(enabled: $enabled, delay: $delay, depth: $depth, interp: $interp, phase: $phase, regen: $regen, shape: $shape, speed: $speed, width: $width)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(delay >= delayMin, 'flanger.delay must be >= 0');
    assert(delay <= delayMax, 'flanger.delay must be <= 30');
    assert(depth >= depthMin, 'flanger.depth must be >= 0');
    assert(depth <= depthMax, 'flanger.depth must be <= 10');
    assert(phase >= phaseMin, 'flanger.phase must be >= 0');
    assert(phase <= phaseMax, 'flanger.phase must be <= 100');
    assert(regen >= regenMin, 'flanger.regen must be >= -95');
    assert(regen <= regenMax, 'flanger.regen must be <= 95');
    assert(speed >= speedMin, 'flanger.speed must be >= 0.1');
    assert(speed <= speedMax, 'flanger.speed must be <= 10');
    assert(width >= widthMin, 'flanger.width must be >= 0');
    assert(width <= widthMax, 'flanger.width must be <= 100');
    final parts = <String>[];
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (depth != 2.0) parts.add('depth=' + _wireDouble(depth));
    if (interp != FlangerItype.linear) parts.add('interp=' + interp.mpvValue);
    if (phase != 25.0) parts.add('phase=' + _wireDouble(phase));
    if (regen != 0.0) parts.add('regen=' + _wireDouble(regen));
    if (shape != FlangerType.sinusoidal) parts.add('shape=' + shape.mpvValue);
    if (speed != 0.5) parts.add('speed=' + _wireDouble(speed));
    if (width != 71.0) parts.add('width=' + _wireDouble(width));
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
/// - [leftBalance]: set left balance (range -1..1, default -1.0)
/// - [leftDelay]: set left delay (range 0..40, default 2.05)
/// - [leftGain]: set left gain (range 0.015625..64, default 1)
/// - [leftPhase]: set left phase (range 0..1, default 0)
/// - [levelIn]: Set input level. By default is `1`, or 0dB (range 0.015625..64, default 1)
/// - [levelOut]: Set output level. By default is `1`, or 0dB. (range 0.015625..64, default 1)
/// - [middlePhase]: set middle phase (range 0..1, default 0)
/// - [middleSource]: Set kind of middle source. Can be one of the following: (range 0..3, default 2)
/// - [rightBalance]: set right balance (range -1..1, default 1)
/// - [rightDelay]: set right delay (range 0..40, default 2.12)
/// - [rightGain]: set right gain (range 0.015625..64, default 1)
/// - [rightPhase]: set right phase (range 0..1, default 1)
/// - [sideGain]: Set gain applied to side part of signal. By default is `1`. (range 0.015625..64, default 1)
final class HaasEffect extends AudioEffect {
  /// Default value for [leftBalance].
  static const double leftBalanceDefault = -1.0;

  /// Minimum value for [leftBalance].
  static const double leftBalanceMin = -1.0;

  /// Maximum value for [leftBalance].
  static const double leftBalanceMax = 1.0;

  /// Default value for [leftDelay].
  static const double leftDelayDefault = 2.05;

  /// Minimum value for [leftDelay].
  static const double leftDelayMin = 0.0;

  /// Maximum value for [leftDelay].
  static const double leftDelayMax = 40.0;

  /// Default value for [leftGain].
  static const double leftGainDefault = 1.0;

  /// Minimum value for [leftGain].
  static const double leftGainMin = 0.015625;

  /// Maximum value for [leftGain].
  static const double leftGainMax = 64.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [rightBalance].
  static const double rightBalanceDefault = 1.0;

  /// Minimum value for [rightBalance].
  static const double rightBalanceMin = -1.0;

  /// Maximum value for [rightBalance].
  static const double rightBalanceMax = 1.0;

  /// Default value for [rightDelay].
  static const double rightDelayDefault = 2.12;

  /// Minimum value for [rightDelay].
  static const double rightDelayMin = 0.0;

  /// Maximum value for [rightDelay].
  static const double rightDelayMax = 40.0;

  /// Default value for [rightGain].
  static const double rightGainDefault = 1.0;

  /// Minimum value for [rightGain].
  static const double rightGainMin = 0.015625;

  /// Maximum value for [rightGain].
  static const double rightGainMax = 64.0;

  /// Default value for [sideGain].
  static const double sideGainDefault = 1.0;

  /// Minimum value for [sideGain].
  static const double sideGainMin = 0.015625;

  /// Maximum value for [sideGain].
  static const double sideGainMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set left balance
  final double leftBalance;

  /// set left delay
  final double leftDelay;

  /// set left gain
  final double leftGain;

  /// set left phase
  final bool leftPhase;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set middle phase
  final bool middlePhase;

  /// set middle source
  final HaasSource middleSource;

  /// set right balance
  final double rightBalance;

  /// set right delay
  final double rightDelay;

  /// set right gain
  final double rightGain;

  /// set right phase
  final bool rightPhase;

  /// set side gain
  final double sideGain;

  /// Creates an [HaasEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HaasEffect({
    this.enabled = true,
    this.leftBalance = -1.0,
    this.leftDelay = 2.05,
    this.leftGain = 1.0,
    this.leftPhase = false,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.middlePhase = false,
    this.middleSource = HaasSource.mid,
    this.rightBalance = 1.0,
    this.rightDelay = 2.12,
    this.rightGain = 1.0,
    this.rightPhase = true,
    this.sideGain = 1.0,
  });

  @override
  String get filterName => 'haas';

  @override
  AudioFilter get filter => AudioFilter.haas;

  /// Returns a copy of this [HaasEffect] with the given fields replaced.
  HaasEffect copyWith({
    bool? enabled,
    double? leftBalance,
    double? leftDelay,
    double? leftGain,
    bool? leftPhase,
    double? levelIn,
    double? levelOut,
    bool? middlePhase,
    HaasSource? middleSource,
    double? rightBalance,
    double? rightDelay,
    double? rightGain,
    bool? rightPhase,
    double? sideGain,
  }) => HaasEffect(
    enabled: enabled ?? this.enabled,
    leftBalance: leftBalance ?? this.leftBalance,
    leftDelay: leftDelay ?? this.leftDelay,
    leftGain: leftGain ?? this.leftGain,
    leftPhase: leftPhase ?? this.leftPhase,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    middlePhase: middlePhase ?? this.middlePhase,
    middleSource: middleSource ?? this.middleSource,
    rightBalance: rightBalance ?? this.rightBalance,
    rightDelay: rightDelay ?? this.rightDelay,
    rightGain: rightGain ?? this.rightGain,
    rightPhase: rightPhase ?? this.rightPhase,
    sideGain: sideGain ?? this.sideGain,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HaasEffect &&
          other.enabled == enabled &&
          other.leftBalance == leftBalance &&
          other.leftDelay == leftDelay &&
          other.leftGain == leftGain &&
          other.leftPhase == leftPhase &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.middlePhase == middlePhase &&
          other.middleSource == middleSource &&
          other.rightBalance == rightBalance &&
          other.rightDelay == rightDelay &&
          other.rightGain == rightGain &&
          other.rightPhase == rightPhase &&
          other.sideGain == sideGain);

  @override
  int get hashCode => Object.hash(
    enabled,
    leftBalance,
    leftDelay,
    leftGain,
    leftPhase,
    levelIn,
    levelOut,
    middlePhase,
    middleSource,
    rightBalance,
    rightDelay,
    rightGain,
    rightPhase,
    sideGain,
  );

  @override
  String toString() =>
      'HaasEffect(enabled: $enabled, leftBalance: $leftBalance, leftDelay: $leftDelay, leftGain: $leftGain, leftPhase: $leftPhase, levelIn: $levelIn, levelOut: $levelOut, middlePhase: $middlePhase, middleSource: $middleSource, rightBalance: $rightBalance, rightDelay: $rightDelay, rightGain: $rightGain, rightPhase: $rightPhase, sideGain: $sideGain)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(leftBalance >= leftBalanceMin, 'haas.left_balance must be >= -1');
    assert(leftBalance <= leftBalanceMax, 'haas.left_balance must be <= 1');
    assert(leftDelay >= leftDelayMin, 'haas.left_delay must be >= 0');
    assert(leftDelay <= leftDelayMax, 'haas.left_delay must be <= 40');
    assert(leftGain >= leftGainMin, 'haas.left_gain must be >= 0.015625');
    assert(leftGain <= leftGainMax, 'haas.left_gain must be <= 64');
    assert(levelIn >= levelInMin, 'haas.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'haas.level_in must be <= 64');
    assert(levelOut >= levelOutMin, 'haas.level_out must be >= 0.015625');
    assert(levelOut <= levelOutMax, 'haas.level_out must be <= 64');
    assert(rightBalance >= rightBalanceMin, 'haas.right_balance must be >= -1');
    assert(rightBalance <= rightBalanceMax, 'haas.right_balance must be <= 1');
    assert(rightDelay >= rightDelayMin, 'haas.right_delay must be >= 0');
    assert(rightDelay <= rightDelayMax, 'haas.right_delay must be <= 40');
    assert(rightGain >= rightGainMin, 'haas.right_gain must be >= 0.015625');
    assert(rightGain <= rightGainMax, 'haas.right_gain must be <= 64');
    assert(sideGain >= sideGainMin, 'haas.side_gain must be >= 0.015625');
    assert(sideGain <= sideGainMax, 'haas.side_gain must be <= 64');
    final parts = <String>[];
    if (leftBalance != -1.0)
      parts.add('left_balance=' + _wireDouble(leftBalance));
    if (leftDelay != 2.05) parts.add('left_delay=' + _wireDouble(leftDelay));
    if (leftGain != 1.0) parts.add('left_gain=' + _wireDouble(leftGain));
    if (leftPhase != false) parts.add('left_phase=' + (leftPhase ? '1' : '0'));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (middlePhase != false)
      parts.add('middle_phase=' + (middlePhase ? '1' : '0'));
    if (middleSource != HaasSource.mid)
      parts.add('middle_source=' + middleSource.mpvValue);
    if (rightBalance != 1.0)
      parts.add('right_balance=' + _wireDouble(rightBalance));
    if (rightDelay != 2.12) parts.add('right_delay=' + _wireDouble(rightDelay));
    if (rightGain != 1.0) parts.add('right_gain=' + _wireDouble(rightGain));
    if (rightPhase != true)
      parts.add('right_phase=' + (rightPhase ? '1' : '0'));
    if (sideGain != 1.0) parts.add('side_gain=' + _wireDouble(sideGain));
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
/// - [analyzeMode]: Replace audio with a solid tone and adjust the amplitude to signal some specific aspect of the decoding process. The output file can be loaded in an audio editor alongside the original to aid analysis.  `analyze_mode=pe:force_pe=true` can be used to see all samples above the PE level.  Modes are: (range 0..4, default HDCD_ANA_OFF)
/// - [bitsPerSample]: Valid bits per sample (location of the true LSB). (range 16..24, default 16)
/// - [cdtMs]: Set the code detect timer period in ms. (range 100..60000, default 2000)
/// - [disableAutoconvert]: Disable any automatic format conversion or resampling in the filter graph. (range 0..1, default 1)
/// - [forcePe]: Always extend peaks above -3dBFS even if PE isn't signaled. (range 0..1, default 0)
/// - [processStereo]: Process the stereo channels together. If target_gain does not match between channels, consider it invalid and use the last valid target_gain. (range 0..1, default HDCD_PROCESS_STEREO_DEFAULT)
final class HdcdEffect extends AudioEffect {
  /// Default value for [cdtMs].
  static const int cdtMsDefault = 2000;

  /// Minimum value for [cdtMs].
  static const int cdtMsMin = 100;

  /// Maximum value for [cdtMs].
  static const int cdtMsMax = 60000;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Replace audio with solid tone and signal some processing aspect in the amplitude.
  final HdcdAnalyzeMode analyzeMode;

  /// Valid bits per sample (location of the true LSB).
  final HdcdBitsPerSample bitsPerSample;

  /// Code detect timer period in ms.
  final int cdtMs;

  /// Disable any format conversion or resampling in the filter graph.
  final bool disableAutoconvert;

  /// Always extend peaks above -3dBFS even when PE is not signaled.
  final bool forcePe;

  /// Process stereo channels together. Only apply target_gain when both channels match.
  final bool processStereo;

  /// Creates an [HdcdEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HdcdEffect({
    this.enabled = true,
    this.analyzeMode = HdcdAnalyzeMode.off,
    this.bitsPerSample = HdcdBitsPerSample.n16,
    this.cdtMs = 2000,
    this.disableAutoconvert = true,
    this.forcePe = false,
    this.processStereo = false,
  });

  @override
  String get filterName => 'hdcd';

  @override
  AudioFilter get filter => AudioFilter.hdcd;

  /// Returns a copy of this [HdcdEffect] with the given fields replaced.
  HdcdEffect copyWith({
    bool? enabled,
    HdcdAnalyzeMode? analyzeMode,
    HdcdBitsPerSample? bitsPerSample,
    int? cdtMs,
    bool? disableAutoconvert,
    bool? forcePe,
    bool? processStereo,
  }) => HdcdEffect(
    enabled: enabled ?? this.enabled,
    analyzeMode: analyzeMode ?? this.analyzeMode,
    bitsPerSample: bitsPerSample ?? this.bitsPerSample,
    cdtMs: cdtMs ?? this.cdtMs,
    disableAutoconvert: disableAutoconvert ?? this.disableAutoconvert,
    forcePe: forcePe ?? this.forcePe,
    processStereo: processStereo ?? this.processStereo,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HdcdEffect &&
          other.enabled == enabled &&
          other.analyzeMode == analyzeMode &&
          other.bitsPerSample == bitsPerSample &&
          other.cdtMs == cdtMs &&
          other.disableAutoconvert == disableAutoconvert &&
          other.forcePe == forcePe &&
          other.processStereo == processStereo);

  @override
  int get hashCode => Object.hash(
    enabled,
    analyzeMode,
    bitsPerSample,
    cdtMs,
    disableAutoconvert,
    forcePe,
    processStereo,
  );

  @override
  String toString() =>
      'HdcdEffect(enabled: $enabled, analyzeMode: $analyzeMode, bitsPerSample: $bitsPerSample, cdtMs: $cdtMs, disableAutoconvert: $disableAutoconvert, forcePe: $forcePe, processStereo: $processStereo)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cdtMs >= cdtMsMin, 'hdcd.cdt_ms must be >= 100');
    assert(cdtMs <= cdtMsMax, 'hdcd.cdt_ms must be <= 60000');
    final parts = <String>[];
    if (analyzeMode != HdcdAnalyzeMode.off)
      parts.add('analyze_mode=' + analyzeMode.mpvValue);
    if (bitsPerSample != HdcdBitsPerSample.n16)
      parts.add('bits_per_sample=' + bitsPerSample.mpvValue);
    if (cdtMs != 2000) parts.add('cdt_ms=' + cdtMs.toString());
    if (disableAutoconvert != true)
      parts.add('disable_autoconvert=' + (disableAutoconvert ? '1' : '0'));
    if (forcePe != false) parts.add('force_pe=' + (forcePe ? '1' : '0'));
    if (processStereo != false)
      parts.add('process_stereo=' + (processStereo ? '1' : '0'));
    return parts.isEmpty ? 'lavfi-hdcd' : 'lavfi-hdcd=' + parts.join(':');
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set frequency in Hz. Default is 3000. (range 0..999999, default 3000, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class HighpassEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final HighpassPrecision precision;

  /// set transform type
  final HighpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final HighpassWidthType widthType;

  /// Creates an [HighpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HighpassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = HighpassPrecision.auto,
    this.transform = HighpassTransformType.di,
    this.width = 0.707,
    this.widthType = HighpassWidthType.q,
  });

  @override
  String get filterName => 'highpass';

  @override
  AudioFilter get filter => AudioFilter.highpass;

  /// Returns a copy of this [HighpassEffect] with the given fields replaced.
  HighpassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    int? poles,
    HighpassPrecision? precision,
    HighpassTransformType? transform,
    double? width,
    HighpassWidthType? widthType,
  }) => HighpassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighpassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'HighpassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'highpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'highpass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'highpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'highpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'highpass.mix must be >= 0');
    assert(mix <= mixMax, 'highpass.mix must be <= 1');
    assert(poles >= polesMin, 'highpass.poles must be >= 1');
    assert(poles <= polesMax, 'highpass.poles must be <= 2');
    assert(width >= widthMin, 'highpass.width must be >= 0');
    assert(width <= widthMax, 'highpass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != HighpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != HighpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (widthType != HighpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-highpass'
        : 'lavfi-highpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant HighpassEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class HighshelfEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final HighshelfPrecision precision;

  /// set transform type
  final HighshelfTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final HighshelfWidthType widthType;

  /// Creates an [HighshelfEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const HighshelfEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = HighshelfPrecision.auto,
    this.transform = HighshelfTransformType.di,
    this.width = 0.5,
    this.widthType = HighshelfWidthType.q,
  });

  @override
  String get filterName => 'highshelf';

  @override
  AudioFilter get filter => AudioFilter.highshelf;

  /// Returns a copy of this [HighshelfEffect] with the given fields replaced.
  HighshelfEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    int? poles,
    HighshelfPrecision? precision,
    HighshelfTransformType? transform,
    double? width,
    HighshelfWidthType? widthType,
  }) => HighshelfEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HighshelfEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'HighshelfEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'highshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'highshelf.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'highshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'highshelf.frequency must be <= 999999');
    assert(gain >= gainMin, 'highshelf.gain must be >= -900');
    assert(gain <= gainMax, 'highshelf.gain must be <= 900');
    assert(mix >= mixMin, 'highshelf.mix must be >= 0');
    assert(mix <= mixMax, 'highshelf.mix must be <= 1');
    assert(poles >= polesMin, 'highshelf.poles must be >= 1');
    assert(poles <= polesMax, 'highshelf.poles must be <= 2');
    assert(width >= widthMin, 'highshelf.width must be >= 0');
    assert(width <= widthMax, 'highshelf.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != HighshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != HighshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != HighshelfWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-highshelf'
        : 'lavfi-highshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant HighshelfEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [dualMono]: Treat mono input files as "dual-mono". If a mono file is intended for playback on a stereo system, its EBU R128 measurement will be perceptually incorrect. If set to `true`, this option will compensate for this effect. Multi-channel input files are not affected by this option. Options are true or false. Default is false. (range 0..1, default 0)
/// - [i]: Set integrated loudness target. Range is -70.0 - -5.0. Default value is -24.0. (range -70.0..-5.0, default -24.)
/// - [linear]: Normalize by linearly scaling the source audio. `measured_I`, `measured_LRA`, `measured_TP`, and `measured_thresh` must all be specified. Target LRA shouldn't be lower than source LRA and the change in integrated loudness shouldn't result in a true peak which exceeds the target TP. If any of these conditions aren't met, normalization mode will revert to `dynamic`. Options are `true` or `false`. Default is `true`. (range 0..1, default 1)
/// - [lra]: Set loudness range target. Range is 1.0 - 50.0. Default value is 7.0. (range 1.0..50.0, default 7.)
/// - [measuredI]: Measured IL of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default 0.)
/// - [measuredLra]: Measured LRA of input file. Range is  0.0 - 99.0. (range 0.0..99.0, default 0.)
/// - [measuredThresh]: Measured threshold of input file. Range is -99.0 - +0.0. (range -99.0..0.0, default -70.)
/// - [measuredTp]: Measured true peak of input file. Range is  -99.0 - +99.0. (range -99.0..99.0, default 99.)
/// - [offset]: Set offset gain. Gain is applied before the true-peak limiter. Range is  -99.0 - +99.0. Default is +0.0. (range -99.0..99.0, default 0.)
/// - [printFormat]: Set print format for stats. Options are summary, json, or none. Default value is none. (range 0..2, default NONE)
/// - [statsFile]: Write stats to specified file. Format is controlled by @option{print_format}, which must be set. Specify `-` to write to standard output. Default is unset. (range 0..0, default "")
/// - [tp]: Set maximum true peak. Range is -9.0 - +0.0. Default value is -2.0. (range -9.0..0.0, default -2.)
final class LoudnormEffect extends AudioEffect {
  /// Default value for [i].
  static const double iDefault = -24.0;

  /// Minimum value for [i].
  static const double iMin = -70.0;

  /// Maximum value for [i].
  static const double iMax = -5.0;

  /// Default value for [lra].
  static const double lraDefault = 7.0;

  /// Minimum value for [lra].
  static const double lraMin = 1.0;

  /// Maximum value for [lra].
  static const double lraMax = 50.0;

  /// Default value for [measuredI].
  static const double measuredIDefault = 0.0;

  /// Minimum value for [measuredI].
  static const double measuredIMin = -99.0;

  /// Maximum value for [measuredI].
  static const double measuredIMax = 0.0;

  /// Default value for [measuredLra].
  static const double measuredLraDefault = 0.0;

  /// Minimum value for [measuredLra].
  static const double measuredLraMin = 0.0;

  /// Maximum value for [measuredLra].
  static const double measuredLraMax = 99.0;

  /// Default value for [measuredThresh].
  static const double measuredThreshDefault = -70.0;

  /// Minimum value for [measuredThresh].
  static const double measuredThreshMin = -99.0;

  /// Maximum value for [measuredThresh].
  static const double measuredThreshMax = 0.0;

  /// Default value for [measuredTp].
  static const double measuredTpDefault = 99.0;

  /// Minimum value for [measuredTp].
  static const double measuredTpMin = -99.0;

  /// Maximum value for [measuredTp].
  static const double measuredTpMax = 99.0;

  /// Default value for [offset].
  static const double offsetDefault = 0.0;

  /// Minimum value for [offset].
  static const double offsetMin = -99.0;

  /// Maximum value for [offset].
  static const double offsetMax = 99.0;

  /// Default value for [tp].
  static const double tpDefault = -2.0;

  /// Minimum value for [tp].
  static const double tpMin = -9.0;

  /// Maximum value for [tp].
  static const double tpMax = 0.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// treat mono input as dual-mono
  final bool dualMono;

  /// set integrated loudness target
  final double i;

  /// normalize linearly if possible
  final bool linear;

  /// set loudness range target
  final double lra;

  /// measured IL of input file
  final double measuredI;

  /// measured LRA of input file
  final double measuredLra;

  /// measured threshold of input file
  final double measuredThresh;

  /// measured true peak of input file
  final double measuredTp;

  /// set offset gain
  final double offset;

  /// set print format for stats
  final LoudnormPrintFormat printFormat;

  /// set stats output file
  final String statsFile;

  /// set maximum true peak
  final double tp;

  /// Creates an [LoudnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const LoudnormEffect({
    this.enabled = true,
    this.dualMono = false,
    this.i = -24.0,
    this.linear = true,
    this.lra = 7.0,
    this.measuredI = 0.0,
    this.measuredLra = 0.0,
    this.measuredThresh = -70.0,
    this.measuredTp = 99.0,
    this.offset = 0.0,
    this.printFormat = LoudnormPrintFormat.none,
    this.statsFile = '',
    this.tp = -2.0,
  });

  @override
  String get filterName => 'loudnorm';

  @override
  AudioFilter get filter => AudioFilter.loudnorm;

  /// Returns a copy of this [LoudnormEffect] with the given fields replaced.
  LoudnormEffect copyWith({
    bool? enabled,
    bool? dualMono,
    double? i,
    bool? linear,
    double? lra,
    double? measuredI,
    double? measuredLra,
    double? measuredThresh,
    double? measuredTp,
    double? offset,
    LoudnormPrintFormat? printFormat,
    String? statsFile,
    double? tp,
  }) => LoudnormEffect(
    enabled: enabled ?? this.enabled,
    dualMono: dualMono ?? this.dualMono,
    i: i ?? this.i,
    linear: linear ?? this.linear,
    lra: lra ?? this.lra,
    measuredI: measuredI ?? this.measuredI,
    measuredLra: measuredLra ?? this.measuredLra,
    measuredThresh: measuredThresh ?? this.measuredThresh,
    measuredTp: measuredTp ?? this.measuredTp,
    offset: offset ?? this.offset,
    printFormat: printFormat ?? this.printFormat,
    statsFile: statsFile ?? this.statsFile,
    tp: tp ?? this.tp,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LoudnormEffect &&
          other.enabled == enabled &&
          other.dualMono == dualMono &&
          other.i == i &&
          other.linear == linear &&
          other.lra == lra &&
          other.measuredI == measuredI &&
          other.measuredLra == measuredLra &&
          other.measuredThresh == measuredThresh &&
          other.measuredTp == measuredTp &&
          other.offset == offset &&
          other.printFormat == printFormat &&
          other.statsFile == statsFile &&
          other.tp == tp);

  @override
  int get hashCode => Object.hash(
    enabled,
    dualMono,
    i,
    linear,
    lra,
    measuredI,
    measuredLra,
    measuredThresh,
    measuredTp,
    offset,
    printFormat,
    statsFile,
    tp,
  );

  @override
  String toString() =>
      'LoudnormEffect(enabled: $enabled, dualMono: $dualMono, i: $i, linear: $linear, lra: $lra, measuredI: $measuredI, measuredLra: $measuredLra, measuredThresh: $measuredThresh, measuredTp: $measuredTp, offset: $offset, printFormat: $printFormat, statsFile: $statsFile, tp: $tp)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(i >= iMin, 'loudnorm.i must be >= -70.0');
    assert(i <= iMax, 'loudnorm.i must be <= -5.0');
    assert(lra >= lraMin, 'loudnorm.lra must be >= 1.0');
    assert(lra <= lraMax, 'loudnorm.lra must be <= 50.0');
    assert(measuredI >= measuredIMin, 'loudnorm.measured_i must be >= -99.0');
    assert(measuredI <= measuredIMax, 'loudnorm.measured_i must be <= 0.0');
    assert(
      measuredLra >= measuredLraMin,
      'loudnorm.measured_lra must be >= 0.0',
    );
    assert(
      measuredLra <= measuredLraMax,
      'loudnorm.measured_lra must be <= 99.0',
    );
    assert(
      measuredThresh >= measuredThreshMin,
      'loudnorm.measured_thresh must be >= -99.0',
    );
    assert(
      measuredThresh <= measuredThreshMax,
      'loudnorm.measured_thresh must be <= 0.0',
    );
    assert(
      measuredTp >= measuredTpMin,
      'loudnorm.measured_tp must be >= -99.0',
    );
    assert(measuredTp <= measuredTpMax, 'loudnorm.measured_tp must be <= 99.0');
    assert(offset >= offsetMin, 'loudnorm.offset must be >= -99.0');
    assert(offset <= offsetMax, 'loudnorm.offset must be <= 99.0');
    assert(tp >= tpMin, 'loudnorm.tp must be >= -9.0');
    assert(tp <= tpMax, 'loudnorm.tp must be <= 0.0');
    final parts = <String>[];
    if (dualMono != false) parts.add('dual_mono=' + (dualMono ? '1' : '0'));
    if (i != -24.0) parts.add('i=' + _wireDouble(i));
    if (linear != true) parts.add('linear=' + (linear ? '1' : '0'));
    if (lra != 7.0) parts.add('lra=' + _wireDouble(lra));
    if (measuredI != 0.0) parts.add('measured_i=' + _wireDouble(measuredI));
    if (measuredLra != 0.0)
      parts.add('measured_lra=' + _wireDouble(measuredLra));
    if (measuredThresh != -70.0)
      parts.add('measured_thresh=' + _wireDouble(measuredThresh));
    if (measuredTp != 99.0) parts.add('measured_tp=' + _wireDouble(measuredTp));
    if (offset != 0.0) parts.add('offset=' + _wireDouble(offset));
    if (printFormat != LoudnormPrintFormat.none)
      parts.add('print_format=' + printFormat.mpvValue);
    if (statsFile != '') parts.add('stats_file=' + '[' + statsFile + ']');
    if (tp != -2.0) parts.add('tp=' + _wireDouble(tp));
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set frequency in Hz. Default is 500. (range 0..999999, default 500, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Specify the band-width of a filter in width_type units. Applies only to double-pole filter. The default is 0.707q and gives a Butterworth response. (range 0..99999, default 0.707, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class LowpassEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 500.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.707;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set frequency
  final double frequency;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final LowpassPrecision precision;

  /// set transform type
  final LowpassTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final LowpassWidthType widthType;

  /// Creates an [LowpassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const LowpassEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 500.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = LowpassPrecision.auto,
    this.transform = LowpassTransformType.di,
    this.width = 0.707,
    this.widthType = LowpassWidthType.q,
  });

  @override
  String get filterName => 'lowpass';

  @override
  AudioFilter get filter => AudioFilter.lowpass;

  /// Returns a copy of this [LowpassEffect] with the given fields replaced.
  LowpassEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? mix,
    bool? normalize,
    int? poles,
    LowpassPrecision? precision,
    LowpassTransformType? transform,
    double? width,
    LowpassWidthType? widthType,
  }) => LowpassEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowpassEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'LowpassEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'lowpass.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'lowpass.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'lowpass.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'lowpass.frequency must be <= 999999');
    assert(mix >= mixMin, 'lowpass.mix must be >= 0');
    assert(mix <= mixMax, 'lowpass.mix must be <= 1');
    assert(poles >= polesMin, 'lowpass.poles must be >= 1');
    assert(poles <= polesMax, 'lowpass.poles must be <= 2');
    assert(width >= widthMin, 'lowpass.width must be >= 0');
    assert(width <= widthMax, 'lowpass.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 500.0) parts.add('frequency=' + _wireDouble(frequency));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != LowpassPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != LowpassTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.707) parts.add('width=' + _wireDouble(width));
    if (widthType != LowpassWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty ? 'lavfi-lowpass' : 'lavfi-lowpass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant LowpassEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `100` Hz. (range 0..999999, default 100, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class LowshelfEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 100.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final LowshelfPrecision precision;

  /// set transform type
  final LowshelfTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final LowshelfWidthType widthType;

  /// Creates an [LowshelfEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const LowshelfEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 100.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = LowshelfPrecision.auto,
    this.transform = LowshelfTransformType.di,
    this.width = 0.5,
    this.widthType = LowshelfWidthType.q,
  });

  @override
  String get filterName => 'lowshelf';

  @override
  AudioFilter get filter => AudioFilter.lowshelf;

  /// Returns a copy of this [LowshelfEffect] with the given fields replaced.
  LowshelfEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    int? poles,
    LowshelfPrecision? precision,
    LowshelfTransformType? transform,
    double? width,
    LowshelfWidthType? widthType,
  }) => LowshelfEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LowshelfEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'LowshelfEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'lowshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'lowshelf.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'lowshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'lowshelf.frequency must be <= 999999');
    assert(gain >= gainMin, 'lowshelf.gain must be >= -900');
    assert(gain <= gainMax, 'lowshelf.gain must be <= 900');
    assert(mix >= mixMin, 'lowshelf.mix must be >= 0');
    assert(mix <= mixMax, 'lowshelf.mix must be <= 1');
    assert(poles >= polesMin, 'lowshelf.poles must be >= 1');
    assert(poles <= polesMax, 'lowshelf.poles must be <= 2');
    assert(width >= widthMin, 'lowshelf.width must be >= 0');
    assert(width <= widthMax, 'lowshelf.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 100.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != LowshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != LowshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != LowshelfWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-lowshelf'
        : 'lavfi-lowshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant LowshelfEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [args]: This option syntax is: attack,decay,\[attack,decay..\] soft-knee points crossover_frequency \[delay \[initial_volume \[gain\]\]\] | attack,decay ... For explanation of each item refer to compand filter documentation. (range 0..0, default "0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000")
final class McompandEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set parameters for each band
  final String args;

  /// Creates an [McompandEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const McompandEffect({
    this.enabled = true,
    this.args =
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000',
  });

  @override
  String get filterName => 'mcompand';

  @override
  AudioFilter get filter => AudioFilter.mcompand;

  /// Returns a copy of this [McompandEffect] with the given fields replaced.
  McompandEffect copyWith({bool? enabled, String? args}) =>
      McompandEffect(enabled: enabled ?? this.enabled, args: args ?? this.args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is McompandEffect &&
          other.enabled == enabled &&
          other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'McompandEffect(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    if (args !=
        '0.005,0.1 6 -47/-40,-34/-34,-17/-33 100 | 0.003,0.05 6 -47/-40,-34/-34,-17/-33 400 | 0.000625,0.0125 6 -47/-40,-34/-34,-15/-33 1600 | 0.0001,0.025 6 -47/-40,-34/-34,-31/-31,-0/-30 6400 | 0,0.025 6 -38/-31,-28/-28,-0/-25 22000')
      parts.add('args=' + '[' + args + ']');
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
/// - [args]:  (range 0..0, default "")
final class PanEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// The `args` parameter.
  final String args;

  /// Creates an [PanEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const PanEffect({this.enabled = true, required this.args});

  @override
  String get filterName => 'pan';

  @override
  AudioFilter get filter => AudioFilter.pan;

  /// Returns a copy of this [PanEffect] with the given fields replaced.
  PanEffect copyWith({bool? enabled, String? args}) =>
      PanEffect(enabled: enabled ?? this.enabled, args: args ?? this.args);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PanEffect && other.enabled == enabled && other.args == args);

  @override
  int get hashCode => Object.hash(enabled, args);

  @override
  String toString() => 'PanEffect(enabled: $enabled, args: $args)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    parts.add('args=' + '[' + args + ']');
    return parts.isEmpty ? 'lavfi-pan' : 'lavfi-pan=' + parts.join(':');
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
/// - [channels]: set channels (range 0..2147483647, default 0)
/// - [detector]: set detector (range 0..2147483647, default 0)
/// - [formant]: set formant (range 0..2147483647, default 0)
/// - [phase]: set phase (range 0..2147483647, default 0)
/// - [pitch]: Set pitch scale factor. (range 0.01..100, default 1, runtime-tunable)
/// - [pitchq]: set pitch quality (range 0..2147483647, default 0)
/// - [smoothing]: set smoothing (range 0..2147483647, default 0)
/// - [tempo]: Set tempo scale factor. (range 0.01..100, default 1, runtime-tunable)
/// - [transients]: Set transients detector. Possible values are: (range 0..2147483647, default 0)
/// - [window]: set window (range 0..2147483647, default 0)
final class RubberbandEffect extends AudioEffect {
  /// Default value for [pitch].
  static const double pitchDefault = 1.0;

  /// Minimum value for [pitch].
  static const double pitchMin = 0.01;

  /// Maximum value for [pitch].
  static const double pitchMax = 100.0;

  /// Default value for [tempo].
  static const double tempoDefault = 1.0;

  /// Minimum value for [tempo].
  static const double tempoMin = 0.01;

  /// Maximum value for [tempo].
  static const double tempoMax = 100.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels
  final RubberbandChannels channels;

  /// set detector
  final RubberbandDetector detector;

  /// set formant
  final RubberbandFormant formant;

  /// set phase
  final RubberbandPhase phase;

  /// set pitch scale factor
  final double pitch;

  /// set pitch quality
  final RubberbandPitch pitchq;

  /// set smoothing
  final RubberbandSmoothing smoothing;

  /// set tempo scale factor
  final double tempo;

  /// set transients
  final RubberbandTransients transients;

  /// set window
  final RubberbandWindow window;

  /// Creates an [RubberbandEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const RubberbandEffect({
    this.enabled = true,
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

  @override
  String get filterName => 'rubberband';

  @override
  AudioFilter get filter => AudioFilter.rubberband;

  /// Returns a copy of this [RubberbandEffect] with the given fields replaced.
  RubberbandEffect copyWith({
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
  }) => RubberbandEffect(
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
      (other is RubberbandEffect &&
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
  int get hashCode => Object.hash(
    enabled,
    channels,
    detector,
    formant,
    phase,
    pitch,
    pitchq,
    smoothing,
    tempo,
    transients,
    window,
  );

  @override
  String toString() =>
      'RubberbandEffect(enabled: $enabled, channels: $channels, detector: $detector, formant: $formant, phase: $phase, pitch: $pitch, pitchq: $pitchq, smoothing: $smoothing, tempo: $tempo, transients: $transients, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(pitch >= pitchMin, 'rubberband.pitch must be >= 0.01');
    assert(pitch <= pitchMax, 'rubberband.pitch must be <= 100');
    assert(tempo >= tempoMin, 'rubberband.tempo must be >= 0.01');
    assert(tempo <= tempoMax, 'rubberband.tempo must be <= 100');
    final parts = <String>[];
    if (channels != RubberbandChannels.apart)
      parts.add('channels=' + channels.mpvValue);
    if (detector != RubberbandDetector.compound)
      parts.add('detector=' + detector.mpvValue);
    if (formant != RubberbandFormant.shifted)
      parts.add('formant=' + formant.mpvValue);
    if (phase != RubberbandPhase.laminar) parts.add('phase=' + phase.mpvValue);
    if (pitch != 1.0) parts.add('pitch=' + _wireDouble(pitch));
    if (pitchq != RubberbandPitch.quality)
      parts.add('pitchq=' + pitchq.mpvValue);
    if (smoothing != RubberbandSmoothing.off)
      parts.add('smoothing=' + smoothing.mpvValue);
    if (tempo != 1.0) parts.add('tempo=' + _wireDouble(tempo));
    if (transients != RubberbandTransients.crisp)
      parts.add('transients=' + transients.mpvValue);
    if (window != RubberbandWindow.standard)
      parts.add('window=' + window.mpvValue);
    return parts.isEmpty
        ? 'lavfi-rubberband'
        : 'lavfi-rubberband=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant RubberbandEffect prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) return null;
    if (detector != prev.detector) return null;
    if (formant != prev.formant) return null;
    if (phase != prev.phase) return null;
    if (pitch != prev.pitch) {
      out.add(('pitch', _wireDouble(pitch)));
    }
    if (pitchq != prev.pitchq) return null;
    if (smoothing != prev.smoothing) return null;
    if (tempo != prev.tempo) {
      out.add(('tempo', _wireDouble(tempo)));
    }
    if (transients != prev.transients) return null;
    if (window != prev.window) return null;
    return out;
  }
}

/// Configuration for the `silenceremove` audio effect.
///
/// Remove silence from the beginning, middle or end of the audio.
///
/// The filter accepts the following options:
///
/// Parameters:
/// - [detection]: Set how is silence detected. (range 0..5, default D_RMS)
/// - [startDuration]: Specify the amount of time that non-silence must be detected before it stops trimming audio. By increasing the duration, bursts of noises can be treated as silence and trimmed off. Default value is `0`. (range 0..2147483647, default 0)
/// - [startMode]: Specify mode of detection of silence end at start of multi-channel audio. Can be `any` or `all`. Default is `any`. With `any`, any sample from any channel that is detected as non-silence will trigger end of silence trimming at start of audio stream. With `all`, only if every sample from every channel is detected as non-silence will trigger end of silence trimming at start of audio stream, limited usage. (range 0..1, default T_ANY, runtime-tunable)
/// - [startPeriods]: This value is used to indicate if audio should be trimmed at beginning of the audio. A value of zero indicates no silence should be trimmed from the beginning. When specifying a non-zero value, it trims audio up until it finds non-silence. Normally, when trimming silence from beginning of audio the `start_periods` will be `1` but it can be increased to higher values to trim all audio up to specific count of non-silence periods. Default value is `0`. (range 0..9000, default 0)
/// - [startSilence]: Specify max duration of silence at beginning that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [startThreshold]: This indicates what sample value should be treated as silence. For digital audio, a value of `0` may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [stopDuration]: Specify a duration of silence that must exist before audio is not copied any more. By specifying a higher duration, silence that is wanted can be left in the audio. Default value is `0`. (range 0..2147483647, default 0)
/// - [stopMode]: Specify mode of detection of silence start after start of multi-channel audio. Can be `any` or `all`. Default is `all`. With `any`, any sample from any channel that is detected as silence will trigger start of silence trimming after start of audio stream, limited usage. With `all`, only if every sample from every channel is detected as silence will trigger start of silence trimming after start of audio stream. (range 0..1, default T_ALL, runtime-tunable)
/// - [stopPeriods]: Set the count for trimming silence from the end of audio. When specifying a positive value, it trims audio after it finds specified silence period. To remove silence from the middle of a file, specify a `stop_periods` that is negative. This value is then treated as a positive value and is used to indicate the effect should restart processing as specified by `stop_periods`, making it suitable for removing periods of silence in the middle of the audio. Default value is `0`. (range -9000..9000, default 0)
/// - [stopSilence]: Specify max duration of silence at end that will be kept after trimming. Default is 0, which is equal to trimming all samples detected as silence. (range 0..2147483647, default 0)
/// - [stopThreshold]: This is the same as @option{start_threshold} but for trimming silence from the end of audio. Can be specified in dB (in case "dB" is appended to the specified value) or amplitude ratio. Default value is `0`. (range 0..1.7976931348623157e+308, default 0, runtime-tunable)
/// - [timestamp]: Set processing mode of every audio frame output timestamp. (range 0..1, default TS_WRITE)
/// - [window]: Set duration in number of seconds used to calculate size of window in number of samples for detecting silence. Using `0` will effectively disable any windowing and use only single sample per channel for silence detection. In that case it may be needed to also set @option{start_silence} and/or @option{stop_silence} to nonzero values with also @option{start_duration} and/or @option{stop_duration} to nonzero values. Default value is `0.02`. Allowed range is from `0` to `10`. (range 0..100000000, default 20000)
final class SilenceremoveEffect extends AudioEffect {
  /// Default value for [startPeriods].
  static const int startPeriodsDefault = 0;

  /// Minimum value for [startPeriods].
  static const int startPeriodsMin = 0;

  /// Maximum value for [startPeriods].
  static const int startPeriodsMax = 9000;

  /// Default value for [startThreshold].
  static const double startThresholdDefault = 0.0;

  /// Minimum value for [startThreshold].
  static const double startThresholdMin = 0.0;

  /// Maximum value for [startThreshold].
  static const double startThresholdMax = 1.7976931348623157e+308;

  /// Default value for [stopPeriods].
  static const int stopPeriodsDefault = 0;

  /// Minimum value for [stopPeriods].
  static const int stopPeriodsMin = -9000;

  /// Maximum value for [stopPeriods].
  static const int stopPeriodsMax = 9000;

  /// Default value for [stopThreshold].
  static const double stopThresholdDefault = 0.0;

  /// Minimum value for [stopThreshold].
  static const double stopThresholdMin = 0.0;

  /// Maximum value for [stopThreshold].
  static const double stopThresholdMax = 1.7976931348623157e+308;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set how silence is detected
  final SilenceremoveDetection detection;

  /// set start duration of non-silence part
  final Duration startDuration;

  /// set which channel will trigger trimming from start
  final SilenceremoveMode startMode;

  /// set periods of silence parts to skip from start
  final int startPeriods;

  /// set start duration of silence part to keep
  final Duration startSilence;

  /// set threshold for start silence detection
  final double startThreshold;

  /// set stop duration of silence part
  final Duration stopDuration;

  /// set which channel will trigger trimming from end
  final SilenceremoveMode stopMode;

  /// set periods of silence parts to skip from end
  final int stopPeriods;

  /// set stop duration of silence part to keep
  final Duration stopSilence;

  /// set threshold for stop silence detection
  final double stopThreshold;

  /// set how every output frame timestamp is processed
  final SilenceremoveTimestamp timestamp;

  /// set duration of window for silence detection
  final Duration window;

  /// Creates an [SilenceremoveEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SilenceremoveEffect({
    this.enabled = true,
    this.detection = SilenceremoveDetection.rms,
    this.startDuration = Duration.zero,
    this.startMode = SilenceremoveMode.any,
    this.startPeriods = 0,
    this.startSilence = Duration.zero,
    this.startThreshold = 0.0,
    this.stopDuration = Duration.zero,
    this.stopMode = SilenceremoveMode.all,
    this.stopPeriods = 0,
    this.stopSilence = Duration.zero,
    this.stopThreshold = 0.0,
    this.timestamp = SilenceremoveTimestamp.write,
    this.window = const Duration(microseconds: 20000),
  });

  @override
  String get filterName => 'silenceremove';

  @override
  AudioFilter get filter => AudioFilter.silenceremove;

  /// Returns a copy of this [SilenceremoveEffect] with the given fields replaced.
  SilenceremoveEffect copyWith({
    bool? enabled,
    SilenceremoveDetection? detection,
    Duration? startDuration,
    SilenceremoveMode? startMode,
    int? startPeriods,
    Duration? startSilence,
    double? startThreshold,
    Duration? stopDuration,
    SilenceremoveMode? stopMode,
    int? stopPeriods,
    Duration? stopSilence,
    double? stopThreshold,
    SilenceremoveTimestamp? timestamp,
    Duration? window,
  }) => SilenceremoveEffect(
    enabled: enabled ?? this.enabled,
    detection: detection ?? this.detection,
    startDuration: startDuration ?? this.startDuration,
    startMode: startMode ?? this.startMode,
    startPeriods: startPeriods ?? this.startPeriods,
    startSilence: startSilence ?? this.startSilence,
    startThreshold: startThreshold ?? this.startThreshold,
    stopDuration: stopDuration ?? this.stopDuration,
    stopMode: stopMode ?? this.stopMode,
    stopPeriods: stopPeriods ?? this.stopPeriods,
    stopSilence: stopSilence ?? this.stopSilence,
    stopThreshold: stopThreshold ?? this.stopThreshold,
    timestamp: timestamp ?? this.timestamp,
    window: window ?? this.window,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SilenceremoveEffect &&
          other.enabled == enabled &&
          other.detection == detection &&
          other.startDuration == startDuration &&
          other.startMode == startMode &&
          other.startPeriods == startPeriods &&
          other.startSilence == startSilence &&
          other.startThreshold == startThreshold &&
          other.stopDuration == stopDuration &&
          other.stopMode == stopMode &&
          other.stopPeriods == stopPeriods &&
          other.stopSilence == stopSilence &&
          other.stopThreshold == stopThreshold &&
          other.timestamp == timestamp &&
          other.window == window);

  @override
  int get hashCode => Object.hash(
    enabled,
    detection,
    startDuration,
    startMode,
    startPeriods,
    startSilence,
    startThreshold,
    stopDuration,
    stopMode,
    stopPeriods,
    stopSilence,
    stopThreshold,
    timestamp,
    window,
  );

  @override
  String toString() =>
      'SilenceremoveEffect(enabled: $enabled, detection: $detection, startDuration: $startDuration, startMode: $startMode, startPeriods: $startPeriods, startSilence: $startSilence, startThreshold: $startThreshold, stopDuration: $stopDuration, stopMode: $stopMode, stopPeriods: $stopPeriods, stopSilence: $stopSilence, stopThreshold: $stopThreshold, timestamp: $timestamp, window: $window)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(
      startPeriods >= startPeriodsMin,
      'silenceremove.start_periods must be >= 0',
    );
    assert(
      startPeriods <= startPeriodsMax,
      'silenceremove.start_periods must be <= 9000',
    );
    assert(
      startThreshold >= startThresholdMin,
      'silenceremove.start_threshold must be >= 0',
    );
    assert(
      startThreshold <= startThresholdMax,
      'silenceremove.start_threshold must be <= 1.7976931348623157e+308',
    );
    assert(
      stopPeriods >= stopPeriodsMin,
      'silenceremove.stop_periods must be >= -9000',
    );
    assert(
      stopPeriods <= stopPeriodsMax,
      'silenceremove.stop_periods must be <= 9000',
    );
    assert(
      stopThreshold >= stopThresholdMin,
      'silenceremove.stop_threshold must be >= 0',
    );
    assert(
      stopThreshold <= stopThresholdMax,
      'silenceremove.stop_threshold must be <= 1.7976931348623157e+308',
    );
    final parts = <String>[];
    if (detection != SilenceremoveDetection.rms)
      parts.add('detection=' + detection.mpvValue);
    if (startDuration != Duration.zero)
      parts.add(
        'start_duration=' + _wireDouble(startDuration.inMicroseconds / 1e6),
      );
    if (startMode != SilenceremoveMode.any)
      parts.add('start_mode=' + startMode.mpvValue);
    if (startPeriods != 0)
      parts.add('start_periods=' + startPeriods.toString());
    if (startSilence != Duration.zero)
      parts.add(
        'start_silence=' + _wireDouble(startSilence.inMicroseconds / 1e6),
      );
    if (startThreshold != 0.0)
      parts.add('start_threshold=' + _wireDouble(startThreshold));
    if (stopDuration != Duration.zero)
      parts.add(
        'stop_duration=' + _wireDouble(stopDuration.inMicroseconds / 1e6),
      );
    if (stopMode != SilenceremoveMode.all)
      parts.add('stop_mode=' + stopMode.mpvValue);
    if (stopPeriods != 0) parts.add('stop_periods=' + stopPeriods.toString());
    if (stopSilence != Duration.zero)
      parts.add(
        'stop_silence=' + _wireDouble(stopSilence.inMicroseconds / 1e6),
      );
    if (stopThreshold != 0.0)
      parts.add('stop_threshold=' + _wireDouble(stopThreshold));
    if (timestamp != SilenceremoveTimestamp.write)
      parts.add('timestamp=' + timestamp.mpvValue);
    if (window != const Duration(microseconds: 20000))
      parts.add('window=' + _wireDouble(window.inMicroseconds / 1e6));
    return parts.isEmpty
        ? 'lavfi-silenceremove'
        : 'lavfi-silenceremove=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SilenceremoveEffect prev) {
    final out = <(String, String)>[];
    if (detection != prev.detection) return null;
    if (startDuration != prev.startDuration) return null;
    if (startMode != prev.startMode) {
      out.add(('start_mode', startMode.mpvValue));
    }
    if (startPeriods != prev.startPeriods) return null;
    if (startSilence != prev.startSilence) return null;
    if (startThreshold != prev.startThreshold) {
      out.add(('start_threshold', _wireDouble(startThreshold)));
    }
    if (stopDuration != prev.stopDuration) return null;
    if (stopMode != prev.stopMode) {
      out.add(('stop_mode', stopMode.mpvValue));
    }
    if (stopPeriods != prev.stopPeriods) return null;
    if (stopSilence != prev.stopSilence) return null;
    if (stopThreshold != prev.stopThreshold) {
      out.add(('stop_threshold', _wireDouble(stopThreshold)));
    }
    if (timestamp != prev.timestamp) return null;
    if (window != prev.window) return null;
    return out;
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
/// - [channels]: Specify which channels to filter, by default all available channels are filtered. (range 0..0, default "all", runtime-tunable)
/// - [compression]: Set the maximum compression factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples compression. This option is used only if @option{threshold} option is set to value greater than 0.0, then in such cases when local peak is lower or same as value set by @option{threshold} all samples belonging to that peak's half-cycle will be compressed by current compression factor. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [expansion]: Set the maximum expansion factor. Allowed range is from 1.0 to 50.0. Default value is 2.0. This option controls maximum local half-cycle of samples expansion. The maximum expansion would be such that local peak value reaches target peak value but never to surpass it and that ratio between new and previous peak value does not surpass this option value. (range 1.0..50.0, default 2.0, runtime-tunable)
/// - [fall]: Set the compression raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast compression factor is raised per each new half-cycle until it reaches @option{compression} value. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [invert]: Enable inverted filtering, by default is disabled. This inverts interpretation of @option{threshold} option. When enabled any half-cycle of samples with their local peak value below or same as @option{threshold} option will be expanded otherwise it will be compressed. (range 0..1, default 0, runtime-tunable)
/// - [link]: Link channels when calculating gain applied to each filtered channel sample, by default is disabled. When disabled each filtered channel gain calculation is independent, otherwise when this option is enabled the minimum of all possible gains for each filtered channel is used. (range 0..1, default 0, runtime-tunable)
/// - [peak]: Set the expansion target peak value. This specifies the highest allowed absolute amplitude level for the normalized audio input. Default value is 0.95. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.95, runtime-tunable)
/// - [raise]: Set the expansion raising amount per each half-cycle of samples. Default value is 0.001. Allowed range is from 0.0 to 1.0. This controls how fast expansion factor is raised per each new half-cycle until it reaches @option{expansion} value. Setting this options too high may lead to distortions. (range 0.0..1.0, default 0.001, runtime-tunable)
/// - [rms]: Set the expansion target RMS value. This specifies the highest allowed RMS level for the normalized audio input. Default value is 0.0, thus disabled. Allowed range is from 0.0 to 1.0. (range 0.0..1.0, default 0.0, runtime-tunable)
/// - [threshold]: Set the threshold value. Default value is 0.0. Allowed range is from 0.0 to 1.0. This option specifies which half-cycles of samples will be compressed and which will be expanded. Any half-cycle samples with their local peak value below or same as this option value will be compressed by current compression factor, otherwise, if greater than threshold value they will be expanded with expansion factor so that it could reach peak target value but never surpass it. (range 0.0..1.0, default 0, runtime-tunable)
final class SpeechnormEffect extends AudioEffect {
  /// Default value for [compression].
  static const double compressionDefault = 2.0;

  /// Minimum value for [compression].
  static const double compressionMin = 1.0;

  /// Maximum value for [compression].
  static const double compressionMax = 50.0;

  /// Default value for [expansion].
  static const double expansionDefault = 2.0;

  /// Minimum value for [expansion].
  static const double expansionMin = 1.0;

  /// Maximum value for [expansion].
  static const double expansionMax = 50.0;

  /// Default value for [fall].
  static const double fallDefault = 0.001;

  /// Minimum value for [fall].
  static const double fallMin = 0.0;

  /// Maximum value for [fall].
  static const double fallMax = 1.0;

  /// Default value for [peak].
  static const double peakDefault = 0.95;

  /// Minimum value for [peak].
  static const double peakMin = 0.0;

  /// Maximum value for [peak].
  static const double peakMax = 1.0;

  /// Default value for [raise].
  static const double raiseDefault = 0.001;

  /// Minimum value for [raise].
  static const double raiseMin = 0.0;

  /// Maximum value for [raise].
  static const double raiseMax = 1.0;

  /// Default value for [rms].
  static const double rmsDefault = 0.0;

  /// Minimum value for [rms].
  static const double rmsMin = 0.0;

  /// Maximum value for [rms].
  static const double rmsMax = 1.0;

  /// Default value for [threshold].
  static const double thresholdDefault = 0.0;

  /// Minimum value for [threshold].
  static const double thresholdMin = 0.0;

  /// Maximum value for [threshold].
  static const double thresholdMax = 1.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set channels to filter
  final String channels;

  /// set the max compression factor
  final double compression;

  /// set the max expansion factor
  final double expansion;

  /// set the compression raising amount
  final double fall;

  /// set inverted filtering
  final bool invert;

  /// set linked channels filtering
  final bool link;

  /// set the peak value
  final double peak;

  /// set the expansion raising amount
  final double raise;

  /// set the RMS value
  final double rms;

  /// set the threshold value
  final double threshold;

  /// Creates an [SpeechnormEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SpeechnormEffect({
    this.enabled = true,
    this.channels = 'all',
    this.compression = 2.0,
    this.expansion = 2.0,
    this.fall = 0.001,
    this.invert = false,
    this.link = false,
    this.peak = 0.95,
    this.raise = 0.001,
    this.rms = 0.0,
    this.threshold = 0.0,
  });

  @override
  String get filterName => 'speechnorm';

  @override
  AudioFilter get filter => AudioFilter.speechnorm;

  /// Returns a copy of this [SpeechnormEffect] with the given fields replaced.
  SpeechnormEffect copyWith({
    bool? enabled,
    String? channels,
    double? compression,
    double? expansion,
    double? fall,
    bool? invert,
    bool? link,
    double? peak,
    double? raise,
    double? rms,
    double? threshold,
  }) => SpeechnormEffect(
    enabled: enabled ?? this.enabled,
    channels: channels ?? this.channels,
    compression: compression ?? this.compression,
    expansion: expansion ?? this.expansion,
    fall: fall ?? this.fall,
    invert: invert ?? this.invert,
    link: link ?? this.link,
    peak: peak ?? this.peak,
    raise: raise ?? this.raise,
    rms: rms ?? this.rms,
    threshold: threshold ?? this.threshold,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeechnormEffect &&
          other.enabled == enabled &&
          other.channels == channels &&
          other.compression == compression &&
          other.expansion == expansion &&
          other.fall == fall &&
          other.invert == invert &&
          other.link == link &&
          other.peak == peak &&
          other.raise == raise &&
          other.rms == rms &&
          other.threshold == threshold);

  @override
  int get hashCode => Object.hash(
    enabled,
    channels,
    compression,
    expansion,
    fall,
    invert,
    link,
    peak,
    raise,
    rms,
    threshold,
  );

  @override
  String toString() =>
      'SpeechnormEffect(enabled: $enabled, channels: $channels, compression: $compression, expansion: $expansion, fall: $fall, invert: $invert, link: $link, peak: $peak, raise: $raise, rms: $rms, threshold: $threshold)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(
      compression >= compressionMin,
      'speechnorm.compression must be >= 1.0',
    );
    assert(
      compression <= compressionMax,
      'speechnorm.compression must be <= 50.0',
    );
    assert(expansion >= expansionMin, 'speechnorm.expansion must be >= 1.0');
    assert(expansion <= expansionMax, 'speechnorm.expansion must be <= 50.0');
    assert(fall >= fallMin, 'speechnorm.fall must be >= 0.0');
    assert(fall <= fallMax, 'speechnorm.fall must be <= 1.0');
    assert(peak >= peakMin, 'speechnorm.peak must be >= 0.0');
    assert(peak <= peakMax, 'speechnorm.peak must be <= 1.0');
    assert(raise >= raiseMin, 'speechnorm.raise must be >= 0.0');
    assert(raise <= raiseMax, 'speechnorm.raise must be <= 1.0');
    assert(rms >= rmsMin, 'speechnorm.rms must be >= 0.0');
    assert(rms <= rmsMax, 'speechnorm.rms must be <= 1.0');
    assert(threshold >= thresholdMin, 'speechnorm.threshold must be >= 0.0');
    assert(threshold <= thresholdMax, 'speechnorm.threshold must be <= 1.0');
    final parts = <String>[];
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (compression != 2.0)
      parts.add('compression=' + _wireDouble(compression));
    if (expansion != 2.0) parts.add('expansion=' + _wireDouble(expansion));
    if (fall != 0.001) parts.add('fall=' + _wireDouble(fall));
    if (invert != false) parts.add('invert=' + (invert ? '1' : '0'));
    if (link != false) parts.add('link=' + (link ? '1' : '0'));
    if (peak != 0.95) parts.add('peak=' + _wireDouble(peak));
    if (raise != 0.001) parts.add('raise=' + _wireDouble(raise));
    if (rms != 0.0) parts.add('rms=' + _wireDouble(rms));
    if (threshold != 0.0) parts.add('threshold=' + _wireDouble(threshold));
    return parts.isEmpty
        ? 'lavfi-speechnorm'
        : 'lavfi-speechnorm=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SpeechnormEffect prev) {
    final out = <(String, String)>[];
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (compression != prev.compression) {
      out.add(('compression', _wireDouble(compression)));
    }
    if (expansion != prev.expansion) {
      out.add(('expansion', _wireDouble(expansion)));
    }
    if (fall != prev.fall) {
      out.add(('fall', _wireDouble(fall)));
    }
    if (invert != prev.invert) {
      out.add(('invert', (invert ? '1' : '0')));
    }
    if (link != prev.link) {
      out.add(('link', (link ? '1' : '0')));
    }
    if (peak != prev.peak) {
      out.add(('peak', _wireDouble(peak)));
    }
    if (raise != prev.raise) {
      out.add(('raise', _wireDouble(raise)));
    }
    if (rms != prev.rms) {
      out.add(('rms', _wireDouble(rms)));
    }
    if (threshold != prev.threshold) {
      out.add(('threshold', _wireDouble(threshold)));
    }
    return out;
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
/// - [balanceIn]: Set input balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [balanceOut]: Set output balance between both channels. Default is 0. Allowed range is from -1 to 1. (range -1..1, default 0, runtime-tunable)
/// - [base]: set stereo base (range -1..1, default 0, runtime-tunable)
/// - [bmodeIn]: set balance in mode (range 0..2, default 0, runtime-tunable)
/// - [bmodeOut]: set balance out mode (range 0..2, default 0, runtime-tunable)
/// - [delay]: set delay (range -20..20, default 0, runtime-tunable)
/// - [levelIn]: Set input level before filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [levelOut]: Set output level after filtering for both channels. Defaults is 1. Allowed range is from 0.015625 to 64. (range 0.015625..64, default 1, runtime-tunable)
/// - [mlev]: set middle level (range 0.015625..64, default 1, runtime-tunable)
/// - [mode]: Set stereo mode. Available values are: (range 0..10, default 0, runtime-tunable)
/// - [mpan]: set middle pan (range -1..1, default 0, runtime-tunable)
/// - [mutel]: Mute the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [muter]: Mute the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phase]: set stereo phase (range 0..360, default 0, runtime-tunable)
/// - [phasel]: Change the phase of the left channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [phaser]: Change the phase of the right channel. Disabled by default. (range 0..1, default 0, runtime-tunable)
/// - [sbal]: set side balance (range -1..1, default 0, runtime-tunable)
/// - [sclevel]: set S/C level (range 1..100, default 1, runtime-tunable)
/// - [slev]: set side level (range 0.015625..64, default 1, runtime-tunable)
/// - [softclip]: Enable softclipping. Results in analog distortion instead of harsh digital 0dB clipping. Disabled by default. (range 0..1, default 0, runtime-tunable)
final class StereotoolsEffect extends AudioEffect {
  /// Default value for [balanceIn].
  static const double balanceInDefault = 0.0;

  /// Minimum value for [balanceIn].
  static const double balanceInMin = -1.0;

  /// Maximum value for [balanceIn].
  static const double balanceInMax = 1.0;

  /// Default value for [balanceOut].
  static const double balanceOutDefault = 0.0;

  /// Minimum value for [balanceOut].
  static const double balanceOutMin = -1.0;

  /// Maximum value for [balanceOut].
  static const double balanceOutMax = 1.0;

  /// Default value for [base].
  static const double baseDefault = 0.0;

  /// Minimum value for [base].
  static const double baseMin = -1.0;

  /// Maximum value for [base].
  static const double baseMax = 1.0;

  /// Default value for [delay].
  static const double delayDefault = 0.0;

  /// Minimum value for [delay].
  static const double delayMin = -20.0;

  /// Maximum value for [delay].
  static const double delayMax = 20.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.015625;

  /// Maximum value for [levelIn].
  static const double levelInMax = 64.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.015625;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 64.0;

  /// Default value for [mlev].
  static const double mlevDefault = 1.0;

  /// Minimum value for [mlev].
  static const double mlevMin = 0.015625;

  /// Maximum value for [mlev].
  static const double mlevMax = 64.0;

  /// Default value for [mpan].
  static const double mpanDefault = 0.0;

  /// Minimum value for [mpan].
  static const double mpanMin = -1.0;

  /// Maximum value for [mpan].
  static const double mpanMax = 1.0;

  /// Default value for [phase].
  static const double phaseDefault = 0.0;

  /// Minimum value for [phase].
  static const double phaseMin = 0.0;

  /// Maximum value for [phase].
  static const double phaseMax = 360.0;

  /// Default value for [sbal].
  static const double sbalDefault = 0.0;

  /// Minimum value for [sbal].
  static const double sbalMin = -1.0;

  /// Maximum value for [sbal].
  static const double sbalMax = 1.0;

  /// Default value for [sclevel].
  static const double sclevelDefault = 1.0;

  /// Minimum value for [sclevel].
  static const double sclevelMin = 1.0;

  /// Maximum value for [sclevel].
  static const double sclevelMax = 100.0;

  /// Default value for [slev].
  static const double slevDefault = 1.0;

  /// Minimum value for [slev].
  static const double slevMin = 0.015625;

  /// Maximum value for [slev].
  static const double slevMax = 64.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set balance in
  final double balanceIn;

  /// set balance out
  final double balanceOut;

  /// set stereo base
  final double base;

  /// set balance in mode
  final StereotoolsBmode bmodeIn;

  /// set balance out mode
  final StereotoolsBmode bmodeOut;

  /// set delay
  final double delay;

  /// set level in
  final double levelIn;

  /// set level out
  final double levelOut;

  /// set middle level
  final double mlev;

  /// set stereo mode
  final StereotoolsMode mode;

  /// set middle pan
  final double mpan;

  /// mute L
  final bool mutel;

  /// mute R
  final bool muter;

  /// set stereo phase
  final double phase;

  /// phase L
  final bool phasel;

  /// phase R
  final bool phaser;

  /// set side balance
  final double sbal;

  /// set S/C level
  final double sclevel;

  /// set side level
  final double slev;

  /// enable softclip
  final bool softclip;

  /// Creates an [StereotoolsEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const StereotoolsEffect({
    this.enabled = true,
    this.balanceIn = 0.0,
    this.balanceOut = 0.0,
    this.base = 0.0,
    this.bmodeIn = StereotoolsBmode.balance,
    this.bmodeOut = StereotoolsBmode.balance,
    this.delay = 0.0,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.mlev = 1.0,
    this.mode = StereotoolsMode.lrToLr,
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

  @override
  String get filterName => 'stereotools';

  @override
  AudioFilter get filter => AudioFilter.stereotools;

  /// Returns a copy of this [StereotoolsEffect] with the given fields replaced.
  StereotoolsEffect copyWith({
    bool? enabled,
    double? balanceIn,
    double? balanceOut,
    double? base,
    StereotoolsBmode? bmodeIn,
    StereotoolsBmode? bmodeOut,
    double? delay,
    double? levelIn,
    double? levelOut,
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
  }) => StereotoolsEffect(
    enabled: enabled ?? this.enabled,
    balanceIn: balanceIn ?? this.balanceIn,
    balanceOut: balanceOut ?? this.balanceOut,
    base: base ?? this.base,
    bmodeIn: bmodeIn ?? this.bmodeIn,
    bmodeOut: bmodeOut ?? this.bmodeOut,
    delay: delay ?? this.delay,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
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
      (other is StereotoolsEffect &&
          other.enabled == enabled &&
          other.balanceIn == balanceIn &&
          other.balanceOut == balanceOut &&
          other.base == base &&
          other.bmodeIn == bmodeIn &&
          other.bmodeOut == bmodeOut &&
          other.delay == delay &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
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
    balanceIn,
    balanceOut,
    base,
    bmodeIn,
    bmodeOut,
    delay,
    levelIn,
    levelOut,
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
    softclip,
  ]);

  @override
  String toString() =>
      'StereotoolsEffect(enabled: $enabled, balanceIn: $balanceIn, balanceOut: $balanceOut, base: $base, bmodeIn: $bmodeIn, bmodeOut: $bmodeOut, delay: $delay, levelIn: $levelIn, levelOut: $levelOut, mlev: $mlev, mode: $mode, mpan: $mpan, mutel: $mutel, muter: $muter, phase: $phase, phasel: $phasel, phaser: $phaser, sbal: $sbal, sclevel: $sclevel, slev: $slev, softclip: $softclip)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(balanceIn >= balanceInMin, 'stereotools.balance_in must be >= -1');
    assert(balanceIn <= balanceInMax, 'stereotools.balance_in must be <= 1');
    assert(
      balanceOut >= balanceOutMin,
      'stereotools.balance_out must be >= -1',
    );
    assert(balanceOut <= balanceOutMax, 'stereotools.balance_out must be <= 1');
    assert(base >= baseMin, 'stereotools.base must be >= -1');
    assert(base <= baseMax, 'stereotools.base must be <= 1');
    assert(delay >= delayMin, 'stereotools.delay must be >= -20');
    assert(delay <= delayMax, 'stereotools.delay must be <= 20');
    assert(levelIn >= levelInMin, 'stereotools.level_in must be >= 0.015625');
    assert(levelIn <= levelInMax, 'stereotools.level_in must be <= 64');
    assert(
      levelOut >= levelOutMin,
      'stereotools.level_out must be >= 0.015625',
    );
    assert(levelOut <= levelOutMax, 'stereotools.level_out must be <= 64');
    assert(mlev >= mlevMin, 'stereotools.mlev must be >= 0.015625');
    assert(mlev <= mlevMax, 'stereotools.mlev must be <= 64');
    assert(mpan >= mpanMin, 'stereotools.mpan must be >= -1');
    assert(mpan <= mpanMax, 'stereotools.mpan must be <= 1');
    assert(phase >= phaseMin, 'stereotools.phase must be >= 0');
    assert(phase <= phaseMax, 'stereotools.phase must be <= 360');
    assert(sbal >= sbalMin, 'stereotools.sbal must be >= -1');
    assert(sbal <= sbalMax, 'stereotools.sbal must be <= 1');
    assert(sclevel >= sclevelMin, 'stereotools.sclevel must be >= 1');
    assert(sclevel <= sclevelMax, 'stereotools.sclevel must be <= 100');
    assert(slev >= slevMin, 'stereotools.slev must be >= 0.015625');
    assert(slev <= slevMax, 'stereotools.slev must be <= 64');
    final parts = <String>[];
    if (balanceIn != 0.0) parts.add('balance_in=' + _wireDouble(balanceIn));
    if (balanceOut != 0.0) parts.add('balance_out=' + _wireDouble(balanceOut));
    if (base != 0.0) parts.add('base=' + _wireDouble(base));
    if (bmodeIn != StereotoolsBmode.balance)
      parts.add('bmode_in=' + bmodeIn.mpvValue);
    if (bmodeOut != StereotoolsBmode.balance)
      parts.add('bmode_out=' + bmodeOut.mpvValue);
    if (delay != 0.0) parts.add('delay=' + _wireDouble(delay));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (mlev != 1.0) parts.add('mlev=' + _wireDouble(mlev));
    if (mode != StereotoolsMode.lrToLr) parts.add('mode=' + mode.mpvValue);
    if (mpan != 0.0) parts.add('mpan=' + _wireDouble(mpan));
    if (mutel != false) parts.add('mutel=' + (mutel ? '1' : '0'));
    if (muter != false) parts.add('muter=' + (muter ? '1' : '0'));
    if (phase != 0.0) parts.add('phase=' + _wireDouble(phase));
    if (phasel != false) parts.add('phasel=' + (phasel ? '1' : '0'));
    if (phaser != false) parts.add('phaser=' + (phaser ? '1' : '0'));
    if (sbal != 0.0) parts.add('sbal=' + _wireDouble(sbal));
    if (sclevel != 1.0) parts.add('sclevel=' + _wireDouble(sclevel));
    if (slev != 1.0) parts.add('slev=' + _wireDouble(slev));
    if (softclip != false) parts.add('softclip=' + (softclip ? '1' : '0'));
    return parts.isEmpty
        ? 'lavfi-stereotools'
        : 'lavfi-stereotools=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant StereotoolsEffect prev) {
    final out = <(String, String)>[];
    if (balanceIn != prev.balanceIn) {
      out.add(('balance_in', _wireDouble(balanceIn)));
    }
    if (balanceOut != prev.balanceOut) {
      out.add(('balance_out', _wireDouble(balanceOut)));
    }
    if (base != prev.base) {
      out.add(('base', _wireDouble(base)));
    }
    if (bmodeIn != prev.bmodeIn) {
      out.add(('bmode_in', bmodeIn.mpvValue));
    }
    if (bmodeOut != prev.bmodeOut) {
      out.add(('bmode_out', bmodeOut.mpvValue));
    }
    if (delay != prev.delay) {
      out.add(('delay', _wireDouble(delay)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (mlev != prev.mlev) {
      out.add(('mlev', _wireDouble(mlev)));
    }
    if (mode != prev.mode) {
      out.add(('mode', mode.mpvValue));
    }
    if (mpan != prev.mpan) {
      out.add(('mpan', _wireDouble(mpan)));
    }
    if (mutel != prev.mutel) {
      out.add(('mutel', (mutel ? '1' : '0')));
    }
    if (muter != prev.muter) {
      out.add(('muter', (muter ? '1' : '0')));
    }
    if (phase != prev.phase) {
      out.add(('phase', _wireDouble(phase)));
    }
    if (phasel != prev.phasel) {
      out.add(('phasel', (phasel ? '1' : '0')));
    }
    if (phaser != prev.phaser) {
      out.add(('phaser', (phaser ? '1' : '0')));
    }
    if (sbal != prev.sbal) {
      out.add(('sbal', _wireDouble(sbal)));
    }
    if (sclevel != prev.sclevel) {
      out.add(('sclevel', _wireDouble(sclevel)));
    }
    if (slev != prev.slev) {
      out.add(('slev', _wireDouble(slev)));
    }
    if (softclip != prev.softclip) {
      out.add(('softclip', (softclip ? '1' : '0')));
    }
    return out;
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
/// - [crossfeed]: Cross feed of left into right with inverted phase. This helps in suppressing the mono. If the value is 1 it will cancel all the signal common to both channels. Default is 0.3. (range 0..0.8, default .3, runtime-tunable)
/// - [delay]: Time in milliseconds of the delay of left signal into right and vice versa. Default is 20 milliseconds. (range 1..100, default 20)
/// - [drymix]: Set level of input signal of original channel. Default is 0.8. (range 0..1.0, default .8, runtime-tunable)
/// - [feedback]: Amount of gain in delayed signal into right and vice versa. Gives a delay effect of left signal in right output and vice versa which gives widening effect. Default is 0.3. (range 0..0.9, default .3, runtime-tunable)
final class StereowidenEffect extends AudioEffect {
  /// Default value for [crossfeed].
  static const double crossfeedDefault = .3;

  /// Minimum value for [crossfeed].
  static const double crossfeedMin = 0.0;

  /// Maximum value for [crossfeed].
  static const double crossfeedMax = 0.8;

  /// Default value for [delay].
  static const double delayDefault = 20.0;

  /// Minimum value for [delay].
  static const double delayMin = 1.0;

  /// Maximum value for [delay].
  static const double delayMax = 100.0;

  /// Default value for [drymix].
  static const double drymixDefault = .8;

  /// Minimum value for [drymix].
  static const double drymixMin = 0.0;

  /// Maximum value for [drymix].
  static const double drymixMax = 1.0;

  /// Default value for [feedback].
  static const double feedbackDefault = .3;

  /// Minimum value for [feedback].
  static const double feedbackMin = 0.0;

  /// Maximum value for [feedback].
  static const double feedbackMax = 0.9;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set cross feed
  final double crossfeed;

  /// set delay time
  final double delay;

  /// set dry-mix
  final double drymix;

  /// set feedback gain
  final double feedback;

  /// Creates an [StereowidenEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const StereowidenEffect({
    this.enabled = true,
    this.crossfeed = .3,
    this.delay = 20.0,
    this.drymix = .8,
    this.feedback = .3,
  });

  @override
  String get filterName => 'stereowiden';

  @override
  AudioFilter get filter => AudioFilter.stereowiden;

  /// Returns a copy of this [StereowidenEffect] with the given fields replaced.
  StereowidenEffect copyWith({
    bool? enabled,
    double? crossfeed,
    double? delay,
    double? drymix,
    double? feedback,
  }) => StereowidenEffect(
    enabled: enabled ?? this.enabled,
    crossfeed: crossfeed ?? this.crossfeed,
    delay: delay ?? this.delay,
    drymix: drymix ?? this.drymix,
    feedback: feedback ?? this.feedback,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StereowidenEffect &&
          other.enabled == enabled &&
          other.crossfeed == crossfeed &&
          other.delay == delay &&
          other.drymix == drymix &&
          other.feedback == feedback);

  @override
  int get hashCode => Object.hash(enabled, crossfeed, delay, drymix, feedback);

  @override
  String toString() =>
      'StereowidenEffect(enabled: $enabled, crossfeed: $crossfeed, delay: $delay, drymix: $drymix, feedback: $feedback)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(crossfeed >= crossfeedMin, 'stereowiden.crossfeed must be >= 0');
    assert(crossfeed <= crossfeedMax, 'stereowiden.crossfeed must be <= 0.8');
    assert(delay >= delayMin, 'stereowiden.delay must be >= 1');
    assert(delay <= delayMax, 'stereowiden.delay must be <= 100');
    assert(drymix >= drymixMin, 'stereowiden.drymix must be >= 0');
    assert(drymix <= drymixMax, 'stereowiden.drymix must be <= 1.0');
    assert(feedback >= feedbackMin, 'stereowiden.feedback must be >= 0');
    assert(feedback <= feedbackMax, 'stereowiden.feedback must be <= 0.9');
    final parts = <String>[];
    if (crossfeed != .3) parts.add('crossfeed=' + _wireDouble(crossfeed));
    if (delay != 20.0) parts.add('delay=' + _wireDouble(delay));
    if (drymix != .8) parts.add('drymix=' + _wireDouble(drymix));
    if (feedback != .3) parts.add('feedback=' + _wireDouble(feedback));
    return parts.isEmpty
        ? 'lavfi-stereowiden'
        : 'lavfi-stereowiden=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant StereowidenEffect prev) {
    final out = <(String, String)>[];
    if (crossfeed != prev.crossfeed) {
      out.add(('crossfeed', _wireDouble(crossfeed)));
    }
    if (delay != prev.delay) return null;
    if (drymix != prev.drymix) {
      out.add(('drymix', _wireDouble(drymix)));
    }
    if (feedback != prev.feedback) {
      out.add(('feedback', _wireDouble(feedback)));
    }
    return out;
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
final class SuperequalizerEffect extends AudioEffect {
  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// Raw values for parameters whose names start with a digit,
  /// keyed by their original ffmpeg option name.
  final Map<String, double> params;

  /// Creates an [SuperequalizerEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SuperequalizerEffect({
    this.enabled = true,
    this.params = const <String, double>{},
  });

  @override
  String get filterName => 'superequalizer';

  @override
  AudioFilter get filter => AudioFilter.superequalizer;

  /// Returns a copy of this [SuperequalizerEffect] with the given fields replaced.
  SuperequalizerEffect copyWith({bool? enabled, Map<String, double>? params}) =>
      SuperequalizerEffect(
        enabled: enabled ?? this.enabled,
        params: params ?? this.params,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SuperequalizerEffect &&
          other.enabled == enabled &&
          _mapEq(params, other.params));

  @override
  int get hashCode => Object.hash(
    enabled,
    Object.hashAllUnordered(
      params.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'SuperequalizerEffect(enabled: $enabled, params: $params)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    final parts = <String>[];
    params.forEach((k, v) => parts.add('$k=' + _wireDouble(v)));
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
/// - [allx]: Set spread usage of stereo image across X axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [ally]: Set spread usage of stereo image across Y axis for all channels. Allowed range is from `-1` to `15`. By default this value is negative `-1`, and thus unused. (range -1..15, default -1, runtime-tunable)
/// - [angle]: Set angle of stereo surround transform, Allowed range is from `0` to `360`. Default is `90`. (range 0..360, default 90, runtime-tunable)
/// - [bcIn]: Set back center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bcOut]: Set back center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [bcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [blIn]: Set back left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [blOut]: Set back left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [blx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [brIn]: Set back right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [brOut]: Set back right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [brx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [bry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [chlIn]: Set input channel layout. By default, this is `stereo`.  See channel layout syntax for the required syntax. (range 0..0, default "stereo")
/// - [chlOut]: Set output channel layout. By default, this is `5.1`.  See channel layout syntax for the required syntax. (range 0..0, default "5.1")
/// - [fcIn]: Set front center input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fcOut]: Set front center output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [fcx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fcy]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [flIn]: Set front left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [flOut]: Set front left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [flx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [focus]: Set focus of stereo surround transform, Allowed range is from `-1` to `1`. Default is `0`. (range -1..1, default 0, runtime-tunable)
/// - [frIn]: Set front right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [frOut]: Set front right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [frx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [fry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [levelIn]: Set input volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [levelOut]: Set output volume level. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfe]: Enable LFE channel output if output channel layout has it. By default, this is enabled. (range 0..1, default 1, runtime-tunable)
/// - [lfeHigh]: Set LFE high cut off frequency. By default, this is `256` Hz. (range 0..512, default 256)
/// - [lfeIn]: Set LFE input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [lfeLow]: Set LFE low cut off frequency. By default, this is `128` Hz. (range 0..256, default 128)
/// - [lfeMode]: Set LFE mode, can be `add` or `sub`. Default is `add`. In `add` mode, LFE channel is created from input audio and added to output. In `sub` mode, LFE channel is created from input audio and added to output but also all non-LFE output channels are subtracted with output LFE channel. (range 0..1, default 0, runtime-tunable)
/// - [lfeOut]: Set LFE output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [overlap]: set window overlap (range 0..1, default 0.5, runtime-tunable)
/// - [slIn]: Set side left input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [slOut]: Set side left output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [slx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sly]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [smooth]: Set temporal smoothness strength, used to gradually change factors when transforming stereo sound in time. Allowed range is from `0.0` to `1.0`. Useful to improve output quality with `focus` option values greater than `0.0`. Default is `0.0`. Only values inside this range and without edges are effective. (range 0..1, default 0, runtime-tunable)
/// - [srIn]: Set side right input volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [srOut]: Set side right output volume. By default, this is `1`. (range 0..10, default 1, runtime-tunable)
/// - [srx]: Set spread usage of stereo image across X axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [sry]: Set spread usage of stereo image across Y axis for each channel. Allowed range is from `0.06` to `15`. By default this value is `0.5`. (range .06..15, default 0.5, runtime-tunable)
/// - [winFunc]: Set window function.  It accepts the following values: (default WFUNC_HANNING)
/// - [winSize]: Set window size. Allowed range is from `1024` to `65536`. Default size is `4096`. (range 1024..65536, default 4096)
final class SurroundEffect extends AudioEffect {
  /// Default value for [allx].
  static const double allxDefault = -1.0;

  /// Minimum value for [allx].
  static const double allxMin = -1.0;

  /// Maximum value for [allx].
  static const double allxMax = 15.0;

  /// Default value for [ally].
  static const double allyDefault = -1.0;

  /// Minimum value for [ally].
  static const double allyMin = -1.0;

  /// Maximum value for [ally].
  static const double allyMax = 15.0;

  /// Default value for [angle].
  static const double angleDefault = 90.0;

  /// Minimum value for [angle].
  static const double angleMin = 0.0;

  /// Maximum value for [angle].
  static const double angleMax = 360.0;

  /// Default value for [bcIn].
  static const double bcInDefault = 1.0;

  /// Minimum value for [bcIn].
  static const double bcInMin = 0.0;

  /// Maximum value for [bcIn].
  static const double bcInMax = 10.0;

  /// Default value for [bcOut].
  static const double bcOutDefault = 1.0;

  /// Minimum value for [bcOut].
  static const double bcOutMin = 0.0;

  /// Maximum value for [bcOut].
  static const double bcOutMax = 10.0;

  /// Default value for [bcx].
  static const double bcxDefault = 0.5;

  /// Minimum value for [bcx].
  static const double bcxMin = .06;

  /// Maximum value for [bcx].
  static const double bcxMax = 15.0;

  /// Default value for [bcy].
  static const double bcyDefault = 0.5;

  /// Minimum value for [bcy].
  static const double bcyMin = .06;

  /// Maximum value for [bcy].
  static const double bcyMax = 15.0;

  /// Default value for [blIn].
  static const double blInDefault = 1.0;

  /// Minimum value for [blIn].
  static const double blInMin = 0.0;

  /// Maximum value for [blIn].
  static const double blInMax = 10.0;

  /// Default value for [blOut].
  static const double blOutDefault = 1.0;

  /// Minimum value for [blOut].
  static const double blOutMin = 0.0;

  /// Maximum value for [blOut].
  static const double blOutMax = 10.0;

  /// Default value for [blx].
  static const double blxDefault = 0.5;

  /// Minimum value for [blx].
  static const double blxMin = .06;

  /// Maximum value for [blx].
  static const double blxMax = 15.0;

  /// Default value for [bly].
  static const double blyDefault = 0.5;

  /// Minimum value for [bly].
  static const double blyMin = .06;

  /// Maximum value for [bly].
  static const double blyMax = 15.0;

  /// Default value for [brIn].
  static const double brInDefault = 1.0;

  /// Minimum value for [brIn].
  static const double brInMin = 0.0;

  /// Maximum value for [brIn].
  static const double brInMax = 10.0;

  /// Default value for [brOut].
  static const double brOutDefault = 1.0;

  /// Minimum value for [brOut].
  static const double brOutMin = 0.0;

  /// Maximum value for [brOut].
  static const double brOutMax = 10.0;

  /// Default value for [brx].
  static const double brxDefault = 0.5;

  /// Minimum value for [brx].
  static const double brxMin = .06;

  /// Maximum value for [brx].
  static const double brxMax = 15.0;

  /// Default value for [bry].
  static const double bryDefault = 0.5;

  /// Minimum value for [bry].
  static const double bryMin = .06;

  /// Maximum value for [bry].
  static const double bryMax = 15.0;

  /// Default value for [fcIn].
  static const double fcInDefault = 1.0;

  /// Minimum value for [fcIn].
  static const double fcInMin = 0.0;

  /// Maximum value for [fcIn].
  static const double fcInMax = 10.0;

  /// Default value for [fcOut].
  static const double fcOutDefault = 1.0;

  /// Minimum value for [fcOut].
  static const double fcOutMin = 0.0;

  /// Maximum value for [fcOut].
  static const double fcOutMax = 10.0;

  /// Default value for [fcx].
  static const double fcxDefault = 0.5;

  /// Minimum value for [fcx].
  static const double fcxMin = .06;

  /// Maximum value for [fcx].
  static const double fcxMax = 15.0;

  /// Default value for [fcy].
  static const double fcyDefault = 0.5;

  /// Minimum value for [fcy].
  static const double fcyMin = .06;

  /// Maximum value for [fcy].
  static const double fcyMax = 15.0;

  /// Default value for [flIn].
  static const double flInDefault = 1.0;

  /// Minimum value for [flIn].
  static const double flInMin = 0.0;

  /// Maximum value for [flIn].
  static const double flInMax = 10.0;

  /// Default value for [flOut].
  static const double flOutDefault = 1.0;

  /// Minimum value for [flOut].
  static const double flOutMin = 0.0;

  /// Maximum value for [flOut].
  static const double flOutMax = 10.0;

  /// Default value for [flx].
  static const double flxDefault = 0.5;

  /// Minimum value for [flx].
  static const double flxMin = .06;

  /// Maximum value for [flx].
  static const double flxMax = 15.0;

  /// Default value for [fly].
  static const double flyDefault = 0.5;

  /// Minimum value for [fly].
  static const double flyMin = .06;

  /// Maximum value for [fly].
  static const double flyMax = 15.0;

  /// Default value for [focus].
  static const double focusDefault = 0.0;

  /// Minimum value for [focus].
  static const double focusMin = -1.0;

  /// Maximum value for [focus].
  static const double focusMax = 1.0;

  /// Default value for [frIn].
  static const double frInDefault = 1.0;

  /// Minimum value for [frIn].
  static const double frInMin = 0.0;

  /// Maximum value for [frIn].
  static const double frInMax = 10.0;

  /// Default value for [frOut].
  static const double frOutDefault = 1.0;

  /// Minimum value for [frOut].
  static const double frOutMin = 0.0;

  /// Maximum value for [frOut].
  static const double frOutMax = 10.0;

  /// Default value for [frx].
  static const double frxDefault = 0.5;

  /// Minimum value for [frx].
  static const double frxMin = .06;

  /// Maximum value for [frx].
  static const double frxMax = 15.0;

  /// Default value for [fry].
  static const double fryDefault = 0.5;

  /// Minimum value for [fry].
  static const double fryMin = .06;

  /// Maximum value for [fry].
  static const double fryMax = 15.0;

  /// Default value for [levelIn].
  static const double levelInDefault = 1.0;

  /// Minimum value for [levelIn].
  static const double levelInMin = 0.0;

  /// Maximum value for [levelIn].
  static const double levelInMax = 10.0;

  /// Default value for [levelOut].
  static const double levelOutDefault = 1.0;

  /// Minimum value for [levelOut].
  static const double levelOutMin = 0.0;

  /// Maximum value for [levelOut].
  static const double levelOutMax = 10.0;

  /// Default value for [lfeHigh].
  static const int lfeHighDefault = 256;

  /// Minimum value for [lfeHigh].
  static const int lfeHighMin = 0;

  /// Maximum value for [lfeHigh].
  static const int lfeHighMax = 512;

  /// Default value for [lfeIn].
  static const double lfeInDefault = 1.0;

  /// Minimum value for [lfeIn].
  static const double lfeInMin = 0.0;

  /// Maximum value for [lfeIn].
  static const double lfeInMax = 10.0;

  /// Default value for [lfeLow].
  static const int lfeLowDefault = 128;

  /// Minimum value for [lfeLow].
  static const int lfeLowMin = 0;

  /// Maximum value for [lfeLow].
  static const int lfeLowMax = 256;

  /// Default value for [lfeOut].
  static const double lfeOutDefault = 1.0;

  /// Minimum value for [lfeOut].
  static const double lfeOutMin = 0.0;

  /// Maximum value for [lfeOut].
  static const double lfeOutMax = 10.0;

  /// Default value for [overlap].
  static const double overlapDefault = 0.5;

  /// Minimum value for [overlap].
  static const double overlapMin = 0.0;

  /// Maximum value for [overlap].
  static const double overlapMax = 1.0;

  /// Default value for [slIn].
  static const double slInDefault = 1.0;

  /// Minimum value for [slIn].
  static const double slInMin = 0.0;

  /// Maximum value for [slIn].
  static const double slInMax = 10.0;

  /// Default value for [slOut].
  static const double slOutDefault = 1.0;

  /// Minimum value for [slOut].
  static const double slOutMin = 0.0;

  /// Maximum value for [slOut].
  static const double slOutMax = 10.0;

  /// Default value for [slx].
  static const double slxDefault = 0.5;

  /// Minimum value for [slx].
  static const double slxMin = .06;

  /// Maximum value for [slx].
  static const double slxMax = 15.0;

  /// Default value for [sly].
  static const double slyDefault = 0.5;

  /// Minimum value for [sly].
  static const double slyMin = .06;

  /// Maximum value for [sly].
  static const double slyMax = 15.0;

  /// Default value for [smooth].
  static const double smoothDefault = 0.0;

  /// Minimum value for [smooth].
  static const double smoothMin = 0.0;

  /// Maximum value for [smooth].
  static const double smoothMax = 1.0;

  /// Default value for [srIn].
  static const double srInDefault = 1.0;

  /// Minimum value for [srIn].
  static const double srInMin = 0.0;

  /// Maximum value for [srIn].
  static const double srInMax = 10.0;

  /// Default value for [srOut].
  static const double srOutDefault = 1.0;

  /// Minimum value for [srOut].
  static const double srOutMin = 0.0;

  /// Maximum value for [srOut].
  static const double srOutMax = 10.0;

  /// Default value for [srx].
  static const double srxDefault = 0.5;

  /// Minimum value for [srx].
  static const double srxMin = .06;

  /// Maximum value for [srx].
  static const double srxMax = 15.0;

  /// Default value for [sry].
  static const double sryDefault = 0.5;

  /// Minimum value for [sry].
  static const double sryMin = .06;

  /// Maximum value for [sry].
  static const double sryMax = 15.0;

  /// Default value for [winSize].
  static const int winSizeDefault = 4096;

  /// Minimum value for [winSize].
  static const int winSizeMin = 1024;

  /// Maximum value for [winSize].
  static const int winSizeMax = 65536;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set all channel's x spread
  final double allx;

  /// set all channel's y spread
  final double ally;

  /// set soundfield transform angle
  final double angle;

  /// set back center channel input level
  final double bcIn;

  /// set back center channel output level
  final double bcOut;

  /// set back center channel x spread
  final double bcx;

  /// set back center channel y spread
  final double bcy;

  /// set back left channel input level
  final double blIn;

  /// set back left channel output level
  final double blOut;

  /// set back left channel x spread
  final double blx;

  /// set back left channel y spread
  final double bly;

  /// set back right channel input level
  final double brIn;

  /// set back right channel output level
  final double brOut;

  /// set back right channel x spread
  final double brx;

  /// set back right channel y spread
  final double bry;

  /// set input channel layout
  final String chlIn;

  /// set output channel layout
  final String chlOut;

  /// set front center channel input level
  final double fcIn;

  /// set front center channel output level
  final double fcOut;

  /// set front center channel x spread
  final double fcx;

  /// set front center channel y spread
  final double fcy;

  /// set front left channel input level
  final double flIn;

  /// set front left channel output level
  final double flOut;

  /// set front left channel x spread
  final double flx;

  /// set front left channel y spread
  final double fly;

  /// set soundfield transform focus
  final double focus;

  /// set front right channel input level
  final double frIn;

  /// set front right channel output level
  final double frOut;

  /// set front right channel x spread
  final double frx;

  /// set front right channel y spread
  final double fry;

  /// set input level
  final double levelIn;

  /// set output level
  final double levelOut;

  /// output LFE
  final bool lfe;

  /// LFE high cut off
  final int lfeHigh;

  /// set lfe channel input level
  final double lfeIn;

  /// LFE low cut off
  final int lfeLow;

  /// set LFE channel mode
  final SurroundLfeMode lfeMode;

  /// set lfe channel output level
  final double lfeOut;

  /// set window overlap
  final double overlap;

  /// set side left channel input level
  final double slIn;

  /// set side left channel output level
  final double slOut;

  /// set side left channel x spread
  final double slx;

  /// set side left channel y spread
  final double sly;

  /// set temporal smoothness strength
  final double smooth;

  /// set side right channel input level
  final double srIn;

  /// set side right channel output level
  final double srOut;

  /// set side right channel x spread
  final double srx;

  /// set side right channel y spread
  final double sry;

  /// set window function
  final SurroundWinFunc winFunc;

  /// set window size
  final int winSize;

  /// Creates an [SurroundEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const SurroundEffect({
    this.enabled = true,
    this.allx = -1.0,
    this.ally = -1.0,
    this.angle = 90.0,
    this.bcIn = 1.0,
    this.bcOut = 1.0,
    this.bcx = 0.5,
    this.bcy = 0.5,
    this.blIn = 1.0,
    this.blOut = 1.0,
    this.blx = 0.5,
    this.bly = 0.5,
    this.brIn = 1.0,
    this.brOut = 1.0,
    this.brx = 0.5,
    this.bry = 0.5,
    this.chlIn = 'stereo',
    this.chlOut = '5.1',
    this.fcIn = 1.0,
    this.fcOut = 1.0,
    this.fcx = 0.5,
    this.fcy = 0.5,
    this.flIn = 1.0,
    this.flOut = 1.0,
    this.flx = 0.5,
    this.fly = 0.5,
    this.focus = 0.0,
    this.frIn = 1.0,
    this.frOut = 1.0,
    this.frx = 0.5,
    this.fry = 0.5,
    this.levelIn = 1.0,
    this.levelOut = 1.0,
    this.lfe = true,
    this.lfeHigh = 256,
    this.lfeIn = 1.0,
    this.lfeLow = 128,
    this.lfeMode = SurroundLfeMode.add,
    this.lfeOut = 1.0,
    this.overlap = 0.5,
    this.slIn = 1.0,
    this.slOut = 1.0,
    this.slx = 0.5,
    this.sly = 0.5,
    this.smooth = 0.0,
    this.srIn = 1.0,
    this.srOut = 1.0,
    this.srx = 0.5,
    this.sry = 0.5,
    this.winFunc = SurroundWinFunc.hann,
    this.winSize = 4096,
  });

  @override
  String get filterName => 'surround';

  @override
  AudioFilter get filter => AudioFilter.surround;

  /// Returns a copy of this [SurroundEffect] with the given fields replaced.
  SurroundEffect copyWith({
    bool? enabled,
    double? allx,
    double? ally,
    double? angle,
    double? bcIn,
    double? bcOut,
    double? bcx,
    double? bcy,
    double? blIn,
    double? blOut,
    double? blx,
    double? bly,
    double? brIn,
    double? brOut,
    double? brx,
    double? bry,
    String? chlIn,
    String? chlOut,
    double? fcIn,
    double? fcOut,
    double? fcx,
    double? fcy,
    double? flIn,
    double? flOut,
    double? flx,
    double? fly,
    double? focus,
    double? frIn,
    double? frOut,
    double? frx,
    double? fry,
    double? levelIn,
    double? levelOut,
    bool? lfe,
    int? lfeHigh,
    double? lfeIn,
    int? lfeLow,
    SurroundLfeMode? lfeMode,
    double? lfeOut,
    double? overlap,
    double? slIn,
    double? slOut,
    double? slx,
    double? sly,
    double? smooth,
    double? srIn,
    double? srOut,
    double? srx,
    double? sry,
    SurroundWinFunc? winFunc,
    int? winSize,
  }) => SurroundEffect(
    enabled: enabled ?? this.enabled,
    allx: allx ?? this.allx,
    ally: ally ?? this.ally,
    angle: angle ?? this.angle,
    bcIn: bcIn ?? this.bcIn,
    bcOut: bcOut ?? this.bcOut,
    bcx: bcx ?? this.bcx,
    bcy: bcy ?? this.bcy,
    blIn: blIn ?? this.blIn,
    blOut: blOut ?? this.blOut,
    blx: blx ?? this.blx,
    bly: bly ?? this.bly,
    brIn: brIn ?? this.brIn,
    brOut: brOut ?? this.brOut,
    brx: brx ?? this.brx,
    bry: bry ?? this.bry,
    chlIn: chlIn ?? this.chlIn,
    chlOut: chlOut ?? this.chlOut,
    fcIn: fcIn ?? this.fcIn,
    fcOut: fcOut ?? this.fcOut,
    fcx: fcx ?? this.fcx,
    fcy: fcy ?? this.fcy,
    flIn: flIn ?? this.flIn,
    flOut: flOut ?? this.flOut,
    flx: flx ?? this.flx,
    fly: fly ?? this.fly,
    focus: focus ?? this.focus,
    frIn: frIn ?? this.frIn,
    frOut: frOut ?? this.frOut,
    frx: frx ?? this.frx,
    fry: fry ?? this.fry,
    levelIn: levelIn ?? this.levelIn,
    levelOut: levelOut ?? this.levelOut,
    lfe: lfe ?? this.lfe,
    lfeHigh: lfeHigh ?? this.lfeHigh,
    lfeIn: lfeIn ?? this.lfeIn,
    lfeLow: lfeLow ?? this.lfeLow,
    lfeMode: lfeMode ?? this.lfeMode,
    lfeOut: lfeOut ?? this.lfeOut,
    overlap: overlap ?? this.overlap,
    slIn: slIn ?? this.slIn,
    slOut: slOut ?? this.slOut,
    slx: slx ?? this.slx,
    sly: sly ?? this.sly,
    smooth: smooth ?? this.smooth,
    srIn: srIn ?? this.srIn,
    srOut: srOut ?? this.srOut,
    srx: srx ?? this.srx,
    sry: sry ?? this.sry,
    winFunc: winFunc ?? this.winFunc,
    winSize: winSize ?? this.winSize,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurroundEffect &&
          other.enabled == enabled &&
          other.allx == allx &&
          other.ally == ally &&
          other.angle == angle &&
          other.bcIn == bcIn &&
          other.bcOut == bcOut &&
          other.bcx == bcx &&
          other.bcy == bcy &&
          other.blIn == blIn &&
          other.blOut == blOut &&
          other.blx == blx &&
          other.bly == bly &&
          other.brIn == brIn &&
          other.brOut == brOut &&
          other.brx == brx &&
          other.bry == bry &&
          other.chlIn == chlIn &&
          other.chlOut == chlOut &&
          other.fcIn == fcIn &&
          other.fcOut == fcOut &&
          other.fcx == fcx &&
          other.fcy == fcy &&
          other.flIn == flIn &&
          other.flOut == flOut &&
          other.flx == flx &&
          other.fly == fly &&
          other.focus == focus &&
          other.frIn == frIn &&
          other.frOut == frOut &&
          other.frx == frx &&
          other.fry == fry &&
          other.levelIn == levelIn &&
          other.levelOut == levelOut &&
          other.lfe == lfe &&
          other.lfeHigh == lfeHigh &&
          other.lfeIn == lfeIn &&
          other.lfeLow == lfeLow &&
          other.lfeMode == lfeMode &&
          other.lfeOut == lfeOut &&
          other.overlap == overlap &&
          other.slIn == slIn &&
          other.slOut == slOut &&
          other.slx == slx &&
          other.sly == sly &&
          other.smooth == smooth &&
          other.srIn == srIn &&
          other.srOut == srOut &&
          other.srx == srx &&
          other.sry == sry &&
          other.winFunc == winFunc &&
          other.winSize == winSize);

  @override
  int get hashCode => Object.hashAll([
    enabled,
    allx,
    ally,
    angle,
    bcIn,
    bcOut,
    bcx,
    bcy,
    blIn,
    blOut,
    blx,
    bly,
    brIn,
    brOut,
    brx,
    bry,
    chlIn,
    chlOut,
    fcIn,
    fcOut,
    fcx,
    fcy,
    flIn,
    flOut,
    flx,
    fly,
    focus,
    frIn,
    frOut,
    frx,
    fry,
    levelIn,
    levelOut,
    lfe,
    lfeHigh,
    lfeIn,
    lfeLow,
    lfeMode,
    lfeOut,
    overlap,
    slIn,
    slOut,
    slx,
    sly,
    smooth,
    srIn,
    srOut,
    srx,
    sry,
    winFunc,
    winSize,
  ]);

  @override
  String toString() =>
      'SurroundEffect(enabled: $enabled, allx: $allx, ally: $ally, angle: $angle, bcIn: $bcIn, bcOut: $bcOut, bcx: $bcx, bcy: $bcy, blIn: $blIn, blOut: $blOut, blx: $blx, bly: $bly, brIn: $brIn, brOut: $brOut, brx: $brx, bry: $bry, chlIn: $chlIn, chlOut: $chlOut, fcIn: $fcIn, fcOut: $fcOut, fcx: $fcx, fcy: $fcy, flIn: $flIn, flOut: $flOut, flx: $flx, fly: $fly, focus: $focus, frIn: $frIn, frOut: $frOut, frx: $frx, fry: $fry, levelIn: $levelIn, levelOut: $levelOut, lfe: $lfe, lfeHigh: $lfeHigh, lfeIn: $lfeIn, lfeLow: $lfeLow, lfeMode: $lfeMode, lfeOut: $lfeOut, overlap: $overlap, slIn: $slIn, slOut: $slOut, slx: $slx, sly: $sly, smooth: $smooth, srIn: $srIn, srOut: $srOut, srx: $srx, sry: $sry, winFunc: $winFunc, winSize: $winSize)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(allx >= allxMin, 'surround.allx must be >= -1');
    assert(allx <= allxMax, 'surround.allx must be <= 15');
    assert(ally >= allyMin, 'surround.ally must be >= -1');
    assert(ally <= allyMax, 'surround.ally must be <= 15');
    assert(angle >= angleMin, 'surround.angle must be >= 0');
    assert(angle <= angleMax, 'surround.angle must be <= 360');
    assert(bcIn >= bcInMin, 'surround.bc_in must be >= 0');
    assert(bcIn <= bcInMax, 'surround.bc_in must be <= 10');
    assert(bcOut >= bcOutMin, 'surround.bc_out must be >= 0');
    assert(bcOut <= bcOutMax, 'surround.bc_out must be <= 10');
    assert(bcx >= bcxMin, 'surround.bcx must be >= .06');
    assert(bcx <= bcxMax, 'surround.bcx must be <= 15');
    assert(bcy >= bcyMin, 'surround.bcy must be >= .06');
    assert(bcy <= bcyMax, 'surround.bcy must be <= 15');
    assert(blIn >= blInMin, 'surround.bl_in must be >= 0');
    assert(blIn <= blInMax, 'surround.bl_in must be <= 10');
    assert(blOut >= blOutMin, 'surround.bl_out must be >= 0');
    assert(blOut <= blOutMax, 'surround.bl_out must be <= 10');
    assert(blx >= blxMin, 'surround.blx must be >= .06');
    assert(blx <= blxMax, 'surround.blx must be <= 15');
    assert(bly >= blyMin, 'surround.bly must be >= .06');
    assert(bly <= blyMax, 'surround.bly must be <= 15');
    assert(brIn >= brInMin, 'surround.br_in must be >= 0');
    assert(brIn <= brInMax, 'surround.br_in must be <= 10');
    assert(brOut >= brOutMin, 'surround.br_out must be >= 0');
    assert(brOut <= brOutMax, 'surround.br_out must be <= 10');
    assert(brx >= brxMin, 'surround.brx must be >= .06');
    assert(brx <= brxMax, 'surround.brx must be <= 15');
    assert(bry >= bryMin, 'surround.bry must be >= .06');
    assert(bry <= bryMax, 'surround.bry must be <= 15');
    assert(fcIn >= fcInMin, 'surround.fc_in must be >= 0');
    assert(fcIn <= fcInMax, 'surround.fc_in must be <= 10');
    assert(fcOut >= fcOutMin, 'surround.fc_out must be >= 0');
    assert(fcOut <= fcOutMax, 'surround.fc_out must be <= 10');
    assert(fcx >= fcxMin, 'surround.fcx must be >= .06');
    assert(fcx <= fcxMax, 'surround.fcx must be <= 15');
    assert(fcy >= fcyMin, 'surround.fcy must be >= .06');
    assert(fcy <= fcyMax, 'surround.fcy must be <= 15');
    assert(flIn >= flInMin, 'surround.fl_in must be >= 0');
    assert(flIn <= flInMax, 'surround.fl_in must be <= 10');
    assert(flOut >= flOutMin, 'surround.fl_out must be >= 0');
    assert(flOut <= flOutMax, 'surround.fl_out must be <= 10');
    assert(flx >= flxMin, 'surround.flx must be >= .06');
    assert(flx <= flxMax, 'surround.flx must be <= 15');
    assert(fly >= flyMin, 'surround.fly must be >= .06');
    assert(fly <= flyMax, 'surround.fly must be <= 15');
    assert(focus >= focusMin, 'surround.focus must be >= -1');
    assert(focus <= focusMax, 'surround.focus must be <= 1');
    assert(frIn >= frInMin, 'surround.fr_in must be >= 0');
    assert(frIn <= frInMax, 'surround.fr_in must be <= 10');
    assert(frOut >= frOutMin, 'surround.fr_out must be >= 0');
    assert(frOut <= frOutMax, 'surround.fr_out must be <= 10');
    assert(frx >= frxMin, 'surround.frx must be >= .06');
    assert(frx <= frxMax, 'surround.frx must be <= 15');
    assert(fry >= fryMin, 'surround.fry must be >= .06');
    assert(fry <= fryMax, 'surround.fry must be <= 15');
    assert(levelIn >= levelInMin, 'surround.level_in must be >= 0');
    assert(levelIn <= levelInMax, 'surround.level_in must be <= 10');
    assert(levelOut >= levelOutMin, 'surround.level_out must be >= 0');
    assert(levelOut <= levelOutMax, 'surround.level_out must be <= 10');
    assert(lfeHigh >= lfeHighMin, 'surround.lfe_high must be >= 0');
    assert(lfeHigh <= lfeHighMax, 'surround.lfe_high must be <= 512');
    assert(lfeIn >= lfeInMin, 'surround.lfe_in must be >= 0');
    assert(lfeIn <= lfeInMax, 'surround.lfe_in must be <= 10');
    assert(lfeLow >= lfeLowMin, 'surround.lfe_low must be >= 0');
    assert(lfeLow <= lfeLowMax, 'surround.lfe_low must be <= 256');
    assert(lfeOut >= lfeOutMin, 'surround.lfe_out must be >= 0');
    assert(lfeOut <= lfeOutMax, 'surround.lfe_out must be <= 10');
    assert(overlap >= overlapMin, 'surround.overlap must be >= 0');
    assert(overlap <= overlapMax, 'surround.overlap must be <= 1');
    assert(slIn >= slInMin, 'surround.sl_in must be >= 0');
    assert(slIn <= slInMax, 'surround.sl_in must be <= 10');
    assert(slOut >= slOutMin, 'surround.sl_out must be >= 0');
    assert(slOut <= slOutMax, 'surround.sl_out must be <= 10');
    assert(slx >= slxMin, 'surround.slx must be >= .06');
    assert(slx <= slxMax, 'surround.slx must be <= 15');
    assert(sly >= slyMin, 'surround.sly must be >= .06');
    assert(sly <= slyMax, 'surround.sly must be <= 15');
    assert(smooth >= smoothMin, 'surround.smooth must be >= 0');
    assert(smooth <= smoothMax, 'surround.smooth must be <= 1');
    assert(srIn >= srInMin, 'surround.sr_in must be >= 0');
    assert(srIn <= srInMax, 'surround.sr_in must be <= 10');
    assert(srOut >= srOutMin, 'surround.sr_out must be >= 0');
    assert(srOut <= srOutMax, 'surround.sr_out must be <= 10');
    assert(srx >= srxMin, 'surround.srx must be >= .06');
    assert(srx <= srxMax, 'surround.srx must be <= 15');
    assert(sry >= sryMin, 'surround.sry must be >= .06');
    assert(sry <= sryMax, 'surround.sry must be <= 15');
    assert(winSize >= winSizeMin, 'surround.win_size must be >= 1024');
    assert(winSize <= winSizeMax, 'surround.win_size must be <= 65536');
    final parts = <String>[];
    if (allx != -1.0) parts.add('allx=' + _wireDouble(allx));
    if (ally != -1.0) parts.add('ally=' + _wireDouble(ally));
    if (angle != 90.0) parts.add('angle=' + _wireDouble(angle));
    if (bcIn != 1.0) parts.add('bc_in=' + _wireDouble(bcIn));
    if (bcOut != 1.0) parts.add('bc_out=' + _wireDouble(bcOut));
    if (bcx != 0.5) parts.add('bcx=' + _wireDouble(bcx));
    if (bcy != 0.5) parts.add('bcy=' + _wireDouble(bcy));
    if (blIn != 1.0) parts.add('bl_in=' + _wireDouble(blIn));
    if (blOut != 1.0) parts.add('bl_out=' + _wireDouble(blOut));
    if (blx != 0.5) parts.add('blx=' + _wireDouble(blx));
    if (bly != 0.5) parts.add('bly=' + _wireDouble(bly));
    if (brIn != 1.0) parts.add('br_in=' + _wireDouble(brIn));
    if (brOut != 1.0) parts.add('br_out=' + _wireDouble(brOut));
    if (brx != 0.5) parts.add('brx=' + _wireDouble(brx));
    if (bry != 0.5) parts.add('bry=' + _wireDouble(bry));
    if (chlIn != 'stereo') parts.add('chl_in=' + '[' + chlIn + ']');
    if (chlOut != '5.1') parts.add('chl_out=' + '[' + chlOut + ']');
    if (fcIn != 1.0) parts.add('fc_in=' + _wireDouble(fcIn));
    if (fcOut != 1.0) parts.add('fc_out=' + _wireDouble(fcOut));
    if (fcx != 0.5) parts.add('fcx=' + _wireDouble(fcx));
    if (fcy != 0.5) parts.add('fcy=' + _wireDouble(fcy));
    if (flIn != 1.0) parts.add('fl_in=' + _wireDouble(flIn));
    if (flOut != 1.0) parts.add('fl_out=' + _wireDouble(flOut));
    if (flx != 0.5) parts.add('flx=' + _wireDouble(flx));
    if (fly != 0.5) parts.add('fly=' + _wireDouble(fly));
    if (focus != 0.0) parts.add('focus=' + _wireDouble(focus));
    if (frIn != 1.0) parts.add('fr_in=' + _wireDouble(frIn));
    if (frOut != 1.0) parts.add('fr_out=' + _wireDouble(frOut));
    if (frx != 0.5) parts.add('frx=' + _wireDouble(frx));
    if (fry != 0.5) parts.add('fry=' + _wireDouble(fry));
    if (levelIn != 1.0) parts.add('level_in=' + _wireDouble(levelIn));
    if (levelOut != 1.0) parts.add('level_out=' + _wireDouble(levelOut));
    if (lfe != true) parts.add('lfe=' + (lfe ? '1' : '0'));
    if (lfeHigh != 256) parts.add('lfe_high=' + lfeHigh.toString());
    if (lfeIn != 1.0) parts.add('lfe_in=' + _wireDouble(lfeIn));
    if (lfeLow != 128) parts.add('lfe_low=' + lfeLow.toString());
    if (lfeMode != SurroundLfeMode.add)
      parts.add('lfe_mode=' + lfeMode.mpvValue);
    if (lfeOut != 1.0) parts.add('lfe_out=' + _wireDouble(lfeOut));
    if (overlap != 0.5) parts.add('overlap=' + _wireDouble(overlap));
    if (slIn != 1.0) parts.add('sl_in=' + _wireDouble(slIn));
    if (slOut != 1.0) parts.add('sl_out=' + _wireDouble(slOut));
    if (slx != 0.5) parts.add('slx=' + _wireDouble(slx));
    if (sly != 0.5) parts.add('sly=' + _wireDouble(sly));
    if (smooth != 0.0) parts.add('smooth=' + _wireDouble(smooth));
    if (srIn != 1.0) parts.add('sr_in=' + _wireDouble(srIn));
    if (srOut != 1.0) parts.add('sr_out=' + _wireDouble(srOut));
    if (srx != 0.5) parts.add('srx=' + _wireDouble(srx));
    if (sry != 0.5) parts.add('sry=' + _wireDouble(sry));
    if (winFunc != SurroundWinFunc.hann)
      parts.add('win_func=' + winFunc.mpvValue);
    if (winSize != 4096) parts.add('win_size=' + winSize.toString());
    return parts.isEmpty
        ? 'lavfi-surround'
        : 'lavfi-surround=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant SurroundEffect prev) {
    final out = <(String, String)>[];
    if (allx != prev.allx) {
      out.add(('allx', _wireDouble(allx)));
    }
    if (ally != prev.ally) {
      out.add(('ally', _wireDouble(ally)));
    }
    if (angle != prev.angle) {
      out.add(('angle', _wireDouble(angle)));
    }
    if (bcIn != prev.bcIn) {
      out.add(('bc_in', _wireDouble(bcIn)));
    }
    if (bcOut != prev.bcOut) {
      out.add(('bc_out', _wireDouble(bcOut)));
    }
    if (bcx != prev.bcx) {
      out.add(('bcx', _wireDouble(bcx)));
    }
    if (bcy != prev.bcy) {
      out.add(('bcy', _wireDouble(bcy)));
    }
    if (blIn != prev.blIn) {
      out.add(('bl_in', _wireDouble(blIn)));
    }
    if (blOut != prev.blOut) {
      out.add(('bl_out', _wireDouble(blOut)));
    }
    if (blx != prev.blx) {
      out.add(('blx', _wireDouble(blx)));
    }
    if (bly != prev.bly) {
      out.add(('bly', _wireDouble(bly)));
    }
    if (brIn != prev.brIn) {
      out.add(('br_in', _wireDouble(brIn)));
    }
    if (brOut != prev.brOut) {
      out.add(('br_out', _wireDouble(brOut)));
    }
    if (brx != prev.brx) {
      out.add(('brx', _wireDouble(brx)));
    }
    if (bry != prev.bry) {
      out.add(('bry', _wireDouble(bry)));
    }
    if (chlIn != prev.chlIn) return null;
    if (chlOut != prev.chlOut) return null;
    if (fcIn != prev.fcIn) {
      out.add(('fc_in', _wireDouble(fcIn)));
    }
    if (fcOut != prev.fcOut) {
      out.add(('fc_out', _wireDouble(fcOut)));
    }
    if (fcx != prev.fcx) {
      out.add(('fcx', _wireDouble(fcx)));
    }
    if (fcy != prev.fcy) {
      out.add(('fcy', _wireDouble(fcy)));
    }
    if (flIn != prev.flIn) {
      out.add(('fl_in', _wireDouble(flIn)));
    }
    if (flOut != prev.flOut) {
      out.add(('fl_out', _wireDouble(flOut)));
    }
    if (flx != prev.flx) {
      out.add(('flx', _wireDouble(flx)));
    }
    if (fly != prev.fly) {
      out.add(('fly', _wireDouble(fly)));
    }
    if (focus != prev.focus) {
      out.add(('focus', _wireDouble(focus)));
    }
    if (frIn != prev.frIn) {
      out.add(('fr_in', _wireDouble(frIn)));
    }
    if (frOut != prev.frOut) {
      out.add(('fr_out', _wireDouble(frOut)));
    }
    if (frx != prev.frx) {
      out.add(('frx', _wireDouble(frx)));
    }
    if (fry != prev.fry) {
      out.add(('fry', _wireDouble(fry)));
    }
    if (levelIn != prev.levelIn) {
      out.add(('level_in', _wireDouble(levelIn)));
    }
    if (levelOut != prev.levelOut) {
      out.add(('level_out', _wireDouble(levelOut)));
    }
    if (lfe != prev.lfe) {
      out.add(('lfe', (lfe ? '1' : '0')));
    }
    if (lfeHigh != prev.lfeHigh) return null;
    if (lfeIn != prev.lfeIn) {
      out.add(('lfe_in', _wireDouble(lfeIn)));
    }
    if (lfeLow != prev.lfeLow) return null;
    if (lfeMode != prev.lfeMode) {
      out.add(('lfe_mode', lfeMode.mpvValue));
    }
    if (lfeOut != prev.lfeOut) {
      out.add(('lfe_out', _wireDouble(lfeOut)));
    }
    if (overlap != prev.overlap) {
      out.add(('overlap', _wireDouble(overlap)));
    }
    if (slIn != prev.slIn) {
      out.add(('sl_in', _wireDouble(slIn)));
    }
    if (slOut != prev.slOut) {
      out.add(('sl_out', _wireDouble(slOut)));
    }
    if (slx != prev.slx) {
      out.add(('slx', _wireDouble(slx)));
    }
    if (sly != prev.sly) {
      out.add(('sly', _wireDouble(sly)));
    }
    if (smooth != prev.smooth) {
      out.add(('smooth', _wireDouble(smooth)));
    }
    if (srIn != prev.srIn) {
      out.add(('sr_in', _wireDouble(srIn)));
    }
    if (srOut != prev.srOut) {
      out.add(('sr_out', _wireDouble(srOut)));
    }
    if (srx != prev.srx) {
      out.add(('srx', _wireDouble(srx)));
    }
    if (sry != prev.sry) {
      out.add(('sry', _wireDouble(sry)));
    }
    if (winFunc != prev.winFunc) return null;
    if (winSize != prev.winSize) return null;
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [gain]: Give the gain at 0 Hz. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class TiltshelfEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final TiltshelfPrecision precision;

  /// set transform type
  final TiltshelfTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final TiltshelfWidthType widthType;

  /// Creates an [TiltshelfEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const TiltshelfEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = TiltshelfPrecision.auto,
    this.transform = TiltshelfTransformType.di,
    this.width = 0.5,
    this.widthType = TiltshelfWidthType.q,
  });

  @override
  String get filterName => 'tiltshelf';

  @override
  AudioFilter get filter => AudioFilter.tiltshelf;

  /// Returns a copy of this [TiltshelfEffect] with the given fields replaced.
  TiltshelfEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    int? poles,
    TiltshelfPrecision? precision,
    TiltshelfTransformType? transform,
    double? width,
    TiltshelfWidthType? widthType,
  }) => TiltshelfEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TiltshelfEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'TiltshelfEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'tiltshelf.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'tiltshelf.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'tiltshelf.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'tiltshelf.frequency must be <= 999999');
    assert(gain >= gainMin, 'tiltshelf.gain must be >= -900');
    assert(gain <= gainMax, 'tiltshelf.gain must be <= 900');
    assert(mix >= mixMin, 'tiltshelf.mix must be >= 0');
    assert(mix <= mixMax, 'tiltshelf.mix must be <= 1');
    assert(poles >= polesMin, 'tiltshelf.poles must be >= 1');
    assert(poles <= polesMax, 'tiltshelf.poles must be <= 2');
    assert(width >= widthMin, 'tiltshelf.width must be >= 0');
    assert(width <= widthMax, 'tiltshelf.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != TiltshelfPrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != TiltshelfTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != TiltshelfWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty
        ? 'lavfi-tiltshelf'
        : 'lavfi-tiltshelf=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant TiltshelfEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
/// - [blocksize]: set the block size (range 0..32768, default 0)
/// - [channels]: Specify which channels to filter, by default all available are filtered. (range 0..0, default "all", runtime-tunable)
/// - [frequency]: Set the filter's central frequency and so can be used to extend or reduce the frequency range to be boosted or cut. The default value is `3000` Hz. (range 0..999999, default 3000, runtime-tunable)
/// - [gain]: Give the gain at whichever is the lower of ~22 kHz and the Nyquist frequency. Its useful range is about -20 (for a large cut) to +20 (for a large boost). Beware of clipping when using a positive gain. (range -900..900, default 0, runtime-tunable)
/// - [mix]: How much to use filtered signal in output. Default is 1. Range is between 0 and 1. (range 0..1, default 1, runtime-tunable)
/// - [normalize]: Normalize biquad coefficients, by default is disabled. Enabling it will normalize magnitude response at DC to 0dB. (range 0..1, default 0, runtime-tunable)
/// - [poles]: Set number of poles. Default is 2. (range 1..2, default 2)
/// - [precision]: Set precision of filtering. (range -1..3, default -1)
/// - [transform]: Set transform type of IIR filter. (range 0..6, default DI)
/// - [width]: Determine how steep is the filter's shelf transition. (range 0..99999, default 0.5, runtime-tunable)
/// - [widthType]: Set method to specify band-width of filter. (range 1..5, default QFACTOR, runtime-tunable)
final class TrebleEffect extends AudioEffect {
  /// Default value for [blocksize].
  static const int blocksizeDefault = 0;

  /// Minimum value for [blocksize].
  static const int blocksizeMin = 0;

  /// Maximum value for [blocksize].
  static const int blocksizeMax = 32768;

  /// Default value for [frequency].
  static const double frequencyDefault = 3000.0;

  /// Minimum value for [frequency].
  static const double frequencyMin = 0.0;

  /// Maximum value for [frequency].
  static const double frequencyMax = 999999.0;

  /// Default value for [gain].
  static const double gainDefault = 0.0;

  /// Minimum value for [gain].
  static const double gainMin = -900.0;

  /// Maximum value for [gain].
  static const double gainMax = 900.0;

  /// Default value for [mix].
  static const double mixDefault = 1.0;

  /// Minimum value for [mix].
  static const double mixMin = 0.0;

  /// Maximum value for [mix].
  static const double mixMax = 1.0;

  /// Default value for [poles].
  static const int polesDefault = 2;

  /// Minimum value for [poles].
  static const int polesMin = 1;

  /// Maximum value for [poles].
  static const int polesMax = 2;

  /// Default value for [width].
  static const double widthDefault = 0.5;

  /// Minimum value for [width].
  static const double widthMin = 0.0;

  /// Maximum value for [width].
  static const double widthMax = 99999.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set the block size
  final int blocksize;

  /// set channels to filter
  final String channels;

  /// set central frequency
  final double frequency;

  /// set gain
  final double gain;

  /// set mix
  final double mix;

  /// normalize coefficients
  final bool normalize;

  /// set number of poles
  final int poles;

  /// set filtering precision
  final TreblePrecision precision;

  /// set transform type
  final TrebleTransformType transform;

  /// set width
  final double width;

  /// set filter-width type
  final TrebleWidthType widthType;

  /// Creates an [TrebleEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const TrebleEffect({
    this.enabled = true,
    this.blocksize = 0,
    this.channels = 'all',
    this.frequency = 3000.0,
    this.gain = 0.0,
    this.mix = 1.0,
    this.normalize = false,
    this.poles = 2,
    this.precision = TreblePrecision.auto,
    this.transform = TrebleTransformType.di,
    this.width = 0.5,
    this.widthType = TrebleWidthType.q,
  });

  @override
  String get filterName => 'treble';

  @override
  AudioFilter get filter => AudioFilter.treble;

  /// Returns a copy of this [TrebleEffect] with the given fields replaced.
  TrebleEffect copyWith({
    bool? enabled,
    int? blocksize,
    String? channels,
    double? frequency,
    double? gain,
    double? mix,
    bool? normalize,
    int? poles,
    TreblePrecision? precision,
    TrebleTransformType? transform,
    double? width,
    TrebleWidthType? widthType,
  }) => TrebleEffect(
    enabled: enabled ?? this.enabled,
    blocksize: blocksize ?? this.blocksize,
    channels: channels ?? this.channels,
    frequency: frequency ?? this.frequency,
    gain: gain ?? this.gain,
    mix: mix ?? this.mix,
    normalize: normalize ?? this.normalize,
    poles: poles ?? this.poles,
    precision: precision ?? this.precision,
    transform: transform ?? this.transform,
    width: width ?? this.width,
    widthType: widthType ?? this.widthType,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TrebleEffect &&
          other.enabled == enabled &&
          other.blocksize == blocksize &&
          other.channels == channels &&
          other.frequency == frequency &&
          other.gain == gain &&
          other.mix == mix &&
          other.normalize == normalize &&
          other.poles == poles &&
          other.precision == precision &&
          other.transform == transform &&
          other.width == width &&
          other.widthType == widthType);

  @override
  int get hashCode => Object.hash(
    enabled,
    blocksize,
    channels,
    frequency,
    gain,
    mix,
    normalize,
    poles,
    precision,
    transform,
    width,
    widthType,
  );

  @override
  String toString() =>
      'TrebleEffect(enabled: $enabled, blocksize: $blocksize, channels: $channels, frequency: $frequency, gain: $gain, mix: $mix, normalize: $normalize, poles: $poles, precision: $precision, transform: $transform, width: $width, widthType: $widthType)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(blocksize >= blocksizeMin, 'treble.blocksize must be >= 0');
    assert(blocksize <= blocksizeMax, 'treble.blocksize must be <= 32768');
    assert(frequency >= frequencyMin, 'treble.frequency must be >= 0');
    assert(frequency <= frequencyMax, 'treble.frequency must be <= 999999');
    assert(gain >= gainMin, 'treble.gain must be >= -900');
    assert(gain <= gainMax, 'treble.gain must be <= 900');
    assert(mix >= mixMin, 'treble.mix must be >= 0');
    assert(mix <= mixMax, 'treble.mix must be <= 1');
    assert(poles >= polesMin, 'treble.poles must be >= 1');
    assert(poles <= polesMax, 'treble.poles must be <= 2');
    assert(width >= widthMin, 'treble.width must be >= 0');
    assert(width <= widthMax, 'treble.width must be <= 99999');
    final parts = <String>[];
    if (blocksize != 0) parts.add('blocksize=' + blocksize.toString());
    if (channels != 'all') parts.add('channels=' + '[' + channels + ']');
    if (frequency != 3000.0) parts.add('frequency=' + _wireDouble(frequency));
    if (gain != 0.0) parts.add('gain=' + _wireDouble(gain));
    if (mix != 1.0) parts.add('mix=' + _wireDouble(mix));
    if (normalize != false) parts.add('normalize=' + (normalize ? '1' : '0'));
    if (poles != 2) parts.add('poles=' + poles.toString());
    if (precision != TreblePrecision.auto)
      parts.add('precision=' + precision.mpvValue);
    if (transform != TrebleTransformType.di)
      parts.add('transform=' + transform.mpvValue);
    if (width != 0.5) parts.add('width=' + _wireDouble(width));
    if (widthType != TrebleWidthType.q)
      parts.add('width_type=' + widthType.mpvValue);
    return parts.isEmpty ? 'lavfi-treble' : 'lavfi-treble=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant TrebleEffect prev) {
    final out = <(String, String)>[];
    if (blocksize != prev.blocksize) return null;
    if (channels != prev.channels) {
      out.add(('channels', channels));
    }
    if (frequency != prev.frequency) {
      out.add(('frequency', _wireDouble(frequency)));
    }
    if (gain != prev.gain) {
      out.add(('gain', _wireDouble(gain)));
    }
    if (mix != prev.mix) {
      out.add(('mix', _wireDouble(mix)));
    }
    if (normalize != prev.normalize) {
      out.add(('normalize', (normalize ? '1' : '0')));
    }
    if (poles != prev.poles) return null;
    if (precision != prev.precision) return null;
    if (transform != prev.transform) return null;
    if (width != prev.width) {
      out.add(('width', _wireDouble(width)));
    }
    if (widthType != prev.widthType) {
      out.add(('width_type', widthType.mpvValue));
    }
    return out;
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
final class TremoloEffect extends AudioEffect {
  /// Default value for [d].
  static const double dDefault = 0.5;

  /// Minimum value for [d].
  static const double dMin = 0.0;

  /// Maximum value for [d].
  static const double dMax = 1.0;

  /// Default value for [f].
  static const double fDefault = 5.0;

  /// Minimum value for [f].
  static const double fMin = 0.1;

  /// Maximum value for [f].
  static const double fMax = 20000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set depth as percentage
  final double d;

  /// set frequency in hertz
  final double f;

  /// Creates an [TremoloEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const TremoloEffect({this.enabled = true, this.d = 0.5, this.f = 5.0});

  @override
  String get filterName => 'tremolo';

  @override
  AudioFilter get filter => AudioFilter.tremolo;

  /// Returns a copy of this [TremoloEffect] with the given fields replaced.
  TremoloEffect copyWith({bool? enabled, double? d, double? f}) =>
      TremoloEffect(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TremoloEffect &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'TremoloEffect(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(d >= dMin, 'tremolo.d must be >= 0.0');
    assert(d <= dMax, 'tremolo.d must be <= 1.0');
    assert(f >= fMin, 'tremolo.f must be >= 0.1');
    assert(f <= fMax, 'tremolo.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + _wireDouble(d));
    if (f != 5.0) parts.add('f=' + _wireDouble(f));
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
final class VibratoEffect extends AudioEffect {
  /// Default value for [d].
  static const double dDefault = 0.5;

  /// Minimum value for [d].
  static const double dMin = 0.00;

  /// Maximum value for [d].
  static const double dMax = 1.0;

  /// Default value for [f].
  static const double fDefault = 5.0;

  /// Minimum value for [f].
  static const double fMin = 0.1;

  /// Maximum value for [f].
  static const double fMax = 20000.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set depth as percentage
  final double d;

  /// set frequency in hertz
  final double f;

  /// Creates an [VibratoEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const VibratoEffect({this.enabled = true, this.d = 0.5, this.f = 5.0});

  @override
  String get filterName => 'vibrato';

  @override
  AudioFilter get filter => AudioFilter.vibrato;

  /// Returns a copy of this [VibratoEffect] with the given fields replaced.
  VibratoEffect copyWith({bool? enabled, double? d, double? f}) =>
      VibratoEffect(
        enabled: enabled ?? this.enabled,
        d: d ?? this.d,
        f: f ?? this.f,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VibratoEffect &&
          other.enabled == enabled &&
          other.d == d &&
          other.f == f);

  @override
  int get hashCode => Object.hash(enabled, d, f);

  @override
  String toString() => 'VibratoEffect(enabled: $enabled, d: $d, f: $f)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(d >= dMin, 'vibrato.d must be >= 0.00');
    assert(d <= dMax, 'vibrato.d must be <= 1.0');
    assert(f >= fMin, 'vibrato.f must be >= 0.1');
    assert(f <= fMax, 'vibrato.f must be <= 20000.0');
    final parts = <String>[];
    if (d != 0.5) parts.add('d=' + _wireDouble(d));
    if (f != 5.0) parts.add('f=' + _wireDouble(f));
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
/// - [strength]: Set the virtual bass strength. Allowed range is from 0.5 to 3. Default value is 3. (range 0.5..3, default 3, runtime-tunable)
final class VirtualbassEffect extends AudioEffect {
  /// Default value for [cutoff].
  static const double cutoffDefault = 250.0;

  /// Minimum value for [cutoff].
  static const double cutoffMin = 100.0;

  /// Maximum value for [cutoff].
  static const double cutoffMax = 500.0;

  /// Default value for [strength].
  static const double strengthDefault = 3.0;

  /// Minimum value for [strength].
  static const double strengthMin = 0.5;

  /// Maximum value for [strength].
  static const double strengthMax = 3.0;

  /// Whether this effect is applied. `false` keeps it in the
  /// list, with its settings, without inserting it in the chain.
  @override
  final bool enabled;

  /// set virtual bass cutoff
  final double cutoff;

  /// set virtual bass strength
  final double strength;

  /// Creates an [VirtualbassEffect] with the given parameter values.
  ///
  /// Each parameter defaults to its ffmpeg default.
  const VirtualbassEffect({
    this.enabled = true,
    this.cutoff = 250.0,
    this.strength = 3.0,
  });

  @override
  String get filterName => 'virtualbass';

  @override
  AudioFilter get filter => AudioFilter.virtualbass;

  /// Returns a copy of this [VirtualbassEffect] with the given fields replaced.
  VirtualbassEffect copyWith({
    bool? enabled,
    double? cutoff,
    double? strength,
  }) => VirtualbassEffect(
    enabled: enabled ?? this.enabled,
    cutoff: cutoff ?? this.cutoff,
    strength: strength ?? this.strength,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VirtualbassEffect &&
          other.enabled == enabled &&
          other.cutoff == cutoff &&
          other.strength == strength);

  @override
  int get hashCode => Object.hash(enabled, cutoff, strength);

  @override
  String toString() =>
      'VirtualbassEffect(enabled: $enabled, cutoff: $cutoff, strength: $strength)';

  /// Returns the audio chain entry for this effect.
  /// Only non-default parameters are emitted.
  @override
  String toFilterString() {
    assert(cutoff >= cutoffMin, 'virtualbass.cutoff must be >= 100');
    assert(cutoff <= cutoffMax, 'virtualbass.cutoff must be <= 500');
    assert(strength >= strengthMin, 'virtualbass.strength must be >= 0.5');
    assert(strength <= strengthMax, 'virtualbass.strength must be <= 3');
    final parts = <String>[];
    if (cutoff != 250.0) parts.add('cutoff=' + _wireDouble(cutoff));
    if (strength != 3.0) parts.add('strength=' + _wireDouble(strength));
    return parts.isEmpty
        ? 'lavfi-virtualbass'
        : 'lavfi-virtualbass=' + parts.join(':');
  }

  /// Runtime-tunable option diff against [prev]: the `(option,
  /// wire value)` pairs the live graph can apply via `af-command`,
  /// or `null` when a changed option requires a chain rebuild.
  @override
  List<(String, String)>? _runtimeDiff(covariant VirtualbassEffect prev) {
    final out = <(String, String)>[];
    if (cutoff != prev.cutoff) return null;
    if (strength != prev.strength) {
      out.add(('strength', _wireDouble(strength)));
    }
    return out;
  }
}
