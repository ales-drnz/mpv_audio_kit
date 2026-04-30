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

  group('Player.openAll + setPrefetchPlaylist end-to-end', () {
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
      // Stop playback + clear playlist before disposing — without this,
      // a 2-item playlist can leave an mpv demuxer thread mid-prefetch
      // and the dispose await chain (mpv_terminate_destroy → isolate
      // exit → controller close) can hang past the test runner timeout.
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test(
        'openAll([m, m]) loads a 2-item playlist and updates state.playlist',
        () async {
      await player.openAll(
        [Media(fixturePath), Media(fixturePath)],
        play: false,
      );

      // Wait for the playlist observer event to populate state.playlist
      // with both entries.
      final playlist = await player.stream.playlist
          .firstWhere((p) => p.medias.length == 2)
          .timeout(const Duration(seconds: 5));
      expect(playlist.medias.length, 2);
      expect(playlist.index, 0);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('setPrefetchPlaylist(true) flips state.prefetchPlaylist', () async {
      // Default mirrors mpv's own default (false).
      expect(player.state.prefetchPlaylist, isFalse);

      await player.setPrefetchPlaylist(true);
      expect(player.state.prefetchPlaylist, isTrue);

      await player.setPrefetchPlaylist(false);
      expect(player.state.prefetchPlaylist, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
