// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Verifies the audio-only pre-init recipe is actually applied to the real
// libmpv after construction — reading each option back from the binary, not
// from Dart state. Guards against a future mpv version renaming/dropping one
// of these (the option read would return null and fail loudly).

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  runtimeSuite(() {
    group('pre-init recipe applied to real libmpv', () {
      late Player player;
      setUpAll(() async => player = await buildPlayer());
      tearDownAll(() => player.dispose());

      test('audio-only hardening options took effect', () async {
        // The headline of fix #5: a failed audio-device open falls back to the
        // null AO instead of hard-failing. The whole point is that this is set
        // BEFORE the first (lazy) AO open, which only the pre-init recipe can do.
        expect(
          await player.getRawProperty('audio-fallback-to-null'),
          'yes',
          reason: 'audio-fallback-to-null must be enabled at init (#5)',
        );

        // A few other load-bearing recipe entries, as a recipe-wide guard.
        expect(await player.getRawProperty('vid'), 'no');
        expect(await player.getRawProperty('keep-open'), 'yes');
        expect(await player.getRawProperty('idle'), 'yes');
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
