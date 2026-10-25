// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The libmpv module in WebAssembly (libmpv.mjs and libmpv.wasm, built by
// libmpv-scripts with Emscripten) seen from Dart: the exported C functions,
// the memory, and the decoding of the client API structs at their wasm32
// offsets. Pointers are wasm32 addresses, plain ints; the 64-bit arguments
// (reply ids, hook ids, PCM ids) cross as JavaScript BigInts.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '../../mpv_constants.dart';
import 'web_layout.dart';

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

/// Test-only: gets the name of each call of [timedCall] before it runs.
@visibleForTesting
void Function(String name)? debugWebCallTrace;

/// Runs [body], the call [name] of the module, and records its length in
/// [webCallMaxMicros].
@internal
T timedCall<T>(String name, T Function() body) {
  debugWebCallTrace?.call(name);
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
  @JS('_mak_web_abi_version')
  external int abiVersion();
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
  @JS('_mpv_command_string')
  external int mpvCommandString(int ctx, int args);
  @JS('_mak_webio_live_streams')
  external int webioLiveStreams();
  @JS('UTF8ToString')
  external JSString utf8ToString(int pointer);
  @JS('stringToNewUTF8')
  external int stringToNewUtf8(JSString value);
  external JSObject get wasmMemory;
  external MakWebAudio get makWebAudio;
}

/// `Module.makWebAudio` of the module (scripts/web/mak_webaudio.js of
/// libmpv-scripts): the AudioContext the webaudio output plays into, its
/// AudioWorklet, and the resume at the first user gesture.
@internal
extension type MakWebAudio._(JSObject _) implements JSObject {
  /// Makes the AudioContext and loads the worklet; a second call replaces
  /// the context, and every open output reopens on the new one.
  external JSPromise<JSObject> init([JSObject? options]);

  /// Resumes the context, which the autoplay policy starts suspended.
  external JSPromise<JSAny?> resume();

  /// Closes the context: open outputs fail until the next [init].
  external JSPromise<JSAny?> close();

  /// Calls [listener] with the context's state at each change; returns the
  /// function that removes it.
  external JSFunction onStateChange(JSFunction listener);

  /// `none` before [init], then the AudioContext's state.
  external String get state;

  /// The AudioWorkletNode of output [id], made on first use.
  external JSObject output([int id]);

  /// The AudioContext, `null` before [init].
  external JSObject? get context;
}

/// One instance of the libmpv module: its exports, its memory, and the
/// wakeup bridge that calls back into Dart.
@internal
final class MpvModule {
  /// Wraps the instance [module] the module factory resolved with, after
  /// checking its ABI version and its struct layout against the ones the
  /// decoders assume, before any other call into it. [processorUrl] is
  /// where the webaudio output's worklet is, when not beside the module.
  MpvModule(JSObject module, {this.processorUrl})
    : instance = module,
      _m = MpvExports._(module) {
    checkWebModuleAbi(_m.has('_mak_web_abi_version') ? _m.abiVersion() : null);
    endFile = checkWebLayout(_layoutTable());
    // One callback per module: mak_web.c posts it to the main thread, at
    // most once per handle until it runs, whenever mpv wakes that client.
    // Emscripten also runs that posted work while the main thread waits for
    // a lock inside a call of the module (a busy wait that "assists" the
    // other threads), so the callback can come in the middle of a drain or
    // a read. It only schedules the work, which runs once the call that was
    // waiting has returned.
    _m['onMpvWakeup'] = ((JSNumber handle) {
      final h = handle.toDartInt;
      if (!_wakeups.containsKey(h) || !_scheduled.add(h)) return;
      scheduleMicrotask(() {
        _scheduled.remove(h);
        _wakeups[h]?.call();
      });
    }).toJS;
  }

  /// The module instance, as the factory resolved it.
  final JSObject instance;

  /// Where mak_webaudio_processor.js is, when not beside libmpv.mjs.
  final String? processorUrl;

  final MpvExports _m;
  final Map<int, void Function()> _wakeups = {};
  final Set<int> _scheduled = {};

  /// The exported C functions.
  MpvExports get c => _m;

  /// Where `mpv_event_end_file` keeps the read error fields of the
  /// read_error patch, `0` and `0` in a module without it.
  late final EndFileFields endFile;

  /// The module's `mak_web_layout()`, up to its `-1` end.
  List<int> _layoutTable() {
    final table = _m.layout();
    final view = _view();
    final values = <int>[];
    for (var i = 0; i < 64; i++) {
      final v = view.getInt32(table + 4 * i, true);
      if (v < 0) break;
      values.add(v);
    }
    return values;
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
/// is where libmpv.wasm is, and [processorUrl] where
/// mak_webaudio_processor.js is, when not beside [url].
@internal
Future<MpvModule> loadMpvModule(
  String url, {
  String? wasmUrl,
  String? processorUrl,
}) async {
  final namespace = await importModule(url.toJS).toDart;
  final factory = namespace['default'] as JSFunction;
  final options = JSObject();
  if (wasmUrl != null) {
    options['locateFile'] = ((JSString path) => wasmUrl.toJS).toJS;
  }
  final instance =
      await (factory.callAsFunction(null, options) as JSPromise).toDart;
  return MpvModule(instance as JSObject, processorUrl: processorUrl);
}
