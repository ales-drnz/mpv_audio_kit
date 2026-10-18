// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Hook API end-to-end', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
      });

      tearDownAll(() async {
        // Stop + clear before dispose; on_load hooks can leave a demuxer
        // thread mid-flight that delays the dispose chain otherwise.
        await player.stop();
        await player.clearPlaylist();
        await player.dispose();
      });

      test('registerHook(on_load) fires on file load; continueHook unblocks '
          'mpv', () async {
        final hookEvents = <MpvHookEvent>[];
        final hookFiredCompleter = Completer<MpvHookEvent>();
        final sub = player.stream.hook.listen((event) {
          hookEvents.add(event);
          if (!hookFiredCompleter.isCompleted && event.hook == Hook.load) {
            hookFiredCompleter.complete(event);
          }
        });

        try {
          unawaited(player.registerHook(Hook.load));
          // Open a file — mpv should fire the on_load hook before opening
          // the demuxer. The hook stream emits MpvHookEvent with the
          // event id; we must call continueHook to unblock mpv.
          unawaited(player.open(Media(fixturePath), play: false));

          final event = await hookFiredCompleter.future.timeout(
            const Duration(seconds: 5),
          );
          expect(event.hook, Hook.load);
          expect(
            event.id,
            greaterThan(0),
            reason: 'hook events carry positive ids',
          );

          unawaited(player.continueHook(event.id));
        } finally {
          await sub.cancel();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('continueHook with an invalid id is a guarded no-op', () {
        // Negative / zero id is documented as ignored (the wrapper logs
        // a warning on internalLog but does not pass the bogus id to
        // mpv). Smoke: must not throw.
        unawaited(player.continueHook(0));
        unawaited(player.continueHook(-1));
      }, timeout: const Timeout(Duration(seconds: 5)));

      test('a hook with a timeout auto-continues when the consumer never '
          'calls continueHook', () async {
        // Edge case: the consumer registers a hook but never calls
        // continueHook (a buggy or deliberately silent listener). With
        // [registerHook]'s `timeout` argument the wrapper auto-continues
        // after the deadline so mpv doesn't hang forever waiting for the
        // hook to complete. This is the contract that lets a buggy
        // listener fail gracefully instead of freezing the player.
        //
        // The wait below is intentionally on `fileFormat` (file-load
        // confirmation) and not on `endFile` (which fires from the
        // previous file's replace, before the new load settles): the
        // test must NOT return while mpv is still in the middle of a
        // hook cycle, otherwise tearDownAll's `quit` arrives while a
        // hook is active and mpv's shutdown path stalls.
        final hookSub = player.stream.hook.listen((_) {
          // Deliberately empty — exercising the auto-timeout safety net.
        });

        try {
          // Anchor on `seekCompleted` (= MPV_EVENT_PLAYBACK_RESTART, fires
          // exactly once per `loadfile` after the demuxer has settled).
          // Anchoring on `fileFormat` here would race the broadcast-stream
          // dedup: the previous test in this group loaded the same fixture,
          // so `state.fileFormat` is already 'wav' and the next load emits
          // no new value to firstWhere on. seekCompleted fires
          // unconditionally per file load and is independent of property
          // dedup.
          final loaded = player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 5),
          );
          unawaited(
            player.registerHook(
              Hook.load,
              timeout: const Duration(milliseconds: 200),
            ),
          );
          unawaited(player.open(Media(fixturePath), play: false));
          await loaded;
        } finally {
          await hookSub.cancel();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('Hook ids', () {
      test('a continueHook that comes after the timeout leaves the next '
          'event of the hook parked', () async {
        final player = await buildPlayer();
        final events = StreamController<MpvHookEvent>();
        final queue = StreamIterator(events.stream);
        var loads = 0;
        final subs = [
          player.stream.hook.listen(events.add),
          player.stream.seekCompleted.listen((_) => loads++),
        ];
        MpvHookEvent? b;
        try {
          await player.registerHook(
            Hook.load,
            timeout: const Duration(milliseconds: 300),
          );
          // A: the listener sits on it past the deadline, so the library
          // continues it and the file loads.
          final aLoaded = player.stream.seekCompleted.first;
          unawaited(player.open(Media(fixturePath), play: false));
          expect(await queue.moveNext().timeout(_wait), isTrue);
          final a = queue.current;
          await aLoaded.timeout(_wait);

          // B: a deadline far away, so only a continue releases it.
          await player.registerHook(
            Hook.load,
            timeout: const Duration(seconds: 30),
          );
          unawaited(player.open(Media(fixturePath), play: false));
          expect(await queue.moveNext().timeout(_wait), isTrue);
          b = queue.current;

          // The late continue for A must not release B.
          await player.continueHook(a.id);
          await Future<void>.delayed(const Duration(seconds: 1));
          expect(
            loads,
            1,
            reason: 'B is still in its on_load: only its own id releases it',
          );
          await player.continueHook(b.id);
          await player.stream.seekCompleted.first.timeout(_wait);
        } finally {
          if (b != null) await player.continueHook(b.id);
          for (final sub in subs) {
            await sub.cancel();
          }
          await queue.cancel();
          await player.dispose();
        }
      }, timeout: const Timeout(Duration(seconds: 30)));
    });
  });
}

const _wait = Duration(seconds: 5);
