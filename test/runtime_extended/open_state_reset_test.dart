// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Per-track state must not leak between an [Player.open] call and the
/// arrival of `MPV_EVENT_FILE_LOADED` for the new file. UIs that read
/// `player.state.<X>` synchronously on track-change would otherwise
/// flash the previous track's cover / chapters / chapter index.
void main() {
  setUpAll(() => initLibmpvOrSkip(fixturePath: defaultFixturePath()));

  group('Player.open clears per-file state synchronously', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test(
      'cover art / chapters / currentChapter are blank between open() returning and FILE_LOADED',
      () async {
        final coverPath =
            '${Directory.current.path}/test/fixtures/sine_with_cover.flac';
        final chaptersPath =
            '${Directory.current.path}/test/fixtures/with_chapters.mka';
        if (!File(coverPath).existsSync() || !File(chaptersPath).existsSync()) {
          markTestSkipped('Cover / chapters fixture missing.');
          return;
        }

        // 1. Load the chapters fixture so state.chapters / currentChapter
        //    are populated by the registry. chapter-list is a NODE
        //    property that may arrive after seekCompleted, so wait on the
        //    stream rather than the lifecycle anchor.
        final chaptersReady = player.stream.chapters
            .firstWhere((c) => c.isNotEmpty)
            .timeout(const Duration(seconds: 10));
        await player.open(Media(chaptersPath), play: false);
        await chaptersReady;
        expect(
          player.state.chapters,
          isNotEmpty,
          reason:
              'pre-condition: chapters fixture must populate state.chapters',
        );

        // 2. Issue the next open() but do NOT await the file-loaded
        //    event. The state must already be blank by the time `open()`
        //    returns — the synchronous reset in `open()` is what
        //    guarantees a UI does not paint stale data.
        final coverLoaded = player.stream.coverArt
            .firstWhere((c) => c != null)
            .timeout(const Duration(seconds: 10));
        await player.open(Media(coverPath), play: false);

        // 3. Synchronous read — the new file's events have not arrived
        //    yet (the await above only resolves the FFI hand-off).
        expect(
          player.state.chapters,
          isEmpty,
          reason: 'chapters must be cleared by open()',
        );
        expect(
          player.state.currentChapter,
          isNull,
          reason: 'currentChapter must be cleared by open()',
        );
        expect(
          player.state.coverArt,
          isNull,
          reason: 'coverArt must be cleared by open()',
        );
        expect(
          player.state.position,
          Duration.zero,
          reason: 'position must be cleared by open()',
        );

        // 4. Eventually the cover-art for the new file arrives.
        await coverLoaded;
        expect(player.state.coverArt, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'state.chapters reflects the current file even when re-loading the same chapters fixture',
      () async {
        final chaptersPath =
            '${Directory.current.path}/test/fixtures/with_chapters.mka';
        if (!File(chaptersPath).existsSync()) {
          markTestSkipped('Chapters fixture missing.');
          return;
        }
        // Loading the SAME file twice in a row would normally trigger
        // mpv's observer dedup (`equal_mpv_value` on the chapter-list
        // node array), so PROPERTY_CHANGE would not fire on the second
        // load. The wrapper-side reset clears `state.chapters` to []
        // synchronously; without an explicit poll on FILE_LOADED, the
        // cell would stay empty forever. This test pins the poll path.
        await openAndWaitForLoad(player, chaptersPath);
        final firstSnapshot = List<Chapter>.from(player.state.chapters);
        expect(
          firstSnapshot,
          isNotEmpty,
          reason: 'fixture must populate chapters on first load',
        );

        // Second load of the identical file. mpv's observer would dedup
        // chapter-list because the value is structurally identical;
        // _pollChapterState in FILE_LOADED bypasses that dedup.
        await openAndWaitForLoad(player, chaptersPath);
        expect(
          player.state.chapters,
          equals(firstSnapshot),
          reason:
              'chapters must be re-populated by the FILE_LOADED poll '
              'even when mpv\'s observer dedups identical values',
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });
}
