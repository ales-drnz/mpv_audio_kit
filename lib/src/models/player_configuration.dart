// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Initial configuration for a [Player] instance.
///
/// All fields are immutable and must be set at construction time.
class PlayerConfiguration {
  /// If `true`, playback starts automatically as soon as a track finishes
  /// loading. Default: `false`.
  final bool autoPlay;

  /// Initial volume level (0–100). Default: `100`.
  final double initialVolume;

  /// mpv log level forwarded to the [Player.stream.log] stream.
  ///
  /// Valid values (from most to least verbose):
  /// `'trace'`, `'debug'`, `'v'`, `'info'`, `'warn'`, `'error'`, `'fatal'`,
  /// `'no'` (disabled).
  ///
  /// Default: `'warn'`.
  final String logLevel;

  final String? audioClientName;

  const PlayerConfiguration({
    this.autoPlay = false,
    this.initialVolume = 100.0,
    this.logLevel = 'warn',
    this.audioClientName,
  });
}
