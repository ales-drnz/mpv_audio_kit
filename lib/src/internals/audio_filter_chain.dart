// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/settings/audio_effects.dart';
import '../types/settings/bass_treble_settings.dart';
import '../types/settings/compressor_settings.dart';
import '../types/settings/crossfeed_settings.dart';
import '../types/settings/equalizer_settings.dart';
import '../types/settings/loudness_settings.dart';
import '../types/settings/pitch_tempo_settings.dart';
import '../types/settings/silence_trim_settings.dart';
import '../types/settings/stereo_settings.dart';

// Chain order (see AudioEffects dartdoc for rationale):
//   custom… → compressor → equalizer → bassTreble → stereo →
//   crossfeed → silenceTrim → pitchTempo → crossfade → loudnorm

/// Reserved labels for wrapper-managed filter stages. Filters carrying
/// these labels are owned by the typed [AudioEffects] bundle and must
/// not appear in [AudioEffects.custom].
class AudioFilterChainLabels {
  static const compressor = '_mak_comp';
  static const equalizer = '_mak_eq';
  static const bassTreble = '_mak_bt';
  static const stereo = '_mak_st';
  static const crossfeed = '_mak_cf';
  static const silenceTrim = '_mak_str';
  static const pitchTempo = '_mak_pt';
  static const crossfade = '_mak_xf';
  static const loudness = '_mak_loud';

  static const all = <String>{
    compressor,
    equalizer,
    bassTreble,
    stereo,
    crossfeed,
    silenceTrim,
    pitchTempo,
    crossfade,
    loudness,
  };
}

const _kEqualizerCenters = <double>[
  31.25,
  62.5,
  125.0,
  250.0,
  500.0,
  1000.0,
  2000.0,
  4000.0,
  8000.0,
  16000.0,
];

/// Builds the full mpv `af` value from an [AudioEffects] bundle.
/// Returns the empty string when nothing is enabled — mpv interprets
/// that as "no filters". Each typed stage is emitted as
/// `@label:filter=args` so [extractCustomFilters] can later strip
/// wrapper-managed entries on the inverse path.
String composeAfChain(AudioEffects effects) {
  final parts = <String>[];

  for (final raw in effects.custom) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) parts.add(trimmed);
  }

  if (effects.compressor.enabled) parts.add(_buildCompressor(effects.compressor));
  if (effects.equalizer.enabled) parts.add(_buildEqualizer(effects.equalizer));
  if (effects.bassTreble.enabled) parts.add(_buildBassTreble(effects.bassTreble));
  if (effects.stereo.enabled) parts.add(_buildStereo(effects.stereo));
  if (effects.crossfeed.enabled) parts.add(_buildCrossfeed(effects.crossfeed));
  final silence = _buildSilenceTrim(effects.silenceTrim);
  if (silence != null) parts.add(silence);
  if (effects.pitchTempo.enabled) parts.add(_buildPitchTempo(effects.pitchTempo));
  final xfade = _buildCrossfade(effects.crossfade);
  if (xfade != null) parts.add(xfade);
  if (effects.loudness.enabled) parts.add(_buildLoudness(effects.loudness));

  return parts.join(',');
}

// Fixed-precision formatting for double-valued filter parameters. Stops
// floating-point noise (e.g. 1.0 vs 1.0000000001 from a copyWith chain)
// from changing the `af` string and triggering spurious filter-chain
// reloads in mpv.
String _f(double v) => v.toStringAsFixed(3);

String _buildCompressor(CompressorSettings c) {
  return '@${AudioFilterChainLabels.compressor}:lavfi-acompressor='
      'threshold=${_f(c.threshold)}dB'
      ':ratio=${_f(c.ratio)}'
      ':attack=${_f(c.attack.inMicroseconds / 1000)}'
      ':release=${_f(c.release.inMicroseconds / 1000)}';
}

String _buildEqualizer(EqualizerSettings eq) {
  if (eq.gains.length != _kEqualizerCenters.length) {
    throw ArgumentError.value(
      eq.gains.length,
      'gains',
      'EqualizerSettings requires exactly ${_kEqualizerCenters.length} bands',
    );
  }
  final bands = <String>[];
  for (var i = 0; i < _kEqualizerCenters.length; i++) {
    final g = eq.gains[i].toStringAsFixed(2);
    bands.add('lavfi-equalizer=f=${_kEqualizerCenters[i]}:t=o:w=1:g=$g');
  }
  // Multiple `equalizer` filter instances must each carry the wrapper
  // label so removal via `af del @_mak_eq` strips the whole bank.
  return bands
      .map((b) => '@${AudioFilterChainLabels.equalizer}:$b')
      .join(',');
}

String _buildBassTreble(BassTrebleSettings b) {
  // bass + treble run as two libavfilter shelving stages, both labelled
  // so the af-del invariant strips the pair atomically.
  final bass = '@${AudioFilterChainLabels.bassTreble}:lavfi-bass='
      'g=${_f(b.bassDb)}:f=${_f(b.bassFrequency)}';
  final treble = '@${AudioFilterChainLabels.bassTreble}:lavfi-treble='
      'g=${_f(b.trebleDb)}:f=${_f(b.trebleFrequency)}';
  return '$bass,$treble';
}

String _buildStereo(StereoSettings s) {
  // `slev` (side level) controls stereo width — increasing widens the
  // L–R difference signal. `mlev` (middle level) is pinned to 1.0 so
  // the centre image stays untouched. `balance_in` shifts L/R balance
  // pre-processing.
  return '@${AudioFilterChainLabels.stereo}:lavfi-stereotools='
      'slev=${_f(s.width)}:mlev=1.0:balance_in=${_f(s.balance)}';
}

String _buildCrossfeed(CrossfeedSettings c) {
  return '@${AudioFilterChainLabels.crossfeed}:lavfi-bs2b='
      'profile=${c.intensity.mpvValue}';
}

String? _buildSilenceTrim(SilenceTrimSettings t) {
  if (!t.trimStart && !t.trimEnd) return null;
  final parts = <String>[];
  if (t.trimStart) {
    parts.add('start_periods=1');
    parts.add('start_duration=${_f(t.minDuration.inMicroseconds / 1e6)}');
    parts.add('start_threshold=${_f(t.thresholdDb)}dB');
  }
  if (t.trimEnd) {
    parts.add('stop_periods=1');
    parts.add('stop_duration=${_f(t.minDuration.inMicroseconds / 1e6)}');
    parts.add('stop_threshold=${_f(t.thresholdDb)}dB');
  }
  return '@${AudioFilterChainLabels.silenceTrim}:lavfi-silenceremove='
      '${parts.join(":")}';
}

String _buildPitchTempo(PitchTempoSettings p) {
  return '@${AudioFilterChainLabels.pitchTempo}:rubberband='
      'pitch=${_f(p.pitch)}'
      ':tempo=${_f(p.tempo)}';
}

String? _buildCrossfade(Duration? d) {
  if (d == null || d == Duration.zero) return null;
  return '@${AudioFilterChainLabels.crossfade}:lavfi-acrossfade='
      'd=${_f(d.inMicroseconds / 1e6)}';
}

String _buildLoudness(LoudnessSettings l) {
  return '@${AudioFilterChainLabels.loudness}:lavfi-loudnorm='
      'I=${_f(l.integratedLoudness)}'
      ':TP=${_f(l.truePeak)}'
      ':LRA=${_f(l.lra)}';
}

/// Returns the unmanaged segment of an mpv `af` value — every entry whose
/// label is NOT one of the wrapper-reserved [AudioFilterChainLabels].
///
/// Used by the `af` observer so external mutations to the chain (raw
/// `setRawProperty('af', ...)` writes) propagate into
/// [AudioEffects.custom]. Wrapper-managed stages stay owned by the
/// bundle setter and are never reverse-parsed from the af string.
List<String> extractCustomFilters(String afValue) {
  if (afValue.trim().isEmpty) return const [];
  final entries = _splitAfTopLevel(afValue);
  final out = <String>[];
  for (final e in entries) {
    if (_managedLabelOf(e) != null) continue;
    final trimmed = e.trim();
    if (trimmed.isNotEmpty) out.add(trimmed);
  }
  return out;
}

/// Splits an `af` chain on top-level commas — commas inside parentheses
/// belong to a graph-style sub-expression and stay attached.
List<String> _splitAfTopLevel(String chain) {
  final out = <String>[];
  final buf = StringBuffer();
  int depth = 0;
  for (final code in chain.codeUnits) {
    if (code == 0x28) {
      depth++;
      buf.writeCharCode(code);
    } else if (code == 0x29) {
      if (depth > 0) depth--;
      buf.writeCharCode(code);
    } else if (code == 0x2C && depth == 0) {
      out.add(buf.toString());
      buf.clear();
    } else {
      buf.writeCharCode(code);
    }
  }
  if (buf.isNotEmpty) out.add(buf.toString());
  return out;
}

/// Returns the wrapper label of a filter entry if present and reserved,
/// or `null` for unlabelled / user-labelled / unknown-labelled entries.
String? _managedLabelOf(String entry) {
  final trimmed = entry.trimLeft();
  if (!trimmed.startsWith('@')) return null;
  final colon = trimmed.indexOf(':');
  if (colon <= 1) return null;
  final label = trimmed.substring(1, colon);
  return AudioFilterChainLabels.all.contains(label) ? label : null;
}
