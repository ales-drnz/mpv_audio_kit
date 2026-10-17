// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// The check the effects chain passes before it reaches mpv.
///
/// A few lavfi filters accept values their own checks miss, then read or
/// write out of their buffers with them, or turn the audio to NaN. Those
/// values are refused here, with the rest of the range the filter checks
/// where it has one. Anything else a filter rejects is left to the
/// filter, which fails the chain when mpv builds it. Lists are read the
/// way the filter reads them, so a string the filter takes as intended is
/// never refused.
library;

import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../generated/audio_effects_settings.dart';

/// Throws [ArgumentError] when an enabled stage of [effects] holds a value
/// its lavfi filter accepts and then reads or writes out of its buffers
/// with, or turns the audio to NaN with. The error names the stage by its
/// index, e.g. `effects[1].decays`.
@internal
void validateAudioEffects(List<AudioEffect> effects) {
  for (var i = 0; i < effects.length; i++) {
    final e = effects[i];
    if (!e.enabled) continue;
    switch (e) {
      case AechoEffect():
        _checkAecho(e, 'effects[$i]');
      case AnequalizerEffect():
        _checkAnequalizer(e, 'effects[$i]');
      case ChorusEffect():
        _checkChorus(e, 'effects[$i]');
      default:
    }
  }
}

/// aecho checks each delay and decay with comparisons that NaN passes,
/// then indexes its delay line with the delay converted to an int.
void _checkAecho(AechoEffect e, String stage) {
  _checkRange(
    e.delays,
    '$stage.delays',
    _scanFloats(e.delays),
    (v) => v > 0 && v <= 90000,
    'aecho delays must be above 0 and at most 90000 ms',
  );
  _checkRange(
    e.decays,
    '$stage.decays',
    _scanFloats(e.decays),
    (v) => v > 0 && v <= 1,
    'aecho decays must be above 0 and at most 1',
  );
}

/// anequalizer checks a band's frequency with comparisons that NaN
/// passes, and its width and gain not at all: a NaN or an infinity turns
/// the band's coefficients, and so the audio, to NaN.
void _checkAnequalizer(AnequalizerEffect e, String stage) {
  for (final band in _strtok(e.params, '|')) {
    _checkRange(
      e.params,
      '$stage.params',
      [
        for (final key in const ['f=', 'w=', 'g='])
          if (band.indexOf(key) case final at when at >= 0)
            ?_scanDouble(band.substring(at + key.length)),
      ],
      (_) => true,
      'anequalizer band values must be finite',
    );
  }
}

/// chorus counts each list with av_strtok and sscanf, then checks the
/// counts with `&&` where it means `||`: lists of different lengths pass
/// and the filter reads past the shorter ones. Every list needs as many
/// values as delays, which sets the number of voices. Nothing checks the
/// values either: a negative or NaN delay or depth, or a speed that is 0
/// or above the sample rate, moves the modulation index out of the delay
/// line. Speeds are capped at 100 Hz, far above a chorus and below any
/// sample rate.
void _checkChorus(ChorusEffect e, String stage) {
  final lists = [
    ('delays', e.delays, (double v) => v >= 0, 'must be 0 ms or more'),
    ('decays', e.decays, (double v) => true, 'must be finite'),
    (
      'speeds',
      e.speeds,
      (double v) => v > 0 && v <= 100,
      'must be above 0 and at most 100 Hz',
    ),
    ('depths', e.depths, (double v) => v >= 0, 'must be 0 ms or more'),
  ];
  final voices = _scanList(e.delays, '|').length;
  for (final (name, list, _, _) in lists) {
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
  for (final (name, list, ok, domain) in lists) {
    _checkRange(
      list,
      '$stage.$name',
      _scanFloats(list),
      ok,
      'chorus $name $domain',
    );
  }
}

/// Throws when a value of [values], read from [list], is not finite or
/// fails [ok].
void _checkRange(
  String list,
  String name,
  List<double> values,
  bool Function(double) ok,
  String rule,
) {
  for (final v in values) {
    if (!v.isFinite || !ok(v)) {
      throw ArgumentError.value(list, name, '$rule, not $v');
    }
  }
}

/// [_scanList] with `|` for a filter that stores its values as C floats,
/// which [_float] rounds them to.
List<double> _scanFloats(String list) => [
  for (final v in _scanList(list, '|')) _float(v),
];

final Float32List _f32 = Float32List(1);

/// [v] rounded to a C float, as sscanf's `%f` stores it.
double _float(double v) {
  _f32[0] = v;
  return _f32[0];
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
