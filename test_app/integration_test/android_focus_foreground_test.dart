// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// F172 on Android: a transient focus loss (a call) pauses the player and
// arms the resume for the end of the call. The session then stays
// playWhenReady with a suppression reason, so Media3 keeps its service in
// the foreground for the whole call. Published as paused, it left the
// foreground after Media3's timeout, and on Android 12 and later the play
// at the end of the call could not bring it back.
//
// The timeout is 10 minutes: the debug seam debugForegroundServiceTimeoutMs
// cuts it to 3 s for the service this test starts. MainActivity takes a
// GAIN_TRANSIENT focus for the call and reads whether the service runs in
// the foreground. Skipped off Android.

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/session_probe.dart';

const _focus = MethodChannel('mpv_audio_kit_test_app/focus');
const _session = MethodChannel('mpv_audio_kit/media_session');

/// Media3's foreground timeout for this test's service.
const _timeout = Duration(seconds: 3);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Android media session service through a call', () {
    if (!Platform.isAndroid) return;

    setUpAll(() {
      MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
    });

    Future<bool?> foreground() =>
        _focus.invokeMethod<bool>('serviceForeground');

    testWidgets('the service keeps the foreground while a call holds the '
        'focus (F172)', (_) async {
      // Before the service exists: its onCreate reads it.
      await _session.invokeMethod<void>(
        'debugForegroundServiceTimeoutMs',
        _timeout.inMilliseconds,
      );
      final player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      addTearDown(player.dispose);
      await player.setRawProperty('ao', 'null');
      await player.setLoop(Loop.file);
      await player.setMediaSession(const MediaSession(title: 'F172'));
      await player.open(
        Media(await materializeFixture('with_chapters.mka')),
        play: true,
      );
      await pumpUntil(
        (s) => s['playbackState'] == 'playing',
        reader: readMediaSession,
        timeout: const Duration(seconds: 10),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (await foreground() != true) {
        if (DateTime.now().isAfter(deadline)) {
          fail('the service never entered the foreground while playing');
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }

      // The call: the kit pauses the player and arms the resume.
      addTearDown(() => _focus.invokeMethod<void>('abandon'));
      await _focus.invokeMethod<int>('requestTransient');
      await player.stream.playWhenReady
          .firstWhere((p) => !p)
          .timeout(const Duration(seconds: 10));
      await pumpUntil((s) => s['suppressed'] == true, reader: readMediaSession);

      // Well past the timeout the service is still in the foreground.
      final end = DateTime.now().add(_timeout * 3);
      while (DateTime.now().isBefore(end)) {
        expect(
          await foreground(),
          isTrue,
          reason: 'the service left the foreground during the call',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }

      // The call ends: the kit resumes, and the session plays again.
      await _focus.invokeMethod<void>('abandon');
      await player.stream.playWhenReady
          .firstWhere((p) => p)
          .timeout(const Duration(seconds: 10));
      await pumpUntil(
        (s) => s['playbackState'] == 'playing' && s['suppressed'] == false,
        reader: readMediaSession,
      );
      expect(await foreground(), isTrue);
    }, timeout: const Timeout(Duration(seconds: 90)));
  });
}
