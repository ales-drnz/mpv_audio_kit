// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'dart:typed_data';

/// A mono 16-bit WAV of [seconds] at 48 kHz: long enough that the shared
/// decode pass of the waveform and the loudness scan is still running for
/// a while after the file loads, with no network involved.
///
/// The tone is a 480 Hz sine whose level rises across the whole file. No
/// two waveform bins hold the same peak, and a bin read before the decode
/// sealed it holds a smaller peak than its final one.
Uint8List longWav(int seconds) {
  const rate = 48000;
  final frames = rate * seconds;
  final data = ByteData(44 + frames * 2);
  void ascii(int at, String s) {
    for (var k = 0; k < s.length; k++) {
      data.setUint8(at + k, s.codeUnitAt(k));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + frames * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, rate, Endian.little);
  data.setUint32(28, rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, frames * 2, Endian.little);
  // One period of the tone, scaled by a level that rises from 0.1 to 0.9
  // of full scale: cheap to build, not silence, never flat.
  final period = Float64List(100);
  for (var i = 0; i < 100; i++) {
    period[i] = math.sin(2 * math.pi * i / 100);
  }
  for (var i = 0; i < frames; i++) {
    final level = 0.1 + 0.8 * i / frames;
    data.setInt16(
      44 + i * 2,
      (32767 * level * period[i % 100]).round(),
      Endian.little,
    );
  }
  return data.buffer.asUint8List();
}
