// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Reentrancy contract for the transport surface: a call issued AFTER
  // another call (in program order) must also win at the mpv command
  // channel. `open()` suspends on `resolveUri` + the TLS-bundle gate
  // before issuing its `(pause, loadfile)` pair, so a `stop()` issued
  // while an `open()` is in flight reaches mpv FIRST and the open's
  // `loadfile` lands AFTER it — silently restarting playback the caller
  // just stopped. This file pins the correct ordering: the later call
  // (`stop()`) must win; the superseded `open()` must not load anything.
  //
  // Single Player per file (CLAUDE.md convention).
  final fixturePath = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fixturePath, () {
    group('open()/stop() reentrancy — the later call wins', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
      });

      tearDownAll(() async {
        await player.stop();
        await player.dispose();
      });

      test('stop() issued while open() is in flight is final — '
          'playback must not restart', () async {
        // Pre-subscribe BEFORE acting (CLAUDE.md). The player is fresh —
        // no file has ever been loaded — so ANY PLAYBACK_RESTART from here
        // on means a `loadfile` reached mpv after this test started.
        final restarted = Completer<void>();
        final sub = player.stream.seekCompleted.listen((_) {
          if (!restarted.isCompleted) restarted.complete();
        });

        try {
          // Same synchronous turn: kick off open() WITHOUT awaiting it,
          // then stop(). Program order says stop() is the caller's final
          // word — nothing may be playing once both futures settle.
          final opening = player.open(Media(fixturePath), play: true);
          await player.stop();
          await opening;

          // Settling window: give mpv time to act on any `loadfile` that
          // (incorrectly) landed after the `stop`.
          final loadedAfterStop = await restarted.future
              .then((_) => true)
              .timeout(const Duration(seconds: 3), onTimeout: () => false);

          expect(
            loadedAfterStop,
            isFalse,
            reason:
                'the in-flight open() resumed after stop() and issued '
                'its loadfile anyway — playback restarted even though '
                'stop() was the last transport call in program order',
          );
          expect(
            player.state.playing,
            isFalse,
            reason:
                'stop() was the final call — nothing may be producing '
                'audio once both futures settle',
          );
          expect(
            player.state.playWhenReady,
            isFalse,
            reason:
                'stop() releases the play intent; the superseded open() '
                'must not re-arm it',
          );
        } finally {
          await sub.cancel();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
