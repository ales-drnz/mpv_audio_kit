// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

// Regression tests for the dispose-during-bring-up lifecycle bugs.
//
// NOTE on the Single-Player-per-file convention (CLAUDE.md): these tests
// inherently create multiple Players sequentially in one file — the
// scenario under test IS "a Player that never finished bring-up was
// disposed; does the process (and the next Player) survive cleanly?".
// Sequential multi-Player usage is a deliberate, documented exception here.
//
// The three bugs covered (all in the dispose-during-init window):
//
// BUG A — `_bringUpInIsolate` (player_init.part.dart:33) early-returns
//   AFTER `_eventIsolate.start(...)` succeeded when `_disposed` flipped
//   during the await. `_lib` / `_handle` are never assigned and
//   `_bringUpCompleted` stays false, so `dispose()` takes the
//   `!_bringUpCompleted` branch and calls `_eventIsolate.stop()` WITHOUT
//   sending `quit` and WITHOUT `requestStop`. The worker isolate keeps
//   looping on `mpv_wait_event` forever (isolate + mpv core leak) and
//   `stop()` burns its full 2 s safety timeout.
//   Red signal: `Player(); await dispose()` takes ~2 s instead of ms.
//
// BUG B — a second concurrent `dispose()` call sees `_disposed == true`
//   (player.dart:811-814) and returns IMMEDIATELY while the first call is
//   still mid-teardown. Correct: the second caller's future completes only
//   when teardown is actually done.
//
// BUG C — a setter that passed `_checkNotDisposed()` and suspended on the
//   pending `_ready`, when dispose lands during init (Bug A path), resumes
//   after the early-returned bring-up and reads the unassigned
//   `late final _lib` → `LateInitializationError` instead of a proper
//   `StateError` (or clean completion).

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(fixturePath: defaultFixturePath(), () {
    test(
      'A1: dispose() immediately after Player() completes well below the '
      '2 s isolate-exit timeout and does not degrade the next Player',
      () async {
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );

        // Deliberately NO await between construction and dispose: `_disposed`
        // flips while `_bringUpInIsolate` is still awaiting
        // `_eventIsolate.start(...)`, so bring-up early-returns with the
        // worker isolate alive and `_bringUpCompleted == false`.
        final sw = Stopwatch()..start();
        await player.dispose();
        sw.stop();

        expect(
          sw.elapsedMilliseconds,
          lessThan(1500),
          reason:
              'dispose() during bring-up ran for ${sw.elapsedMilliseconds} '
              'ms — at/above the 2 s MpvEventIsolate.stop() safety timeout. '
              'The !_bringUpCompleted dispose branch is stopping the event '
              'isolate without `quit` + requestStop, so the worker never '
              'leaves mpv_wait_event (isolate + mpv core leak) and stop() '
              'only returns via its timeout.',
        );

        // Process-wide libmpv state must not be degraded by the early
        // dispose: a subsequent Player initializes and opens a fixture.
        final next = await buildPlayer();
        try {
          await openAndWaitForLoad(next, defaultFixturePath());
          // The duration property event can land a tick after PLAYBACK_RESTART
          // (the load anchor) under full-suite load — poll instead of reading
          // the state once.
          final deadline = DateTime.now().add(const Duration(seconds: 10));
          while (next.state.duration == Duration.zero &&
              DateTime.now().isBefore(deadline)) {
            await Future<void>.delayed(const Duration(milliseconds: 25));
          }
          expect(next.state.duration, greaterThan(Duration.zero));
        } finally {
          await next.dispose();
        }
      },
      timeout: const Timeout(Duration(seconds: 60)),
    );

    // A2 (leaked-isolate observation): there is no public-API surface that
    // exposes whether the event isolate is still alive — `MpvEventIsolate`
    // is internal and the worker has no externally visible side channel
    // once `dispose()` returned. The timing assertion in A1 is the primary
    // red signal for the leak (stop() returning only via its 2 s timeout
    // IS the observable consequence of the isolate never exiting), so the
    // direct "no isolate left running" sub-assertion is intentionally
    // omitted rather than faked.

    test('B: a second concurrent dispose() completes only after the first '
        'teardown has actually finished', () async {
      // A fully initialized player with an open file so teardown takes
      // measurable (asynchronous) time: quit command, pipelines,
      // cooperative isolate stop.
      final player = await buildPlayer();
      await openAndWaitForLoad(player, defaultFixturePath());

      final order = <String>[];
      final f1 = player.dispose().whenComplete(() => order.add('f1'));
      final f2 = player.dispose().whenComplete(() => order.add('f2'));

      await f2;
      expect(
        order,
        contains('f1'),
        reason:
            'the second dispose() future completed while the first '
            'dispose() was still mid-teardown (completion order so far: '
            '$order). A concurrent dispose() caller must not observe the '
            'player as torn down before it actually is — the early '
            '`if (_disposed) return;` returns immediately instead of '
            'awaiting the in-flight teardown.',
      );
      await f1;
    }, timeout: const Timeout(Duration(seconds: 60)));

    test('C: a setter suspended on _ready when dispose lands during init '
        'must not fail with LateInitializationError', () async {
      // Timing-sensitive: the setter must pass `_checkNotDisposed()` and
      // suspend on the pending `_ready` BEFORE dispose flips `_disposed`
      // during bring-up. Calling both inside the same microtask turn as
      // the constructor hits the window on attempt 0 in practice; the
      // retry loop with a small growing pre-dispose delay scans the
      // window defensively in case scheduling differs across hosts.
      const attempts = 10;
      for (var i = 0; i < attempts; i++) {
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );

        // Fire the setter WITHOUT awaiting: it passes _checkNotDisposed()
        // (not disposed yet) and parks on `await _ready`.
        Object? setterError;
        final setterFuture = player
            .setVolume(50)
            .catchError((Object e) => setterError = e);

        if (i > 0) {
          // Scan the bring-up window on later attempts.
          await Future<void>.delayed(Duration(milliseconds: i * 5));
        }

        final disposeFuture = player.dispose();
        await setterFuture;
        await disposeFuture;

        if (setterError != null) {
          final typeName = setterError.runtimeType.toString();
          final isLateInitError =
              typeName.contains('LateError') ||
              setterError.toString().contains('LateInitializationError');
          expect(
            isLateInitError,
            isFalse,
            reason:
                'attempt $i: setVolume() resumed after the dispose-'
                'aborted bring-up and read the unassigned `late final _lib` '
                '— it failed with $typeName ("$setterError") instead of a '
                'proper StateError or clean completion.',
          );
          // Anything else surfaced must be the documented contract.
          expect(
            setterError,
            isA<StateError>(),
            reason:
                'attempt $i: setter failed with unexpected error type '
                '$typeName ("$setterError"); the contract is clean '
                'completion or StateError.',
          );
        }
        // Clean completion is acceptable too — no assertion needed.
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
