// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// openAll appends a large album in one go. Awaited one by one, each
/// append made mpv report the whole playlist again: 5000 entries took
/// about 40 s on a desktop, 3000 about 15 s.
void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    test('openAll of 3000 entries', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      const n = 3000;
      final medias = [
        for (var i = 0; i < n; i++) Media(fixturePath, extras: {'i': i}),
      ];
      var emits = 0;
      final sub = player.stream.playlist.listen((_) => emits++);
      addTearDown(sub.cancel);

      final watch = Stopwatch()..start();
      await player.openAll(medias, play: false, index: n - 1);
      await waitUntil(
        () =>
            player.state.playlist.items.length == n &&
            player.state.playlist.index == n - 1,
      );
      watch.stop();

      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(emits, lessThan(200), reason: 'one playlist report per append');
      final items = player.state.playlist.items;
      for (var i = 0; i < n; i += 499) {
        expect(items[i].extras?['i'], i, reason: 'entry $i lost its Media');
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
