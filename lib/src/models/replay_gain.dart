// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

/// Modes for ReplayGain normalization.
enum ReplayGainMode {
  /// Disable ReplayGain.
  none('no'),

  /// Use track-based ReplayGain.
  track('track'),

  /// Use album-based ReplayGain.
  album('album');

  final String value;
  const ReplayGainMode(this.value);
}
