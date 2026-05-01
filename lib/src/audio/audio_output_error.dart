// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../audio/audio_output_state.dart';
import '../events/mpv_player_error.dart';

/// Pure mapping from an [AudioOutputState] transition to an optional
/// [MpvLogError] surfaced on `Player.stream.error`.
///
/// `audio-output-state` reaches `failed` the moment `ao_init_best()`
/// returns NULL — the wrapper turns that into a typed error so consumers
/// can react immediately to a silent player without polling
/// `audio-out-params/format`. All other states return `null`.
///
/// Extracted from the player constructor for testability — see
/// `test/internal/audio_output_error_test.dart`.
@internal
MpvLogError? buildAudioOutputError(AudioOutputState state) {
  if (state == AudioOutputState.failed) {
    return const MpvLogError(
      prefix: 'mpv_audio_kit',
      level: 'error',
      text: 'Audio output failed to initialize — playback is silent',
    );
  }
  return null;
}
