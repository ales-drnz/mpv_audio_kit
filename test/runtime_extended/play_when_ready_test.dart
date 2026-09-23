// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// End-to-end coverage for the `playWhenReady` intent axis against real
/// libmpv.
///
/// `playWhenReady` is the user-intent half of the two-axis transport
/// model (intent × processing-state, as in ExoPlayer / just_audio /
/// AVFoundation). It is what the OS media-session play/pause button
/// binds to, and its load-bearing contract is:
///
/// 1. It emits `true` on the FIRST autoplay open — the case mpv's
///    `pause` property cannot signal (it defaults to `no` and fires no
///    PROPERTY_CHANGE on the first load → playing transition).
/// 2. It NEVER flips to `false` during a seek. mpv flips `core-idle`
///    (→ `state.playing`) transiently on every seek; `playWhenReady`
///    must stay stable so the OS scrub bar's play/pause button does not
///    flicker while scrubbing.
void main() {
  // 3-second fixture: long enough to seek around without racing EOF.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  runtimeSuite(fixturePath: fixturePath, () {
    group('playWhenReady intent axis (end-to-end)', () {
      test(
        'open(play: true) emits playWhenReady=true on the FIRST load',
        () async {
          // Binding intent to mpv's `pause` stream would leave the play/pause
          // button stuck — `pause` is silent on the first autoplay. Intent is
          // set optimistically at the open() call-site, so it must surface
          // even on a cold player.
          final player = await buildPlayer();
          addTearDown(player.dispose);

          final firstTrue = player.stream.playWhenReady
              .firstWhere((p) => p)
              .timeout(const Duration(seconds: 10));
          await player.open(Media(fixturePath), play: true);
          await firstTrue;
          expect(player.state.playWhenReady, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 20)),
      );

      test('open(play: false) leaves playWhenReady=false', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        await openAndWaitForLoad(player, fixturePath); // opens with play: false
        expect(player.state.playWhenReady, isFalse);
      }, timeout: const Timeout(Duration(seconds: 20)));

      test(
        'seek of a PLAYING file never flips playWhenReady to false',
        () async {
          // The core anti-flicker guarantee. While core-idle (→ state.playing)
          // may toggle during each seek, the intent axis must stay true
          // across a burst of seeks — that is what keeps the OS button stable.
          final player = await buildPlayer();
          addTearDown(() async {
            await player.stop();
            await player.dispose();
          });

          final playing = player.stream.playWhenReady
              .firstWhere((p) => p)
              .timeout(const Duration(seconds: 10));
          await player.open(Media(fixturePath), play: true);
          await playing;
          expect(player.state.playWhenReady, isTrue);

          // Loop the file so the untimed null AO can't race to EOF mid-test
          // (EOF → idle-active would legitimately clear intent — that is not
          // a seek flicker, and it would mask the signal we're isolating).
          await player.setLoop(Loop.file);

          // Record every intent emission during a burst of seeks.
          final emissions = <bool>[];
          final sub = player.stream.playWhenReady.listen(emissions.add);

          // A scrub-bar drag is a burst of absolute seeks. Fire several,
          // each waiting for the position to land so mpv actually runs the
          // reset → restart cycle (which flips core-idle) every time.
          for (final ms in const [200, 1200, 400, 1800, 600, 2200]) {
            final landed = player.stream.seekCompleted.first.timeout(
              const Duration(seconds: 5),
            );
            await player.seek(Duration(milliseconds: ms));
            await landed;
          }
          await Future<void>.delayed(const Duration(milliseconds: 200));
          await sub.cancel();

          expect(
            emissions,
            isNot(contains(false)),
            reason: 'intent must not flip false during seeks (button flicker)',
          );
          expect(player.state.playWhenReady, isTrue);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );

      test('pause() / play() toggle playWhenReady', () async {
        final player = await buildPlayer();
        addTearDown(() async {
          await player.stop();
          await player.dispose();
        });

        final up = player.stream.playWhenReady
            .firstWhere((p) => p)
            .timeout(const Duration(seconds: 10));
        await player.open(Media(fixturePath), play: true);
        await up;

        final down = player.stream.playWhenReady
            .firstWhere((p) => !p)
            .timeout(const Duration(seconds: 5));
        await player.pause();
        await down;
        expect(player.state.playWhenReady, isFalse);

        final up2 = player.stream.playWhenReady
            .firstWhere((p) => p)
            .timeout(const Duration(seconds: 5));
        await player.play();
        await up2;
        expect(player.state.playWhenReady, isTrue);
      }, timeout: const Timeout(Duration(seconds: 25)));

      test('stop() clears playWhenReady', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);

        final up = player.stream.playWhenReady
            .firstWhere((p) => p)
            .timeout(const Duration(seconds: 10));
        await player.open(Media(fixturePath), play: true);
        await up;

        final down = player.stream.playWhenReady
            .firstWhere((p) => !p)
            .timeout(const Duration(seconds: 5));
        await player.stop();
        await down;
        expect(player.state.playWhenReady, isFalse);
      }, timeout: const Timeout(Duration(seconds: 25)));
    });
  });
}
