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
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  // These cover the park the player has seen (`completed` up). A park it
  // has not seen, the case the transport reads eof-reached from the core
  // for, needs the slow-core shim: see end_of_content_shim_test.
  runtimeSuite(fixturePath: fixturePath, () {
    group('Resume after keep-open EOF park', () {
      late Player player;

      setUp(() async {
        player = await buildPlayer();
      });

      tearDown(() async {
        await player.stop();
        await player.clearPlaylist();
        await player.dispose();
      });

      /// Plays [uris] to the end and waits until mpv is parked paused on
      /// the last frame (`keep-open: yes` + `keep-open-pause`).
      Future<void> playToEofPark(List<String> uris) async {
        final completed = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 15));
        await player.openAll(
          uris.map(Media.new).toList(growable: false),
          play: true,
        );
        await completed;
        // `completed` flips on the eof-reached edge; the keep-open pause is
        // written by mpv's playloop right after. Poll until it lands.
        await waitUntil(
          () async => await player.getRawProperty('pause') == 'yes',
          reason: 'mpv never parked paused at EOF',
        );
      }

      test('open(play: true) from the parked state starts unpaused', () async {
        await playToEofPark([shortFixture]);

        // The "user clicks a new album" moment: without the corrective
        // unpause, mpv's keep-open logic re-pauses between the pause
        // write and the loadfile, and the new file loads stuck paused.
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.open(Media(fixturePath), play: true);
        await loaded;

        expect(
          await player.getRawProperty('pause'),
          'no',
          reason: 'a play: true load must not inherit the keep-open pause',
        );
        expect(player.state.playWhenReady, isTrue);
      }, timeout: const Timeout(Duration(seconds: 60)));

      test(
        'openAll(play: true) from the parked state starts unpaused',
        () async {
          await playToEofPark([shortFixture]);

          final loaded = player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 10),
          );
          await player.openAll([
            Media(fixturePath),
            Media(shortFixture),
          ], play: true);
          await loaded;

          expect(
            await player.getRawProperty('pause'),
            'no',
            reason: 'a play: true load must not inherit the keep-open pause',
          );
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test('jump() from the parked state starts unpaused', () async {
        // The entry jumped to lasts 1 s: with two 50 ms entries the
        // playlist could reach its end and park again before the read.
        await playToEofPark([fixturePath, shortFixture]);

        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        await player.jump(0);
        await loaded;

        expect(
          await player.getRawProperty('pause'),
          'no',
          reason: 'jump() must not inherit the keep-open pause',
        );
      }, timeout: const Timeout(Duration(seconds: 60)));

      test(
        'play() from the parked state starts the last track again',
        () async {
          // Long enough to still be playing when checked.
          await playToEofPark([longFixture]);

          await player.play();

          await waitUntil(
            () async =>
                await player.getRawProperty('pause') == 'no' &&
                player.state.playing &&
                !player.state.completed,
            reason: 'play() at the end must play, not only show pause',
          );
          expect(player.state.playWhenReady, isTrue);
          expect(
            player.state.position,
            lessThan(const Duration(seconds: 4)),
            reason: 'the last track starts again from its beginning',
          );
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );
    });
  });
}
