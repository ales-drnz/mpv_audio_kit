// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A reset of the audio output that the OS reports to a player without a
// core. The native side is mocked at the platform-channel boundary. No
// libmpv is needed: the player fails to start on purpose.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');
const _commandsName = 'mpv_audio_kit/media_session/commands';
const _commandsControl = MethodChannel(_commandsName);

void main() {
  late TestDefaultBinaryMessenger messenger;

  /// Answers every call of the two channels.
  void mockChannels() {
    messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_methodChannel, (call) async {
      return null;
    });
    messenger.setMockMethodCallHandler(_commandsControl, (_) async => null);
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(_methodChannel, null);
    messenger.setMockMethodCallHandler(_commandsControl, null);
  });

  // The session does not wait for the core: it exists before the player
  // has started, and stays when it could not start. A reset of the output
  // then found no core to send `ao-reload` to.
  test('an output reset on a player that could not start is logged, not '
      'thrown', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    MpvAudioKit.ensureInitialized(
      libmpv: '/nonexistent/libmpv_audio_kit.so',
      hotRestartCleanup: false,
    );
    mockChannels();
    final errors = <Object>[];
    final logs = <String>[];
    final done = Completer<void>();
    unawaited(
      runZonedGuarded(() async {
        final player = Player();
        player.stream.internalLog.listen((e) => logs.add(e.text));
        await player.setMediaSession(const MediaSession());
        try {
          await player.ready;
        } catch (_) {}
        await messenger.handlePlatformMessage(
          _commandsName,
          const StandardMethodCodec().encodeSuccessEnvelope({
            'type': 'reloadAudioOutput',
          }),
          (_) {},
        );
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await player.dispose();
        done.complete();
      }, (e, _) => errors.add(e)),
    );
    await done.future.timeout(const Duration(seconds: 20));
    expect(errors, isEmpty);
    expect(
      logs.where((l) => l.contains('Media-session command failed')),
      hasLength(1),
    );
  });
}
