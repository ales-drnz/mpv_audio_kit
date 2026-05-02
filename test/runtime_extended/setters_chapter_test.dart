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
  final chapterPath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() => initLibmpvOrSkip(fixturePath: chapterPath));

  group('setChapter end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayer();
      // Pre-subscribe so the chapters emit isn't lost while open() runs.
      final chaptersReady = player.stream.chapters
          .firstWhere((c) => c.length == 3)
          .timeout(const Duration(seconds: 5));
      await openAndWaitForLoad(player, chapterPath);
      if (player.state.chapters.length != 3) await chaptersReady;
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('jumps to chapter index 1 (Verse) — optimistic update + observer '
        'confirmation', () async {
      expect(player.state.chapters.length, 3);

      await player.setChapter(1);
      // Optimistic state update is synchronous.
      expect(player.state.currentChapter, 1);

      // Allow the observer-driven roundtrip from mpv to land. The
      // ReactiveProperty dedups the second update if mpv echoes the
      // same int, so we cannot wait on a stream emission — but we can
      // verify the value remains stable after the roundtrip window.
      await Future.delayed(const Duration(milliseconds: 200));
      expect(player.state.currentChapter, 1,
          reason: 'observer roundtrip must not destabilise the value');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
