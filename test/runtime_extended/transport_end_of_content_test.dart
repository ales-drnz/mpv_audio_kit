// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// End-to-end coverage for the transport state at end-of-content against
/// real libmpv, under the shipped `keep-open: yes` + `idle: yes` config.
///
/// mpv parks paused on the last frame at the natural end of a single track
/// or the last playlist entry and withholds BOTH `END_FILE` and
/// `idle-active` (verified against mpv 0.41.0 `handle_keep_open`,
/// player/playloop.c:983). The library settles the transport off the
/// `eof-reached` rising edge instead, so:
///   - the play/pause intent (`playWhenReady`, the OS-button binding) is
///     released at the true end of content,
///   - `completed` / `MpvPlaybackState.completed` are reachable for a lone
///     track and for the last playlist entry,
///   - but neither fires at a gapless mid-playlist boundary (no button
///     flicker).
void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('end-of-content transport (keep-open)', () {
    test(
      'single-track natural EOF releases intent and marks completed',
      () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        final states = <MpvPlaybackState>[];
        final sub = player.stream.playbackState.listen(states.add);

        final completed = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 8));
        await player.open(Media(fixturePath), play: true);
        await completed;
        // Let any trailing transitions settle.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        expect(player.state.completed, isTrue);
        expect(player.state.eofReached, isTrue);
        expect(player.state.playing, isFalse);
        expect(
          player.state.playWhenReady,
          isFalse,
          reason: 'OS play/pause button settles on play at end-of-content',
        );
        expect(
          states.last,
          MpvPlaybackState.completed,
          reason: 'derive lands on completed, not paused',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    test(
      'playlist advance does NOT reset intent mid-playlist (no flicker)',
      () async {
        final player = await buildPlayer();
        addTearDown(() async {
          await player.stop();
          await player.dispose();
        });

        final emissions = <bool>[];
        final sub = player.stream.playWhenReady.listen(emissions.add);
        await player.openAll([
          Media(fixturePath),
          Media(fixturePath),
        ], play: true);
        // Sample across the track1->track2 boundary but BEFORE track2 ends.
        await Future<void>.delayed(const Duration(milliseconds: 1400));
        await sub.cancel();

        expect(
          emissions,
          isNot(contains(false)),
          reason: 'gapless advance must not flip the play/pause button',
        );
        expect(player.state.playWhenReady, isTrue);
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );

    test('end of a playlist releases intent and marks completed', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);

      await player.openAll([
        Media(fixturePath),
        Media(fixturePath),
      ], play: true);
      final done = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 12));
      // The first track's end also pulses completed=true; wait for the queue
      // to drain fully, then assert the resting state.
      await done;
      await Future<void>.delayed(const Duration(milliseconds: 2600));

      expect(
        player.state.playWhenReady,
        isFalse,
        reason: 'button settles on play when the playlist is exhausted',
      );
      expect(player.state.playing, isFalse);
      expect(player.state.completed, isTrue);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('seeking back into a completed track clears completed', () async {
      final player = await buildPlayer();
      addTearDown(() async {
        await player.stop();
        await player.dispose();
      });

      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 8));
      await player.open(Media(fixturePath), play: true);
      await completed;
      expect(player.state.completed, isTrue);

      // Seek back into the track: eof-reached drops, completed must clear.
      final cleared = player.stream.completed
          .firstWhere((c) => !c)
          .timeout(const Duration(seconds: 5));
      await player.seek(const Duration(milliseconds: 100));
      await cleared;
      expect(player.state.completed, isFalse);
    }, timeout: const Timeout(Duration(seconds: 25)));
  });

  group('intent-axis integrity', () {
    test('setRawProperty("pause", ...) is rejected', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      await openAndWaitForLoad(player, fixturePath);

      expect(
        () => player.setRawProperty('pause', 'yes'),
        throwsArgumentError,
        reason: 'pause is reserved by the transport intent axis',
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

    test(
      'failed first open(play:true) does not leave intent stuck true',
      () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        final missing =
            '${Directory.current.path}/test/fixtures/__does_not_exist__.mka';
        await player.open(Media(missing), play: true);
        // `open(play: true)` writes the optimistic intent synchronously, so the
        // button reads `true` here. The failed load then runs START_FILE (arms
        // the latch even for a failed open) -> END_FILE(error) -> idle-active ->
        // intent reset. Poll the resting state until it flips instead of a fixed
        // delay: under full-suite load the event chain can take longer than a
        // couple of seconds, which is what made the fixed-delay version flake.
        final deadline = DateTime.now().add(const Duration(seconds: 12));
        while (player.state.playWhenReady &&
            DateTime.now().isBefore(deadline)) {
          await Future<void>.delayed(const Duration(milliseconds: 25));
        }

        expect(
          player.state.playWhenReady,
          isFalse,
          reason: 'a failed load loads nothing; the button must not stick',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
