// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../dsp/compressor_config.dart';
import '../dsp/equalizer_config.dart';
import '../dsp/loudness_config.dart';
import '../dsp/pitch_tempo_config.dart';

// Chain order is fixed:
//   custom... → compressor → equalizer → pitch/tempo → loudnorm
//
// Compression on the raw signal before tonal shaping (EQ); pitch/tempo
// after so timing changes see a stable spectrum; loudness normalization
// last so it adapts to whatever the earlier stages produced.

/// Reserved labels for the wrapper-managed filter stages. Filters carrying
/// these labels are owned by the typed setters ([Player.setEqualizer] et
/// al.) and must not be passed to [Player.setCustomAudioFilters].
class AudioFilterChainLabels {
  static const equalizer = '_mak_eq';
  static const compressor = '_mak_comp';
  static const loudness = '_mak_loud';
  static const pitchTempo = '_mak_pt';

  static const all = <String>{equalizer, compressor, loudness, pitchTempo};
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

/// Builds the full mpv `af` value, joining custom filters with the four
/// typed DSP stages in fixed order. Returns the empty string when nothing
/// is enabled — mpv interprets that as "no filters". Each typed stage is
/// emitted as `@label:filter=args` so [extractCustomFilters] can later
/// strip them on the inverse path.
String composeAfChain({
  required List<String> customFilters,
  required CompressorConfig compressor,
  required EqualizerConfig equalizer,
  required PitchTempoConfig pitchTempo,
  required LoudnessConfig loudness,
}) {
  final parts = <String>[];

  for (final raw in customFilters) {
    final trimmed = raw.trim();
    if (trimmed.isNotEmpty) parts.add(trimmed);
  }

  if (compressor.enabled) parts.add(_buildCompressor(compressor));
  if (equalizer.enabled) parts.add(_buildEqualizer(equalizer));
  if (pitchTempo.enabled) parts.add(_buildPitchTempo(pitchTempo));
  if (loudness.enabled) parts.add(_buildLoudness(loudness));

  return parts.join(',');
}

// Fixed-precision formatting for double-valued filter parameters. Stops
// floating-point noise (e.g. 1.0 vs 1.0000000001 from a copyWith chain)
// from changing the `af` string and triggering spurious filter-chain
// reloads in mpv.
String _f(double v) => v.toStringAsFixed(3);

String _buildCompressor(CompressorConfig c) {
  return '@${AudioFilterChainLabels.compressor}:lavfi-acompressor='
      'threshold=${_f(c.threshold)}dB'
      ':ratio=${_f(c.ratio)}'
      ':attack=${_f(c.attack.inMicroseconds / 1000)}'
      ':release=${_f(c.release.inMicroseconds / 1000)}';
}

String _buildEqualizer(EqualizerConfig eq) {
  if (eq.gains.length != _kEqualizerCenters.length) {
    throw ArgumentError.value(
      eq.gains.length,
      'gains',
      'EqualizerConfig requires exactly ${_kEqualizerCenters.length} bands',
    );
  }
  final bands = <String>[];
  for (var i = 0; i < _kEqualizerCenters.length; i++) {
    final g = eq.gains[i].toStringAsFixed(2);
    bands.add('lavfi-equalizer=f=${_kEqualizerCenters[i]}:t=o:w=1:g=$g');
  }
  // Multiple `equalizer` filter instances must each carry the wrapper
  // label so removal via `af del @_mak_eq` strips the whole bank.
  final labelled = bands
      .map((b) => '@${AudioFilterChainLabels.equalizer}:$b')
      .join(',');
  return labelled;
}

String _buildPitchTempo(PitchTempoConfig p) {
  return '@${AudioFilterChainLabels.pitchTempo}:rubberband='
      'pitch=${_f(p.pitch)}'
      ':tempo=${_f(p.tempo)}';
}

String _buildLoudness(LoudnessConfig l) {
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
/// [PlayerState.customAudioFilters]. Wrapper-managed stages stay owned by
/// their typed setters and are never reverse-parsed from the af string.
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
