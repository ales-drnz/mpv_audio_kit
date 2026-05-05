// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Smoke test: passing a non-default `priority` to registerHook does
  // not throw and the registered hook still fires. Higher-priority
  // values let mpv dispatch this hook earlier when multiple consumers
  // register the same name; on a single-Player single-handler test
  // there's nothing to compare against, so we just verify the
  // registration completes and the hook event is delivered.
  setUpAll(() => initLibmpvOrSkip());

  test('registerHook(priority: 50) fires on file load and is continueable',
      () async {
    final fix = '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
    if (!File(fix).existsSync()) {
      markTestSkipped('Fixture missing: $fix');
      return;
    }

    final player = await buildPlayer();
    try {
      final fired = Completer<MpvHookEvent>();
      final sub = player.stream.hook.listen((e) {
        if (e.hook == Hook.load && !fired.isCompleted) fired.complete(e);
      });
      try {
        await player.registerHook(Hook.load, priority: 50);
        await player.open(Media(fix), play: false);
        final event = await fired.future.timeout(const Duration(seconds: 5));
        expect(event.hook, Hook.load);
        // continueHook must accept the id and unblock mpv. If priority
        // dispatch were broken, mpv would stall and the next play()
        // call would never resolve.
        await player.continueHook(event.id);
      } finally {
        await sub.cancel();
      }
    } finally {
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 15)));
}
