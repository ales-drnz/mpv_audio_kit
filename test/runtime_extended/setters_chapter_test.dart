// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
final chapterPath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(chapterPath).existsSync()) {
      markTestSkipped('Chapter fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('setChapter end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(chapterPath), play: false);
      // Wait for chapters to populate (observer-driven, lands after
      // file-loaded event).
      await player.stream.chapters
          .firstWhere((c) => c.length == 3)
          .timeout(const Duration(seconds: 5));
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
