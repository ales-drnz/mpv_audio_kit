// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// `playing` after a file follows another, driven through the slow-core
// shim. The player clears `playing` at every END_FILE, and mpv samples the
// observed `core-idle` once per playloop iteration: a file that starts in
// the same iteration (a prefetched gapless advance, about 1 time in 10
// between local files) reports no idle value in between. A reply held back
// in the event isolate across the change gives the same outcome every
// time: the isolate reads `core-idle` only once the next file plays, with
// the value it last forwarded.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final shortFixture = '$dir/sine_stereo_1s.flac';
  final longFixture = '$dir/sine_5s.flac';

  slowCoreShimSuite(fixturePath: longFixture, extraFixtures: [shortFixture], (
    shim,
  ) {
    late Player player;
    late List<MpvPlaybackState> states;
    late StreamSubscription<MpvPlaybackState> sub;

    setUp(() async {
      shim().reset();
      player = await buildPlayer();
      states = [];
      sub = player.stream.playbackState.listen(states.add);
    });

    tearDown(() async {
      shim().reset();
      await sub.cancel();
      await player.dispose();
    });

    /// Holds the event isolate behind the reply of a read for [hold], from
    /// a moment when the first entry plays, and runs [change] meanwhile.
    Future<void> changeWhileHeld(
      Duration hold, [
      Future<void> Function()? change,
    ]) async {
      await waitUntil(
        () => player.state.playing && player.state.playlist.index == 0,
        reason: 'the first entry never played',
      );
      shim().holdReply('mpv-version', hold);
      final read = player.getRawProperty('mpv-version');
      await waitUntil(
        () => shim().counter('replies_held') > 0,
        reason: 'the read reply was never held',
      );
      await change?.call();
      await read;
    }

    /// Waits until the second entry has played [at], well after the event
    /// isolate caught up, and checks that the player says it plays.
    Future<void> expectPlayingAt(Duration at) async {
      await waitUntil(
        () => player.state.playlist.index == 1 && player.state.position >= at,
        timeout: const Duration(seconds: 8),
        reason: 'playback never got into the second entry',
      );
      expect(
        player.state.playing,
        isTrue,
        reason:
            'the second entry plays at ${player.state.position}, '
            'completed ${player.state.completed}, '
            'buffering ${player.state.buffering}',
      );
      expect(states.last, MpvPlaybackState.playing, reason: '$states');
    }

    for (final prefetch in [true, false]) {
      test('an advance the isolate is behind on leaves playing true '
          '(prefetch: $prefetch)', () async {
        await player.setPrefetchPlaylist(prefetch);
        await player.openAll([
          Media(shortFixture),
          Media(longFixture),
        ], play: true);
        // The first entry ends about 0.6 s in, inside the hold.
        await changeWhileHeld(const Duration(milliseconds: 1500));
        await expectPlayingAt(const Duration(milliseconds: 2500));
      });
    }

    test('a jump the isolate is behind on leaves playing true', () async {
      await player.setPrefetchPlaylist(true);
      await player.openAll([
        Media(longFixture),
        Media(longFixture),
      ], play: true);
      await changeWhileHeld(
        const Duration(milliseconds: 1000),
        () => player.sendRawCommand(['playlist-next']),
      );
      await expectPlayingAt(const Duration(milliseconds: 2500));
    });
  });
}
