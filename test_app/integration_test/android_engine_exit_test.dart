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
// thread to go.
//
// The OS media session is one per process (P4.1): a second engine started
// on `engineSessionMain` asks for it while the test's engine owns it. The
// enable is refused, setMediaSession throws StateError there, and the
// first engine's entry stays, also when the second engine goes. Once the
// first turns it off, a new second engine takes it, and its destruction
// turns it off. Skipped off Android.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit_test_app/engine_exit_entry.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/device_probes.dart';
import '_helpers/session_probe.dart';

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

  group('Android media session with two engines', () {
    if (!Platform.isAndroid) return;

    /// Starts a second engine on `engineSessionMain` and returns its port
    /// and the answers it sends.
    Future<(SendPort, StreamIterator<Object?>)> startSecond() async {
      final inbox = ReceivePort();
      IsolateNameServer.removePortNameMapping(engineSessionPortName);
      IsolateNameServer.registerPortWithName(
        inbox.sendPort,
        engineSessionPortName,
      );
      addTearDown(() {
        IsolateNameServer.removePortNameMapping(engineSessionPortName);
        inbox.close();
      });
      final answers = StreamIterator<Object?>(inbox);
      await _engine.invokeMethod<void>('start', {
        'library': 'package:mpv_audio_kit_test_app/engine_exit_entry.dart',
        'function': 'engineSessionMain',
      });
      expect(
        await answers.moveNext().timeout(const Duration(seconds: 30)),
        isTrue,
      );
      return (answers.current! as SendPort, answers);
    }

    Future<Object?> enableIn(
      SendPort second,
      StreamIterator<Object?> answers,
    ) async {
      second.send('enable');
      expect(
        await answers.moveNext().timeout(const Duration(seconds: 30)),
        isTrue,
      );
      return answers.current;
    }

    testWidgets('a second engine cannot take the session of the first', (
      _,
    ) async {
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      addTearDown(player.dispose);
      await player.setRawProperty('ao', 'null');
      await player.open(
        Media(await materializeFixture('with_chapters.mka')),
        play: false,
      );
      await player.setMediaSession(const MediaSession(title: 'First engine'));
      await pumpUntil(
        (s) => s['title'] == 'First engine',
        reader: readMediaSession,
      );
      addTearDown(() => _engine.invokeMethod<void>('destroy'));

      // Refused while the first owns it, and the entry stays the first's.
      var (second, answers) = await startSecond();
      expect(await enableIn(second, answers), 'refused');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect((await readMediaSession())['title'], 'First engine');

      // The refused engine goes: its detach leaves the session alone.
      await _engine.invokeMethod<void>('destroy');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect((await readMediaSession())['title'], 'First engine');

      // Free once the first turns it off: a new second engine takes it,
      // and its destruction turns it off.
      await player.setMediaSession(null);
      (second, answers) = await startSecond();
      expect(await enableIn(second, answers), 'accepted');
      await pumpUntil(
        (s) => s['title'] == 'Second engine',
        reader: readMediaSession,
      );
      await _engine.invokeMethod<void>('destroy');
      await pumpUntil(
        (s) => s['playbackState'] == 'stopped' && s['title'] == null,
        reader: readMediaSession,
      );
    }, timeout: const Timeout(Duration(seconds: 120)));
  });
}
