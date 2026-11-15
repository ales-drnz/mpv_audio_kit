// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  slowCoreShimSuite((shim) {
    setUp(() => shim().reset());
    tearDown(() => shim().reset());

    // registerHook completes once mpv took the registration. The name was
    // marked as registered before mpv_hook_add ran, so a second call for
    // the same hook made meanwhile returned at once, with mpv still
    // without the hook.
    test('a second registerHook for a hook being registered waits for '
        'mpv too', () async {
      const delay = Duration(milliseconds: 600);
      shim().set('hook_add_delay_us', delay.inMicroseconds);
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await player.ready;

      final sw = Stopwatch()..start();
      final first = player.registerHook(Hook.load);
      await waitUntil(
        () => shim().counter('hook_adds_entered') >= 1,
        reason: 'the first registration never reached mpv',
      );
      await player.registerHook(Hook.load);
      expect(
        sw.elapsed,
        greaterThanOrEqualTo(delay),
        reason: 'the second call returned while mpv_hook_add still ran',
      );
      await first;
      expect(shim().counter('hook_adds_entered'), 1);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
