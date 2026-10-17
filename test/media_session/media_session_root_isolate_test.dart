// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// setMediaSession needs the root isolate: the OS sends its commands only
// there, and the platform channels of another isolate fail. Called from
// another isolate it used to write the owner and the state first, then
// fail inside the controller: an unhandled error from the command channel
// killed the isolate, and a controller nobody could dispose kept failing
// at every push (F293). A create that fails in the root isolate left the
// same leftovers.

import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

const _methodName = 'mpv_audio_kit/media_session';
const _commandsControl = MethodChannel('mpv_audio_kit/media_session/commands');

void main() {
  runtimeSuite(() {
    test('setMediaSession from another isolate throws a StateError and '
        'leaves no session', () async {
      // The flutter test isolate is a root isolate: the guard lets it in.
      expect(RootIsolateToken.instance, isNotNull);

      final outcome = await Isolate.run(() async {
        MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );
        try {
          await player.setMediaSession(const MediaSession());
          return 'no error';
        } on StateError {
          // The session is still free: a null is allowed anywhere.
          await player.setMediaSession(null);
          return 'StateError, mediaSession ${player.state.mediaSession}';
        } finally {
          await player.dispose();
        }
      });
      expect(outcome, 'StateError, mediaSession null');
    }, timeout: const Timeout(Duration(seconds: 45)));

    test(
      'a failed create leaves no owner, no state and no controller',
      () async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        const codec = StandardMethodCodec();
        final calls = <String>[];
        // An empty reply to `enable` is not an envelope: the decoding error
        // reaches create, as no PlatformException would.
        messenger.setMockMessageHandler(_methodName, (message) async {
          final method = codec.decodeMethodCall(message).method;
          calls.add(method);
          return method == 'enable'
              ? ByteData(0)
              : codec.encodeSuccessEnvelope(null);
        });
        messenger.setMockMethodCallHandler(_commandsControl, (_) async => null);
        final player = await buildPlayer();
        Player? other;
        addTearDown(() async {
          await other?.dispose();
          await player.dispose();
          messenger.setMockMessageHandler(_methodName, null);
          messenger.setMockMethodCallHandler(_commandsControl, null);
        });

        await expectLater(
          player.setMediaSession(const MediaSession()),
          throwsA(isA<FormatException>()),
        );
        expect(player.state.mediaSession, isNull);
        expect(calls.last, 'disable', reason: 'calls: $calls');

        // No controller is left to push the next change.
        final mark = calls.length;
        await player.setRate(1.5);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(calls.sublist(mark), isEmpty);

        // And the session is free for another Player.
        other = await buildPlayer();
        messenger.setMockMessageHandler(
          _methodName,
          (_) async => codec.encodeSuccessEnvelope(null),
        );
        await other.setMediaSession(const MediaSession());
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}
