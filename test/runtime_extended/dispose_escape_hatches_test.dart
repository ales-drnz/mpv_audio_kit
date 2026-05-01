// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;


import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  // Companion of `dispose_safety_test.dart` — split into a separate
  // file so the SIGSEGV-on-3rd-Player ceiling (CLAUDE.md) doesn't bite
  // when running the full dispose-contract suite. This file uses
  // exactly ONE Player.

  group('Dispose safety — escape hatches throw StateError after dispose',
      () {
    test('getRawProperty / setRawProperty / sendRawCommand / registerHook / '
        'continueHook all throw StateError post-dispose', () async {
      final player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      // Allow the event isolate to spawn fully before disposing.
      await Future.delayed(const Duration(milliseconds: 200));
      await player.dispose();

      expect(() => player.getRawProperty('volume'), throwsStateError);
      expect(
          () => player.setRawProperty('volume', '50'), throwsStateError);
      expect(() => player.sendRawCommand(['set', 'volume', '50']),
          throwsStateError);
      expect(() => player.registerHook('on_load'), throwsStateError);
      expect(() => player.continueHook(1), throwsStateError);

      // Let libmpv's background threads wind down (see
      // dispose_safety_test.dart for the rationale).
      await Future.delayed(const Duration(seconds: 1));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
