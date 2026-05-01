// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('setCache end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(fixturePath), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 500)
          .timeout(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('writes 5 backing properties atomically', () async {
      const cfg = CacheConfig(
        mode: CacheMode.yes,
        secs: Duration(seconds: 5),
        onDisk: true,
        pause: false,
        pauseWait: Duration(seconds: 2),
      );
      await player.setCache(cfg);
      expect(player.state.cache.mode, CacheMode.yes);
      expect(player.state.cache.secs, const Duration(seconds: 5));
      expect(player.state.cache.onDisk, isTrue);
      expect(player.state.cache.pause, isFalse);
      expect(player.state.cache.pauseWait, const Duration(seconds: 2));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
