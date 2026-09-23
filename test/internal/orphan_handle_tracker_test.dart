// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// OrphanHandleTracker smoke — the tracker is a singleton keyed by the
// running pid + tmp file, and its full Hot-Restart cleanup flow can
// only be reproduced inside a real Flutter app between hot-restarts.
// This file exercises the API surface end-to-end **without** depending
// on the singleton being fresh: ensureInitialized + add(0xdeadbeef) +
// remove(0xdeadbeef) must complete without throwing, and the file at
// `<tmp>/mpv_audio_kit_refs_<pid>.txt` must exist after init.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:test/test.dart';

void main() {
  test('OrphanHandleTracker.ensureInitialized + add + remove smoke', () {
    var orphansSeenCalls = 0;
    OrphanHandleTracker.instance.ensureInitialized((orphans) {
      orphansSeenCalls += 1;
    });

    // The tmp file should exist after the first init — keyed by pid.
    final expected = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_audio_kit_refs_$pid.txt',
    );
    expect(
      expected.existsSync(),
      isTrue,
      reason: 'tracker writes a per-pid sentinel into systemTemp on init',
    );

    // add() and remove() of a fake handle pointer must not throw. The
    // tracker is a Future-chained queue internally, so the assertions
    // here only verify "no synchronous throw" — full state inspection
    // would need cross-VM hot-restart simulation, which `dart test`
    // can't reproduce.
    final fake = Pointer<MpvHandle>.fromAddress(0xdeadbeef);
    expect(() => OrphanHandleTracker.instance.add(fake), returnsNormally);
    expect(() => OrphanHandleTracker.instance.remove(fake), returnsNormally);

    // Calling ensureInitialized again is a no-op (singleton flag).
    OrphanHandleTracker.instance.ensureInitialized((_) {
      fail('the second ensureInitialized must NOT re-run the orphan callback');
    });

    // First call may have surfaced any orphans from a previous test run
    // (most often zero on a fresh tmp); we don't assert the exact count,
    // only that the callback shape works and the second call is suppressed.
    expect(orphansSeenCalls, lessThanOrEqualTo(1));
  });

  // The tracker stores its 64-bit cookie inline in an `IntPtr` — on a
  // 32-bit IntPtr host the high half would silently truncate, so the
  // tracker degrades to a no-op. This pins the assumption that today's
  // targeted desktop / mobile builds are all 64-bit.
  test('host has a 64-bit IntPtr — required by OrphanHandleTracker', () {
    expect(sizeOf<IntPtr>(), 8);
  });
}
