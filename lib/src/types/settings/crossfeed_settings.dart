// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'crossfeed_settings.freezed.dart';

/// Headphone crossfeed processor — bleeds a low-passed copy of each
/// channel into the opposite ear, simulating the natural inter-aural
/// crosstalk of a loudspeaker setup. Reduces "head-in-a-vise" fatigue
/// on hard-panned mixes when listening on headphones.
///
/// Wraps libavfilter's `bs2b` (Bauer Stereophonic-to-Binaural) filter.
/// [enabled] toggles the stage in the filter chain; the parameters are
/// preserved while disabled.
///
/// [intensity] selects one of bs2b's three preset profiles, balancing
/// the strength of the crossfeed effect against the audible coloration
/// it introduces.
@freezed
abstract class CrossfeedSettings with _$CrossfeedSettings {
  const factory CrossfeedSettings({
    /// Whether the stage is inserted into mpv's filter chain. Disabling
    /// preserves the configuration.
    @Default(false) bool enabled,

    /// Profile / intensity preset. Default matches ffmpeg's `bs2b`
    /// default ([CrossfeedIntensity.defaultProfile], 700 Hz / 4.5 dB).
    @Default(CrossfeedIntensity.defaultProfile) CrossfeedIntensity intensity,
  }) = _CrossfeedSettings;
}

/// bs2b's three classic profiles, ordered by crossfeed strength.
enum CrossfeedIntensity {
  /// Default. Light crossfeed (700 Hz cutoff, 4.5 dB level). Subtle,
  /// least audible coloration.
  defaultProfile('default'),

  /// C. Moy's profile (700 Hz cutoff, 6 dB level). Stronger crossfeed,
  /// matches the original Moy headphone amp.
  cmoy('cmoy'),

  /// Jan Meier's profile (650 Hz cutoff, 9.5 dB level). Most aggressive,
  /// closest to a loudspeaker's interaural crosstalk.
  jmeier('jmeier');

  final String mpvValue;
  const CrossfeedIntensity(this.mpvValue);
}
