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

  group('Network / demuxer / buffer setters end-to-end', () {
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

    test('networkTimeout / tlsVerify round-trip', () async {
      await player.setNetworkTimeout(const Duration(seconds: 60));
      expect(player.state.networkTimeout, const Duration(seconds: 60));

      await player.setTlsVerify(false);
      expect(player.state.tlsVerify, isFalse);
      await player.setTlsVerify(true);
      expect(player.state.tlsVerify, isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('demuxerMaxBytes / demuxerMaxBackBytes / demuxerReadaheadSecs '
        'round-trip', () async {
      // mpv accepts these in MiB units (the wrapper floors bytes →
      // MiB). 100 MiB is well within the default range.
      await player.setDemuxerMaxBytes(100 * 1024 * 1024);
      expect(player.state.demuxerMaxBytes, 100 * 1024 * 1024);

      await player.setDemuxerMaxBackBytes(25 * 1024 * 1024);
      expect(player.state.demuxerMaxBackBytes, 25 * 1024 * 1024);

      await player.setDemuxerReadaheadSecs(10);
      expect(player.state.demuxerReadaheadSecs, 10);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('audioBuffer / audioStreamSilence / audioNullUntimed round-trip',
        () async {
      await player.setAudioBuffer(const Duration(milliseconds: 500));
      expect(player.state.audioBuffer, const Duration(milliseconds: 500));

      await player.setAudioStreamSilence(true);
      expect(player.state.audioStreamSilence, isTrue);
      await player.setAudioStreamSilence(false);
      expect(player.state.audioStreamSilence, isFalse);

      await player.setAudioNullUntimed(true);
      expect(player.state.audioNullUntimed, isTrue);
      await player.setAudioNullUntimed(false);
      expect(player.state.audioNullUntimed, isFalse);
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
