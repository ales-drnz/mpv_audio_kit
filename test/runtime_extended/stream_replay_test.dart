// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// State streams give each subscriber the current value first; event
/// streams don't.
void main() {
  final fx = defaultFixturePath();

  runtimeSuite(fixturePath: fx, () {
    group('Stream replay', () {
      late Player player;

      setUp(() async {
        player = await buildPlayerWithFixture(fixturePath: fx);
      });

      tearDown(() => player.dispose());

      test('a state stream starts from the current value', () async {
        await player.setVolume(42);
        expect(await player.stream.volume.first, 42);
        expect(await player.stream.playlist.first, player.state.playlist);
      });

      test('skip(1) waits for the next change', () async {
        final next = player.stream.volume.skip(1).first;
        await player.setVolume(17);
        expect(await next, 17);
      });

      test(
        'every subscriber of playbackState gets the current value',
        () async {
          // Paused needs the duration, which can land after the load.
          await waitUntil(() => player.state.duration > Duration.zero);
          final first = await player.stream.playbackState.first;
          final second = await player.stream.playbackState.first;
          expect(first, MpvPlaybackState.paused);
          expect(second, first);
        },
      );

      test('coverArt replays the current cover', () async {
        expect(await player.stream.coverArt.first, player.state.coverArt);
      });

      test('an event stream does not replay', () async {
        final events = <void>[];
        final sub = player.stream.seekCompleted.listen(events.add);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sub.cancel();
        expect(events, isEmpty);
      });
    });
  });
}
