// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Modes for gapless audio transitions.
enum GaplessMode {
  /// Disable gapless playback.
  none('no'),

  /// Enable gapless playback (always attempt it).
  yes('yes'),

  /// Attempt gapless playback only if the audio format matches.
  weak('weak');

  final String value;
  const GaplessMode(this.value);
}
