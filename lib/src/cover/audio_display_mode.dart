// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Cover-art display priority, mirroring
/// `--audio-display=<no|embedded-first|external-first>`.
enum AudioDisplayMode {
  /// Disable video/cover-art display entirely. Recommended when the host
  /// app reads artwork out-of-band (e.g. via `metadata_god`).
  no('no'),

  /// Show embedded cover art first, fall back to external files (mpv default).
  embeddedFirst('embedded-first'),

  /// Show external cover-art files first, fall back to embedded.
  externalFirst('external-first');

  const AudioDisplayMode(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [embeddedFirst].
  static AudioDisplayMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'embedded-first' => embeddedFirst,
        'external-first' => externalFirst,
        _ => embeddedFirst,
      };
}
