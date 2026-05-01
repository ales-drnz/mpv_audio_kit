// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Shared bootstrap for the runtime-extended setter suites. Most files
// open the same fixture in `setUpAll`, configure the null AO, and wait
// for `state.duration` to be populated. This helper collapses that
// boilerplate into one call.

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import 'libmpv_resolver.dart';

/// Default 1-second sine fixture used by the setter suites.
String defaultFixturePath() =>
    '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

/// Top-level `setUpAll` body for setter test files. Resolves the
/// platform's libmpv, marks the test group skipped if either the
/// library or [fixturePath] is missing, and initializes
/// [MpvAudioKit] with the hot-restart tracker disabled (the
/// per-VM-pid sentinel is incompatible with `flutter test`'s isolate
/// reuse — see CLAUDE.md).
///
/// Returns `true` when the suite is good to run; `false` when it was
/// skipped (callers usually ignore the return value because
/// `markTestSkipped` short-circuits subsequent tests on its own).
bool initLibmpvOrSkip({String? fixturePath}) {
  final lib = resolveLibmpv();
  if (lib == null) {
    markTestSkipped('libmpv not found');
    return false;
  }
  if (fixturePath != null && !File(fixturePath).existsSync()) {
    markTestSkipped('Fixture missing: $fixturePath');
    return false;
  }
  MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  return true;
}

/// Builds a [Player] wired for tests (no audio device, no auto-play,
/// no logs) and, if [fixturePath] is non-null, opens it and waits for
/// the duration observer to land.
///
/// Mirrors the body that every `setters_*_test.dart` repeats today.
Future<Player> buildPlayerWithFixture({String? fixturePath}) async {
  final player = Player(
    configuration: const PlayerConfiguration(
      autoPlay: false,
      logLevel: 'no',
    ),
  );
  await player.setRawProperty('ao', 'null');
  if (fixturePath != null) {
    await player.open(Media(fixturePath), play: false);
    await player.stream.duration
        .firstWhere((d) => d.inMilliseconds > 500)
        .timeout(const Duration(seconds: 5));
  }
  return player;
}
