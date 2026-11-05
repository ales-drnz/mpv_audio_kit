// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A web module with the ABI and the layout of the pin, but of another
// release, fails the player at bring-up with a PlayerInitException, as a
// native libmpv of another release does. debugWebMpvVersion stands for the
// mpv-version of such a module (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/web_session.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

import 'web_module_helper.dart';

void main() {
  setUpAll(() {
    debugWebModule = loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });
  tearDown(() => debugWebMpvVersion = null);

  test('a module of another release fails bring-up', () async {
    debugWebMpvVersion = 'mpv v0.41.0+r1';
    final player = Player();
    addTearDown(player.dispose);
    await expectLater(
      player.ready,
      throwsA(
        isA<PlayerInitException>().having(
          (e) => e.message,
          'message',
          allOf(contains('mpv v0.41.0+r1'), contains('libmpv-$libmpvRelease')),
        ),
      ),
    );
  });

  test('a player after it, on the module of the pin, brings up', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
  });
}
