// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'cover_art_raw.dart';

/// Async pipeline that converts a [CoverArtRaw] into a downsized PNG.
///
/// Lives in its own file so [CoverArtExtractor] can stay pure-FFI (no
/// `dart:ui` dependency) and so consumers who don't want the library's
/// default scaling can disable it via `PlayerConfiguration.processCoverArt`
/// and run their own pipeline against the raw [Stream<CoverArtRaw>].
abstract final class CoverArtProcessor {
  CoverArtProcessor._();

  /// Default max dimension (longer edge) for the resized output. Matches
  /// the historical behaviour of the in-line implementation in 0.0.x.
  static const int defaultMaxDimension = 800;

  /// Decodes [raw] (BGRA) into a [ui.Image], downscales so the longer edge
  /// is at most [maxDimension] pixels, and re-encodes to PNG.
  ///
  /// The [isCancelled] callback is consulted between every async boundary;
  /// if it returns `true`, processing aborts and `null` is returned. Use
  /// this to bail when the player is disposed mid-decode (a frequent path
  /// during rapid `open()` followed by `dispose()`).
  ///
  /// Returns `null` on cancellation or on any platform decode failure.
  static Future<Uint8List?> toPng(
    CoverArtRaw raw, {
    int maxDimension = defaultMaxDimension,
    bool Function() isCancelled = _neverCancelled,
  }) async {
    if (isCancelled()) return null;

    // 1. Re-align if stride has padding.
    final Uint8List workingBuffer = raw.isContiguous
        ? raw.bytes
        : _repackContiguous(raw);

    // 2. Force alpha to opaque (mpv uses BGR0 with the alpha byte zeroed).
    for (var i = 3; i < workingBuffer.length; i += 4) {
      workingBuffer[i] = 255;
    }
    if (isCancelled()) return null;

    final buffer = await ui.ImmutableBuffer.fromUint8List(workingBuffer);
    if (isCancelled()) {
      buffer.dispose();
      return null;
    }
    final descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: raw.width,
      height: raw.height,
      pixelFormat: ui.PixelFormat.bgra8888,
    );

    try {
      final ratio = _downscaleRatio(raw.width, raw.height, maxDimension);
      final codec = await descriptor.instantiateCodec(
        targetWidth: (raw.width * ratio).round(),
        targetHeight: (raw.height * ratio).round(),
      );
      try {
        final frame = await codec.getNextFrame();
        try {
          if (isCancelled()) return null;
          final data =
              await frame.image.toByteData(format: ui.ImageByteFormat.png);
          if (isCancelled() || data == null) return null;
          return data.buffer.asUint8List();
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } finally {
      descriptor.dispose();
    }
  }

  static Uint8List _repackContiguous(CoverArtRaw raw) {
    final out = Uint8List(raw.width * raw.height * 4);
    final rowBytes = raw.width * 4;
    for (var y = 0; y < raw.height; y++) {
      out.setRange(y * rowBytes, (y + 1) * rowBytes,
          raw.bytes.sublist(y * raw.stride, y * raw.stride + rowBytes));
    }
    return out;
  }

  static double _downscaleRatio(int width, int height, int maxDimension) {
    final longerEdge = width > height ? width : height;
    final ratio = maxDimension / longerEdge;
    return ratio > 1.0 ? 1.0 : ratio;
  }

  static bool _neverCancelled() => false;
}
