// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A plain `dart` program (no Flutter) that builds spectrum settings the
// constructor asserts refuse, as a release build lets through, and reports
// what SpectrumSettings.validate does with each. `flutter test` always runs
// with asserts, so the tests run this in a `dart` process, which runs
// without them. Prints one JSON line:
// - `asserts`: whether this process runs asserts;
// - `cases`: per case, the type of the error validate throws, or `null`
//   when it returns.

import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/src/types/settings/spectrum_settings.dart';

void main() {
  var asserts = false;
  assert(asserts = true);
  final cases = <String, SpectrumSettings Function()>{
    'defaults': SpectrumSettings.new,
    'edges': () => const SpectrumSettings(
      fftSize: 256,
      bandCount: 1,
      bandLowHz: 0.001,
      bandHighHz: 0.002,
      attackSmoothing: 0,
      releaseSmoothing: 1,
      overlapFactor: 16,
    ),
    'fftSize 1000': () => SpectrumSettings(fftSize: 1000),
    'fftSize 128': () => SpectrumSettings(fftSize: 128),
    'fftSize 8192': () => SpectrumSettings(fftSize: 8192),
    'bandCount 0': () => SpectrumSettings(bandCount: 0),
    'bandCount -1': () => SpectrumSettings(bandCount: -1),
    'bandLowHz 0': () => SpectrumSettings(bandLowHz: 0),
    'bandLowHz NaN': () => SpectrumSettings(bandLowHz: double.nan),
    'bandHighHz 20': () => SpectrumSettings(bandHighHz: 20),
    'attackSmoothing 1.5': () => SpectrumSettings(attackSmoothing: 1.5),
    'attackSmoothing NaN': () => SpectrumSettings(attackSmoothing: double.nan),
    'releaseSmoothing -0.1': () => SpectrumSettings(releaseSmoothing: -0.1),
    'maxDb -100': () => SpectrumSettings(maxDb: -100),
    'overlapFactor 0': () => SpectrumSettings(overlapFactor: 0),
    'overlapFactor 3': () => SpectrumSettings(overlapFactor: 3),
    'overlapFactor 32': () => SpectrumSettings(overlapFactor: 32),
  };
  final report = <String, String?>{};
  for (final MapEntry(:key, :value) in cases.entries) {
    try {
      value().validate();
      report[key] = null;
    } on Error catch (e) {
      report[key] = e.runtimeType.toString();
    }
  }
  stdout.writeln(jsonEncode({'asserts': asserts, 'cases': report}));
}
