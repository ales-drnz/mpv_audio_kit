// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// A pause that comes from outside the app, in one table: what paused
// (the browser, a call, the app, the OS controls) by the interruption
// policy of the session, on the Dart side. The web's outside pause was
// touched in three releases in a row (0.6.0, 0.6.2, 0.7.0), a case at a
// time; outside_pause_test.dart has those cases on each class alone.
//
// The first table runs the two classes of the web session together, as
// web_audio.dart and mpv_audio_kit_web.dart wire them (_Page): the events
// of the `<audio>` element go through OutsideElementWatch, what it tells
// from outside goes through OutsidePauseFollower, and the player takes
// the command. The second is the count of the app's own pauses in the
// playback push, which tells the native side whose pause it was (Android
// disarms the resume of a call on it): the same under every policy.
//
// VM only. The element in a browser is in test/web/web_audio_test.dart,
// the Android side in android/src/test (InterruptionLogicTest,
// AudioFocusControllerTest).

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_controller.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_inputs.dart';
import 'package:mpv_audio_kit/src/media_session/outside_pause.dart';

/// The page of a web session: the element, the output that plays it, and
/// the player behind the session.
final class _Page {
  _Page(InterruptionPolicy policy) {
    follower.policy = policy;
    // The page starts playing: the context runs, the output plays the
    // element at a gesture, and the app plays.
    context('running');
    appPlays();
  }

  final OutsideElementWatch watch = OutsideElementWatch();
  final OutsidePauseFollower follower = OutsidePauseFollower();

  /// The play intent in the last playback push of the session.
  bool playing = false;
  bool elementPaused = true;

  /// The commands the session sent the player.
  final List<String> commands = [];

  // The session's _onOutside, and the player taking the command.
  void _outside(bool elementPlaying) {
    final type = follower.onOutside(
      elementPlaying: elementPlaying,
      playing: playing,
    );
    if (type == null) return;
    commands.add(type);
    _pushed(type == 'play');
  }

  // The session's updatePlayback: a playing player ends an outside pause.
  void _pushed(bool value) {
    playing = value;
    if (value) follower.reset();
  }

  void _elementPlays() {
    // play() on a playing element fires no event.
    if (!elementPaused) return;
    elementPaused = false;
    if (watch.onPlaying()) _outside(true);
  }

  /// player.play() and player.pause(): the element goes on either way.
  void appPlays() => _pushed(true);
  void appPauses() => _pushed(false);

  /// A pause on the controls of the OS (the session's _onAction).
  void controlsPause() {
    follower.reset();
    _pushed(false);
  }

  /// The output calls play() on the element (at a gesture, or when the
  /// context runs), which the browser may refuse.
  void outputPlays({bool refused = false}) {
    watch.onOutputPlay(elementPaused: elementPaused);
    if (refused) return watch.onPlayRefused();
    _elementPlays();
  }

  /// The browser pauses the element, or plays it again, by itself.
  void browserPauses() {
    if (elementPaused) return;
    elementPaused = true;
    if (watch.onPause()) _outside(false);
  }

  void browserPlays() => _elementPlays();

  /// The context's new state.
  void context(String state, {bool refused = false}) {
    if (watch.onContextState(state)) outputPlays(refused: refused);
  }
}

typedef _Case = ({
  String origin,
  void Function(_Page) run,

  /// The commands under pauseAndResume, pauseOnly and keepPlaying.
  List<String> resume,
  List<String> pauseOnly,
  List<String> keep,
});

final List<_Case> _table = [
  (
    origin: 'the browser pauses the element, then plays it',
    run: (p) => p
      ..browserPauses()
      ..browserPlays(),
    resume: ['pause', 'play'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'a call interrupts the context, then ends',
    run: (p) => p
      ..context('interrupted')
      ..browserPauses()
      ..context('running'),
    resume: ['pause', 'play'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'a call ends with the play refused, a gesture plays the element',
    run: (p) => p
      ..context('interrupted')
      ..browserPauses()
      ..context('running', refused: true)
      ..outputPlays(),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'the context is suspended, then runs again',
    run: (p) => p
      ..context('suspended')
      ..browserPauses()
      ..context('running'),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'the browser pauses and plays the element twice',
    run: (p) => p
      ..browserPauses()
      ..browserPlays()
      ..browserPauses()
      ..browserPlays(),
    resume: ['pause', 'play', 'pause', 'play'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'the app pauses, then the browser pauses and plays the element',
    run: (p) => p
      ..appPauses()
      ..browserPauses()
      ..browserPlays(),
    resume: [],
    pauseOnly: [],
    keep: [],
  ),
  (
    origin: 'the browser pauses, the app plays at a gesture',
    run: (p) => p
      ..browserPauses()
      ..appPlays()
      ..outputPlays(),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'the browser pauses, the app plays, the browser plays the element',
    run: (p) => p
      ..browserPauses()
      ..appPlays()
      ..browserPlays(),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin: 'the browser pauses, the OS controls pause, the browser plays',
    run: (p) => p
      ..browserPauses()
      ..controlsPause()
      ..browserPlays(),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
  (
    origin:
        'the browser pauses, a gesture plays the element with the player '
        'left paused, the browser pauses and plays again',
    run: (p) => p
      ..browserPauses()
      ..outputPlays()
      ..browserPauses()
      ..browserPlays(),
    resume: ['pause'],
    pauseOnly: ['pause'],
    keep: [],
  ),
];

/// The playback pushes of a controller, by their play intent and count of
/// the app's pauses.
final class _Pushes extends MediaSessionChannel {
  final List<(bool playing, int appPauses)> playback = [];

  @override
  Stream<MediaSessionCommand> get commandStream => const Stream.empty();

  @override
  Stream<void> get audioOutputResets => const Stream.empty();

  @override
  Future<bool> enable({
    required MediaSession session,
    required MediaSessionMetadataSnapshot metadata,
    required MediaSessionPlaybackSnapshot playback,
  }) async => true;

  @override
  Future<void> updateConfig(MediaSession session) async {}

  @override
  Future<void> updateMetadata(MediaSessionMetadataSnapshot metadata) async {}

  @override
  Future<void> updatePlayback(MediaSessionPlaybackSnapshot playback) async =>
      this.playback.add((playback.playing, playback.appPauses));

  @override
  Future<void> disable() async {}
}

void main() {
  for (final policy in InterruptionPolicy.values) {
    group('under ${policy.name}', () {
      for (final row in _table) {
        test(row.origin, () {
          final page = _Page(policy);
          expect(page.commands, isEmpty, reason: 'the page starts playing');
          row.run(page);
          final expected = switch (policy) {
            InterruptionPolicy.pauseAndResume => row.resume,
            InterruptionPolicy.pauseOnly => row.pauseOnly,
            InterruptionPolicy.keepPlaying => row.keep,
          };
          expect(page.commands, expected);
        });
      }
    });
  }

  test('no policy ever plays a player the outside did not pause', () {
    // Every row, every policy: a play is sent only right after a pause
    // the session sent, and only under pauseAndResume.
    for (final policy in InterruptionPolicy.values) {
      for (final row in _table) {
        final page = _Page(policy);
        row.run(page);
        final reason = '${policy.name}: ${row.origin}';
        for (var i = 0; i < page.commands.length; i++) {
          expect(page.commands[i], i.isEven ? 'pause' : 'play', reason: reason);
        }
        if (policy != InterruptionPolicy.pauseAndResume) {
          expect(page.commands, isNot(contains('play')), reason: reason);
        }
      }
    }
  });

  group('the policy changes during the outside pause', () {
    List<String> run(InterruptionPolicy from, InterruptionPolicy to) {
      final page = _Page(from)..browserPauses();
      page.follower.policy = to;
      page.browserPlays();
      return page.commands;
    }

    const resume = InterruptionPolicy.pauseAndResume;
    const pauseOnly = InterruptionPolicy.pauseOnly;
    const keep = InterruptionPolicy.keepPlaying;

    test('the policy at the end decides the play', () {
      expect(run(resume, pauseOnly), ['pause']);
      expect(run(resume, keep), ['pause']);
      expect(run(pauseOnly, resume), [
        'pause',
      ], reason: 'that pause armed none');
      expect(run(keep, resume), isEmpty, reason: 'nothing was paused');
      expect(run(keep, pauseOnly), isEmpty);
    });
  });

  group('whose pause it was, in the playback push', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const real = MethodChannel('mpv_audio_kit/media_session');
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(real, (_) async => null);
    });
    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(real, null);
    });

    for (final policy in InterruptionPolicy.values) {
      test('${policy.name}: only a pause of the app moves the count', () async {
        final pushes = _Pushes();
        final intent = StreamController<bool>.broadcast();
        final never = StreamController<Never>.broadcast();
        var playing = true;
        final controller = await MediaSessionController.create(
          stateSnapshot: () => PlayerState(
            playback: PlaybackState(playWhenReady: playing),
            settings: PlayerSettings(
              mediaSession: MediaSession(interruptionPolicy: policy),
            ),
          ),
          inputs: MediaSessionInputs(
            playWhenReady: intent.stream,
            playing: never.stream.cast(),
            buffering: never.stream.cast(),
            rate: never.stream.cast(),
            seekCompleted: never.stream.cast(),
            seekable: never.stream.cast(),
            loop: never.stream.cast(),
            shuffle: never.stream.cast(),
            duration: never.stream.cast(),
            metadata: never.stream.cast(),
            coverArt: never.stream.cast(),
            mediaTitle: never.stream.cast(),
            mediaSession: never.stream.cast(),
          ),
          onCommand: (_) {},
          channel: pushes,
        );
        addTearDown(() async {
          await controller.dispose();
          await intent.close();
          await never.close();
        });

        // A pause the session sent (a command of the OS, a focus loss, the
        // web's outside pause): the intent goes off, the count stays.
        playing = false;
        intent.add(false);
        await pumpEventQueue();
        expect(pushes.playback, [(false, 0)]);

        // A pause of the app while paused: nothing changes but the count,
        // and the push still goes.
        controller.appPaused();
        await pumpEventQueue();
        expect(pushes.playback.last, (false, 1));
        expect(pushes.playback, hasLength(2));

        // The resume the native side asks for at the end of the call.
        playing = true;
        intent.add(true);
        await pumpEventQueue();
        expect(pushes.playback.last, (true, 1));

        // A pause of the app while playing: the intent and the count.
        playing = false;
        controller.appPaused();
        intent.add(false);
        await pumpEventQueue();
        expect(pushes.playback.last, (false, 2));
      });
    }
  });
}
