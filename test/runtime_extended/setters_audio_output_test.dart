// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
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

  group('Audio output config setters end-to-end', () {
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

    test('audioExclusive / audioSpdif / audioFormat / audioChannels / '
        'audioSampleRate round-trip', () async {
      await player.setAudioExclusive(true);
      expect(player.state.audioExclusive, isTrue);
      await player.setAudioExclusive(false);
      expect(player.state.audioExclusive, isFalse);

      await player.setAudioSpdif('ac3');
      expect(player.state.audioSpdif, 'ac3');
      await player.setAudioSpdif('');
      expect(player.state.audioSpdif, '');

      await player.setAudioFormat('s16');
      expect(player.state.audioFormat, 's16');

      await player.setAudioChannels('stereo');
      expect(player.state.audioChannels, 'stereo');

      await player.setAudioSampleRate(48000);
      expect(player.state.audioSampleRate, 48000);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioClientName / audioDriver round-trip', () async {
      await player.setAudioClientName('test-client');
      expect(player.state.audioClientName, 'test-client');

      await player.setAudioDriver('null');
      expect(player.state.audioDriver, 'null');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioDevice round-trips by name (description is metadata)',
        () async {
      const dev = AudioDevice('null', 'Null Driver');
      await player.setAudioDevice(dev);
      expect(player.state.audioDevice.name, 'null');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('reloadAudio is a fire-and-forget command (no state mutation)',
        () async {
      // Smoke: reloadAudio sends the `ao-reload` command; the only
      // observable post-condition is that subsequent setters keep
      // working without throwing.
      await player.reloadAudio();
      await player.setVolume(80.0);
      expect(player.state.volume, 80.0);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
