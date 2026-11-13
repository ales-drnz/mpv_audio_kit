// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

/// How long the event isolate stays inside one synchronous read: past the
/// 2 s dispose waits for its exit.
const int _stallUs = 4 * 1000 * 1000;

void main() {
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  slowCoreShimSuite(fixturePath: longFixture, (shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // An event isolate held in a read (an output that takes seconds to
    // open) outlasts the wait of dispose, which then leaves the core
    // alone. Nobody destroyed it afterwards: the core, its threads and
    // its output stayed for the life of the process.
    test('a core whose event isolate exits after the wait of dispose is '
        'destroyed once it exits', () async {
      final player = await buildPlayer();
      shim().set('stall_park_read_us', _stallUs);
      await openAndWaitForLoad(player, longFixture);
      await player.seek(const Duration(milliseconds: 4700));
      await player.play();
      await waitUntil(
        () => shim().counter('park_reads_stalled') > 0,
        timeout: const Duration(seconds: 10),
        reason: 'mpv never parked',
      );
      final destroys = shim().counter('destroys');

      final sw = Stopwatch()..start();
      await player.dispose().timeout(const Duration(seconds: 10));
      expect(
        sw.elapsed,
        lessThan(const Duration(milliseconds: 3500)),
        reason: 'dispose does not wait for the held isolate',
      );
      expect(
        shim().counter('destroys'),
        destroys,
        reason: 'no destroy under an isolate still inside libmpv',
      );

      await waitUntil(
        () => shim().counter('destroys') == destroys + 1,
        timeout: const Duration(seconds: 10),
        reason: 'the core was never destroyed after the isolate exited',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
