// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;


import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  // ONE Player per file, by convention. Companion files in this
  // directory cover the rest of the dispose-contract surface:
  // - `dispose_setters_state_error_test.dart` — typed setters
  // - `dispose_escape_hatches_test.dart` — getRawProperty / etc.
  // The split exists because creating + disposing 2+ Players inside
  // a single test file pushes against the SIGSEGV-on-3rd-Player
  // quirk (CLAUDE.md).

  group('Dispose safety — idempotency', () {
    test('dispose() called twice is a no-op', () async {
      final player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      // Let the event isolate spawn fully before we tear it down — a
      // dispose that races the isolate's first `mpv_wait_event` lands
      // a non-graceful subprocess exit at flutter_test teardown.
      await Future.delayed(const Duration(milliseconds: 200));

      await player.dispose();
      // Second dispose: the implementation guards with
      // `if (_disposed) return;` at the top of dispose(). Must not
      // throw, must not crash.
      await player.dispose();
      // Wait for libmpv's background threads to fully wind down.
      await Future.delayed(const Duration(seconds: 1));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
