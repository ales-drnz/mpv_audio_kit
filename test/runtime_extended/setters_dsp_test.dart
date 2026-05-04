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

    test('superequalizer round-trip — band gains preserved via params map',
        () async {
      const bands = {
        '1b': 1.5,
        '5b': 0.8,
        '10b': 1.2,
        '18b': 0.5,
      };
      await player.updateAudioEffects(
        (e) => e.copyWith(
          superequalizer: const SuperequalizerSettings(
            enabled: true,
            params: bands,
          ),
        ),
      );
      expect(player.state.audioEffects.superequalizer.enabled, isTrue);
      expect(player.state.audioEffects.superequalizer.params, bands);

      // Disabling preserves the band map.
      await player.updateAudioEffects(
        (e) => e.copyWith(
          superequalizer:
              e.superequalizer.copyWith(enabled: false),
        ),
      );
      expect(player.state.audioEffects.superequalizer.enabled, isFalse);
      expect(player.state.audioEffects.superequalizer.params, bands);
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('acompressor / loudnorm / rubberband round-trip', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          acompressor: const AcompressorSettings(
              enabled: true, threshold: 0.1, ratio: 6),
        ),
      );
      expect(player.state.audioEffects.acompressor.enabled, isTrue);
      expect(player.state.audioEffects.acompressor.threshold, 0.1);
      expect(player.state.audioEffects.acompressor.ratio, 6);

      await player.updateAudioEffects(
        (e) => e.copyWith(
          loudnorm: const LoudnormSettings(enabled: true, I: -23),
        ),
      );
      expect(player.state.audioEffects.loudnorm.enabled, isTrue);
      expect(player.state.audioEffects.loudnorm.I, -23);

      await player.updateAudioEffects(
        (e) => e.copyWith(
          rubberband: const RubberbandSettings(
              enabled: true, pitch: 1.5, tempo: 0.8),
        ),
      );
      expect(player.state.audioEffects.rubberband.enabled, isTrue);
      expect(player.state.audioEffects.rubberband.pitch, 1.5);
      expect(player.state.audioEffects.rubberband.tempo, 0.8);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('bass + treble round-trip — separate biquad shelves preserved',
        () async {
      // 0.0.x bundled bass+treble into a single `BassTrebleSettings`. In
      // 0.1.0 each ffmpeg filter is its own typed Settings; the consumer
      // sets them independently.
      await player.updateAudioEffects(
        (e) => e.copyWith(
          bass: const BassSettings(enabled: true, g: 4.5, f: 120.0),
          treble: const TrebleSettings(enabled: true, g: -2.0, f: 5500.0),
        ),
      );
      expect(player.state.audioEffects.bass.enabled, isTrue);
      expect(player.state.audioEffects.bass.g, 4.5);
      expect(player.state.audioEffects.bass.f, 120.0);
      expect(player.state.audioEffects.treble.enabled, isTrue);
      expect(player.state.audioEffects.treble.g, -2.0);
      expect(player.state.audioEffects.treble.f, 5500.0);

      // Disabling preserves the parameters.
      await player.updateAudioEffects(
        (e) => e.copyWith(bass: e.bass.copyWith(enabled: false)),
      );
      expect(player.state.audioEffects.bass.enabled, isFalse);
      expect(player.state.audioEffects.bass.g, 4.5);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('stereotools round-trip — slev (width) + balance_in preserved',
        () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          stereotools: const StereotoolsSettings(
              enabled: true, slev: 1.5, balance_in: -0.3),
        ),
      );
      expect(player.state.audioEffects.stereotools.enabled, isTrue);
      expect(player.state.audioEffects.stereotools.slev, 1.5);
      expect(player.state.audioEffects.stereotools.balance_in, -0.3);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('crossfeed round-trip — typed strength + range preserved', () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          crossfeed: const CrossfeedSettings(
              enabled: true, strength: 0.4, range: 0.6),
        ),
      );
      expect(player.state.audioEffects.crossfeed.enabled, isTrue);
      expect(player.state.audioEffects.crossfeed.strength, 0.4);
      expect(player.state.audioEffects.crossfeed.range, 0.6);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('silenceremove round-trip — start/stop period flags preserved',
        () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(
          silenceremove: const SilenceremoveSettings(
            enabled: true,
            start_periods: 1,
            stop_periods: 1,
            // ffmpeg's silenceremove uses linear-ratio thresholds (not
            // dB) with min=0; 0.001 ≈ -60 dB.
            start_threshold: 0.001,
            stop_threshold: 0.001,
            start_duration: Duration(milliseconds: 500),
            stop_duration: Duration(milliseconds: 500),
          ),
        ),
      );
      final s = player.state.audioEffects.silenceremove;
      expect(s.enabled, isTrue);
      expect(s.start_periods, 1);
      expect(s.stop_periods, 1);
      expect(s.start_threshold, 0.001);
      expect(s.start_duration, const Duration(milliseconds: 500));

      // Switch to start-only — stop_periods=0 disables the trailing trim.
      await player.updateAudioEffects(
        (e) => e.copyWith(
          silenceremove: e.silenceremove.copyWith(stop_periods: 0),
        ),
      );
      expect(player.state.audioEffects.silenceremove.start_periods, 1);
      expect(player.state.audioEffects.silenceremove.stop_periods, 0);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setAudioEffects atomic — multiple effects in one write', () async {
      await player.setAudioEffects(const AudioEffects(
        acompressor:
            AcompressorSettings(enabled: true, threshold: 0.1, ratio: 4),
        bass: BassSettings(enabled: true, g: 3),
        treble: TrebleSettings(enabled: true, g: -1),
        stereotools: StereotoolsSettings(enabled: true, slev: 1.2),
        loudnorm: LoudnormSettings(enabled: true, i: -16),
      ));
      final fx = player.state.audioEffects;
      expect(fx.acompressor.enabled, isTrue);
      expect(fx.acompressor.threshold, 0.1);
      expect(fx.bass.enabled, isTrue);
      expect(fx.bass.g, 3);
      expect(fx.treble.g, -1);
      expect(fx.stereotools.enabled, isTrue);
      expect(fx.stereotools.slev, 1.2);
      expect(fx.loudnorm.enabled, isTrue);
      expect(fx.loudnorm.i, -16);
      // Untouched effects stay at default (disabled).
      expect(fx.superequalizer.enabled, isFalse);
      expect(fx.rubberband.enabled, isFalse);

      // Reset the bundle.
      await player.setAudioEffects(const AudioEffects());
      expect(player.state.audioEffects, const AudioEffects());
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioEffects.custom round-trip — raw lavfi entries preserved',
        () async {
      await player.updateAudioEffects(
        (e) => e.copyWith(custom: const ['lavfi-volume=2.0']),
      );
      expect(player.state.audioEffects.custom, ['lavfi-volume=2.0']);

      // Combined: custom + typed effect coexist.
      await player.updateAudioEffects(
        (e) => e.copyWith(
          custom: const ['lavfi-aresample=48000'],
          acompressor: const AcompressorSettings(
              enabled: true, threshold: 0.1),
        ),
      );
      expect(player.state.audioEffects.custom, ['lavfi-aresample=48000']);
      expect(player.state.audioEffects.acompressor.enabled, isTrue);

      // Clear.
      await player.updateAudioEffects((e) => e.copyWith(custom: const []));
      expect(player.state.audioEffects.custom, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setRawProperty rejects `af` with ArgumentError', () async {
      expect(
        () => player.setRawProperty('af', 'lavfi-volume=2'),
        throwsA(isA<ArgumentError>()),
      );
    });

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
