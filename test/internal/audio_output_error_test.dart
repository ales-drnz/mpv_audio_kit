// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:mpv_audio_kit/src/audio/audio_output_error.dart';
import 'package:mpv_audio_kit/src/audio/audio_output_state.dart';
import 'package:mpv_audio_kit/src/events/mpv_player_error.dart';

void main() {
  group('buildAudioOutputError', () {
    test('returns an MpvLogError on AudioOutputState.failed', () {
      final err = buildAudioOutputError(AudioOutputState.failed);
      expect(err, isNotNull);
      expect(err!.prefix, 'mpv_audio_kit');
      expect(err.level, 'error');
      expect(err.text, contains('Audio output failed'));
    });

    test('returns null on every non-failed state', () {
      expect(buildAudioOutputError(AudioOutputState.closed), isNull);
      expect(buildAudioOutputError(AudioOutputState.initializing), isNull);
      expect(buildAudioOutputError(AudioOutputState.active), isNull);
    });

    test('emitted error round-trips through MpvPlayerError sealed type', () {
      // Future code that consumes the error stream uses a switch over the
      // sealed `MpvPlayerError` union. Verify the helper's product is in
      // the right branch.
      final MpvPlayerError err = buildAudioOutputError(
        AudioOutputState.failed,
      )!;
      final isLog = switch (err) {
        MpvLogError() => true,
        MpvEndFileError() => false,
      };
      expect(isLog, isTrue);
    });
  });
}
