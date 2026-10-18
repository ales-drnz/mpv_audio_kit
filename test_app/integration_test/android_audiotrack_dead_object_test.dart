// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The audiotrack output of libmpv-r18 after audioserver dies (F278). Up to
// r17 the output recreated its AudioTrack on the spot, while audioserver
// was still down, and stayed silent when that failed. Now it asks mpv to
// reload the output.
//
// Needs a host that kills audioserver: diag/android_emulator.sh waits for
// the "[f278] playing" line this test prints, then runs `killall
// audioserver` with adb root. Skipped off Android, and on a libmpv older
// than r18.

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

  group('Android audiotrack after audioserver dies', () {
    if (!Platform.isAndroid) return;

    testWidgets('the output reopens and the position runs again (F278)', (
      _,
    ) async {
      final player = Player();
      addTearDown(() async {
        await player.stop();
        await player.dispose();
      });
      if (await skipBeforeRelease(player, 18)) return;
      await player.setVolume(0);
      final tone = await writeToneWav('tone_120s.wav', 120);
      final states = <AudioOutputState>[];
      final sub = player.stream.audioOutputState.listen(states.add);
      addTearDown(sub.cancel);
      await player.open(Media(tone), play: true);
      await player.stream.currentAo
          .firstWhere((ao) => ao == 'audiotrack')
          .timeout(const Duration(seconds: 10));
      await player.stream.position
          .firstWhere((p) => p > const Duration(milliseconds: 500))
          .timeout(const Duration(seconds: 10));

      // The cue for the script, which kills audioserver once it reads it.
      // ignore: avoid_print
      print('[f278] playing');

      // The kill shows as the output leaving `active` or the position
      // standing still while playing.
      var lastPos = player.state.position;
      var movedAt = DateTime.now();
      final seen = states.length;
      final deadline = DateTime.now().add(const Duration(seconds: 90));
      while (true) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        final pos = player.state.position;
        if (pos != lastPos) {
          lastPos = pos;
          movedAt = DateTime.now();
        }
        final left = states.skip(seen).any((s) => s != AudioOutputState.active);
        final stalled =
            DateTime.now().difference(movedAt) > const Duration(seconds: 1);
        if (left || stalled) break;
        if (DateTime.now().isAfter(deadline)) {
          fail(
            'audioserver was not killed within 90 s: run this test '
            'through diag/android_emulator.sh',
          );
        }
      }
      // ignore: avoid_print
      print('[f278] kill seen at ${player.state.position}, states $states');

      // Back: the output active again, and the position past where it was.
      final stopAt = player.state.position;
      final back = DateTime.now().add(const Duration(seconds: 20));
      while (!(player.state.audioOutputState == AudioOutputState.active &&
          player.state.position > stopAt + const Duration(seconds: 1))) {
        if (DateTime.now().isAfter(back)) {
          fail(
            'the output did not come back: state '
            '${player.state.audioOutputState}, position '
            '${player.state.position} (stopped at $stopAt), states $states',
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(threadExists(audiotrackThread), isTrue);
    }, timeout: const Timeout(Duration(minutes: 3)));
  });
}
