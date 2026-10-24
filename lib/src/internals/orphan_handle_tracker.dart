// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../mpv_bindings.dart';
import 'build_mode.dart';
import 'debug_log.dart';

/// Recovers libmpv handles leaked across a Flutter Hot-Restart.
///
/// Flutter replaces the Dart VM but keeps the parent process alive,
/// so handles allocated by the previous VM stay open (and block
/// exclusive-mode audio devices like WASAPI) until the process exits.
/// The tracker keeps the live handle addresses in a native buffer and
/// publishes the buffer in a variable of the process environment
/// ([envName]), with the pid. On startup the new VM finds the buffer
/// there and surfaces every still-tracked handle to the caller's
/// cleanup callback.
///
/// The environment lives and dies with the process, like the buffer:
/// a new process never sees the value of an old one, and nothing is
/// left on disk. A child process inherits the value with the pid of
/// its parent, and ignores it.
///
/// **Debug only**: guarded by [kHotRestartPossible]. Profile and
/// release builds have no Hot-Restart. An engine can still go while the
/// process stays (Android): the players of an isolate that exits are
/// stopped by `OwnerWatch`, not here.
///
/// **Single-isolate**: [add] and [remove] are not synchronized across
/// isolates that share a pid. The test suite disables the tracker
/// via `MpvAudioKit.ensureInitialized(hotRestartCleanup: false)`.
class OrphanHandleTracker {
  static const int _kBufferSize = 256;
  // Magic cookie stored alongside every address. Hot-Restart cleanup
  // verifies this before calling into libmpv with a stored address so
  // a buffer that is not ours can't trick us into invoking FFI on a
  // pointer that wasn't ours. Slots are laid out as
  // [cookie₀, addr₀, cookie₁, addr₁, …] in the underlying buffer.
  static const int _kCookie = 0x4D414B5F4D5056AB; // "MAK_MPV\xab"
  // 2 Int64 words per slot (cookie + address) on every ABI: the cookie
  // keeps its 64 bits on a 32-bit ABI (armeabi-v7a), and an address of
  // that ABI fits in the second word.
  static const int _kSlotStride = 2;

  /// The bytes of one slot, the same on every ABI.
  @visibleForTesting
  static int get slotBytes => _kSlotStride * sizeOf<Int64>();

  /// The process environment variable that holds `<pid>:<address>` of
  /// the buffer.
  @visibleForTesting
  static const String envName = 'MPV_AUDIO_KIT_ORPHAN_BUFFER';

  /// The process-wide singleton. One tracker shares the per-process leak
  /// buffer across every [Player] created in this Dart VM.
  static final OrphanHandleTracker instance = OrphanHandleTracker._(
    ProcessEnvironment.native(),
  );

  /// A tracker over [env] instead of the process environment: each one
  /// stands for one Dart VM of the process [env] belongs to.
  @visibleForTesting
  OrphanHandleTracker.forTesting(ProcessEnvironment env) : this._(env);

  OrphanHandleTracker._(this._env);

  final ProcessEnvironment _env;
  bool _initialized = false;

  // Null until [ensureInitialized] runs, and if it fails.
  Pointer<Int64>? _buffer;
  final Completer<void> _completer = Completer<void>();

  bool get _isDebug => kHotRestartPossible;

  /// Whether an earlier Dart VM of this process initialized the tracker:
  /// this VM came from a Hot-Restart. Set by [ensureInitialized].
  bool get restarted => _restarted;
  bool _restarted = false;

  /// Initializes the tracker once per Dart VM.
  ///
  /// On a fresh launch the buffer is allocated and published in the
  /// process environment; on a Hot-Restart the published buffer is
  /// reattached. Any non-zero entries in the buffer are surfaced to
  /// [onOrphanFound] for the caller to clean up.
  ///
  /// The environment is written once per process, here: before any
  /// [Player] creates an mpv core, whose threads may read it.
  void ensureInitialized(
    void Function(List<Pointer<MpvHandle>>) onOrphanFound,
  ) {
    if (!_isDebug) {
      return;
    }
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      final previous = _publishedBuffer();
      final Pointer<Int64> buffer;
      if (previous == null) {
        // Intentionally never freed: the buffer must outlive the Dart VM
        // so the next Hot-Restart can rehydrate orphan addresses from it.
        // The OS reclaims the allocation when the host process eventually
        // exits.
        buffer = calloc<Int64>(_kBufferSize * _kSlotStride);
        _buffer = buffer;
        if (!_env.set(envName, '$pid:${buffer.address}')) {
          debugLog(
            'mpv_audio_kit: OrphanHandleTracker cannot publish its buffer. '
            'Hot-restart cleanup disabled for the next restart.',
          );
        }
      } else {
        buffer = previous;
        _buffer = buffer;
        _restarted = true;
      }

      final orphans = <Pointer<MpvHandle>>[];
      for (int i = 0; i < _kBufferSize; i++) {
        final cookieRef = buffer + (i * _kSlotStride);
        final addrRef = buffer + (i * _kSlotStride + 1);
        final cookieVal = cookieRef.value;
        final refAddr = addrRef.value;
        // Skip slots that lack the magic cookie: either empty (cookie=0)
        // or filled by something other than us. This is the load-bearing
        // safety check against handing libmpv a dangling pointer.
        if (cookieVal != _kCookie) continue;
        if (refAddr != 0) {
          orphans.add(Pointer.fromAddress(refAddr));
          cookieRef.value = 0;
          addrRef.value = 0;
        }
      }

      if (orphans.isNotEmpty) {
        onOrphanFound(orphans);
      }
    } catch (e) {
      debugLog('mpv_audio_kit: OrphanHandleTracker initialization failed: $e');
    } finally {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// The buffer an earlier VM of this process published, or `null` when
  /// there is none. A value with another pid came from the parent of
  /// this process, which a child inherits: its address is not ours.
  Pointer<Int64>? _publishedBuffer() {
    final value = _env.get(envName);
    if (value == null) return null;
    final sep = value.indexOf(':');
    if (sep < 0) return null;
    final owner = int.tryParse(value.substring(0, sep));
    final address = int.tryParse(value.substring(sep + 1));
    if (owner != pid || address == null || address == 0) return null;
    return Pointer.fromAddress(address);
  }

  /// Records [handle] in the first free slot.
  ///
  /// Silently drops the handle when the buffer is full and emits a
  /// stderr warning. Hot-Restart cleanup will then miss this handle:
  /// on Windows that means a WASAPI exclusive-mode device may
  /// stay locked until the parent process terminates.
  void add(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      final buffer = _buffer;
      if (buffer == null || handle == nullptr) {
        return;
      }
      for (int i = 0; i < _kBufferSize; i++) {
        final cookieRef = buffer + (i * _kSlotStride);
        final addrRef = buffer + (i * _kSlotStride + 1);
        if (cookieRef.value == 0 && addrRef.value == 0) {
          cookieRef.value = _kCookie;
          addrRef.value = handle.address;
          return;
        }
      }
      debugLog(
        'mpv_audio_kit: OrphanHandleTracker buffer full ($_kBufferSize '
        'handles tracked). Handle ${handle.address} not registered for '
        'hot-restart cleanup: dispose Player instances before creating '
        'more.',
      );
    });
  }

  /// Clears [handle] from the buffer when [Player.dispose] runs
  /// normally: keeps the orphan list accurate so the next
  /// Hot-Restart only sees handles that actually leaked.
  void remove(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      final buffer = _buffer;
      if (buffer == null || handle == nullptr) {
        return;
      }
      _clear(buffer, handle);
    });
  }

  /// Clears [handle] from the buffer the process published, from any
  /// isolate and without [ensureInitialized]: the event isolate of a
  /// player whose owner exited frees the handle itself, and the next VM
  /// of the process must not free it again.
  void forget(Pointer<MpvHandle> handle) {
    if (!_isDebug) return;
    final buffer = _publishedBuffer();
    if (buffer != null) _clear(buffer, handle);
  }

  static void _clear(Pointer<Int64> buffer, Pointer<MpvHandle> handle) {
    for (int i = 0; i < _kBufferSize; i++) {
      final cookieRef = buffer + (i * _kSlotStride);
      final addrRef = buffer + (i * _kSlotStride + 1);
      if (cookieRef.value == _kCookie && addrRef.value == handle.address) {
        cookieRef.value = 0;
        addrRef.value = 0;
        break;
      }
    }
  }
}

/// One variable at a time of the process environment, which outlives the
/// Dart VM. Not `Platform.environment`, which only reads a copy.
@internal
abstract interface class ProcessEnvironment {
  /// Through the C library (`getenv` and `setenv`), or kernel32 on
  /// Windows.
  factory ProcessEnvironment.native() =>
      Platform.isWindows ? _Kernel32Environment() : _LibcEnvironment();

  /// The value of [name], or `null` when it is not set.
  String? get(String name);

  /// Sets [name] to [value]. Returns whether it succeeded.
  ///
  /// Not safe while another thread reads the environment (POSIX
  /// `setenv`): call it before the threads that could exist.
  bool set(String name, String value);
}

final class _LibcEnvironment implements ProcessEnvironment {
  _LibcEnvironment() : this._(_openLibc());

  _LibcEnvironment._(DynamicLibrary libc)
    : _getenv = libc
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Utf8>),
            Pointer<Utf8> Function(Pointer<Utf8>)
          >('getenv'),
      _setenv = libc
          .lookupFunction<
            Int32 Function(Pointer<Utf8>, Pointer<Utf8>, Int32),
            int Function(Pointer<Utf8>, Pointer<Utf8>, int)
          >('setenv');

  final Pointer<Utf8> Function(Pointer<Utf8>) _getenv;
  final int Function(Pointer<Utf8>, Pointer<Utf8>, int) _setenv;

  static DynamicLibrary _openLibc() => switch (Platform.operatingSystem) {
    'linux' => DynamicLibrary.open('libc.so.6'),
    'android' => DynamicLibrary.open('libc.so'),
    // macOS and iOS.
    _ => DynamicLibrary.open('libSystem.B.dylib'),
  };

  @override
  String? get(String name) => using((arena) {
    final value = _getenv(name.toNativeUtf8(allocator: arena));
    return value == nullptr ? null : value.toDartString();
  });

  @override
  bool set(String name, String value) => using(
    (arena) =>
        _setenv(
          name.toNativeUtf8(allocator: arena),
          value.toNativeUtf8(allocator: arena),
          1,
        ) ==
        0,
  );
}

final class _Kernel32Environment implements ProcessEnvironment {
  _Kernel32Environment() : this._(DynamicLibrary.open('kernel32.dll'));

  _Kernel32Environment._(DynamicLibrary kernel32)
    : _getVariable = kernel32
          .lookupFunction<
            Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32),
            int Function(Pointer<Utf16>, Pointer<Utf16>, int)
          >('GetEnvironmentVariableW'),
      _setVariable = kernel32
          .lookupFunction<
            Int32 Function(Pointer<Utf16>, Pointer<Utf16>),
            int Function(Pointer<Utf16>, Pointer<Utf16>)
          >('SetEnvironmentVariableW');

  // The values written here are `<pid>:<address>`, well under this.
  static const int _kCapacity = 128;

  final int Function(Pointer<Utf16>, Pointer<Utf16>, int) _getVariable;
  final int Function(Pointer<Utf16>, Pointer<Utf16>) _setVariable;

  @override
  String? get(String name) => using((arena) {
    final buffer = arena<Uint16>(_kCapacity).cast<Utf16>();
    final length = _getVariable(
      name.toNativeUtf16(allocator: arena),
      buffer,
      _kCapacity,
    );
    // 0: not set (or empty). Not under the capacity: not one of ours.
    if (length == 0 || length >= _kCapacity) return null;
    return buffer.toDartString(length: length);
  });

  @override
  bool set(String name, String value) => using(
    (arena) =>
        _setVariable(
          name.toNativeUtf16(allocator: arena),
          value.toNativeUtf16(allocator: arena),
        ) !=
        0,
  );
}
