part of '../player.dart';

/// Module for controlling the core playback pipeline.
mixin _PlaybackModule on _PlayerBase {
  /// Starts or resumes playback.
  Future<void> play() async {
    _checkNotDisposed();
    _prop('pause', 'no');
  }

  /// Pauses playback.
  Future<void> pause() async {
    _checkNotDisposed();
    _prop('pause', 'yes');
  }

  /// Toggles between play and pause.
  Future<void> playOrPause() async {
    _checkNotDisposed();
    _commandString('cycle pause');
  }

  /// Stops playback and unloads the current file.
  Future<void> stop() async {
    _checkNotDisposed();
    _command(['stop']);
  }

  /// Seeks to [position].
  ///
  /// Set [relative] to `true` to seek by an offset from the current position.
  Future<void> seek(Duration position, {bool relative = false}) async {
    _checkNotDisposed();
    final secs = position.inMicroseconds / 1e6;
    _command(
        ['seek', secs.toStringAsFixed(6), relative ? 'relative' : 'absolute']);
  }
}
