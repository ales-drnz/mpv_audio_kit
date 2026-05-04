// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/types/enums/window_function.dart';

void main() {
  group('WindowFunction', () {
    test('rectangular is unity at every point', () {
      final w = WindowFunction.rectangular.compute(64);
      expect(w.length, 64);
      for (final v in w) {
        expect(v, 1.0);
      }
    });

    test('hann tapers to zero at both edges and peaks at the centre', () {
      final w = WindowFunction.hann.compute(128);
      expect(w[0], lessThan(1e-6));
      expect(w[127], lessThan(1e-6));
      // Peak near the middle — Hann is symmetric and reaches 1 at (N-1)/2.
      final mid = w[64];
      expect(mid, greaterThan(0.99));
    });

    test('blackmanHarris tapers to ~zero at both edges', () {
      final w = WindowFunction.blackmanHarris.compute(128);
      expect(w[0], closeTo(0, 1e-3));
      expect(w[127], closeTo(0, 1e-3));
      // Peak near centre, value near 1.
      expect(w[64], greaterThan(0.99));
    });

    test('non-power-of-two sizes still produce the right length', () {
      expect(WindowFunction.hann.compute(127).length, 127);
      expect(WindowFunction.blackmanHarris.compute(255).length, 255);
    });

    test('hann is symmetric about the centre', () {
      final w = WindowFunction.hann.compute(256);
      for (var i = 0; i < 128; i++) {
        expect(w[i], closeTo(w[255 - i], 1e-12));
      }
    });
  });
}
