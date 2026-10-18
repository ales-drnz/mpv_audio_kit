// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// F170 on Android, for an engine: Back on the root route or a swipe from
// the recent apps destroys the Flutter engine, and its root isolate, while
// the process stays. The players that isolate created kept playing. Now
// the engine's root isolate is watched like any owner, and its players
// free their core when the engine shuts it down.
//
// MainActivity starts a second engine on `engineExitMain`
// (lib/engine_exit_entry.dart), which plays a fixture and never disposes
// its player; the test destroys that engine and waits for mpv's output
// thread to go. Skipped off Android.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit_test_app/engine_exit_entry.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/device_probes.dart';

const _engine = MethodChannel('mpv_audio_kit_test_app/engine');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android players of a destroyed engine', () {
    if (!Platform.isAndroid) return;

    testWidgets('a player of an engine destroyed while it plays stops '
        '(F170)', (_) async {
      expect(
        threadExists(audiotrackThread),
        isFalse,
        reason: 'no other output is open',
      );
      final path = await materializeFixture('sine_440hz_1s.wav');
      final inbox = ReceivePort();
      IsolateNameServer.removePortNameMapping(engineExitPortName);
      IsolateNameServer.registerPortWithName(
        inbox.sendPort,
        engineExitPortName,
      );
      addTearDown(() {
        IsolateNameServer.removePortNameMapping(engineExitPortName);
        inbox.close();
      });
      final messages = StreamIterator<Object?>(inbox);
      await _engine.invokeMethod<void>('start', {
        'library': 'package:mpv_audio_kit_test_app/engine_exit_entry.dart',
        'function': 'engineExitMain',
      });
      addTearDown(() => _engine.invokeMethod<void>('destroy'));

      expect(
        await messages.moveNext().timeout(const Duration(seconds: 30)),
        isTrue,
      );
      (messages.current! as SendPort).send(path);
      expect(
        await messages.moveNext().timeout(const Duration(seconds: 30)),
        isTrue,
      );
      expect(messages.current, 'playing');
      expect(
        threadExists(audiotrackThread),
        isTrue,
        reason: 'the player of the second engine plays on audiotrack',
      );

      await _engine.invokeMethod<void>('destroy');
      final deadline = DateTime.now().add(const Duration(seconds: 5));
      while (threadExists(audiotrackThread)) {
        if (DateTime.now().isAfter(deadline)) {
          fail('the output still plays 5 s after its engine was destroyed');
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
