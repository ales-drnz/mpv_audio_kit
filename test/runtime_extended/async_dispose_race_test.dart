// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
@Timeout(Duration(minutes: 2))
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Regressions for the async-transport teardown races surfaced by the 0.4.0
/// review. Each would manifest as a use-after-free SIGSEGV (test-process
/// crash) under the old code; reaching the assertions proves the handle is
/// never dereferenced after `mpv_terminate_destroy`.
void main() {
  runtimeSuite(fixturePath: defaultFixturePath(), () {
    test('uaf-1: a multi-write setter in flight when dispose() runs never issues '
        'FFI on the freed handle', () async {
      // setReplayGain issues four sequential async writes. Firing it un-awaited
      // and disposing immediately suspends it mid-sequence; dispose drains the
      // pending replies, which resumes the setter — its remaining writes must
      // hit the `_ffiClosed` guard, not `mpv_*_async` on the destroyed handle.
      for (var i = 0; i < 6; i++) {
        final player = await buildPlayer();
        await openAndWaitForLoad(player, defaultFixturePath());
        final setFuture = player
            .setReplayGain(const ReplayGainSettings(mode: ReplayGain.track))
            .catchError((_) {});
        final disposeFuture = player.dispose();
        await Future.wait([setFuture, disposeFuture]);
      }
      expect(true, isTrue, reason: 'survived 6 setReplayGain-vs-dispose races');
    });

    test(
      'hooks-1: a registerHook running in its throwaway isolate when dispose() '
      'runs never dereferences the freed handle',
      () async {
        // registerHook runs mpv_hook_add in an Isolate.run against the shared
        // handle. Firing it un-awaited and disposing must await the in-flight
        // run before mpv_terminate_destroy frees the handle.
        for (var i = 0; i < 6; i++) {
          final player = await buildPlayer();
          await openAndWaitForLoad(player, defaultFixturePath());
          final hookFuture = player.registerHook(Hook.load).catchError((_) {});
          final disposeFuture = player.dispose();
          await Future.wait([hookFuture, disposeFuture]);
        }
        expect(
          true,
          isTrue,
          reason: 'survived 6 registerHook-vs-dispose races',
        );
      },
    );

    test('settle-1: replace() racing stop() does not restart playback past the '
        'stop', () async {
      final fixture = defaultFixturePath();
      final player = await buildPlayer();
      try {
        await player.openAll([Media(fixture), Media(fixture)], play: false);
        // Wait for the first entry to settle so replace() sees a current pos.
        await player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );

        // Race: replace the currently-playing entry while stopping. stop() bumps
        // the load epoch; replace()'s post-resolve commands (insert / next-force
        // / remove) must observe the superseding epoch and bail instead of
        // issuing `playlist-next force`, which would restart playback.
        final replaceFuture = player
            .replace(0, Media(fixture))
            .catchError((_) {});
        await player.stop();
        await replaceFuture;
        // Let any (incorrectly) surviving replace commands land.
        await Future<void>.delayed(const Duration(milliseconds: 300));

        expect(
          player.state.playWhenReady,
          isFalse,
          reason:
              'stop() settled the intent to not-playing; a replace that '
              'leaked its playlist-next force past the stop would have '
              'restarted playback',
        );
      } finally {
        await player.dispose();
      }
    });
  });
}
