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

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

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
          play: true,);
      await completed;
      // `completed` flips on the eof-reached edge; the keep-open pause is
      // written by mpv's playloop right after. Poll until it lands.
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (await player.getRawProperty('pause') != 'yes') {
        if (DateTime.now().isAfter(deadline)) {
          fail('mpv never parked paused at EOF');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    test('open(play: true) from the parked state starts unpaused', () async {
      await playToEofPark([shortFixture]);

      // The "user clicks a new album" moment: without the corrective
      // unpause, mpv's keep-open logic re-pauses between the pause
      // write and the loadfile, and the new file loads stuck paused.
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: true);
      await loaded;

      expect(await player.getRawProperty('pause'), 'no',
          reason: 'a play: true load must not inherit the keep-open pause',);
      expect(player.state.playWhenReady, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('openAll(play: true) from the parked state starts unpaused',
        () async {
      await playToEofPark([shortFixture]);

      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.openAll([Media(fixturePath), Media(shortFixture)],
          play: true,);
      await loaded;

      expect(await player.getRawProperty('pause'), 'no',
          reason: 'a play: true load must not inherit the keep-open pause',);
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('jump() from the parked state starts unpaused', () async {
      await playToEofPark([shortFixture, shortFixture]);

      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.jump(0);
      await loaded;

      expect(await player.getRawProperty('pause'), 'no',
          reason: 'jump() must not inherit the keep-open pause',);
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });
}
