// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'equalizer_config.freezed.dart';

/// Flat 10-band response — every gain at 0 dB, equivalent to no EQ.
const _kFlatGains = <double>[
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
];

/// 10-band graphic equalizer config.
///
/// Bands are at the ISO standard center frequencies: 31.25, 62.5, 125,
/// 250, 500, 1k, 2k, 4k, 8k, 16k Hz. [gains] lists per-band gain in dB
/// (positive = boost). [enabled] toggles the EQ in the filter chain;
/// [gains] are preserved while disabled so the consumer can re-enable
/// without losing slider state.
///
/// Apply via [Player.setEqualizer]. Read live via [PlayerStream.equalizer]
/// or [PlayerState.equalizer].
@freezed
abstract class EqualizerConfig with _$EqualizerConfig {
  const factory EqualizerConfig({
    @Default(false) bool enabled,
    @Default(_kFlatGains) List<double> gains,
  }) = _EqualizerConfig;

  /// All bands at 0 dB. Use as `setEqualizer(EqualizerConfig.flat)` to
  /// reset.
  static const flat = EqualizerConfig();
}
