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
/// [fixturePath], [extraFixtures] and the mpv [properties] of this build)
/// can't run on this host, or `null` when it can.
String? libmpvSkipReason({
  String? fixturePath,
  List<String> extraFixtures = const [],
  List<String> properties = const [],
}) {
  final lib = resolveLibmpv();
  if (lib == null) {
    return 'no bundled libmpv (did the build hook run?)';
  }
  for (final path in [?fixturePath, ...extraFixtures]) {
    if (!File(path).existsSync()) return 'Fixture missing: $path';
  }
  for (final name in properties) {
    if (!libmpvNamesProperty(lib, name)) return 'libmpv has no $name';
  }
  return null;
}

/// Initializes [MpvAudioKit] against the bundled libmpv, with the
/// hot-restart tracker disabled (its per-process buffer is incompatible
/// with `flutter test`'s isolate reuse). Only call it when
/// [libmpvSkipReason] returned `null`.
void initLibmpv() {
  // Brings up the Flutter test binding so `rootBundle.load` works —
  // `asset://` URIs are materialised through `rootBundle` by the URI
  // resolver, which needs the binding initialised first.
  TestWidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
}

/// Declares a suite that needs the bundled libmpv. When libmpv, any
/// fixture or any of the mpv [properties] is missing, every test in
/// [body] is registered as skipped with the reason; otherwise a
/// `setUpAll` initializes [MpvAudioKit] before [body]'s own setup runs.
/// Pass `initialize: false` for a suite that initializes [MpvAudioKit]
/// itself (e.g. through a shim), since only the first
/// `ensureInitialized` call takes effect.
///
/// A skip has to be decided while tests are declared: `markTestSkipped`
/// inside `setUpAll` only skips the `setUpAll` itself, and the tests after
/// it still run against an uninitialized library.
void runtimeSuite(
  void Function() body, {
  String? fixturePath,
  List<String> extraFixtures = const [],
  List<String> properties = const [],
  bool initialize = true,
}) {
  final reason = libmpvSkipReason(
    fixturePath: fixturePath,
    extraFixtures: extraFixtures,
    properties: properties,
  );
  if (reason != null) {
    // On CI the library and the fixtures are always there: a missing one
    // means the hook or its output path changed, and skipping would leave
    // the runtime suites silently out of the run.
    if (Platform.environment['CI'] == 'true') {
      test('libmpv and fixtures are available', () => fail(reason));
      return;
    }
    group('libmpv', body, skip: reason);
    return;
  }
  if (initialize) setUpAll(initLibmpv);
  body();
}

/// Why the tests of a fix that ships in libmpv-r[release] cannot run on the
/// bundled libmpv, or `null` when they can (or when there is no libmpv,
/// which [runtimeSuite] reports). Unlike a missing fixture this is no
/// failure on CI: the package pins an older release until the bump, and
/// the tests start running with the bump itself.
String? needsLibmpvRelease(int release) {
  final lib = resolveLibmpv();
  if (lib == null) return null;
  final found = libmpvReleaseOf(lib);
  if (found != null && found >= release) return null;
  return 'tests a fix of libmpv-r$release, the bundled libmpv is '
      '${found == null ? 'not a libmpv-scripts build' : 'r$found'}';
}

/// A [group] of tests for the patches of libmpv-r[release]: skipped with
/// the reason of [needsLibmpvRelease] on an older libmpv.
void libmpvReleaseGroup(
  int release,
  String description,
  void Function() body,
) => group(description, body, skip: needsLibmpvRelease(release));

/// [runtimeSuite] for a suite that needs this build's analysis properties,
/// `waveform-data` and `loudness-scan-data`.
void analysisSuite(
  void Function() body, {
  String? fixturePath,
  List<String> extraFixtures = const [],
}) => runtimeSuite(
  body,
  fixturePath: fixturePath,
  extraFixtures: extraFixtures,
  properties: const ['waveform-data', 'loudness-scan-data'],
);

/// Skips the running test because something it needs is missing (the
/// bundled libmpv, a fixture, a property of the binary), or fails it with
/// CI=true: on CI all of them are always there, and a skip would leave the
/// test silently out of the run.
void skipMissing(String reason) {
  if (Platform.environment['CI'] == 'true') fail(reason);
  markTestSkipped(reason);
}

/// The real audio outputs of the desktop hosts, for a test that needs a
/// device: the null output ignores `audio-buffer` and has no volume.
const realAudioOutputs = 'pipewire,pulse,alsa,coreaudio,wasapi';

/// The output mpv opens on this host for [realAudioOutputs]: `'null'` (or
/// `null`) when none of them has a device and mpv fell back to null. Plays
/// the default fixture muted until the output is open.
Future<String?> probeAudioOutput() async {
  final player = await buildPlayer();
  try {
    await player.setRawProperty('ao', realAudioOutputs);
    await player.setVolume(0);
    await player.open(Media(defaultFixturePath()), play: true);
    final deadline = DateTime.now().add(const Duration(seconds: 5));
    while (true) {
      final ao = await player.getRawProperty('current-ao');
      if (ao != null || DateTime.now().isAfter(deadline)) return ao;
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  } finally {
    await player.dispose();
  }
}

/// Skips the running test because the host has no audio device. The Linux
/// CI job runs a PulseAudio null sink, so there a missing device means the
/// sink broke, and the test fails. Other runners may have no device.
void skipWithoutAudioDevice(String reason) {
  if (Platform.environment['CI'] == 'true' && Platform.isLinux) fail(reason);
  markTestSkipped(reason);
}

/// The single stage of type [T] in [player]'s effects chain.
T effectOf<T extends AudioEffect>(Player player) =>
    player.state.audioEffects.whereType<T>().single;

/// Replaces the stage of [effect]'s type in [player]'s effects chain, or
/// appends it when the chain has none.
Future<void> putEffect<T extends AudioEffect>(Player player, T effect) =>
    player.updateAudioEffects((fx) {
      final i = fx.indexWhere((e) => e is T);
      return i < 0 ? [...fx, effect] : ([...fx]..[i] = effect);
    });

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

/// Reads mpv's own value of [name] and expects [expected], after a setter
/// that converts units on the way (bytes, a [Duration] in seconds). The
/// state takes the value the test passed before mpv sees the write, so
/// only this read catches a conversion that went wrong. An int is matched
/// exactly; a double, such as seconds, to the 6 decimals mpv prints.
Future<void> expectMpv(Player player, String name, num expected) async {
  final raw = await player.getRawProperty(name);
  final reason = 'mpv holds $name = $raw';
  if (expected is int) {
    expect(int.tryParse(raw ?? ''), expected, reason: reason);
  } else {
    expect(double.tryParse(raw ?? ''), closeTo(expected, 1e-6), reason: reason);
  }
}

/// Polls [condition] every [interval] until it holds, and fails the test
/// with [reason] when it still does not after [timeout]. Use it in place
/// of a fixed delay before asserting a state that mpv reaches
/// asynchronously: it returns as soon as the state lands, and waits
/// longer under a loaded suite instead of flaking.
Future<void> waitUntil(
  FutureOr<bool> Function() condition, {
  Duration timeout = const Duration(seconds: 5),
  Duration interval = const Duration(milliseconds: 20),
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!await condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail(reason ?? 'condition not met within $timeout');
    }
    await Future<void>.delayed(interval);
  }
}
