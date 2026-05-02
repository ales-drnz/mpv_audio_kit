// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_params.freezed.dart';

/// Audio format parameters reported by mpv. Used both for the decoder
/// side (`audio-params` + `audio-codec*`) and for the hardware output
/// side (`audio-out-params`).
@freezed
abstract class AudioParams with _$AudioParams {
  const factory AudioParams({
    /// Sample format string (e.g. `"floatp"`, `"s16"`).
    String? format,

    /// Sample rate in Hz.
    int? sampleRate,

    /// Channel layout string in mpv notation (e.g. `"stereo"`, `"5.1"`).
    String? channels,

    /// Number of audio channels.
    int? channelCount,

    /// Human-readable channel layout description.
    String? hrChannels,

    /// Raw value of mpv's `audio-codec` property. The exact form
    /// (short id vs descriptive name) varies by mpv build and codec
    /// (`mp3` vs `mp3float`, `aac` vs `aac_lc`, `FLAC` vs
    /// `FLAC (Free Lossless Audio Codec)`); treat as an opaque hint.
    /// For reliable codec-family matching, do a case-insensitive
    /// substring check against BOTH [codec] and [codecName].
    String? codec,

    /// Raw value of mpv's `audio-codec-name` property. Same volatility
    /// caveat as [codec] — the short/descriptive split is not stable
    /// across mpv versions, and one of the two may be absent on a
    /// given file.
    String? codecName,
  }) = _AudioParams;
}
