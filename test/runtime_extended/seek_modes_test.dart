// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = defaultFixturePath();
  setUpAll(() => initLibmpvOrSkip(fixturePath: fx));

  test('seek(exact) / seekToPercent / revertSeek move the playhead', () async {
    final player = await buildPlayerWithFixture(fixturePath: fx);
    addTearDown(player.dispose);

    bool near(int ms, [int tol = 120]) =>
        (player.state.position.inMilliseconds - ms).abs() <= tol;
    // Poll the state snapshot (robust under load) until the seek lands.
    Future<void> waitNear(int ms) async {
      for (var i = 0; i < 100 && !near(ms); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(
        near(ms),
        isTrue,
        reason: 'expected ~${ms}ms, was ${player.state.position}',
      );
    }

    await player.seek(const Duration(milliseconds: 600), exact: true);
    await waitNear(600); // exact absolute seek

    // revert-seek undoes the seek session, returning to the pre-seek position.
    await player.revertSeek();
    await waitNear(0);

    await player.seekToPercent(25, exact: true);
    await waitNear(250); // 25% of the ~1s fixture
  }, timeout: const Timeout(Duration(seconds: 25)));
}
