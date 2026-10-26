// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform and loudness scan of a remote HTTP file read the packets
// mpv's demuxer already downloaded (#22). When one clean pass from the
// start of the file to its end is not possible, the analysis opens the URL
// a second time, as it always did. Both ways the result must be the one of
// the same file opened as a local path (for Matroska, the one of the
// re-open: see setUpAll).
//
// A loopback server (test/_helpers/range_http_server.dart) logs every
// request. mpv opens the URL once, from byte 0 (for a WAV it asks again
// from the start of the samples); any later GET from byte 0 is the
// analysis opening the file again. The counts are computed from the
// scenario, never from byte totals that depend on timing.

@TestOn('linux || mac-os || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

/// A 16-bit PCM WAV of [seconds] at 48 kHz stereo whose level changes
/// along the file, so every waveform bin and the loudness gate carry
/// something to compare. Deterministic: the same bytes on every run.
Uint8List _makeWav(int seconds) {
  const rate = 48000;
  const channels = 2;
  final frames = rate * seconds;
  final data = ByteData(frames * channels * 2);
  for (var i = 0; i < frames; i++) {
    final t = i / rate;
    // A slow swell, a 400 ms silent hole each 6 s, two tones.
    final swell = 0.15 + 0.7 * (0.5 + 0.5 * math.sin(2 * math.pi * t / 7));
    final hole = (t % 6) > 5.6 ? 0.0 : 1.0;
    final l = swell * hole * math.sin(2 * math.pi * 440 * t);
    final r = swell * hole * 0.6 * math.sin(2 * math.pi * 660 * t + 0.3);
    data.setInt16(i * 4, (l * 32767).round(), Endian.little);
    data.setInt16(i * 4 + 2, (r * 32767).round(), Endian.little);
  }
  final pcm = data.buffer.asUint8List();
  final header = ByteData(44);
  void ascii(int at, String s) {
    for (var k = 0; k < s.length; k++) {
      header.setUint8(at + k, s.codeUnitAt(k));
    }
  }

  ascii(0, 'RIFF');
  header.setUint32(4, 36 + pcm.length, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  header.setUint32(16, 16, Endian.little);
  header.setUint16(20, 1, Endian.little);
  header.setUint16(22, channels, Endian.little);
  header.setUint32(24, rate, Endian.little);
  header.setUint32(28, rate * channels * 2, Endian.little);
  header.setUint16(32, channels * 2, Endian.little);
  header.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  header.setUint32(40, pcm.length, Endian.little);
  return (BytesBuilder(copy: false)
        ..add(header.buffer.asUint8List())
        ..add(pcm))
      .toBytes();
}

/// The settled result of one analysis pass.
final class _Analysis {
  _Analysis(this.wave, this.loudness);

  final WaveformData wave;
  final LoudnessScan loudness;
}

bool _terminal(LoudnessScan? s) =>
    s != null &&
    (s.state == LoudnessScanState.ready ||
        s.state == LoudnessScanState.failed ||
        s.state == LoudnessScanState.unavailable);

/// Whether [w] is a settled envelope that holds all its audio: the filled
/// bins run from the start with no hole. A file shorter than the length mpv
/// estimated ends with an unfilled tail.
bool _complete(WaveformData? w) {
  if (w == null || w.decoding || w.live) return false;
  final tail = w.filled.indexWhere((b) => b == 0);
  return tail != 0 && (tail < 0 || w.filled.skip(tail).every((b) => b == 0));
}

/// [w] in a failure message: whether it is a partial and the bins filled.
String _show(WaveformData? w) => w == null
    ? 'null'
    : 'decoding=${w.decoding} filled='
          '${w.filled.where((b) => b != 0).length}/${w.filled.length}';

/// The native state of the analyzer (`ready`, `decoding`, `progressive`,
/// `failed`, ...), or `null` when there is none.
Future<String?> _nativeState(Player player) async {
  final node = await player.getRawPropertyNode('waveform-data');
  return node is Map ? node['state'] as String? : null;
}

/// Watches the waveform and the loudness scan of [player] from now on.
/// Subscribing arms both analyzers (they are listener-gated).
final class _Watch {
  _Watch(this.player) {
    _wave = player.stream.waveform.listen((w) {
      waves.add(w);
      wave = w;
      _note('waveform ${_show(w)}');
    });
    _loud = player.stream.loudnessScan.listen((s) {
      scans.add(s);
      loudness = s;
      _note('loudness ${s?.state.name}');
    });
  }

  final Player player;
  final List<WaveformData?> waves = [];
  final List<LoudnessScan?> scans = [];
  WaveformData? wave;
  LoudnessScan? loudness;
  late final StreamSubscription<WaveformData?> _wave;
  late final StreamSubscription<LoudnessScan?> _loud;
  final Stopwatch _clock = Stopwatch()..start();
  final List<String> _trace = [];
  String? _lastState;

  void _note(String what) {
    _trace.add('${_clock.elapsedMilliseconds} ms $what');
    // A log at verbose level runs long: the end tells the most.
    if (_trace.length > 400) _trace.removeAt(0);
  }

  /// What the watch saw, from its start: the stream values and the native
  /// states [settle] read, for failure messages.
  String describe() => _trace.isEmpty
      ? '  (nothing seen)'
      : _trace.map((l) => '  $l').join('\n');

  /// Waits for the native analyzer to settle (`ready` or `failed`) and for
  /// the loudness scan to reach a terminal state. Fails with [log] when it
  /// does not within [timeout]: an analysis that never settles is a hang.
  Future<_Analysis?> settle(
    String Function() log, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    final deadline = DateTime.now().add(timeout);
    DateTime? readyAt;
    while (true) {
      final state = await _nativeState(player);
      if (state != _lastState) _note('native $state');
      _lastState = state;
      if (state == 'failed' && _terminal(loudness)) return null;
      if (state == 'ready' && _terminal(loudness)) {
        readyAt ??= DateTime.now();
        // The stream delivers the final envelope on its next poll. One
        // that stays incomplete is returned as it is, for the caller's
        // coverage check to report.
        final w = wave;
        final grace =
            DateTime.now().difference(readyAt) > const Duration(seconds: 1);
        if (w != null && !w.decoding && (_complete(w) || grace)) {
          return _Analysis(w, loudness!);
        }
      }
      if (DateTime.now().isAfter(deadline)) {
        fail(
          'analysis did not settle within $timeout (native state $state, '
          'waveform ${_show(wave)}, loudness ${loudness?.state}), seen:\n'
          '${describe()}\nrequests:\n${log()}',
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> cancel() async {
    await _wave.cancel();
    await _loud.cancel();
  }
}

/// Opens [media] on a fresh player and returns its settled analysis.
Future<_Analysis> _analyzeLocal(String path) async {
  final player = await buildPlayer();
  final watch = _Watch(player);
  try {
    await player.open(Media(path), play: false);
    final a = await watch.settle(() => '(local file $path)');
    expect(a, isNotNull, reason: 'the local analysis of $path failed');
    expect(a!.loudness.state, LoudnessScanState.ready);
    return a;
  } finally {
    await watch.cancel();
    await player.dispose();
  }
}

/// Opens [name] (with [bytes]) over HTTP on a fresh player whose demuxer
/// cache is smaller than the file, so the analysis takes the re-open path
/// (the only network path before #22), and returns its settled analysis.
Future<_Analysis> _analyzeHttpReopen(String name, Uint8List bytes) async {
  final server = await RangeHttpServer.start({name: bytes});
  final player = await buildPlayer();
  final watch = _Watch(player);
  try {
    await player.setDemuxer(
      player.state.demuxer.copyWith(maxBytes: bytes.length ~/ 2),
    );
    await player.open(Media(server.url(name)), play: true);
    final a = await watch.settle(server.describe);
    expect(a, isNotNull, reason: 'the network analysis of $name failed');
    expect(a!.loudness.state, LoudnessScanState.ready);
    expect(
      _fromStart(server, '/$name').length,
      greaterThanOrEqualTo(2),
      reason: 'the reference of $name did not re-open\n${server.describe()}',
    );
    return a;
  } finally {
    await watch.cancel();
    await player.dispose();
    await server.close();
  }
}

/// The analysis of a network pass equals the local one: the same bins and
/// the same loudness.
void _expectSame(_Analysis got, _Analysis ref, String log) {
  final w = got.wave;
  final r = ref.wave;
  final covered = w.filled.where((b) => b != 0).length;
  expect(
    _complete(w),
    isTrue,
    reason:
        'a settled envelope covers its bins from the start, with no hole: '
        'this one $covered of ${w.bins}\n$log',
  );
  expect(w.bins, r.bins, reason: 'bin count\n$log');
  expect(w.duration, r.duration, reason: 'duration\n$log');
  var minDiffs = 0, maxDiffs = 0, rmsDiffs = 0, filledDiffs = 0;
  var first = -1;
  for (var i = 0; i < r.bins; i++) {
    final dMin = w.min[i] != r.min[i];
    final dMax = w.max[i] != r.max[i];
    final dRms = r.rms != null && w.rms![i] != r.rms![i];
    final dFilled = w.filled[i] != r.filled[i];
    if (dMin) minDiffs++;
    if (dMax) maxDiffs++;
    if (dRms) rmsDiffs++;
    if (dFilled) filledDiffs++;
    if (first < 0 && (dMin || dMax || dRms || dFilled)) first = i;
  }
  final at = math.max(first, 0);
  expect(
    minDiffs + maxDiffs + rmsDiffs + filledDiffs,
    0,
    reason:
        'of ${r.bins} bins, $minDiffs min, $maxDiffs max, $rmsDiffs rms and '
        '$filledDiffs filled differ from the reference (first at bin '
        '$first: min ${w.min[at]} vs ${r.min[at]}, max ${w.max[at]} vs '
        '${r.max[at]}, rms ${w.rms?[at]} vs ${r.rms?[at]}, filled '
        '${w.filled[at]} vs ${r.filled[at]})\n$log',
  );
  final l = got.loudness;
  final lr = ref.loudness;
  expect(l.state, LoudnessScanState.ready, reason: 'loudness state\n$log');
  String show(LoudnessScan s) =>
      'I ${s.integrated} LRA ${s.range} SP ${s.samplePeak} '
      'TP ${s.truePeak} blocks ${s.gatedBlockCount}';
  final same =
      l.samplePeak == lr.samplePeak &&
      l.truePeak == lr.truePeak &&
      l.gatedBlockCount == lr.gatedBlockCount &&
      (l.integrated! - lr.integrated!).abs() <= _luTolerance &&
      (l.range! - lr.range!).abs() <= _luTolerance;
  expect(
    same,
    isTrue,
    reason: 'loudness ${show(l)}\n   local ${show(lr)}\n$log',
  );
}

/// How far the integrated loudness and the loudness range of a network pass
/// may sit from the local analysis. The local file is decoded by several
/// workers whose gating blocks are merged, while a network file is read by
/// one reader (the cache feed or the single-worker re-open): the two land
/// under 1e-4 LU apart. Bins and peaks match exactly.
const _luTolerance = 0.001;

/// The GETs of [path] that start at byte 0: mpv's first open, then one per
/// time the analysis opened the file again.
List<ServedRequest> _fromStart(RangeHttpServer server, String path) =>
    server.gets(path).where((r) => r.start == 0).toList();

/// Waits for mpv's first file-loaded signal after [open].
Future<void> _openAndLoad(
  Player player,
  Future<void> Function() open, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final loaded = player.stream.seekCompleted.first.timeout(timeout);
  await open();
  await loaded;
}

void main() {
  final fixtures = '${Directory.current.path}/test/fixtures';
  final flacPath = '$fixtures/sine_stereo_48k_5s.flac';
  final mkaPath = '$fixtures/multitrack_two_audio_5s.mka';
  final webmPath = '$fixtures/codec/webm_opus.webm';

  analysisSuite(extraFixtures: [flacPath, mkaPath, webmPath], () {
    late Directory tmp;
    late String wavPath;
    late Uint8List wav;
    late Uint8List flac;
    late Uint8List mka;
    late _Analysis wavRef;
    late _Analysis flacRef;
    late _Analysis mkaRef;
    late Uint8List webm;
    late _Analysis webmRef;
    late Uint8List longWav;
    late RangeHttpServer server;
    Player? player;
    _Watch? watch;

    const wavName = 'swell_20s.wav';
    const flacName = 'sine_stereo_48k_5s.flac';
    const mkaName = 'multitrack_two_audio_5s.mka';
    const webmName = 'webm_opus.webm';
    const longName = 'swell_120s.wav';

    setUpAll(() async {
      tmp = await Directory.systemTemp.createTemp('mak_cache_feed_');
      wav = _makeWav(20);
      longWav = _makeWav(120);
      wavPath = '${tmp.path}/$wavName';
      await File(wavPath).writeAsBytes(wav);
      flac = await File(flacPath).readAsBytes();
      mka = await File(mkaPath).readAsBytes();
      // The bulk path: the same files opened as local paths.
      wavRef = await _analyzeLocal(wavPath);
      flacRef = await _analyzeLocal(flacPath);
      webm = await File(webmPath).readAsBytes();
      // Matroska timestamps are rounded to the millisecond, and the local
      // decode, split over several workers, places each region by them:
      // its bins differ from one sequential reader's, before #22 as well.
      // The reference of these files is the network result before #22, the
      // single reader of the re-open, which the cache feed must match.
      mkaRef = await _analyzeHttpReopen(mkaName, mka);
      webmRef = await _analyzeHttpReopen(webmName, webm);
    });

    tearDownAll(() async {
      await tmp.delete(recursive: true);
    });

    setUp(() async {
      server = await RangeHttpServer.start({
        wavName: wav,
        flacName: flac,
        mkaName: mka,
        webmName: webm,
        longName: longWav,
      });
      player = await buildPlayer();
      watch = _Watch(player!);
      // The analysis is one per process: a fresh player must not start
      // from the result of the one before.
      watch!._note('native ${await _nativeState(player!)} before the open');
    });

    tearDown(() async {
      // MAK_HTTP_LOG=1 prints the requests and what the watch saw in every
      // test, not only in a failing one.
      if (Platform.environment['MAK_HTTP_LOG'] != null) {
        // ignore: avoid_print
        print('${server.describe()}\n${watch?.describe()}');
      }
      await watch?.cancel();
      watch = null;
      await player?.dispose();
      player = null;
      await server.close();
    });

    String log() => server.describe();

    /// Polls [condition] like [waitUntil], with the request log in the
    /// failure message as it is when the wait gives up.
    Future<void> waitFor(
      FutureOr<bool> Function() condition,
      String what, {
      Duration timeout = const Duration(seconds: 10),
      FutureOr<String> Function()? detail,
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (!await condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('$what within $timeout${await detail?.call() ?? ''}\n${log()}');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    group('clean pass, one download', () {
      test('a WAV played from its start is analysed from the cache', () async {
        // Throttled, so the feed follows packets as mpv downloads them
        // instead of replaying a cache that is already complete.
        server.bytesPerSecond = 2 * 1024 * 1024;
        await player!.open(Media(server.url(wavName)), play: true);
        final a = (await watch!.settle(log))!;

        // mpv reads the WAV header from byte 0, then asks again from the
        // start of the samples: one open, which the analysis must not add
        // to.
        expect(
          _fromStart(server, '/$wavName'),
          hasLength(1),
          reason: 'a clean pass must not open the URL a second time\n${log()}',
        );
        expect(server.gets('/$wavName').last.completed, isTrue, reason: log());
        expect(
          server.bytesSent('/$wavName'),
          lessThan(wav.length * 3 ~/ 2),
          reason: 'the file must be downloaded once\n${log()}',
        );
        _expectSame(a, wavRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('a FLAC played from its start is analysed from the cache', () async {
        await player!.open(Media(server.url(flacName)), play: true);
        final a = (await watch!.settle(log))!;

        final gets = server.gets('/$flacName');
        expect(
          gets,
          hasLength(1),
          reason: 'a clean pass must not open the URL a second time\n${log()}',
        );
        expect(gets.single.bytesSent, flac.length, reason: log());
        _expectSame(a, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test(
        'a Matroska file played from its start is analysed from the cache',
        () async {
          // Millisecond timestamps: the feed must place the samples where
          // one sequential reader does, not where each rounded packet
          // timestamp says.
          await player!.open(Media(server.url(mkaName)), play: true);
          final a = (await watch!.settle(log))!;
          expect(server.gets('/$mkaName'), hasLength(1), reason: log());
          _expectSame(a, mkaRef, log());
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test(
        'a WebM Opus file played from its start is analysed from the cache',
        () async {
          await player!.open(Media(server.url(webmName)), play: true);
          final a = (await watch!.settle(log))!;
          expect(server.gets('/$webmName'), hasLength(1), reason: log());
          _expectSame(a, webmRef, log());
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test('a file opened paused is analysed from the cache', () async {
        await player!.open(Media(server.url(flacName)), play: false);
        final a = (await watch!.settle(log))!;
        expect(server.gets('/$flacName'), hasLength(1), reason: log());
        _expectSame(a, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test(
        'a file looping on itself is analysed once, from the cache',
        () async {
          // Untimed: the loop comes back to the start as soon as the
          // throttled download reaches the end.
          await player!.setAudioNullUntimed(true);
          await player!.setLoop(Loop.file);
          server.bytesPerSecond = 48 * 1024;
          var wraps = 0;
          var last = Duration.zero;
          final pos = player!.stream.position.listen((p) {
            if (p < last - const Duration(seconds: 1)) {
              wraps++;
              watch!._note('wrap from $last to $p');
            }
            last = p;
          });
          // mpv's own account of the loop, for a failure: on the Windows
          // runner, in the whole suite, the second loop did not come.
          player!.setLogLevel(LogLevel.v);
          final lines = player!.stream.log.listen(
            (e) => watch!._note('[${e.prefix}] ${e.text.trim()}'),
          );
          Future<String> props() async {
            final values = [
              for (final name in [
                'pause',
                'paused-for-cache',
                'core-idle',
                'eof-reached',
                'seeking',
                'time-pos',
                'demuxer-cache-time',
                'demuxer-cache-idle',
              ])
                '$name=${await player!.getRawProperty(name)}',
            ];
            return ' (wraps $wraps, position $last, ${values.join(' ')}), '
                'seen:\n${watch!.describe()}';
          }

          try {
            await player!.open(Media(server.url(flacName)), play: true);
            final a = (await watch!.settle(log))!;
            await waitFor(
              () => wraps >= 2,
              'the file did not loop twice',
              timeout: const Duration(seconds: 20),
              detail: props,
            );
            expect(
              server.gets('/$flacName'),
              hasLength(1),
              reason:
                  'a loop inside the cache needs no second download\n'
                  '${log()}',
            );
            _expectSame(a, flacRef, log());
            // Looping did not restart or spoil the settled analysis.
            expect(await _nativeState(player!), 'ready', reason: await props());
            expect(_complete(watch!.wave), isTrue);
            _expectSame(
              _Analysis(watch!.wave!, watch!.loudness!),
              flacRef,
              log(),
            );
          } finally {
            await pos.cancel();
            await lines.cancel();
          }
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test('a download cut short and resumed by mpv stays one pass', () async {
        final cut = flac.length ~/ 3;
        server.dropAfterBytes = cut;
        await player!.open(Media(server.url(flacName)), play: true);
        final a = (await watch!.settle(log))!;

        final gets = server.gets('/$flacName');
        expect(
          gets,
          isNotEmpty,
          reason:
              'the analysis settled with no GET of the file, seen:\n'
              '${watch!.describe()}\n${log()}',
        );
        expect(gets.first.dropped, isTrue, reason: log());
        // FFmpeg reconnects with a range from where the body stopped, so
        // the packets stay contiguous and the pass is still clean.
        expect(
          gets.where((r) => r.start == cut),
          isNotEmpty,
          reason: 'mpv did not resume the cut download\n${log()}',
        );
        expect(
          _fromStart(server, '/$flacName'),
          hasLength(1),
          reason:
              'a resumed download is contiguous and needs no second '
              'open\n${log()}',
        );
        _expectSame(a, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('a size the server does not send is still one pass', () async {
        // 200 with no Content-Length, the body ending with the
        // connection. The feed takes a file of unknown size; the end of
        // the decode at the duration tells it the pass is complete.
        server.mode = ServeMode.rangesUnknownSize;
        await player!.open(Media(server.url(flacName)), play: true);
        final a = await watch!.settle(log);
        expect(a, isNotNull, reason: 'the analysis failed\n${log()}');
        expect(
          _fromStart(server, '/$flacName'),
          hasLength(1),
          reason: 'a clean pass must not open the URL a second time\n${log()}',
        );
        _expectSame(a!, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    libmpvReleaseGroup(19, 'the partials of a clean pass', () {
      test('read as decoding until the final envelope (#28)', () async {
        // Throttled, so the pass follows the download over a few seconds
        // and the stream emits several partials before the final one.
        server.bytesPerSecond = 1024 * 1024;
        await player!.open(Media(server.url(wavName)), play: true);
        final a = (await watch!.settle(log))!;
        expect(
          _fromStart(server, '/$wavName'),
          hasLength(1),
          reason: 'a clean pass must not open the URL a second time\n${log()}',
        );
        _expectSame(a, wavRef, log());

        final waves = watch!.waves.whereType<WaveformData>().toList();
        final last = waves.lastIndexWhere((w) => !w.decoding);
        expect(last, waves.length - 1, reason: 'the final envelope is last');
        final partials = waves.sublist(0, last);
        expect(
          partials.where((w) => !w.decoding),
          isEmpty,
          reason: 'every envelope before the final one reads as decoding',
        );
        for (final w in partials) {
          expect(w.coverageBins, isNotNull, reason: 'coverage of a partial');
          expect(w.totalBins, isNotNull, reason: 'axis of a partial');
        }
        final growing = partials.where(
          (w) => w.coverageBins! > 0 && w.coverageBins! < w.totalBins!,
        );
        expect(
          growing.length,
          greaterThanOrEqualTo(2),
          reason: 'partials while the file downloads (${partials.length})',
        );
        var before = 0;
        for (final w in partials) {
          final filled = w.filled.where((b) => b != 0).length;
          expect(w.coverageBins, filled, reason: 'coverage is the bins filled');
          expect(w.coverageBins, greaterThanOrEqualTo(before));
          expect(w.decodeFraction, w.coverageBins! / w.totalBins!);
          before = w.coverageBins!;
        }
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('no clean pass, the URL is opened again', () {
      test('a seek past the cache during the download', () async {
        // 3.8 MB at 600 kB/s: about 6 s of download, so a seek to 15 s
        // lands past what is cached.
        server.bytesPerSecond = 600 * 1024;
        await _openAndLoad(
          player!,
          () => player!.open(Media(server.url(wavName)), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        final before = server.gets('/$wavName').length;
        await player!.seek(const Duration(seconds: 15));
        await waitFor(
          () => server.gets('/$wavName').length > before,
          'mpv did not request the seek target',
        );
        // The re-open does not have to crawl at the same pace.
        server.bytesPerSecond = null;
        final a = (await watch!.settle(log))!;

        expect(
          server.gets('/$wavName').any((r) => r.start > wav.length ~/ 2),
          isTrue,
          reason: 'mpv did not jump past the cache\n${log()}',
        );
        expect(
          _fromStart(server, '/$wavName').length,
          greaterThanOrEqualTo(2),
          reason:
              'the cache has a hole, so the analysis must open the URL '
              'again from its start\n${log()}',
        );
        _expectSame(a, wavRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('playback starting further in', () async {
        await player!.setRawProperty('start', '10');
        await _openAndLoad(
          player!,
          () => player!.open(Media(server.url(wavName)), play: true),
        );
        // Playback begins at 10 s, so the demuxer never reads the first
        // half. How mpv gets there is FFmpeg's choice: a new range request,
        // or, when the socket's receive window is larger than the jump
        // (seen on macOS), reading on through the first connection. The
        // requests cannot tell, the playhead can.
        final startPos = double.tryParse(
          await player!.getRawProperty('time-pos') ?? '',
        );
        expect(
          startPos,
          allOf(isNotNull, greaterThanOrEqualTo(9.9)),
          reason: 'playback did not start at the start position\n${log()}',
        );
        final a = (await watch!.settle(log))!;

        expect(
          _fromStart(server, '/$wavName').length,
          greaterThanOrEqualTo(2),
          reason:
              'the cache lacks the start of the file, so the analysis '
              'must open the URL again\n${log()}',
        );
        _expectSame(a, wavRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('a demuxer cache smaller than the file', () async {
        await player!.setDemuxer(
          player!.state.demuxer.copyWith(maxBytes: 1024 * 1024),
        );
        await player!.open(Media(server.url(wavName)), play: true);
        final a = (await watch!.settle(log))!;

        expect(
          _fromStart(server, '/$wavName').length,
          greaterThanOrEqualTo(2),
          reason:
              'a file larger than the forward cache cannot be fed, so '
              'the analysis must open the URL again\n${log()}',
        );
        _expectSame(a, wavRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('an audio track switch during the download', () async {
        // 87 kB at 16 kB/s: the switch lands mid-download.
        server.bytesPerSecond = 16 * 1024;
        await player!.open(Media(server.url(mkaName)), play: true);
        await waitFor(
          () =>
              player!.state.tracks.where((t) => t.type == 'audio').length >= 2,
          'the fixture did not expose two audio tracks',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(
          server.gets('/$mkaName').first.completed,
          isFalse,
          reason: 'the download ended before the switch\n${log()}',
        );
        await player!.setAudioTrack(const Track.id(2));
        server.bytesPerSecond = null;
        final a = (await watch!.settle(log))!;

        // The analysis follows the file, not the selected track: the
        // same result as the local file on its default track.
        _expectSame(a, mkaRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('a download cut short that mpv cannot resume', () async {
        // The cut and mpv's attempts to resume it fail, so the demuxer
        // ends short of the duration; the URL then works again.
        final cut = flac.length ~/ 3;
        server
          ..dropAfterBytes = cut
          ..refuseResume = true;
        await player!.open(Media(server.url(flacName)), play: true);
        final a = (await watch!.settle(log))!;

        final gets = server.gets('/$flacName');
        expect(
          gets,
          isNotEmpty,
          reason:
              'the analysis settled with no GET of the file, seen:\n'
              '${watch!.describe()}\n${log()}',
        );
        expect(gets.first.dropped, isTrue, reason: log());
        expect(
          gets.any((r) => r.status == 503),
          isTrue,
          reason: 'mpv did not try to resume the cut download\n${log()}',
        );
        expect(
          _fromStart(server, '/$flacName').length,
          greaterThanOrEqualTo(2),
          reason:
              'the pass ended short of the duration, so the analysis '
              'must open the URL again\n${log()}',
        );
        _expectSame(a, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('sources the feed does not take', () {
      test('a chunked body of unknown size is never opened twice', () async {
        // No length and no ranges: mpv cannot seek it, so the analysis
        // follows playback and must not open the URL itself.
        server.mode = ServeMode.chunked;
        await player!.setAudioNullUntimed(true);
        final eof = player!.stream.eofReached
            .firstWhere((v) => v)
            .timeout(const Duration(seconds: 30));
        await player!.open(Media(server.url(flacName)), play: true);
        await eof;
        // Give the analysis a moment to react to the end.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(
          server.gets('/$flacName'),
          hasLength(1),
          reason:
              'a non-seekable stream must never be opened a second '
              'time\n${log()}',
        );
        expect(
          watch!.waves.whereType<WaveformData>().where((w) => w.decoding),
          isEmpty,
          reason: 'no bulk decode for a non-seekable stream',
        );
      }, timeout: const Timeout(Duration(seconds: 60)));
    });

    group('teardown during the feed', () {
      test(
        'stop or next while the analysis replays a long cached file',
        () async {
          // The analysis is armed only after mpv cached the whole file, so it
          // starts by copying a long cache, a batch at a time on its own
          // thread. Stopping or advancing then tears the demuxer down under
          // it: the replay must let go without touching the freed cache and
          // without opening the file again. The delays land the teardown
          // before, during or after the replay, which in a release build
          // lasts a few milliseconds; the use of the freed cache it guards
          // against shows under AddressSanitizer.
          await watch!.cancel();
          watch = null;
          for (final action in ['stop', 'next']) {
            for (final delayMs in [0, 2, 5, 15, 40]) {
              final gets = server.gets('/$longName').length;
              final opens = _fromStart(server, '/$longName').length;
              await _openAndLoad(
                player!,
                () => player!.openAll([
                  Media(server.url(longName)),
                  Media(server.url(flacName)),
                ], play: true),
              );
              await waitFor(
                () => server
                    .gets('/$longName')
                    .skip(gets)
                    .any((r) => r.completed),
                'the long file was not cached whole',
              );
              final w = _Watch(player!);
              await Future<void>.delayed(Duration(milliseconds: delayMs));
              if (action == 'stop') {
                await player!.stop();
              } else {
                expect(await player!.next(), isTrue);
              }
              await Future<void>.delayed(const Duration(milliseconds: 600));
              await w.cancel();
              expect(
                _fromStart(server, '/$longName'),
                hasLength(opens + 1),
                reason:
                    '$action ${delayMs}ms into the replay opened the left '
                    'file again\n${log()}',
              );
            }
          }
          // The core is still sound: a new file analyses from its cache.
          // The last `next` left this FLAC loaded and analysed: a listener
          // back on it gets that result without a new pass, so the
          // player stops first and the open below is a new file.
          await player!.stop();
          watch = _Watch(player!);
          await player!.open(Media(server.url(flacName)), play: true);
          final a = (await watch!.settle(log))!;
          _expectSame(a, flacRef, log());
        },
        timeout: const Timeout(Duration(seconds: 120)),
      );

      test('dispose while the feed follows the download', () async {
        server.bytesPerSecond = 300 * 1024;
        final p = player!;
        final done = Completer<void>();
        p.stream.waveform.listen((_) {}, onDone: done.complete);
        final loudDone = Completer<void>();
        p.stream.loudnessScan.listen((_) {}, onDone: loudDone.complete);
        await _openAndLoad(
          p,
          () => p.open(Media(server.url(wavName)), play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(server.gets('/$wavName').last.completed, isFalse);

        await watch!.cancel();
        watch = null;
        player = null;
        await p.dispose().timeout(const Duration(seconds: 10));
        await done.future.timeout(const Duration(seconds: 5));
        await loudDone.future.timeout(const Duration(seconds: 5));
        // The download stops with the player.
        await waitFor(
          () => server.gets('/$wavName').every((r) => r.aborted || r.completed),
          'a request of the disposed player is still being served',
        );

        // A new player analyses a new file: no state was left stuck.
        player = await buildPlayer();
        watch = _Watch(player!);
        server.bytesPerSecond = null;
        await player!.open(Media(server.url(flacName)), play: true);
        final a = (await watch!.settle(log))!;
        expect(server.gets('/$flacName'), hasLength(1), reason: log());
        _expectSame(a, flacRef, log());
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('a playlist advance while the feed follows the download', () async {
        server.bytesPerSecond = 300 * 1024;
        await _openAndLoad(
          player!,
          () => player!.openAll([
            Media(server.url(wavName)),
            Media(server.url(flacName)),
          ], play: true),
        );
        await Future<void>.delayed(const Duration(milliseconds: 600));
        expect(server.gets('/$wavName').last.completed, isFalse);
        final before = watch!.waves.length;
        server.bytesPerSecond = null;
        expect(await player!.next(), isTrue);
        // The boundary clears the first track's envelope, then the second
        // track settles on its own result.
        await waitFor(
          () => watch!.waves.skip(before).contains(null),
          'no reset at the track boundary',
        );
        final a = (await watch!.settle(log))!;
        expect(
          server.gets('/$flacName'),
          hasLength(1),
          reason:
              'the second track plays from its start: one download\n'
              '${log()}',
        );
        _expectSame(a, flacRef, log());
        // The abandoned track's analysis did not open it again.
        expect(_fromStart(server, '/$wavName'), hasLength(1), reason: log());
      }, timeout: const Timeout(Duration(seconds: 60)));
    });
  });
}
