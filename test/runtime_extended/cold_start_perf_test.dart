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
  runtimeSuite(() {
    group('cold start perf', () {
      test('T1: Player() ctor returns under 50ms', () async {
        // The first Player of the process also pays for loading and
        // compiling code, which is not what this pins.
        await Player().dispose();
        // The median of several runs: a ctor that blocks is slow every
        // time, while a loaded machine (the full suite runs files in
        // parallel) only stretches some runs.
        final ctorUs = <int>[];
        for (var i = 0; i < 9; i++) {
          final sw = Stopwatch()..start();
          final player = Player();
          sw.stop();
          ctorUs.add(sw.elapsedMicroseconds);
          await player.dispose();
        }
        final median = ([...ctorUs]..sort())[ctorUs.length ~/ 2];
        // ignore: avoid_print
        print('[T1] Player() ctor took $ctorUs us, median $median us');
        expect(
          median,
          lessThan(50000),
          reason: 'Player() ctor blocked for a median ${median / 1000} ms',
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

      test('T4: no ctor in 5 cycles blocks for 250ms', () async {
        // A cap on every single run, loose enough for a loaded machine
        // (under 25 ms with every core busy) and still far below what an
        // audio output opened on the main isolate costs.
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
          lessThan(250),
          reason: 'max ctor over 5 cycles: $maxMs ms (all: $ctorTimes)',
        );
      });
    });
  });
}
