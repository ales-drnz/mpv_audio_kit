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
    // ONE Player per file (see dispose_safety_test.dart for the rationale).

    group('Dispose safety — typed setters throw StateError post-dispose', () {
      test('representative setter sample across the 5 mixin modules throws '
          'StateError after dispose', () async {
        final player = await buildPlayer();
        // Bring-up (event isolate included) is done before disposing.
        await player.ready;
        await player.dispose();

        // Pick a representative subset across the 5 mixin modules; they
        // all share the `_checkNotDisposed()` guard.
        expect(() => player.setVolume(50), throwsStateError);
        expect(() => player.setMute(true), throwsStateError);
        expect(() => player.setShuffle(true), throwsStateError);
        expect(() => player.setRate(1.5), throwsStateError);
        expect(
          () => player.setReplayGain(const ReplayGainSettings()),
          throwsStateError,
        );
        expect(() => player.setCache(const CacheSettings()), throwsStateError);
        expect(() => player.play(), throwsStateError);
        expect(() => player.pause(), throwsStateError);
        expect(() => player.stop(), throwsStateError);
        expect(() => player.add(const Media('/tmp/x.wav')), throwsStateError);
        expect(() => player.next(), throwsStateError);
        expect(() => player.clearPlaylist(), throwsStateError);
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
