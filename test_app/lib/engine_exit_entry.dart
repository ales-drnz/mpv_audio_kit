// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The Dart side of the second engine of android_engine_exit_test, started
// by MainActivity on the channel `mpv_audio_kit_test_app/engine`.
// [engineExitMain] plays the fixture the test hands over on
// [engineExitPortName], tells the test, and keeps playing until the test
// destroys the engine. [engineSessionMain] asks for the OS media session
// the test's engine may own, each time the test says so.

import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// The name the test registers its port under.
const engineExitPortName = 'mpv_audio_kit_test_app/engine_exit';

/// The entrypoint MainActivity runs in the second engine.
@pragma('vm:entry-point')
Future<void> engineExitMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final test = IsolateNameServer.lookupPortByName(engineExitPortName);
  if (test == null) return;
  final inbox = ReceivePort();
  test.send(inbox.sendPort);
  final path = await inbox.first as String;
  try {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
    final player = Player();
    await player.setVolume(0);
    await player.setLoop(Loop.file);
    await player.open(Media(path), play: true);
    await player.stream.currentAo
        .firstWhere((ao) => ao == 'audiotrack')
        .timeout(const Duration(seconds: 10));
    await player.stream.position
        .firstWhere((p) => p > const Duration(milliseconds: 300))
        .timeout(const Duration(seconds: 10));
    test.send('playing');
  } catch (e) {
    test.send('failed: $e');
  }
  // The player is never disposed: the engine goes away under it.
}

/// The name the media session test registers its port under.
const engineSessionPortName = 'mpv_audio_kit_test_app/engine_session';

/// The entrypoint of the second engine of the media session test. On each
/// 'enable' from the test it calls setMediaSession and answers 'accepted',
/// 'refused' (a StateError, with the state left off) or what went wrong.
@pragma('vm:entry-point')
Future<void> engineSessionMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  final test = IsolateNameServer.lookupPortByName(engineSessionPortName);
  if (test == null) return;
  final inbox = ReceivePort();
  test.send(inbox.sendPort);
  MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  final player = Player();
  await for (final message in inbox) {
    if (message != 'enable') continue;
    try {
      await player.setMediaSession(const MediaSession(title: 'Second engine'));
      test.send('accepted');
    } on StateError {
      test.send(
        player.state.mediaSession == null ? 'refused' : 'refused, state kept',
      );
    } catch (e) {
      test.send('failed: $e');
    }
  }
}
