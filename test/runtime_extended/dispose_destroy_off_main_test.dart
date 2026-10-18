// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

/// Stall injected in front of `mpv_terminate_destroy`. Models the destroy
/// of a real core: a synchronous `quit`, the wait for every async reply,
/// the join of the core thread and the close of the audio output, which on
/// a Bluetooth or AirPlay device takes as long as its init.
const int _destroyDelayUs = 600 * 1000;

/// Main-isolate heartbeat gaps above this fail the test: a destroy on the
/// main isolate costs at least [_destroyDelayUs].
const int _maxGapMs = 350;

void main() {
  slowCoreShimSuite(fixturePath: defaultFixturePath(), (shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // F26: dispose called mpv_terminate_destroy on the main isolate, the
    // one synchronous core call left there.
    test('dispose destroys the core off the main isolate, and completes '
        'once it is gone', () async {
      final player = await buildPlayer();
      await player.setLoop(Loop.file);
      await player.open(Media(defaultFixturePath()), play: true);
      await player.stream.playing
          .firstWhere((playing) => playing)
          .timeout(const Duration(seconds: 10));
      final destroys = shim().counter('destroys');
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
        await player.dispose().timeout(const Duration(seconds: 20));
        took = sw.elapsed - start;
        // The tail of the last turn stays inside the window.
        await Future<void>.delayed(const Duration(milliseconds: 50));
      } finally {
        timer.cancel();
      }

      // ignore: avoid_print
      print(
        '[dispose] max main-isolate heartbeat gap: ${maxGapMs}ms, dispose '
        '${took.inMilliseconds}ms (destroy stalled '
        '${_destroyDelayUs ~/ 1000}ms)',
      );
      expect(
        shim().counter('destroys'),
        destroys + 1,
        reason: 'dispose destroyed the core',
      );
      expect(
        took.inMilliseconds,
        greaterThanOrEqualTo(_destroyDelayUs ~/ 1000),
        reason: 'dispose completes only once the core is destroyed',
      );
      expect(
        maxGapMs,
        lessThan(_maxGapMs),
        reason:
            'the main isolate froze for ${maxGapMs}ms in dispose: '
            'mpv_terminate_destroy still runs on it',
      );
    });
  });
}
