// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:mpv_audio_kit/src/utils/native_reference_holder.dart';

import 'dart:ffi';
import 'dart:io';

/// Global configuration / one-time initialization for `mpv_audio_kit`.
///
/// Despite living next to `Player`, this is *not* the player itself —
/// it owns the libmpv `DynamicLibrary` lookup and the orphaned-handle
/// cleanup that fires across hot-restarts.
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
  /// `libmpv.so.2` on Linux, `libmpv.dylib` on macOS/iOS,
  /// `mpv.dll` on Windows, and the bundled JNI library on Android.
  /// Pass an explicit path only when shipping a custom libmpv build
  /// alongside your app.
  static void ensureInitialized({String? libmpv}) {
    if (_initialized) {
      return;
    }

    // Apply platform-specific fixes (e.g., LC_NUMERIC for libmpv on Linux/macOS)
    _applyPlatformQuirks();

    NativeReferenceHolder.instance.ensureInitialized((references) {
      if (references.isEmpty) {
        return;
      }

      const tag = 'mpv_audio_kit: NativeReferenceHolder:';
      debugPrint('$tag Found ${references.length} orphaned reference(s).');
      debugPrint(
          '$tag Disposing over-leaked native pointers (Hot-Restart fix):');

      // Load mpv library
      final lib = MpvLibrary.open(libmpv);
      for (final ref in references) {
        debugPrint(' - Address: ${ref.address}');
        try {
          // We can't use mpv_terminate_destroy because the handle thread might have panicked or exited improperly.
          // Sending the 'quit' command is much safer and lets MPV clean up its own context in its thread.
          final cmd = 'quit'.toNativeUtf8();
          try {
            lib.mpvCommandString(ref, cmd);
          } finally {
            calloc.free(cmd);
          }
        } catch (e) {
          debugPrint('$tag Error sending quit: $e');
        }
      }
    });

    _libraryPath = libmpv;
    _initialized = true;
  }

  /// Applies platform-specific native quirks.
  ///
  /// On Linux and macOS, mpv requires the `LC_NUMERIC` locale to be set to "C"
  /// to ensure proper parsing of floating-point numbers regardless of the
  /// user's system language settings (e.g., using a dot instead of a comma).
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
      debugPrint('mpv_audio_kit: setlocale failed: $e. '
          'mpv might fail to initialize if system locale is not compatible.');
    }
  }
}
