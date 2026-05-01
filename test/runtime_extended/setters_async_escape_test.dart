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

  group('Async escape hatches (getRawProperty / setRawProperty / sendRawCommand)',
      () {
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

    test(
        'getRawProperty / setRawProperty / sendRawCommand all return Future '
        'and round-trip through libmpv', () async {
      // setRawProperty returns Future<void> — reads correctly via
      // getRawProperty.
      await player.setRawProperty('volume', '42');
      final raw = await player.getRawProperty('volume');
      expect(raw, isNotNull);
      // mpv reports volume as a decimal string ("42.000000").
      expect(double.parse(raw!), 42.0);

      // sendRawCommand is fire-and-forget; verify it doesn't throw on a
      // valid command (`set` is a known-safe noop counterpart).
      await player.sendRawCommand(['set', 'volume', '50']);
      // Roundtrip back via getRawProperty.
      final after = await player.getRawProperty('volume');
      expect(double.parse(after!), 50.0);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
