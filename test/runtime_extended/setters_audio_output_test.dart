// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Audio output config setters end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
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

    test('audioDevice description is sourced from audioDevices list, '
        'not duplicated from name', () async {
      // Regression: the spec used to parse `audio-device` as
      // AudioDevice(raw, raw) — both name AND description were the
      // raw mpv name. With the cross-reference fix the description
      // mirrors the entry in `state.audioDevices` (parsed from the
      // `audio-device-list` node observer).
      //
      // mpv always exposes a built-in 'auto' device with description
      // 'Autoselect device' across every backend on every platform —
      // it's the most stable assertion target.
      await player.setAudioDevice(const AudioDevice('auto', 'whatever'));
      // Allow the property observer round-trip to land.
      await Future.delayed(const Duration(milliseconds: 200));

      final autoEntry = player.state.audioDevices
          .firstWhere((d) => d.name == 'auto',
              orElse: () => const AudioDevice('auto', 'auto'));
      expect(player.state.audioDevice.name, 'auto');
      expect(player.state.audioDevice.description, autoEntry.description,
          reason: 'active device description must match the audioDevices '
              'entry, not be a copy of the name');
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
