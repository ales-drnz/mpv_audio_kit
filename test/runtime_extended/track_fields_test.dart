// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// Verifies the [MpvTrack] fields the package maps are actually populated
/// by real libmpv from a loaded file — and documents which keys mpv's
/// track-list node genuinely carries.
///
/// Regression anchor for the `demux-duration` removal: that field used to
/// be parsed from a track-list key mpv never emits, so it was permanently
/// null and only "worked" against a synthetic unit-test node. Track length
/// is the file-level `state.duration`, asserted here alongside.
void main() {
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('MpvTrack fields from real libmpv', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayerWithFixture(fixturePath: fixturePath);
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test(
        'track-list exposes a selected audio track with real demuxer fields',
        () {
          final tracks = player.state.tracks;
          expect(tracks, isNotEmpty, reason: 'track-list populated on load');

          final audio = tracks.firstWhere(
            (t) => t.type == 'audio',
            orElse: () => fail('no audio track in track-list'),
          );

          // Identity + selection come straight from the track-list node.
          expect(audio.id, greaterThanOrEqualTo(0));
          expect(audio.type, 'audio');
          expect(
            audio.selected,
            isTrue,
            reason: 'the sole audio track of the fixture is auto-selected',
          );

          // The demuxer-side fields the parser maps (demux-samplerate /
          // demux-channel-count) are real keys mpv emits — they must populate
          // for a plain PCM WAV.
          expect(audio.sampleRate, isNotNull);
          expect(audio.sampleRate, greaterThan(0));
          expect(audio.channelCount, isNotNull);
          expect(audio.channelCount, greaterThan(0));

          // Track length is the file-level duration, not a per-track field.
          expect(player.state.duration, greaterThan(Duration.zero));
        },
        timeout: const Timeout(Duration(seconds: 15)),
      );

      test('current-tracks/audio mirrors the selected track', () {
        final current = player.state.currentAudioTrack;
        // current-tracks/audio is populated once a track is selected at load.
        expect(current, isNotNull);
        expect(current!.type, 'audio');
        expect(current.selected, isTrue);
      }, timeout: const Timeout(Duration(seconds: 15)));
    });
  });
}
