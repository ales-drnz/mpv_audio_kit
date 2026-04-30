// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Module for controlling the core playback pipeline.
mixin _PlaybackModule on _PlayerBase {
  /// Starts or resumes playback. Idempotent: a no-op when already
  /// playing. Returns immediately; the actual `pause=no` round-trip
  /// to mpv settles asynchronously, observable via [PlayerStream.playing].
  Future<void> play() async {
    _checkNotDisposed();
    _prop('pause', 'no');
  }

  /// Pauses playback. Idempotent: a no-op when already paused. Position
  /// is preserved — call [play] to resume from the same offset.
  Future<void> pause() async {
    _checkNotDisposed();
    _prop('pause', 'yes');
  }

  /// Stops playback and unloads the current file. Distinct from [pause]:
  /// the demuxer is torn down, the playhead is reset, and the next call
  /// must be [open] (not [play]) to start a new track.
  Future<void> stop() async {
    _checkNotDisposed();
    _command(['stop']);
  }

  /// Seeks playback to a position in the current file.
  ///
  /// With [relative] = `false` (default), [position] is an absolute
  /// timestamp from the start of the file (clamped to `[0, duration]`).
  /// With [relative] = `true`, [position] is a signed offset from the
  /// current playhead — positive moves forward, negative moves backward.
  ///
  /// Examples:
  /// ```dart
  /// await player.seek(const Duration(seconds: 30));                    // jump to 0:30
  /// await player.seek(const Duration(seconds: -10), relative: true);   // skip back 10s
  /// await player.seek(const Duration(seconds: 30), relative: true);    // skip forward 30s
  /// ```
  Future<void> seek(Duration position, {bool relative = false}) async {
    _checkNotDisposed();
    final secs = position.inMicroseconds / 1e6;
    _command(
        ['seek', secs.toStringAsFixed(6), relative ? 'relative' : 'absolute']);
  }

  /// Jumps to the chapter at [index] in the current file.
  ///
  /// Indexing is 0-based and matches [PlayerState.chapters]. mpv handles
  /// out-of-range values (negative or beyond the last chapter) by
  /// clamping; the optimistic [PlayerState.currentChapter] update reflects
  /// the requested value and is corrected by the next observer event.
  Future<void> setChapter(int index) async {
    _checkNotDisposed();
    _prop('chapter', index.toString());
    _updateField((s) => s.copyWith(currentChapter: index),
        _reactives.currentChapter, index);
  }

  // ── A-B loop ───────────────────────────────────────────────────────────────

  /// Sets the A-B loop start point. Pass `null` to disable.
  ///
  /// Combined with [setAbLoopB], creates a playback loop: when the head
  /// crosses the B point, mpv seeks back to A. Common in language-learning
  /// or audiobook apps for repeated practice of a passage.
  Future<void> setAbLoopA(Duration? position) async {
    _checkNotDisposed();
    _prop('ab-loop-a',
        position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6));
    _updateField(
        (s) => s.copyWith(abLoopA: position), _reactives.abLoopA, position);
  }

  /// Sets the A-B loop end point. Pass `null` to disable. See [setAbLoopA].
  Future<void> setAbLoopB(Duration? position) async {
    _checkNotDisposed();
    _prop('ab-loop-b',
        position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6));
    _updateField(
        (s) => s.copyWith(abLoopB: position), _reactives.abLoopB, position);
  }

  /// Sets the total A-B loop repetitions. Pass `null` for infinite looping
  /// (mpv's `inf`); non-negative int for explicit count. Mirrors mpv's
  /// `--ab-loop-count` option.
  Future<void> setAbLoopCount(int? count) async {
    _checkNotDisposed();
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'count', 'must be null (= inf) or >= 0');
    }
    _prop('ab-loop-count', count == null ? 'inf' : count.toString());
    _updateField(
        (s) => s.copyWith(abLoopCount: count), _reactives.abLoopCount, count);
  }
}
