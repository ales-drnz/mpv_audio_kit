// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The names of MediaAction on the wire. The native plugins read them as
// strings (Android: MediaSessionMappers.buildCommands, whose JVM test,
// android/src/test/.../MediaSessionMappersTest.kt, has the same list): a
// renamed value would silently drop its command there.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

const _channel = MethodChannel('mpv_audio_kit/media_session');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the wire names are the ones the native plugins read', () {
    expect(MediaAction.values.map((a) => a.name), [
      'play',
      'pause',
      'playPause',
      'stop',
      'next',
      'previous',
      'seek',
      'fastForward',
      'rewind',
      'setRepeatMode',
      'setShuffle',
      'setPlaybackRate',
      'like',
    ]);
  });

  test('the config carries the actions by name, in the order given', () async {
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(_channel, null));

    // The order is the priority of the buttons on Android.
    const actions = [
      MediaAction.like,
      MediaAction.rewind,
      MediaAction.play,
      MediaAction.setShuffle,
    ];
    await MediaSessionChannel().updateConfig(
      MediaSession(actions: actions.toSet()),
    );
    final args = calls.single.arguments as Map<Object?, Object?>;
    expect(args['actions'], ['like', 'rewind', 'play', 'setShuffle']);
  });
}
