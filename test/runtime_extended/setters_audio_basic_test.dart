// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  String? resolveLibmpv() {
    final root = Directory.current.path;
    if (Platform.isMacOS) {
      final p = '$root/macos/libs/libmpv.dylib';
      return File(p).existsSync() ? p : null;
    }
    if (Platform.isLinux) {
      final p = '$root/linux/libs/libmpv.so';
      return File(p).existsSync() ? p : null;
    }
    return null;
  }

  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Audio basic setters end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(fixturePath), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 500)
          .timeout(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('volume / rate / pitch / mute round-trip into state', () async {
      await player.setVolume(75.0);
      expect(player.state.volume, 75.0);

      await player.setRate(1.25);
      expect(player.state.rate, 1.25);

      await player.setPitch(0.8);
      expect(player.state.pitch, 0.8);

      await player.setMute(true);
      expect(player.state.mute, isTrue);
      await player.setMute(false);
      expect(player.state.mute, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('volumeGain / volumeMax / pitchCorrection round-trip', () async {
      await player.setVolumeGain(-3.5);
      expect(player.state.volumeGain, -3.5);

      await player.setVolumeMax(200.0);
      expect(player.state.volumeMax, 200.0);

      await player.setPitchCorrection(false);
      expect(player.state.pitchCorrection, isFalse);
      await player.setPitchCorrection(true);
      expect(player.state.pitchCorrection, isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioDelay (Duration) round-trips', () async {
      await player.setAudioDelay(const Duration(milliseconds: 50));
      expect(player.state.audioDelay, const Duration(milliseconds: 50));

      await player.setAudioDelay(Duration.zero);
      expect(player.state.audioDelay, Duration.zero);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
