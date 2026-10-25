// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

/// `stream.endFile` carries the entry that ended: its Media, the position
/// its output reached and its duration. The state cannot stand in for
/// them: with gapless audio an entry ends while its buffered audio still
/// plays, the next event already describes the next entry, and a stop
/// resets the position.
void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final oneSecond = '$dir/sine_stereo_1s.flac';
  final fiveSeconds = '$dir/sine_5s.flac';

  /// Seconds of a numeric mpv property.
  Future<double> seconds(Player player, String name) async =>
      double.parse((await player.getRawProperty(name))!);

  runtimeSuite(fixturePath: fiveSeconds, extraFixtures: [oneSecond], () {
    test('the eof of a playlist entry carries that entry', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final first = Media(oneSecond, extras: const {'n': 1});
      final second = Media(fiveSeconds, extras: const {'n': 2});
      final ended = player.stream.endFile
          .firstWhere((e) => e.reason == MpvEndFileReason.eof)
          .timeout(const Duration(seconds: 10));

      await player.openAll([first, second], play: true);
      final event = await ended;

      expect(event.media, first);
      // FLAC carries its sample count: the duration is exact, and the
      // first entry's, not the 5 s of the entry that follows.
      expect(event.duration, isNotNull);
      expect(event.duration!.inMilliseconds, closeTo(1000, 5));
      // Gapless: mpv ends the entry once its decoder is done, while the
      // output still holds `audio-buffer` plus the null output's buffer.
      // The position trails the end by at most that much, plus one update
      // of the position: mpv reports it once per playloop wakeup, about
      // every 90 ms on the outputs measured, and the END_FILE can come
      // ahead of the last one.
      final buffered =
          await seconds(player, 'audio-buffer') +
          await seconds(player, 'ao-null-buffer');
      const tick = 0.1;
      final position = event.position;
      expect(position, isNotNull);
      final end = event.duration!.inMicroseconds / 1e6;
      final at = position!.inMicroseconds / 1e6;
      expect(at, lessThanOrEqualTo(end));
      expect(
        at,
        greaterThanOrEqualTo(end - buffered - tick),
        reason: 'buffered $buffered s, tick $tick s',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a stop carries the position where the entry stopped', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final media = Media(fiveSeconds, extras: const {'n': 1});

      await player.open(media, play: true);
      await waitUntil(
        () => player.state.position >= const Duration(milliseconds: 1500),
        timeout: const Duration(seconds: 10),
      );
      final ended = player.stream.endFile.first.timeout(
        const Duration(seconds: 5),
      );
      final seen = player.state.position;
      final clock = Stopwatch()..start();
      await player.stop();
      final event = await ended;
      clock.stop();

      expect(event.reason, MpvEndFileReason.stop);
      expect(event.media, media);
      expect(event.duration, isNotNull);
      expect(event.duration!.inMilliseconds, closeTo(5000, 5));
      // The last position mpv reported: not before what the state showed
      // when stop() was called, and not past it by more than the time the
      // stop took to land (the clock runs at 1x) plus the 33 ms window the
      // state's position can trail the reported one by.
      final position = event.position;
      expect(position, isNotNull);
      expect(position, greaterThanOrEqualTo(seen));
      expect(
        position,
        lessThanOrEqualTo(
          seen + clock.elapsed + const Duration(milliseconds: 33),
        ),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('the last entry parks, and its stop carries the end', () async {
      final player = await buildPlayer();
      addTearDown(player.dispose);
      final media = Media(oneSecond, extras: const {'n': 1});
      final ends = <MpvFileEndedEvent>[];
      final sub = player.stream.endFile.listen(ends.add);
      addTearDown(sub.cancel);

      await player.open(media, play: true);
      await player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 10));
      final parkedAt = player.state.position;

      expect(ends, isEmpty, reason: 'keep-open holds the last entry open');
      expect(parkedAt.inMilliseconds, closeTo(1000, 50));

      await player.stop();
      await waitUntil(() => ends.isNotEmpty);

      final event = ends.single;
      expect(event.reason, MpvEndFileReason.stop);
      expect(event.media, media);
      expect(event.position, isNotNull);
      expect(
        (event.position! - parkedAt).inMicroseconds.abs(),
        lessThan(1000),
        reason: 'the park position, read where the file ended',
      );
      expect(event.duration!.inMilliseconds, closeTo(1000, 5));
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
