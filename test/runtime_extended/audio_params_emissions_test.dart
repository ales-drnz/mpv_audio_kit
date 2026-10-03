// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

/// `audioParams` folds three mpv properties (`audio-params`, `audio-codec`
/// and `audio-codec-name`), which mpv reports one at a time. Forwarded one
/// by one, a track change emitted six partial values and a stop three. The
/// event isolate now holds them together, so a track change emits the
/// cleared value and the new one, and a stop the cleared value.
void main() {
  runtimeSuite(() {
    test('a track change and a stop emit audioParams at most twice', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final seen = <AudioParams>[];
      final sub = player.stream.audioParams.skip(1).listen(seen.add);
      addTearDown(sub.cancel);

      for (final fixture in [
        'test/fixtures/sine_5s.flac',
        'test/fixtures/codec/aac_lc_44100.m4a',
        'test/fixtures/sine_88200hz.flac',
      ]) {
        seen.clear();
        await openAndWaitForLoad(player, fixture);
        await waitUntil(
          () => seen.isNotEmpty && seen.last.sampleRate != null,
          reason: 'no complete audioParams for $fixture',
        );
        // Room for a late, split emission to show up.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(seen.length, lessThanOrEqualTo(2), reason: '$fixture: $seen');
        final last = seen.last;
        expect(last.codec, isNotNull, reason: '$fixture: $last');
        expect(last.codecName, isNotNull, reason: '$fixture: $last');
        expect(last.format, isNotNull, reason: '$fixture: $last');
        expect(player.state.audioParams, last);
      }

      seen.clear();
      await player.stop();
      await waitUntil(
        () => seen.isNotEmpty && seen.last == const AudioParams(),
        reason: 'audioParams not cleared after stop: $seen',
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(seen.length, lessThanOrEqualTo(2), reason: 'stop: $seen');
    });
  });
}
