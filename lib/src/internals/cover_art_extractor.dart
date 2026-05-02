// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import '../mpv_bindings.dart';
import '../models/cover_art_raw.dart';

/// Pure-FFI helper that captures the embedded cover art of the
/// currently loaded file as a [CoverArtRaw] (codec bytes + MIME type).
///
/// Stateless: the player owns the mpv handle and decides when to call
/// [capture] (typically right after `MPV_EVENT_FILE_LOADED`).
abstract final class CoverArtExtractor {
  CoverArtExtractor._();

  /// Reads the bytes of the file's embedded cover art via the
  /// `embedded-cover-art-data` and `embedded-cover-art-mime` mpv
  /// properties. Returns `null` when the loaded file has no embedded
  /// cover.
  ///
  /// The returned bytes are the original PNG / JPEG / … as embedded —
  /// no decode, no pixel format conversion.
  static CoverArtRaw? capture(
    MpvLibrary lib,
    Pointer<MpvHandle> handle,
  ) {
    final result = calloc<MpvNode>();
    try {
      return using<CoverArtRaw?>((arena) {
        final propName =
            'embedded-cover-art-data'.toNativeUtf8(allocator: arena);
        final rc = lib.mpvGetProperty(
            handle, propName, MpvFormat.mpvFormatNode, result.cast());
        if (rc < 0) return null;
        if (result.ref.format != MpvFormat.mpvFormatByteArray) return null;
        final ba = result.ref.u.ba.ref;
        if (ba.size <= 0) return null;
        // Copy out of mpv-owned memory before mpvFreeNodeContents
        // releases it in the outer `finally`.
        final bytes =
            Uint8List.fromList(ba.data.cast<Uint8>().asTypedList(ba.size));
        final mime = _getPropString(lib, handle, 'embedded-cover-art-mime') ??
            'application/octet-stream';
        return CoverArtRaw(bytes: bytes, mimeType: mime);
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
