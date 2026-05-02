// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'compressor_settings.freezed.dart';

/// Dynamic-range compressor config (libavfilter `acompressor`).
///
/// Reduces the gap between loud and quiet passages. Useful for spoken
/// content and crowded mixes. [enabled] toggles the filter in the chain;
/// the parameters are preserved while disabled.
///
/// Apply via [Player.setCompressor]. Read live via
/// [PlayerStream.compressor] or [PlayerState.compressor].
@freezed
abstract class CompressorSettings with _$CompressorSettings {
  const factory CompressorSettings({
    /// Whether the stage is inserted into mpv's filter chain. Disabling
    /// preserves the configuration.
    @Default(false) bool enabled,

    /// Onset level above which compression kicks in, in dB. Hard range
    /// -60 to 0 dB (FFmpeg `acompressor` accepts linear amplitudes
    /// 0.000976563–1; mpv converts the dB form before forwarding).
    /// Typical sweet spot: -40 to -10 dB.
    @Default(-20.0) double threshold,

    /// Compression ratio above [threshold] (e.g. 4.0 means 4:1). Hard
    /// range 1.0 (no compression) to 20.0 (limiter).
    @Default(4.0) double ratio,

    /// Time the compressor takes to engage once the signal exceeds
    /// [threshold]. Hard range 0.01–2000 ms. Lower = snappier transient
    /// response.
    @Default(Duration(milliseconds: 20)) Duration attack,

    /// Time the compressor takes to disengage once the signal falls
    /// below [threshold]. Hard range 0.01–9000 ms. Lower = pumpier;
    /// higher = smoother.
    @Default(Duration(milliseconds: 250)) Duration release,
  }) = _CompressorSettings;
}
