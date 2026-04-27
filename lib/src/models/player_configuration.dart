// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

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

  /// When `true` (default), the library decodes the embedded video frame
  /// extracted on each file-loaded event into an 800px PNG and attaches it
  /// to `playlist.medias[currentIdx].extras['artBytes']` (and
  /// `'artUri'` as a base64 data URI).
  ///
  /// Set to `false` to skip that work entirely — useful for apps that read
  /// cover art out-of-band (e.g. via `metadata_god`) or want to run their
  /// own image pipeline. The raw BGRA buffer is still emitted on
  /// `Player.stream.coverArtRaw` regardless of this flag.
  final bool processCoverArt;

  const PlayerConfiguration({
    this.autoPlay = false,
    this.initialVolume = 100.0,
    this.logLevel = 'warn',
    this.audioClientName,
    this.processCoverArt = true,
  });
}
