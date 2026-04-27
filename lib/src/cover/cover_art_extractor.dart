// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import 'cover_art_raw.dart';

/// Pure-FFI helper that captures the current video frame from an mpv handle
/// as a [CoverArtRaw] (BGRA pixel buffer + dimensions + stride).
///
/// Stateless: the player owns the mpv handle and decides when to call
/// [capture] (typically right after `MPV_EVENT_FILE_LOADED`). All `dart:ui`
/// processing lives in [CoverArtProcessor] so this layer can be exercised
/// without a Flutter engine.
abstract final class CoverArtExtractor {
  CoverArtExtractor._();

  /// Captures the current video frame via mpv's `screenshot-raw video`
  /// command. Returns `null` when:
  /// - the file has no video / cover-art track (`vid == 'no' | '0'`),
  /// - mpv refuses the command,
  /// - the returned node is not a NodeMap (mpv internal error).
  ///
  /// Synchronous: the FFI call is fast enough to run on the main isolate
  /// alongside the property-change burst that follows file-loaded. The
  /// actual decode/resize work happens later in [CoverArtProcessor].
  static CoverArtRaw? capture(
    MpvLibrary lib,
    Pointer<MpvHandle> handle,
  ) {
    final vid = _getPropString(lib, handle, 'vid');
    if (vid == null || vid == 'no' || vid == '0') {
      return null;
    }

    final result = calloc<MpvNode>();
    final args = ['screenshot-raw', 'video'];

    try {
      return using<CoverArtRaw?>((arena) {
        final argPtrs = arena.allocate<Pointer<Utf8>>(
            (args.length + 1) * sizeOf<Pointer<Utf8>>());
        for (var i = 0; i < args.length; i++) {
          argPtrs[i] = args[i].toNativeUtf8(allocator: arena);
        }
        argPtrs[args.length] = nullptr;

        final res = lib.mpvCommandRet(handle, argPtrs, result);
        if (res < 0) return null;
        if (result.ref.format != MpvFormat.mpvFormatNodeMap) return null;

        int? w, h, stride;
        Uint8List? rawBytes;

        final map = result.ref.u.list;
        for (var i = 0; i < map.ref.num; i++) {
          final key = map.ref.keys[i].toDartString();
          final val = map.ref.values[i];
          switch (key) {
            case 'w' when val.format == MpvFormat.mpvFormatInt64:
              w = val.u.int64;
            case 'h' when val.format == MpvFormat.mpvFormatInt64:
              h = val.u.int64;
            case 'stride' when val.format == MpvFormat.mpvFormatInt64:
              stride = val.u.int64;
            case 'data' when val.format == MpvFormat.mpvFormatByteArray:
              // Copy out of mpv's owned buffer immediately — the buffer is
              // freed by `mpvFreeNodeContents` below and reusing it after
              // would be a use-after-free.
              rawBytes = Uint8List.fromList(val.u.ba.ref.data
                  .cast<Uint8>()
                  .asTypedList(val.u.ba.ref.size));
          }
        }

        if (w == null || h == null || stride == null || rawBytes == null) {
          return null;
        }
        return CoverArtRaw(
            bytes: rawBytes, width: w, height: h, stride: stride);
      });
    } finally {
      lib.mpvFreeNodeContents(result);
      calloc.free(result);
    }
  }

  static String? _getPropString(
      MpvLibrary lib, Pointer<MpvHandle> handle, String name) {
    return using<String?>((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final ptr = lib.mpvGetPropertyString(handle, n);
      if (ptr == nullptr) return null;
      final s = ptr.cast<Utf8>().toDartString();
      lib.mpvFree(ptr.cast());
      return s;
    });
  }
}
