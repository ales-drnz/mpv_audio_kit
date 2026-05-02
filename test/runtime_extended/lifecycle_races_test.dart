// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // Lifecycle races — calls that arrive in unexpected order or interleave
  // with in-flight commands. The wrapper has a single `_command` /
  // `_prop` channel into mpv, so on the Dart side these are serialized;
  // what we verify here is that mpv's own response to interleaved
  // `loadfile` / `seek` / `stop` doesn't leave the wrapper in an
  // inconsistent state.
  //
  // Single-Player, no explicit `dispose()` mid-test: respects the per-
  // file SIGSEGV guard documented in CLAUDE.md and lets all five tests
  // share one fixture-loaded player without rebuilding it.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Lifecycle races — order-of-operation invariants', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('pause() before any open() is a no-op (no crash)', () async {
      // Idle player has no file loaded — pause is meaningless. The
      // wrapper just writes `pause=yes` to mpv; mpv accepts it without
      // emitting any property change because there's nothing playing.
      await player.pause();
      expect(player.state.playing, isFalse);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('seek() before any open() is a no-op (no crash)', () async {
      // mpv silently ignores seek when no file is loaded. The wrapper
      // doesn't pre-validate because the state model is convergent —
      // the position observer simply never fires.
      await player.seek(const Duration(seconds: 5));
      expect(player.state.position, Duration.zero);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('open() while a previous seek is in flight settles on the new file',
        () async {
      // Open file A, seek to a known position, then race seek+open and
      // verify the playhead lands back near zero (the second open's
      // `loadfile replace` aborts the in-flight seek). Anchoring on
      // `position < 500ms` rather than `seekCompleted` because the
      // second `loadfile replace` may swallow the in-flight seek's
      // PLAYBACK_RESTART entirely — counting restarts would race;
      // observing the playhead is unambiguous.
      final firstLoad = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: false);
      await firstLoad;

      // Move the playhead away from zero so the post-race assertion
      // can distinguish "fresh load reset" from "never moved".
      final pastSeek = player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 1500)
          .timeout(const Duration(seconds: 5));
      await player.seek(const Duration(seconds: 2));
      await pastSeek;

      // Race: kick off seek without awaiting, then issue open() with
      // the loadfile-replace semantic. The replace aborts the seek and
      // resets the playhead.
      final backNearZero = player.stream.position
          .firstWhere((p) => p.inMilliseconds < 500)
          .timeout(const Duration(seconds: 10));
      // ignore: unawaited_futures
      player.seek(const Duration(seconds: 1));
      await player.open(Media(fixturePath), play: false);

      await backNearZero;
      expect(player.state.position.inMilliseconds, lessThan(500));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('stop() immediately followed by open() loads the new file', () async {
      // stop() unloads the demuxer; open() must successfully load again
      // without an explicit reset between the two. The contract is that
      // these can be issued back-to-back without await.
      await player.stop();
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: false);
      await loaded;
      expect(player.state.duration.inMilliseconds, greaterThan(2500),
          reason: 'with_chapters.mka has duration > 2.5s once demuxed');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('20 sequential open() cycles on the same Player remain stable',
        () async {
      // Stress the open path on a single long-lived Player: each
      // `loadfile replace` should abort the previous load and settle on
      // the new file. After 20 rapid cycles the state should match a
      // freshly opened file — not partially populated, not leaked.
      for (var i = 0; i < 20; i++) {
        final loaded = player.stream.seekCompleted.first
            .timeout(const Duration(seconds: 10));
        await player.open(Media(fixturePath), play: false);
        await loaded;
      }
      expect(player.state.duration.inMilliseconds, greaterThan(2500),
          reason: 'after 20 cycles, duration must still match the fixture');
      expect(player.state.audioParams.sampleRate, isNotNull,
          reason: 'audio-params must be populated after the final load');
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
