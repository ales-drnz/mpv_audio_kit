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
          // with both entries and the first one current.
          await waitUntil(
            () =>
                player.state.playlist.items.length == 2 &&
                player.state.playlist.index == 0,
          );
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
          // PrefetchState is broken end-to-end.
          //
          // Skip if the loaded libmpv doesn't expose `prefetch-state` —
          // same pattern as the cover-art-mime smoke on iOS/Android.
          // Pre-subscribe so a fast prefetch.loading emit isn't missed.
          final emitted = player.stream.prefetchState
              .firstWhere((s) => s != PrefetchState.idle)
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
                PrefetchState.loading,
                PrefetchState.ready,
                PrefetchState.used,
                PrefetchState.failed,
              ]),
              reason:
                  'mpv must emit at least one non-idle prefetch state '
                  'while a 2-item playlist plays through with prefetch enabled',
            );
          } on TimeoutException {
            // Only a binary without the property may skip; with it, no
            // non-idle state is a regression.
            if (await player.getRawProperty('prefetch-state') == null) {
              skipMissing(
                'prefetch-state property is not exposed by the '
                'libmpv build loaded on this platform',
              );
              return;
            }
            rethrow;
          } finally {
            await player.setPrefetchPlaylist(false);
            await player.stop();
          }
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test('prefetchCacheDuration stream reports the prefetch and is never '
          'negative', () async {
        // `prefetch-cache-duration` reports how much of the next item the
        // background prefetch has buffered ahead (pairs with prefetch-state
        // for a determinate progress bar). A local file is prefetched
        // whole while the first entry plays, so mpv reports a positive
        // value before the transition: without one the property never
        // reached the stream (F131). The initial zero the stream replays
        // on subscribe proves nothing.
        final seen = <Duration>[];
        final sub = player.stream.prefetchCacheDuration.listen(seen.add);

        await player.setPrefetchPlaylist(true);
        await player.openAll([
          Media(fixturePath),
          Media(fixturePath),
        ], play: true);
        // The prefetch of the second entry runs while the first plays.
        await waitUntil(
          () => player.state.playlist.index == 1,
          timeout: const Duration(seconds: 10),
        );

        await sub.cancel();
        await player.setPrefetchPlaylist(false);
        await player.stop();

        expect(
          seen,
          anyElement(greaterThan(Duration.zero)),
          reason: 'the prefetched entry was never reported as buffered',
        );
        for (final d in seen) {
          expect(
            d,
            greaterThanOrEqualTo(Duration.zero),
            reason:
                'prefetch-cache-duration must never report a negative '
                'buffered-ahead duration',
          );
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
