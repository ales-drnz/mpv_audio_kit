// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Loads that a later call overtakes, driven through the slow-core shim: a
// reply held back keeps a load in flight for as long as the test needs to
// call something else meanwhile.

@TestOn('mac-os || linux')
@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';
import '../_helpers/slow_core_shim.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final fixturePath = '$dir/sine_440hz_1s.wav';
  final longFixture = '$dir/sine_5s.flac';

  slowCoreShimSuite(fixturePath: fixturePath, extraFixtures: [longFixture], (
    shim,
  ) {
    late Player player;

    setUp(() async {
      shim().reset();
      player = await buildPlayer();
    });

    tearDown(() async {
      shim().reset();
      await player.dispose();
    });

    /// Plays [fixturePath] to the keep-open park at the end of the queue.
    Future<void> park() async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      await player.open(Media(fixturePath), play: true);
      await completed;
    }

    /// Runs [load] with the reply to its [command] held back, and calls
    /// pause() while that reply waits: after mpv ran the command, before
    /// the load sees it.
    Future<void> pauseDuring(
      String command,
      Future<void> Function() load,
    ) async {
      shim().holdReply(command, const Duration(milliseconds: 400));
      final loading = load();
      await waitUntil(
        () => shim().counter('replies_held') > 0,
        reason: 'the $command reply was never held',
      );
      final pausing = player.pause();
      await loading;
      await pausing;
    }

    // At the park a load writes the unpause again once mpv replaced the
    // file, since keep-open undoes the first one. A pause() called while
    // the load waited for that reply has the last word.
    group('a pause() during a load at the end has the last word', () {
      test('open', () async {
        await park();
        await pauseDuring(
          'loadfile',
          () => player.open(Media(longFixture), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'yes');
        expect(player.state.playWhenReady, isFalse);
      });

      test('openPlaylistFile', () async {
        final tmp = Directory.systemTemp.createTempSync('mak_m3u_');
        addTearDown(() => tmp.deleteSync(recursive: true));
        final list = File('${tmp.path}/list.m3u')
          ..writeAsStringSync('$longFixture\n');
        await park();
        await pauseDuring(
          'loadlist',
          () => player.openPlaylistFile(Media(list.path), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(await player.getRawProperty('pause'), 'yes');
        expect(player.state.playWhenReady, isFalse);
      });
    });
  });
}
