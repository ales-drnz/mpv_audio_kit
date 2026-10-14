// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../internals/debug_log.dart';
import '../internals/pcm_native.dart';
import '../models/media.dart';
import 'pcm_format.dart';

/// Where a [PcmSource] is in its life.
enum PcmSourceState {
  /// Created, not yet opened by a player. Chunks wait in the buffer.
  waiting,

  /// A player reads it.
  reading,

  /// [PcmSource.close] was called: the buffered audio still plays out.
  finishing,

  /// The player read everything up to the end set by [PcmSource.close].
  drained,

  /// [PcmSource.abort] was called.
  aborted,

  /// The player let it go before the end, read or not: `stop()`, a next
  /// track, another `open()`, a removal from the playlist, or a dispose.
  stopped,
}

/// A live input of raw PCM chunks, played as a [Media] while it arrives:
/// speech generated chunk by chunk, a network stream of samples, a
/// synthesizer. No file, no socket, no header.
///
/// Create one with [Player.openPcmStream], which also opens it, or with
/// [PcmSource.create] and play [toMedia] like any other media (also queued
/// in a playlist, to play several sources back to back). Feed it with
/// [add] or [addStream], then [close] it: the player plays the buffered
/// audio to its end and the entry ends normally (`completed`, `endFile`).
/// [abort] stops it at once.
///
/// ```dart
/// final socket = await WebSocket.connect('wss://example.com/speech');
/// final source = await player.openPcmStream(
///   const PcmFormat(sampleRate: 24000, channels: 1),
/// );
/// await source.addStream(socket.where((m) => m is List<int>).map(
///   (m) => m is Uint8List ? m : Uint8List.fromList(m as List<int>),
/// ));
/// await source.close();
/// ```
///
/// A player holds the source of each entry it loaded while the entry is
/// in its playlist, so a queued source needs no other reference. Prefetch
/// skips live entries: a queued source opens when its entry starts, and
/// what was added meanwhile waits in its buffer. An entry that leaves the
/// playlist (a skip, a removal, another `open()`, a dispose) ends its
/// source as [PcmSourceState.stopped], read or not.
///
/// Each source is read once: it cannot be played again, and seeking is
/// not possible (a seek on it does nothing). Its length is not known in
/// advance: `state.duration` follows the audio received so far.
/// [Media.isPcmStream] tells a live source from a file.
final class PcmSource {
  PcmSource._(this.format, this.maxBuffered, this._native, this._id)
    : _capacity = _capacityFor(format, maxBuffered);

  /// A new source of [format], ready to take chunks and to be played.
  ///
  /// [maxBuffered] is how much audio may wait for the player before
  /// [ready] holds back and [addStream] pauses its stream. [add] never
  /// refuses audio: past it, chunks wait in Dart memory.
  ///
  /// [lowLatency] halves the audio output buffer for this entry (100 ms in
  /// place of 200 ms): playback starts about 0.13 s after the first chunk
  /// in place of about 0.2 s, with less margin against a late chunk or a
  /// busy device.
  ///
  /// Throws [ArgumentError] when [maxBuffered] holds more than 1 GiB of
  /// [format]. Call `MpvAudioKit.ensureInitialized` first, as for a
  /// [Player]: throws [StateError] otherwise, and [UnsupportedError] when
  /// the loaded libmpv has no live PCM input (a custom build without the
  /// mpv_audio_kit patches).
  static PcmSource create(
    PcmFormat format, {
    Duration maxBuffered = const Duration(seconds: 30),
    bool lowLatency = false,
  }) {
    format.validate();
    if (maxBuffered <= Duration.zero) {
      throw ArgumentError.value(maxBuffered, 'maxBuffered', 'must be > 0');
    }
    if (format.durationBytes(maxBuffered) > _maxCapacity) {
      throw ArgumentError.value(
        maxBuffered,
        'maxBuffered',
        'holds more than 1 GiB of $format',
      );
    }
    final native = pcmNative();
    final source = PcmSource._(format, maxBuffered, native, 0);
    final id = native.create(source._capacity);
    if (id <= 0) {
      throw StateError('The live PCM input could not be created ($id).');
    }
    source._id = id;
    _formats[id] = format;
    if (lowLatency) _lowLatency.add(id);
    _live[id] = WeakReference(source);
    _finalizer.attach(source, _NativeRef(native, id), detach: source);
    _watch(source);
    return source;
  }

  /// The layout of the chunks this source takes.
  final PcmFormat format;

  /// The buffered audio past which [ready] waits.
  final Duration maxBuffered;

  final PcmNative _native;
  int _id;

  /// Bytes the native buffer holds at most: [maxBuffered], and at least
  /// one second so a slow Dart event loop never starves the player.
  final int _capacity;

  final ListQueue<Uint8List> _queue = ListQueue<Uint8List>();
  int _queuedBytes = 0;
  // The bytes of a frame split across two chunks.
  final Uint8List _carry = Uint8List(32);
  int _carryLength = 0;

  PcmSourceState _state = PcmSourceState.waiting;
  bool _closing = false;
  bool _finished = false;
  bool _released = false;
  Completer<void>? _closed;
  Completer<void>? _ready;
  final Completer<void> _done = Completer<void>();
  final List<Future<void>? Function(PcmSource)> _cutters = [];

  /// Where the source is in its life.
  PcmSourceState get state => _state;

  /// Completes once the source is through: [PcmSourceState.drained],
  /// [PcmSourceState.aborted] or [PcmSourceState.stopped]. The audio the
  /// player already read may still be playing: the player's `completed`
  /// and `endFile` tell when it ended.
  Future<void> get done => _done.future;

  /// Whether the source is through (see [done]).
  bool get isDone => _done.isCompleted;

  /// The audio waiting for the player: in the native buffer and, past
  /// [maxBuffered], in Dart memory. Audio the player already read into
  /// its own buffers is not counted.
  Duration get buffered => format.durationOf(_bufferedBytes);

  /// A `mak-pcm://` [Media] that plays this source, with [extras] for the
  /// playlist. The player opens it with the raw audio demuxer set to
  /// [format], whatever the load path (`open`, `openAll`, `add`,
  /// `replace`).
  Media toMedia({Map<String, Object?>? extras}) =>
      Media('$_scheme$_id', extras: extras);

  /// Completes when the source can take more audio without going past
  /// [maxBuffered]: at once while below it, otherwise once the player has
  /// read the buffer down to half of it. Also completes when the source is
  /// [done].
  ///
  /// ```dart
  /// await for (final chunk in generator()) {
  ///   await source.ready;
  ///   source.add(chunk);
  /// }
  /// ```
  Future<void> get ready {
    if (isDone || _bufferedBytes < _highBytes) return Future<void>.value();
    final ready = _ready ??= Completer<void>();
    _hold(this);
    return ready.future;
  }

  /// Queues [chunk] for playback. Never blocks and never refuses audio:
  /// what the native buffer cannot take yet waits in Dart memory, and
  /// goes to the player as it reads. The bytes are copied when they wait.
  ///
  /// [chunk] may split a frame: the extra bytes are kept and joined to
  /// the next chunk. After the source is [done] (the player stopped it,
  /// or [abort]), chunks are dropped. Throws [StateError] after [close].
  void add(Uint8List chunk) {
    if (_closing && !isDone) {
      throw StateError('PcmSource.add() after close()');
    }
    if (isDone || chunk.isEmpty) return;
    final frame = format.bytesPerFrame;
    var offset = 0;
    if (_carryLength > 0) {
      final need = frame - _carryLength;
      if (chunk.length < need) {
        _carry.setRange(_carryLength, _carryLength + chunk.length, chunk);
        _carryLength += chunk.length;
        return;
      }
      _carry.setRange(_carryLength, frame, chunk);
      _enqueue(Uint8List.fromList(Uint8List.sublistView(_carry, 0, frame)));
      _carryLength = 0;
      offset = need;
    }
    final whole = (chunk.length - offset) ~/ frame * frame;
    if (whole > 0) {
      _enqueue(
        Uint8List.sublistView(chunk, offset, offset + whole),
        view: true,
      );
    }
    final rest = chunk.length - offset - whole;
    if (rest > 0) {
      _carry.setRange(0, rest, chunk, offset + whole);
      _carryLength = rest;
    }
  }

  /// Adds every chunk of [stream], pausing it while the source is past
  /// [maxBuffered] (see [ready]). Completes when [stream] ends, or when
  /// the source is [done], which cancels the subscription. An error of
  /// [stream] cancels it and completes the future with that error.
  ///
  /// Does not [close] the source, so several streams can follow each
  /// other: call [close] after the last one.
  Future<void> addStream(Stream<Uint8List> stream) {
    if (_closing && !isDone) {
      throw StateError('PcmSource.addStream() after close()');
    }
    final completer = Completer<void>();
    if (isDone) {
      completer.complete();
      return completer.future;
    }
    late final StreamSubscription<Uint8List> sub;
    void finish() {
      if (completer.isCompleted) return;
      unawaited(sub.cancel());
      completer.complete();
    }

    sub = stream.listen(
      (chunk) {
        if (isDone) return finish();
        add(chunk);
        if (_bufferedBytes >= _highBytes && !sub.isPaused) {
          sub.pause();
          unawaited(
            ready.then((_) {
              if (isDone) return finish();
              if (sub.isPaused) sub.resume();
            }),
          );
        }
      },
      onError: (Object e, StackTrace st) {
        if (completer.isCompleted) return;
        unawaited(sub.cancel());
        completer.completeError(e, st);
      },
      onDone: () {
        if (!completer.isCompleted) completer.complete();
      },
      cancelOnError: true,
    );
    unawaited(_done.future.then((_) => finish()));
    return completer.future;
  }

  /// Ends the input: the player plays what is buffered, then the entry
  /// ends normally, once its last sample has played (`completed` rises,
  /// or the next entry starts). Completes once every chunk has reached
  /// the native buffer; [done] completes once the player has read it all.
  ///
  /// A partial frame left over from [add] is dropped. Calling it again,
  /// or after [done], does nothing.
  Future<void> close() {
    if (isDone) return Future<void>.value();
    final closed = _closed;
    if (closed != null) return closed.future;
    _closing = true;
    _state = PcmSourceState.finishing;
    if (_carryLength > 0) {
      debugLog(
        'mpv_audio_kit: PcmSource.close() drops $_carryLength bytes of a '
        'partial frame.',
      );
      _carryLength = 0;
    }
    final completer = _closed = Completer<void>();
    _pump();
    if (!completer.isCompleted) _hold(this);
    return completer.future;
  }

  /// Stops feeding and cuts the playback of this source at once: the
  /// queued chunks are dropped, and a player playing it moves to its next
  /// entry, or stops when there is none (as `next(force: true)`, so with
  /// `loop-playlist` on it wraps to the first entry). The audio output
  /// does not play out what it holds.
  ///
  /// A source aborted before a player opened it fails to load there, so
  /// abort a queued source only to drop it. Does nothing once the source
  /// is [done].
  void abort() {
    if (isDone) return;
    final cuts = [for (final cut in _cutters) ?cut(this)];
    if (cuts.isEmpty) {
      if (!_released) _native.abort(_id);
      _end(PcmSourceState.aborted);
      return;
    }
    // The player leaves the entry first: aborting the native side now
    // would end it as a normal end of file, which plays out the audio
    // output, and could let the player reach the next entry before the
    // cut and skip that one instead.
    _end(PcmSourceState.aborted, release: false);
    unawaited(
      Future.wait(cuts)
          .timeout(const Duration(seconds: 1))
          .then<void>((_) {}, onError: (Object _) {})
          .whenComplete(() {
            if (_released) return;
            _native.abort(_id);
            _release();
          }),
    );
  }

  /// Ends the source as [PcmSourceState.stopped] (or drained, when the
  /// reader got to the end): the player dropped its entry, or never loaded
  /// it, so no reader will come or stay. Aborts the native side, which
  /// ends a reader still closing at once.
  @internal
  void endUnread() {
    if (isDone) return;
    if (_released) return _end(PcmSourceState.stopped);
    _native.abort(_id);
    final code = _native.state(_id);
    _end(
      code == PcmNative.stateDrained
          ? PcmSourceState.drained
          : PcmSourceState.stopped,
    );
  }

  /// Registers [cut], called by [abort] while the source is not done: a
  /// player that loaded it leaves the entry when it is current, and
  /// returns when that is done, or `null` when it has nothing to do.
  @internal
  void addCutter(Future<void>? Function(PcmSource source) cut) {
    if (!isDone && !_cutters.contains(cut)) _cutters.add(cut);
  }

  @override
  String toString() => 'PcmSource($_scheme$_id, $format, ${_state.name})';

  // ── internals ────────────────────────────────────────────────────────

  int get _highBytes =>
      math.max(format.bytesPerFrame, format.durationBytes(maxBuffered));

  int get _lowBytes => _highBytes ~/ 2;

  int get _bufferedBytes {
    final native = _released ? 0 : math.max(0, _native.buffered(_id));
    return native + _queuedBytes + _carryLength;
  }

  void _enqueue(Uint8List bytes, {bool view = false}) {
    if (_queue.isEmpty) {
      final taken = _write(bytes);
      if (taken < 0 || taken == bytes.length) return;
      bytes = Uint8List.sublistView(bytes, taken);
    }
    // A view of the caller's chunk is copied, since it may reuse it.
    _queue.add(view ? Uint8List.fromList(bytes) : bytes);
    _queuedBytes += bytes.length;
    _hold(this);
  }

  /// Writes the whole frames of [bytes] the native buffer has room for.
  /// Returns the bytes taken, or -1 when the source ended.
  int _write(Uint8List bytes) {
    if (_released) return -1;
    final frame = format.bytesPerFrame;
    final fill = _native.buffered(_id);
    if (fill < 0) {
      _sync();
      return -1;
    }
    final room = (_capacity - fill) ~/ frame * frame;
    final n = math.min(room, bytes.length);
    if (n <= 0) return 0;
    final rc = _native.write(
      _id,
      n == bytes.length ? bytes : Uint8List.sublistView(bytes, 0, n),
    );
    // Out of memory: the chunk stays queued for the next poll.
    if (rc == PcmNative.errNoMemory) return 0;
    if (rc < 0) {
      // The reader closed, or the source was aborted: stop feeding.
      _sync();
      if (!isDone) _end(PcmSourceState.aborted);
      return -1;
    }
    return rc;
  }

  /// Moves queued chunks into the native buffer as it has room, then
  /// finishes the input once a [close] has nothing left to move.
  void _pump() {
    while (_queue.isNotEmpty && !isDone) {
      final head = _queue.first;
      final taken = _write(head);
      if (taken <= 0) break;
      _queuedBytes -= taken;
      if (taken == head.length) {
        _queue.removeFirst();
      } else {
        _queue
          ..removeFirst()
          ..addFirst(Uint8List.sublistView(head, taken));
        break;
      }
    }
    if (_closing && !_finished && _queue.isEmpty && !isDone) {
      _finished = true;
      _native.finish(_id);
      _closed?.complete();
    }
  }

  /// One poll: moves the queue, follows the native state, wakes [ready].
  void _tick() {
    if (isDone) return;
    _pump();
    _sync();
    if (isDone) return;
    final ready = _ready;
    if (ready != null && _bufferedBytes <= _lowBytes) {
      _ready = null;
      ready.complete();
    }
  }

  /// Follows the native state.
  void _sync() {
    if (isDone || _released) return;
    final code = _native.state(_id);
    switch (code) {
      case PcmNative.stateOpen:
        if (!_closing) _state = PcmSourceState.waiting;
      case PcmNative.stateReading:
        if (!_closing) _state = PcmSourceState.reading;
      case PcmNative.stateFinished:
        _state = PcmSourceState.finishing;
      case PcmNative.stateDrained:
        _end(PcmSourceState.drained);
      case PcmNative.stateReaderClosed:
        _end(PcmSourceState.stopped);
      default:
        // Aborted, or unknown: released behind our back (a libmpv-wide
        // release_all).
        _end(PcmSourceState.aborted);
    }
  }

  /// Settles every waiter and lets the native side go.
  void _end(PcmSourceState state, {bool release = true}) {
    _state = state;
    _queue.clear();
    _queuedBytes = 0;
    _carryLength = 0;
    _cutters.clear();
    if (release) _release();
    final closed = _closed;
    if (closed != null && !closed.isCompleted) closed.complete();
    final ready = _ready;
    _ready = null;
    ready?.complete();
    if (!_done.isCompleted) _done.complete();
    _held.remove(this);
  }

  void _release() {
    if (_released) return;
    _released = true;
    _finalizer.detach(this);
    _native.release(_id);
    _forget(_id);
  }

  // ── polling ──────────────────────────────────────────────────────────
  //
  // One timer serves every source while any is not done: the reader runs
  // on an mpv thread and the C API never calls back into Dart, so the
  // queue, the state and [ready] follow by polling. A tick costs a few
  // leaf calls per source. Sources are watched through weak references,
  // so one the app dropped is still collected (its finalizer releases
  // it); a source with queued chunks, a pending close or a ready waiter
  // is held strongly until that work is done.

  static const Duration _interval = Duration(milliseconds: 20);
  static final List<WeakReference<PcmSource>> _watched = [];
  static final Set<PcmSource> _held = {};
  static Timer? _timer;

  static void _watch(PcmSource source) {
    _watched.add(WeakReference(source));
    _timer ??= Timer.periodic(_interval, (_) => _pollAll());
  }

  static void _hold(PcmSource source) {
    if (!source.isDone) _held.add(source);
  }

  static void _pollAll() {
    for (var i = _watched.length - 1; i >= 0; i--) {
      final source = _watched[i].target;
      if (source != null) source._tick();
      if (source == null || source.isDone) {
        _watched.removeAt(i);
      } else if (source._queue.isEmpty &&
          source._ready == null &&
          !(source._closing && !source._finished)) {
        _held.remove(source);
      }
    }
    if (_watched.isEmpty) {
      _timer?.cancel();
      _timer = null;
    }
  }

  // A source the app dropped: the native side lets go, and its media is
  // refused from then on.
  static final Finalizer<_NativeRef> _finalizer = Finalizer<_NativeRef>((ref) {
    ref.native.release(ref.id);
    _forget(ref.id);
  });

  static void _forget(int id) {
    _formats.remove(id);
    _lowLatency.remove(id);
    _live.remove(id);
  }

  // The native side refuses a larger buffer.
  static const int _maxCapacity = 1 << 30;

  static const String _scheme = 'mak-pcm://';

  // The format of every source not yet released, for the load options of
  // its media.
  static final Map<int, PcmFormat> _formats = {};
  static final Set<int> _lowLatency = {};

  // Every source not yet released, for the player that loads its media.
  static final Map<int, WeakReference<PcmSource>> _live = {};

  /// Test-only: runs one poll of every source now.
  @visibleForTesting
  static void debugPoll() => _pollAll();

  /// Test-only: whether the poll timer runs.
  @visibleForTesting
  static bool get debugPolling => _timer != null;

  /// Test-only: forgets every source and stops the poll timer.
  @visibleForTesting
  static void debugReset() {
    _timer?.cancel();
    _timer = null;
    _watched.clear();
    _held.clear();
    _formats.clear();
    _lowLatency.clear();
    _live.clear();
  }

  static int _capacityFor(PcmFormat format, Duration maxBuffered) {
    final floor = format.bytesPerSecond;
    final bytes = math.min(
      _maxCapacity,
      math.max(floor, format.durationBytes(maxBuffered)),
    );
    return bytes ~/ format.bytesPerFrame * format.bytesPerFrame;
  }
}

final class _NativeRef {
  _NativeRef(this.native, this.id);
  final PcmNative native;
  final int id;
}

/// The live source [uri] names, while it is not released.
@internal
PcmSource? pcmSourceFor(String uri) {
  if (!isPcmUri(uri)) return null;
  final id = int.tryParse(uri.substring(PcmSource._scheme.length));
  return id == null ? null : PcmSource._live[id]?.target;
}

/// Whether [uri] names a live PCM source.
@internal
bool isPcmUri(String uri) => uri.startsWith(PcmSource._scheme);

/// The file-local `loadfile` options that play the `mak-pcm://` [uri]:
/// mpv's raw audio demuxer set to the source's format, and no gapless
/// audio, so the entry ends once its last sample has played rather than
/// once the audio output holds it (a buffer earlier, with nothing after
/// it to join). `null` when [uri] is not one. Throws [ArgumentError] for
/// a source that is released or was never created in this isolate.
@internal
String? pcmLoadOptions(String uri) {
  if (!isPcmUri(uri)) return null;
  final id = int.tryParse(uri.substring(PcmSource._scheme.length));
  final format = id == null ? null : PcmSource._formats[id];
  if (format == null) {
    throw ArgumentError.value(
      uri,
      'media',
      'is not a live PcmSource: it is done, or was not created here',
    );
  }
  // cache-pause=no: a pause in the input (between two sentences) would
  // otherwise hold playback until a second is buffered, a lag that stays
  // for the rest of the entry. demuxer-termination-timeout=0: stop, next
  // or a dispose with a starved reader return at once instead of after
  // 100 ms.
  return 'demuxer=rawaudio,'
      'demuxer-rawaudio-format=${format.encoding.mpvValue},'
      'demuxer-rawaudio-rate=${format.sampleRate},'
      'demuxer-rawaudio-channels=${format.channels},'
      'cache-pause=no,'
      'demuxer-termination-timeout=0,'
      'gapless-audio=no'
      '${PcmSource._lowLatency.contains(id) ? ',audio-buffer=0.1' : ''}';
}

extension on PcmFormat {
  int durationBytes(Duration d) =>
      d.inMicroseconds *
      sampleRate ~/
      Duration.microsecondsPerSecond *
      bytesPerFrame;
}
