// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Import via the public entry library so we get the typed `MpvEndFileReason`
// from `models/events/player_error.dart` (and not the duplicate raw FFI enum
// of the same name from `mpv_bindings.dart`, which the public `library`
// intentionally hides).
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('PlayerError sealed switch', () {
    test('exhaustive pattern match compiles and dispatches by variant', () {
      const endFile = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: 'loading failed',
      );
      const log = LogError(
        prefix: 'ffmpeg',
        level: LogLevel.error,
        text: 'codec not found',
      );

      String describe(PlayerError e) {
        return switch (e) {
          EndFileError() => 'end:${e.code}',
          LogError() => 'log:${e.prefix}',
        };
      }

      expect(describe(endFile), 'end:${MpvError.mpvErrorLoadingFailed}');
      expect(describe(log), 'log:ffmpeg');
    });

    test('message getter routes to the variant payload', () {
      const endFile = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: 'mpv-supplied error string',
      );
      expect(endFile.message, 'mpv-supplied error string');

      const log = LogError(
        prefix: 'demux',
        level: LogLevel.error,
        text: 'failed to open',
      );
      expect(log.message, '[demux] error: failed to open');
    });
  });

  group('EndFileErrorX predicates', () {
    test('isLoadingError matches mpvErrorLoadingFailed', () {
      const e = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorLoadingFailed,
        message: '',
      );
      expect(e.isLoadingError, isTrue);
      expect(e.isAudioOutputError, isFalse);
      expect(e.isFormatError, isFalse);
    });

    test('isAudioOutputError matches mpvErrorAoInitFailed', () {
      const e = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorAoInitFailed,
        message: '',
      );
      expect(e.isAudioOutputError, isTrue);
      expect(e.isLoadingError, isFalse);
      expect(e.isFormatError, isFalse);
    });

    test('isFormatError matches both unknown-format and nothing-to-play', () {
      const unknown = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorUnknownFormat,
        message: '',
      );
      const nothing = EndFileError(
        reason: MpvEndFileReason.error,
        code: MpvError.mpvErrorNothingToPlay,
        message: '',
      );
      expect(unknown.isFormatError, isTrue);
      expect(nothing.isFormatError, isTrue);
    });

    test('zero code does not satisfy any predicate', () {
      const e = EndFileError(
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
        error: MpvError.mpvErrorLoadingFailed,
      );
      expect(error.reachedNaturalEnd, isFalse);

      const redirect = MpvFileEndedEvent(
        reason: MpvEndFileReason.redirect,
        error: 0,
      );
      expect(redirect.reachedNaturalEnd, isFalse);
    });
  });

  group('MpvFileEndedEvent value semantics', () {
    const media = Media('https://example.com/a.mp3');
    const full = MpvFileEndedEvent(
      reason: MpvEndFileReason.eof,
      error: 0,
      media: media,
      position: Duration(seconds: 3),
      duration: Duration(seconds: 4),
    );

    test('the entry fields default to null', () {
      const bare = MpvFileEndedEvent(reason: MpvEndFileReason.stop, error: 0);
      expect(bare.media, isNull);
      expect(bare.position, isNull);
      expect(bare.duration, isNull);
    });

    test('equality and hashCode cover every field', () {
      const same = MpvFileEndedEvent(
        reason: MpvEndFileReason.eof,
        error: 0,
        media: Media('https://example.com/a.mp3'),
        position: Duration(seconds: 3),
        duration: Duration(seconds: 4),
      );
      expect(full, same);
      expect(full.hashCode, same.hashCode);
      const others = [
        MpvFileEndedEvent(
          reason: MpvEndFileReason.eof,
          error: 0,
          media: Media('https://example.com/b.mp3'),
          position: Duration(seconds: 3),
          duration: Duration(seconds: 4),
        ),
        MpvFileEndedEvent(
          reason: MpvEndFileReason.eof,
          error: 0,
          media: media,
          position: Duration(seconds: 2),
          duration: Duration(seconds: 4),
        ),
        MpvFileEndedEvent(
          reason: MpvEndFileReason.eof,
          error: 0,
          media: media,
          position: Duration(seconds: 3),
        ),
      ];
      for (final other in others) {
        expect(full, isNot(other));
      }
    });

    test('toString names the entry fields', () {
      final text = full.toString();
      expect(text, contains('media: Media(uri: https://example.com/a.mp3'));
      expect(text, contains('position: 0:00:03.000000'));
      expect(text, contains('duration: 0:00:04.000000'));
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
