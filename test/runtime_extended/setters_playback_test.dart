// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // Use the 3-second chapters fixture: long enough that seek tests can
  // assert past 400ms without racing mpv's EOF on a 1-second file.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Playback transport (play / pause / stop / seek) end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      // Stop + clear before dispose: the seek tests leave the player
      // mid-playback, and an active demuxer thread can stall the
      // dispose chain when many runtime_extended files run in parallel.
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    // Order matters: do seek tests FIRST, while the player is still
    // paused on a freshly-opened file. play / pause / stop tests
    // mutate transport state and run last; the dispose chain in
    // tearDownAll then operates on a quiesced player.

    test('seek absolute updates state.position', () async {
      // Subscribe BEFORE the setter so the broadcast emission isn't
      // missed. Anchor on the position observer rather than wall-clock:
      // mpv may settle slightly off the requested 1000ms target.
      final waitFor800 = player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 800)
          .timeout(const Duration(seconds: 3));
      await player.seek(const Duration(seconds: 1));
      await waitFor800;
      expect(player.state.position.inMilliseconds, greaterThan(800));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('seek relative offsets from the current position', () async {
      // Reset to 0 first: the previous seek-absolute test left position
      // at ~1000ms, and ReactiveProperty.position dedups same-value
      // updates — without this reset, the seek(1s) below would land on
      // an already-cached value and never emit.
      final waitForZero = player.stream.position
          .firstWhere((p) => p.inMilliseconds < 100)
          .timeout(const Duration(seconds: 3));
      await player.seek(Duration.zero);
      await waitForZero;

      // Anchor at 1.0s, then seek +1.0s relative → ~2.0s. Both legs
      // subscribe BEFORE the seek so the broadcast emission isn't
      // missed by a late subscription.
      final waitFor800 = player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 800)
          .timeout(const Duration(seconds: 3));
      await player.seek(const Duration(seconds: 1));
      await waitFor800;

      final waitFor1700 = player.stream.position
          .firstWhere((p) => p.inMilliseconds >= 1700)
          .timeout(const Duration(seconds: 3));
      await player.seek(const Duration(seconds: 1), relative: true);
      await waitFor1700;
      expect(player.state.position.inMilliseconds, greaterThan(1700));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('play / pause flip state.playing via the core-idle observer',
        () async {
      await player.play();
      await player.stream.playing
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 3));
      expect(player.state.playing, isTrue);

      await player.pause();
      await player.stream.playing
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 3));
      expect(player.state.playing, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('stop returns the player to an idle lifecycle', () async {
      // The previous test left state.playing == false (after pause), so
      // ReactiveProperty.playing dedups the false→false echo and no new
      // emission fires after stop(). We can't anchor on a stream value
      // change; the wait gives mpv time to process the stop command,
      // and we assert the post-stop state synchronously.
      await player.stop();
      await Future.delayed(const Duration(milliseconds: 300));
      expect(player.state.playing, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setAbLoopA / setAbLoopB round-trip Duration ↔ state', () async {
      // Re-open the fixture: stop() above unloaded the demuxer, and
      // ab-loop properties only stick once mpv has a live file. Anchor
      // on seekCompleted (PLAYBACK_RESTART) — duration may dedup at the
      // 3-second value cached from earlier tests in this group.
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: false);
      await loaded;

      // Pre-subscribe BEFORE the setter — the optimistic emit from
      // `_updateField` is synchronous, so a late firstWhere would miss
      // it and time out.
      Future<Duration?> nextA(bool Function(Duration?) pred) =>
          player.stream.abLoopA.firstWhere(pred).timeout(const Duration(seconds: 3));
      Future<Duration?> nextB(bool Function(Duration?) pred) =>
          player.stream.abLoopB.firstWhere(pred).timeout(const Duration(seconds: 3));

      final waitASet = nextA((d) => d?.inMilliseconds == 500);
      await player.setAbLoopA(const Duration(milliseconds: 500));
      await waitASet;
      expect(player.state.abLoopA, const Duration(milliseconds: 500));

      final waitBSet = nextB((d) => d?.inMilliseconds == 1500);
      await player.setAbLoopB(const Duration(milliseconds: 1500));
      await waitBSet;
      expect(player.state.abLoopB, const Duration(milliseconds: 1500));

      // Clearing with `null` writes mpv's "no" sentinel; the stream
      // emits `null` and state catches up.
      final waitAClear = nextA((d) => d == null);
      await player.setAbLoopA(null);
      await waitAClear;
      expect(player.state.abLoopA, isNull);

      final waitBClear = nextB((d) => d == null);
      await player.setAbLoopB(null);
      await waitBClear;
      expect(player.state.abLoopB, isNull);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
