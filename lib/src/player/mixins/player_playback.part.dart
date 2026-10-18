// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Transport setters: play, pause, stop, seek, chapter navigation,
/// and the A-B loop controls.
mixin _PlaybackModule on _PlayerBase {
  /// Starts or resumes playback. Idempotent: a no-op when already
  /// playing, including the last moments of the queue while the output
  /// buffer still plays. Once the queue has ended ([PlayerState.completed])
  /// it starts the last track again from its beginning; a source that
  /// cannot seek back there (a live stream, a closed [PcmSource]) stays at
  /// its end and the intent stays off. With nothing loaded (before any
  /// open, after [stop]) there is nothing to resume and the intent stays
  /// off too. The future completes once mpv has taken the unpause; the
  /// playback itself is observable via [PlayerStream.playing]. A [pause],
  /// [stop] or load called after it has the last word: then it writes
  /// nothing.
  Future<void> play() async {
    await _gate();
    // Optimistic intent: `pause` is silent on the first load → playing
    // transition, so set the intent axis here rather than relying on the
    // observer. See [PlayerState.playWhenReady].
    final intent = _claimIntent(true);
    // Parked at the end (`keep-open`), an unpause alone is undone by the
    // playloop hitting EOF again, and the intent would show playing over
    // silence. Seek back first; the unpause after it sticks, as in [jump].
    // In the last buffer before the park mpv is not paused yet and the
    // audio still plays: nothing to do but the unpause.
    final parked = await _parkedPaused();
    // A later call claimed the transport during the reads: its pause write
    // is already out, and an unpause written now would undo it.
    if (intent != _intentEpoch) return;
    if (parked) {
      await _command(['seek', '0', 'absolute']);
      // A seek that landed has left EOF by the next read: the seek wakes
      // the core, which runs it before it serves another request. Still at
      // EOF on a source that cannot seek, it failed. The unpause would only
      // be paused again by keep-open, too fast for a notification, so it
      // is not written and the intent goes back off. Not while a load is
      // running: it replaces the parked file (openAll removes it first), so
      // the reads tell nothing about the source, and the unpause arms the
      // load.
      if (_loadsInFlight == 0 &&
          await _parkedAtEof() &&
          await getRawProperty('seekable') != 'yes' &&
          _loadsInFlight == 0) {
        if (intent == _intentEpoch) _writeIntent(false);
        return;
      }
      if (intent != _intentEpoch) return;
      await _prop('pause', 'no');
      // A park read still on its way when this call began (the park had
      // just happened) clears the intent on arrival; by now it has
      // arrived, so the intent of this call is set again.
      if (intent == _intentEpoch) _writeIntent(true);
      return;
    }
    await _prop('pause', 'no');
    // Idle with nothing to play (before any open, after stop or a failed
    // load): the unpause only arms the next load, nothing plays now. Not
    // while a load is running, which is about to give the core content.
    if (_loadsInFlight == 0 &&
        await getRawProperty('idle-active') == 'yes' &&
        _loadsInFlight == 0 &&
        intent == _intentEpoch) {
      _writeIntent(false);
    }
  }

  /// Pauses playback. Idempotent: a no-op when already paused. Position
  /// is preserved: call [play] to resume from the same offset.
  Future<void> pause() async {
    await _gate();
    _claimIntent(false);
    await _prop('pause', 'yes');
  }

  /// Writes mpv's "watch later" resume config for the current file, saving the
  /// playback position (plus a curated set of audio props) so a later
  /// [Player.open] of the same file resumes from here. Playback continues.
  ///
  /// Pairs with [PlayerConfiguration.resumePlayback] (on by default) and
  /// [PlayerConfiguration.watchLaterDir]. On mobile, set `watchLaterDir` to a
  /// writable path or the write silently fails.
  ///
  /// mpv saves only the values that differ from the ones it had at
  /// startup. [PlayerConfiguration.initialVolume] applies after startup,
  /// so for the volume that base is 100: a volume of 100 is not saved, and
  /// reopening the file keeps the volume of the moment.
  ///
  /// A restored value becomes the player's own: it stays for the files
  /// that follow, until the app sets another. To keep a value per file,
  /// set it again when the next file opens.
  ///
  /// An Android `content://` source has no resume point: it plays from a
  /// file descriptor, whose number the system gives again to other files.
  /// For it the call writes nothing and says so on
  /// [PlayerStream.internalLog].
  Future<void> writeResumeConfig() async {
    await _gate();
    final (rc, path) = await _getAsync('path', MpvFormat.mpvFormatString);
    if (rc >= 0 && path is String && isFdUri(path)) {
      _internalLog(
        'No resume point for $path: a descriptor number names another '
        'file once it is closed.',
      );
      return;
    }
    await _commandChecked(['write-watch-later-config']);
  }

  /// Deletes the "watch later" resume config for the current file, or for
  /// [filename] when given, clearing any saved resume point.
  ///
  /// Name [filename] as the [Media] given to [Player.open]: a `file://`
  /// URL or an `asset://` URI stands for the path the load gives mpv,
  /// which keys the resume point.
  Future<void> deleteResumeConfig({String? filename}) async {
    await _gate();
    await _command(
      filename == null
          ? ['delete-watch-later-config']
          : ['delete-watch-later-config', await loadedName(filename)],
    );
  }

  /// Stops playback and unloads the current file. Distinct from [pause]:
  /// the demuxer is torn down, the playhead is reset, and the next call
  /// must be [open] (not [play]) to start a new track.
  Future<void> stop() async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open() that is
    // still resolving its URI aborts instead of resuming after this call
    // and restarting playback (see [Player.open]).
    _claimLoad();
    await _gate();
    // Stop unloads the file; intent returns to "not playing" so the OS
    // button settles on play. mpv may not emit `pause` here, so set it.
    _claimIntent(false);
    // Execute in-flight transport writes first; see [_settleWrites].
    await _settleWrites();
    await _commandChecked(['stop']);
    // mpv clears its playlist on stop but reports the change only when a
    // file was playing. Idle (after a failed load) it stays silent, so the
    // state would keep the old entries and the live sources they hold.
    final (rc, node) = await _getAsync('playlist', MpvFormat.mpvFormatNode);
    if (rc >= 0 && node is List && !_disposed) _updatePlaylistFromNode(node);
  }

  /// Seeks playback to a position in the current file.
  ///
  /// With [relative] = `false` (default), [position] is an absolute
  /// timestamp from the start of the file: a negative one seeks to the
  /// start, and one past the end ends the file as if it played there.
  /// With [relative] = `true`, [position] is a signed offset from the
  /// current playhead: positive moves forward, negative moves backward.
  ///
  /// Examples:
  /// ```dart
  /// await player.seek(const Duration(seconds: 30));                    // jump to 0:30
  /// await player.seek(const Duration(seconds: -10), relative: true);   // skip back 10s
  /// await player.seek(const Duration(seconds: 30), relative: true);    // skip forward 30s
  /// ```
  ///
  /// Throws [MpvCommandException] if mpv rejects the seek: most commonly when
  /// nothing is loaded.
  Future<void> seek(
    Duration position, {
    bool relative = false,
    bool exact = false,
  }) async {
    await _gate();
    // mpv counts a negative absolute time from the end of the file, and
    // fails it when the length is unknown.
    final secs = !relative && position.isNegative
        ? 0.0
        : durationToSeconds(position);
    final mode = relative ? 'relative' : 'absolute';
    await _commandChecked([
      'seek',
      secs.toStringAsFixed(6),
      exact ? '$mode+exact' : mode,
    ]);
  }

  /// Seeks by percentage of the file duration (0 to 100; past 100 the file
  /// ends). Absolute by default, or relative to the current percent position
  /// when [relative] is true.
  /// [exact] forces a sample-accurate (slower) seek instead of snapping to a
  /// keyframe. Counterpart of [seek] for progress-bar scrubbing.
  Future<void> seekToPercent(
    double percent, {
    bool relative = false,
    bool exact = false,
  }) async {
    _checkFinite(percent, 'percent');
    await _gate();
    final mode = relative ? 'relative-percent' : 'absolute-percent';
    await _commandChecked([
      'seek',
      percent.toStringAsFixed(4),
      exact ? '$mode+exact' : mode,
    ]);
  }

  /// Jumps back to where playback was before the last jump in the current
  /// file (mpv's `revert-seek`). A jump is a [seek] or [seekToPercent], and
  /// also a chapter change, a return to A of the A-B loop, the restart
  /// [play] makes from the end, or a seek from the OS media session. Jumps
  /// less than about 2 seconds apart count as one. Calling it again undoes
  /// the revert.
  ///
  /// Throws [MpvCommandException] when the current file has nothing to
  /// undo yet, for example right after it loaded.
  Future<void> revertSeek() async {
    await _gate();
    await _commandChecked(['revert-seek']);
  }

  /// Jumps to the chapter at [index] in the current file.
  ///
  /// Indexing is 0-based and matches [PlayerState.chapters]; -1 goes to
  /// the start of the file. mpv refuses any index outside -1 to
  /// `chapters.length - 1`, and the call then throws
  /// [MpvCommandException] with [PlayerState.currentChapter] unchanged:
  /// check the length for a "next chapter" button. An accepted index
  /// reaches [PlayerState.currentChapter] at once, and the next observer
  /// event confirms it.
  Future<void> setChapter(int index) async {
    await _gate();
    await _prop('chapter', index.toString());
    _updateField(
      (s) => s.copyWith(currentChapter: index),
      _reactives.currentChapter,
      index,
    );
  }

  /// Replaces the current file's chapter markers with [chapters]: an
  /// "external chapters" injection for sources whose container carries none.
  ///
  /// The canonical case is a resolved YouTube (`googlevideo`) audio stream:
  /// YouTube's chapters live in the video description
  /// not in the audio container, so a freshly-loaded stream has an empty
  /// `chapter-list`. This writes the list directly through the stable C API
  /// (`mpv_set_property` on `chapter-list`), so [PlayerStream.chapters] /
  /// [PlayerState.chapters] then reflect them and [setChapter] navigates them
  /// natively: no demuxer chapters required. Pass an empty list to clear.
  ///
  /// Timing: call this AFTER the file is loaded (e.g. on the first
  /// [PlayerStream.duration] event for the track). mpv resets `chapter-list`
  /// to the demuxer's own chapters on each load, so a write issued before the
  /// load settles would be overwritten.
  ///
  /// mpv keeps only the markers from 0 up to the end of the file, none when
  /// the length is unknown (a live stream), and does not sort them: pass
  /// the list in time order. The state takes the list mpv kept.
  Future<void> setChapters(List<Chapter> chapters) async {
    await _gate();
    final rc = await _setChapterListNode(chapters);
    if (rc < 0) {
      throw MpvCommandException(
        name: 'chapter-list',
        code: rc,
        message: _errorString(rc),
      );
    }
    // Read back what mpv kept: its observer reports nothing when that
    // equals its list before the write.
    final (readRc, node) = await _getAsync(
      'chapter-list',
      MpvFormat.mpvFormatNode,
    );
    if (_disposed) return;
    final list = readRc >= 0
        ? List<Chapter>.unmodifiable(parseChapterListNode(node))
        : List<Chapter>.unmodifiable(chapters);
    _updateField((s) => s.copyWith(chapters: list), _reactives.chapters, list);
  }

  // ── A-B loop ───────────────────────────────────────────────────────────────

  /// Sets the A-B loop start point. Pass `null` to disable.
  ///
  /// Combined with [setAbLoopB], creates a playback loop: when the head
  /// crosses the B point, mpv seeks back to A. Common in language-learning
  /// or audiobook apps for repeated practice of a passage.
  ///
  /// The points belong to the current file: when it ends, or another file
  /// loads, they go back to `null`. Points set with no file loaded apply to
  /// every file instead. Keep both inside the file: past its end, the end
  /// of the file seeks back to A again and again. A live [PcmSource] entry
  /// plays on past B from libmpv-r18 on; with an older libmpv it never
  /// ends while the loop is on.
  Future<void> setAbLoopA(Duration? position) async {
    await _gate();
    await _prop(
      'ab-loop-a',
      position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6),
    );
    _updateField(
      (s) => s.copyWith(abLoopA: position),
      _reactives.abLoopA,
      position,
    );
  }

  /// Sets the A-B loop end point. Pass `null` to disable. Like A, it
  /// belongs to the current file. See [setAbLoopA].
  Future<void> setAbLoopB(Duration? position) async {
    await _gate();
    await _prop(
      'ab-loop-b',
      position == null ? 'no' : durationToSeconds(position).toStringAsFixed(6),
    );
    _updateField(
      (s) => s.copyWith(abLoopB: position),
      _reactives.abLoopB,
      position,
    );
  }

  /// Sets how many times playback jumps back to A after the first pass:
  /// with 3 the section is heard 4 times. Pass `null` for infinite looping
  /// (mpv's `inf`); `0` turns the A-B loop off even with both points set.
  /// Unlike the points, the count stays for the next files. Mirrors mpv's
  /// `--ab-loop-count` option.
  Future<void> setAbLoopCount(int? count) async {
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'count', 'must be null (= inf) or >= 0');
    }
    await _gate();
    await _prop('ab-loop-count', count == null ? 'inf' : count.toString());
    _updateField(
      (s) => s.copyWith(abLoopCount: count),
      _reactives.abLoopCount,
      count,
    );
  }
}
