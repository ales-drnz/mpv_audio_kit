// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

// `mpv_bindings.dart` defines its own integer-typed `MpvEndFileReason`
// (auto-generated FFI). The enum below shadows that name, so we hide
// the bindings symbol to keep the import free of name conflicts.
import '../mpv_bindings.dart' hide MpvEndFileReason;

part 'mpv_player_error.freezed.dart';

/// Typed error events from the mpv engine.
///
/// Sealed union of structured events that lets consumers distinguish
/// between playback failures, log-level errors, and internal engine
/// issues with a `switch`.
///
/// Use a `switch` on the sealed subtypes:
/// ```dart
/// player.stream.error.listen((error) {
///   switch (error) {
///     case MpvEndFileError():
///       print('Playback ended: reason=${error.reason}, code=${error.code}');
///     case MpvLogError():
///       print(error.message);
///   }
/// });
/// ```
@freezed
sealed class MpvPlayerError with _$MpvPlayerError {
  const MpvPlayerError._();

  /// Playback of a file ended with an error or unexpected EOF.
  ///
  /// Emitted when mpv fires `MPV_EVENT_END_FILE` with a non-zero error code.
  ///
  /// **Network note:** according to the mpv documentation, a network
  /// disconnection mid-stream may report as [MpvEndFileReason.eof] rather
  /// than [MpvEndFileReason.error]. Use `Player.stream.endFile` and compare
  /// the player's position against duration to detect premature endings.
  const factory MpvPlayerError.endFile({
    /// Why the file ended.
    required MpvEndFileReason reason,

    /// mpv error code (one of [MpvError] constants, e.g.
    /// [MpvError.mpvErrorLoadingFailed]). Only meaningful when [reason]
    /// is [MpvEndFileReason.error]; otherwise `0`.
    required int code,

    /// Human-readable error description.
    required String message,
  }) = MpvEndFileError;

  /// A log message at `error` or `fatal` level from an mpv subsystem.
  ///
  /// These are informational errors from mpv's internal logging — they don't
  /// necessarily mean playback has stopped. For example, a codec warning or
  /// a filter configuration issue.
  const factory MpvPlayerError.log({
    /// The mpv subsystem that produced the message (e.g. `'ffmpeg'`,
    /// `'demux'`, `'ao'`).
    required String prefix,

    /// The log level — either `'error'` or `'fatal'`.
    required String level,

    /// Raw log text from the mpv subsystem.
    required String text,
  }) = MpvLogError;

  /// Human-readable error description.
  ///
  /// For [MpvEndFileError] this is the mpv-supplied error string; for
  /// [MpvLogError] it is `'[prefix] level: text'`.
  String get message => switch (this) {
        MpvEndFileError(:final message) => message,
        MpvLogError(:final prefix, :final level, :final text) =>
          '[$prefix] $level: $text',
      };
}

/// Convenience predicates for [MpvEndFileError].
extension MpvEndFileErrorX on MpvEndFileError {
  /// Whether this is likely a loading/network failure.
  bool get isLoadingError => code == MpvError.mpvErrorLoadingFailed;

  /// Whether the audio output failed to initialize.
  bool get isAudioOutputError => code == MpvError.mpvErrorAoInitFailed;

  /// Whether the file format is unknown or too broken to open.
  bool get isFormatError =>
      code == MpvError.mpvErrorUnknownFormat ||
      code == MpvError.mpvErrorNothingToPlay;
}

/// Emitted for **every** file-end event, regardless of whether an error occurred.
///
/// This is the typed Dart equivalent of mpv's `MPV_EVENT_END_FILE`.
/// Subscribe via `Player.stream.endFile` to detect both clean completions
/// and premature endings (e.g. a network stream that reports EOF
/// mid-playback without setting an error code).
///
/// ```dart
/// player.stream.endFile.listen((event) {
///   if (event.reason == MpvEndFileReason.eof) {
///     // Compare player.state.position vs player.state.duration
///     // to decide if this was a genuine completion or a network drop.
///   }
/// });
/// ```
@freezed
abstract class MpvFileEndedEvent with _$MpvFileEndedEvent {
  const factory MpvFileEndedEvent({
    /// Why the file ended.
    required MpvEndFileReason reason,

    /// mpv error code. Non-zero only when [reason] is [MpvEndFileReason.error].
    required int error,
  }) = _MpvFileEndedEvent;
}

/// Whether the file ended naturally and not because of a stop, error, redirect,
/// or shutdown.
extension MpvFileEndedEventX on MpvFileEndedEvent {
  /// `true` when [reason] is [MpvEndFileReason.eof] — note that mpv also
  /// reports EOF on mid-stream network disconnects, so this is "natural end
  /// from mpv's POV", not "track played to completion".
  bool get reachedNaturalEnd => reason == MpvEndFileReason.eof;
}

/// Why a file ended — mirrors `mpv_end_file_reason` from the C API.
///
/// See the [mpv documentation](https://mpv.io/manual/master/) for details.
enum MpvEndFileReason {
  /// Playback ended naturally (reached end of file).
  ///
  /// **Important:** this is also reported when a network connection is
  /// interrupted mid-stream. Do not assume this always means the file
  /// played to completion.
  eof(MpvEndFileReason._eof),

  /// Playback was stopped by an external action (e.g. playlist-next).
  stop(MpvEndFileReason._stop),

  /// The player is quitting.
  quit(MpvEndFileReason._quit),

  /// An error caused playback to abort. The associated [MpvEndFileError.code]
  /// contains the specific mpv error code.
  error(MpvEndFileReason._error),

  /// The file was a playlist or redirect — its entries were appended to the
  /// playlist and this entry was removed.
  redirect(MpvEndFileReason._redirect);

  const MpvEndFileReason(this.value);

  /// The raw integer value matching the C API constant.
  final int value;

  // Private constants matching mpv_end_file_reason values.
  static const _eof = 0;
  static const _stop = 2;
  static const _quit = 3;
  static const _error = 4;
  static const _redirect = 5;

  /// Converts a raw mpv integer reason code to the corresponding enum value.
  static MpvEndFileReason fromValue(int value) => switch (value) {
        _eof => eof,
        _stop => stop,
        _quit => quit,
        _error => error,
        _redirect => redirect,
        _ => eof, // Defensive fallback for unknown values.
      };
}
