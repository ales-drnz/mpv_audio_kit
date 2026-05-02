// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_with_cover.flac';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('setImageDisplayDuration end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('finite Duration round-trips into state.imageDisplayDuration',
        () async {
      await player.setImageDisplayDuration(const Duration(seconds: 5));
      expect(player.state.imageDisplayDuration, const Duration(seconds: 5));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('null encodes mpv\'s `inf` (frame held indefinitely)', () async {
      // Set a finite value first so we can verify the null-write
      // actually transitions the state.
      await player.setImageDisplayDuration(const Duration(seconds: 2));
      expect(player.state.imageDisplayDuration, const Duration(seconds: 2));

      await player.setImageDisplayDuration(null);
      expect(player.state.imageDisplayDuration, isNull,
          reason: 'null is the typed representation of mpv `inf`');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('Duration.zero is a valid finite value (drop frame immediately)',
        () async {
      await player.setImageDisplayDuration(Duration.zero);
      expect(player.state.imageDisplayDuration, Duration.zero);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
