// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
  // PlaybackLifecycle aggregate stream — the derivation logic is unit-
  // tested in `test/internal/playback_lifecycle_test.dart` and
  // `test/internal/lifecycle_transitions_test.dart`. What's NOT covered
  // there is the runtime stream wiring: the lazy-bind that subscribes
  // when the consumer first listens, and the actual emit cadence as
  // open / play / pause / stop progress.
  //
  // The contract: at least one `playing` lifecycle emission should land
  // on the stream when the consumer plays a fixture through.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/with_chapters.mka';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  test('playbackLifecycle stream emits PlaybackLifecycle.playing during '
      'normal playback', () async {
    final player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ),
    );
    await player.setRawProperty('ao', 'null');

    try {
      // Pre-subscribe BEFORE play() — the lazy-bind only attaches the
      // composing reactives when the first listener arrives, and any
      // emission before subscription is lost on a broadcast stream.
      final playingEmit = player.stream.playbackLifecycle
          .firstWhere((s) => s == PlaybackLifecycle.playing)
          .timeout(const Duration(seconds: 10));

      await player.open(Media(fixturePath), play: false);
      await player.stream.seekCompleted.first
          .timeout(const Duration(seconds: 10));
      await player.play();

      final state = await playingEmit;
      expect(state, PlaybackLifecycle.playing,
          reason: 'aggregate stream must emit `playing` once core-idle '
              'flips to false on the first play() call');
    } finally {
      await player.stop();
      await player.dispose();
    }
  }, timeout: const Timeout(Duration(seconds: 30)));
}
