// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The libmpv module in WebAssembly (libmpv.mjs and libmpv.wasm, built by
// libmpv-scripts with Emscripten) seen from Dart: the exported C functions,
// the memory, and the decoding of the client API structs at their wasm32
// offsets. Pointers are wasm32 addresses, plain ints; the 64-bit arguments
// (reply ids, hook ids, PCM ids) cross as JavaScript BigInts.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../mpv_constants.dart';

@JS('BigInt')
external JSBigInt _bigInt(JSNumber value);

@JS('Number')
external JSNumber _number(JSBigInt value);

/// [value] as a JavaScript BigInt, for a 64-bit argument.
@internal
JSBigInt bigInt(int value) => _bigInt(value.toJS);

/// The BigInt [value] of a 64-bit result as an int (exact below 2^53).
@internal
int bigIntValue(JSBigInt value) => _number(value).toDartInt;

/// The longest run so far of each call that waits for the core on the
/// main thread (`mpv_initialize`, `mpv_hook_add`, `mpv_hook_continue`,
/// `mpv_terminate_destroy` and the like), in microseconds, by C name: the
/// measure behind running them there rather than on a service thread.
@visibleForTesting
final Map<String, int> webCallMaxMicros = {};

/// Runs [body], the call [name] of the module, and records its length in
/// [webCallMaxMicros].
@internal
T timedCall<T>(String name, T Function() body) {
  final clock = Stopwatch()..start();
  try {
    return body();
  } finally {
    final micros = clock.elapsedMicroseconds;
    if (micros > (webCallMaxMicros[name] ?? -1)) {
      webCallMaxMicros[name] = micros;
    }
  }
}

/// The `struct` offsets of the client API on wasm32, in the order of
/// `mak_web_layout()` (scripts/web/mak_web.c of libmpv-scripts): sizeof and
/// offsetof of mpv_node, mpv_node_list, mpv_byte_array, mpv_event,
/// mpv_event_property, mpv_event_log_message, mpv_event_end_file and
/// mpv_event_hook. The decoders below use these numbers; the module's own
/// table is compared with it when the module loads.
const List<int> _kLayout = [
  16, 8, // mpv_node: size, format
  12, 4, 8, // mpv_node_list: size, values, keys
  8, 4, // mpv_byte_array: size, size field
  24, 4, 8, 16, // mpv_event: size, error, reply_userdata, data
  12, 4, 8, // mpv_event_property: size, format, data
  16, 8, 12, // mpv_event_log_message: size, text, log_level
  32, 4, 8, 16, 24, // mpv_event_end_file
  16, 8, // mpv_event_hook: size, id
];

@JS('DataView')
extension type _View._(JSObject _) implements JSObject {
  external _View(JSObject buffer);
  external int getInt32(int byteOffset, bool littleEndian);
  external int getUint32(int byteOffset, bool littleEndian);
  external double getFloat64(int byteOffset, bool littleEndian);
  external void setInt32(int byteOffset, int value, bool littleEndian);
  external void setUint32(int byteOffset, int value, bool littleEndian);
  external void setFloat64(int byteOffset, double value, bool littleEndian);
}

@JS('Uint8Array')
extension type _Bytes._(JSObject _) implements JSObject {
  external _Bytes(JSObject buffer, int byteOffset, int length);
  external JSUint8Array slice();
  external void set(JSUint8Array source, int offset);
}

/// The exported C functions and runtime helpers of the module, by their
/// Emscripten names.
@internal
extension type MpvExports._(JSObject _) implements JSObject {
  @JS('_mpv_create')
  external int mpvCreate();
  @JS('_mpv_create_client')
  external int mpvCreateClient(int ctx, int name);
  @JS('_mpv_initialize')
  external int mpvInitialize(int ctx);
  @JS('_mpv_terminate_destroy')
  external void mpvTerminateDestroy(int ctx);
  @JS('_mpv_destroy')
  external void mpvDestroy(int ctx);
  @JS('_mpv_set_option_string')
  external int mpvSetOptionString(int ctx, int name, int value);
  @JS('_mpv_set_property_string')
  external int mpvSetPropertyString(int ctx, int name, int value);
  @JS('_mpv_request_log_messages')
  external int mpvRequestLogMessages(int ctx, int level);
  @JS('_mpv_request_event')
  external int mpvRequestEvent(int ctx, int event, int enable);
  @JS('_mpv_observe_property')
  external int mpvObserveProperty(int ctx, JSBigInt id, int name, int format);
  @JS('_mpv_wait_event')
  external int mpvWaitEvent(int ctx, double timeout);
  @JS('_mpv_set_property_async')
  external int mpvSetPropertyAsync(
    int ctx,
    JSBigInt id,
    int name,
    int format,
    int data,
  );
  @JS('_mpv_get_property_async')
  external int mpvGetPropertyAsync(int ctx, JSBigInt id, int name, int format);
  @JS('_mpv_command_async')
  external int mpvCommandAsync(int ctx, JSBigInt id, int args);
  @JS('_mpv_hook_add')
  external int mpvHookAdd(int ctx, JSBigInt id, int name, int priority);
  @JS('_mpv_hook_continue')
  external int mpvHookContinue(int ctx, JSBigInt id);
  @JS('_mpv_error_string')
  external int mpvErrorString(int error);
  @JS('_mpv_wakeup')
  external void mpvWakeup(int ctx);
  @JS('_mak_web_wakeup_attach')
  external int wakeupAttach(int ctx);
  @JS('_mak_web_wakeup_detach')
  external void wakeupDetach(int bridge);
  @JS('_mak_web_layout')
  external int layout();
  @JS('_malloc')
  external int malloc(int size);
  @JS('_free')
  external void free(int pointer);
  @JS('_mak_pcm_create')
  external JSBigInt pcmCreate(JSBigInt capacity);
  @JS('_mak_pcm_write')
  external JSBigInt pcmWrite(JSBigInt id, int data, JSBigInt length);
  @JS('_mak_pcm_finish')
  external int pcmFinish(JSBigInt id);
  @JS('_mak_pcm_abort')
  external int pcmAbort(JSBigInt id);
  @JS('_mak_pcm_buffered')
  external JSBigInt pcmBuffered(JSBigInt id);
  @JS('_mak_pcm_consumed')
  external JSBigInt pcmConsumed(JSBigInt id);
  @JS('_mak_pcm_state')
  external int pcmState(JSBigInt id);
  @JS('_mak_pcm_release')
  external int pcmRelease(JSBigInt id);
  @JS('_mak_pcm_release_all')
  external void pcmReleaseAll();
  @JS('UTF8ToString')
  external JSString utf8ToString(int pointer);
  @JS('stringToNewUTF8')
  external int stringToNewUtf8(JSString value);
  external JSObject get wasmMemory;
}

/// One instance of the libmpv module: its exports, its memory, and the
/// wakeup bridge that calls back into Dart.
@internal
final class MpvModule {
  /// Wraps the instance [module] the module factory resolved with, after
  /// checking its struct layout against the one the decoders assume.
  MpvModule(JSObject module) : _m = MpvExports._(module) {
    _checkLayout();
    // One callback per module: mak_web.c posts it to the main thread, at
    // most once per handle until it runs, whenever mpv wakes that client.
    _m['onMpvWakeup'] = ((JSNumber handle) {
      _wakeups[handle.toDartInt]?.call();
    }).toJS;
  }

  final MpvExports _m;
  final Map<int, void Function()> _wakeups = {};

  /// The exported C functions.
  MpvExports get c => _m;

  void _checkLayout() {
    final table = _m.layout();
    final view = _view();
    final got = <int>[];
    for (var i = 0; i < 64; i++) {
      final v = view.getInt32(table + 4 * i, true);
      if (v < 0) break;
      got.add(v);
    }
    if (got.length != _kLayout.length) {
      throw StateError('mpv_audio_kit: the web module has another layout');
    }
    for (var i = 0; i < got.length; i++) {
      if (got[i] != _kLayout[i]) {
        throw StateError('mpv_audio_kit: the web module has another layout');
      }
    }
  }

  /// Calls [onWakeup] on the main thread whenever mpv wakes client
  /// [handle], until [detachWakeup]. Returns the bridge.
  int attachWakeup(int handle, void Function() onWakeup) {
    _wakeups[handle] = onWakeup;
    return _m.wakeupAttach(handle);
  }

  /// Stops the wakeups of [handle] through [bridge].
  void detachWakeup(int handle, int bridge) {
    _wakeups.remove(handle);
    _m.wakeupDetach(bridge);
  }

  // The memory can grow, which replaces the buffer: a view is made for
  // each use, never kept.
  _View _view() => _View(_m.wasmMemory['buffer'] as JSObject);

  /// The signed 32-bit value at [p].
  int i32(int p) => _view().getInt32(p, true);

  /// The unsigned 32-bit value at [p] (a pointer, a size_t).
  int u32(int p) => _view().getUint32(p, true);

  /// The signed 64-bit value at [p] (exact below 2^53).
  int i64(int p) {
    final view = _view();
    return view.getInt32(p + 4, true) * 4294967296 + view.getUint32(p, true);
  }

  /// The double at [p].
  double f64(int p) => _view().getFloat64(p, true);

  /// The NUL-terminated string at [p], malformed UTF-8 replaced with
  /// U+FFFD as on the native side; `null` for a null pointer.
  String? string(int p) => p == 0 ? null : _m.utf8ToString(p).toDart;

  /// A copy of the [length] bytes at [p].
  Uint8List bytes(int p, int length) {
    if (length <= 0) return Uint8List(0);
    final buffer = _m.wasmMemory['buffer'] as JSObject;
    return _Bytes(buffer, p, length).slice().toDart;
  }

  /// Copies [data] to the module's memory at [p].
  void writeBytes(int p, Uint8List data) {
    final buffer = _m.wasmMemory['buffer'] as JSObject;
    _Bytes(buffer, p, data.length).set(data.toJS, 0);
  }

  /// Writes the 32-bit [value] at [p].
  void setU32(int p, int value) => _view().setUint32(p, value, true);

  /// Writes the signed 32-bit [value] at [p].
  void setI32(int p, int value) => _view().setInt32(p, value, true);

  /// Writes the signed 64-bit [value] at [p] (exact below 2^53).
  void setI64(int p, int value) {
    final view = _view();
    final hi = (value / 4294967296).floor();
    view.setUint32(p, value - hi * 4294967296, true);
    view.setInt32(p + 4, hi, true);
  }

  /// Writes the double [value] at [p].
  void setF64(int p, double value) => _view().setFloat64(p, value, true);

  /// A copy of [value] in the module's memory, NUL-terminated; free it with
  /// [free].
  int newString(String value) => _m.stringToNewUtf8(value.toJS);

  /// Allocates [size] bytes of the module's memory.
  int malloc(int size) => _m.malloc(size);

  /// Frees [pointer], allocated with [malloc] or [newString].
  void free(int pointer) => _m.free(pointer);

  /// Runs [body] with [values] copied to the module's memory as strings,
  /// freed when it returns.
  T withStrings<T>(List<String> values, T Function(List<int> pointers) body) {
    final pointers = [for (final v in values) newString(v)];
    try {
      return body(pointers);
    } finally {
      for (final p in pointers) {
        free(p);
      }
    }
  }

  /// Decodes the `mpv_node` at [p]: the same Dart shapes as the native
  /// decoder, byte arrays as [Uint8List] copies.
  Object? node(int p) {
    switch (i32(p + 8)) {
      case MpvFormat.mpvFormatString:
        return string(u32(p));
      case MpvFormat.mpvFormatFlag:
        return i32(p) != 0;
      case MpvFormat.mpvFormatInt64:
        return i64(p);
      case MpvFormat.mpvFormatDouble:
        return f64(p);
      case MpvFormat.mpvFormatNodeArray:
        final list = u32(p);
        final num = i32(list);
        final values = u32(list + 4);
        return [for (var i = 0; i < num; i++) node(values + 16 * i)];
      case MpvFormat.mpvFormatNodeMap:
        final list = u32(p);
        final num = i32(list);
        final values = u32(list + 4);
        final keys = u32(list + 8);
        return <String, dynamic>{
          for (var i = 0; i < num; i++)
            string(u32(keys + 4 * i))!: node(values + 16 * i),
        };
      case MpvFormat.mpvFormatByteArray:
        final ba = u32(p);
        return bytes(u32(ba), u32(ba + 4));
      default:
        return null;
    }
  }

  /// Decodes the value of format [format] at [data], as a property change
  /// or a read carries it: a flag as an int, as the native side does.
  Object? value(int format, int data) => switch (format) {
    MpvFormat.mpvFormatDouble => f64(data),
    MpvFormat.mpvFormatFlag => i32(data),
    MpvFormat.mpvFormatInt64 => i64(data),
    MpvFormat.mpvFormatString => string(u32(data)),
    MpvFormat.mpvFormatNode => node(data),
    _ => null,
  };
}

/// Imports the module at [url] (libmpv.mjs) and instantiates it. [wasmUrl]
/// is where libmpv.wasm is, when not beside [url].
@internal
Future<MpvModule> loadMpvModule(String url, {String? wasmUrl}) async {
  final namespace = await importModule(url.toJS).toDart;
  final factory = namespace['default'] as JSFunction;
  final options = JSObject();
  if (wasmUrl != null) {
    options['locateFile'] = ((JSString path) => wasmUrl.toJS).toJS;
  }
  final instance =
      await (factory.callAsFunction(null, options) as JSPromise).toDart;
  return MpvModule(instance as JSObject);
}
