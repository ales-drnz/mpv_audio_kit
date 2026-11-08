// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The playback push counts the pauses and stops the app makes, in
// `appPauses`. Android disarms the resume of a call when the count
// changes: during the call the player is already paused, so a pause of
// the app changes nothing else in the push, and the end of the call would
// play again. A pause or a stop the session sends, among them the pause
// of a focus loss, is not counted: that pause must keep the resume.
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

    Object? lastCount() => pushes.last['appPauses'];

    Future<void> sessionCommand(String type) async {
      await messenger.handlePlatformMessage(
        _commandsName,
        const StandardMethodCodec().encodeSuccessEnvelope({'type': type}),
        (_) {},
      );
      await settle();
    }

    test(
      'a pause of the app while paused is pushed with a new count',
      () async {
        expect(lastCount(), 0);
        expect(player.state.playback.playWhenReady, isFalse);
        final mark = pushes.length;
        await player.pause();
        await settle();
        expect(
          pushes.length,
          greaterThan(mark),
          reason: 'a push even unchanged',
        );
        expect(lastCount(), 1);
        expect(pushes.last['playing'], isFalse);
        await player.pause();
        await settle();
        expect(lastCount(), 2);
      },
    );

    test('a stop of the app is counted too', () async {
      await player.stop();
      await settle();
      expect(lastCount(), 1);
    });

    test('a pause or a stop of the session is not counted', () async {
      await player.pause();
      await settle();
      expect(lastCount(), 1);
      // The pause Android sends for a focus loss, and a stop.
      await sessionCommand('pause');
      await sessionCommand('stop');
      await player.setRate(1.25);
      await settle();
      expect(pushes.map((p) => p['appPauses']).toSet(), {0, 1});
      expect(lastCount(), 1);
    });
  });
}

/// Lets the microtask flush and the mpv round trips settle.
Future<void> settle() =>
    Future<void>.delayed(const Duration(milliseconds: 300));
