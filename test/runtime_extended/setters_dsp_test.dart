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

  group('DSP / filter / mode setters end-to-end', () {
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

    test('setEqualizer round-trip — gains stored, enabled toggles chain',
        () async {
      final gains = List<double>.generate(10, (i) => i.toDouble() - 5);
      await player.setEqualizer(EqualizerConfig(enabled: true, gains: gains));
      expect(player.state.equalizer.enabled, isTrue);
      expect(player.state.equalizer.gains, gains);

      await player.setEqualizer(player.state.equalizer.copyWith(enabled: false));
      expect(player.state.equalizer.enabled, isFalse);
      // Gains preserved while disabled.
      expect(player.state.equalizer.gains, gains);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setCompressor / setLoudness / setPitchTempo round-trip', () async {
      await player.setCompressor(
        const CompressorConfig(enabled: true, threshold: -18, ratio: 6),
      );
      expect(player.state.compressor.enabled, isTrue);
      expect(player.state.compressor.threshold, -18);
      expect(player.state.compressor.ratio, 6);

      await player.setLoudness(
        const LoudnessConfig(enabled: true, integratedLoudness: -23),
      );
      expect(player.state.loudness.enabled, isTrue);
      expect(player.state.loudness.integratedLoudness, -23);

      await player.setPitchTempo(
        const PitchTempoConfig(enabled: true, pitch: 1.5, tempo: 0.8),
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

    test('gaplessMode / audioDisplayMode / coverArtAutoMode enum round-trip',
        () async {
      await player.setGaplessMode(GaplessMode.yes);
      expect(player.state.gaplessMode, GaplessMode.yes);
      await player.setGaplessMode(GaplessMode.no);
      expect(player.state.gaplessMode, GaplessMode.no);

      await player.setAudioDisplayMode(AudioDisplayMode.no);
      expect(player.state.audioDisplayMode, AudioDisplayMode.no);

      await player.setCoverArtAutoMode(CoverArtAutoMode.exact);
      expect(player.state.coverArtAutoMode, CoverArtAutoMode.exact);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
