// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// A pause in the gapless tail, where eof-reached is already yes while the
// output still plays the last buffer: it pauses there, `completed` stays
// down, and play() plays the rest instead of starting the file again.
// libmpv-r22 tells the keep-open park apart (keep-open-parked); before it
// the pause drained the output first and the player took it for the park.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    libmpvReleaseGroup(22, 'A pause in the tail', () {
      test(
        'a pause in the tail pauses there, and play() plays the rest',
        () async {
          final player = await buildPlayer();
          try {
            await player.open(Media(fixturePath), play: true);
            // The tail: the decoder is done, the output still plays.
            await waitUntil(
              () async =>
                  await player.getRawProperty('eof-reached') == 'yes' &&
                  await player.getRawProperty('pause') == 'no',
              interval: const Duration(milliseconds: 2),
              timeout: const Duration(seconds: 10),
              reason: 'eof-reached never came with the output playing',
            );
            await player.pause();
            // The next pass of the core settles time-pos on the delay the
            // output froze at the pause, a few ms; then it stays.
            await Future<void>.delayed(const Duration(milliseconds: 50));
            final at = await player.getRawProperty('time-pos');
            final duration = player.state.duration;
            await Future<void>.delayed(const Duration(milliseconds: 500));
            expect(
              await player.getRawProperty('time-pos'),
              at,
              reason: 'the pause in the tail let the output play on',
            );
            expect(
              player.state.completed,
              isFalse,
              reason: 'a pause in the tail is no end of content',
            );
            final before = double.parse(at!);
            expect(
              before * 1000,
              lessThan(duration.inMilliseconds - 20),
              reason: 'paused at the end, with no tail left',
            );
            await player.play();
            await waitUntil(
              () => player.state.completed,
              reason: 'the rest never played to the park',
            );
            final end = double.parse(
              (await player.getRawProperty('time-pos'))!,
            );
            expect(
              end,
              greaterThan(before),
              reason: 'play() started the file again instead of the rest',
            );
            expect(end * 1000, closeTo(duration.inMilliseconds, 20));
          } finally {
            await player.dispose();
          }
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    });
  });
}
