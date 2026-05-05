// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Pins the side-effect of `setShuffle(true)`: the playlist contents
  // must actually reorder, not just the boolean flag flip. Pre-0.1.0
  // tests only asserted `state.shuffle == true` and missed the case
  // where mpv accepted the property but never issued the
  // `playlist-shuffle` command (or vice versa).
  setUpAll(() => initLibmpvOrSkip());

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
        markTestSkipped('Fixture missing: $f');
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

      // Now shuffle and capture the new order.
      final newPlaylistFuture = player.stream.playlist
          .firstWhere((p) =>
              p.items.length == fixtures.length &&
              p.items.map((m) => m.uri).toList().toString() !=
                  originalOrder.toString())
          .timeout(const Duration(seconds: 5),
              onTimeout: () => player.state.playlist);

      await player.setShuffle(true);
      await shuffleStateFuture;
      expect(player.state.shuffle, isTrue);

      // The order must change. With 5 distinct items, the probability
      // of the random shuffle producing the original order is 1/120 —
      // negligible in CI, and a deterministic-fail re-run is vanishingly
      // unlikely. If this ever flakes consistently, the wrapper isn't
      // calling playlist-shuffle.
      final reordered = await newPlaylistFuture;
      final shuffledOrder = reordered.items
          .map((m) => m.uri)
          .toList(growable: false);
      expect(shuffledOrder.length, originalOrder.length);
      expect(shuffledOrder.toSet(), originalOrder.toSet(),
          reason: 'shuffle must preserve the set of tracks, only the order '
              'should change');
      expect(shuffledOrder.toString(), isNot(originalOrder.toString()),
          reason: 'shuffle must change the playlist order — if this fails, '
              'setShuffle did not issue the playlist-shuffle command');
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
