// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Pins the side-effect of `setShuffle(true)`: the playlist contents
  // must actually reorder, not just the boolean flag flip. Pre-0.1.0
  // tests only asserted `state.shuffle == true` and missed the case
  // where mpv accepted the property but never issued the
  // `playlist-shuffle` command (or vice versa).
  runtimeSuite(() {
    test('setShuffle(true) actually reorders the playlist contents', () async {
      final dir = '${Directory.current.path}/test/fixtures';
      final fixtures = [
        '$dir/sine_440hz_1s.wav',
        '$dir/sine_50ms.wav',
        '$dir/sine_5s.flac',
        '$dir/sine_88200hz.flac',
        '$dir/with_chapters.mka',
      ];
      for (final f in fixtures) {
        if (!File(f).existsSync()) {
          skipMissing('Fixture missing: $f');
          return;
        }
      }

      final player = await buildPlayer();
      try {
        // Pre-subscribe so the shuffled playlist emit doesn't slip past.
        final shuffleStateFuture = player.stream.shuffle
            .firstWhere((b) => b == true)
            .timeout(const Duration(seconds: 5));
        final reorderedFuture = player.stream.playlist
            .firstWhere((p) => p.items.length == fixtures.length)
            .timeout(const Duration(seconds: 5));

        await player.openAll([for (final f in fixtures) Media(f)]);
        await reorderedFuture;
        final originalOrder = player.state.playlist.items
            .map((m) => m.uri)
            .toList(growable: false);

        List<String> order() => player.state.playlist.items
            .map((m) => m.uri)
            .toList(growable: false);

        /// Whether the order leaves [originalOrder] within 2 seconds.
        Future<bool> reordered() async {
          final deadline = DateTime.now().add(const Duration(seconds: 2));
          while (DateTime.now().isBefore(deadline)) {
            if (order().toString() != originalOrder.toString()) return true;
            await Future<void>.delayed(const Duration(milliseconds: 20));
          }
          return false;
        }

        await player.setShuffle(true);
        await shuffleStateFuture;
        expect(player.state.shuffle, isTrue);

        // The order must change. A random shuffle of 5 items gives the
        // original order back once in 120 runs (CI run 42047677582), so
        // it shuffles up to twice more: each setShuffle(true) sends
        // playlist-shuffle. A wrapper that never sends it still fails.
        var changed = await reordered();
        for (var i = 0; i < 2 && !changed; i++) {
          await player.setShuffle(true);
          changed = await reordered();
        }
        final shuffledOrder = order();
        expect(shuffledOrder.length, originalOrder.length);
        expect(
          shuffledOrder.toSet(),
          originalOrder.toSet(),
          reason:
              'shuffle must preserve the set of tracks, only the order '
              'should change',
        );
        expect(
          shuffledOrder.toString(),
          isNot(originalOrder.toString()),
          reason:
              'shuffle must change the playlist order — if this fails, '
              'setShuffle did not issue the playlist-shuffle command',
        );
      } finally {
        await player.dispose();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
