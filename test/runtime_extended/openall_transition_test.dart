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
  final fixturePath = defaultFixturePath();
  final shortFixture = '${Directory.current.path}/test/fixtures/sine_50ms.wav';
  final longFixture = '${Directory.current.path}/test/fixtures/sine_5s.flac';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('openAll transition (append-first)', () {
    late Player player;
    // Every frame a UI would act on: an addressable (index, uri) pair.
    late List<(int, String)> frames;

    setUp(() async {
      player = await buildPlayer();
      frames = <(int, String)>[];
      player.stream.playlist.listen((pl) {
        if (pl.index >= 0 && pl.index < pl.items.length) {
          frames.add((pl.index, pl.items[pl.index].uri));
        }
      });
    });

    tearDown(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    /// Frames where an entry of the INCOMING album (identified by [uri])
    /// was current at a position other than the [allowed] target ones.
    /// The outgoing track may legitimately stay current at any position;
    /// an incoming entry anywhere but the target is the pre-rewrite
    /// "track 1 flashes before the selected track" transient.
    List<(int, String)> incomingOffTarget(String uri, Set<int> allowed) =>
        frames
            .where((f) => f.$2 == uri && !allowed.contains(f.$1))
            .toList(growable: false);

    Future<void> parkAtEof() async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 15));
      await player.openAll([Media(shortFixture)], play: true);
      await completed;
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (await player.getRawProperty('pause') != 'yes') {
        if (DateTime.now().isAfter(deadline)) fail('mpv never parked at EOF');
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    Future<void> openAllAndSettle({bool? play}) async {
      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.openAll(
        List.generate(8, (_) => Media(fixturePath)),
        play: play,
        index: 6,
      );
      await loaded;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }

    test('from IDLE: only the selected entry ever becomes current',
        () async {
      await openAllAndSettle(play: true);

      expect(incomingOffTarget(fixturePath, {6}), isEmpty,
          reason: 'no incoming entry before the selected one may ever '
              'become current',);
      expect(player.state.playlist.index, 6);
      expect(player.state.playlist.items.length, 8);
      expect(await player.getRawProperty('pause'), 'no');
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('from PLAYING: old track holds until the direct jump', () async {
      await openAndWaitForLoad(player, longFixture);
      await player.play();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      frames.clear();

      await openAllAndSettle(play: true);

      // The old entry occupies position 0 until the post-jump remove, so
      // the incoming target legitimately appears at 7 first, then 6.
      expect(incomingOffTarget(fixturePath, {6, 7}), isEmpty,
          reason: 'no incoming entry before the selected one may ever '
              'become current',);
      expect(player.state.playlist.index, 6);
      expect(player.state.playlist.items.length, 8);
      expect(player.state.playing, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('from PARKED at EOF: starts unpaused with intent intact', () async {
      await parkAtEof();
      frames.clear();

      await openAllAndSettle(play: true);

      // The parked entry is removed before the appends (no retained
      // offset), so the incoming target is only ever current at 6.
      expect(incomingOffTarget(fixturePath, {6}), isEmpty,
          reason: 'no incoming entry before the selected one may ever '
              'become current',);
      expect(player.state.playlist.index, 6);
      expect(await player.getRawProperty('pause'), 'no');
      expect(player.state.playWhenReady, isTrue,
          reason: 'the transient idle hop must not settle the OS play '
              'button on paused',);
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('from PARKED with play: false loads the target paused', () async {
      await parkAtEof();
      frames.clear();

      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.openAll(
        List.generate(8, (_) => Media(fixturePath)),
        play: false,
        index: 6,
      );
      await loaded;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(incomingOffTarget(fixturePath, {6}), isEmpty);
      expect(player.state.playlist.index, 6);
      expect(await player.getRawProperty('pause'), 'yes');
      expect(player.state.playWhenReady, isFalse);
    }, timeout: const Timeout(Duration(seconds: 60)),);

    test('default index 0 from PLAYING resolves the retained-entry offset',
        () async {
      await openAndWaitForLoad(player, longFixture);
      await player.play();
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final loaded = player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.openAll(
        [Media(fixturePath), Media(shortFixture)],
        play: true,
      );
      await loaded;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(player.state.playlist.index, 0,
          reason: 'after the old entry is dropped the target settles at 0',);
      expect(player.state.playlist.items.length, 2);
      expect(player.state.playing, isTrue);
    }, timeout: const Timeout(Duration(seconds: 60)),);
  });
}
