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

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import 'libmpv_resolver.dart';

/// Default 1-second sine fixture used by the setter suites.
String defaultFixturePath() =>
    '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

/// Why a suite that needs the bundled libmpv (and optionally
/// [fixturePath] and [extraFixtures]) can't run on this host, or `null`
/// when it can.
String? libmpvSkipReason({
  String? fixturePath,
  List<String> extraFixtures = const [],
}) {
  if (resolveLibmpv() == null) return 'libmpv not found';
  for (final path in [?fixturePath, ...extraFixtures]) {
    if (!File(path).existsSync()) return 'Fixture missing: $path';
  }
  return null;
}

/// Initializes [MpvAudioKit] against the bundled libmpv, with the
/// hot-restart tracker disabled (the per-VM-pid sentinel is incompatible
/// with `flutter test`'s isolate reuse). Only call it when
/// [libmpvSkipReason] returned `null`.
void initLibmpv() {
  // Brings up the Flutter test binding so `rootBundle.load` works —
  // `asset://` URIs are materialised through `rootBundle` by the URI
  // resolver, which needs the binding initialised first.
  TestWidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized(
    libmpv: resolveLibmpv()!,
    hotRestartCleanup: false,
  );
}

/// Declares a suite that needs the bundled libmpv. When libmpv or
/// any fixture is missing, every test in [body] is registered as
/// skipped with the reason; otherwise a `setUpAll` initializes
/// [MpvAudioKit] before [body]'s own setup runs. Pass `initialize: false`
/// for a suite that initializes [MpvAudioKit] itself (e.g. through a
/// shim), since only the first `ensureInitialized` call takes effect.
///
/// A skip has to be decided while tests are declared: `markTestSkipped`
/// inside `setUpAll` only skips the `setUpAll` itself, and the tests after
/// it still run against an uninitialized library.
void runtimeSuite(
  void Function() body, {
  String? fixturePath,
  List<String> extraFixtures = const [],
  bool initialize = true,
}) {
  final reason = libmpvSkipReason(
    fixturePath: fixturePath,
    extraFixtures: extraFixtures,
  );
  if (reason != null) {
    group('libmpv', body, skip: reason);
    return;
  }
  if (initialize) setUpAll(initLibmpv);
  body();
}

/// Builds a [Player] wired for tests: no audio device, no auto-play,
/// no logs. Use when the test wants to drive `open()` itself (e.g.
/// dispose-during-load races, multi-fixture suites). Pass a custom
/// [configuration] to override the helper's defaults.
Future<Player> buildPlayer({PlayerConfiguration? configuration}) async {
  final player = Player(
    configuration:
        configuration ?? const PlayerConfiguration(logLevel: LogLevel.off),
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
