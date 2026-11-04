// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The one decoder of mpv events, for both transports: the native pump reads
// the core's memory over FFI, the web pump the module's memory over
// js_interop, and both hand this file the addresses. Plain Dart, so the
// rules run on the VM for both layouts.

import 'package:meta/meta.dart';

import '../mpv_constants.dart';
import 'core_events.dart';
import 'event_logic.dart';

/// The memory of a core, as the decoder reads it: the values at an
/// address, little-endian.
@internal
abstract interface class CoreMemory {
  /// The size of a pointer and of a `size_t`: 8 on a 64-bit host, 4 on
  /// wasm32 and on 32-bit ARM.
  int get pointerSize;

  /// The `int32_t` at [address].
  int i32(int address);

  /// The `int64_t` at [address].
  int i64(int address);

  /// The `double` at [address].
  double f64(int address);

  /// The pointer, or the `size_t`, at [address].
  int pointer(int address);

  /// The UTF-8 C string that starts at [address], `null` for 0.
  String? string(int address);

  /// A copy of the [length] bytes at [address], out of the core's memory
  /// before mpv frees it. With [transfer], in the form the transport
  /// sends to another isolate at the cost of one copy.
  Object bytes(int address, int length, {bool transfer = false});
}

/// What one mpv event asks of [EventLogic]: an event to dispatch, a
/// property change, or an audio reconfig.
@internal
sealed class DecodedEvent {}

/// An event [EventLogic.dispatch] takes.
@internal
final class Dispatch extends DecodedEvent {
  /// Wraps [event].
  Dispatch(this.event);

  /// The event.
  final MpvIsolateEvent event;
}

/// A change of an observed property, as [EventLogic.property] takes it.
@internal
final class PropertyChange extends DecodedEvent {
  /// The change of [name] in [format] to [value].
  PropertyChange(this.name, this.format, this.value);

  /// The property.
  final String name;

  /// The format it was observed in.
  final int format;

  /// Its value, [kPropertyUnavailable] or [kPropertyUnobserved].
  final Object? value;
}

/// MPV_EVENT_AUDIO_RECONFIG, which [EventLogic.audioReconfig] handles.
@internal
final class AudioReconfig extends DecodedEvent {}

/// Decodes the `mpv_event` at [event] out of [m], and hands it to [logic].
/// Returns the future of the reads the event takes, if any. The payload is
/// valid only until the next `mpv_wait_event`: everything is copied before
/// this returns.
@internal
Future<void>? dispatchEvent(EventLogic logic, CoreMemory m, int event) =>
    switch (decodeEvent(m, event)) {
      null => null,
      Dispatch(:final event) => logic.dispatch(event),
      PropertyChange(:final name, :final format, :final value) =>
        logic.property(name, format, value),
      AudioReconfig() => logic.audioReconfig(),
    };

/// The `mpv_event` at [event] in [m], decoded; `null` for an event the
/// player does not take.
///
/// The offsets are those of the client API structs for the pointer size of
/// [m]: `mpv_event` is the same on every ABI (the id at 0, the error at 4,
/// `reply_userdata` at 8 and `data` at 16), and so is `mpv_event_end_file`
/// with the four fields of the patch read_error (28, 32, 40, 48).
@internal
DecodedEvent? decodeEvent(CoreMemory m, int event) =>
    _decoders[m.i32(event)]?.call(m, event);

/// The `error` of the event at [e].
int _error(CoreMemory m, int e) => m.i32(e + 4);

/// The `reply_userdata` of the event at [e].
int _userdata(CoreMemory m, int e) => m.i64(e + 8);

/// The `data` of the event at [e].
int _data(CoreMemory m, int e) => m.pointer(e + 16);

/// One decoder for each event the player takes, by event id.
final Map<int, DecodedEvent Function(CoreMemory, int)> _decoders = {
  MpvEventId.mpvEventPropertyChange: _propertyChange,
  MpvEventId.mpvEventShutdown: (_, _) => Dispatch(MpvEventShutdown()),
  MpvEventId.mpvEventStartFile: (m, e) =>
      Dispatch(MpvEventStartFile(m.i64(_data(m, e)))),
  MpvEventId.mpvEventFileLoaded: (_, _) => Dispatch(MpvEventFileLoaded()),
  MpvEventId.mpvEventEndFile: (m, e) => Dispatch(_endFile(m, _data(m, e))),
  MpvEventId.mpvEventAudioReconfig: (_, _) => AudioReconfig(),
  MpvEventId.mpvEventSetPropertyReply: (m, e) =>
      Dispatch(MpvEventReply(_userdata(m, e), _error(m, e))),
  MpvEventId.mpvEventCommandReply: _commandReply,
  MpvEventId.mpvEventGetPropertyReply: _getReply,
  MpvEventId.mpvEventLogMessage: _log,
  MpvEventId.mpvEventHook: (m, e) => Dispatch(
    MpvEventHookFired(
      m.i64(_data(m, e) + 8),
      m.string(m.pointer(_data(m, e))) ?? '',
    ),
  ),
  MpvEventId.mpvEventPlaybackRestart: (_, _) =>
      Dispatch(MpvEventPlaybackRestart()),
};

DecodedEvent _propertyChange(CoreMemory m, int e) {
  final data = _data(m, e);
  final format = m.i32(data + m.pointerSize);
  return PropertyChange(
    m.string(m.pointer(data)) ?? '',
    format,
    _changeValue(m, format, m.pointer(data + _propertyData(m.pointerSize))),
  );
}

/// An `mpv_event_command`, whose only member is the `mpv_node result`
/// (`loadfile` returns `playlist_entry_id` in it).
DecodedEvent _commandReply(CoreMemory m, int e) {
  final error = _error(m, e);
  final data = _data(m, e);
  final result = error >= 0 && data != 0 ? decodeNode(m, data) : null;
  return Dispatch(MpvEventReply(_userdata(m, e), error, result));
}

DecodedEvent _getReply(CoreMemory m, int e) {
  final error = _error(m, e);
  final value = error >= 0 ? propertyValue(m, _data(m, e)) : null;
  return Dispatch(MpvEventGetReply(_userdata(m, e), error, value));
}

/// An `mpv_event_log_message`: the prefix, the level and the text, in a
/// pointer each.
DecodedEvent _log(CoreMemory m, int e) {
  final data = _data(m, e);
  String text(int i) => m.string(m.pointer(data + i * m.pointerSize)) ?? '';
  return Dispatch(MpvEventLog(text(0), text(1), text(2).trimRight()));
}

/// Where `mpv_event_property` keeps `data`: past the name and the format,
/// aligned to a pointer.
int _propertyData(int pointerSize) => pointerSize == 8 ? 16 : 8;

/// The `mpv_event_end_file` at [data]. A duration or position mpv did not
/// know (-1) is `null`, and the event logic keeps what mpv reported of the
/// entry before.
MpvEventEndFile _endFile(CoreMemory m, int data) {
  double? known(double seconds) => seconds >= 0 ? seconds : null;
  return MpvEventEndFile(
    m.i64(data + 8),
    m.i32(data),
    m.i32(data + 4),
    readError: m.i32(data + 28) != 0,
    skippedSegments: m.i64(data + 32),
    duration: known(m.f64(data + 40)),
    position: known(m.f64(data + 48)),
  );
}

/// The value of a property change as [EventLogic.property] takes it.
Object? _changeValue(CoreMemory m, int format, int data) {
  if (format == MpvFormat.mpvFormatNone || data == 0) {
    return kPropertyUnavailable;
  }
  return switch (format) {
    MpvFormat.mpvFormatDouble ||
    MpvFormat.mpvFormatFlag ||
    MpvFormat.mpvFormatInt64 ||
    MpvFormat.mpvFormatString ||
    MpvFormat.mpvFormatNode => _value(m, format, data, transfer: false),
    _ => kPropertyUnobserved,
  };
}

/// The value of the `mpv_event_property` at [property], as a read carries
/// it; `null` without one. The byte arrays of a node come in the form the
/// transport sends on: the polled PCM, tap and waveform frames are copied
/// once.
@internal
Object? propertyValue(CoreMemory m, int property) {
  if (property == 0) return null;
  final data = m.pointer(property + _propertyData(m.pointerSize));
  if (data == 0) return null;
  return _value(m, m.i32(property + m.pointerSize), data, transfer: true);
}

/// The value of format [format] at [data]: a flag as an int.
Object? _value(CoreMemory m, int format, int data, {required bool transfer}) =>
    switch (format) {
      MpvFormat.mpvFormatDouble => m.f64(data),
      MpvFormat.mpvFormatFlag => m.i32(data),
      MpvFormat.mpvFormatInt64 => m.i64(data),
      MpvFormat.mpvFormatString => m.string(m.pointer(data)),
      MpvFormat.mpvFormatNode => decodeNode(m, data, transfer: transfer),
      _ => null,
    };

/// The `mpv_node` at [node], as a Dart tree: a string, a bool for a flag,
/// an int, a double, a list, a map with string keys, or the bytes of a
/// byte array ([CoreMemory.bytes], sent on as is with [transfer]). `null`
/// for any other format. Everything is copied, so mpv can free the node
/// right after.
///
/// `mpv_node` is the 8 bytes of its union and the format at 8, on every
/// ABI; `mpv_node_list` is `num`, then the `values` and `keys` pointers;
/// `mpv_byte_array` is the `data` pointer, then its `size_t` size.
@internal
Object? decodeNode(CoreMemory m, int node, {bool transfer = false}) {
  final p = m.pointerSize;
  switch (m.i32(node + 8)) {
    case MpvFormat.mpvFormatString:
      return m.string(m.pointer(node));
    case MpvFormat.mpvFormatFlag:
      return m.i32(node) != 0;
    case MpvFormat.mpvFormatInt64:
      return m.i64(node);
    case MpvFormat.mpvFormatDouble:
      return m.f64(node);
    case MpvFormat.mpvFormatNodeArray:
      return _nodeArray(m, m.pointer(node), transfer);
    case MpvFormat.mpvFormatNodeMap:
      return _nodeMap(m, m.pointer(node), transfer);
    case MpvFormat.mpvFormatByteArray:
      final ba = m.pointer(node);
      return m.bytes(m.pointer(ba), m.pointer(ba + p), transfer: transfer);
  }
  return null;
}

/// The `mpv_node_list` at [list] of an array.
List<Object?> _nodeArray(CoreMemory m, int list, bool transfer) {
  final values = m.pointer(list + m.pointerSize);
  return [
    for (var i = 0; i < m.i32(list); i++)
      decodeNode(m, values + 16 * i, transfer: transfer),
  ];
}

/// The `mpv_node_list` at [list] of a map, its keys after its values.
Map<String, dynamic> _nodeMap(CoreMemory m, int list, bool transfer) {
  final p = m.pointerSize;
  final values = m.pointer(list + p);
  final keys = m.pointer(list + 2 * p);
  return <String, dynamic>{
    for (var i = 0; i < m.i32(list); i++)
      m.string(m.pointer(keys + p * i)) ?? '': decodeNode(
        m,
        values + 16 * i,
        transfer: transfer,
      ),
  };
}
