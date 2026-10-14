// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The spectrum poll against a fake mpv, with no libmpv loaded.

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/dsp/spectrum_pipeline.dart';
import 'package:test/test.dart';

void main() {
  group('spectrum', () {
    test('an emit interval under 8 ms is polled every 8 ms', () async {
      var gets = 0;
      final p = SpectrumPipeline(
        asyncGet: (name, format) async {
          gets++;
          return (-10, null);
        },
      )..setSettings(const SpectrumSettings(emitInterval: Duration.zero));
      final sub = p.fftStream.listen((_) {});
      await Future<void>.delayed(const Duration(milliseconds: 160));
      expect(gets, lessThanOrEqualTo(22), reason: '$gets reads in 160 ms');
      await sub.cancel();
      await p.dispose();
    });
  });
}
