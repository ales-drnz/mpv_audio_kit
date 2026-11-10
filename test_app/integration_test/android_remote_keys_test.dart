// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The media keys of a remote (Android TV, Fire TV, Google TV) or of a
// headset reach the player through the media session: play, pause,
// play-pause, next and previous. Android hands them to the active
// MediaSession, and the package's Media3 session forwards them.
//
// Needs a host that presses the keys: diag/android_emulator.sh relays each
// "[key] KEYCODE_..." line this test prints with `adb shell input
// keyevent`, as a remote does. Skipped off Android.

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/device_probes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('Android media keys', () {
    if (!Platform.isAndroid) return;

    testWidgets('the keys of a remote drive the player', (_) async {
      final player = Player();
      addTearDown(() async {
        await player.setMediaSession(null);
        await player.stop();
        await player.dispose();
      });
      await player.setVolume(0);
      final first = await writeToneWav('keys_a.wav', 60);
      final second = await writeToneWav('keys_b.wav', 60);
      await player.setMediaSession(const MediaSession(title: 'Keys'));
      await player.openAll([Media(first), Media(second)], play: true);

      Future<void> press(String key, bool Function() done, String what) async {
        // The cue for the script, which presses the key once it reads it.
        // ignore: avoid_print
        print('[key] $key');
        final deadline = DateTime.now().add(const Duration(seconds: 20));
        while (!done()) {
          if (DateTime.now().isAfter(deadline)) {
            fail(
              '$key never $what: run this test through '
              'diag/android_emulator.sh',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }

      await player.stream.position
          .firstWhere((p) => p > const Duration(milliseconds: 300))
          .timeout(const Duration(seconds: 10));
      await press(
        'KEYCODE_MEDIA_PAUSE',
        () => !player.state.playback.playing,
        'paused',
      );
      await press(
        'KEYCODE_MEDIA_PLAY',
        () => player.state.playback.playing,
        'played',
      );
      await press(
        'KEYCODE_MEDIA_NEXT',
        () => player.state.playback.playlist.index == 1,
        'went to the next entry',
      );
      await press(
        'KEYCODE_MEDIA_PREVIOUS',
        () => player.state.playback.playlist.index == 0,
        'went to the previous entry',
      );
      await press(
        'KEYCODE_MEDIA_PLAY_PAUSE',
        () => !player.state.playback.playing,
        'toggled to pause',
      );
      // ignore: avoid_print
      print('[key] done');
    });
  });
}
