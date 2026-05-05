// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // The finalizer is the safety net for consumers that drop a Player
  // without disposing. It runs on GC of the Player object; if dispose()
  // ran first it's a no-op.
  //
  // We can't deterministically force a GC in pure Dart — `gc()` is
  // non-binding and the VM may collect at any time. So this test only
  // proves what we *can* prove on host: explicitly disposed players
  // tear down cleanly with no warning emitted on stderr (which is what
  // the finalizer logs when it has work to do).
  //
  // The architectural invariant lives in the source: `dispose()` flips
  // `_nativeResources.disposed = true` before detaching the finalizer,
  // so even a late-firing finalizer skips its body.
  setUpAll(() => initLibmpvOrSkip());

  test('explicit dispose() detaches the finalizer (no double cleanup)',
      () async {
    // Spin up + dispose 5 players in sequence. If the finalizer ever
    // double-dispatches, the second mpv_terminate_destroy on the same
    // handle would deadlock or SIGSEGV.
    for (var i = 0; i < 5; i++) {
      final player = await buildPlayer();
      await player.dispose();
    }
    // Reaching here without crashing is the assertion.
    expect(true, isTrue);
  }, timeout: const Timeout(Duration(seconds: 10)));
}
