// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// openAll while a file plays keeps that file playing until the new list
// is in, jumps to the new entry, then removes the old one. Between the
// jump and the removal mpv lists the old entry ahead of the new ones: the
// state hides it, so the app sees the list it asked for, and the calls by
// index address that list. A macOS run of web_parity_native_test caught
// the state at FILE_LOADED as [long, first, second] at 1.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/player/player.dart'
    show debugBeforeRetainedRemove;
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();
  final dir = '${Directory.current.path}/test/fixtures';
  final longPath = '$dir/sine_5s.flac';
  final secondPath = '$dir/sine_stereo_1s.flac';

  runtimeSuite(
    fixturePath: fixturePath,
    extraFixtures: [longPath, secondPath],
    () {
      late Player player;
      setUp(() async => player = await buildPlayer());
      tearDown(() async {
        debugBeforeRetainedRemove = null;
        await player.dispose();
      });

      String uris(Playlist p) =>
          '${p.items.map((m) => m.uri.split('/').last).join(',')} at ${p.index}';

      /// Opens the long file playing, then [openAll] of the two others
      /// with the old entry held in mpv for 300 ms after the jump, and
      /// runs [during] in that window.
      Future<void> openAllHeld(Future<void> Function() during) async {
        await player.open(Media(longPath), play: true);
        await waitUntil(
          () => player.state.playback.playing,
          reason: 'long plays',
        );
        final held = Completer<void>();
        debugBeforeRetainedRemove = () async {
          debugBeforeRetainedRemove = null;
          await waitUntil(
            () =>
                !player.state.network.buffering &&
                player.state.playback.playing,
            reason: 'the new entry loaded',
          );
          await Future<void>.delayed(const Duration(milliseconds: 300));
          await during();
          held.complete();
        };
        await player.openAll([
          Media(fixturePath),
          Media(secondPath),
        ], play: true);
        await held.future;
      }

      test('the state never lists the old entry after the jump', () async {
        final seen = <String>[];
        final sub = player.stream.playlist.listen((p) => seen.add(uris(p)));
        addTearDown(sub.cancel);
        await openAllHeld(() async {
          expect(
            uris(player.state.playback.playlist),
            'sine_440hz_1s.wav,sine_stereo_1s.flac at 0',
            reason: 'mpv still lists the old entry, the state must not',
          );
        });
        expect(
          seen.where(
            (s) => s.startsWith('sine_5s.flac,') && !s.endsWith(' at 0'),
          ),
          isEmpty,
          reason: 'a playlist event showed the old entry after the jump: $seen',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('calls by index address the list the state shows', () async {
        await openAllHeld(() async {
          await player.jump(1);
          await waitUntil(
            () => player.state.playback.playlist.index == 1,
            reason: 'jump(1) never reached the second new entry',
          );
          expect(
            await player.getRawProperty('path'),
            endsWith('sine_stereo_1s.flac'),
          );
        });
        await waitUntil(
          () => player.state.playback.playlist.items.length == 2,
          reason: 'the old entry never left',
        );
        expect(
          uris(player.state.playback.playlist),
          'sine_440hz_1s.wav,sine_stereo_1s.flac at 1',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    },
  );
}
