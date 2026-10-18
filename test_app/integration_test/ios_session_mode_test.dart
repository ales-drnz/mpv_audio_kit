// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// F187 on iOS: up to libmpv-r17 mpv's audio output set the shared audio
// session to the MoviePlayback mode at every init, a mode Apple means for
// video, in every app and with no media session enabled. From r18 it sets
// the `.playback` category only, and the mode stays default. Read back
// through the plugin's debug probe, which reports the session's category
// and mode on iOS. Skipped off iOS, and on a libmpv older than r18.

import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/device_probes.dart';

const _probe = MethodChannel('mpv_audio_kit/media_session');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('iOS audio session', () {
    if (!Platform.isIOS) return;

    testWidgets('the audio output leaves the session mode at default '
        '(F187)', (_) async {
      final player = Player();
      addTearDown(() async {
        await player.stop();
        await player.dispose();
      });
      if (await skipBeforeRelease(player, 18)) return;
      final fixture = await materializeFixture('sine_440hz_1s.wav');
      await player.setVolume(0);
      await player.setLoop(Loop.file);
      // The default output: audiounit, which configures the session.
      await player.open(Media(fixture), play: true);
      try {
        await player.stream.currentAo
            .firstWhere((ao) => ao == 'audiounit')
            .timeout(const Duration(seconds: 10));
      } on Exception {
        fail(
          'audiounit never took the stream (current output '
          '${player.state.currentAo}): the session was not configured',
        );
      }
      final raw = await _probe.invokeMethod<Map<Object?, Object?>>(
        'debugNowPlayingInfo',
      );
      final snapshot = Map<String, Object?>.from(raw ?? const {});
      expect(snapshot['sessionCategory'], 'AVAudioSessionCategoryPlayback');
      expect(
        snapshot['sessionMode'],
        'AVAudioSessionModeDefault',
        reason: 'mpv set the session mode: $snapshot',
      );
    }, timeout: const Timeout(Duration(seconds: 60)));
  });
}
