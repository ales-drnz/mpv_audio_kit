// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final shortFixture = '${Directory.current.path}/test/fixtures/sine_50ms.wav';
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('completed with short entries', () {
      /// Plays [uris] to the keep-open park and checks that `completed`
      /// rose once, at the end, and holds there. An entry that reaches
      /// EOF as soon as it loads makes mpv's observer skip the
      /// eof-reached edges between entries: an edge-driven flag rose at
      /// a track change and was then cleared, or missed the end.
      /// Repeated, since the skipped edges depend on timing.
      Future<void> playThroughAndCheck(List<String> uris) async {
        for (var run = 0; run < 5; run++) {
          final player = await buildPlayer();
          final completed = <bool>[];
          final states = <MpvPlaybackState>[];
          final subs = [
            player.stream.completed.listen(completed.add),
            player.stream.playbackState.listen(states.add),
          ];
          try {
            await player.openAll(
              uris.map(Media.new).toList(growable: false),
              play: true,
            );
            await waitUntil(
              () async =>
                  await player.getRawProperty('eof-reached') == 'yes' &&
                  await player.getRawProperty('pause') == 'yes' &&
                  await player.getRawProperty('playlist-pos') ==
                      '${uris.length - 1}',
              timeout: const Duration(seconds: 15),
              reason: 'mpv never parked at the end of the playlist',
            );
            // The park's events cross the isolate after the reads above.
            await waitUntil(
              () => player.state.completed,
              timeout: const Duration(seconds: 2),
              reason: 'completed missed the end of the playlist (run $run)',
            );
            await Future<void>.delayed(const Duration(milliseconds: 200));

            expect(completed.skipWhile((c) => !c).toList(), [
              true,
            ], reason: 'completed must rise once, at the end (run $run)');
            expect(player.state.completed, isTrue);
            expect(player.state.eofReached, isTrue);
            expect(player.state.playWhenReady, isFalse);
            expect(states.last, MpvPlaybackState.completed);
            expect(
              states.skipWhile((s) => s != MpvPlaybackState.completed).toSet(),
              {MpvPlaybackState.completed},
              reason: 'playbackState must not leave completed (run $run)',
            );
          } finally {
            for (final s in subs) {
              await s.cancel();
            }
            await player.stop();
            await player.dispose();
          }
        }
      }

      test('a long entry then a short one', () async {
        await playThroughAndCheck([fixturePath, shortFixture]);
      }, timeout: const Timeout(Duration(seconds: 120)));

      test('only short entries', () async {
        await playThroughAndCheck([shortFixture, shortFixture, shortFixture]);
      }, timeout: const Timeout(Duration(seconds: 120)));

      test('a loop change at the park follows the end of content', () async {
        final player = await buildPlayer();
        try {
          await player.openAll([Media(shortFixture)], play: true);
          await waitUntil(
            () => player.state.completed,
            timeout: const Duration(seconds: 15),
            reason: 'mpv never parked at the end',
          );
          // A loop at the park means the end is no longer the end. mpv
          // rewinds the file when the loop goes on and stays paused, so
          // eof-reached moves here too: the loop-only read is checked in
          // end_of_content_shim_test. With the loop off again the entry
          // sits paused at its start, not at its end, until it plays out.
          await player.setLoop(Loop.file);
          await waitUntil(
            () => !player.state.completed,
            timeout: const Duration(seconds: 2),
            reason: 'completed stayed up with a loop on',
          );
          await player.setLoop(Loop.off);
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(
            player.state.completed,
            isFalse,
            reason: 'the rewound entry is paused at its start',
          );
          await player.play();
          await waitUntil(
            () => player.state.completed,
            reason: 'completed missed the end once the loop went off',
          );
        } finally {
          await player.stop();
          await player.dispose();
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    });
  });
}
