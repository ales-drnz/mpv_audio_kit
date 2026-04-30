// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_params.freezed.dart';

/// Audio format parameters as reported by the mpv audio output pipeline.
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

    /// The codec identifier (e.g. `"flac"`, `"mp3"`).
    String? codec,

    /// Descriptive codec name (e.g. `"FLAC (Free Lossless Audio Codec)"`).
    String? codecName,
  }) = _AudioParams;
}
