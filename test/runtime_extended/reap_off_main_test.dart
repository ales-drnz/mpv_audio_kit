// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/library_loader.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

import '../_helpers/slow_core_shim.dart';

/// Stall injected in front of `mpv_terminate_destroy`, as in
/// dispose_destroy_off_main_test: the destroy of a core whose audio output
/// closes as slowly as it opened.
const int _destroyDelayUs = 600 * 1000;

/// Main-isolate heartbeat gaps above this fail the test: a destroy on the
/// main isolate costs at least [_destroyDelayUs].
const int _maxGapMs = 350;

/// The wait between the quit and the destroy of the reap.
const int _reapDelayMs = 500;

void main() {
  slowCoreShimSuite((shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // The Hot Restart reap destroyed the orphaned cores on the main
    // isolate, 500 ms after the restart, while the new VM's first frames
    // and players come up.
    test('the reap destroys an orphaned core off the main isolate, and '
        'completes once it is gone', () async {
      final lib = MpvLibrary.open(shim().path);
      final orphan = lib.mpvCreate();
      using((arena) {
        for (final (name, value) in [('ao', 'null'), ('idle', 'yes')]) {
          lib.mpvSetOptionString(
            orphan,
            name.toNativeUtf8(allocator: arena),
            value.toNativeUtf8(allocator: arena),
          );
        }
      });
      expect(lib.mpvInitialize(orphan), greaterThanOrEqualTo(0));
      shim().set('destroy_delay_us', _destroyDelayUs);

      // 1 ms heartbeat: a synchronous wait on the main isolate shows up as
      // one gap as long as the wait.
      final sw = Stopwatch()..start();
      var lastMs = 0;
      var maxGapMs = 0;
      final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
        final now = sw.elapsedMilliseconds;
        if (now - lastMs > maxGapMs) maxGapMs = now - lastMs;
        lastMs = now;
      });
      final Duration took;
      try {
        final start = sw.elapsed;
        await reapOrphanedHandles(lib, [
          orphan,
        ], stopAnalysis: false).timeout(const Duration(seconds: 20));
        took = sw.elapsed - start;
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } finally {
        timer.cancel();
      }

      // ignore: avoid_print
      print(
        '[reap] max main-isolate heartbeat gap: ${maxGapMs}ms, reap '
        '${took.inMilliseconds}ms (destroy stalled '
        '${_destroyDelayUs ~/ 1000}ms)',
      );
      expect(shim().counter('destroys'), 1, reason: 'the reap destroyed it');
      expect(
        took.inMilliseconds,
        greaterThanOrEqualTo(_reapDelayMs + _destroyDelayUs ~/ 1000),
        reason: 'the reap completes only once the core is destroyed',
      );
      expect(
        maxGapMs,
        lessThan(_maxGapMs),
        reason:
            'the main isolate froze for ${maxGapMs}ms in the reap: '
            'mpv_terminate_destroy still runs on it',
      );
    });
  });
}
