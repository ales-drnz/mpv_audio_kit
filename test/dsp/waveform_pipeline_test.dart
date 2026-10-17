// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform poll against a fake mpv, with no libmpv loaded.

import 'dart:async';
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/dsp/waveform_pipeline.dart';
import 'package:test/test.dart';

Future<void> _ticks(int n, Duration tick) =>
    Future<void>.delayed(tick * n + const Duration(milliseconds: 5));

Uint8List _floats(int n, double v) =>
    (Float32List(n)..fillRange(0, n, v)).buffer.asUint8List();

void main() {
  group('waveform growing with playback', () {
    Map<String, Object?> node(String state, int bins, {double level = 0.5}) => {
      'state': state,
      'duration_us': 10000000,
      'range_start_us': 0,
      'range_end_us': bins * 40000,
      'min': _floats(bins, -level),
      'max': _floats(bins, level),
      'rms': _floats(bins, level / 2),
      'filled': Uint8List(bins)..fillRange(0, bins, 1),
    };

    for (final state in ['progressive', 'rolling']) {
      test('$state: an unchanged envelope is emitted once', () async {
        var current = node(state, 100);
        var gets = 0;
        final p = WaveformPipeline(
          asyncGet: (name, format) async {
            gets++;
            return (0, current);
          },
          asyncSet: (name, value) async => 0,
          pollInterval: const Duration(milliseconds: 10),
        );
        final got = <WaveformData?>[];
        p.stream.listen(got.add);
        p.setEnabled(true);
        await _ticks(6, const Duration(milliseconds: 10));
        expect(gets, greaterThan(3), reason: 'it keeps polling');
        expect(got.whereType<WaveformData>(), hasLength(1));

        // One bin changes in place: a new emission.
        current = node(state, 100);
        (current['max']! as Uint8List).buffer.asFloat32List()[99] = 0.9;
        await _ticks(3, const Duration(milliseconds: 10));
        final waves = got.whereType<WaveformData>().toList();
        expect(waves, hasLength(2));
        expect(waves.last.max[99], closeTo(0.9, 1e-6));

        // It grows: a new emission.
        current = node(state, 101);
        await _ticks(3, const Duration(milliseconds: 10));
        expect(got.whereType<WaveformData>(), hasLength(3));
        await p.dispose();
      });
    }

    test('a new file emits its first envelope again', () async {
      final p = WaveformPipeline(
        asyncGet: (name, format) async => (0, node('progressive', 50)),
        asyncSet: (name, value) async => 0,
        pollInterval: const Duration(milliseconds: 10),
      );
      final got = <WaveformData?>[];
      p.stream.listen(got.add);
      p.setEnabled(true);
      await _ticks(3, const Duration(milliseconds: 10));
      p.reset();
      await _ticks(3, const Duration(milliseconds: 10));
      expect(got.map((w) => w == null ? 'null' : 'data'), [
        'data',
        'null',
        'data',
      ]);
      await p.dispose();
    });
  });

  test('a ready envelope shorter than its axis pads the tail', () async {
    // The length estimated from the bitrate was three times the audio:
    // the decode filled 10 bins of the 30 on the axis.
    final p = WaveformPipeline(
      asyncGet: (name, format) async => (
        0,
        {
          'state': 'ready',
          'duration_us': 18000000,
          'total_bins': 30,
          'min': _floats(10, -0.5),
          'max': _floats(10, 0.5),
          'rms': _floats(10, 0.25),
          'filled': Uint8List(10)..fillRange(0, 10, 1),
        },
      ),
      asyncSet: (name, value) async => 0,
      pollInterval: const Duration(milliseconds: 10),
    );
    final got = <WaveformData?>[];
    p.stream.listen(got.add);
    p.setEnabled(true);
    await _ticks(2, const Duration(milliseconds: 10));
    final w = got.whereType<WaveformData>().single;
    expect(w.bins, 30);
    expect(w.duration, const Duration(seconds: 18));
    expect(w.filled.sublist(0, 10), everyElement(1));
    expect(w.filled.sublist(10), everyElement(0));
    expect(w.min[9], closeTo(-0.5, 1e-6));
    expect(w.max[9], closeTo(0.5, 1e-6));
    expect(w.rms![9], closeTo(0.25, 1e-6));
    expect(w.min.sublist(10), everyElement(0));
    expect(w.max.sublist(10), everyElement(0));
    expect(w.rms!.sublist(10), everyElement(0));
    await p.dispose();
  });
}
