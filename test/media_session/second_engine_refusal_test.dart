// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A second Flutter engine of the process asks for the OS media session
// while another engine owns it. The native side, one per process, answers
// the enable with the error already_owned (Android, iOS, macOS, Windows,
// Linux). setMediaSession then throws StateError, as for a second Player
// of the same engine, and leaves the state off. Before, the channel
// swallowed the error and the Player believed it was on the lock screen.
//
// The channel tests need no libmpv. The Player tests drive the real mixin
// with the native side mocked at the channel, as
// set_media_session_race_test does.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

import '../_helpers/setter_test_helpers.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsControl = MethodChannel('mpv_audio_kit/media_session/commands');

/// Answers every method call on the media session channel with [reply],
/// recording the method names in [calls].
void _mockNative(
  List<String> calls,
  Future<Object?> Function(MethodCall call) reply,
) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    ..setMockMethodCallHandler(_methodChannel, (call) {
      calls.add(call.method);
      return reply(call);
    })
    ..setMockMethodCallHandler(_commandsControl, (call) async => null);
}

Future<Object?> _refuseEnable(MethodCall call) async {
  if (call.method == 'enable') {
    throw PlatformException(
      code: 'already_owned',
      message: 'Another Flutter engine of this process owns the media session.',
    );
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      ..setMockMethodCallHandler(_methodChannel, null)
      ..setMockMethodCallHandler(_commandsControl, null),
  );

  group('MediaSessionChannel', () {
    const metadata = MediaSessionMetadataSnapshot(title: 'Second');
    const playback = MediaSessionPlaybackSnapshot(
      playing: false,
      position: Duration.zero,
      rate: 1,
      seekable: false,
      loop: Loop.off,
      shuffle: false,
    );

    test('an enable refused as already_owned throws StateError', () async {
      _mockNative([], _refuseEnable);
      await expectLater(
        MediaSessionChannel().enable(
          session: const MediaSession(),
          metadata: metadata,
          playback: playback,
        ),
        throwsStateError,
      );
    });

    test('any other platform error is still swallowed', () async {
      _mockNative(
        [],
        (call) => Future.error(
          PlatformException(code: 'smtc_error', message: 'boom'),
        ),
      );
      final channel = MediaSessionChannel();
      await channel.enable(
        session: const MediaSession(),
        metadata: metadata,
        playback: playback,
      );
      await channel.updateMetadata(metadata);
      await channel.disable();
    });
  });

  runtimeSuite(() {
    late Player player;

    setUp(() async => player = await buildPlayer());
    tearDown(() => player.dispose());

    test(
      'setMediaSession throws StateError and leaves the session off',
      () async {
        final calls = <String>[];
        _mockNative(calls, _refuseEnable);

        await expectLater(
          player.setMediaSession(const MediaSession(title: 'Second engine')),
          throwsStateError,
        );
        expect(player.state.mediaSession, isNull);
        expect(calls, contains('enable'));
      },
    );

    test('the refused Player can publish once the session is free', () async {
      _mockNative([], _refuseEnable);
      await expectLater(
        player.setMediaSession(const MediaSession()),
        throwsStateError,
      );

      // The owner engine disabled: the next enable is accepted.
      final calls = <String>[];
      _mockNative(calls, (call) async => null);
      await player.setMediaSession(const MediaSession(title: 'Now mine'));
      expect(player.state.mediaSession?.title, 'Now mine');
      expect(calls, contains('enable'));
      await player.setMediaSession(null);
    });
  });
}
