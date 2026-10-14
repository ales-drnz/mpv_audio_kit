// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The per-file analyses (waveform, loudness scan) drive process-wide native
// flags: `waveform-enabled` and `loudness-scan-enabled` are statics of the
// libmpv process, not of one core. These pin the writes the pipelines make
// against a fake mpv, with no libmpv loaded.

import 'dart:async';
import 'dart:typed_data';

import 'package:mpv_audio_kit/src/dsp/loudness_scan_pipeline.dart';
import 'package:mpv_audio_kit/src/dsp/waveform_pipeline.dart';
import 'package:test/test.dart';

/// A fake mpv: [values] answers the gets, every set is recorded.
final class _FakeMpv {
  final Map<String, Object?> values = {};
  final List<String> sets = [];
  int gets = 0;

  Future<(int, dynamic)> get(String name, int format) async {
    gets++;
    return values.containsKey(name) ? (0, values[name]) : (-8, null);
  }

  Future<int> set(String name, String value) async {
    sets.add('$name=$value');
    return 0;
  }
}

Map<String, Object?> _readyWave() => {
  'state': 'ready',
  'duration_us': 1000000,
  'min': Uint8List(16),
  'max': Uint8List(16),
};

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 5));

void main() {
  group('dispose turns off the analysis it armed', () {
    test('waveform', () async {
      final mpv = _FakeMpv();
      final p = WaveformPipeline(asyncGet: mpv.get, asyncSet: mpv.set);
      p.setEnabled(true);
      await p.dispose();
      await _settle();
      expect(mpv.sets, ['waveform-enabled=yes', 'waveform-enabled=no']);
    });

    test('loudness scan', () async {
      final mpv = _FakeMpv();
      final p = LoudnessScanPipeline(asyncGet: mpv.get, asyncSet: mpv.set);
      p.setEnabled(true);
      await p.dispose();
      await _settle();
      expect(mpv.sets, [
        'loudness-scan-enabled=yes',
        'loudness-scan-enabled=no',
      ]);
    });

    test('an analysis never armed writes nothing', () async {
      final mpv = _FakeMpv();
      final p = WaveformPipeline(asyncGet: mpv.get, asyncSet: mpv.set);
      await p.dispose();
      await _settle();
      expect(mpv.sets, isEmpty);
    });
  });

  test('a poll in flight at dispose emits nothing', () async {
    final gate = Completer<void>();
    final mpv = _FakeMpv();
    final p = WaveformPipeline(
      asyncGet: (name, format) async {
        await gate.future;
        return (0, _readyWave());
      },
      asyncSet: mpv.set,
    );
    final got = <Object?>[];
    p.stream.listen(got.add);
    p.setEnabled(true);
    await p.dispose();
    gate.complete();
    await _settle();
    expect(got, isEmpty);
  });
}
