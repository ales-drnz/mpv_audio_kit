// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'bass_treble_settings.dart';
import 'compressor_settings.dart';
import 'crossfeed_settings.dart';
import 'equalizer_settings.dart';
import 'loudness_settings.dart';
import 'pitch_tempo_settings.dart';
import 'silence_trim_settings.dart';
import 'stereo_settings.dart';

part 'audio_effects.freezed.dart';

/// All DSP effects in mpv's `--af` filter chain, bundled into a single
/// atomic configuration object.
///
/// Apply via [Player.setAudioEffects] (replace the whole bundle) or
/// [Player.updateAudioEffects] (mutate one or more fields with a
/// Freezed-style mapper). Read live via [PlayerStream.audioEffects] or
/// [PlayerState.audioEffects].
///
/// Chain order is fixed:
///
///   1. [custom]      — raw lavfi filter strings (consumer-supplied)
///   2. [compressor]  — dynamic-range compressor
///   3. [equalizer]   — 10-band graphic EQ
///   4. [bassTreble]  — low-shelf + high-shelf tone control
///   5. [stereo]      — width / balance manipulation
///   6. [crossfeed]   — headphone crossfeed (bs2b)
///   7. [silenceTrim] — auto-trim silence at start / end
///   8. [pitchTempo]  — pitch + tempo shifter (rubberband)
///   9. [crossfade]   — fade between consecutive playlist entries
///  10. [loudness]    — EBU R128 loudness normalisation
///
/// Compression hits the raw signal first; tonal shaping (EQ + tone +
/// stereo + crossfeed) follows; pitch/tempo and crossfade adjust
/// timing; loudnorm runs last so it adapts to whatever the upstream
/// stages produced.
///
/// Each per-effect Settings carries its own `enabled` flag — disabling
/// a stage strips it from the chain at zero CPU cost while preserving
/// its parameters in the bundle.
@freezed
abstract class AudioEffects with _$AudioEffects {
  const factory AudioEffects({
    /// Raw mpv lavfi filter strings (see ffmpeg's libavfilter for syntax,
    /// e.g. `lavfi-aecho=0.8:0.5:50:0.4`). Inserted at the head of the
    /// chain, before any wrapper-managed stage. Use for filters not
    /// covered by the typed effects below.
    @Default(<String>[]) List<String> custom,

    /// Dynamic-range compressor. See [CompressorSettings].
    @Default(CompressorSettings()) CompressorSettings compressor,

    /// 10-band graphic equalizer. See [EqualizerSettings].
    @Default(EqualizerSettings()) EqualizerSettings equalizer,

    /// Two-band shelving tone control (bass + treble). See
    /// [BassTrebleSettings].
    @Default(BassTrebleSettings()) BassTrebleSettings bassTreble,

    /// Stereo width + balance. See [StereoSettings].
    @Default(StereoSettings()) StereoSettings stereo,

    /// Headphone crossfeed (bs2b). See [CrossfeedSettings].
    @Default(CrossfeedSettings()) CrossfeedSettings crossfeed,

    /// Auto-trim silence at start / end. See [SilenceTrimSettings].
    @Default(SilenceTrimSettings()) SilenceTrimSettings silenceTrim,

    /// Pitch + tempo shifter (rubberband). See [PitchTempoSettings].
    @Default(PitchTempoSettings()) PitchTempoSettings pitchTempo,

    /// Crossfade duration between consecutive playlist entries. `null`
    /// disables crossfading (gapless transition still works via mpv's
    /// prefetch). Set to `Duration.zero` to also disable explicitly.
    Duration? crossfade,

    /// EBU R128 loudness normalisation. See [LoudnessSettings].
    @Default(LoudnessSettings()) LoudnessSettings loudness,
  }) = _AudioEffects;
}
