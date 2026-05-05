// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:test/test.dart';
// Import via the public entry library so we get the typed `MpvEndFileReason`
// from `models/events/mpv_player_error.dart` (and not the duplicate raw FFI enum
// of the same name from `mpv_bindings.dart`, which the public `library`
// intentionally hides).
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('MpvPlayerError sealed switch', () {
    test('exhaustive pattern match compiles and dispatches by variant', () {
      const endFile = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: 'loading failed',
      );
      const log = MpvLogError(
        prefix: 'ffmpeg',
        level: LogLevel.error,
        text: 'codec not found',
      );

      String describe(MpvPlayerError e) {
        return switch (e) {
          MpvEndFileError() => 'end:${e.code}',
          MpvLogError() => 'log:${e.prefix}',
        };
      }

      expect(describe(endFile), 'end:${MpvError.mpvErrorLoadingFailed}');
      expect(describe(log), 'log:ffmpeg');
    });

    test('message getter routes to the variant payload', () {
      const endFile = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: 'mpv-supplied error string',
      );
      expect(endFile.message, 'mpv-supplied error string');

      const log = MpvLogError(
        prefix: 'demux',
        level: LogLevel.error,
        text: 'failed to open',
      );
      expect(log.message, '[demux] error: failed to open');
    });
  });

  group('MpvEndFileErrorX predicates', () {
    test('isLoadingError matches mpvErrorLoadingFailed', () {
      const e = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: '',
      );
      expect(e.isLoadingError, isTrue);
      expect(e.isAudioOutputError, isFalse);
      expect(e.isFormatError, isFalse);
    });

    test('isAudioOutputError matches mpvErrorAoInitFailed', () {
      const e = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorAoInitFailed,
        message: '',
      );
      expect(e.isAudioOutputError, isTrue);
      expect(e.isLoadingError, isFalse);
      expect(e.isFormatError, isFalse);
    });

    test('isFormatError matches both unknown-format and nothing-to-play', () {
      const unknown = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorUnknownFormat,
        message: '',
      );
      const nothing = MpvEndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorNothingToPlay,
        message: '',
      );
      expect(unknown.isFormatError, isTrue);
      expect(nothing.isFormatError, isTrue);
    });

    test('zero code does not satisfy any predicate', () {
      const e = MpvEndFileError(
        reason: MpvEndFileReason.eof,
        code: 0,
        message: '',
      );
      expect(e.isLoadingError, isFalse);
      expect(e.isAudioOutputError, isFalse);
      expect(e.isFormatError, isFalse);
    });
  });

  group('MpvFileEndedEventX.reachedNaturalEnd', () {
    test('true only for eof reason', () {
      const eof = MpvFileEndedEvent(reason: MpvEndFileReason.eof, error: 0);
      expect(eof.reachedNaturalEnd, isTrue);

      const stop = MpvFileEndedEvent(reason: MpvEndFileReason.stop, error: 0);
      expect(stop.reachedNaturalEnd, isFalse);

      const quit = MpvFileEndedEvent(reason: MpvEndFileReason.quit, error: 0);
      expect(quit.reachedNaturalEnd, isFalse);

      const error = MpvFileEndedEvent(
          reason: MpvEndFileReason.error,
          error: MpvError.mpvErrorLoadingFailed);
      expect(error.reachedNaturalEnd, isFalse);

      const redirect =
          MpvFileEndedEvent(reason: MpvEndFileReason.redirect, error: 0);
      expect(redirect.reachedNaturalEnd, isFalse);
    });
  });

  group('MpvEndFileReason.fromValue', () {
    test('round-trips every defined value', () {
      for (final reason in MpvEndFileReason.values) {
        expect(MpvEndFileReason.fromValue(reason.value), reason);
      }
    });

    test('unknown values fall back to eof', () {
      expect(MpvEndFileReason.fromValue(99), MpvEndFileReason.eof);
      expect(MpvEndFileReason.fromValue(-1), MpvEndFileReason.eof);
    });
  });
}
