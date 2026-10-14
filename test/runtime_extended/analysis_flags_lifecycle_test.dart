// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform and the loudness scan share one native decode pass and two
// process-wide flags (`waveform-enabled`, `loudness-scan-enabled`). These
// pin how the flags follow the listeners across a dispose, a cancel in the
// middle of a scan and a listener that comes back to a finished result.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// A mono 16-bit WAV of [seconds] at 48 kHz: long enough that the shared
/// decode pass is still running a moment after the file loads.
Uint8List _longWav(int seconds) {
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
  // One period of a 480 Hz tone, repeated: cheap to build, not silence.
  final period = Int16List(100);
  for (var i = 0; i < 100; i++) {
    period[i] = (12000 * math.sin(2 * math.pi * i / 100)).round();
  }
  for (var i = 0; i < frames; i++) {
    data.setInt16(44 + i * 2, period[i % 100], Endian.little);
  }
  return data.buffer.asUint8List();
}

void main() {
  final fixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  late Directory tmp;
  late String longFile;

  runtimeSuite(() {
    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('mak_analysis_flags_');
      longFile = '${tmp.path}/long.wav';
      await File(longFile).writeAsBytes(_longWav(900));
    });

    tearDownAll(() async {
      if (tmp.existsSync()) await tmp.delete(recursive: true);
    });

    test('dispose turns off the analysis flags it armed', () async {
      final a = await buildPlayer();
      final wave = a.stream.waveform.listen((_) {});
      final scan = a.stream.loudnessScan.listen((_) {});
      await openAndWaitForLoad(a, fixture);
      await waitUntil(
        () async =>
            await a.getRawProperty('waveform-enabled') == 'yes' &&
            await a.getRawProperty('loudness-scan-enabled') == 'yes',
        reason: 'the listeners armed both analyses',
      );
      // Dispose without cancelling: the listeners never go away.
      await a.dispose();
      await wave.cancel();
      await scan.cancel();

      final b = await buildPlayer();
      try {
        expect(
          await b.getRawProperty('waveform-enabled'),
          'no',
          reason:
              'the flag is a process static: left on, every file the '
              'next player opens is decoded for a waveform nobody reads',
        );
        expect(await b.getRawProperty('loudness-scan-enabled'), 'no');
      } finally {
        await b.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
