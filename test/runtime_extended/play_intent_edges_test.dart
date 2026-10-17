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
