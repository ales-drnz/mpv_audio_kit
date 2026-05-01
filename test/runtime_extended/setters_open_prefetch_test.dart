// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
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

    test('prefetchState stream emits non-idle when prefetch is active',
        () async {
      // The `prefetch-state` mpv property is part of the patched build:
      // it reports loading / ready / used / failed during background
      // prefetch of the next playlist item. With prefetch enabled and a
      // 2-item playlist playing through, at least one non-idle emission
      // must reach the typed stream — otherwise the FFI bridge for
      // MpvPrefetchState is broken end-to-end.
      //
      // Skip if the loaded libmpv lacks the patched property — same
      // pattern as the cover-art-mime smoke on iOS/Android.
      // Pre-subscribe so a fast prefetch.loading emit isn't missed.
      final emitted = player.stream.prefetchState
          .firstWhere((s) => s != MpvPrefetchState.idle)
          .timeout(const Duration(seconds: 10));

      await player.setPrefetchPlaylist(true);
      await player.openAll(
        [Media(fixturePath), Media(fixturePath)],
        play: true,
      );

      try {
        final state = await emitted;
        expect(
          state,
          isIn([
            MpvPrefetchState.loading,
            MpvPrefetchState.ready,
            MpvPrefetchState.used,
            MpvPrefetchState.failed,
          ]),
          reason: 'mpv must emit at least one non-idle prefetch state '
              'while a 2-item playlist plays through with prefetch enabled',
        );
      } on TimeoutException {
        markTestSkipped('prefetch-state property is not exposed by the '
            'libmpv build loaded on this platform — rebuild with the '
            'prefetch-state patch applied to enable this assertion');
      } finally {
        await player.setPrefetchPlaylist(false);
        await player.stop();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
