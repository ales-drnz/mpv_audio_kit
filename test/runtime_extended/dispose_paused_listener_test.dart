// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// dispose() with a subscription the app holds paused. A paused listener
// takes the done only when it resumes, so a teardown that waits for the
// close of its stream never ends: with a tap it never even sends the quit,
// and inside an `await for` over an event stream it deadlocks.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('dispose with a paused listener', () {
      test('of a filter tap', () async {
        final player = await buildPlayer();
        await player.setAudioEffects(const [EqualizerEffect()]);
        await openAndWaitForLoad(player, fixturePath);
        final sub = player.stream
            .tap(AudioFilter.equalizer, side: TapSide.post)
            .listen((_) {});
        await player.play();
        sub.pause();
        await player.dispose().timeout(const Duration(seconds: 5));
        await sub.cancel();
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('of a state stream', () async {
        final player = await buildPlayer();
        await openAndWaitForLoad(player, fixturePath);
        final sub = player.stream.position.listen((_) {})..pause();
        await player.dispose().timeout(const Duration(seconds: 5));
        await sub.cancel();
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('of an event stream, from an await for', () async {
        final player = await buildPlayer();
        // The loop body runs with the subscription paused.
        final opening = player
            .open(Media(fixturePath), play: false)
            .catchError((Object _) {});
        var disposed = false;
        await for (final _ in player.stream.seekCompleted) {
          await player.dispose().timeout(const Duration(seconds: 5));
          disposed = true;
          break;
        }
        await opening;
        expect(disposed, isTrue);
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}
