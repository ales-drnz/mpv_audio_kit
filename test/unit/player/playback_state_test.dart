// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/player/mpv_playback_state_derive.dart';
import 'package:mpv_audio_kit/src/types/state/mpv_playback_state.dart';
import 'package:test/test.dart';

MpvPlaybackState _derive({
  bool playing = false,
  bool buffering = false,
  bool completed = false,
  bool pausedForCache = false,
  bool fileLoaded = false,
}) => deriveMpvPlaybackState(
  playing: playing,
  buffering: buffering,
  completed: completed,
  pausedForCache: pausedForCache,
  fileLoaded: fileLoaded,
);

void main() {
  group('deriveMpvPlaybackState', () {
    test('nothing set and no file loaded: idle', () {
      expect(_derive(), MpvPlaybackState.idle);
    });

    test('completed=true wins over every other flag', () {
      expect(
        _derive(completed: true, playing: true, buffering: true),
        MpvPlaybackState.completed,
      );
      expect(
        _derive(completed: true, pausedForCache: true, fileLoaded: true),
        MpvPlaybackState.completed,
      );
    });

    test('pausedForCache=true → buffering (mid-playback network stall)', () {
      expect(
        _derive(pausedForCache: true, fileLoaded: true),
        MpvPlaybackState.buffering,
      );
      // Even if the underlying `buffering` flag also flipped, network
      // stall takes precedence in the semantic mapping.
      expect(
        _derive(buffering: true, pausedForCache: true),
        MpvPlaybackState.buffering,
      );
    });

    test(
      'buffering=true (without pausedForCache) → loading (initial open)',
      () {
        expect(_derive(buffering: true), MpvPlaybackState.loading);
        expect(
          _derive(buffering: true, fileLoaded: true),
          MpvPlaybackState.loading,
          reason: 'mid-load buffering stays "loading" until cache stalls fire',
        );
      },
    );

    test('playing=true (no other flags) → playing', () {
      expect(
        _derive(playing: true, fileLoaded: true),
        MpvPlaybackState.playing,
      );
    });

    test('not playing + file loaded + no flags → paused (user pause)', () {
      expect(_derive(fileLoaded: true), MpvPlaybackState.paused);
    });

    test('not playing + no file loaded + no flags → idle '
        '(distinguishes "no file" from "user pause")', () {
      expect(_derive(), MpvPlaybackState.idle);
    });

    test('a loaded file with no known duration is paused, not idle', () {
      // A live stream before its first cache estimate, or any file in the
      // turn between the end of loading and its first duration report.
      expect(_derive(fileLoaded: true), MpvPlaybackState.paused);
    });
  });
}
