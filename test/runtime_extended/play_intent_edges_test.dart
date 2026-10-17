// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// `playWhenReady` follows what play() can actually do: nothing plays
/// from an idle core, a source that cannot seek back stays at its end, and
/// a load that fails before reaching mpv leaves the intent it found.
void main() {
  final fixturePath = defaultFixturePath();
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  final shortFixture = '${Directory.current.path}/test/fixtures/sine_50ms.wav';
  const speech = PcmFormat(sampleRate: 24000, channels: 1);

  Uint8List tone(int ms) {
    final frames = speech.sampleRate * ms ~/ 1000;
    final d = ByteData(frames * speech.bytesPerFrame);
    for (var i = 0; i < frames; i++) {
      final v = 0.3 * math.sin(2 * math.pi * 440 * i / speech.sampleRate);
      d.setInt16(i * 2, (v * 32767).round(), Endian.little);
    }
    return d.buffer.asUint8List();
  }

  runtimeSuite(fixturePath: fixturePath, () {
    const t = Timeout(Duration(seconds: 30));

    test('play() before any open leaves the intent off', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await player.play();
      expect(player.state.playWhenReady, isFalse);
    }, timeout: t);

    test('play() after stop() leaves the intent off', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await player.open(Media(fixturePath), play: true);
      await waitUntil(() => player.state.playing);
      await player.stop();
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      await player.play();
      expect(player.state.playWhenReady, isFalse);
    }, timeout: t);

    // The core is still idle when play() reads it: the load in flight is
    // what keeps the intent on.
    test('play() right after an unawaited open keeps the intent', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final opening = player.open(Media(fixturePath), play: false);
      await player.play();
      await opening;
      expect(player.state.playWhenReady, isTrue);
      // The pause write of the open comes after the unpause: it follows
      // the intent the play() set, so the file plays.
      expect(await player.getRawProperty('pause'), 'no');
      await waitUntil(() => player.state.playing);
    }, timeout: t);

    test('pause() right after an unawaited open keeps it paused', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final opening = player.open(Media(fixturePath), play: true);
      await player.pause();
      await opening;
      expect(player.state.playWhenReady, isFalse);
      expect(await player.getRawProperty('pause'), 'yes');
    }, timeout: t);

    test('play() right after an unawaited openAll plays', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final opening = player.openAll([
        Media(fixturePath),
        Media(fixturePath),
      ], play: false);
      await player.play();
      await opening;
      expect(player.state.playWhenReady, isTrue);
      expect(await player.getRawProperty('pause'), 'no');
    }, timeout: t);

    test('play() at the end of a closed PCM source stays off', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      final source = await player.openPcmStream(speech);
      source.add(tone(500));
      await source.close();
      await completed;

      await player.play();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(
        player.state.playWhenReady,
        isFalse,
        reason: 'the intent shows playback over a source that cannot restart',
      );
      expect(player.state.completed, isTrue);
    }, timeout: t);

    test('play() at the end of a file starts it again', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: true);
      await completed;

      await player.play();
      await waitUntil(() => !player.state.completed && player.state.playing);
      expect(player.state.playWhenReady, isTrue);
    }, timeout: t);

    // play() reads the core before it unpauses: a pause() called after it
    // has the last word, and the unpause must not land after its write.
    test('play() then pause() without awaiting leaves it paused', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await openAndWaitForLoad(player, longFixture);
      final playing = player.play();
      final pausing = player.pause();
      await Future.wait([playing, pausing]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(await player.getRawProperty('pause'), 'yes');
      expect(player.state.playWhenReady, isFalse);
      expect(player.state.playing, isFalse);
    }, timeout: t);

    test('play() at the end then pause() stays paused', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: true);
      await completed;

      final playing = player.play();
      final pausing = player.pause();
      await Future.wait([playing, pausing]);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(await player.getRawProperty('pause'), 'yes');
      expect(player.state.playWhenReady, isFalse);
      expect(player.state.playing, isFalse);
    }, timeout: t);

    // At the end of the queue openAll steps through idle: mpv cannot append
    // behind a parked entry without playing into the new album. That idle
    // is the load's own step, not the end of the content: it must not
    // spend the intent. Eight runs each, since the step lasts a few ms.
    group('openAll at the end of the queue', () {
      const runs = 8;

      Future<Player> parked() async {
        final player = await buildPlayer();
        await player.openAll([Media(shortFixture)], play: true);
        await waitUntil(
          () => player.state.completed,
          timeout: const Duration(seconds: 15),
          reason: 'never parked',
        );
        return player;
      }

      test('with play() in flight plays', () async {
        for (var run = 0; run < runs; run++) {
          final player = await parked();
          try {
            final opening = player.openAll([
              Media(fixturePath),
              Media(fixturePath),
            ], play: false);
            await player.play();
            await opening;
            await waitUntil(
              () => player.state.playing && player.state.playWhenReady,
              timeout: const Duration(seconds: 2),
              reason:
                  'run $run: playing ${player.state.playing}, '
                  'playWhenReady ${player.state.playWhenReady}',
            );
            expect(await player.getRawProperty('pause'), 'no');
          } finally {
            await player.dispose();
          }
        }
      }, timeout: const Timeout(Duration(seconds: 120)));

      test('with play: true never shows paused', () async {
        for (var run = 0; run < runs; run++) {
          final player = await parked();
          final seen = <bool>[];
          final sub = player.stream.playWhenReady.listen(seen.add);
          try {
            await Future<void>.delayed(const Duration(milliseconds: 100));
            seen.clear();
            await player.openAll([
              Media(fixturePath),
              Media(fixturePath),
            ], play: true);
            await waitUntil(
              () => player.state.playing,
              timeout: const Duration(seconds: 2),
              reason: 'run $run: not playing',
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));
            expect(seen, isNot(contains(false)), reason: 'run $run: $seen');
            expect(player.state.playWhenReady, isTrue);
          } finally {
            await sub.cancel();
            await player.dispose();
          }
        }
      }, timeout: const Timeout(Duration(seconds: 120)));
    });

    // jump() claims the intent at the call, like play() and open().
    group('jump()', () {
      Future<Player> pausedQueue() async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.openAll([
          Media(longFixture),
          Media(longFixture),
          Media(longFixture),
        ], play: false);
        await loaded;
        return player;
      }

      test('then pause() without awaiting loads the entry paused', () async {
        final player = await pausedQueue();
        final jumping = player.jump(2);
        final pausing = player.pause();
        await Future.wait([jumping, pausing]);
        await waitUntil(
          () async => await player.getRawProperty('playlist-pos') == '2',
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'yes');
        expect(player.state.playWhenReady, isFalse);
        expect(player.state.playing, isFalse);
      }, timeout: t);

      test('after an unawaited open() has the last word', () async {
        final player = await pausedQueue();
        final opening = player.open(Media(longFixture), play: false);
        final jumping = player.jump(0);
        await Future.wait([opening, jumping]);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'no');
        expect(player.state.playWhenReady, isTrue);
      }, timeout: t);

      test('out of range leaves the intent it found', () async {
        final player = await pausedQueue();
        await expectLater(player.jump(5), throwsRangeError);
        expect(player.state.playWhenReady, isFalse);
        expect(await player.getRawProperty('pause'), 'yes');
      }, timeout: t);
    });

    test('a failed open puts the intent back', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await player.open(Media(fixturePath), play: false);
      expect(player.state.playWhenReady, isFalse);

      await expectLater(
        player.open(const Media('asset://missing/nothing.wav'), play: true),
        throwsA(anything),
      );
      expect(player.state.playWhenReady, isFalse);
      await expectLater(
        player.openAll([
          Media(fixturePath),
          const Media('asset://missing/nothing.wav'),
        ], play: true),
        throwsA(anything),
      );
      expect(player.state.playWhenReady, isFalse);
      await expectLater(
        player.openPlaylistFile(
          const Media('asset://missing/list.m3u'),
          play: true,
        ),
        throwsA(anything),
      );
      expect(player.state.playWhenReady, isFalse);
    }, timeout: t);
  });
}
