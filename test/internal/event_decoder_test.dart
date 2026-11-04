// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The one decoder of mpv events (event_decoder.dart) on both transports:
// each event is laid out in the memory of this process, as the native pump
// reads it over FFI, and in a wasm32 memory with 4-byte pointers, as the
// web pump reads the module's. Both must give the same event, and the one
// expected.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/internals/event_decoder.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/internals/event_logic.dart';
import 'package:mpv_audio_kit/src/mpv_constants.dart';
import 'package:test/test.dart';

/// Writes structs into a memory and hands it to the decoder.
abstract class _Heap {
  CoreMemory get memory;
  int get pointerSize => memory.pointerSize;

  /// [size] zeroed bytes, 8-aligned.
  int alloc(int size);
  void i32(int address, int value);
  void i64(int address, int value);
  void f64(int address, double value);
  void pointer(int address, int value);

  /// A NUL-terminated UTF-8 copy of [s].
  int cString(String s) {
    final bytes = utf8.encode(s);
    final p = alloc(bytes.length + 1);
    for (var i = 0; i < bytes.length; i++) {
      byte(p + i, bytes[i]);
    }
    return p;
  }

  void byte(int address, int value);
  void free();
}

/// The memory of this process, through FFI.
final class _NativeHeap extends _Heap {
  final List<Pointer<Uint8>> _blocks = [];

  @override
  CoreMemory get memory => nativeMemory;

  @override
  int alloc(int size) {
    final p = calloc<Uint8>(size < 8 ? 8 : size);
    _blocks.add(p);
    return p.address;
  }

  @override
  void i32(int a, int v) => Pointer<Int32>.fromAddress(a).value = v;
  @override
  void i64(int a, int v) => Pointer<Int64>.fromAddress(a).value = v;
  @override
  void f64(int a, double v) => Pointer<Double>.fromAddress(a).value = v;
  @override
  void pointer(int a, int v) => Pointer<UintPtr>.fromAddress(a).value = v;
  @override
  void byte(int a, int v) => Pointer<Uint8>.fromAddress(a).value = v;

  @override
  void free() {
    for (final p in _blocks) {
      calloc.free(p);
    }
  }
}

/// A wasm32 memory: 4-byte pointers, little-endian, as the web module's.
final class _Wasm32Heap extends _Heap {
  final ByteData _data = ByteData(1 << 16);
  int _next = 8;

  @override
  late final CoreMemory memory = _Wasm32Memory(this);

  @override
  int alloc(int size) {
    final p = _next;
    _next += (size + 7) & ~7;
    return p;
  }

  @override
  void i32(int a, int v) => _data.setInt32(a, v, Endian.little);
  @override
  void i64(int a, int v) => _data.setInt64(a, v, Endian.little);
  @override
  void f64(int a, double v) => _data.setFloat64(a, v, Endian.little);
  @override
  void pointer(int a, int v) => _data.setUint32(a, v, Endian.little);
  @override
  void byte(int a, int v) => _data.setUint8(a, v);
  @override
  void free() {}
}

/// The reads of a [_Wasm32Heap], as the web module answers them.
final class _Wasm32Memory implements CoreMemory {
  _Wasm32Memory(this._heap);

  final _Wasm32Heap _heap;

  @override
  int get pointerSize => 4;
  @override
  int i32(int a) => _heap._data.getInt32(a, Endian.little);
  @override
  int i64(int a) => _heap._data.getInt64(a, Endian.little);
  @override
  double f64(int a) => _heap._data.getFloat64(a, Endian.little);
  @override
  int pointer(int a) => _heap._data.getUint32(a, Endian.little);
  @override
  String? string(int a) {
    if (a == 0) return null;
    var end = a;
    while (_heap._data.getUint8(end) != 0) {
      end++;
    }
    return utf8.decode(
      _heap._data.buffer.asUint8List(a, end - a),
      allowMalformed: true,
    );
  }

  @override
  Object bytes(int a, int length, {bool transfer = false}) =>
      Uint8List.fromList(_heap._data.buffer.asUint8List(a, length));
}

// ── Struct writers, offsets by pointer size ───────────────────────────────

int _event(_Heap h, int id, {int error = 0, int userdata = 0, int data = 0}) {
  final e = h.alloc(24);
  h.i32(e, id);
  h.i32(e + 4, error);
  h.i64(e + 8, userdata);
  h.pointer(e + 16, data);
  return e;
}

int _propertyData(_Heap h) => h.pointerSize == 8 ? 16 : 8;

int _property(_Heap h, String name, int format, int data) {
  final p = h.alloc(24);
  h.pointer(p, h.cString(name));
  h.i32(p + h.pointerSize, format);
  h.pointer(p + _propertyData(h), data);
  return p;
}

/// The value of [format] for a property payload: its address.
int _scalar(_Heap h, int format, Object value) {
  final p = h.alloc(8);
  switch (format) {
    case MpvFormat.mpvFormatDouble:
      h.f64(p, value as double);
    case MpvFormat.mpvFormatFlag:
      h.i32(p, value as int);
    case MpvFormat.mpvFormatInt64:
      h.i64(p, value as int);
    case MpvFormat.mpvFormatString:
      h.pointer(p, h.cString(value as String));
  }
  return p;
}

/// An mpv_node of [value]: a string, bool, int, double, list, map or
/// byte array ([Uint8List]).
int _node(_Heap h, Object? value) {
  final n = h.alloc(16);
  _fillNode(h, n, value);
  return n;
}

void _fillNode(_Heap h, int n, Object? value) {
  final p = h.pointerSize;
  switch (value) {
    case String():
      h.pointer(n, h.cString(value));
      h.i32(n + 8, MpvFormat.mpvFormatString);
    case bool():
      h.i32(n, value ? 1 : 0);
      h.i32(n + 8, MpvFormat.mpvFormatFlag);
    case int():
      h.i64(n, value);
      h.i32(n + 8, MpvFormat.mpvFormatInt64);
    case double():
      h.f64(n, value);
      h.i32(n + 8, MpvFormat.mpvFormatDouble);
    case Uint8List():
      final ba = h.alloc(2 * p);
      final data = h.alloc(value.length);
      for (var i = 0; i < value.length; i++) {
        h.byte(data + i, value[i]);
      }
      h.pointer(ba, data);
      h.pointer(ba + p, value.length);
      h.pointer(n, ba);
      h.i32(n + 8, MpvFormat.mpvFormatByteArray);
    case List():
      h.pointer(n, _list(h, value, null));
      h.i32(n + 8, MpvFormat.mpvFormatNodeArray);
    case Map():
      h.pointer(
        n,
        _list(h, value.values.toList(), value.keys.cast<String>().toList()),
      );
      h.i32(n + 8, MpvFormat.mpvFormatNodeMap);
    default:
      h.i32(n + 8, MpvFormat.mpvFormatNone);
  }
}

int _list(_Heap h, List<Object?> values, List<String>? keys) {
  final p = h.pointerSize;
  final list = h.alloc(3 * p);
  final nodes = h.alloc(16 * values.length);
  for (var i = 0; i < values.length; i++) {
    _fillNode(h, nodes + 16 * i, values[i]);
  }
  h.i32(list, values.length);
  h.pointer(list + p, nodes);
  if (keys != null) {
    final k = h.alloc(p * keys.length);
    for (var i = 0; i < keys.length; i++) {
      h.pointer(k + p * i, h.cString(keys[i]));
    }
    h.pointer(list + 2 * p, k);
  }
  return list;
}

// ── What a decoded event says, comparable ────────────────────────────────

Object? _plain(Object? v) => switch (v) {
  TransferableTypedData() => v.materialize().asUint8List().toList(),
  Uint8List() => v.toList(),
  List() => v.map(_plain).toList(),
  Map() => v.map((k, x) => MapEntry(k, _plain(x))),
  _ => v,
};

Object? _describe(DecodedEvent? d) => switch (d) {
  null => null,
  AudioReconfig() => 'audio-reconfig',
  PropertyChange(:final name, :final format, :final value) => {
    'property': name,
    'format': format,
    'value': _plain(value),
  },
  Dispatch(:final event) => switch (event) {
    MpvEventShutdown() => 'shutdown',
    MpvEventFileLoaded() => 'file-loaded',
    MpvEventPlaybackRestart() => 'playback-restart',
    MpvEventStartFile(:final entryId) => {'start-file': entryId},
    final MpvEventEndFile e => {
      'end-file': e.entryId,
      'reason': e.reason,
      'error': e.error,
      'readError': e.readError,
      'skippedSegments': e.skippedSegments,
      'duration': e.duration,
      'position': e.position,
    },
    MpvEventReply(:final userdata, :final error, :final result) => {
      'reply': userdata,
      'error': error,
      'result': _plain(result),
    },
    MpvEventGetReply(:final userdata, :final error, :final value) => {
      'get-reply': userdata,
      'error': error,
      'value': _plain(value),
    },
    MpvEventLog(:final prefix, :final level, :final text) => {
      'log': text,
      'prefix': prefix,
      'level': level,
    },
    MpvEventHookFired(:final id, :final name) => {'hook': name, 'id': id},
    _ => event.runtimeType.toString(),
  },
};

/// Builds the event with [build] in both memories, decodes it in each, and
/// expects both to say [expected].
void _same(String name, int Function(_Heap) build, Object? expected) {
  test(name, () {
    final native = _NativeHeap();
    final wasm = _Wasm32Heap();
    try {
      final fromNative = _describe(decodeEvent(native.memory, build(native)));
      final fromWasm = _describe(decodeEvent(wasm.memory, build(wasm)));
      expect(fromNative, expected, reason: 'native');
      expect(fromWasm, expected, reason: 'wasm32');
    } finally {
      native.free();
    }
  });
}

void main() {
  final tree = <String, Object?>{
    'title': 'Ünïcode',
    'n': 42,
    'flag': true,
    'gain': -3.5,
    'list': ['a', 7],
    'bytes': Uint8List.fromList([1, 2, 255]),
  };
  final plainTree = _plain(tree);

  group('property change', () {
    _same(
      'a double',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(
          h,
          'volume',
          MpvFormat.mpvFormatDouble,
          _scalar(h, MpvFormat.mpvFormatDouble, 80.5),
        ),
      ),
      {
        'property': 'volume',
        'format': MpvFormat.mpvFormatDouble,
        'value': 80.5,
      },
    );
    _same(
      'a flag, as an int',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(
          h,
          'pause',
          MpvFormat.mpvFormatFlag,
          _scalar(h, MpvFormat.mpvFormatFlag, 1),
        ),
      ),
      {'property': 'pause', 'format': MpvFormat.mpvFormatFlag, 'value': 1},
    );
    _same(
      'an int64',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(
          h,
          'playlist-pos',
          MpvFormat.mpvFormatInt64,
          _scalar(h, MpvFormat.mpvFormatInt64, 1 << 40),
        ),
      ),
      {
        'property': 'playlist-pos',
        'format': MpvFormat.mpvFormatInt64,
        'value': 1 << 40,
      },
    );
    _same(
      'a string',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(
          h,
          'media-title',
          MpvFormat.mpvFormatString,
          _scalar(h, MpvFormat.mpvFormatString, 'Café'),
        ),
      ),
      {
        'property': 'media-title',
        'format': MpvFormat.mpvFormatString,
        'value': 'Café',
      },
    );
    _same(
      'a node tree, its bytes copied',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(h, 'metadata', MpvFormat.mpvFormatNode, _node(h, tree)),
      ),
      {
        'property': 'metadata',
        'format': MpvFormat.mpvFormatNode,
        'value': plainTree,
      },
    );
    _same(
      'no value is unavailable',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(h, 'duration', MpvFormat.mpvFormatNone, 0),
      ),
      {
        'property': 'duration',
        'format': MpvFormat.mpvFormatNone,
        'value': kPropertyUnavailable,
      },
    );
    _same(
      'a format the player never observes',
      (h) => _event(
        h,
        MpvEventId.mpvEventPropertyChange,
        data: _property(
          h,
          'osd',
          MpvFormat.mpvFormatOsdString,
          _scalar(h, MpvFormat.mpvFormatString, 'x'),
        ),
      ),
      {
        'property': 'osd',
        'format': MpvFormat.mpvFormatOsdString,
        'value': kPropertyUnobserved,
      },
    );
  });

  group('file boundaries', () {
    _same('START_FILE', (h) {
      final d = h.alloc(8);
      h.i64(d, 17);
      return _event(h, MpvEventId.mpvEventStartFile, data: d);
    }, {'start-file': 17});

    int endFile(_Heap h, {double duration = 180.5, double position = 179.25}) {
      final d = h.alloc(56);
      h.i32(d, MpvEndFileReason.mpvEndFileReasonEof);
      h.i32(d + 4, 0);
      h.i64(d + 8, 8);
      h.i32(d + 28, 1);
      h.i64(d + 32, 2);
      h.f64(d + 40, duration);
      h.f64(d + 48, position);
      return _event(h, MpvEventId.mpvEventEndFile, data: d);
    }

    _same('END_FILE with the four fields of read_error', endFile, {
      'end-file': 8,
      'reason': MpvEndFileReason.mpvEndFileReasonEof,
      'error': 0,
      'readError': true,
      'skippedSegments': 2,
      'duration': 180.5,
      'position': 179.25,
    });
    _same(
      'a duration or position mpv did not know is null',
      (h) => endFile(h, duration: -1, position: -1),
      {
        'end-file': 8,
        'reason': MpvEndFileReason.mpvEndFileReasonEof,
        'error': 0,
        'readError': true,
        'skippedSegments': 2,
        'duration': null,
        'position': null,
      },
    );
    _same(
      'FILE_LOADED',
      (h) => _event(h, MpvEventId.mpvEventFileLoaded),
      'file-loaded',
    );
    _same(
      'PLAYBACK_RESTART',
      (h) => _event(h, MpvEventId.mpvEventPlaybackRestart),
      'playback-restart',
    );
    _same(
      'SHUTDOWN',
      (h) => _event(h, MpvEventId.mpvEventShutdown),
      'shutdown',
    );
    _same(
      'AUDIO_RECONFIG',
      (h) => _event(h, MpvEventId.mpvEventAudioReconfig),
      'audio-reconfig',
    );
  });

  group('replies', () {
    _same(
      'a set reply',
      (h) => _event(h, MpvEventId.mpvEventSetPropertyReply, userdata: 9),
      {'reply': 9, 'error': 0, 'result': null},
    );
    _same(
      'a command reply with its node',
      (h) => _event(
        h,
        MpvEventId.mpvEventCommandReply,
        userdata: 10,
        data: _node(h, {'playlist_entry_id': 3}),
      ),
      {
        'reply': 10,
        'error': 0,
        'result': {'playlist_entry_id': 3},
      },
    );
    _same(
      'a refused command carries no result',
      (h) => _event(
        h,
        MpvEventId.mpvEventCommandReply,
        userdata: 11,
        error: MpvError.mpvErrorCommand,
        data: _node(h, 'ignored'),
      ),
      {'reply': 11, 'error': MpvError.mpvErrorCommand, 'result': null},
    );
    _same(
      'a get reply with a node of bytes',
      (h) => _event(
        h,
        MpvEventId.mpvEventGetPropertyReply,
        userdata: 12,
        data: _property(h, 'mak-pcm', MpvFormat.mpvFormatNode, _node(h, tree)),
      ),
      {'get-reply': 12, 'error': 0, 'value': plainTree},
    );
    _same(
      'a get reply without data is null',
      (h) => _event(
        h,
        MpvEventId.mpvEventGetPropertyReply,
        userdata: 13,
        data: _property(h, 'path', MpvFormat.mpvFormatString, 0),
      ),
      {'get-reply': 13, 'error': 0, 'value': null},
    );
    _same(
      'a refused get is null',
      (h) => _event(
        h,
        MpvEventId.mpvEventGetPropertyReply,
        userdata: 14,
        error: MpvError.mpvErrorPropertyUnavailable,
      ),
      {
        'get-reply': 14,
        'error': MpvError.mpvErrorPropertyUnavailable,
        'value': null,
      },
    );
  });

  group('log and hooks', () {
    _same('a log message, trimmed at its end', (h) {
      final p = h.pointerSize;
      final d = h.alloc(4 * p);
      h.pointer(d, h.cString('ffmpeg'));
      h.pointer(d + p, h.cString('warn'));
      h.pointer(d + 2 * p, h.cString('a line\n'));
      h.i32(d + 3 * p, 30);
      return _event(h, MpvEventId.mpvEventLogMessage, data: d);
    }, {'log': 'a line', 'prefix': 'ffmpeg', 'level': 'warn'});
    _same('a hook', (h) {
      final d = h.alloc(16);
      h.pointer(d, h.cString('on_load'));
      h.i64(d + 8, 77);
      return _event(h, MpvEventId.mpvEventHook, data: d);
    }, {'hook': 'on_load', 'id': 77});
    _same(
      'an event the player does not take is null',
      (h) => _event(h, MpvEventId.mpvEventIdle),
      null,
    );
  });
}
