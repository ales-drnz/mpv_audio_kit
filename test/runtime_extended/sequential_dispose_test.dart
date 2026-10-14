// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Player has no finalizer: a Player dropped without dispose() keeps its
  // handle until the process exits (hot restart cleans it up through the
  // orphan handle tracker). What a test can check is that players created
  // and disposed one after another each tear down fully.
  runtimeSuite(() {
    test('players disposed one after another each tear down', () async {
      for (var i = 0; i < 5; i++) {
        final player = await buildPlayer();
        final volumeDone = player.stream.volume.drain<void>();
        await player.dispose().timeout(const Duration(seconds: 5));
        await volumeDone.timeout(
          const Duration(seconds: 1),
          onTimeout: () => fail('player $i left its streams open'),
        );
        await expectLater(
          player.setVolume(50),
          throwsA(isA<PlayerDisposedException>()),
          reason: 'player $i still takes calls after dispose',
        );
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
