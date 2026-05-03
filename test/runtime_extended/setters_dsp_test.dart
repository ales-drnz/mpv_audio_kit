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
      await player.updateAudioEffects(
        (e) => e.copyWith(
          equalizer: EqualizerSettings(enabled: true, gains: gains),
        ),
      );
      expect(player.state.audioEffects.equalizer.enabled, isTrue);
      expect(player.state.audioEffects.equalizer.gains, gains);

      await player.updateAudioEffects(
        (e) => e.copyWith(
          equalizer:
              player.state.audioEffects.equalizer.copyWith(enabled: false),
        ),
      );
      expect(player.state.audioEffects.equalizer.enabled, isFalse);
      // Gains preserved while disabled.
      expect(player.state.audioEffects.equalizer.gains, gains);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('setCompressor / setLoudness / setPitchTempo round-trip', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          compressor: const CompressorSettings(
              enabled: true, threshold: -18, ratio: 6),
        ),
      );
      expect(player.state.audioEffects.compressor.enabled, isTrue);
      expect(player.state.audioEffects.compressor.threshold, -18);
      expect(player.state.audioEffects.compressor.ratio, 6);

      await player.updateAudioEffects(
        (e) => e.copyWith(
          loudness: const LoudnessSettings(
              enabled: true, integratedLoudness: -23),
        ),
      );
      expect(player.state.audioEffects.loudness.enabled, isTrue);
      expect(player.state.audioEffects.loudness.integratedLoudness, -23);

      await player.updateAudioEffects(
        (e) => e.copyWith(
          pitchTempo: const PitchTempoSettings(
              enabled: true, pitch: 1.5, tempo: 0.8),
        ),
      );
      expect(player.state.audioEffects.pitchTempo.enabled, isTrue);
      expect(player.state.audioEffects.pitchTempo.pitch, 1.5);
      expect(player.state.audioEffects.pitchTempo.tempo, 0.8);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setCustomAudioFilters stores raw mpv filter strings', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(custom: [
          'lavfi-volume=2',
          'lavfi-aecho=0.8:0.5:50:0.4',
        ]),
      );
      expect(player.state.audioEffects.custom.length, 2);
      expect(player.state.audioEffects.custom[0], 'lavfi-volume=2');

      await player.updateAudioEffects((e) => e.copyWith(custom: const []));
      expect(player.state.audioEffects.custom, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setCustomAudioFilters rejects wrapper-reserved labels', () async {
      // The four wrapper-managed DSP stages own labels `@_mak_eq`,
      // `@_mak_comp`, `@_mak_loud`, `@_mak_pt`. A custom filter carrying
      // any of those would silently shadow the typed setter on the next
      // composeAfChain pass; validating up-front turns it into an
      // explicit ArgumentError instead.
      expect(
        () => player.updateAudioEffects(
          (e) => e.copyWith(custom: [
            '@_mak_eq:lavfi-equalizer=f=1000:t=o:w=1:g=6',
          ]),
        ),
        throwsA(isA<ArgumentError>()),
      );
      // User-defined labels are still allowed.
      await player.updateAudioEffects(
        (e) => e.copyWith(custom: ['@my_label:lavfi-volume=2']),
      );
      expect(player.state.audioEffects.custom, hasLength(1));
      await player.updateAudioEffects((e) => e.copyWith(custom: const []));
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setBassTreble round-trip — frequencies and gains preserved',
        () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          bassTreble: const BassTrebleSettings(
            enabled: true,
            bassDb: 4.5,
            bassFrequency: 120.0,
            trebleDb: -2.0,
            trebleFrequency: 5500.0,
          ),
        ),
      );
      expect(player.state.audioEffects.bassTreble.enabled, isTrue);
      expect(player.state.audioEffects.bassTreble.bassDb, 4.5);
      expect(player.state.audioEffects.bassTreble.bassFrequency, 120.0);
      expect(player.state.audioEffects.bassTreble.trebleDb, -2.0);
      expect(player.state.audioEffects.bassTreble.trebleFrequency, 5500.0);

      // Disabling preserves the parameters.
      await player.updateAudioEffects((e) =>
          e.copyWith(bassTreble: e.bassTreble.copyWith(enabled: false)));
      expect(player.state.audioEffects.bassTreble.enabled, isFalse);
      expect(player.state.audioEffects.bassTreble.bassDb, 4.5);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setStereo round-trip — width + balance preserved', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          stereo: const StereoSettings(
              enabled: true, width: 1.5, balance: -0.3),
        ),
      );
      expect(player.state.audioEffects.stereo.enabled, isTrue);
      expect(player.state.audioEffects.stereo.width, 1.5);
      expect(player.state.audioEffects.stereo.balance, -0.3);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setCrossfeed round-trip — every CrossfeedIntensity profile applies',
        () async {
      for (final p in CrossfeedIntensity.values) {
        await player.updateAudioEffects(
          (e) => e.copyWith(
            crossfeed: CrossfeedSettings(enabled: true, intensity: p),
          ),
        );
        expect(player.state.audioEffects.crossfeed.enabled, isTrue);
        expect(player.state.audioEffects.crossfeed.intensity, p);
      }
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setSilenceTrim round-trip — start/end flags + threshold preserved',
        () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          silenceTrim: const SilenceTrimSettings(
            trimStart: true,
            trimEnd: true,
            thresholdDb: -55.0,
            minDuration: Duration(milliseconds: 500),
          ),
        ),
      );
      expect(player.state.audioEffects.silenceTrim.trimStart, isTrue);
      expect(player.state.audioEffects.silenceTrim.trimEnd, isTrue);
      expect(player.state.audioEffects.silenceTrim.thresholdDb, -55.0);
      expect(player.state.audioEffects.silenceTrim.minDuration,
          const Duration(milliseconds: 500));

      // Switch to start-only — end must reset on the bundle.
      await player.updateAudioEffects(
        (e) => e.copyWith(
          silenceTrim:
              e.silenceTrim.copyWith(trimEnd: false),
        ),
      );
      expect(player.state.audioEffects.silenceTrim.trimStart, isTrue);
      expect(player.state.audioEffects.silenceTrim.trimEnd, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('crossfade round-trip — Duration preserved', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(crossfade: const Duration(seconds: 3)),
      );
      expect(player.state.audioEffects.crossfade,
          const Duration(seconds: 3));

      // Reset to null disables crossfade.
      await player.updateAudioEffects((e) => e.copyWith(crossfade: null));
      expect(player.state.audioEffects.crossfade, isNull);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setAudioEffects atomic — multiple effects in one write', () async {
      await player.setAudioEffects(const AudioEffects(
        compressor:
            CompressorSettings(enabled: true, threshold: -20, ratio: 4),
        bassTreble:
            BassTrebleSettings(enabled: true, bassDb: 3, trebleDb: -1),
        stereo: StereoSettings(enabled: true, width: 1.2),
        crossfade: Duration(seconds: 2),
      ));
      final fx = player.state.audioEffects;
      expect(fx.compressor.enabled, isTrue);
      expect(fx.compressor.threshold, -20);
      expect(fx.bassTreble.enabled, isTrue);
      expect(fx.bassTreble.bassDb, 3);
      expect(fx.stereo.enabled, isTrue);
      expect(fx.stereo.width, 1.2);
      expect(fx.crossfade, const Duration(seconds: 2));
      // Untouched effects stay at default.
      expect(fx.equalizer.enabled, isFalse);
      expect(fx.loudness.enabled, isFalse);

      // Reset the bundle.
      await player.setAudioEffects(const AudioEffects());
      expect(player.state.audioEffects, const AudioEffects());
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('gapless / coverArtAuto enum round-trip', () async {
      await player.setGapless(Gapless.yes);
      expect(player.state.gapless, Gapless.yes);
      await player.setGapless(Gapless.no);
      expect(player.state.gapless, Gapless.no);

      await player.setCoverArtAuto(Cover.exact);
      expect(player.state.coverArtAuto, Cover.exact);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
