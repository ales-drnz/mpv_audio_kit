// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// F170 on Android: the process outlives the isolates that create players.
// An isolate that exits without disposing its players left them playing,
// with nobody to stop them. Now each owner is watched, and its players
// free their core when it exits: the output thread of mpv goes away.
//
// Here the owner is a spawned isolate; android_engine_exit_test covers the
// root isolate of a destroyed engine. Skipped off Android.

import 'dart:io' show Platform;
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/device_probes.dart';

/// Plays [args] (the fixture path) looped on audiotrack, tells the test,
/// waits for its go and exits without dispose.
Future<void> _ownPlayer(List<Object?> args) async {
  final reply = args[0]! as SendPort;
  final path = args[1]! as String;
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
  final go = ReceivePort();
  reply.send(go.sendPort);
  await go.first;
  Isolate.exit();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android players of an isolate that exits', () {
    if (!Platform.isAndroid) return;

    testWidgets('a playing player whose isolate exits without dispose '
        'stops (F170)', (_) async {
      expect(
        threadExists(audiotrackThread),
        isFalse,
        reason: 'no other output is open',
      );
      final path = await materializeFixture('sine_440hz_1s.wav');
      final ready = ReceivePort();
      final exited = ReceivePort();
      await Isolate.spawn(_ownPlayer, [
        ready.sendPort,
        path,
      ], onExit: exited.sendPort);
      final go =
          await ready.first.timeout(const Duration(seconds: 30)) as SendPort;
      expect(
        threadExists(audiotrackThread),
        isTrue,
        reason: 'the player of the isolate plays on audiotrack',
      );
      go.send(null);
      await exited.first.timeout(const Duration(seconds: 10));

      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (threadExists(audiotrackThread)) {
        if (DateTime.now().isAfter(deadline)) {
          fail('the output still plays 5 s after its isolate exited');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
