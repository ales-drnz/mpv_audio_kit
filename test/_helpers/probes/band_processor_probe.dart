// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A plain `dart` program (no Flutter) that hands BandProcessor spectrum
// settings the constructor asserts refuse, as a release build lets through.
// `flutter test` always runs with asserts, so the tests run this in a `dart`
// process, which runs without them. Prints one JSON line:
// - `asserts`: whether this process runs asserts;
// - `cases`: per case, the type of the error thrown, or `null` when the
//   call returns.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mpv_audio_kit/src/dsp/band_processor.dart';
import 'package:mpv_audio_kit/src/models/pcm_frame.dart';
import 'package:mpv_audio_kit/src/types/settings/spectrum_settings.dart';

PcmFrame _frame() => PcmFrame(
  samples: Float32List(8192),
  timestamp: const Duration(seconds: 1),
  sampleRate: 48000,
  channels: 2,
);

void main() {
  var asserts = false;
  assert(asserts = true);
  final cases = <String, void Function()>{
    'defaults': () =>
        BandProcessor(SpectrumSettings.defaults).process(_frame()),
    'new overlapFactor 0': () =>
        BandProcessor(SpectrumSettings(overlapFactor: 0)),
    'new overlapFactor 3': () =>
        BandProcessor(SpectrumSettings(overlapFactor: 3)),
    'new fftSize 1000': () => BandProcessor(SpectrumSettings(fftSize: 1000)),
    'new bandCount 0': () => BandProcessor(SpectrumSettings(bandCount: 0)),
    'set overlapFactor 0': () => BandProcessor(
      SpectrumSettings.defaults,
    ).setSettings(SpectrumSettings(overlapFactor: 0)),
    'set fftSize 8192': () => BandProcessor(
      SpectrumSettings.defaults,
    ).setSettings(SpectrumSettings(fftSize: 8192)),
    // Refused settings leave the processor as it was.
    'process after a refused set': () {
      final p = BandProcessor(SpectrumSettings.defaults);
      try {
        p.setSettings(SpectrumSettings(overlapFactor: 0));
      } on Error catch (_) {}
      p.process(_frame());
    },
  };
  final report = <String, String?>{};
  for (final MapEntry(:key, :value) in cases.entries) {
    try {
      value();
      report[key] = null;
    } on Error catch (e) {
      report[key] = e.runtimeType.toString();
    }
  }
  stdout.writeln(jsonEncode({'asserts': asserts, 'cases': report}));
}
