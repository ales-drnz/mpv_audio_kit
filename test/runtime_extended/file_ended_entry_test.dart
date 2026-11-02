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
/// Skips the test, and returns true, when the END_FILE of the libmpv does
/// not carry the duration and position of the entry (`mak-end-file-fields`
/// below 4, before libmpv-r21). On CI a run of r21 or later must have them.
Future<bool> _skipWithoutEntryFields(Player player) async {
  final fields = int.tryParse(
    await player.getRawProperty('mak-end-file-fields') ?? '',
  );
  if (fields != null && fields >= 4) return false;
  if (strictLibmpvRelease && expectedLibmpvRelease() >= 21) {
    fail('mak-end-file-fields is $fields on a run of r21');
  }
  markTestSkipped('the libmpv has no mak_duration and mak_position');
  return true;
}

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final oneSecond = '$dir/sine_stereo_1s.flac';
  final fiveSeconds = '$dir/sine_5s.flac';
  final oneSecondWav = '$dir/sine_440hz_1s.wav';
  final fiftyMs = '$dir/sine_50ms.wav';

  /// Seconds of a numeric mpv property.
  Future<double> seconds(Player player, String name) async =>
      double.parse((await player.getRawProperty(name))!);

  runtimeSuite(
    fixturePath: fiveSeconds,
    extraFixtures: [oneSecond, oneSecondWav, fiftyMs],
    () {
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

      // kit-core-2: mpv sends property changes only once its event queue is
      // empty, so an entry that loads and ends within one burst of events got
      // no duration or position, and its END_FILE carried null for both, as
      // for a live stream. The END_FILE of libmpv-r21 carries both. An older
      // libmpv cannot: with gapless audio the entry ends as soon as its
      // decoder is done, before the pump can read anything of it.
      test('an entry of 50 ms carries its duration and position', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        if (await _skipWithoutEntryFields(player)) return;
        final ended = player.stream.endFile
            .firstWhere((e) => e.reason == MpvEndFileReason.eof)
            .timeout(const Duration(seconds: 10));

        await player.openAll([Media(fiftyMs), Media(oneSecond)], play: true);
        final event = await ended;

        expect(event.duration, isNotNull, reason: '$event');
        expect(event.duration!.inMilliseconds, closeTo(50, 5));
        expect(event.position, isNotNull, reason: '$event');
        expect(event.position!.inMilliseconds, inInclusiveRange(0, 55));
      }, timeout: const Timeout(Duration(seconds: 30)));

      // With any libmpv: an entry of 50 ms that parks at the end, then
      // stops. Before libmpv-r21 the duration comes from the read of the
      // pump when the entry loads.
      test('a last entry of 50 ms carries its duration and position at its '
          'stop', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        final ends = <MpvFileEndedEvent>[];
        final sub = player.stream.endFile.listen(ends.add);
        addTearDown(sub.cancel);

        await player.openAll([Media(oneSecond), Media(fiftyMs)], play: true);
        await waitUntil(
          () => ends.isNotEmpty && player.state.completed,
          timeout: const Duration(seconds: 10),
        );
        await player.stop();
        await waitUntil(() => ends.length == 2, reason: '$ends');

        final event = ends.last;
        expect(event.reason, MpvEndFileReason.stop);
        expect(event.duration, isNotNull, reason: '$event');
        expect(event.duration!.inMilliseconds, closeTo(50, 5));
        expect(event.position, isNotNull, reason: '$event');
        expect(event.position!.inMilliseconds, inInclusiveRange(0, 55));
      }, timeout: const Timeout(Duration(seconds: 30)));

      // The END_FILE of libmpv-r21 carries the duration and position of
      // the entry (`mak-end-file-fields` 4). The null output untimed plays
      // every entry out in one burst of events: before, 16 entries in 16
      // ended with no duration and no position.
      test('every entry played untimed carries its duration and '
          'position', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        if (await _skipWithoutEntryFields(player)) return;
        await player.setAudioNullUntimed(true);
        final files = [
          oneSecondWav,
          oneSecond,
          fiftyMs,
          fiveSeconds,
          oneSecond,
        ];
        const lengths = [1000, 1000, 50, 5000, 1000];
        final ends = <MpvFileEndedEvent>[];
        final sub = player.stream.endFile.listen(ends.add);
        addTearDown(sub.cancel);

        await player.openAll([for (final f in files) Media(f)], play: true);
        await waitUntil(
          () => ends.length >= files.length - 1 && player.state.completed,
          timeout: const Duration(seconds: 20),
          reason: 'the playlist never ended: $ends',
        );
        // The last entry parks: its stop ends it.
        await player.stop();
        await waitUntil(() => ends.length == files.length, reason: '$ends');

        for (var i = 0; i < files.length; i++) {
          final e = ends[i];
          final reason = 'entry $i: $e';
          expect(e.duration, isNotNull, reason: reason);
          expect(
            e.duration!.inMilliseconds,
            closeTo(lengths[i], 5),
            reason: reason,
          );
          expect(e.position, isNotNull, reason: reason);
          expect(
            e.position!.inMilliseconds,
            inInclusiveRange(0, lengths[i] + 5),
            reason: reason,
          );
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    },
  );
}
