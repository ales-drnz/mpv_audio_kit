// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/pcm_native.dart';
import 'package:mpv_audio_kit/src/pcm/pcm_source.dart' show pcmLoadOptions;

import 'fake_pcm_native.dart';

// 1 kHz mono s16le: 2 bytes a frame, 2000 bytes a second. The native
// buffer holds at least one second (2000 bytes).
const _mono = PcmFormat(sampleRate: 1000, channels: 1);
// 4 bytes a frame, 8000 a second.
const _stereo = PcmFormat(
  sampleRate: 1000,
  channels: 2,
  encoding: PcmEncoding.f32le,
);

int _id(PcmSource s) =>
    int.parse(s.toMedia().uri.substring('mak-pcm://'.length));

Uint8List _ramp(int start, int n) =>
    Uint8List.fromList([for (var i = 0; i < n; i++) (start + i) & 0xff]);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

/// Allocates garbage until [done] or a few rounds have passed, to give
/// the GC a chance to collect what nothing holds.
Future<void> _churn(bool Function() done) async {
  for (var i = 0; i < 30 && !done(); i++) {
    final junk = [for (var j = 0; j < 64; j++) Uint8List(1 << 20)];
    junk.clear();
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  late FakePcmNative native;

  setUp(() {
    PcmSource.debugReset();
    native = FakePcmNative();
    debugPcmNativeOverride = native;
  });

  tearDown(() {
    debugPcmNativeOverride = null;
    PcmSource.debugReset();
  });

  group('PcmFormat', () {
    test('bytes per frame and durations', () {
      expect(_mono.bytesPerFrame, 2);
      expect(_stereo.bytesPerFrame, 8 ~/ 2 * 2);
      expect(
        const PcmFormat(
          sampleRate: 48000,
          channels: 2,
          encoding: PcmEncoding.s24le,
        ).bytesPerFrame,
        6,
      );
      expect(_mono.durationOf(2000), const Duration(seconds: 1));
      expect(_mono.durationOf(3), const Duration(milliseconds: 1));
    });

    test('equality', () {
      expect(_mono, const PcmFormat(sampleRate: 1000, channels: 1));
      expect(_mono == _stereo, isFalse);
    });

    test('create rejects a buffer past the native 1 GiB', () {
      const wide = PcmFormat(
        sampleRate: 384000,
        channels: 8,
        encoding: PcmEncoding.f32le,
      );
      // 12.3 MB a second: 87 s fit in 1 GiB.
      PcmSource.create(wide, maxBuffered: const Duration(seconds: 80)).abort();
      expect(
        () => PcmSource.create(wide, maxBuffered: const Duration(seconds: 90)),
        throwsA(
          isA<ArgumentError>().having((e) => e.name, 'name', 'maxBuffered'),
        ),
      );
      expect(native.sources.values.single.capacity, lessThanOrEqualTo(1 << 30));
    });

    test('create needs MpvAudioKit.ensureInitialized', () {
      debugPcmNativeOverride = null;
      expect(() => PcmSource.create(_mono), throwsStateError);
    });

    test('create rejects a buffer of no time', () {
      expect(
        () => PcmSource.create(_mono, maxBuffered: Duration.zero),
        throwsArgumentError,
      );
      expect(native.sources, isEmpty);
    });
  });

  group('add', () {
    test('writes whole frames and keeps a split frame for the next chunk', () {
      final s = PcmSource.create(_stereo);
      final id = _id(s);
      final data = _ramp(0, 64);
      var at = 0;
      for (final n in [3, 5, 1, 7, 13, 2, 33]) {
        s.add(Uint8List.sublistView(data, at, at + n));
        at += n;
      }
      expect(at, 64);
      // Every write is whole frames.
      expect(native[id].writes.every((w) => w % 8 == 0), isTrue);
      expect(native[id].fifo.toBytes(), data);
      s.abort();
    });

    test('a chunk smaller than the missing part of a frame waits', () {
      final s = PcmSource.create(_stereo);
      final id = _id(s);
      s.add(_ramp(0, 3));
      s.add(_ramp(3, 2));
      expect(native[id].fifo.length, 0);
      expect(s.buffered, Duration.zero);
      s.add(_ramp(5, 3));
      expect(native[id].fifo.toBytes(), _ramp(0, 8));
      s.abort();
    });

    test(
      'past the native capacity chunks queue in Dart and flush as the reader reads',
      () {
        final s = PcmSource.create(
          _mono,
          maxBuffered: const Duration(seconds: 5),
        );
        final id = _id(s);
        // Native capacity: 5 s = 10000 bytes.
        expect(native[id].capacity, 10000);
        s.add(_ramp(0, 12000));
        expect(native[id].fifo.length, 10000);
        expect(s.buffered, const Duration(seconds: 6));
        native.open(id);
        native.readBytes(id, 3000);
        PcmSource.debugPoll();
        expect(native[id].fifo.length, 9000);
        expect(s.buffered, const Duration(milliseconds: 4500));
        s.abort();
      },
    );

    test('a caller reusing its buffer does not change the queued audio', () {
      final s = PcmSource.create(
        _mono,
        maxBuffered: const Duration(seconds: 1),
      );
      final id = _id(s);
      final buf = Uint8List(3000)..fillRange(0, 3000, 7);
      s.add(buf);
      buf.fillRange(0, 3000, 9);
      native.open(id);
      native.readBytes(id, 2000);
      PcmSource.debugPoll();
      native.readBytes(id, 1000);
      expect(native[id].read.every((b) => b == 7), isTrue);
      s.abort();
    });

    test('add after close throws, after the end it is dropped', () {
      final s = PcmSource.create(_mono);
      unawaited(s.close());
      expect(() => s.add(_ramp(0, 2)), throwsStateError);
      s.abort();
      s.add(_ramp(0, 2));
      expect(s.state, PcmSourceState.aborted);
    });
  });

  group('state', () {
    test('waiting, reading, finishing, drained', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      expect(s.state, PcmSourceState.waiting);
      s.add(_ramp(0, 100));
      native.open(id);
      PcmSource.debugPoll();
      expect(s.state, PcmSourceState.reading);
      final closed = s.close();
      expect(s.state, PcmSourceState.finishing);
      await closed;
      expect(native[id].state, PcmNative.stateFinished);
      expect(s.isDone, isFalse);
      native.readBytes(id, 100);
      PcmSource.debugPoll();
      expect(s.state, PcmSourceState.drained);
      expect(s.isDone, isTrue);
      await s.done;
      expect(native[id].released, isTrue);
    });

    test(
      'close finishes only once the Dart queue reached the native buffer',
      () async {
        final s = PcmSource.create(
          _mono,
          maxBuffered: const Duration(seconds: 1),
        );
        final id = _id(s);
        s.add(_ramp(0, 3000));
        var closed = false;
        unawaited(s.close().then((_) => closed = true));
        await _flush();
        expect(closed, isFalse);
        expect(native[id].state, PcmNative.stateOpen);
        native.open(id);
        native.readBytes(id, 1500);
        PcmSource.debugPoll();
        await _flush();
        expect(closed, isTrue);
        expect(native[id].state, PcmNative.stateFinished);
        native.readBytes(id, 1500);
        PcmSource.debugPoll();
        expect(s.state, PcmSourceState.drained);
        expect(native[id].read, _ramp(0, 3000));
      },
    );

    test('close drops a partial frame', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      s.add(_ramp(0, 5));
      await s.close();
      expect(native[id].fifo.length, 4);
      s.abort();
    });

    test('abort drops everything, ends at once and releases', () async {
      final s = PcmSource.create(
        _mono,
        maxBuffered: const Duration(seconds: 1),
      );
      final id = _id(s);
      s.add(_ramp(0, 5000));
      s.abort();
      expect(s.state, PcmSourceState.aborted);
      expect(native[id].state, PcmNative.stateAborted);
      expect(native[id].released, isTrue);
      expect(s.buffered, Duration.zero);
      await s.done.timeout(const Duration(seconds: 1));
      s.abort();
      await s.close();
    });

    test('a reader that closes before the end stops the source', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      s.add(_ramp(0, 100));
      native.open(id);
      native.closeReader(id);
      PcmSource.debugPoll();
      expect(s.state, PcmSourceState.stopped);
      await s.done;
      s.add(_ramp(0, 100));
      expect(native[id].released, isTrue);
    });

    test('a write the reader refuses stops feeding', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      native.open(id);
      native.closeReader(id);
      s.add(_ramp(0, 100));
      expect(s.isDone, isTrue);
      expect(s.state, PcmSourceState.stopped);
      await s.done;
    });

    test(
      'abort lets a player leave the entry before the native abort',
      () async {
        final s = PcmSource.create(_mono);
        final id = _id(s);
        native.open(id);
        final left = Completer<void>();
        var cuts = 0;
        Future<void>? cut(PcmSource source) {
          cuts++;
          return left.future;
        }

        s
          ..addCutter(cut)
          ..addCutter(cut);
        s.abort();
        expect(cuts, 1);
        expect(s.state, PcmSourceState.aborted);
        expect(s.isDone, isTrue);
        // Still readable until the player has left the entry.
        expect(native[id].state, PcmNative.stateReading);
        expect(native[id].released, isFalse);
        left.complete();
        await _flush();
        await _flush();
        expect(native[id].state, PcmNative.stateAborted);
        expect(native[id].released, isTrue);
      },
    );

    test('a cutter with nothing to do aborts at once', () {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      s
        ..addCutter((_) => null)
        ..abort();
      expect(native[id].state, PcmNative.stateAborted);
      expect(native[id].released, isTrue);
    });

    test('endUnread ends an unread source as stopped', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      s.add(_ramp(0, 100));
      final fed = s.addStream(const Stream<Uint8List>.empty());
      s.endUnread();
      expect(s.state, PcmSourceState.stopped);
      expect(native[id].state, PcmNative.stateAborted);
      expect(native[id].freed, isTrue);
      await s.done;
      await fed;
      expect(() => pcmLoadOptions(s.toMedia().uri), throwsArgumentError);
    });

    test('endUnread keeps drained for a source read to its end', () async {
      final s = PcmSource.create(_mono);
      final id = _id(s);
      native.open(id);
      s.add(_ramp(0, 100));
      await s.close();
      native.readBytes(id, 100);
      s.endUnread();
      expect(s.state, PcmSourceState.drained);
    });

    test('a source released behind its back reads as aborted', () async {
      final s = PcmSource.create(_mono);
      native.releaseAll();
      PcmSource.debugPoll();
      expect(s.state, PcmSourceState.aborted);
      await s.done;
    });

    test('the poll timer runs while a source is not done', () async {
      final s = PcmSource.create(_mono);
      expect(PcmSource.debugPolling, isTrue);
      s.abort();
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(PcmSource.debugPolling, isFalse);
    });
  });

  group('backpressure', () {
    test('ready waits past maxBuffered until half of it is left', () async {
      final s = PcmSource.create(
        _mono,
        maxBuffered: const Duration(seconds: 2),
      );
      final id = _id(s);
      await s.ready;
      s.add(_ramp(0, 5000)); // 2.5 s
      var ready = false;
      unawaited(s.ready.then((_) => ready = true));
      native.open(id);
      native.readBytes(id, 1500); // 1.75 s left
      PcmSource.debugPoll();
      await _flush();
      expect(ready, isFalse);
      native.readBytes(id, 1600); // 0.95 s left
      PcmSource.debugPoll();
      await _flush();
      expect(ready, isTrue);
      s.abort();
    });

    test('ready completes when the source ends', () async {
      final s = PcmSource.create(
        _mono,
        maxBuffered: const Duration(seconds: 1),
      );
      s.add(_ramp(0, 4000));
      final ready = s.ready;
      s.abort();
      await ready.timeout(const Duration(seconds: 1));
    });

    test('addStream pauses its stream past maxBuffered and resumes', () async {
      final s = PcmSource.create(
        _mono,
        maxBuffered: const Duration(seconds: 1),
      );
      final id = _id(s);
      var sent = 0;
      var paused = 0;
      late StreamController<Uint8List> c;
      c = StreamController<Uint8List>(
        onPause: () => paused++,
        onListen: () {
          void push() {
            if (c.isPaused || c.isClosed) return;
            if (sent >= 20) {
              unawaited(c.close());
              return;
            }
            c.add(_ramp(sent * 500, 500));
            sent++;
            scheduleMicrotask(push);
          }

          c.onResume = push;
          push();
        },
      );
      final fed = s.addStream(c.stream);
      await _flush();
      expect(paused, greaterThan(0));
      expect(sent, lessThan(20));
      native.open(id);
      for (
        var i = 0;
        i < 10000 && (sent < 20 || native[id].fifo.isNotEmpty);
        i++
      ) {
        native.readBytes(id, 400);
        PcmSource.debugPoll();
        await _flush();
      }
      await fed.timeout(const Duration(seconds: 2));
      await s.close();
      native.readBytes(id, 1 << 20);
      PcmSource.debugPoll();
      expect(native[id].read.length, 10000);
      expect(s.state, PcmSourceState.drained);
    });

    test(
      'addStream ends and cancels its stream when the source is aborted',
      () async {
        final s = PcmSource.create(_mono);
        var cancelled = false;
        final c = StreamController<Uint8List>(onCancel: () => cancelled = true);
        final fed = s.addStream(c.stream);
        c.add(_ramp(0, 10));
        await _flush();
        s.abort();
        await fed.timeout(const Duration(seconds: 1));
        expect(cancelled, isTrue);
      },
    );

    test('close during addStream ends it with a StateError', () async {
      final s = PcmSource.create(_mono);
      var cancelled = false;
      final c = StreamController<Uint8List>(onCancel: () => cancelled = true);
      final fed = s.addStream(c.stream);
      c.add(_ramp(0, 10));
      await _flush();
      final closing = s.close();
      c.add(_ramp(10, 10));
      await expectLater(
        fed.timeout(const Duration(seconds: 1)),
        throwsStateError,
      );
      expect(cancelled, isTrue);
      s.abort();
      await closing;
    });

    test('addStream forwards an error of its stream', () async {
      final s = PcmSource.create(_mono);
      final fed = s.addStream(Stream<Uint8List>.error(StateError('socket')));
      await expectLater(fed, throwsStateError);
      s.abort();
    });
  });

  group('media', () {
    test('a media keeps its source alive until a player holds it', () async {
      // The app may keep only the media: `player.add(make().toMedia())`.
      (Media, WeakReference<PcmSource>) make() {
        final s = PcmSource.create(_mono);
        s.add(_ramp(0, 10));
        return (s.toMedia(), WeakReference(s));
      }

      final (media, weak) = make();
      PcmSource.debugPoll();
      await _churn(() => weak.target == null);
      expect(weak.target, isNotNull, reason: 'the media still names it');
      expect(pcmLoadOptions(media.uri), isNotNull);
    });

    test('toMedia carries the uri, the extras and the load options', () {
      final s = PcmSource.create(
        const PcmFormat(sampleRate: 24000, channels: 1),
      );
      final m = s.toMedia(extras: const {'title': 'Live'});
      expect(m.uri, 'mak-pcm://${_id(s)}');
      expect(m.isPcmStream, isTrue);
      expect(const Media('https://x/y.mp3').isPcmStream, isFalse);
      expect(m.extras, const {'title': 'Live'});
      expect(
        pcmLoadOptions(m.uri),
        'demuxer=rawaudio,demuxer-rawaudio-format=s16le,'
        'demuxer-rawaudio-rate=24000,demuxer-rawaudio-channels=1,'
        'cache-pause=no,demuxer-termination-timeout=0,gapless-audio=no',
      );
      final stereo = PcmSource.create(_stereo);
      expect(
        pcmLoadOptions(stereo.toMedia().uri),
        contains('demuxer-rawaudio-format=floatle'),
      );
      stereo.abort();
      expect(pcmLoadOptions('https://x/y.mp3'), isNull);
      final low = PcmSource.create(_mono, lowLatency: true);
      expect(pcmLoadOptions(low.toMedia().uri), endsWith(',audio-buffer=0.1'));
      expect(pcmLoadOptions(m.uri), isNot(contains('audio-buffer')));
      low.abort();
      s.abort();
      expect(() => pcmLoadOptions(m.uri), throwsArgumentError);
      expect(() => pcmLoadOptions('mak-pcm://zz'), throwsArgumentError);
    });
  });
}
