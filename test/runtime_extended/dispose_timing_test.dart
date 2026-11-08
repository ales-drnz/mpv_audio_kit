// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Locks in the load-bearing invariant from `event_isolate.dart`'s
  // `_isolateEntry`: the `fromMain.close()` after `_runEventLoop`
  // returns lets the isolate VM tear down promptly. Without that
  // close, `MpvEventIsolate.stop()` waits the full 2 s timeout
  // (`_kIsolateExitTimeout`), which both adds latency to the dispose
  // chain and surfaces as a flutter_test "(tearDownAll) - did not
  // complete" cosmetic error on long-running test files.
  //
  // The threshold below is a budget, not a target: real exits are
  // ~100 ms in practice. Anything approaching 1 s would indicate the
  // isolate is hanging until the safety-net timeout, i.e. the
  // root-cause fix has regressed.

  runtimeSuite(() {
    test('20 consecutive Player.dispose() calls all return quickly', () async {
      // Stress the path: build + dispose 20 times. If the cooperative
      // exit ever falls into the 2 s timeout, the cumulative time will
      // dwarf the 20 × ~100 ms baseline (~2 s) and the assertion fires.
      final times = <int>[];
      for (var i = 0; i < 20; i++) {
        final p = await buildPlayerWithFixture();
        await p.ready;
        final sw = Stopwatch()..start();
        await p.dispose();
        sw.stop();
        times.add(sw.elapsedMilliseconds);
      }
      final avg = times.reduce((a, b) => a + b) / times.length;
      final max = times.reduce((a, b) => a > b ? a : b);
      expect(
        max,
        lessThan(1000),
        reason:
            'max dispose time across 20 cycles was $max ms (avg '
            '${avg.toStringAsFixed(1)} ms); a single cycle hitting the '
            '2 s timeout indicates the isolate is not exiting cleanly.',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
