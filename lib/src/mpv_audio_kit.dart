// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:mpv_audio_kit/src/utils/native_reference_holder.dart';

abstract class MpvAudioKit {
  static bool _initialized = false;

  /// Initializes the native backend for `mpv_audio_kit`.
  /// Must be called before creating any [Player] instances.
  /// 
  /// This takes care of cleaning up any orphaned `libmpv` Native resources 
  /// (e.g., handles that leaked across a Flutter Hot-Restart).
  static void ensureInitialized({String? libmpv}) {
    if (_initialized) return;

    NativeReferenceHolder.instance.ensureInitialized((references) {
      if (references.isEmpty) return;
      
      const tag = 'mpv_audio_kit: NativeReferenceHolder:';
      debugPrint('$tag Found ${references.length} orphaned reference(s).');
      debugPrint('$tag Disposing over-leaked native pointers (Hot-Restart fix):');
      
      // Load mpv library
      final lib = MpvLibrary.open();
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

    _initialized = true;
  }
}
