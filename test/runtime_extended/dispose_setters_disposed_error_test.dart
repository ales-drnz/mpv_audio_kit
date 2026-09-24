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

    group(
      'Dispose safety — typed setters throw PlayerDisposedException post-dispose',
      () {
        test('representative setter sample across the 5 mixin modules throws '
            'PlayerDisposedException after dispose', () async {
          final player = await buildPlayer();
          // Bring-up (event isolate included) is done before disposing.
          await player.ready;
          await player.dispose();

          // Pick a representative subset across the 5 mixin modules; they
          // all share the `_checkNotDisposed()` guard.
          expect(
            () => player.setVolume(50),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(
            () => player.setMute(true),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(
            () => player.setShuffle(true),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(
            () => player.setRate(1.5),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(
            () => player.setReplayGain(const ReplayGainSettings()),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(
            () => player.setCache(const CacheSettings()),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(() => player.play(), throwsA(isA<PlayerDisposedException>()));
          expect(() => player.pause(), throwsA(isA<PlayerDisposedException>()));
          expect(() => player.stop(), throwsA(isA<PlayerDisposedException>()));
          expect(
            () => player.add(const Media('/tmp/x.wav')),
            throwsA(isA<PlayerDisposedException>()),
          );
          expect(() => player.next(), throwsA(isA<PlayerDisposedException>()));
          expect(
            () => player.clearPlaylist(),
            throwsA(isA<PlayerDisposedException>()),
          );
        }, timeout: const Timeout(Duration(seconds: 15)));
      },
    );
  });
}
