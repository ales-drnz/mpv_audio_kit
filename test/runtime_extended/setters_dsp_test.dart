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

    test('setActiveFilters replaces the chain; clearAudioFilters empties',
        () async {
      await player.setActiveFilters([
        AudioFilter.custom('lavfi-volume=2'),
        AudioFilter.custom('lavfi-aecho=0.8:0.5:50:0.4'),
      ]);
      expect(player.state.activeFilters.length, 2);

      await player.clearAudioFilters();
      expect(player.state.activeFilters, isEmpty);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setEqualizerGains stores the 10-band list (state-only, no mpv '
        'commit)', () async {
      final gains = List<double>.generate(10, (i) => i.toDouble());
      await player.setEqualizerGains(gains);
      expect(player.state.equalizerGains, gains);
      // Note: setEqualizerGains is state-only by design — consumers
      // commit the gains to mpv via setActiveFilters(...
      // AudioFilter.equalizer(gains)). See setter dartdoc.
    }, timeout: const Timeout(Duration(seconds: 5)));

    test('addAudioFilter appends to the mpv chain (round-trip via observer)',
        () async {
      // Start from an empty chain so the assertion below is unambiguous.
      await player.clearAudioFilters();
      expect(player.state.activeFilters, isEmpty);

      await player.addAudioFilter(AudioFilter.custom('lavfi-volume=2'));
      // The `af` observer fires asynchronously after the `af add` mpv
      // command — wait for the typed list to update.
      await player.stream.activeFilters
          .firstWhere((list) => list.isNotEmpty)
          .timeout(const Duration(seconds: 3));
      expect(player.state.activeFilters, hasLength(1));
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
