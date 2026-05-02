// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/internals/mpv_playback_state_derive.dart';
import 'package:mpv_audio_kit/src/types/state/mpv_playback_state.dart';

MpvPlaybackState _derive({
  bool playing = false,
  bool buffering = false,
  bool completed = false,
  bool pausedForCache = false,
  Duration duration = Duration.zero,
}) =>
    deriveMpvPlaybackState(
      playing: playing,
      buffering: buffering,
      completed: completed,
      pausedForCache: pausedForCache,
      duration: duration,
    );

void main() {
  group('deriveMpvPlaybackState', () {
    test('all-false + duration=0 → idle (no file loaded)', () {
      expect(_derive(), MpvPlaybackState.idle);
    });

    test('completed=true wins over every other flag', () {
      expect(
        _derive(completed: true, playing: true, buffering: true),
        MpvPlaybackState.completed,
      );
      expect(
        _derive(
          completed: true,
          pausedForCache: true,
          duration: const Duration(seconds: 30),
        ),
        MpvPlaybackState.completed,
      );
    });

    test('pausedForCache=true → buffering (mid-playback network stall)', () {
      expect(
        _derive(
          pausedForCache: true,
          duration: const Duration(seconds: 30),
        ),
        MpvPlaybackState.buffering,
      );
      // Even if the underlying `buffering` flag also flipped, network
      // stall takes precedence in the semantic mapping.
      expect(
        _derive(buffering: true, pausedForCache: true),
        MpvPlaybackState.buffering,
      );
    });

    test('buffering=true (without pausedForCache) → loading (initial open)',
        () {
      expect(_derive(buffering: true), MpvPlaybackState.loading);
      expect(
        _derive(
          buffering: true,
          duration: const Duration(seconds: 30),
        ),
        MpvPlaybackState.loading,
        reason: 'mid-load buffering stays "loading" until cache stalls fire',
      );
    });

    test('playing=true (no other flags) → playing', () {
      expect(
        _derive(playing: true, duration: const Duration(seconds: 30)),
        MpvPlaybackState.playing,
      );
    });

    test('not playing + duration > 0 + no flags → paused (user pause)', () {
      expect(
        _derive(duration: const Duration(seconds: 30)),
        MpvPlaybackState.paused,
      );
    });

    test(
        'not playing + duration == 0 + no flags → idle '
        '(distinguishes "no file" from "user pause")', () {
      expect(_derive(), MpvPlaybackState.idle);
    });
  });
}
