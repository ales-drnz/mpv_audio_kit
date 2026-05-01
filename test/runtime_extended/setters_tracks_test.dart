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
final multitrackPath =
      '${Directory.current.path}/test/fixtures/multitrack_two_audio.mka';

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(multitrackPath).existsSync()) {
      markTestSkipped('Multitrack fixture missing');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Audio track typed setters end-to-end (multi-track MKA)', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
      await player.open(Media(multitrackPath), play: false);
      // Wait for tracks to populate.
      await player.stream.tracks
          .firstWhere(
              (t) => t.where((tr) => tr.type == 'audio').length == 2)
          .timeout(const Duration(seconds: 5));
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('setAudioTrack(int) selects the requested track', () async {
      // Subscribe BEFORE the setter so the broadcast emission isn't
      // missed (the observer fires synchronously on the wrapper-side
      // dispatch path when mpv echoes the change back).
      final waitForTrack2 = player.stream.currentAudioTrack
          .firstWhere((t) => t != null && t.id == 2)
          .timeout(const Duration(seconds: 3));
      await player.setAudioTrack(2);
      final current = await waitForTrack2;
      expect(current!.id, 2);
      expect(current.lang, 'fra',
          reason: 'fixture metadata: track 2 is French');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('setAudioTrackOff() disables audio output (`aid=no`)', () async {
      // mpv 0.41 does NOT emit a `current-tracks/audio` property-change
      // event when aid transitions from a numeric id to `no` — the
      // event is emitted only on track-to-track switches. We assert via
      // the raw `aid` property + small wait for mpv to settle.
      await player.setAudioTrackOff();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(await player.getRawProperty('aid'), 'no');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('setAudioTrackAuto() writes aid=auto (mpv resolves it to a '
        'numeric track id immediately for default-flagged tracks)',
        () async {
      // mpv accepts `aid=auto` and resolves it on the spot to the
      // default-flagged track id (or the first audio track if no
      // default is set). The observable contract is therefore "the
      // setter completes and aid is in {auto, <numeric id>}", not the
      // literal `auto` string.
      await player.setAudioTrackAuto();
      await Future.delayed(const Duration(milliseconds: 200));
      final aid = await player.getRawProperty('aid');
      expect(['auto', '1', '2'], contains(aid),
          reason: 'mpv 0.41 may resolve auto → default track id at write '
              'time; both shapes are valid post-conditions');
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
