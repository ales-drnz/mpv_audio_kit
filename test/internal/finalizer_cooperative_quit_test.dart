// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/player_finalizer.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

void main() {
  // When a Player is GC'd without dispose(), the finalizer reaps the
  // leaked core. It must send a cooperative `quit` first (so the live
  // event isolate, still inside mpv_wait_event on the same handle,
  // returns on MPV_EVENT_SHUTDOWN and unwinds) and must NOT free the
  // handle synchronously — destroying it while the isolate is still in
  // the syscall is the documented SIGSEGV pattern (CLAUDE.md, "dispose
  // teardown order"). The destroy is deferred (see reapOrphanedHandles).
  //
  // We can't deterministically force a real GC in pure Dart. Instead we
  // drive the finalizer body directly via the `finalizePlayerForTesting`
  // seam and inspect the FFI calls a spy library records.

  group('finalizer reaps the leaked core', () {
    test(
        'sends cooperative quit synchronously and defers terminate_destroy',
        () {
      final spy = _SpyMpvLibrary();
      final fakeHandle = Pointer<MpvHandle>.fromAddress(0xC0FFEE);
      final res = PlayerNativeResources(spy, fakeHandle);

      finalizePlayerForTesting(res);

      // The quit (phase 1) runs synchronously before the first await.
      expect(spy.commandStringCalls, 1,
          reason: 'finalizer should issue exactly one cooperative quit',);
      expect(spy.lastCommand, equals('quit'),
          reason: 'cooperative quit must be the literal "quit" command',);
      expect(spy.lastHandle?.address, equals(fakeHandle.address));
      // The destroy (phase 2) is deferred past the isolate's unwind, so
      // it has NOT happened by the time the synchronous finalizer returns.
      expect(spy.terminateDestroyCalls, 0,
          reason: 'finalizer must not free the handle synchronously — that '
              'would race the live event isolate still in mpv_wait_event',);
      expect(res.disposed, isTrue,
          reason: 'PlayerNativeResources.disposed must flip so a late '
              'second finalize() (after the GC late-fires) is a no-op',);
    });

    test('idempotent — already-disposed resource is a no-op', () {
      final spy = _SpyMpvLibrary();
      final res = PlayerNativeResources(
        spy,
        Pointer<MpvHandle>.fromAddress(0x1),
      )..disposed = true;

      finalizePlayerForTesting(res);

      expect(spy.commandStringCalls, 0);
      expect(spy.terminateDestroyCalls, 0);
    });

    test('a failure during reap still marks the resource disposed', () {
      final spy = _SpyMpvLibrary()..commandStringThrows = true;
      final res = PlayerNativeResources(
        spy,
        Pointer<MpvHandle>.fromAddress(0x2),
      );

      // Must not rethrow — the finalizer is the bottom of the stack
      // (no caller can recover from it), so it swallows and logs.
      finalizePlayerForTesting(res);

      expect(res.disposed, isTrue,
          reason: 'finalizer must mark the resource disposed even on '
              'cleanup failure, otherwise a retry on a stale handle '
              'could fire later',);
    });
  });
}

/// Stub [MpvLibrary] that records the two functions the reaper touches.
/// Constructed via the test-only [MpvLibrary.uninitializedForTest]
/// constructor; only the entries we actually call are assigned, so any
/// accidental call to a different FFI function trips a
/// [LateInitializationError] and surfaces immediately as a test failure.
class _SpyMpvLibrary extends MpvLibrary {
  _SpyMpvLibrary() : super.uninitializedForTest() {
    mpvCommandString = (handle, cmd) {
      commandStringCalls++;
      lastHandle = handle;
      lastCommand = cmd.cast<Utf8>().toDartString();
      if (commandStringThrows) {
        throw StateError('simulated FFI failure');
      }
      return 0;
    };
    mpvTerminateDestroy = (handle) {
      terminateDestroyCalls++;
    };
  }

  int commandStringCalls = 0;
  int terminateDestroyCalls = 0;
  Pointer<MpvHandle>? lastHandle;
  String? lastCommand;
  bool commandStringThrows = false;
}
