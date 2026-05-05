// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Companion to dispose_during_seek_test.dart: races dispose() against
  // an in-flight `open()` (i.e. while the demuxer thread is still
  // building the chain). The cooperative shutdown must complete within
  // the safety timeout (1 s comfortably) — pre-dispose race fixes
  // (Player.create() + _eventIsolateReady await) put this in the steady
  // millisecond range.
  setUpAll(() => initLibmpvOrSkip());

  test('dispose() while open() is in flight tears down within 1s', () async {
    final fix = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
    if (!File(fix).existsSync()) {
      markTestSkipped('Fixture missing: $fix');
      return;
    }

    final player = await buildPlayer();
    // Start the open without awaiting — the demuxer thread is now
    // actively loading.
    final loadFuture = player.open(Media(fix));

    // Give the load a few microseconds to actually begin. Without the
    // tiny delay the dispose may run before any FFI work has been
    // dispatched.
    await Future<void>.delayed(const Duration(milliseconds: 5));

    final stopwatch = Stopwatch()..start();
    await player.dispose().timeout(const Duration(seconds: 1));
    stopwatch.stop();

    expect(stopwatch.elapsed.inMilliseconds, lessThan(1000),
        reason: 'dispose() must complete in well under 1s when racing an '
            'in-flight open(). If this regresses, the cooperative SHUTDOWN '
            'path is no longer reaching the event isolate.');

    // The pending open's future may complete normally or throw; both
    // are valid outcomes. The important property is that dispose
    // returned cleanly above.
    try {
      await loadFuture;
    } catch (_) {
      // Either StateError (post-dispose) or no error — both acceptable.
    }
  }, timeout: const Timeout(Duration(seconds: 5)));
}
