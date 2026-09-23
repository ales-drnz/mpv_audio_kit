// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // L3 — `mpv_wait_event` is invoked with a BOUNDED timeout (debug `0.1` s,
  // product `1.0` s as of 0.3.4), not the old busy-poll. The bounded floor
  // exists so a Player left undisposed at process exit can't wedge
  // `WaitForIsolateShutdown` (the macOS Dock-Quit hang); the graceful dispose
  // path unblocks instantly via `mpv_wakeup`. Previously the event isolate
  // spun on a 50 ms timeout, waking ~20× / sec just to re-enter the syscall.
  //
  // The wakeup-counter seam (`Player.testInstrumented(wakeupCounterAddress: ...)`) lets
  // us pin the new behaviour deterministically: after the isolate has
  // settled into a quiescent state (no playback, no observed property
  // changes), the counter must stay essentially flat. Pre-fix this
  // would have ticked ~40× over a 2-second window; post-fix it stays
  // at single digits (one or two genuine internal mpv events at most).

  runtimeSuite(() {
    test('idle event isolate does not busy-poll mpv_wait_event '
        '(L3 wakeup-rate invariant)', () async {
      final counter = calloc<Int64>();
      try {
        final player = Player.testInstrumented(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
          wakeupCounterAddress: counter.address,
        );
        try {
          // Force the null AO so we don't touch real audio hardware
          // on host runners.
          await player.setRawProperty('ao', 'null');

          // Let the initial property-observation burst settle. The
          // ~70 default specs each fire one PROPERTY_CHANGE on
          // observe; we want the counter sample window AFTER that.
          await Future<void>.delayed(const Duration(seconds: 1));

          final beforeIdle = counter.value;
          const idleWindow = Duration(seconds: 2);
          await Future<void>.delayed(idleWindow);
          final afterIdle = counter.value;

          final wakeupsDuringIdle = afterIdle - beforeIdle;

          // Pre-0.1.2 (timeout = 0.05s): ~40 wakeups in 2s — busy-poll.
          // 0.1.2     (timeout = -1):     near zero — perfect at idle but
          //                               deadlocks Hot Restart / app Quit.
          // 0.1.3     (debug: 0.1s, product: -1): ~20 in 2s under debug,
          //                               near zero in product — but the
          //                               product `-1` still hung Quit.
          // 0.3.4     (debug: 0.1s, product: 1.0s): ~20 in 2s under
          //                               `flutter test` (debug build), ~2 in
          //                               2s in product. The bounded product
          //                               floor kills the Quit hang; the
          //                               threshold stays <30 to accommodate
          //                               the debug kill-checkpoint while still
          //                               catching the pre-0.1.2 busy-poll.
          expect(
            wakeupsDuringIdle,
            lessThan(30),
            reason:
                'event isolate must wake at most ~10 Hz in debug '
                '(kill-checkpoint for Hot Restart), or never in product. '
                'Got $wakeupsDuringIdle wakeups in ${idleWindow.inSeconds}s '
                'of idle, which is consistent with the pre-0.1.2 50 ms '
                'busy-poll pattern.',
          );
        } finally {
          await player.dispose();
        }
      } finally {
        calloc.free(counter);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
