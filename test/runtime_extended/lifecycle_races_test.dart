// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

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

    test(
      'seek() before any open() throws MpvException and leaves state clean',
      () async {
        // mpv rejects seek when no file is loaded; the typed seek surfaces
        // that as MpvException (same contract as sendRawCommand) instead of
        // silently reporting success for a command that did nothing.
        await expectLater(
          player.seek(const Duration(seconds: 5)),
          throwsA(isA<MpvException>()),
        );
        expect(player.state.position, Duration.zero);
      },
      timeout: const Timeout(Duration(seconds: 5)),
    );

    test(
      'open() while a previous seek is in flight settles on the new file',
      () async {
        // Open file A, seek to a known position, then race seek+open and
        // verify the playhead SETTLES back near zero on the new file.
        final firstLoad = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.open(Media(fixturePath), play: false);
        await firstLoad;

        // Move the playhead away from zero so the post-race assertion
        // can distinguish "fresh load reset" from "never moved".
        final pastSeek = player.stream.position
            .firstWhere((p) => p.inMilliseconds >= 1500)
            .timeout(const Duration(seconds: 5));
        await player.seek(const Duration(seconds: 2));
        await pastSeek;

        // Race: kick off a seek without awaiting, then issue open() with the
        // loadfile-replace semantic. `open()` calls `_settleWrites()` before its
        // loadfile, so the in-flight seek is honored on the OLD file first (the
        // playhead jumps to ~1s) and only THEN does FILE_LOADED reset it to the
        // new file's start. We pin the WHOLE observable sequence — the seek
        // executes (≈1s seen) AND the playhead settles back near zero — rather
        // than only the endpoint, which alone settles at 0 regardless.
        final seen = <int>[];
        final posSub = player.stream.position.listen(
          (p) => seen.add(p.inMilliseconds),
        );
        // ignore: unawaited_futures
        player.seek(const Duration(seconds: 1));
        await player.open(Media(fixturePath), play: false);

        // Give the in-flight seek and then the replace's FILE_LOADED time to
        // land, then assert the settled playhead is at the new file's start —
        // not at the seek's ~1s target (which would mean the seek "won").
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await posSub.cancel();
        expect(
          player.state.position.inMilliseconds,
          lessThan(500),
          reason:
              'the loadfile-replace must settle the playhead at the new '
              "file's start, not leave it at the in-flight seek target",
        );
        // The seek must have actually executed on the old file — proof it was
        // not silently coalesced away by the following loadfile.
        expect(
          seen.any((ms) => ms >= 700 && ms <= 1300),
          isTrue,
          reason:
              'the in-flight seek must reach its ~1s target on the old '
              'file before the replace resets the playhead (settle-then-load '
              'ordering); observed positions: $seen',
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('stop() immediately followed by open() loads the new file', () async {
      // stop() unloads the demuxer; open() must successfully load again
      // without an explicit reset between the two. The contract is that
      // these can be issued back-to-back without await.
      await player.stop();
      final loaded = player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
      await player.open(Media(fixturePath), play: false);
      await loaded;
      expect(
        player.state.duration.inMilliseconds,
        greaterThan(2500),
        reason: 'with_chapters.mka has duration > 2.5s once demuxed',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
      '20 sequential open() cycles on the same Player remain stable',
      () async {
        // Stress the open path on a single long-lived Player: each
        // `loadfile replace` should abort the previous load and settle on
        // the new file. After 20 rapid cycles the state should match a
        // freshly opened file — not partially populated, not leaked.
        for (var i = 0; i < 20; i++) {
          final loaded = player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 10),
          );
          await player.open(Media(fixturePath), play: false);
          await loaded;
        }
        expect(
          player.state.duration.inMilliseconds,
          greaterThan(2500),
          reason: 'after 20 cycles, duration must still match the fixture',
        );
        expect(
          player.state.audioParams.sampleRate,
          isNotNull,
          reason: 'audio-params must be populated after the final load',
        );
      },
      timeout: const Timeout(Duration(seconds: 120)),
    );
  });
}
