// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:typed_data';

import 'package:mpv_audio_kit/src/dsp/dsp_async_io.dart';
import 'package:test/test.dart';

/// `float32FromByteValue` is the single shared reinterpret behind every
/// async-get DSP pipeline (spectrum samples, waveform min/max, filter-tap
/// rings): it turns the [Uint8List] the event isolate decodes from a
/// `MPV_FORMAT_BYTE_ARRAY` into a [Float32List]. Its correctness rests on a
/// non-obvious invariant — a `SendPort`-transferred typed-data buffer starts
/// 4-byte-aligned at offset 0, so `buffer.asFloat32List(0, n)` cannot throw —
/// plus an offset/length-aware copy fallback. These pin both paths.
void main() {
  Uint8List bytesOf(List<double> floats) {
    final f = Float32List.fromList(floats);
    return f.buffer.asUint8List(f.offsetInBytes, f.lengthInBytes);
  }

  test('round-trips an aligned 4N-byte buffer bit-exact', () {
    const samples = [0.0, 1.0, -1.0, 0.5, -0.25, 1234.5];
    final out = float32FromByteValue(bytesOf(samples));
    expect(out, isNotNull);
    expect(out!.length, samples.length);
    for (var i = 0; i < samples.length; i++) {
      expect(out[i], samples[i]);
    }
  });

  test('takes the copy path for a non-zero-offset view and stays correct', () {
    const samples = [3.5, -7.25, 42.0, 0.0];
    final full = bytesOf(samples);
    // A view starting 4 bytes in (one float): offsetInBytes != 0 forces the
    // aligned-copy fallback. It must decode samples[1..] correctly.
    final view = Uint8List.view(full.buffer, full.offsetInBytes + 4);
    final out = float32FromByteValue(view);
    expect(out, isNotNull);
    expect(out!.length, samples.length - 1);
    expect(out[0], samples[1]);
    expect(out[1], samples[2]);
    expect(out[2], samples[3]);
  });

  test('drops a trailing partial sample (length not a multiple of 4)', () {
    final full = bytesOf(const [9.0, -9.0]); // 8 bytes
    final ragged = Uint8List(10)..setRange(0, 8, full);
    final out = float32FromByteValue(ragged);
    expect(out, isNotNull);
    expect(out!.length, 2, reason: '10 bytes → 2 whole float32 samples');
    expect(out[0], 9.0);
    expect(out[1], -9.0);
  });

  test('returns null for too-small, non-byte, and null inputs', () {
    expect(float32FromByteValue(Uint8List(0)), isNull);
    expect(float32FromByteValue(Uint8List(3)), isNull, reason: '< 4 bytes');
    expect(float32FromByteValue(null), isNull);
    expect(float32FromByteValue('not bytes'), isNull);
    expect(
      float32FromByteValue(<int>[1, 2, 3, 4]),
      isNull,
      reason: 'a plain List<int> is not a Uint8List',
    );
  });
}
