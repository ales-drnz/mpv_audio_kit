// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// MpvAudioKit.passthroughCodecs: what the plugin's channel reports on
// Android, and nothing anywhere else or when the channel fails.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('mpv_audio_kit/passthrough');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late List<String> calls;
  void answer(Object? Function() reply) {
    calls = [];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return reply();
    });
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('on Android the codecs of the channel, unknown ones dropped', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    answer(() => ['ac3', 'eac3', 'mlp']);
    expect(await MpvAudioKit.passthroughCodecs(), {Spdif.ac3, Spdif.eac3});
    expect(calls, ['codecs']);
  });

  test('on Android a failing channel gives no passthrough', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    answer(() => throw PlatformException(code: 'ERROR'));
    expect(await MpvAudioKit.passthroughCodecs(), isEmpty);
  });

  test('on Android a missing plugin gives no passthrough', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(channel, null);
    expect(await MpvAudioKit.passthroughCodecs(), isEmpty);
  });

  for (final platform in [
    TargetPlatform.iOS,
    TargetPlatform.macOS,
    TargetPlatform.linux,
    TargetPlatform.windows,
  ]) {
    test('on ${platform.name} no passthrough, the channel untouched', () async {
      debugDefaultTargetPlatformOverride = platform;
      answer(() => ['ac3']);
      expect(await MpvAudioKit.passthroughCodecs(), isEmpty);
      expect(calls, isEmpty);
    });
  }
}
