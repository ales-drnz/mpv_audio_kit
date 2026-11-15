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
  final dir = '${Directory.current.path}/test/fixtures';
  final chapterPath = '$dir/with_chapters.mka';
  final plainPath = '$dir/sine_5s.flac';

  runtimeSuite(fixturePath: chapterPath, extraFixtures: [plainPath], () {
    late Player player;

    setUp(() async => player = await buildPlayer());
    tearDown(() => player.dispose());

    // The state says "no chapter" as null: the observer and FILE_LOADED
    // map mpv's -1 to it. The setter wrote the -1 itself.
    test('setChapter(-1) shows no chapter as null, never as -1', () async {
      await openAndWaitForLoad(player, chapterPath);
      await player.pause();
      await player.setChapter(1);
      final seen = <int?>[];
      final sub = player.stream.currentChapter.listen(seen.add);
      await player.setChapter(-1);
      expect(player.state.playback.currentChapter, isNot(-1));
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await sub.cancel();
      expect(seen, isNot(contains(-1)));
    }, timeout: const Timeout(Duration(seconds: 20)));

    // The state kept the caller's own set: changed afterwards, it changed
    // the state without an event, and the same set passed again was equal
    // to itself, so the stream stayed silent.
    test('setAudioSpdif keeps a copy of the set', () async {
      final codecs = {Spdif.ac3};
      await player.setAudioSpdif(codecs);
      final seen = <Set<Spdif>>[];
      final sub = player.stream.audioSpdif.skip(1).listen(seen.add);
      codecs.add(Spdif.dts);
      expect(player.state.settings.audioSpdif, {Spdif.ac3});
      await player.setAudioSpdif(codecs);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();
      expect(player.state.settings.audioSpdif, {Spdif.ac3, Spdif.dts});
      expect(seen, [
        {Spdif.ac3, Spdif.dts},
      ]);
      expect(
        () => player.state.settings.audioSpdif.add(Spdif.eac3),
        throwsUnsupportedError,
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    // openAll reads the list across many awaits: one the app changed
    // meanwhile gave an error from the middle, or the wrong Media on an
    // entry.
    test('openAll loads the list as it was at the call', () async {
      final medias = [
        Media(plainPath, extras: const {'n': 0}),
        Media(plainPath, extras: const {'n': 1}),
        Media(plainPath, extras: const {'n': 2}),
      ];
      final opened = player.openAll(medias, play: false, index: 2);
      medias.clear();
      await opened;
      await waitUntil(
        () => player.state.playback.playlist.items.length == 3,
        reason: 'the playlist is ${player.state.playback.playlist}',
      );
      expect(
        [for (final m in player.state.playback.playlist.items) m.extras?['n']],
        [0, 1, 2],
      );
      await waitUntil(() => player.state.playback.playlist.index == 2);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
