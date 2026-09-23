// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as mpv;

import '../_helpers/libmpv_resolver.dart';

void main() {
  // Regression for the macOS Dock-Quit hang: an event isolate parked inside a
  // blocking `mpv_wait_event` can never reach a Dart safepoint, so at process
  // exit `WaitForIsolateShutdown` blocks forever (dart-lang/sdk#46680).
  //
  // This pins the FIX MECHANISM directly: the worker must exit via the native
  // stop flag + `mpv_wakeup` ALONE — WITHOUT a `quit` command and WITHOUT mpv
  // ever emitting `MPV_EVENT_SHUTDOWN`. Under the pre-fix design (timeout `-1`,
  // no `mpv_wakeup` binding, no native flag) this path could not unblock and
  // `stop()` would burn the full 2 s timeout with the worker still parked —
  // i.e. exactly the hang. Post-fix it unwinds in single-digit ms.
  test('event loop exits via stop-flag + mpv_wakeup alone '
      '(no quit / no MPV_EVENT_SHUTDOWN)', () async {
    final libPath = resolveLibmpv();
    if (libPath == null) {
      markTestSkipped('libmpv not bundled for this host');
      return;
    }
    final lib = mpv.MpvLibrary.open(libPath);
    final counter = calloc<Int64>();
    final iso = MpvEventIsolate();
    try {
      final handleAddr = await iso.start(
        libraryPath: libPath,
        preInitOptions: const {'ao': 'null', 'vo': 'null', 'idle': 'yes'},
        postInitOptions: const {},
        observes: const <MpvObserveSpec>[],
        wakeupCounterAddress: counter.address,
      );
      final handle = Pointer<mpv.MpvHandle>.fromAddress(handleAddr);

      // Let the worker settle into a parked mpv_wait_event.
      await Future<void>.delayed(const Duration(milliseconds: 400));

      // Drive teardown WITHOUT sending mpv `quit`: native flag + mpv_wakeup.
      final sw = Stopwatch()..start();
      iso.requestStop(lib, handle);
      final exited = await iso.stop();
      sw.stop();

      expect(
        exited,
        isTrue,
        reason: 'worker must confirm exit via flag + mpv_wakeup alone',
      );
      expect(
        sw.elapsedMilliseconds,
        lessThan(1000),
        reason:
            'wakeup-driven exit must be far under the 2s stop bound; a '
            'value near/over 2000ms means the worker stayed parked in '
            'mpv_wait_event — the pre-fix hang.',
      );

      // Prove the loop actually stopped (not merely that a Future resolved):
      // the wakeup counter must be flat across a post-exit window.
      final after = counter.value;
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        counter.value,
        after,
        reason: 'event loop kept running after stop() returned',
      );

      // No quit was sent, so tear the mpv core down explicitly.
      lib.mpvTerminateDestroy(handle);
    } finally {
      calloc.free(counter);
    }
  }, timeout: const Timeout(Duration(seconds: 20)));
}
