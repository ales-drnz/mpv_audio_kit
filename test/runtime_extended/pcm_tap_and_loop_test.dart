// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The PCM patches of libmpv-r18 (pcm_tap, pcm_stream). Up to r17 the tap
// behind `stream.pcm` kept the samples of the previous output format
// after a change of channels or rate, and read them as the new format
// (F47). A live PCM entry set to loop seeked back at its end, failed, and
// tried again on every turn of the playloop, with no end (F225).

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// [seconds] of a constant [level] in a 16-bit WAV of [channels] at 48 kHz.
Uint8List _dcWav(int channels, double level, int seconds) {
  const rate = 48000;
  final samples = rate * seconds * channels;
  final d = ByteData(44 + samples * 2);
  void ascii(int at, String s) {
    for (var k = 0; k < s.length; k++) {
      d.setUint8(at + k, s.codeUnitAt(k));
    }
  }

  ascii(0, 'RIFF');
  d.setUint32(4, 36 + samples * 2, Endian.little);
  ascii(8, 'WAVEfmt ');
  d.setUint32(16, 16, Endian.little);
  d.setUint16(20, 1, Endian.little);
  d.setUint16(22, channels, Endian.little);
  d.setUint32(24, rate, Endian.little);
  d.setUint32(28, rate * channels * 2, Endian.little);
  d.setUint16(32, channels * 2, Endian.little);
  d.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  d.setUint32(40, samples * 2, Endian.little);
  final v = (level * 32768).round();
  for (var i = 0; i < samples; i++) {
    d.setInt16(44 + i * 2, v, Endian.little);
  }
  return d.buffer.asUint8List();
}

void main() {
  runtimeSuite(() {
    libmpvReleaseGroup(18, 'PCM patches', () {
      late Player player;
      late Directory dir;

      setUp(() async {
        dir = Directory.systemTemp.createTempSync('mak_pcm_r18');
        player = await buildPlayer(
          configuration: const PlayerConfiguration(), // logs from warn up
        );
      });

      tearDown(() async {
        await player.dispose();
        dir.deleteSync(recursive: true);
      });

      // F47: stereo at +0.25, then mono at -0.5. A small output buffer, so
      // the first write after the change does not fill the window by itself
      // and what the ring kept from before shows.
      test('after a change of channels the tap holds only the new '
          'format', () async {
        final stereo = File('${dir.path}/stereo.wav')
          ..writeAsBytesSync(_dcWav(2, 0.25, 1));
        final mono = File('${dir.path}/mono.wav')
          ..writeAsBytesSync(_dcWav(1, -0.5, 1));
        await player.setRawProperty('ao-null-buffer', '0.02');
        var monoFrames = 0;
        var stale = 0;
        final sub = player.stream.pcm.listen((frame) {
          if (frame.channels != 1) return;
          monoFrames++;
          if (frame.samples.any((s) => s > 0)) stale++;
        });
        final done = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 10));
        await player.openAll([
          Media(stereo.path),
          Media(mono.path),
        ], play: true);
        await done;
        await sub.cancel();
        expect(monoFrames, greaterThan(5), reason: 'the mono file was tapped');
        expect(
          stale,
          0,
          reason:
              '$stale of $monoFrames mono frames held samples of the '
              'stereo file',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F225: r17 logged tens of thousands of "Cannot seek" a second, kept
      // the core busy and never left the entry.
      group('a live PCM entry with Loop.file plays once', () {
        late PcmSource source;
        var seekErrors = 0;

        setUp(() async {
          const format = PcmFormat(sampleRate: 48000, channels: 2);
          final tone = ByteData(48000 * format.bytesPerFrame);
          for (var i = 0; i < 48000; i++) {
            final v = (0.3 * 32767 * math.sin(2 * math.pi * 440 * i / 48000))
                .round();
            tone
              ..setInt16(i * 4, v, Endian.little)
              ..setInt16(i * 4 + 2, v, Endian.little);
          }
          seekErrors = 0;
          player.stream.log.listen((l) {
            if (l.text.contains('Cannot seek')) seekErrors++;
          });
          await player.setLoop(Loop.file);
          source = PcmSource.create(format)..add(tone.buffer.asUint8List());
          await source.close();
        });

        test('and parks at its end', () async {
          final parked = player.stream.eofReached
              .firstWhere((eof) => eof)
              .then((_) => true)
              .timeout(const Duration(seconds: 6), onTimeout: () => false);
          await player.open(source.toMedia(), play: true);
          expect(await parked, isTrue, reason: 'the entry never ended');
          final at = player.state.position;
          await Future<void>.delayed(const Duration(milliseconds: 500));
          expect(player.state.position, at, reason: 'it plays on');
          expect(player.state.playing, isFalse);
          expect(seekErrors, 0, reason: 'mpv tried to loop a live source');
        }, timeout: const Timeout(Duration(seconds: 30)));

        // The loop stays on for the entries that can repeat, but this one
        // has ended: the kit read Loop.file as a restart to come and held
        // `completed` down at the park.
        test('and completed rises at its park', () async {
          final completed = player.stream.completed
              .firstWhere((c) => c)
              .then((_) => true)
              .timeout(const Duration(seconds: 6), onTimeout: () => false);
          await player.open(source.toMedia(), play: true);
          expect(await completed, isTrue, reason: 'no completed at the park');
          expect(player.state.loop, Loop.file);
          expect(player.state.playWhenReady, isFalse);
        }, timeout: const Timeout(Duration(seconds: 30)));

        test('and the next entry follows', () async {
          final next = player.stream.playlist
              .firstWhere((p) => p.index == 1)
              .then((_) => true)
              .timeout(const Duration(seconds: 6), onTimeout: () => false);
          await player.openAll([
            source.toMedia(),
            Media(defaultFixturePath()),
          ], play: true);
          expect(await next, isTrue, reason: 'the live entry never ended');
          expect(seekErrors, 0, reason: 'mpv tried to loop a live source');
        }, timeout: const Timeout(Duration(seconds: 30)));
      });
    });
  });
}
