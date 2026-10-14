// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    // Companion of `dispose_safety_test.dart` — split into a separate
    // file so the SIGSEGV-on-3rd-Player ceiling (CLAUDE.md) doesn't bite
    // when running the full dispose-contract suite. This file uses
    // exactly ONE Player.

    group(
      'Dispose safety — escape hatches throw PlayerDisposedException after dispose',
      () {
        test(
          'getRawProperty, setRawProperty, sendRawCommand and registerHook '
          'throw PlayerDisposedException post-dispose, continueHook is a no-op',
          () async {
            final player = await buildPlayer();
            // Bring-up (event isolate included) is done before disposing.
            await player.ready;
            await player.dispose();

            expect(
              () => player.getRawProperty('volume'),
              throwsA(isA<PlayerDisposedException>()),
            );
            expect(
              () => player.setRawProperty('volume', '50'),
              throwsA(isA<PlayerDisposedException>()),
            );
            expect(
              () => player.sendRawCommand(['set', 'volume', '50']),
              throwsA(isA<PlayerDisposedException>()),
            );
            expect(
              () => player.registerHook(Hook.load),
              throwsA(isA<PlayerDisposedException>()),
            );
            // Dispose continued every pending hook: a late continue from
            // a listener is a no-op, not an error.
            await player.continueHook(1);
          },
          timeout: const Timeout(Duration(seconds: 15)),
        );
      },
    );
  });
}
