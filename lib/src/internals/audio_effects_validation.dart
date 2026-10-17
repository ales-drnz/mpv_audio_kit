// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The check the effects chain passes before it reaches mpv.
///
/// A few lavfi filters accept values their own checks miss, then read or
/// write out of their buffers with them. Only those values are refused
/// here: anything else a filter rejects is left to the filter, which
/// fails the chain when mpv builds it. The values are read the way the
/// filter reads them, so a string the filter takes as intended is never
/// refused.
library;

import 'package:meta/meta.dart';

import '../generated/audio_effects_settings.dart';

/// Throws [ArgumentError] when an enabled stage of [effects] holds a value
/// its lavfi filter accepts and then reads or writes out of its buffers
/// with. The error names the stage by its index, e.g.
/// `effects[1].decays`.
@internal
void validateAudioEffects(List<AudioEffect> effects) {
  for (var i = 0; i < effects.length; i++) {
    final e = effects[i];
    if (!e.enabled) continue;
    switch (e) {
      case ChorusEffect():
        _checkChorus(e, 'effects[$i]');
      default:
    }
  }
}

/// chorus counts each list with av_strtok and sscanf, then checks the
/// counts with `&&` where it means `||`: lists of different lengths pass
/// and the filter reads past the shorter ones. Every list needs as many
/// values as delays, which sets the number of voices.
void _checkChorus(ChorusEffect e, String stage) {
  final voices = _scanList(e.delays, '|').length;
  for (final (name, list) in [
    ('decays', e.decays),
    ('speeds', e.speeds),
    ('depths', e.depths),
  ]) {
    final n = _scanList(list, '|').length;
    if (n != voices) {
      throw ArgumentError.value(
        list,
        '$stage.$name',
        'chorus needs one value per voice in delays, decays, speeds and '
            'depths: $voices delays, $n $name',
      );
    }
  }
}

/// The values lavfi reads from [list]: the items av_strtok splits on any
/// of [delimiters], skipping empty ones, that sscanf reads a number from.
List<double> _scanList(String list, String delimiters) => [
  for (final item in _strtok(list, delimiters)) ?_scanDouble(item),
];

/// The items av_strtok returns for [s]: runs of characters that are not
/// in [delimiters]. Empty items are skipped.
List<String> _strtok(String s, String delimiters) {
  final out = <String>[];
  var start = -1;
  for (var i = 0; i <= s.length; i++) {
    final end = i == s.length || delimiters.contains(s[i]);
    if (end) {
      if (start >= 0) out.add(s.substring(start, i));
      start = -1;
    } else if (start < 0) {
      start = i;
    }
  }
  return out;
}

/// The number sscanf's `%lf` reads at the start of [item], or `null` when
/// it reads none: leading white space, then a decimal number, `inf`,
/// `infinity` or `nan` in any case. What follows the number is ignored.
double? _scanDouble(String item) {
  final m = _cNumber.firstMatch(item);
  if (m == null) return null;
  final sign = m.group(1)!;
  final digits = m.group(3);
  if (digits != null) return double.parse('$sign$digits');
  if (m.group(2)!.toLowerCase().startsWith('nan')) return double.nan;
  return sign == '-' ? double.negativeInfinity : double.infinity;
}

final RegExp _cNumber = RegExp(
  r'^[ \t\n\v\f\r]*([+-]?)'
  r'(?:(inf(?:inity)?|nan(?:\([0-9a-z_]*\))?)|'
  r'((?:\d+\.?\d*|\.\d+)(?:e[+-]?\d+)?))',
  caseSensitive: false,
);
