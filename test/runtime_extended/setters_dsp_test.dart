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

  group('DSP / filter / mode setters end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('setEqualizer round-trip — gains stored, enabled toggles chain',
        () async {
      final gains = List<double>.generate(10, (i) => i.toDouble() - 5);
      await player.setEqualizer(EqualizerSettings(enabled: true, gains: gains));
      expect(player.state.equalizer.enabled, isTrue);
      expect(player.state.equalizer.gains, gains);

      await player
          .setEqualizer(player.state.equalizer.copyWith(enabled: false));
      expect(player.state.equalizer.enabled, isFalse);
      // Gains preserved while disabled.
      expect(player.state.equalizer.gains, gains);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setCompressor / setLoudness / setPitchTempo round-trip', () async {
      await player.setCompressor(
        const CompressorSettings(enabled: true, threshold: -18, ratio: 6),
      );
      expect(player.state.compressor.enabled, isTrue);
      expect(player.state.compressor.threshold, -18);
      expect(player.state.compressor.ratio, 6);

      await player.setLoudness(
        const LoudnessSettings(enabled: true, integratedLoudness: -23),
      );
      expect(player.state.loudness.enabled, isTrue);
      expect(player.state.loudness.integratedLoudness, -23);

      await player.setPitchTempo(
        const PitchTempoSettings(enabled: true, pitch: 1.5, tempo: 0.8),
      );
      expect(player.state.pitchTempo.enabled, isTrue);
      expect(player.state.pitchTempo.pitch, 1.5);
      expect(player.state.pitchTempo.tempo, 0.8);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setCustomAudioFilters stores raw mpv filter strings', () async {
      await player.setCustomAudioFilters([
        'lavfi-volume=2',
        'lavfi-aecho=0.8:0.5:50:0.4',
      ]);
      expect(player.state.customAudioFilters.length, 2);
      expect(player.state.customAudioFilters[0], 'lavfi-volume=2');

      await player.setCustomAudioFilters(const []);
      expect(player.state.customAudioFilters, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setCustomAudioFilters rejects wrapper-reserved labels', () async {
      // The four wrapper-managed DSP stages own labels `@_mak_eq`,
      // `@_mak_comp`, `@_mak_loud`, `@_mak_pt`. A custom filter carrying
      // any of those would silently shadow the typed setter on the next
      // composeAfChain pass; validating up-front turns it into an
      // explicit ArgumentError instead.
      expect(
        () => player.setCustomAudioFilters([
          '@_mak_eq:lavfi-equalizer=f=1000:t=o:w=1:g=6',
        ]),
        throwsA(isA<ArgumentError>()),
      );
      // User-defined labels are still allowed.
      await player.setCustomAudioFilters(['@my_label:lavfi-volume=2']);
      expect(player.state.customAudioFilters, hasLength(1));
      await player.setCustomAudioFilters(const []);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('gapless / audioDisplay / coverArtAuto enum round-trip', () async {
      await player.setGapless(Gapless.yes);
      expect(player.state.gapless, Gapless.yes);
      await player.setGapless(Gapless.no);
      expect(player.state.gapless, Gapless.no);

      await player.setAudioDisplay(Display.no);
      expect(player.state.audioDisplay, Display.no);

      await player.setCoverArtAuto(Cover.exact);
      expect(player.state.coverArtAuto, Cover.exact);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
