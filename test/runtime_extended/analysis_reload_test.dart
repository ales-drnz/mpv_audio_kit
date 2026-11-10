// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// A new file clears the waveform of the last one at its FILE_LOADED: 0.7.0
// keeps it only for the same path loaded again. The event isolate sends the
// new `path` ahead of FILE_LOADED (it re-reads what END_FILE left
// unavailable), so a check against the state's path took every new file
// for the same one and kept the old envelope on screen. This replays that
// order on a player whose waveform is ready: the native result is still
// the old file's, so a held one is never replaced.

@TestOn('linux || mac-os || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/core_events.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final a = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  const b = '/nowhere/another.flac';

  analysisSuite(extraFixtures: [a], () {
    Future<(Player, List<WaveformData?>)> ready() async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final got = <WaveformData?>[];
      final sub = player.stream.waveform.listen(got.add);
      addTearDown(sub.cancel);
      await player.open(Media(a), play: false);
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while ((got.isEmpty || got.last == null || got.last!.decoding) &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(got.last, isNotNull, reason: 'a.flac analyzed');
      return (player, got);
    }

    test(
      'another path, sent ahead of its FILE_LOADED, clears the waveform',
      () async {
        final (player, got) = await ready();
        got.clear();
        player
          ..debugDispatchProperty('path', b)
          ..debugDispatchEvent(MpvEventFileLoaded(path: b));
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(got, isNotEmpty, reason: 'nothing emitted: a.flac stays');
        expect(got.first, isNull);
      },
    );

    test('the same path loaded again keeps it, with no null', () async {
      final (player, got) = await ready();
      got.clear();
      player
        ..debugDispatchProperty('path', a)
        ..debugDispatchEvent(MpvEventFileLoaded(path: a));
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(got.contains(null), isFalse, reason: '$got');
    });
  });
}
