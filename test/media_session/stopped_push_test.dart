// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The playback push carries `stopped` after a stop, of the app or of
// the session, until a load starts or the play intent turns on: MPRIS
// reports `Stopped` from it on Linux.
//
// The native side is mocked at the platform-channel boundary. A real
// Player drives the production path, so libmpv on the host is required.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsName = 'mpv_audio_kit/media_session/commands';
const _commandsControl = MethodChannel(_commandsName);

void main() {
  runtimeSuite(() {
    late Player player;
    late TestDefaultBinaryMessenger messenger;
    final pushes = <Map<Object?, Object?>>[];

    setUp(() async {
      pushes.clear();
      messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(_methodChannel, (call) async {
        if (call.method == 'updatePlayback') {
          pushes.add(call.arguments as Map<Object?, Object?>);
        } else if (call.method == 'enable') {
          final args = call.arguments as Map<Object?, Object?>;
          pushes.add(args['playback']! as Map<Object?, Object?>);
        }
        return null;
      });
      messenger.setMockMethodCallHandler(_commandsControl, (_) async => null);
      player = await buildPlayer();
      await player.setMediaSession(const MediaSession());
      await settle();
    });

    tearDown(() async {
      await player.dispose();
      messenger.setMockMethodCallHandler(_methodChannel, null);
      messenger.setMockMethodCallHandler(_commandsControl, null);
    });

    Object? lastStopped() => pushes.last['stopped'];

    Future<void> sessionCommand(String type) async {
      await messenger.handlePlatformMessage(
        _commandsName,
        const StandardMethodCodec().encodeSuccessEnvelope({'type': type}),
        (_) {},
      );
      await settle();
    }

    test('a stop of the app is pushed as stopped', () async {
      await player.open(Media(defaultFixturePath()), play: true);
      await waitUntil(() => player.state.playback.playing);
      await settle();
      expect(lastStopped(), isFalse);
      await player.stop();
      await settle();
      expect(lastStopped(), isTrue);
    });

    test('a stop of the session is pushed as stopped', () async {
      await player.open(Media(defaultFixturePath()), play: true);
      await waitUntil(() => player.state.playback.playing);
      await sessionCommand('stop');
      expect(lastStopped(), isTrue);
    });

    test('a load after the stop clears it', () async {
      await player.open(Media(defaultFixturePath()), play: true);
      await waitUntil(() => player.state.playback.playing);
      await player.stop();
      await settle();
      expect(lastStopped(), isTrue);
      await player.open(Media(defaultFixturePath()), play: false);
      await settle();
      expect(lastStopped(), isFalse);
    });

    test('play() after a kept stop clears it', () async {
      await player.openAll([
        Media(defaultFixturePath()),
        Media(defaultFixturePath()),
      ], play: true);
      await waitUntil(() => player.state.playback.playing);
      await player.stop(keepPlaylist: true);
      await settle();
      expect(lastStopped(), isTrue);
      await player.play();
      await waitUntil(() => player.state.playback.playing);
      await settle();
      expect(lastStopped(), isFalse);
      expect(pushes.last['playing'], isTrue);
    });
  });
}

/// Lets the microtask flush and the mpv round trips settle.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));
