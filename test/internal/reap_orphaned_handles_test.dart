// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/library_loader.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

void main() {
  // reapOrphanedHandles is the teardown for libmpv handles leaked across
  // a Hot-Restart (library_loader). The leak the user reported was caused by
  // a bare `quit`: it only requests shutdown — the core's worker threads
  // and audio output are freed ONLY when the handle is destroyed. The fix
  // is the two-phase reap pinned here: `quit` every handle first (so any
  // event isolate still parked in mpv_wait_event returns and unwinds), then
  // mpv_terminate_destroy every handle AFTER a delay (so the destroy never
  // races an isolate still inside the syscall). This is the host-testable
  // half; the real cross-VM thread-join needs a live hot restart.

  group('reapOrphanedHandles two-phase teardown', () {
    test(
      'quits ALL handles before destroying ANY (terminate, not bare quit)',
      () async {
        final spy = _SpyMpvLibrary();
        final h1 = Pointer<MpvHandle>.fromAddress(0xAAAA);
        final h2 = Pointer<MpvHandle>.fromAddress(0xBBBB);

        await reapOrphanedHandles(
          spy,
          [h1, h2],
          delay: Duration.zero,
          stopAnalysis: false,
        );

        // Phase 1 quits both, THEN phase 2 destroys both — proves the fix
        // both sends quit AND actually destroys (the old code only quit).
        expect(spy.events, [
          'quit:${h1.address}',
          'quit:${h2.address}',
          'terminate:${h1.address}',
          'terminate:${h2.address}',
        ]);
      },
    );

    test('destroy is deferred — not called before the delay elapses', () async {
      final spy = _SpyMpvLibrary();
      final h = Pointer<MpvHandle>.fromAddress(0xCAFE);

      // Start the reap but don't await it yet.
      final reaping = reapOrphanedHandles(
        spy,
        [h],
        delay: const Duration(milliseconds: 50),
        stopAnalysis: false,
      );

      // The quit ran synchronously up to the first await; the destroy is
      // still pending behind the delay.
      expect(spy.commandStringCalls, 1);
      expect(
        spy.terminateDestroyCalls,
        0,
        reason:
            'terminate_destroy must wait out the reap delay so it '
            'cannot race an isolate still inside mpv_wait_event',
      );

      await reaping;
      expect(
        spy.terminateDestroyCalls,
        1,
        reason: 'the handle must be destroyed once the delay elapses',
      );
    });

    test('a quit failure on one handle does not abort the others or the '
        'destroy pass', () async {
      final spy = _SpyMpvLibrary()..commandStringThrows = true;
      final h1 = Pointer<MpvHandle>.fromAddress(0x11);
      final h2 = Pointer<MpvHandle>.fromAddress(0x22);

      await reapOrphanedHandles(spy, [h1, h2], delay: Duration.zero);

      // Every command was attempted (best-effort, swallowed), and both
      // handles were still destroyed.
      expect(spy.commandStringCalls, 8);
      expect(spy.terminateDestroyCalls, 2);
    });

    // The waveform, the loudness scan and the analyzer taps are switched
    // process-wide in libmpv, and the previous VM never ran the dispose
    // that turns them off (F158). The loudness scan goes off first: the
    // waveform off restarts a running pass for a scan still on.
    test(
      'turns the analysis off before each quit, before any destroy',
      () async {
        final spy = _SpyMpvLibrary();
        final h1 = Pointer<MpvHandle>.fromAddress(0x31);
        final h2 = Pointer<MpvHandle>.fromAddress(0x32);

        final reaping = reapOrphanedHandles(spy, [
          h1,
          h2,
        ], delay: const Duration(milliseconds: 50));
        // All of it runs before the first await, so before the new VM's
        // first player can exist.
        List<String> phase1(Pointer<MpvHandle> h) => [
          'set loudness-scan-enabled no:${h.address}',
          'set waveform-enabled no:${h.address}',
          'set analyzer-taps "":${h.address}',
          'quit:${h.address}',
        ];
        expect(spy.events, [...phase1(h1), ...phase1(h2)]);

        await reaping;
        expect(spy.events.skip(8), [
          'terminate:${h1.address}',
          'terminate:${h2.address}',
        ]);
      },
    );

    test('without stopAnalysis only quits', () async {
      final spy = _SpyMpvLibrary();
      final h = Pointer<MpvHandle>.fromAddress(0x41);
      await reapOrphanedHandles(
        spy,
        [h],
        delay: Duration.zero,
        stopAnalysis: false,
      );
      expect(spy.events, ['quit:${h.address}', 'terminate:${h.address}']);
    });

    test('empty reference list is a no-op', () async {
      final spy = _SpyMpvLibrary();
      await reapOrphanedHandles(spy, [], delay: Duration.zero);
      expect(spy.events, isEmpty);
    });
  });
}

/// Stub [MpvLibrary] recording the ordered sequence of the two FFI calls
/// the reaper makes. Built via [MpvLibrary.uninitializedForTest] so any
/// stray call to another binding trips a [LateInitializationError].
class _SpyMpvLibrary extends MpvLibrary {
  _SpyMpvLibrary() : super.uninitializedForTest() {
    mpvCommandString = (handle, cmd) {
      commandStringCalls++;
      final c = cmd.cast<Utf8>().toDartString();
      events.add('$c:${handle.address}');
      if (commandStringThrows) {
        throw StateError('simulated FFI failure');
      }
      return 0;
    };
    mpvTerminateDestroy = (handle) {
      terminateDestroyCalls++;
      events.add('terminate:${handle.address}');
    };
  }

  final List<String> events = [];
  int commandStringCalls = 0;
  int terminateDestroyCalls = 0;
  bool commandStringThrows = false;
}
