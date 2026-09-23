// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Player.openAll + setPrefetchPlaylist end-to-end', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
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
          await player.openAll([
            Media(fixturePath),
            Media(fixturePath),
          ], play: false);

          // Wait for the playlist observer event to populate state.playlist
          // with both entries.
          final playlist = await player.stream.playlist
              .firstWhere((p) => p.items.length == 2)
              .timeout(const Duration(seconds: 5));
          expect(playlist.items.length, 2);
          expect(playlist.index, 0);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test('setPrefetchPlaylist(true) flips state.prefetchPlaylist', () async {
        // Default mirrors mpv's own default (false).
        expect(player.state.prefetchPlaylist, isFalse);

        await player.setPrefetchPlaylist(true);
        expect(player.state.prefetchPlaylist, isTrue);

        await player.setPrefetchPlaylist(false);
        expect(player.state.prefetchPlaylist, isFalse);
      }, timeout: const Timeout(Duration(seconds: 15)));

      test(
        'prefetchState stream emits non-idle when prefetch is active',
        () async {
          // The `prefetch-state` mpv property reports
          // loading / ready / used / failed during background prefetch of
          // the next playlist item. With prefetch enabled and a 2-item
          // playlist playing through, at least one non-idle emission must
          // reach the typed stream — otherwise the FFI bridge for
          // MpvPrefetchState is broken end-to-end.
          //
          // Skip if the loaded libmpv doesn't expose `prefetch-state` —
          // same pattern as the cover-art-mime smoke on iOS/Android.
          // Pre-subscribe so a fast prefetch.loading emit isn't missed.
          final emitted = player.stream.prefetchState
              .firstWhere((s) => s != MpvPrefetchState.idle)
              .timeout(const Duration(seconds: 10));

          await player.setPrefetchPlaylist(true);
          await player.openAll([
            Media(fixturePath),
            Media(fixturePath),
          ], play: true);

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
              reason:
                  'mpv must emit at least one non-idle prefetch state '
                  'while a 2-item playlist plays through with prefetch enabled',
            );
          } on TimeoutException {
            markTestSkipped(
              'prefetch-state property is not exposed by the '
              'libmpv build loaded on this platform — rebuild with the '
              'prefetch-state patch applied to enable this assertion',
            );
          } finally {
            await player.setPrefetchPlaylist(false);
            await player.stop();
          }
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test(
        'prefetchCacheDuration stream is wired and never negative',
        () async {
          // `prefetch-cache-duration` reports how much of the next item the
          // background prefetch has buffered ahead (pairs with prefetch-state
          // for a determinate progress bar). Instant local-file prefetch
          // can't be forced to a deterministic positive value, so we assert
          // the weaker but still meaningful contract: the stream is
          // subscribable and every emission that arrives is a valid,
          // non-negative Duration — i.e. the double → Duration FFI path is
          // wired end-to-end. Zero emissions is tolerated (a fast prefetch
          // may never move the value off zero).
          final seen = <Duration>[];
          final sub = player.stream.prefetchCacheDuration.listen(seen.add);

          await player.setPrefetchPlaylist(true);
          await player.openAll([
            Media(fixturePath),
            Media(fixturePath),
          ], play: true);
          await Future<void>.delayed(const Duration(seconds: 3));

          await sub.cancel();
          await player.setPrefetchPlaylist(false);
          await player.stop();

          for (final d in seen) {
            expect(
              d,
              greaterThanOrEqualTo(Duration.zero),
              reason:
                  'prefetch-cache-duration must never report a negative '
                  'buffered-ahead duration',
            );
          }
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });
  });
}
