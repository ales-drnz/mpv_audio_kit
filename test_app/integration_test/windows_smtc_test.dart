// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// SMTC on the real Windows API. The probe reads back what the
// SystemMediaTransportControls of the process hold (the smtc* keys of
// debugMediaSessionState in windows/media_session_smtc.cpp), so a green run
// proves that the session reached the transport controls, not only the
// plugin's copy of it. CI runs it in the Build Windows job of ci.yml.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/session_probe.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  group('SMTC read back from the transport controls', () {
    late Player player;

    setUp(() async {
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.setMediaSession(null);
      await player.stop();
      await player.dispose();
    });

    testWidgets('tags, cover and play state reach the transport controls', (
      _,
    ) async {
      final tagged = await materializeFixture('tagged.m4a');
      await player.setMediaSession(const MediaSession());
      await player.open(Media(tagged), play: false);

      final np = await pumpUntil(
        (s) => s['smtcCreated'] == false || s['smtcTitle'] == 'Tagged Title',
        reader: readMediaSession,
      );
      expect(
        np['smtcCreated'],
        isTrue,
        reason: 'the plugin could not create the SMTC on this host: $np',
      );
      expect(np['smtcEnabled'], isTrue);
      expect(np['smtcArtist'], 'Tagged Artist');
      expect(np['smtcAlbum'], 'Tagged Album');
      expect(np['smtcThumbnail'], isTrue, reason: 'the embedded cover: $np');
      // Changing while the file loads, then the intent of open(play: false).
      await pumpUntil(
        (s) => s['smtcStatus'] == 'paused',
        reader: readMediaSession,
      );

      await player.play();
      await pumpUntil(
        (s) => s['smtcStatus'] == 'playing',
        reader: readMediaSession,
      );

      await player.pause();
      await pumpUntil(
        (s) => s['smtcStatus'] == 'paused',
        reader: readMediaSession,
      );
    }, skip: !Platform.isWindows);

    testWidgets('disable stops and clears the transport controls', (_) async {
      final fixture = await materializeFixture('with_chapters.mka');
      await player.open(Media(fixture), play: false);
      await player.setMediaSession(const MediaSession(title: 'E2E'));
      await pumpUntil((s) => s['smtcTitle'] == 'E2E', reader: readMediaSession);

      await player.setMediaSession(null);
      final np = await pumpUntil(
        (s) => s['smtcStatus'] == 'stopped',
        reader: readMediaSession,
      );
      expect(np['smtcEnabled'], isFalse);
      expect(np['smtcTitle'], '');
      expect(np['smtcThumbnail'], isFalse);
    }, skip: !Platform.isWindows);
  });
}
