// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/player/audio_output_error.dart';
import 'package:test/test.dart';

void main() {
  group('buildAudioOutputError', () {
    test('returns an LogError on AudioOutputState.failed', () {
      final err = buildAudioOutputError(AudioOutputState.failed);
      expect(err, isNotNull);
      expect(err!.prefix, 'mpv_audio_kit');
      expect(err.level, LogLevel.error);
      expect(err.text, contains('Audio output failed'));
    });

    test('returns null on every non-failed state', () {
      expect(buildAudioOutputError(AudioOutputState.closed), isNull);
      expect(buildAudioOutputError(AudioOutputState.initializing), isNull);
      expect(buildAudioOutputError(AudioOutputState.active), isNull);
    });

    test('emitted error round-trips through PlayerError sealed type', () {
      // Future code that consumes the error stream uses a switch over the
      // sealed `PlayerError` union. Verify the helper's product is in
      // the right branch.
      final PlayerError err = buildAudioOutputError(AudioOutputState.failed)!;
      final isLog = switch (err) {
        LogError() => true,
        EndFileError() => false,
      };
      expect(isLog, isTrue);
    });
  });
}
