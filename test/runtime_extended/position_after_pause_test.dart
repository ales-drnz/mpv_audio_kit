// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// The clock properties are throttled to ~30 Hz in the event isolate. A
/// value that falls inside the window is held and sent when it closes:
/// after a pause mpv sends no further `time-pos`, so a dropped last value
/// would leave `state.position` behind the real playhead for good.
void main() {
  final fx = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  runtimeSuite(fixturePath: fx, () {
    test('position settles on the paused playhead', () async {
      final player = await buildPlayerWithFixture(fixturePath: fx);
      addTearDown(player.dispose);

      for (var i = 0; i < 12; i++) {
        await player.seek(Duration.zero);
        await player.play();
        await waitUntil(() => player.state.playing);
        // Vary the pause point against the throttle window.
        await Future<void>.delayed(Duration(milliseconds: 150 + i * 7));
        await player.pause();
        await waitUntil(() => !player.state.playing);
        // mpv reports the paused playhead up to a few hundred ms later.
        final raw = double.parse((await player.getRawProperty('time-pos'))!);
        final rawUs = (raw * 1e6).round();
        await waitUntil(
          () => (player.state.position.inMicroseconds - rawUs).abs() <= 1000,
          timeout: const Duration(seconds: 2),
          reason:
              'run $i: state stuck at ${player.state.position.inMilliseconds} '
              'ms, mpv paused at ${rawUs ~/ 1000} ms',
        );
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
