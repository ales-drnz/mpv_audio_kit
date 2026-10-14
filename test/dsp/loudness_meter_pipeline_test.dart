// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The live loudness meter against a fake mpv, with no libmpv loaded.

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/dsp/loudness_meter_pipeline.dart';
import 'package:test/test.dart';

Future<void> _ticks(int n, Duration tick) =>
    Future<void>.delayed(tick * n + const Duration(milliseconds: 5));

void main() {
  group('loudness meter', () {
    test('one read per tick, parsed from the frame metadata', () async {
      final names = <String>[];
      final meter = LoudnessMeterPipeline(
        asyncGet: (name, format) async {
          names.add(name);
          return (
            0,
            {
              'lavfi.r128.M': '-inf',
              'lavfi.r128.S': '-23.500',
              'lavfi.r128.I': '-70.000',
              'lavfi.r128.LRA': '0.000',
            },
          );
        },
        label: () => 'aek_ebur128_0',
        pollInterval: const Duration(milliseconds: 10),
      );
      final got = <Loudness>[];
      meter.stream.listen(got.add);
      meter.setEnabled(true);
      await _ticks(5, const Duration(milliseconds: 10));
      meter.setEnabled(false);
      expect(got, isNotEmpty);
      expect(names, hasLength(got.length), reason: 'one read per tick');
      expect(names.toSet(), {'af-metadata/aek_ebur128_0'});
      expect(
        got.first,
        const Loudness(shortTerm: -23.5, integrated: -70, range: 0),
        reason: 'ffmpeg writes -inf in silence, read as null',
      );
      await meter.dispose();
    });

    test('silent while the stage has no metadata', () async {
      final meter = LoudnessMeterPipeline(
        asyncGet: (name, format) async => (-10, null),
        label: () => 'aek_ebur128_0',
        pollInterval: const Duration(milliseconds: 10),
      );
      final got = <Loudness>[];
      meter.stream.listen(got.add);
      meter.setEnabled(true);
      await _ticks(4, const Duration(milliseconds: 10));
      expect(got, isEmpty);
      await meter.dispose();
    });
  });
}
