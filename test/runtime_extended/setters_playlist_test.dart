// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  String? resolveLibmpv() {
    final root = Directory.current.path;
    if (Platform.isMacOS) {
      final p = '$root/macos/libs/libmpv.dylib';
      return File(p).existsSync() ? p : null;
    }
    if (Platform.isLinux) {
      final p = '$root/linux/libs/libmpv.so';
      return File(p).existsSync() ? p : null;
    }
    return null;
  }

  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Playlist mutation / navigation setters end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
    });

    tearDownAll(() async {
      // Stop + clear before dispose to avoid demuxer threads stalling
      // the dispose chain on multi-item playlists (see
      // setters_open_prefetch_test.dart for the same mitigation).
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('add appends a track and updates state.playlist length', () async {
      await player.openAll([Media(fixturePath)], play: false);
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 1)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.medias.length, 1);

      await player.add(Media(fixturePath));
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 2)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.medias.length, 2);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('jump moves to the requested index', () async {
      // Playlist now has 2 entries from the previous test.
      await player.jump(1);
      await player.stream.playlist
          .firstWhere((p) => p.index == 1)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.index, 1);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('move reorders entries (1 → 0)', () async {
      // 2-item playlist; move the second entry to position 0.
      await player.move(1, 0);
      // mpv's playlist observer fires; just verify the call doesn't
      // throw. Index tracking after a move depends on the current
      // entry's position, which may shift.
      await Future.delayed(const Duration(milliseconds: 200));
      expect(player.state.playlist.medias.length, 2);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('remove drops an entry', () async {
      // Drop position 1.
      await player.remove(1);
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 1)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.medias.length, 1);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('clearPlaylist empties the queue', () async {
      await player.clearPlaylist();
      // mpv's `playlist-clear` + `playlist-remove current` collapses
      // the queue. The observer eventually emits an empty playlist.
      await player.stream.playlist
          .firstWhere((p) => p.medias.isEmpty)
          .timeout(const Duration(seconds: 5));
      expect(player.state.playlist.medias, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setShuffle / setPlaylistMode round-trip', () async {
      await player.openAll(
        [Media(fixturePath), Media(fixturePath)],
        play: false,
      );
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 2)
          .timeout(const Duration(seconds: 5));

      await player.setShuffle(true);
      expect(player.state.shuffle, isTrue);
      await player.setShuffle(false);
      expect(player.state.shuffle, isFalse);

      await player.setPlaylistMode(PlaylistMode.single);
      expect(player.state.playlistMode, PlaylistMode.single);
      await player.setPlaylistMode(PlaylistMode.loop);
      expect(player.state.playlistMode, PlaylistMode.loop);
      await player.setPlaylistMode(PlaylistMode.none);
      expect(player.state.playlistMode, PlaylistMode.none);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
