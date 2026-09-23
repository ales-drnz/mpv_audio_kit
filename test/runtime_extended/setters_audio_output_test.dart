// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

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

      await player.setAudioMediaRole(true);
      expect(player.state.audioMediaRole, isTrue);
      await player.setAudioMediaRole(false);
      expect(player.state.audioMediaRole, isFalse);

      await player.setAudioSpdif({Spdif.ac3});
      expect(player.state.audioSpdif, {Spdif.ac3});
      // The full set of codecs mpv accepts round-trips through real libmpv.
      // The enum deliberately omits aac/mp3 — mpv's audio-spdif rejects them,
      // so a setter call with them would throw (see test/models/spdif_test.dart).
      await player.setAudioSpdif({
        Spdif.ac3,
        Spdif.dts,
        Spdif.eac3,
        Spdif.trueHd,
      });
      expect(player.state.audioSpdif, {
        Spdif.ac3,
        Spdif.dts,
        Spdif.eac3,
        Spdif.trueHd,
      });
      await player.setAudioSpdif(<Spdif>{});
      expect(player.state.audioSpdif, isEmpty);

      await player.setAudioFormat(Format.s16);
      expect(player.state.audioFormat, Format.s16);

      // 64-bit PCM formats mpv accepts on audio-format.
      await player.setAudioFormat(Format.s64);
      expect(player.state.audioFormat, Format.s64);

      // The documented reset path: Format.auto writes the wire token `no`.
      // This build's libmpv accepts `""`/`"no"` on `audio-format` as a
      // reset to auto (a parse/print asymmetry fixed in the maintained
      // build; vanilla mpv rejects the token). This pin guards that
      // behavior across libmpv updates — if it ever regresses to the
      // vanilla parser, this throws instead of resetting.
      await player.setAudioFormat(Format.auto);
      expect(player.state.audioFormat, Format.auto);
      expect(await player.getRawProperty('audio-format'), 'no');

      await player.setAudioChannels(Channels.stereo);
      expect(player.state.audioChannels, Channels.stereo);

      await player.setAudioChannels(Channels.fiveOneSide);
      expect(player.state.audioChannels, Channels.fiveOneSide);

      // Custom escape — anything outside the named-layout set.
      await player.setAudioChannels(
        const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
      );
      expect(
        player.state.audioChannels,
        const Channels.custom('fl-fr-fc-bl-br-sl-sr-lfe'),
      );

      await player.setAudioSampleRate(48000);
      expect(player.state.audioSampleRate, 48000);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioClientName / audioDriver round-trip', () async {
      await player.setAudioClientName('test-client');
      expect(player.state.audioClientName, 'test-client');

      await player.setAudioDriver('null');
      expect(player.state.audioDriver, 'null');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test("audioDriver 'auto' normalizes to mpv's empty auto-probe", () async {
      // mpv has no backend literally named 'auto'; passing it through
      // would fail to initialize any output. 'auto' and '' both map to
      // the empty `ao` auto-probe value.
      await player.setAudioDriver('auto');
      expect(player.state.audioDriver, '');

      await player.setAudioDriver('');
      expect(player.state.audioDriver, '');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioDevice round-trips by name (description is metadata)', () async {
      const dev = Device(name: 'null', description: 'Null Driver');
      await player.setAudioDevice(dev);
      expect(player.state.audioDevice.name, 'null');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioDevice description is sourced from audioDevices list, '
        'not duplicated from name', () async {
      // Regression: the spec used to parse `audio-device` as
      // Device(name: raw, description: raw) — both name AND description were the
      // raw mpv name. With the cross-reference fix the description
      // mirrors the entry in `state.audioDevices` (parsed from the
      // `audio-device-list` node observer).
      //
      // mpv always exposes a built-in 'auto' device with description
      // 'Autoselect device' across every backend on every platform —
      // it's the most stable assertion target.
      await player.setAudioDevice(
        const Device(name: 'auto', description: 'whatever'),
      );
      // Allow the property observer round-trip to land.
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final autoEntry = player.state.audioDevices.firstWhere(
        (d) => d.name == 'auto',
        orElse: () => const Device(name: 'auto', description: 'auto'),
      );
      expect(player.state.audioDevice.name, 'auto');
      expect(
        player.state.audioDevice.description,
        autoEntry.description,
        reason:
            'active device description must match the audioDevices '
            'entry, not be a copy of the name',
      );
    }, timeout: const Timeout(Duration(seconds: 15)));

    test(
      'reloadAudio / rescanExternalFiles are fire-and-forget commands',
      () async {
        // Smoke: each sends an mpv command with no direct state mutation; the
        // observable post-condition is that subsequent setters keep working
        // without throwing.
        await player.reloadAudio();
        await player.rescanExternalFiles();
        await player.rescanExternalFiles(keepSelection: true);
        await player.setVolume(80.0);
        expect(player.state.volume, 80.0);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}
