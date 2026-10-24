// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The live PCM input of the bundled libmpv (the `mak-pcm://` stream and its
// `mak_pcm_*` C API, a mpv_audio_kit patch). Every call takes a mutex for a
// moment and never waits on the reader, so all of them are leaf calls.
@DefaultAsset('package:mpv_audio_kit/libmpv')
library;

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../internals/library_loader.dart';

/// The native side of a `PcmSource`: one byte FIFO per id, read by mpv
/// through `mak-pcm://<id>`. Negative returns are the codes below.
@internal
abstract interface class PcmNative {
  /// Unknown id.
  static const int errUnknown = -1;

  /// Invalid argument.
  static const int errInvalid = -2;

  /// The source is finished, aborted or released.
  static const int errClosed = -3;

  /// Out of memory.
  static const int errNoMemory = -4;

  // Native state codes of [state].

  /// The source is open and no reader has opened it yet.
  static const int stateOpen = 0;

  /// A reader opened the source.
  static const int stateReading = 1;

  /// [finish] was called; the reader may still be draining.
  static const int stateFinished = 2;

  /// The reader saw the end.
  static const int stateDrained = 3;

  /// [abort] was called.
  static const int stateAborted = 4;

  /// The reader closed before the end (stop, next, dispose).
  static const int stateReaderClosed = 5;

  /// A new source with a soft cap of [capacityBytes]; the id or an error.
  int create(int capacityBytes);

  /// Copies up to the free space of [data]; the bytes taken or an error.
  int write(int id, Uint8List data);

  /// Ends the input: the reader plays what is buffered, then sees the end.
  int finish(int id);

  /// Drops the buffer and ends the reader at once.
  int abort(int id);

  /// Bytes waiting in the FIFO.
  int buffered(int id);

  /// Bytes the reader has taken so far.
  int consumed(int id);

  /// One of the state codes above, or an error.
  int state(int id);

  /// The app side lets go; freed once the reader closed too.
  int release(int id);

  /// Aborts and releases every source in the process.
  void releaseAll();
}

/// The [PcmNative] of the libmpv the players use: the bundled one, or the
/// library at [MpvAudioKit.libraryPath].
///
/// Throws [UnsupportedError] when that libmpv has no live PCM input (a
/// custom build without the mpv_audio_kit patches).
@internal
PcmNative pcmNative() {
  final override = debugPcmNativeOverride;
  if (override != null) return override;
  // The sources live in the library the players use, which
  // ensureInitialized chooses: before it, a source could land in another.
  if (!MpvAudioKit.isInitialized) {
    throw StateError(
      'Call MpvAudioKit.ensureInitialized() before creating a PcmSource.',
    );
  }
  return _native ??= _open(MpvAudioKit.libraryPath);
}

/// Test-only: replaces the native layer of every new `PcmSource`.
@visibleForTesting
PcmNative? debugPcmNativeOverride;

PcmNative? _native;

PcmNative _open(String? path) {
  try {
    if (path == null) {
      // @Native symbols resolve on first use: resolve one now, so a libmpv
      // without the patch fails here with a useful message.
      Native.addressOf<NativeFunction<Int64 Function(Int64)>>(_create);
      return const _BundledPcmNative();
    }
    return _LookupPcmNative(DynamicLibrary.open(path));
  } catch (e) {
    throw UnsupportedError(
      'This libmpv has no live PCM input (mak_pcm_create): $e. '
      'It comes with the libmpv release mpv_audio_kit bundles.',
    );
  }
}

final class _BundledPcmNative implements PcmNative {
  const _BundledPcmNative();

  @override
  int create(int capacityBytes) => _create(capacityBytes);

  @override
  int write(int id, Uint8List data) => _write(id, data.address, data.length);

  @override
  int finish(int id) => _finish(id);

  @override
  int abort(int id) => _abort(id);

  @override
  int buffered(int id) => _buffered(id);

  @override
  int consumed(int id) => _consumed(id);

  @override
  int state(int id) => _state(id);

  @override
  int release(int id) => _release(id);

  @override
  void releaseAll() => _releaseAll();
}

final class _LookupPcmNative implements PcmNative {
  _LookupPcmNative(DynamicLibrary lib)
    : _c = lib.lookupFunction<Int64 Function(Int64), int Function(int)>(
        'mak_pcm_create',
        isLeaf: true,
      ),
      _w = lib
          .lookupFunction<
            Int64 Function(Int64, Pointer<Uint8>, Int64),
            int Function(int, Pointer<Uint8>, int)
          >('mak_pcm_write', isLeaf: true),
      _f = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_finish',
        isLeaf: true,
      ),
      _a = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_abort',
        isLeaf: true,
      ),
      _b = lib.lookupFunction<Int64 Function(Int64), int Function(int)>(
        'mak_pcm_buffered',
        isLeaf: true,
      ),
      _n = lib.lookupFunction<Int64 Function(Int64), int Function(int)>(
        'mak_pcm_consumed',
        isLeaf: true,
      ),
      _s = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_state',
        isLeaf: true,
      ),
      _r = lib.lookupFunction<Int32 Function(Int64), int Function(int)>(
        'mak_pcm_release',
        isLeaf: true,
      ),
      _all = lib.lookupFunction<Void Function(), void Function()>(
        'mak_pcm_release_all',
        isLeaf: true,
      );

  final int Function(int) _c;
  final int Function(int, Pointer<Uint8>, int) _w;
  final int Function(int) _f;
  final int Function(int) _a;
  final int Function(int) _b;
  final int Function(int) _n;
  final int Function(int) _s;
  final int Function(int) _r;
  final void Function() _all;

  @override
  int create(int capacityBytes) => _c(capacityBytes);

  // The typed-data address only reaches @Native leaf calls, so this path
  // copies through a native buffer for the call.
  @override
  int write(int id, Uint8List data) {
    if (data.isEmpty) return 0;
    final buffer = malloc<Uint8>(data.length);
    try {
      buffer.asTypedList(data.length).setAll(0, data);
      return _w(id, buffer, data.length);
    } finally {
      malloc.free(buffer);
    }
  }

  @override
  int finish(int id) => _f(id);

  @override
  int abort(int id) => _a(id);

  @override
  int buffered(int id) => _b(id);

  @override
  int consumed(int id) => _n(id);

  @override
  int state(int id) => _s(id);

  @override
  int release(int id) => _r(id);

  @override
  void releaseAll() => _all();
}

@Native<Int64 Function(Int64)>(symbol: 'mak_pcm_create', isLeaf: true)
external int _create(int capacityBytes);

@Native<Int64 Function(Int64, Pointer<Uint8>, Int64)>(
  symbol: 'mak_pcm_write',
  isLeaf: true,
)
external int _write(int id, Pointer<Uint8> data, int len);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_finish', isLeaf: true)
external int _finish(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_abort', isLeaf: true)
external int _abort(int id);

@Native<Int64 Function(Int64)>(symbol: 'mak_pcm_buffered', isLeaf: true)
external int _buffered(int id);

@Native<Int64 Function(Int64)>(symbol: 'mak_pcm_consumed', isLeaf: true)
external int _consumed(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_state', isLeaf: true)
external int _state(int id);

@Native<Int32 Function(Int64)>(symbol: 'mak_pcm_release', isLeaf: true)
external int _release(int id);

@Native<Void Function()>(symbol: 'mak_pcm_release_all', isLeaf: true)
external void _releaseAll();
