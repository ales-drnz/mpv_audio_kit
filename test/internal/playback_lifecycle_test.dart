// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/playback/playback_lifecycle_derive.dart';
import 'package:mpv_audio_kit/src/playback/playback_lifecycle.dart';

PlaybackLifecycle _derive({
  bool playing = false,
  bool buffering = false,
  bool completed = false,
  bool pausedForCache = false,
  Duration duration = Duration.zero,
}) =>
    derivePlaybackLifecycle(
      playing: playing,
      buffering: buffering,
      completed: completed,
      pausedForCache: pausedForCache,
      duration: duration,
    );

void main() {
  group('derivePlaybackLifecycle', () {
    test('all-false + duration=0 → idle (no file loaded)', () {
      expect(_derive(), PlaybackLifecycle.idle);
    });

    test('completed=true wins over every other flag', () {
      expect(
        _derive(completed: true, playing: true, buffering: true),
        PlaybackLifecycle.completed,
      );
      expect(
        _derive(
          completed: true,
          pausedForCache: true,
          duration: const Duration(seconds: 30),
        ),
        PlaybackLifecycle.completed,
      );
    });

    test('pausedForCache=true → buffering (mid-playback network stall)', () {
      expect(
        _derive(
          pausedForCache: true,
          duration: const Duration(seconds: 30),
        ),
        PlaybackLifecycle.buffering,
      );
      // Even if the underlying `buffering` flag also flipped, network
      // stall takes precedence in the semantic mapping.
      expect(
        _derive(buffering: true, pausedForCache: true),
        PlaybackLifecycle.buffering,
      );
    });

    test('buffering=true (without pausedForCache) → loading (initial open)',
        () {
      expect(_derive(buffering: true), PlaybackLifecycle.loading);
      expect(
        _derive(
          buffering: true,
          duration: const Duration(seconds: 30),
        ),
        PlaybackLifecycle.loading,
        reason: 'mid-load buffering stays "loading" until cache stalls fire',
      );
    });

    test('playing=true (no other flags) → playing', () {
      expect(
        _derive(playing: true, duration: const Duration(seconds: 30)),
        PlaybackLifecycle.playing,
      );
    });

    test('not playing + duration > 0 + no flags → paused (user pause)', () {
      expect(
        _derive(duration: const Duration(seconds: 30)),
        PlaybackLifecycle.paused,
      );
    });

    test(
        'not playing + duration == 0 + no flags → idle '
        '(distinguishes "no file" from "user pause")', () {
      expect(_derive(), PlaybackLifecycle.idle);
    });
  });
}
