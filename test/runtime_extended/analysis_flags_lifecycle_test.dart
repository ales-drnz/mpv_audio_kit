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

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
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

    test(
      'cancelling the waveform mid scan lets the loudness scan finish',
      () async {
        final player = await buildPlayer();
        try {
          final wave = player.stream.waveform.listen((_) {});
          final progress = <double?>[];
          final ready = player.stream.loudnessScan
              .where((s) {
                if (s?.state == LoudnessScanState.scanning) {
                  progress.add(s!.progress);
                }
                return s?.state == LoudnessScanState.ready;
              })
              .first
              .timeout(const Duration(seconds: 30));
          await openAndWaitForLoad(player, longFile);
          final early = await player.getRawPropertyNode('loudness-scan-data');
          await wave.cancel();
          expect(
            (early as Map?)?['state'],
            'scanning',
            reason: 'the file must still be scanning when the waveform goes',
          );
          final result = (await ready)!;
          expect(result.integrated, isNotNull);
          expect(result.integrated!, lessThan(0));
        } finally {
          await player.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    test(
      'a listener back on a finished waveform does not decode again',
      () async {
        final player = await buildPlayer();
        try {
          // Loaded first, so the track change is behind us.
          await openAndWaitForLoad(player, fixture);
          final done = (await player.stream.waveform
              .firstWhere((w) => w != null && !w.decoding)
              .timeout(const Duration(seconds: 10)))!;

          // Back on the same file: the replay gives the result and the
          // native analyzer stays off.
          final again = await player.stream.waveform.first.timeout(
            const Duration(seconds: 2),
          );
          expect(again, same(done));
          final sub = player.stream.waveform.listen((_) {});
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(await player.getRawProperty('waveform-enabled'), 'no');
          final data = await player.getRawPropertyNode('waveform-data');
          expect((data as Map?)?['state'], isNot('decoding'));

          // The next file is analyzed for the listener that stayed.
          final next = player.stream.waveform
              .skipWhile((w) => w != null)
              .firstWhere((w) => w != null && !w.decoding)
              .timeout(const Duration(seconds: 10));
          await openAndWaitForLoad(
            player,
            '${Directory.current.path}/test/fixtures/sine_stereo_1s.flac',
          );
          final w = (await next)!;
          expect(w.duration.inMilliseconds, closeTo(1000, 50));
          expect(await player.getRawProperty('waveform-enabled'), 'yes');
          await sub.cancel();
        } finally {
          await player.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "one player's cancel or dispose leaves another's analysis on",
      () async {
        final a = await buildPlayer();
        final b = await buildPlayer();
        var bGone = false;
        try {
          final aWave = a.stream.waveform.listen((_) {});
          final aScan = a.stream.loudnessScan.listen((_) {});
          Future<void> flags(String value) => waitUntil(
            () async =>
                await a.getRawProperty('waveform-enabled') == value &&
                await a.getRawProperty('loudness-scan-enabled') == value,
            reason: 'the analysis flags are not $value',
          );
          Future<void> analyzed(String path) async {
            final wave = a.stream.waveform
                .firstWhere((w) => w != null && !w.decoding)
                .timeout(const Duration(seconds: 10));
            final scan = a.stream.loudnessScan
                .firstWhere((s) => s?.state == LoudnessScanState.ready)
                .timeout(const Duration(seconds: 10));
            await openAndWaitForLoad(a, path);
            await wave;
            await scan;
          }

          await flags('yes');

          // B comes and goes without loading anything: a page that
          // subscribes and leaves.
          await b.stream.waveform.listen((_) {}).cancel();
          await b.stream.loudnessScan.listen((_) {}).cancel();
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await analyzed(fixture);

          // B goes with its listeners attached.
          final bWave = b.stream.waveform.listen((_) {});
          final bScan = b.stream.loudnessScan.listen((_) {});
          await b.dispose();
          bGone = true;
          await bWave.cancel();
          await bScan.cancel();
          await analyzed(
            '${Directory.current.path}/test/fixtures/sine_stereo_1s.flac',
          );
          await flags('yes');

          // The last listener of the isolate turns them off.
          await aWave.cancel();
          await aScan.cancel();
          await flags('no');
        } finally {
          if (!bGone) await b.dispose();
          await a.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );
  });
}
