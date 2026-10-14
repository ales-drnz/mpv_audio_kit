// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

// Live PCM input against the bundled libmpv: chunks fed at real-time pace
// into `mak-pcm://`, played on the null audio output (which keeps real
// time). The bounds are generous; the measured numbers are printed.

const _speech = PcmFormat(sampleRate: 24000, channels: 1);
const _music = PcmFormat(
  sampleRate: 48000,
  channels: 2,
  encoding: PcmEncoding.f32le,
);

/// [ms] of a 440 Hz tone in [f], phase-continuous from frame [frame0].
Uint8List _tone(PcmFormat f, int frame0, int ms) {
  final frames = f.sampleRate * ms ~/ 1000;
  final d = ByteData(frames * f.bytesPerFrame);
  var at = 0;
  for (var i = 0; i < frames; i++) {
    final v = 0.3 * math.sin(2 * math.pi * 440 * (frame0 + i) / f.sampleRate);
    for (var c = 0; c < f.channels; c++) {
      switch (f.encoding) {
        case PcmEncoding.s16le:
          d.setInt16(at, (v * 32767).round(), Endian.little);
        case PcmEncoding.f32le:
          d.setFloat32(at, v, Endian.little);
        default:
          throw UnimplementedError();
      }
      at += f.encoding.bytesPerSample;
    }
  }
  return d.buffer.asUint8List();
}

/// A fake network source: [totalMs] of tone in chunks of [chunkMs], sent
/// at real-time pace, with an extra random delay of up to [jitterMs]
/// before each chunk and, every [burstEvery] chunks, a pause made up by a
/// burst. [split] cuts the bytes at odd offsets instead of whole chunks.
Stream<Uint8List> _feed(
  PcmFormat f, {
  int totalMs = 2000,
  int chunkMs = 40,
  int jitterMs = 0,
  int burstEvery = 0,
  bool split = false,
  void Function()? onFirst,
}) async* {
  final rnd = math.Random(27);
  final start = DateTime.now();
  var sentMs = 0;
  var frame = 0;
  var chunks = 0;
  var pending = <int>[];
  while (sentMs < totalMs) {
    final due = start.add(Duration(milliseconds: sentMs));
    var wait = due.difference(DateTime.now());
    if (jitterMs > 0) wait += Duration(milliseconds: rnd.nextInt(jitterMs));
    if (burstEvery > 0 && chunks % burstEvery == burstEvery - 1) {
      wait += const Duration(milliseconds: 150);
    }
    if (wait > Duration.zero) await Future<void>.delayed(wait);
    final ms = math.min(chunkMs, totalMs - sentMs);
    final pcm = _tone(f, frame, ms);
    frame += pcm.length ~/ f.bytesPerFrame;
    sentMs += ms;
    chunks++;
    if (chunks == 1) onFirst?.call();
    if (!split) {
      yield pcm;
      continue;
    }
    pending = [...pending, ...pcm];
    while (pending.length > 37) {
      final n = 1 + rnd.nextInt(37);
      yield Uint8List.fromList(pending.sublist(0, n));
      pending = pending.sublist(n);
    }
  }
  if (pending.isNotEmpty) yield Uint8List.fromList(pending);
}

/// Polls `time-pos` and `paused-for-cache` while a source plays.
final class _Watch {
  _Watch(this.player);
  final Player player;
  final samples = <(DateTime, double, bool)>[];
  bool _stop = false;

  Future<void> run() async {
    while (!_stop) {
      final tp = double.tryParse(await player.getRawProperty('time-pos') ?? '');
      final pfc = await player.getRawProperty('paused-for-cache') == 'yes';
      if (tp != null) samples.add((DateTime.now(), tp, pfc));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  void stop() => _stop = true;

  /// Wall time at which the playhead was at 0: the first position seen,
  /// moved back by that position.
  DateTime? get started {
    final s = samples.where((s) => s.$2 > 0.02).firstOrNull;
    if (s == null) return null;
    return s.$1.subtract(Duration(microseconds: (s.$2 * 1e6).round()));
  }

  double get lastPos => samples.isEmpty ? 0 : samples.last.$2;

  /// Times `paused-for-cache` went up after playback started.
  int get underruns {
    var n = 0;
    var playing = false;
    var prev = false;
    for (final (_, tp, pfc) in samples) {
      if (tp > 0.05) playing = true;
      if (playing && pfc && !prev) n++;
      prev = pfc;
    }
    return n;
  }
}

void _log(String name, Map<String, Object?> numbers) =>
    // ignore: avoid_print
    print('PCM $name: $numbers');

/// Plays [totalMs] of [f] through openPcmStream with the given feed, and
/// returns the numbers once the entry completed.
Future<Map<String, Object?>> _playThrough(
  PcmFormat f, {
  int totalMs = 2000,
  int chunkMs = 40,
  int jitterMs = 0,
  int burstEvery = 0,
  bool split = false,
}) async {
  final player = await buildPlayer();
  final errors = <PlayerError>[];
  final ends = <MpvFileEndedEvent>[];
  final subs = [
    player.stream.error.listen(errors.add),
    player.stream.endFile.listen(ends.add),
  ];
  final completed = Completer<DateTime>();
  subs.add(
    player.stream.completed.listen((c) {
      if (c && !completed.isCompleted) completed.complete(DateTime.now());
    }),
  );
  final watch = _Watch(player);
  final source = await player.openPcmStream(f);
  unawaited(watch.run());
  DateTime? firstAdd;
  await source.addStream(
    _feed(
      f,
      totalMs: totalMs,
      chunkMs: chunkMs,
      jitterMs: jitterMs,
      burstEvery: burstEvery,
      split: split,
      onFirst: () => firstAdd = DateTime.now(),
    ),
  );
  final lastAdd = DateTime.now();
  final liveDuration = player.state.duration;
  await source.close();
  final end = await completed.future.timeout(
    Duration(milliseconds: totalMs + 10000),
  );
  await Future<void>.delayed(const Duration(milliseconds: 100));
  watch.stop();
  final started = watch.started;
  final numbers = <String, Object?>{
    'startLatencyMs': started?.difference(firstAdd!).inMilliseconds,
    'fedMs': totalMs,
    'timePosAtEnd': watch.lastPos,
    'completedAfterStartMs': started == null
        ? null
        : end.difference(started).inMilliseconds,
    'completedAfterLastAddMs': end.difference(lastAdd).inMilliseconds,
    'underruns': watch.underruns,
    'sourceState': source.state.name,
    'endFile': ends.map((e) => e.reason.name).toList(),
    'liveDurationMs': liveDuration.inMilliseconds,
    'errors': errors.length,
  };
  for (final s in subs) {
    await s.cancel();
  }
  await player.dispose();
  return numbers;
}

void main() {
  runtimeSuite(() {
    const t = Timeout(Duration(seconds: 60));

    for (final (name, f) in [
      ('s16le mono 24 kHz', _speech),
      ('f32le stereo 48 kHz', _music),
    ]) {
      test(
        '$name starts soon and completes after the fed audio played',
        () async {
          final r = await _playThrough(f);
          _log(name, r);
          expect(r['startLatencyMs'], isNotNull);
          expect(r['startLatencyMs']! as int, lessThan(1500));
          // Everything fed played: the playhead reached the fed duration,
          // and completed came no earlier than its playing time.
          expect(r['timePosAtEnd']! as double, greaterThan(1.95));
          expect(
            r['completedAfterStartMs']! as int,
            greaterThanOrEqualTo(1900),
          );
          expect(r['sourceState'], 'drained');
          // mpv reports the audio received so far as the duration.
          expect(r['liveDurationMs']! as int, lessThanOrEqualTo(2000));
          expect(r['errors'], 0);
        },
        timeout: t,
      );
    }

    test('bursts and jitter play without an underrun', () async {
      final r = await _playThrough(
        _speech,
        totalMs: 4000,
        chunkMs: 20,
        jitterMs: 60,
        burstEvery: 10,
      );
      _log('jitter', r);
      expect(r['underruns'], 0);
      expect(r['timePosAtEnd']! as double, greaterThan(3.95));
    }, timeout: t);

    test('odd chunk sizes play the whole input', () async {
      final r = await _playThrough(_music, totalMs: 1500, split: true);
      _log('odd chunks', r);
      expect(r['timePosAtEnd']! as double, greaterThan(1.45));
      expect(r['sourceState'], 'drained');
    }, timeout: t);

    test('abort cuts the entry at once', () async {
      final player = await buildPlayer();
      final ended = Completer<(DateTime, MpvFileEndedEvent)>();
      final sub = player.stream.endFile.listen((e) {
        if (!ended.isCompleted) ended.complete((DateTime.now(), e));
      });
      final source = await player.openPcmStream(_speech);
      final feeding = source.addStream(_feed(_speech, totalMs: 4000));
      await waitUntil(
        () async =>
            (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                0) >
            0.5,
        reason: 'playback reaches 0.5 s',
      );
      final at = DateTime.now();
      source.abort();
      final (endAt, e) = await ended.future.timeout(const Duration(seconds: 3));
      await feeding.timeout(const Duration(seconds: 1));
      final ms = endAt.difference(at).inMilliseconds;
      _log('abort', {'endFileAfterAbortMs': ms, 'reason': e.reason.name});
      expect(ms, lessThan(500));
      expect(source.state, PcmSourceState.aborted);
      await sub.cancel();
      await player.dispose();
    }, timeout: t);

    test('abort of the current source starts the next entry', () async {
      final player = await buildPlayer();
      final a = PcmSource.create(_speech);
      final b = PcmSource.create(_speech);
      b.add(_tone(_speech, 0, 1000));
      await b.close();
      await player.openAll([a.toMedia(), b.toMedia()], play: true);
      final feeding = a.addStream(_feed(_speech, totalMs: 4000));
      await waitUntil(
        () async =>
            (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                0) >
            0.5,
        reason: 'the first source plays',
      );
      final sw = Stopwatch()..start();
      a.abort();
      await waitUntil(
        () => player.state.playlist.index == 1,
        reason: 'the second entry is current',
      );
      final switchMs = sw.elapsedMilliseconds;
      await waitUntil(
        () => b.isDone,
        reason: 'the second source plays to its end',
      );
      await feeding;
      _log('abort to next', {'switchMs': switchMs, 'b': b.state.name});
      expect(switchMs, lessThan(500));
      expect(b.state, PcmSourceState.drained);
      await player.dispose();
    }, timeout: t);

    for (final action in ['stop', 'dispose', 'open']) {
      test('$action while the reader waits for input returns soon', () async {
        final player = await buildPlayer();
        final source = await player.openPcmStream(_speech);
        source.add(_tone(_speech, 0, 500));
        await waitUntil(
          () async =>
              (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                  0) >
              0.1,
          reason: 'playback starts',
        );
        // The reader now waits on an empty buffer.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        final sw = Stopwatch()..start();
        switch (action) {
          case 'stop':
            await player.stop();
          case 'dispose':
            await player.dispose();
          case 'open':
            await player.open(Media(defaultFixturePath()), play: false);
        }
        sw.stop();
        await source.done.timeout(const Duration(seconds: 3));
        _log(action, {
          'returnMs': sw.elapsedMilliseconds,
          'state': source.state.name,
        });
        expect(sw.elapsedMilliseconds, lessThan(2000));
        expect(
          source.state,
          action == 'dispose' ? PcmSourceState.aborted : PcmSourceState.stopped,
        );
        await player.dispose();
      }, timeout: t);
    }

    test('lowLatency starts sooner and stays with its entry', () async {
      final latencies = <bool, int>{};
      for (final low in [false, true]) {
        final player = await buildPlayer();
        final watch = _Watch(player);
        final source = await player.openPcmStream(_speech, lowLatency: low);
        unawaited(watch.run());
        final first = DateTime.now();
        final feeding = source.addStream(_feed(_speech, totalMs: 1000));
        await waitUntil(() => watch.started != null, reason: 'playback starts');
        latencies[low] = watch.started!.difference(first).inMilliseconds;
        expect(
          await player.getRawProperty('audio-buffer'),
          low ? '0.100000' : '0.200000',
        );
        watch.stop();
        await feeding;
        await source.close();
        // The next file gets the player's own buffer back.
        await openAndWaitForLoad(player, defaultFixturePath());
        expect(await player.getRawProperty('audio-buffer'), '0.200000');
        await player.dispose();
      }
      _log('lowLatency', {'startLatencyMs': latencies});
      expect(latencies[true]!, lessThan(1500));
    }, timeout: t);

    test('analysis listeners keep one reader', () async {
      final player = await buildPlayer();
      final scans = <LoudnessScan?>[];
      final waves = <WaveformData?>[];
      final errors = <PlayerError>[];
      final subs = [
        player.stream.waveform.listen(waves.add),
        player.stream.loudnessScan.listen(scans.add),
        player.stream.error.listen(errors.add),
      ];
      final completed = player.stream.completed.firstWhere((c) => c);
      final source = await player.openPcmStream(_speech);
      await source.addStream(_feed(_speech, totalMs: 1500));
      await source.close();
      await completed.timeout(const Duration(seconds: 10));
      await source.done.timeout(const Duration(seconds: 1));
      _log('analysis', {
        'state': source.state.name,
        'scan': scans.isEmpty ? null : scans.last?.state.name,
        'waveforms': waves.length,
        'errors': errors.length,
      });
      expect(source.state, PcmSourceState.drained);
      expect(errors, isEmpty);
      for (final s in subs) {
        await s.cancel();
      }
      await player.dispose();
    }, timeout: t);

    test('two sources queued as a playlist play back to back', () async {
      final player = await buildPlayer();
      final ends = <MpvFileEndedEvent>[];
      final sub = player.stream.endFile.listen(ends.add);
      final a = PcmSource.create(_speech);
      final b = PcmSource.create(_speech);
      final c = PcmSource.create(_speech);
      final completed = player.stream.completed.firstWhere((c) => c);
      await player.openAll([a.toMedia(), b.toMedia()], play: true);
      await player.add(c.toMedia());
      // Fed ahead of time, as a generator faster than real time would:
      // the gaps measured are the player's own.
      for (final s in [a, b, c]) {
        s.add(_tone(_speech, 0, 1000));
        await s.close();
      }
      final sw = Stopwatch()..start();
      await waitUntil(
        () async =>
            (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                0) >
            0,
        reason: 'playback starts',
      );
      final started = sw.elapsedMilliseconds;
      await completed.timeout(const Duration(seconds: 10));
      final total = sw.elapsedMilliseconds - started;
      _log('playlist', {
        'playedMs': total,
        'gapPerTransitionMs': (total - 3000) / 2,
        'endFile': ends.map((e) => e.reason.name).toList(),
        'states': [a, b, c].map((s) => s.state.name).toList(),
      });
      // keep-open parks the last entry: two ends, both at their end.
      expect(ends.map((e) => e.reason), [
        MpvEndFileReason.eof,
        MpvEndFileReason.eof,
      ]);
      expect(total, greaterThan(2900));
      expect(
        [a, b, c].map((s) => s.state),
        everyElement(PcmSourceState.drained),
      );
      await sub.cancel();
      await player.dispose();
    }, timeout: t);

    test('a seek on a live entry does nothing', () async {
      final player = await buildPlayer();
      final source = await player.openPcmStream(_speech);
      final feeding = source.addStream(_feed(_speech, totalMs: 3000));
      await waitUntil(
        () async =>
            (double.tryParse(await player.getRawProperty('time-pos') ?? '') ??
                0) >
            1.0,
        reason: 'playback reaches 1 s',
      );
      Object? error;
      try {
        await player.seek(const Duration(milliseconds: 100));
      } catch (e) {
        error = e;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
      final pos = double.parse(await player.getRawProperty('time-pos') ?? '0');
      _log('seek', {
        'error': '$error',
        'posAfter': pos,
        'seekable': await player.getRawProperty('seekable'),
      });
      expect(pos, greaterThan(1.0));
      source.abort();
      await feeding;
      await player.dispose();
    }, timeout: t);
  });
}
