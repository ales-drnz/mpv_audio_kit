// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Shared bootstrap for the runtime-extended setter suites. Most files
// open the same fixture in `setUpAll`, configure the null AO, and wait
// for `state.duration` to be populated. This helper collapses that
// boilerplate into one call.

import 'dart:async';
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

/// Builds a [Player] wired for tests: no audio device, no auto-play,
/// no logs. Use when the test wants to drive `open()` itself (e.g.
/// dispose-during-load races, multi-fixture suites).
Future<Player> buildPlayer() async {
  final player = Player(
    configuration: const PlayerConfiguration(
      autoPlay: false,
      logLevel: LogLevel.off,
    ),
  );
  await player.setRawProperty('ao', 'null');
  return player;
}

/// Opens [fixturePath] on [player] and waits for the file-loaded
/// signal. Anchors on `seekCompleted` (mpv's PLAYBACK_RESTART), which
/// fires exactly once per `loadfile` after the demuxer has settled —
/// robust against `ReactiveProperty` dedup on identical-duration
/// fixtures.
Future<void> openAndWaitForLoad(
  Player player,
  String fixturePath, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final c = Completer<void>();
  final sub = player.stream.seekCompleted.listen((_) {
    if (!c.isCompleted) c.complete();
  });
  try {
    await player.open(Media(fixturePath), play: false);
    await c.future.timeout(timeout);
  } finally {
    await sub.cancel();
  }
}

/// Convenience for the most common setUpAll body: builds a [Player] and,
/// if [fixturePath] is non-null, opens it and waits for file-loaded.
Future<Player> buildPlayerWithFixture({String? fixturePath}) async {
  final player = await buildPlayer();
  if (fixturePath != null) {
    await openAndWaitForLoad(player, fixturePath);
  }
  return player;
}
