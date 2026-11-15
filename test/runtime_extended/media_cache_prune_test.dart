// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/player/player.dart' show debugMediaCacheKeys;

import '../_helpers/setter_test_helpers.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final shortFixture = '$dir/sine_50ms.wav';

  /// The fixture under another name each time: `fixtures/./././x.wav`.
  String alias(String fixture, int n) =>
      '$dir/${'./' * n}${fixture.split('/').last}';

  runtimeSuite(fixturePath: shortFixture, () {
    late Player player;

    setUp(() async => player = await buildPlayer());
    tearDown(() async {
      await player.setSourceResolver(null);
      await player.dispose();
    });

    // The player keeps the Media of each URL it loaded, to hand it back
    // with the playlist and to the source resolver. Only an open emptied
    // that cache.
    test('entries that left the playlist leave the Media cache', () async {
      await openAndWaitForLoad(player, shortFixture);
      for (var n = 1; n <= 20; n++) {
        await player.add(Media(alias(shortFixture, n), extras: {'n': n}));
        await player.remove(1);
      }
      await player.add(Media(alias(shortFixture, 21), extras: {'n': 21}));
      await waitUntil(
        () => player.state.playback.playlist.items.length == 2,
        reason: 'the playlist never listed the two entries',
      );
      await waitUntil(
        () => debugMediaCacheKeys(player).length <= 4,
        reason:
            'the cache keeps ${debugMediaCacheKeys(player).length} keys '
            'for 2 entries',
      );
      // The entries still there keep their Media.
      expect(player.state.playback.playlist.items[1].extras, {'n': 21});
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('a resolver that gives a new URL at each load does not grow the '
        'Media cache', () async {
      var calls = 0;
      await player.setSourceResolver((request) {
        calls++;
        return alias(shortFixture, calls);
      });
      await player.setLoop(Loop.playlist);
      await player.open(const Media('resolve://sine'), play: true);
      await waitUntil(
        () => calls >= 12,
        timeout: const Duration(seconds: 30),
        reason: 'the playlist never looped 12 times',
      );
      expect(
        debugMediaCacheKeys(player).length,
        lessThanOrEqualTo(4),
        reason: 'one key for each URL the resolver ever gave',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
