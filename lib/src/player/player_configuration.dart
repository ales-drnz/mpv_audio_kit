// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../types/enums/log_level.dart';

/// Initial configuration for a [Player] instance.
///
/// All fields are immutable and must be set at construction time.
/// Properties that mpv exposes as runtime-mutable (volume, audio client
/// name, audio driver, …) are not duplicated here — set them with the
/// matching `setX(...)` method after construction instead.
class PlayerConfiguration {
  /// If `true`, playback starts automatically as soon as a track finishes
  /// loading. Default: `false`.
  final bool autoPlay;

  /// Initial volume level (0–100). Default: `100`.
  final double initialVolume;

  /// Threshold forwarded to the [Player.stream.log] stream.
  ///
  /// Default: [LogLevel.warn] — surfaces warnings, errors, fatals.
  final LogLevel logLevel;

  const PlayerConfiguration({
    this.autoPlay = false,
    this.initialVolume = 100.0,
    this.logLevel = LogLevel.warn,
  });
}
