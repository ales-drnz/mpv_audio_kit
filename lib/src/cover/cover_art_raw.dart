// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';

/// Raw cover-art payload extracted from the currently loaded file.
///
/// [bytes] holds the original codec data (PNG / JPEG / WEBP / BMP /
/// GIF) exactly as it was embedded in the audio file's attached
/// picture stream. Consumers can hand the bytes directly to
/// `Image.memory(bytes)` or `dart:ui.instantiateImageCodec`.
class CoverArtRaw {
  const CoverArtRaw({required this.bytes, required this.mimeType});

  /// The raw file content (e.g. PNG bytes starting with `\x89PNG`).
  final Uint8List bytes;

  /// MIME type — `image/png`, `image/jpeg`, `image/webp`, `image/bmp`,
  /// or `image/gif`.
  final String mimeType;
}
