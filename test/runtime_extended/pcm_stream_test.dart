// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

// Live PCM input against the bundled libmpv: chunks fed at real-time pace
// into `mak-pcm://`, played on the null audio output (which keeps real
// time). The bounds leave room for a loaded machine; the measured numbers
// are printed.

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
  List<(int, DateTime)>? arrivals,
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
    arrivals?.add((sentMs, DateTime.now()));
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

/// Polls `time-pos` while a source plays.
final class _Watch {
  _Watch(this.player);
  final Player player;
  final samples = <(DateTime, double)>[];
  bool _stop = false;
  Future<void>? _loop;

  void start() => _loop = _run();

  Future<void> _run() async {
    while (!_stop) {
      final tp = double.tryParse(await player.getRawProperty('time-pos') ?? '');
      if (tp != null) samples.add((DateTime.now(), tp));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  /// Ends the polling and waits for the poll in flight, so the player
  /// can be disposed after it.
  Future<void> stop() async {
    _stop = true;
    await _loop;
  }

  /// Wall time at which the playhead was at 0: the first position seen,
  /// moved back by that position.
  DateTime? get started {
    final s = samples.where((s) => s.$2 > 0.02).firstOrNull;
    if (s == null) return null;
    return s.$1.subtract(Duration(microseconds: (s.$2 * 1e6).round()));
  }

  double get lastPos => samples.isEmpty ? 0 : samples.last.$2;
}

/// Allocates garbage until [done] or a few rounds have passed, to give
/// the GC a chance to collect what nothing holds.
Future<void> _churn(bool Function() done) async {
  for (var i = 0; i < 40 && !done(); i++) {
    final junk = [for (var j = 0; j < 64; j++) Uint8List(1 << 20)];
    junk.clear();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void _log(String name, Map<String, Object?> numbers) =>
    // ignore: avoid_print
    print('PCM $name: $numbers');

/// Underruns of the null output while a 5 s file plays: the control for
/// a host that stalls mpv whatever it plays.
Future<int> _fileUnderruns() async {
  final player = await buildPlayer(
    configuration: const PlayerConfiguration(), // logs from warn up
  );
  var underruns = 0;
  final sub = player.stream.log.listen((l) {
    if (l.text.contains('Audio device underrun')) underruns++;
  });
  final done = player.stream.completed.firstWhere((c) => c);
  await player.open(
    Media('${Directory.current.path}/test/fixtures/sine_5s.flac'),
    play: true,
  );
  await done.timeout(const Duration(seconds: 20));
  await sub.cancel();
  await player.dispose();
  return underruns;
}

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
  // Warnings on: mpv logs each time the audio output ran dry. The source
  // loads with cache-pause=no, so paused-for-cache never tells.
  final player = await buildPlayer(
    configuration: const PlayerConfiguration(), // logs from warn up
  );
  final errors = <PlayerError>[];
  final ends = <MpvFileEndedEvent>[];
  var underruns = 0;
  final subs = [
    player.stream.error.listen(errors.add),
    player.stream.endFile.listen(ends.add),
    player.stream.log.listen((l) {
      if (l.text.contains('Audio device underrun')) underruns++;
    }),
  ];
  final completed = Completer<DateTime>();
  subs.add(
    player.stream.completed.listen((c) {
      if (c && !completed.isCompleted) completed.complete(DateTime.now());
    }),
  );
  final watch = _Watch(player);
  final source = await player.openPcmStream(f);
  watch.start();
  DateTime? firstAdd;
  final arrivals = <(int, DateTime)>[];
  await source.addStream(
    _feed(
      f,
      totalMs: totalMs,
      chunkMs: chunkMs,
      jitterMs: jitterMs,
      burstEvery: burstEvery,
      split: split,
      onFirst: () => firstAdd = DateTime.now(),
      arrivals: arrivals,
    ),
  );
  final lastAdd = DateTime.now();
  final liveDuration = player.state.duration;
  await source.close();
  final end = await completed.future.timeout(
    Duration(milliseconds: totalMs + 10000),
  );
  final finalDuration = player.state.duration;
  await Future<void>.delayed(const Duration(milliseconds: 100));
  await watch.stop();
  final started = watch.started;
  final numbers = <String, Object?>{
    'startLatencyMs': started?.difference(firstAdd!).inMilliseconds,
    'fedMs': totalMs,
    'timePosAtEnd': watch.lastPos,
    'completedAfterStartMs': started == null
        ? null
        : end.difference(started).inMilliseconds,
    'completedAfterLastAddMs': end.difference(lastAdd).inMilliseconds,
    'underruns': underruns,
    // How far ahead of the playhead the latest chunk arrived: the playhead
    // reaches a chunk's start `sentMs` after playback started, if it never
    // ran dry. Below zero the feed itself was late for the output.
    'minLeadMs': started == null
        ? null
        : arrivals
              .map(
                (a) =>
                    started.add(Duration(milliseconds: a.$1)).difference(a.$2),
              )
              .reduce((a, b) => a < b ? a : b)
              .inMilliseconds,
    'sourceState': source.state.name,
    'endFile': ends.map((e) => e.reason.name).toList(),
    'liveDurationMs': liveDuration.inMilliseconds,
    'finalDurationMs': finalDuration.inMilliseconds,
    'errors': errors.length,
  };
  for (final s in subs) {
    await s.cancel();
  }
  await player.dispose();
  return numbers;
}

/// Queues [first] then a closed source no Dart variable keeps, paused,
/// and returns a weak reference to that second source.
Future<WeakReference<PcmSource>> _queueDropped(
  Player player,
  PcmSource first,
) async {
  final second = PcmSource.create(_speech);
  second.add(_tone(_speech, 0, 300));
  await second.close();
  await player.openAll([first.toMedia(), second.toMedia()], play: false);
  return WeakReference(second);
}

/// Queues [n] closed sources of 0.5 s that no Dart variable keeps,
/// paused, and returns weak references to them.
Future<List<WeakReference<PcmSource>>> _queueClosed(
  Player player,
  int n,
) async {
  final sources = [for (var i = 0; i < n; i++) PcmSource.create(_speech)];
  for (final s in sources) {
    s.add(_tone(_speech, 0, 500));
    await s.close();
  }
  await player.openAll([for (final s in sources) s.toMedia()], play: false);
  return [for (final s in sources) WeakReference(s)];
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
          // About 165 ms here (audio-buffer 0.2 s less the first 40 ms
          // chunk): three times that is a regression, not a slow machine.
          expect(r['startLatencyMs']! as int, lessThan(500));
          // Everything fed played: the playhead reached the fed duration,
          // and completed came no earlier than its playing time.
          expect(r['timePosAtEnd']! as double, greaterThan(1.95));
          expect(
            r['completedAfterStartMs']! as int,
            greaterThanOrEqualTo(1900),
          );
          expect(r['sourceState'], 'drained');
          // mpv reports the audio received so far as the duration (1920
          // ms here: it counts packets by their start).
          expect(r['liveDurationMs']! as int, lessThanOrEqualTo(2000));
          expect(r['liveDurationMs']! as int, greaterThan(1500));
          // At the end it can stay one packet short of the fed audio, below
          // the position the playhead reached.
          expect(r['finalDurationMs']! as int, inInclusiveRange(1900, 2000));
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
      // The feed paces by absolute deadlines, so the start delay is the
      // lead every later chunk gets. A host whose timers fall behind by
      // more than that runs the output dry by design, not by a fault of
      // the source: the check holds when the feed kept a lead.
      final lead = r['minLeadMs']! as int;
      if (lead < 40) {
        markTestSkipped('the host fed $lead ms ahead of the playhead');
        return;
      }
      // A virtual host can stall mpv's own threads past the buffer: the
      // macOS runners run a plain file dry too, a few seconds at a time.
      // A file played right after tells the host apart from the source.
      if (r['underruns'] != 0) {
        // The stalls come in bursts, so one clean file can miss them.
        var control = 0;
        for (var i = 0; i < 3 && control == 0; i++) {
          control = await _fileUnderruns();
        }
        if (control > 0) {
          markTestSkipped(
            'the host ran a plain file dry too ($control underruns)',
          );
          return;
        }
      }
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

    test(
      'abort removes its entry when the app removes another meanwhile',
      () async {
        // mpv removes by index: an entry the app takes out between the cut's
        // read of the playlist and its removal moves the source up by one,
        // and the index read before names the entry after it.
        final player = await buildPlayer();
        final fixtures = '${Directory.current.path}/test/fixtures';
        final playing = '$fixtures/sine_5s.flac';
        final other = '$fixtures/sine_stereo_1s.flac';
        final last = '$fixtures/sine_440hz_1s.wav';
        final source = PcmSource.create(_speech);
        source.add(_tone(_speech, 0, 1000));
        await player.openAll([
          Media(playing),
          Media(other),
          source.toMedia(),
          Media(last),
        ], play: true);
        await waitUntil(() => player.state.playing, reason: 'the file plays');
        expect(player.state.playlist.items, hasLength(4));
        player.debugBeforePcmCutRemove = () async {
          player.debugBeforePcmCutRemove = null;
          await player.sendRawCommand(['playlist-remove', '1']);
        };
        source.abort();
        await waitUntil(
          () => player.state.playlist.items.length == 2,
          timeout: const Duration(seconds: 2),
          reason: 'the aborted entry and the removed one are still queued',
        );
        expect(player.state.playlist.items.map((m) => m.uri), [playing, last]);
        await player.dispose();
      },
    );

    test('abort of a queued source removes its entry', () async {
      final player = await buildPlayer();
      final errors = <PlayerError>[];
      final ends = <MpvFileEndedEvent>[];
      final subs = [
        player.stream.error.listen(errors.add),
        player.stream.endFile.listen(ends.add),
      ];
      final file = defaultFixturePath();
      final source = PcmSource.create(_speech);
      source.add(_tone(_speech, 0, 1000));
      await player.openAll([Media(file), source.toMedia()], play: true);
      await waitUntil(() => player.state.playing, reason: 'the file plays');
      expect(player.state.playlist.items, hasLength(2));
      source.abort();
      await waitUntil(
        () => player.state.playlist.items.length == 1,
        timeout: const Duration(seconds: 1),
        reason: 'the aborted entry is still queued',
      );
      expect(player.state.playlist.items.single.uri, file);
      // The file plays to its end, with no load of the aborted entry
      // failing after it.
      await waitUntil(
        () => player.state.completed,
        reason: 'the file completes',
      );
      _log('abort queued', {
        'state': source.state.name,
        'endFile': ends.map((e) => e.reason.name).toList(),
      });
      expect(source.state, PcmSourceState.aborted);
      expect(errors, isEmpty);
      expect(
        ends.map((e) => e.reason),
        isNot(contains(MpvEndFileReason.error)),
      );
      for (final s in subs) {
        await s.cancel();
      }
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
        expect(source.state, PcmSourceState.stopped);
        await player.dispose();
      }, timeout: t);
    }

    test('lowLatency sets audio-buffer for its entry only', () async {
      // audio-buffer is an option of the entry: this holds on the null
      // output too, so it runs on every host.
      for (final low in [false, true]) {
        final player = await buildPlayer();
        final watch = _Watch(player);
        final source = await player.openPcmStream(_speech, lowLatency: low);
        watch.start();
        final feeding = source.addStream(_feed(_speech, totalMs: 300));
        await waitUntil(() => watch.started != null, reason: 'playback starts');
        expect(
          await player.getRawProperty('audio-buffer'),
          low ? '0.100000' : '0.200000',
        );
        await watch.stop();
        await feeding;
        await source.close();
        // The next file gets the player's own buffer back.
        await openAndWaitForLoad(player, defaultFixturePath());
        expect(await player.getRawProperty('audio-buffer'), '0.200000');
        await player.dispose();
      }
    }, timeout: t);

    test('lowLatency starts sooner on a real output', () async {
      // The null output ignores audio-buffer: the comparison needs a real
      // one, muted. Asked first, so a host without a device skips before
      // six players do their work for nothing.
      final ao = await probeAudioOutput();
      if (ao == null || ao == 'null') {
        skipWithoutAudioDevice(
          'no audio device: the null output has no buffer to cut',
        );
        return;
      }
      final latencies = <bool, List<int>>{false: [], true: []};
      for (var round = 0; round < 3; round++) {
        for (final low in [false, true]) {
          final player = await buildPlayer();
          await player.setRawProperty('ao', realAudioOutputs);
          await player.setVolume(0);
          final watch = _Watch(player);
          final source = await player.openPcmStream(_speech, lowLatency: low);
          watch.start();
          final first = DateTime.now();
          final feeding = source.addStream(_feed(_speech, totalMs: 600));
          await waitUntil(
            () => watch.started != null,
            reason: 'playback starts',
          );
          latencies[low]!.add(watch.started!.difference(first).inMilliseconds);
          expect(
            await player.getRawProperty('current-ao'),
            ao,
            reason: 'every round plays on the output the probe found',
          );
          await watch.stop();
          await feeding;
          await source.close();
          await player.dispose();
        }
      }
      int median(List<int> v) => (v.toList()..sort())[v.length ~/ 2];
      _log('lowLatency', {'ao': ao, 'startLatencyMs': latencies});
      expect(
        median(latencies[true]!),
        lessThan(median(latencies[false]!) - 20),
      );
    }, timeout: t);

    test('a queued source the app dropped still plays', () async {
      final player = await buildPlayer();
      final ends = <MpvFileEndedEvent>[];
      final sub = player.stream.endFile.listen(ends.add);
      final first = PcmSource.create(_speech);
      first.add(_tone(_speech, 0, 300));
      await first.close();
      // The second source is referenced by its playlist entry only.
      final weak = await _queueDropped(player, first);
      // Give the GC a chance: if nothing held it, the finalizer would
      // release the finished, unread source and its entry fail to load.
      await _churn(() => weak.target == null);
      expect(weak.target, isNotNull, reason: 'its queued entry holds it');
      await player.play();
      await waitUntil(
        () => ends.isNotEmpty && player.state.completed,
        timeout: const Duration(seconds: 10),
        reason: 'both entries play',
      );
      _log('dropped source', {
        'endFile': ends.map((e) => '${e.reason.name}:${e.error}').toList(),
      });
      expect(ends.single.reason, MpvEndFileReason.eof);
      expect(player.state.playlist.index, 1);
      expect(
        double.parse(await player.getRawProperty('time-pos') ?? '0'),
        greaterThan(0.25),
      );
      await sub.cancel();
      await player.dispose();
    }, timeout: t);

    test('with prefetch on, dropped queued sources all play', () async {
      final player = await buildPlayer();
      await player.setPrefetchPlaylist(true);
      final ends = <MpvFileEndedEvent>[];
      final sub = player.stream.endFile.listen(ends.add);
      final weak = await _queueClosed(player, 3);
      await _churn(() => weak.every((w) => w.target == null));
      expect(
        weak.where((w) => w.target != null),
        hasLength(3),
        reason: 'their queued entries hold them',
      );
      final sw = Stopwatch()..start();
      await player.play();
      await waitUntil(
        () => ends.length == 2 && player.state.completed,
        timeout: const Duration(seconds: 10),
        reason: 'the three entries play',
      );
      final pos = double.parse(await player.getRawProperty('time-pos') ?? '0');
      _log('prefetch', {
        'playedMs': sw.elapsedMilliseconds,
        'endFile': ends.map((e) => '${e.reason.name}:${e.error}').toList(),
        'lastPos': pos,
      });
      expect(ends.map((e) => e.reason), [
        MpvEndFileReason.eof,
        MpvEndFileReason.eof,
      ]);
      expect(player.state.playlist.index, 2);
      expect(pos, greaterThan(0.45));
      expect(sw.elapsedMilliseconds, greaterThan(1400));
      await sub.cancel();
      await player.dispose();
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
      // The waveform rolls with the live input; the scan has no file to read.
      expect(waves.any((w) => w != null && w.live), isTrue);
      expect(scans.last?.state, LoudnessScanState.unavailable);
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

    for (final cache in [Cache.auto, Cache.yes]) {
      test(
        'a seek on a live entry does nothing, cache ${cache.name}',
        () async {
          final player = await buildPlayer();
          // With the cache forced on, mpv would seek back in what it cached.
          await player.setCache(player.state.cache.copyWith(mode: cache));
          final source = await player.openPcmStream(_speech);
          final feeding = source.addStream(_feed(_speech, totalMs: 3000));
          await waitUntil(
            () async =>
                (double.tryParse(
                      await player.getRawProperty('time-pos') ?? '',
                    ) ??
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
          final pos = double.parse(
            await player.getRawProperty('time-pos') ?? '0',
          );
          _log('seek', {
            'error': '$error',
            'posAfter': pos,
            'seekable': await player.getRawProperty('seekable'),
          });
          expect(pos, greaterThan(1.0));
          expect(await player.getRawProperty('seekable'), 'no');
          source.abort();
          await feeding;
          await player.dispose();
        },
        timeout: t,
      );
    }
  });
}
