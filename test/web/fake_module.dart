// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A stand-in for an instance of the web module, for what the real one
// cannot be made to do: a malloc that returns NULL, a memory that grows on
// demand, a call that throws as an aborted module's does. It has a memory
// of its own, the ABI version and the layout table MpvModule checks, a
// malloc that never reuses an address, and every export recorded in
// [FakeModule.calls].

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

// The table of web_layout.dart, with its -1 end.
const List<int> _kLayout = [
  16, 8, 12, 4, 8, 8, 4, 24, 4, 8, 16, 12, 4, 8, 16, 8, 12, //
  56, 4, 8, 16, 24, 28, 32, 40, 48, 16, 8, -1,
];

const int _kLayoutAddress = 1024;
const int _kHeapStart = 4096;

@JS('WebAssembly.Memory')
extension type _Memory._(JSObject _) implements JSObject {
  external _Memory(JSObject descriptor);
  external JSArrayBuffer get buffer;
  external int grow(int pages);
}

/// The stand-in, see the top of the file.
final class FakeModule {
  /// A module with a memory of [pages] pages of 64 KiB.
  FakeModule({int pages = 1})
    : _memory = _Memory(JSObject()..['initial'] = pages.toJS) {
    instance['wasmMemory'] = _memory;
    final table = Int32List.sublistView(bytes, _kLayoutAddress);
    table.setAll(0, _kLayout);
    _export('_mak_web_abi_version', 0, (_) => webModuleAbi);
    _export('_mak_web_layout', 0, (_) => _kLayoutAddress);
    _export('_malloc', 1, (a) => _malloc(a[0]));
    _export('_free', 1, (a) {
      freed.add(a[0]);
      return 0;
    });
    instance['stringToNewUTF8'] = ((JSString value) {
      calls.add('stringToNewUTF8');
      final encoded = utf8.encode(value.toDart);
      final p = _malloc(encoded.length + 1);
      if (p != 0) bytes.setAll(p, [...encoded, 0]);
      return p.toJS;
    }).toJS;
    _export('_mpv_create', 0, (_) => 1);
    const arities = {
      '_mpv_set_option_string': 3,
      '_mpv_command_string': 2,
      '_mpv_destroy': 1,
      '_mpv_terminate_destroy': 1,
      '_mak_web_wakeup_attach': 1,
      '_mak_web_wakeup_detach': 1,
      '_mak_pcm_release_all': 0,
    };
    for (final MapEntry(key: name, value: arity) in arities.entries) {
      _export(name, arity, (args) {
        arguments.add((name, args));
        return 0;
      });
    }
    // The 64-bit arguments are BigInts, and so is a 64-bit result.
    instance['_mak_pcm_write'] = ((JSAny? id, JSNumber data, JSAny? length) {
      calls.add('_mak_pcm_write');
      return length;
    }).toJS;
    instance['_mpv_command_async'] = ((JSNumber ctx, JSAny? id, JSNumber a) {
      calls.add('_mpv_command_async');
      return 0.toJS;
    }).toJS;
  }

  /// The instance, as the module's factory would resolve it.
  final JSObject instance = JSObject();

  final _Memory _memory;

  /// The exports called so far, by name, in order.
  final List<String> calls = [];

  /// The mpv and mak calls so far, each with its arguments.
  final List<(String, List<int>)> arguments = [];

  /// The pointers freed so far.
  final List<int> freed = [];

  /// The pointers malloc and stringToNewUTF8 returned, the NULLs left out.
  final List<int> allocated = [];

  /// The allocations left before malloc returns NULL; `null` for no end.
  int? allocationsLeft;

  /// Whether the call of an export with these arguments throws, as every
  /// call of an aborted module does; `null` for none.
  bool Function(String name, List<int> args)? aborts;

  int _next = _kHeapStart;

  /// The memory as it is now: a growth replaces it.
  Uint8List get bytes => _memory.buffer.toDart.asUint8List();

  /// Grows the memory by [pages], which detaches the buffer it had.
  void grow(int pages) => _memory.grow(pages);

  int _malloc(int size) {
    final left = allocationsLeft;
    if (left != null) {
      if (left == 0) return 0;
      allocationsLeft = left - 1;
    }
    final p = _next;
    _next += (size + 15) & ~15;
    allocated.add(p);
    return p;
  }

  // An export of [arity] arguments, all numbers.
  void _export(String name, int arity, int Function(List<int> args) body) {
    JSNumber run(List<JSNumber> args) {
      calls.add(name);
      final values = [for (final a in args) a.toDartInt];
      if (aborts?.call(name, values) ?? false) throw StateError('Aborted()');
      return body(values).toJS;
    }

    instance[name] = switch (arity) {
      0 => (() => run([])).toJS,
      1 => ((JSNumber a) => run([a])).toJS,
      2 => ((JSNumber a, JSNumber b) => run([a, b])).toJS,
      _ => ((JSNumber a, JSNumber b, JSNumber c) => run([a, b, c])).toJS,
    };
  }
}
