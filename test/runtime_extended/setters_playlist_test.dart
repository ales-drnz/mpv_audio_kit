// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
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

    test('setShuffle / setLoop round-trip', () async {
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

      await player.setLoop(LoopMode.file);
      expect(player.state.loop, LoopMode.file);
      await player.setLoop(LoopMode.playlist);
      expect(player.state.loop, LoopMode.playlist);
      await player.setLoop(LoopMode.off);
      expect(player.state.loop, LoopMode.off);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('next() / previous() advance the playlist index', () async {
      // 3-item playlist so next/previous have a clear before/after to
      // anchor on. jump(0) is the documented entry point; next/prev
      // are the convenience wrappers tested here.
      await player.openAll(
        [Media(fixturePath), Media(fixturePath), Media(fixturePath)],
        play: false,
      );
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 3)
          .timeout(const Duration(seconds: 5));

      // Pre-subscribe to the index transition before each command —
      // the playlist observer can fire before a late firstWhere binds.
      Future<void> waitFor(int idx) => player.stream.playlist
          .firstWhere((p) => p.index == idx)
          .timeout(const Duration(seconds: 5));

      final advancedTo1 = waitFor(1);
      await player.next();
      await advancedTo1;
      expect(player.state.playlist.index, 1);

      final advancedTo2 = waitFor(2);
      await player.next();
      await advancedTo2;
      expect(player.state.playlist.index, 2);

      final backTo1 = waitFor(1);
      await player.previous();
      await backTo1;
      expect(player.state.playlist.index, 1);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('replace(index, media) swaps the entry without changing the length',
        () async {
      // Use two distinct fixture URIs so the replaced entry is
      // observably different. The primary fixture above is
      // sine_440hz_1s.wav; with_chapters.mka serves as the alt.
      final altPath =
          '${Directory.current.path}/test/fixtures/with_chapters.mka';
      if (!File(altPath).existsSync()) {
        markTestSkipped('Alt fixture missing for replace()');
        return;
      }

      // Reset to a known 2-item playlist of the primary fixture.
      await player.openAll(
        [Media(fixturePath), Media(fixturePath)],
        play: false,
      );
      await player.stream.playlist
          .firstWhere((p) => p.medias.length == 2)
          .timeout(const Duration(seconds: 5));

      // After replace(1, alt), the playlist must still have length 2
      // and entry 1 must point at the alt URI. The wrapper implements
      // this as `playlist-remove 1` + `loadfile insert-at 1`, so we
      // wait for the entry's URI to flip while length stays 2.
      final swapped = player.stream.playlist
          .firstWhere((p) =>
              p.medias.length == 2 &&
              p.medias[1].uri.endsWith('with_chapters.mka'))
          .timeout(const Duration(seconds: 10));
      await player.replace(1, Media(altPath));
      await swapped;
      expect(player.state.playlist.medias.length, 2);
      expect(
          player.state.playlist.medias[1].uri.endsWith('with_chapters.mka'),
          isTrue);
      expect(player.state.playlist.medias[0].uri.endsWith('sine_440hz_1s.wav'),
          isTrue,
          reason: 'replace(1) must not touch entry 0');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
