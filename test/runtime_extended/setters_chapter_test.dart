// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final chapterPath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  final plainPath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: chapterPath, extraFixtures: [plainPath], () {
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
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(
          player.state.currentChapter,
          1,
          reason: 'observer roundtrip must not destabilise the value',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('setChapter out of range', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
        final chaptersReady = player.stream.chapters
            .firstWhere((c) => c.length == 3)
            .timeout(const Duration(seconds: 5));
        await openAndWaitForLoad(player, chapterPath);
        if (player.state.chapters.length != 3) await chaptersReady;
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test('throws instead of clamping', () async {
        // "Next chapter" past the last one.
        await expectLater(
          player.setChapter(3),
          throwsA(isA<MpvCommandException>()),
        );
        await expectLater(
          player.setChapter(-5),
          throwsA(isA<MpvCommandException>()),
        );
        expect(player.state.currentChapter, isNot(3));
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('setChapters on a file without chapters', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
        await openAndWaitForLoad(player, plainPath);
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test('mpv takes the markers, setChapter navigates them, and an empty '
          'list clears them', () async {
        expect(player.state.chapters, isEmpty);
        const chapters = [
          Chapter(time: Duration.zero, title: 'Intro'),
          Chapter(time: Duration(seconds: 3), title: 'Outro'),
        ];

        await player.setChapters(chapters);
        expect(player.state.chapters, chapters);
        final node = await player.getRawPropertyNode('chapter-list');
        expect(node, isA<List<Object?>>());
        final list = (node as List<Object?>).cast<Map<Object?, Object?>>();
        expect(list.map((c) => c['title']), ['Intro', 'Outro']);
        expect((list[1]['time'] as num).toDouble(), closeTo(3.0, 1e-3));

        await player.setChapter(1);
        await waitUntil(
          () async =>
              (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                  0) >=
              2.9,
          reason: 'setChapter(1) did not seek to the injected marker',
        );

        await player.setChapters(const []);
        expect(player.state.chapters, isEmpty);
        await waitUntil(
          () async => await player.getRawProperty('chapters') == '0',
          reason: 'an empty list must clear mpv\'s chapters',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('the state keeps the markers mpv took', () async {
        // A fresh load: after setChapter(1) above, a shorter list makes
        // libmpv r17 read chapter-metadata past its array (a crash).
        await openAndWaitForLoad(player, plainPath);
        const intro = Chapter(time: Duration.zero, title: 'Intro');
        await player.setChapters(const [intro]);
        // mpv drops a marker past the end of the 5 s file. What it keeps
        // equals its list before, so no change is reported after it.
        await player.setChapters(const [
          intro,
          Chapter(time: Duration(seconds: 20), title: 'Past the end'),
        ]);
        expect(await player.getRawProperty('chapters'), '1');
        expect(player.state.chapters, const [intro]);
        await player.setChapters(const []);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
