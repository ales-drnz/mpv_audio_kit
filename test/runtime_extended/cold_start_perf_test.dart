// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Pins the contract that `Player()` must NOT run heavy FFI on the
  // main isolate. Pre-refactor these all fail with the actual blocking
  // numbers; post-refactor they pass.
  setUpAll(() => initLibmpvOrSkip());

  group('cold start perf', () {
    test('T1: Player() ctor returns under 50ms', () async {
      final sw = Stopwatch()..start();
      final player = Player();
      sw.stop();
      final ctorUs = sw.elapsedMicroseconds;
      // ignore: avoid_print
      print('[T1] Player() ctor took ${ctorUs / 1000} ms');
      await player.dispose();
      expect(
        ctorUs,
        lessThan(50000),
        reason: 'Player() ctor blocked for ${ctorUs / 1000} ms',
      );
    });

    test('T2: main isolate processes timer ticks while a Player is being '
        'initialized', () async {
      int tickCount = 0;
      final timer = Timer.periodic(
        const Duration(milliseconds: 16),
        (_) => tickCount++,
      );
      final player = Player();
      await Future<void>.delayed(const Duration(milliseconds: 800));
      timer.cancel();
      await player.dispose();
      // 800 / 16 = 50 expected; 50% tolerance → ≥25.
      expect(
        tickCount,
        greaterThan(25),
        reason:
            'Main isolate fired only $tickCount ticks in 800ms — '
            'init blocked the event loop',
      );
    });

    test('T4: 5 cycles all stay under 50ms ctor', () async {
      final ctorTimes = <int>[];
      for (var i = 0; i < 5; i++) {
        final sw = Stopwatch()..start();
        final p = Player();
        sw.stop();
        ctorTimes.add(sw.elapsedMilliseconds);
        await p.dispose();
      }
      final maxMs = ctorTimes.reduce((a, b) => a > b ? a : b);
      // ignore: avoid_print
      print('[T4] ctor times across 5 cycles: $ctorTimes ms');
      expect(
        maxMs,
        lessThan(50),
        reason: 'max ctor over 5 cycles: $maxMs ms (all: $ctorTimes)',
      );
    });
  });
}
