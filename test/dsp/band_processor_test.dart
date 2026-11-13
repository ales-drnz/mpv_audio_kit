// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

const _rate = 48000;
const _window = 4096;
const _hop = 1584; // 33 ms of new audio per poll, as the pcm tap delivers.

/// The last [_window] stereo frames of a 440 Hz tone ending at [end].
PcmFrame _frame(int end) {
  final s = Float32List(_window * 2);
  for (var i = 0; i < _window; i++) {
    final v = 0.3 * math.sin(2 * math.pi * 440 * (end - _window + i) / _rate);
    s[i * 2] = v;
    s[i * 2 + 1] = v;
  }
  return PcmFrame(
    samples: s,
    timestamp: Duration(microseconds: end * 1000000 ~/ _rate),
    sampleRate: _rate,
    channels: 2,
  );
}

String _dart() {
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    final exe = Platform.isWindows ? 'dart.exe' : 'dart';
    final path = [
      root,
      'bin',
      'cache',
      'dart-sdk',
      'bin',
      exe,
    ].join(Platform.pathSeparator);
    if (File(path).existsSync()) return path;
  }
  return 'dart';
}

void main() {
  // BandProcessor is public and takes any SpectrumSettings: in a release
  // build the constructor asserts are skipped, and an overlapFactor of 0
  // threw IntegerDivisionByZeroException from process. `flutter test` always
  // runs asserts, so a `dart` process, which runs none, builds the settings.
  test(
    'settings out of range are refused, in a build without asserts',
    testOn: 'mac-os || linux || windows',
    () async {
      final result = await Process.run(_dart(), [
        'test/_helpers/probes/band_processor_probe.dart',
      ], stdoutEncoding: utf8);
      expect(result.exitCode, 0, reason: '${result.stderr}');
      final report =
          jsonDecode((result.stdout as String).trim().split('\n').last)
              as Map<String, dynamic>;
      expect(report['asserts'], isFalse);
      final cases = report['cases'] as Map<String, dynamic>;
      expect(cases['defaults'], isNull);
      expect(cases['process after a refused set'], isNull);
      for (final MapEntry(:key, :value) in cases.entries) {
        if (!key.startsWith('new ') && !key.startsWith('set ')) continue;
        expect(value, anyOf('ArgumentError', 'RangeError'), reason: key);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  for (final (name, bad) in [
    ('NaN', double.nan),
    ('Inf', double.infinity),
    ('-Inf', double.negativeInfinity),
  ]) {
    test('one $name sample does not stick in the bands', () {
      final p = BandProcessor(SpectrumSettings.defaults);
      var end = _window;
      for (var i = 0; i < 20; i++) {
        p.process(_frame(end));
        end += _hop;
      }
      final poisoned = _frame(end);
      poisoned.samples[100] = bad;
      final hit = p.process(poisoned)!;
      expect(hit.bands.every((v) => v.isFinite), isTrue);
      expect(hit.bins.every((v) => v.isFinite), isTrue);

      FftFrame? last;
      for (var i = 0; i < 200; i++) {
        end += _hop;
        last = p.process(_frame(end)) ?? last;
      }
      expect(last!.bands.every((v) => v.isFinite && v >= 0 && v <= 1), isTrue);
      expect(
        last.bands.reduce(math.max),
        greaterThan(0.5),
        reason: 'the tone is back in the bands',
      );
    });
  }
}
