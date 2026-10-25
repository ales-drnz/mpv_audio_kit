// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../mpv_constants.dart' as mpv;
import 'core_events.dart';

part 'event_end_of_content.dart';
part 'event_properties.dart';

// The event pump's logic, the same on every transport: which events take
// reads of the core and in which order, the payloads they ride, the
// property cache, the end of content. A transport decodes each mpv event
// out of the core's memory, hands it here, and waits for the future a
// dispatch returns before it takes the next event from mpv: the native
// pump reads synchronously on its own isolate, the web pump reads
// asynchronously, and in both the later events stay in mpv's queue
// meanwhile, so the player sees them in the same order.

typedef _Send = void Function(MpvIsolateEvent event);

/// The value a transport hands [EventLogic.property] when mpv sent the
/// change without data (`MPV_FORMAT_NONE`): the property is unavailable.
@internal
const Object kPropertyUnavailable = _Sentinel('unavailable');

/// The value a transport hands [EventLogic.property] for a format the
/// player does not observe (OSD_STRING, a top-level BYTE_ARRAY).
@internal
const Object kPropertyUnobserved = _Sentinel('unobserved');

final class _Sentinel {
  const _Sentinel(this.name);
  final String name;
  @override
  String toString() => name;
}

/// The property reads the event logic takes, in mpv's formats. Each one
/// answers `null` when the read fails, and once the pump was asked to
/// stop: nothing read after a stop reaches the player.
@internal
abstract interface class CoreReader {
  /// [name] as a string (`MPV_FORMAT_STRING`).
  Future<String?> string(String name);

  /// [name] as a double (`MPV_FORMAT_DOUBLE`).
  Future<double?> float(String name);

  /// [name] as an integer (`MPV_FORMAT_INT64`).
  Future<int?> int64(String name);

  /// [name] as a flag (`MPV_FORMAT_FLAG`): 1 or 0.
  Future<int?> flag(String name);

  /// [name] as a decoded node tree (`MPV_FORMAT_NODE`), byte arrays as
  /// [Uint8List].
  Future<Object?> node(String name);
}

/// The event logic of one core: turns the events a transport decodes into
/// the events the player consumes, through [send].
@internal
final class EventLogic {
  /// The logic of a core that [reader] reads and whose events go to
  /// [send].
  EventLogic(this._reader, this._send);

  final CoreReader _reader;
  final _Send _send;
  final _PropertyCache _cache = _PropertyCache();

  /// Registers the observe format of [name], which [property] changes and
  /// the re-read of an unavailable value use.
  void observe(String name, int format) => _cache.formats[name] = format;

  /// How long the pump may wait for the next event: [cap], shortened to the
  /// end of the earliest throttle window while a value is held back.
  double waitSeconds(double cap) => _waitSeconds(_cache, cap);

  /// Whether a value is held back for a throttle window or the group.
  bool get holdsValues => _cache.trailing.isNotEmpty || _cache.group.isNotEmpty;

  /// Sends the held values whose window has closed. The pump calls it after
  /// every event and whenever its wait ends with no event.
  void flushTrailing() => _flushTrailing(_send, _cache);

  /// A property change of [name] in [format], with the [value] the
  /// transport decoded, [kPropertyUnavailable] or [kPropertyUnobserved].
  /// Returns a future when the change takes reads (an end-of-content
  /// trigger); the pump waits for it before the next event.
  Future<void>? property(String name, int format, Object? value) {
    if (name != 'pause') _dispatchProperty(_send, name, format, value, _cache);
    if (_kEndOfContentTriggers.contains(name)) {
      return _sendEndOfContent(_reader, _send, _cache);
    }
    return null;
  }

  /// Any other event, as the transport decoded it: the bare
  /// [MpvEventFileLoaded], [MpvEventPlaybackRestart] and [MpvEventEndFile]
  /// are filled here with the reads they carry. Returns a future when the
  /// event takes reads; the pump waits for it before the next event.
  Future<void>? dispatch(MpvIsolateEvent event) {
    switch (event) {
      case MpvEventStartFile(:final entryId):
        // A clock value held from the previous file must not land after the
        // new one starts.
        _cache.trailing.clear();
        _cache.started = _StartedEntry(entryId);
        _send(event);
      case MpvEventFileLoaded():
        return _fileLoaded();
      case MpvEventEndFile(:final entryId, :final reason, :final error):
        if (reason == mpv.MpvEndFileReason.mpvEndFileReasonEof ||
            reason == mpv.MpvEndFileReason.mpvEndFileReasonError) {
          return _endFile(entryId, reason, error);
        }
        _send(_endFileEvent(entryId, reason, error, lastEntry: false));
      case MpvEventAudioReconfig():
        return _audioReconfig(event);
      case MpvEventPlaybackRestart():
        return _playbackRestart();
      default:
        _send(event);
    }
    return null;
  }

  // The payload reads run in the pump, not on the main isolate: each one
  // waits for the playloop, and the file-load boundary is exactly the window
  // where the playloop can be stuck for seconds initializing the audio
  // output. A failed payload read must never swallow the event itself:
  // lifecycle, af resync and the waveform re-arm all ride it.
  Future<void> _fileLoaded() async {
    MpvEventFileLoaded loaded;
    try {
      loaded = await _readFileLoadedEvent();
    } catch (e, st) {
      _send(
        MpvEventInternalLog('warn', 'file-loaded payload read failed: $e\n$st'),
      );
      loaded = MpvEventFileLoaded();
    }
    // The values mpv has not notified again go first, so the player has
    // them when FILE_LOADED ends the loading state.
    await _rereadUnavailable(_reader, _send, _cache);
    _send(loaded);
    // A short entry can reach EOF before this event is handled: its
    // `eof-reached` change may already be spent (re-read above, or skipped
    // by mpv), so the end of content is read again after it.
    await _sendEndOfContent(_reader, _send, _cache);
  }

  Future<void> _endFile(int entryId, int reason, int error) async {
    final lastEntry = await _isLastEntry(_reader, entryId);
    _send(_endFileEvent(entryId, reason, error, lastEntry: lastEntry));
  }

  /// The END_FILE of entry [entryId]. mpv has unloaded the file by now:
  /// what it reported of the entry comes from the START_FILE that named it
  /// ([_PropertyCache.started]).
  MpvEventEndFile _endFileEvent(
    int entryId,
    int reason,
    int error, {
    required bool lastEntry,
  }) {
    final started = _cache.started;
    final entry = started?.id == entryId ? started : null;
    return MpvEventEndFile(
      entryId,
      reason,
      error,
      lastEntry: lastEntry,
      position: entry?.position,
      duration: entry?.duration,
    );
  }

  Future<void> _audioReconfig(MpvIsolateEvent event) async {
    await _rereadUnavailable(_reader, _send, _cache);
    _send(event);
  }

  // The landing position rides the event payload (read here, where waiting
  // on the core is harmless), so it reaches the stream before any throttled
  // time-pos event from the property observer. A held time-pos from before
  // the seek would land after it and step the position back: drop it. The
  // other clock values keep the newest one mpv sent, which the seek may
  // already have moved.
  Future<void> _playbackRestart() async {
    _cache.trailing.remove('time-pos');
    _flushGroup(_send, _cache);
    // Ahead of the event, so a listener of the restart sees `playing`.
    await _forwardCoreIdle(_reader, _send, _cache);
    _send(MpvEventPlaybackRestart(timePos: await _reader.float('time-pos')));
    await _rereadUnavailable(_reader, _send, _cache);
    await _sendEndOfContent(_reader, _send, _cache);
  }

  /// Reads the file-load payload (path, playlist, position, chapters,
  /// embedded cover) for [MpvEventFileLoaded]. A malformed or oversized
  /// embedded picture must not abort the rest of the payload, so the cover
  /// read is guarded on its own: the event then carries a `null` cover and
  /// consumers clear stale artwork.
  Future<MpvEventFileLoaded> _readFileLoadedEvent() async {
    (Uint8List, String)? cover;
    try {
      cover = await _readEmbeddedCover();
    } catch (_) {
      // Cover stays null; the rest of the payload is still delivered.
    }
    return MpvEventFileLoaded(
      path: await _reader.string('path'),
      playlist: await _reader.node('playlist'),
      timePos: await _reader.float('time-pos'),
      chapterIndex: await _reader.int64('chapter'),
      chapterList: await _reader.node('chapter-list'),
      coverData: cover?.$1,
      coverMime: cover?.$2,
    );
  }

  /// Reads the embedded cover art of the loaded file via the
  /// `embedded-cover-art-data` and `embedded-cover-art-mime` properties.
  /// Returns `null` when the file has no embedded cover. The bytes are the
  /// original PNG, JPEG or other format as embedded (no decode, no
  /// conversion), copied out of mpv-owned memory by the reader.
  Future<(Uint8List, String)?> _readEmbeddedCover() async {
    final data = await _reader.node('embedded-cover-art-data');
    if (data is! Uint8List || data.isEmpty) return null;
    final mime =
        await _reader.string('embedded-cover-art-mime') ??
        'application/octet-stream';
    return (data, mime);
  }
}
