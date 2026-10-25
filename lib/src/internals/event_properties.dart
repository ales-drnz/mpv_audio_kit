// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_logic.dart';

// The observed properties on their way to the player: the event pump's
// cache of them ([_PropertyCache]), the dedup, the throttle of the clock
// values, the group of the audio parameters, and the re-read of the values
// mpv reported unavailable.

/// Throttle window for the playback-clock properties. mpv emits one update
/// per playloop iteration whose cadence is the audio output's buffer tick:
/// measured ~11 Hz on macOS coreaudio (mpv 0.41), but AO-dependent and not
/// guaranteed across platforms. ~33ms ≈ 30Hz is comfortably inside
/// human-perception territory for a progress bar update and keeps the
/// message bus uncluttered on outputs that tick faster. A value that falls
/// inside the window is held and sent when it closes, so the last one
/// before mpv goes quiet (a pause) is never lost.
const int _kClockThrottleMs = 33;

/// The properties the throttle applies to: every member is a pure function
/// of the playback clock, so all of them change on EVERY playloop tick and
/// would otherwise cross the isolate (and rebuild PlayerState) at the full
/// AO rate together.
const Set<String> _kClockThrottledProps = {
  'time-pos',
  'time-remaining',
  'playtime-remaining',
  'percent-pos',
  'audio-pts',
};

/// The properties behind the one `audioParams` cell. mpv reports them one
/// at a time, between other events, and the re-reads at FILE_LOADED and
/// AUDIO_RECONFIG add more, so forwarded one by one a track change emitted
/// up to six partial values. They are held together instead and cross as
/// one [MpvEventPropertyGroup]: as soon as all of them changed (a file
/// unloaded or loaded), before PLAYBACK_RESTART, or [_kGroupWindowMs] after
/// the first one, for a change that touches only some of them.
const Set<String> _kGroupedProps = {
  'audio-params',
  'audio-codec',
  'audio-codec-name',
};

/// How long a held [_kGroupedProps] change waits for the rest of its group.
const int _kGroupWindowMs = 33;

/// Monotonic clock for the property throttle.
final Stopwatch _throttleClock = Stopwatch()..start();

/// The event pump's view of the observed properties: the observe
/// format of each, the last value forwarded (for dedup), the last forward
/// time of the throttled ones, and the properties mpv reported unavailable
/// after they had a value.
class _PropertyCache {
  final formats = <String, int>{};
  final lastValues = <String, dynamic>{};
  final lastTimestamps = <String, int>{};
  final unavailable = <String>{};

  /// The newest value of each throttled property held back inside its
  /// window, sent when the window closes.
  final trailing = <String, double>{};

  /// The held changes of [_kGroupedProps], the newest one per property.
  final group = <String, MpvIsolateEvent>{};

  /// When the first change in [group] was held.
  int groupSince = 0;

  /// The entry of the last START_FILE forwarded to the player:
  /// [_sendEndOfContent] reads count only for it, and its END_FILE carries
  /// what mpv last reported of it.
  _StartedEntry? started;

  /// Whether the pump read `time-pos` itself after the last change mpv
  /// sent for it: the next change is read again ([_forwardFreshTimePos]).
  bool timePosRead = false;
}

/// The entry of a START_FILE, with the last `time-pos` and `duration` mpv
/// reported for it, in seconds. The unavailable notifications of its
/// unload leave them, so they still describe it when its END_FILE goes
/// out, after the unload.
class _StartedEntry {
  _StartedEntry(this.id);

  /// The `playlist_entry_id` the START_FILE named.
  final int id;

  double? position;
  double? duration;

  /// Keeps [value] of [name] when it is one of the two.
  void note(String name, double value) {
    switch (name) {
      case 'time-pos':
        position = value;
      case 'duration':
        duration = value;
    }
  }
}

/// How long the pump may wait for the next event: [cap], shortened to the
/// end of the earliest throttle window while a value is held back.
double _waitSeconds(_PropertyCache cache, double cap) {
  if (cache.trailing.isEmpty && cache.group.isEmpty) {
    return cap;
  }
  final now = _throttleClock.elapsedMilliseconds;
  var remaining = _kClockThrottleMs;
  if (cache.group.isNotEmpty) {
    remaining = cache.groupSince + _kGroupWindowMs - now;
  }
  for (final name in cache.trailing.keys) {
    final last = cache.lastTimestamps[name] ?? -_kClockThrottleMs;
    final left = last + _kClockThrottleMs - now;
    if (left < remaining) remaining = left;
  }
  if (remaining <= 0) return 0;
  final seconds = remaining / 1000;
  return seconds < cap ? seconds : cap;
}

/// Sends the held-back values whose throttle window has closed, so the
/// last clock value before mpv goes quiet (a pause) still arrives, and
/// the held group once its window has closed.
void _flushTrailing(_Send send, _PropertyCache cache) {
  if (cache.trailing.isEmpty && cache.group.isEmpty) return;
  final now = _throttleClock.elapsedMilliseconds;
  if (cache.group.isNotEmpty && now - cache.groupSince >= _kGroupWindowMs) {
    _flushGroup(send, cache);
  }
  for (final name in cache.trailing.keys.toList(growable: false)) {
    final last = cache.lastTimestamps[name] ?? -_kClockThrottleMs;
    if (now - last < _kClockThrottleMs) continue;
    final value = cache.trailing.remove(name)!;
    _forwardValue(send, name, mpv.MpvFormat.mpvFormatDouble, value, cache);
  }
}

/// A property change of [name] in [format], whose [value] the transport
/// decoded ([kPropertyUnavailable] when mpv sent no data,
/// [kPropertyUnobserved] for a format the player does not observe).
void _dispatchProperty(
  _Send send,
  String name,
  int format,
  Object? value,
  _PropertyCache cache,
) {
  if (identical(value, kPropertyUnavailable)) {
    _forwardUnavailable(send, name, cache);
    return;
  }
  // An unobserved format (OSD_STRING, top-level BYTE_ARRAY): drop it.
  if (identical(value, kPropertyUnobserved)) return;
  // Every value mpv reports, ahead of the throttle and the dedup.
  if (value is double) cache.started?.note(name, value);
  _forwardValue(send, name, format, value, cache);
}

/// Forwards [value] of property [name] to the main isolate unless it equals
/// the last one forwarded, or it is a clock-driven property inside its
/// throttle window.
void _forwardValue(
  _Send send,
  String name,
  int format,
  dynamic value,
  _PropertyCache cache,
) {
  cache.unavailable.remove(name);
  final lastValues = cache.lastValues;

  if (format == mpv.MpvFormat.mpvFormatDouble &&
      _kClockThrottledProps.contains(name)) {
    // Monotonic clock: a wall-clock jump (NTP sync, manual change) would
    // freeze or double-fire a DateTime-based throttle.
    final now = _throttleClock.elapsedMilliseconds;
    final last = cache.lastTimestamps[name] ?? -_kClockThrottleMs;
    if (now - last < _kClockThrottleMs) {
      // Held, not dropped: mpv may send nothing more (a pause), so the
      // newest value goes out when the window closes (_flushTrailing).
      cache.trailing[name] = value as double;
      return;
    }
    cache.lastTimestamps[name] = now;
    cache.trailing.remove(name);
  }

  if (format == mpv.MpvFormat.mpvFormatNode) {
    // Dedup by structural equality against the previously decoded tree:
    // early-out on the first difference, no per-event string allocation.
    // High-churn nodes (`demuxer-cache-state` during streaming) differ on
    // nearly every emission, so the compare usually exits within a few
    // scalar checks.
    final prev = lastValues[name];
    if (prev != null && _deepNodeEquals(prev, value)) {
      return;
    }
  } else if (lastValues[name] == value) {
    return;
  }
  lastValues[name] = value;

  _sendProperty(send, cache, name, switch (format) {
    mpv.MpvFormat.mpvFormatDouble => MpvEventPropertyDouble(
      name,
      value as double,
    ),
    mpv.MpvFormat.mpvFormatString => MpvEventPropertyString(
      name,
      value as String,
    ),
    mpv.MpvFormat.mpvFormatNode => MpvEventPropertyNode(name, value),
    _ => MpvEventPropertyInt(name, value as int),
  });
}

/// The property became unavailable (`MPV_FORMAT_NONE`, `data == nullptr`):
/// the file was unloaded, or the new one lacks the value. Forget the cached
/// value and tell the main isolate once, if it had seen a value. mpv does
/// not always notify when such a property comes back (a change notified
/// while it was still unavailable is not repeated), so it is also marked
/// for [_rereadUnavailable].
void _forwardUnavailable(_Send send, String name, _PropertyCache cache) {
  cache.lastTimestamps.remove(name);
  cache.trailing.remove(name);
  if (!cache.lastValues.containsKey(name)) return;
  cache.lastValues.remove(name);
  cache.unavailable.add(name);
  _sendProperty(send, cache, name, MpvEventPropertyUnavailable(name));
}

/// Sends a property change, or holds it in the group when [name] is one of
/// [_kGroupedProps].
void _sendProperty(
  _Send send,
  _PropertyCache cache,
  String name,
  MpvIsolateEvent event,
) {
  if (!_kGroupedProps.contains(name)) {
    send(event);
    return;
  }
  if (cache.group.isEmpty) {
    cache.groupSince = _throttleClock.elapsedMilliseconds;
  }
  // Re-inserted, so the group keeps the order of the newest changes.
  cache.group
    ..remove(name)
    ..[name] = event;
  if (cache.group.length == _kGroupedProps.length) _flushGroup(send, cache);
}

/// Sends the held group changes as one [MpvEventPropertyGroup].
void _flushGroup(_Send send, _PropertyCache cache) {
  if (cache.group.isEmpty) return;
  send(MpvEventPropertyGroup(cache.group.values.toList(growable: false)));
  cache.group.clear();
}

/// Reads again every property mpv reported unavailable after it had a
/// value, and forwards those that are back. Runs at the points where a
/// new file's values settle (file loaded, audio reconfigured, playback
/// restarted), since mpv may not send them itself.
Future<void> _rereadUnavailable(
  CoreReader reader,
  _Send send,
  _PropertyCache cache,
) async {
  if (cache.unavailable.isEmpty) return;
  for (final name in cache.unavailable.toList(growable: false)) {
    final format = cache.formats[name];
    if (format == null) continue;
    // One property that fails to read or decode must not cost the others,
    // or the event (FILE_LOADED, AUDIO_RECONFIG) the caller sends next.
    try {
      // One await on a future picked first, not one per arm of a switch
      // expression (see the WebAssembly note in _sendEndOfContent).
      final read = switch (format) {
        mpv.MpvFormat.mpvFormatDouble => reader.float(name),
        mpv.MpvFormat.mpvFormatFlag => reader.flag(name),
        mpv.MpvFormat.mpvFormatInt64 => reader.int64(name),
        mpv.MpvFormat.mpvFormatString => reader.string(name),
        mpv.MpvFormat.mpvFormatNode => reader.node(name),
        _ => null,
      };
      final value = await read;
      if (name == 'time-pos') cache.timePosRead = true;
      if (value != null) _forwardValue(send, name, format, value, cache);
    } catch (e) {
      send(MpvEventInternalLog('warn', 're-reading $name failed: $e'));
    }
  }
}

/// Reads `time-pos` for the pump's own use: the payloads of FILE_LOADED
/// and PLAYBACK_RESTART, and the park. The next change mpv sends for it is
/// read again ([_forwardFreshTimePos]).
Future<double?> _readTimePos(CoreReader reader, _PropertyCache cache) {
  cache.timePosRead = true;
  return reader.float('time-pos');
}

/// Forwards the `time-pos` change that follows a read of it by the pump
/// ([_readTimePos], [_rereadUnavailable]) with a fresh read in place of
/// mpv's value. mpv samples `time-pos` for its observers at a tick, at
/// most every 50 ms and none while the core is parked, and hands the
/// newest sample over when the pump asks for the next event. That sample
/// can be older than the pump's read: an entry that loads, plays out and
/// parks between two ticks (a short one, or one the null output plays
/// untimed) gives the position of its start after the park read, and
/// nothing moves it again while it stays parked. mpv keeps one sample per
/// property, so only this change can be older than the read; the ones
/// after it are mpv's own.
Future<void> _forwardFreshTimePos(
  CoreReader reader,
  _Send send,
  _PropertyCache cache,
) async {
  cache.timePosRead = false;
  final value = await reader.float('time-pos');
  _dispatchProperty(
    send,
    'time-pos',
    mpv.MpvFormat.mpvFormatDouble,
    value ?? kPropertyUnavailable,
    cache,
  );
}

/// Reads `core-idle` and forwards it even when it equals the last value
/// forwarded. Runs at PLAYBACK_RESTART, where mpv sets it for the file that
/// starts. The player clears `playing` at every END_FILE and at idle, and
/// only a `core-idle` value sets it again. mpv samples the observed
/// properties once per playloop iteration, and the pump reads them when it
/// gets to them: a file that starts in the iteration the previous one
/// ended (a prefetched gapless advance), or while the pump is still on the
/// previous file's events, leaves no idle value in between. The next
/// value then equals the last one forwarded, and `playing` stayed false
/// for the whole file.
Future<void> _forwardCoreIdle(
  CoreReader reader,
  _Send send,
  _PropertyCache cache,
) async {
  final idle = await reader.flag('core-idle');
  if (idle == null) return;
  cache.lastValues.remove('core-idle');
  _forwardValue(send, 'core-idle', mpv.MpvFormat.mpvFormatFlag, idle, cache);
}

/// Structural equality over decoded `mpv_node` trees
/// (`Map<String, dynamic>`, `List`, scalars or [Uint8List]).
bool _deepNodeEquals(dynamic a, dynamic b) {
  if (identical(a, b)) return true;
  if (a is Map) {
    if (b is! Map || a.length != b.length) return false;
    for (final entry in a.entries) {
      if (!b.containsKey(entry.key) ||
          !_deepNodeEquals(entry.value, b[entry.key])) {
        return false;
      }
    }
    return true;
  }
  if (a is List<int> && a is TypedData) {
    if (b is! List<int> || b is! TypedData || a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  if (a is List) {
    if (b is! List || a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepNodeEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
