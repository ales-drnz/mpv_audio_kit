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

  group('a new listener on a finished result does not decode again', () {
    test('no yes while the result stands, yes on the next file', () async {
      final mpv = _FakeMpv()..values['waveform-data'] = _readyWave();
      final p = WaveformPipeline(asyncGet: mpv.get, asyncSet: mpv.set);
      final got = <Object?>[];
      final sub = p.stream.listen(got.add);
      p.setEnabled(true);
      await _settle();
      expect(got.whereType<Object>(), hasLength(1), reason: 'ready');

      p.setEnabled(false);
      p.setEnabled(true);
      p.setEnabled(false);
      p.setEnabled(true);
      await _settle();
      expect(mpv.sets, ['waveform-enabled=yes', 'waveform-enabled=no']);

      // The next file arms the analysis again.
      mpv.values.remove('waveform-data');
      p.reset();
      await _settle();
      expect(mpv.sets.last, 'waveform-enabled=yes');

      // And the next cancel turns it off.
      p.setEnabled(false);
      await _settle();
      expect(mpv.sets.last, 'waveform-enabled=no');
      await sub.cancel();
      await p.dispose();
    });

    test('dispose after a deferred yes writes nothing more', () async {
      final mpv = _FakeMpv()..values['waveform-data'] = _readyWave();
      final p = WaveformPipeline(asyncGet: mpv.get, asyncSet: mpv.set);
      p.setEnabled(true);
      await _settle();
      p.setEnabled(false);
      p.setEnabled(true);
      await p.dispose();
      await _settle();
      expect(mpv.sets, ['waveform-enabled=yes', 'waveform-enabled=no']);
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

  group('two players', () {
    test('one player\'s cancel or dispose leaves the other\'s on', () async {
      final a = _FakeMpv();
      final b = _FakeMpv();
      final pa = WaveformPipeline(asyncGet: a.get, asyncSet: a.set);
      final pb = WaveformPipeline(asyncGet: b.get, asyncSet: b.set);
      pa.setEnabled(true);
      pb.setEnabled(true);
      await _settle();
      pb.setEnabled(false);
      pb.setEnabled(true);
      await pb.dispose();
      await _settle();
      expect(a.sets, ['waveform-enabled=yes']);
      expect(b.sets, ['waveform-enabled=yes', 'waveform-enabled=yes']);

      // The last one to let go turns it off.
      pa.setEnabled(false);
      await _settle();
      expect(a.sets.last, 'waveform-enabled=no');
      await pa.dispose();
    });

    test('an enable waits for the other player\'s disable', () async {
      // B's core is busy: its no must land before A's yes.
      final reply = Completer<int>();
      final a = _FakeMpv();
      final bSets = <String>[];
      final pa = LoudnessScanPipeline(asyncGet: a.get, asyncSet: a.set);
      final pb = LoudnessScanPipeline(
        asyncGet: a.get,
        asyncSet: (name, value) {
          bSets.add('$name=$value');
          return reply.future;
        },
      );
      pb.setEnabled(true);
      pb.setEnabled(false);
      pa.setEnabled(true);
      await _settle();
      expect(bSets, ['loudness-scan-enabled=yes', 'loudness-scan-enabled=no']);
      expect(a.sets, isEmpty);
      reply.complete(0);
      await _settle();
      expect(a.sets, ['loudness-scan-enabled=yes']);
      await pa.dispose();
      await pb.dispose();
      await _settle();
      expect(a.sets.last, 'loudness-scan-enabled=no');
    });
  });
}
