// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import 'debug_log.dart';
import 'orphan_handle_tracker.dart';

/// One-time initialization for `mpv_audio_kit`. Owns the libmpv
/// `DynamicLibrary` lookup and the orphaned-handle cleanup that fires
/// across Flutter Hot-Restarts.
abstract final class MpvAudioKit {
  MpvAudioKit._();

  static bool _initialized = false;
  static String? _libraryPath;

  /// Returns the path used to initialize the library, if provided.
  static String? get libraryPath => _libraryPath;

  /// Initializes the native backend for `mpv_audio_kit`.
  /// Must be called before creating any [Player] instances.
  ///
  /// Handles cleanup of orphaned `libmpv` native resources
  /// (e.g., handles that leaked across a Flutter Hot-Restart).
  ///
  /// [libmpv] (optional) — explicit path or filename for the native
  /// `libmpv` library to load via `DynamicLibrary.open`. When `null`
  /// (the default), the platform's standard lookup is used:
  /// `libmpv.so` on Linux, `libmpv.dylib` on macOS/iOS, `libmpv.dll`
  /// on Windows, and the bundled JNI library on Android.
  /// Pass an explicit path only when shipping a custom libmpv build
  /// alongside your app.
  ///
  /// [hotRestartCleanup] (default: `true`) — recovers libmpv handles
  /// leaked across a Flutter Hot-Restart so they don't keep
  /// exclusive-mode audio devices locked. Pass `false` in test runners
  /// or other multi-VM scenarios that share a pid; the tracker would
  /// otherwise mis-attribute prior-VM handles as orphans.
  static void ensureInitialized({
    String? libmpv,
    bool hotRestartCleanup = true,
  }) {
    if (_initialized) {
      return;
    }

    _applyPlatformQuirks();

    if (!hotRestartCleanup) {
      _libraryPath = libmpv;
      _initialized = true;
      return;
    }

    OrphanHandleTracker.instance.ensureInitialized((references) {
      if (references.isEmpty) {
        return;
      }

      const tag = 'mpv_audio_kit: OrphanHandleTracker:';
      debugLog('$tag Found ${references.length} orphaned reference(s).');
      debugLog('$tag Releasing leaked handles (Hot-Restart fix):');

      final lib = MpvLibrary.open(libmpv);
      for (final ref in references) {
        debugLog(' - Address: ${ref.address}');
        try {
          // `mpv_terminate_destroy` is not safe here: the handle's
          // worker thread may have panicked or exited mid-callback in
          // the previous VM. Sending `quit` lets mpv unwind from inside
          // its own thread.
          final cmd = 'quit'.toNativeUtf8();
          try {
            lib.mpvCommandString(ref, cmd);
          } finally {
            calloc.free(cmd);
          }
        } catch (e) {
          debugLog('$tag Error sending quit: $e');
        }
      }
    });

    _libraryPath = libmpv;
    _initialized = true;
  }

  /// Applies platform-specific native quirks.
  ///
  /// Sets `LC_NUMERIC=C` on Linux and macOS so libmpv parses floats with
  /// a dot regardless of the user's locale.
  ///
  /// **Process-wide side effect.** `setlocale` affects every C library
  /// in this process — `printf("%f", ...)`, `strtod`, and any locale-
  /// aware numeric formatter will switch to the C locale. Use the
  /// `intl` package (or explicit `NumberFormat`) for user-facing
  /// numeric formatting in apps that integrate this library.
  static void _applyPlatformQuirks() {
    if (Platform.isWindows || Platform.isAndroid) {
      return;
    }

    try {
      final DynamicLibrary libc = Platform.isLinux
          ? DynamicLibrary.open('libc.so.6')
          : DynamicLibrary.open('libSystem.B.dylib');

      final setlocale = libc.lookupFunction<
          Pointer<Utf8> Function(Int32, Pointer<Utf8>),
          Pointer<Utf8> Function(int, Pointer<Utf8>)>('setlocale');

      // LC_NUMERIC = 1 on Linux/macOS
      using((arena) {
        setlocale(1, 'C'.toNativeUtf8(allocator: arena));
      });
    } catch (e) {
      debugLog('mpv_audio_kit: setlocale failed: $e. '
          'mpv might fail to initialize if system locale is not compatible.');
    }
  }
}
