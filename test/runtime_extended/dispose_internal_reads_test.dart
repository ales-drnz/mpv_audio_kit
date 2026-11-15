// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(fixturePath: defaultFixturePath(), () {
    // A call under way when dispose lands ends without effect and without
    // an error. The calls that read the core on their way (play, openAll)
    // read through the public getRawProperty, whose gate refuses a
    // disposed player: they threw PlayerDisposedException from the middle.
    test('play() and openAll() under way at dispose complete, as setVolume() '
        'does', () async {
      final player = await buildPlayer();
      await player.ready;
      final volume = player.setVolume(40);
      final play = player.play();
      final openAll = player.openAll([
        Media(defaultFixturePath()),
        Media(defaultFixturePath()),
      ]);
      final dispose = player.dispose();
      await expectLater(volume, completes);
      await expectLater(play, completes);
      await expectLater(openAll, completes);
      await dispose;
      // A call made after dispose is still refused.
      expect(player.play, throwsA(isA<PlayerDisposedException>()));
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
