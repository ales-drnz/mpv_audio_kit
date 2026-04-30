// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  String? resolveLibmpv() {
    final root = Directory.current.path;
    if (Platform.isMacOS) {
      final p = '$root/macos/libs/libmpv.dylib';
      return File(p).existsSync() ? p : null;
    }
    if (Platform.isLinux) {
      final p = '$root/linux/libs/libmpv.so';
      return File(p).existsSync() ? p : null;
    }
    return null;
  }

  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Hook API end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
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
        if (!hookFiredCompleter.isCompleted &&
            event.name == 'on_load') {
          hookFiredCompleter.complete(event);
        }
      });

      try {
        player.registerHook('on_load');
        // Open a file — mpv should fire the on_load hook before opening
        // the demuxer. The hook stream emits MpvHookEvent with the
        // event id; we must call continueHook to unblock mpv.
        unawaited(player.open(Media(fixturePath), play: false));

        final event = await hookFiredCompleter.future
            .timeout(const Duration(seconds: 5));
        expect(event.name, 'on_load');
        expect(event.id, greaterThan(0),
            reason: 'mpv assigns positive ids to hook events');

        player.continueHook(event.id);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('continueHook with an invalid id is a guarded no-op', () async {
      // Negative / zero id is documented as ignored (the wrapper logs
      // a warning on internalLog but does not pass the bogus id to
      // mpv). Smoke: must not throw.
      player.continueHook(0);
      player.continueHook(-1);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test(
        'a hook with a timeout auto-continues when the consumer never '
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
        player.registerHook('on_load',
            timeout: const Duration(milliseconds: 200));
        unawaited(player.open(Media(fixturePath), play: false));

        // Wait for the new file to fully load (post-hook). When the
        // auto-timeout has continued every hook event, mpv proceeds
        // and we observe `fileFormat` flip to non-empty.
        await player.stream.fileFormat
            .firstWhere((fmt) => fmt.isNotEmpty)
            .timeout(const Duration(seconds: 5));
      } finally {
        await hookSub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
