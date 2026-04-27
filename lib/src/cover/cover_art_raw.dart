// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Raw cover-art payload extracted from mpv via `screenshot-raw video`.
///
/// Surfaced on `Player.stream.coverArtRaw` for consumers that want to do
/// their own image processing (resize, format conversion, color-space
/// adjustment, …) instead of the library's default 800px BGRA → PNG path.
///
/// Pixel format is mpv's `bgra8888`. The buffer may have row stride padding
/// — always honour [stride] when iterating row-by-row, do not assume
/// `stride == width * 4`.
class CoverArtRaw {
  const CoverArtRaw({
    required this.bytes,
    required this.width,
    required this.height,
    required this.stride,
  });

  /// Raw pixel buffer. Length is `stride * height` bytes.
  final Uint8List bytes;

  /// Image width in pixels.
  final int width;

  /// Image height in pixels.
  final int height;

  /// Row stride in bytes — ≥ `width * 4` and possibly larger if mpv
  /// over-aligned the buffer for SIMD writes.
  final int stride;

  /// Whether the buffer is densely packed (no row padding).
  bool get isContiguous => stride == width * 4;
}
