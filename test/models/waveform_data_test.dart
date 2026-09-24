// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('WaveformData', () {
    test('bins matches min length', () {
      final w = WaveformData(
        duration: const Duration(seconds: 30),
        min: Float32List.fromList(const [-0.5, -0.7, 0.0]),
        max: Float32List.fromList(const [0.4, 0.6, 0.0]),
        filled: Uint8List.fromList(const [1, 1, 0]),
      );
      expect(w.bins, 3);
      expect(w.min.length, w.max.length);
      expect(w.duration, const Duration(seconds: 30));
      expect(w.min[0], closeTo(-0.5, 1e-6));
      expect(w.max[1], closeTo(0.6, 1e-6));
    });

    test('filled carries per-bin coverage flags', () {
      final w = WaveformData(
        duration: const Duration(seconds: 10),
        min: Float32List.fromList(const [-0.2, 0.0]),
        max: Float32List.fromList(const [0.3, 0.0]),
        filled: Uint8List.fromList(const [1, 0]),
      );
      expect(w.filled.length, w.bins);
      expect(w.filled[0], 1); // covered bin
      expect(w.filled[1], 0); // not-yet-covered bin
    });

    test('rms is optional and shares the bin axis', () {
      final base = WaveformData(
        duration: const Duration(seconds: 10),
        min: Float32List.fromList(const [-0.2, 0.0]),
        max: Float32List.fromList(const [0.3, 0.0]),
        filled: Uint8List.fromList(const [1, 0]),
      );
      expect(base.rms, isNull);

      final w = WaveformData(
        duration: const Duration(seconds: 10),
        min: Float32List.fromList(const [-0.2, 0.0]),
        max: Float32List.fromList(const [0.3, 0.0]),
        rms: Float32List.fromList(const [0.15, 0.0]),
        filled: Uint8List.fromList(const [1, 0]),
      );
      expect(w.rms!.length, w.bins);
      expect(w.rms![0], closeTo(0.15, 1e-6));
    });
  });
}
