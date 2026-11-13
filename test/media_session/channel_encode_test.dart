// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// Tests the Dart → native direction: what `MediaSessionChannel` writes on
// the method channel, read back through the real codec by a mock handler.
// The native sides read these maps by key and by type.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';

const _methodChannel = MethodChannel('mpv_audio_kit/media_session');

const _playback = MediaSessionPlaybackSnapshot(
  playing: false,
  position: Duration.zero,
  rate: 1,
  seekable: false,
  loop: Loop.off,
  shuffle: false,
);

/// The arguments of the `enable` the channel sends for [session] and
/// [metadata], as the native side decodes them.
Future<Map<Object?, Object?>> _enableArguments({
  MediaSession session = const MediaSession(),
  MediaSessionMetadataSnapshot metadata = const MediaSessionMetadataSnapshot(),
}) async {
  Object? sent;
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_methodChannel, (call) async {
        if (call.method == 'enable') sent = call.arguments;
        return null;
      });
  await MediaSessionChannel().enable(
    session: session,
    metadata: metadata,
    playback: _playback,
  );
  return sent! as Map<Object?, Object?>;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_methodChannel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('supportedPlaybackRates crosses as a plain list, whatever list the '
      'app gave', () async {
    // A Float64List is a List<double>, and the codec writes it as typed
    // data: the native sides read a list of doubles and would fall back to
    // their default rates.
    final sent = await _enableArguments(
      session: MediaSession(
        supportedPlaybackRates: Float64List.fromList([1, 1.5]),
      ),
    );
    final rates = (sent['config']! as Map)['supportedPlaybackRates'];
    expect(rates, isNot(isA<TypedData>()));
    expect(rates, [1.0, 1.5]);
  });
}
