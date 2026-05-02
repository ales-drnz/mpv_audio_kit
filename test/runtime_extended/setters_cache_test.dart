// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('setCache end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('writes 5 backing properties atomically', () async {
      const cfg = CacheSettings(
        mode: Cache.yes,
        secs: Duration(seconds: 5),
        onDisk: true,
        pause: false,
        pauseWait: Duration(seconds: 2),
      );
      await player.setCache(cfg);
      expect(player.state.cache.mode, Cache.yes);
      expect(player.state.cache.secs, const Duration(seconds: 5));
      expect(player.state.cache.onDisk, isTrue);
      expect(player.state.cache.pause, isFalse);
      expect(player.state.cache.pauseWait, const Duration(seconds: 2));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
