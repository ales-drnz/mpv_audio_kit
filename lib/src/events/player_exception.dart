// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Every exception a [Player] method throws. Switch on it to handle each
/// case:
///
/// ```dart
/// try {
///   await player.seek(position);
/// } on PlayerException catch (e) {
///   switch (e) {
///     case PlayerDisposedException():
///     case PlayerInitException(:final message):
///     case MpvCommandException(:final name, :final code):
///     case SourceException(:final uri):
///   }
/// }
/// ```
///
/// Invalid arguments are programming errors and throw [ArgumentError] or
/// [RangeError] instead, before anything reaches libmpv.
sealed class PlayerException implements Exception {
  const PlayerException();
}

/// The [Player] was disposed before or during the call.
final class PlayerDisposedException extends PlayerException {
  /// Creates the exception thrown by a call on a disposed player.
  const PlayerDisposedException();

  @override
  String toString() => 'PlayerDisposedException: the Player has been disposed';
}

/// The [Player] could not start: libmpv failed to load or initialize.
/// Every call on that player throws it.
final class PlayerInitException extends PlayerException {
  /// Creates the exception with the reason bring-up failed.
  const PlayerInitException(this.message);

  /// Why bring-up failed, as reported by the loader or by libmpv.
  final String message;

  @override
  String toString() => 'PlayerInitException: $message';
}

/// libmpv rejected a command or a property write: an unknown property or
/// command, a value it refuses, or a command with nothing to act on (a
/// seek with no file loaded).
final class MpvCommandException extends PlayerException {
  /// Creates the exception for a request libmpv rejected.
  const MpvCommandException({
    required this.name,
    required this.code,
    required this.message,
  });

  /// The property (`'volume'`) or command (`'seek'`) that was rejected.
  final String name;

  /// The negative mpv error code, see `MpvError` for the known ones.
  final int code;

  /// mpv's description of [code], from `mpv_error_string`.
  final String message;

  @override
  String toString() => 'MpvCommandException($name): $message (code=$code)';
}

/// A media source could not be prepared for playback before reaching
/// libmpv: a missing `asset://`, or an Android `content://` URI the app
/// cannot read. Failures inside libmpv (a 404, an unsupported format)
/// arrive on `stream.error` instead, since playback is asynchronous.
final class SourceException extends PlayerException {
  /// Creates the exception for [uri] with the reason it failed.
  const SourceException(this.uri, this.message);

  /// The URI as passed to the player.
  final String uri;

  /// Why the source could not be prepared.
  final String message;

  @override
  String toString() => 'SourceException($uri): $message';
}
