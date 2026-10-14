// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// MediaSession.interruptionPolicy on its way to the native side: the
// Swift and Kotlin plugins read the wire name, so a renamed value would
// silently fall back to their default.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

const _channel = MethodChannel('mpv_audio_kit/media_session');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (call) async {
          calls.add(call);
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('the default is pauseAndResume', () {
    expect(
      const MediaSession().interruptionPolicy,
      InterruptionPolicy.pauseAndResume,
    );
  });

  test('copyWith changes the policy and equality sees it', () {
    const base = MediaSession();
    final keep = base.copyWith(
      interruptionPolicy: InterruptionPolicy.keepPlaying,
    );
    expect(keep.interruptionPolicy, InterruptionPolicy.keepPlaying);
    expect(keep, isNot(base));
    expect(keep.copyWith(), keep);
  });

  for (final policy in InterruptionPolicy.values) {
    test('$policy reaches the native config by its wire name', () async {
      await MediaSessionChannel().updateConfig(
        MediaSession(interruptionPolicy: policy),
      );
      final args = calls.single.arguments as Map<Object?, Object?>;
      expect(calls.single.method, 'updateConfig');
      expect(args['interruptionPolicy'], policy.name);
    });
  }

  test('the wire names are the ones the native plugins read', () {
    expect(InterruptionPolicy.values.map((p) => p.name), [
      'pauseAndResume',
      'pauseOnly',
      'keepPlaying',
    ]);
  });
}
