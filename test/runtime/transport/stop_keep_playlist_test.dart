// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../_helpers/setter_test_helpers.dart';

/// `stop(keepPlaylist: true)` unloads the file and keeps the queue; the
/// next play() starts the entry that stopped, from its beginning.
void main() {
  final fixturePath = defaultFixturePath();
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    const t = Timeout(Duration(seconds: 30));

    Future<Player> playingSecondOfThree() async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await player.openAll(
        [
          Media(longFixture),
          Media(longFixture, extras: const {'n': 2}),
          Media(longFixture, extras: const {'n': 3}),
        ],
        index: 1,
        play: true,
      );
      await waitUntil(
        () =>
            player.state.playback.playing &&
            player.state.playback.position > const Duration(milliseconds: 500),
      );
      return player;
    }

    test('keeps the entries and the index of the one stopped', () async {
      final player = await playingSecondOfThree();
      await player.stop(keepPlaylist: true);
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      final playlist = player.state.playback.playlist;
      expect(playlist.items, hasLength(3));
      expect(playlist.index, 1);
      expect(playlist.current?.extras, {'n': 2});
      expect(await player.getRawProperty('playlist-pos'), '-1');
      expect(player.state.playback.playWhenReady, isFalse);
      expect(await player.getRawProperty('playlist-count'), '3');
    }, timeout: t);

    test('play() starts the entry that stopped from its start', () async {
      final player = await playingSecondOfThree();
      await player.stop(keepPlaylist: true);
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      await player.play();
      expect(player.state.playback.playWhenReady, isTrue);
      await waitUntil(
        () =>
            player.state.playback.playing &&
            player.state.playback.playlist.index == 1,
      );
      expect(
        player.state.playback.position,
        lessThan(const Duration(milliseconds: 1500)),
      );
      expect(player.state.playback.playlist.current?.extras, {'n': 2});
    }, timeout: t);

    test('a pause() right after the play() keeps the entry', () async {
      final player = await playingSecondOfThree();
      await player.stop(keepPlaylist: true);
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      final playing = player.play();
      await player.pause();
      await playing;
      expect(player.state.playback.playWhenReady, isFalse);
      expect(await player.getRawProperty('idle-active'), 'yes');
      // The next play() still starts the entry that stopped.
      await player.play();
      await waitUntil(
        () =>
            player.state.playback.playing &&
            player.state.playback.playlist.index == 1,
      );
    }, timeout: t);

    test('the default stop still clears the playlist', () async {
      final player = await playingSecondOfThree();
      await player.stop();
      await waitUntil(() => player.state.playback.playlist.items.isEmpty);
      await player.play();
      expect(player.state.playback.playWhenReady, isFalse);
    }, timeout: t);

    test('a load after the kept stop wins over the resume', () async {
      final player = await playingSecondOfThree();
      await player.stop(keepPlaylist: true);
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      await player.jump(2);
      await waitUntil(() => player.state.playback.playlist.index == 2);
      await player.pause();
      await player.play();
      await waitUntil(() => player.state.playback.playing);
      expect(player.state.playback.playlist.index, 2);
    }, timeout: t);

    test('an entry removed after the kept stop leaves play() idle', () async {
      final player = await playingSecondOfThree();
      await player.stop(keepPlaylist: true);
      await waitUntil(
        () async => await player.getRawProperty('idle-active') == 'yes',
      );
      await player.remove(1);
      await waitUntil(() => player.state.playback.playlist.items.length == 2);
      await player.play();
      expect(player.state.playback.playWhenReady, isFalse);
      expect(await player.getRawProperty('idle-active'), 'yes');
    }, timeout: t);
  });
}
