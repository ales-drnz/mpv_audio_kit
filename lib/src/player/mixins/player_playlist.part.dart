// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Playlist setters: queue mutation (add / remove / move / replace),
/// navigation (next / previous / jump), repeat / shuffle / prefetch
/// modes.
mixin _PlaylistModule on _PlayerBase {
  /// Appends [media] to the end of the current playlist.
  ///
  /// `media.httpHeaders` ride along as the 4th `loadfile` argument
  /// (mpv 0.38+: `loadfile <url> append -1 <opts>`), so mpv scopes
  /// them as file-local for this exact entry — even if the entry
  /// only loads minutes later when playback advances.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    _validateLoadOptions(media);
    // Snapshot (not bump — appends don't supersede each other) the load
    // epoch: if a content-replacing call (open / stop / clearPlaylist)
    // lands while this append is still resolving its URI, the append is
    // stale and must not graft the old queue's entry onto the new one.
    final load = _snapshotLoad();
    await _gate();
    _mediaCache[media.uri] = media;
    final resolved = _hold(await resolveUri(media.uri));
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    final opts = _buildLoadfileOptions(media);
    if (opts.isEmpty) {
      await _loadfile(['loadfile', resolved.uri, 'append'], media);
    } else {
      await _loadfile(['loadfile', resolved.uri, 'append', '-1', opts], media);
    }
  }

  /// Removes the track at [index] from the playlist.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> remove(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    await _commandChecked(['playlist-remove', index.toString()]);
  }

  /// Skips to the next track and returns `true`, or `false` when there is
  /// none. With [force] `true`, advancing past the last entry stops
  /// playback (mpv's `force` flag); the default (`weak`) does nothing when
  /// the last entry is already playing.
  Future<bool> next({bool force = false}) async {
    await _gate();
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the track change, so they apply to the OLD entry — see [_settleWrites].
    await _settleWrites();
    return _navigate(['playlist-next', force ? 'force' : 'weak']);
  }

  /// Skips to the previous track and returns `true`, or `false` when there
  /// is none. With [force] `true`, going back past the first entry stops
  /// playback; the default (`weak`) does nothing when the first entry is
  /// already playing.
  Future<bool> previous({bool force = false}) async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    return _navigate(['playlist-prev', force ? 'force' : 'weak']);
  }

  /// Jumps to the next entry whose source playlist (`playlist-path`) differs
  /// from the current one — for navigating across concatenated playlists
  /// (e.g. several internet-radio `.m3u` lists appended into one queue).
  /// Returns `false`, doing nothing, when no later entry comes from a
  /// different playlist.
  Future<bool> nextPlaylist() async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    return _navigate(['playlist-next-playlist']);
  }

  /// Jumps to the first of the previous entries whose source playlist
  /// (`playlist-path`) differs from the current one. The reverse of
  /// [nextPlaylist], with the same return value.
  Future<bool> previousPlaylist() async {
    await _gate();
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    return _navigate(['playlist-prev-playlist']);
  }

  /// Jumps to the track at [index] in the playlist and starts playback.
  ///
  /// Writes `pause=no` before issuing the playlist jump (and once more
  /// after it when mpv was parked at the end of content), so the new
  /// track starts playing as soon as `MPV_EVENT_FILE_LOADED` arrives.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> jump(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    // See [next] — in-flight transport writes apply to the old entry.
    await _settleWrites();
    // Optimistic intent, same as play(): this call unpauses, and `pause`
    // is deliberately unobserved, so skipping the write here would leave
    // `state.playWhenReady` (and the OS play/pause button bound to it)
    // stuck on "paused" while audio is audibly playing.
    _updateField(
      (s) => s.copyWith(playWhenReady: true),
      _reactives.playWhenReady,
      true,
    );
    // See [Player.open] — parked at EOF (`keep-open`) the unpause below
    // doesn't survive: the playloop hits EOF again and re-pauses before
    // the jump command is processed. The corrective write after it sticks.
    final parkedAtEof = await _parkedAtEof();
    await _prop('pause', 'no');
    await _commandChecked(['playlist-play-index', index.toString()]);
    if (parkedAtEof) {
      await _prop('pause', 'no');
    }
  }

  /// Moves the track at [from] to position [to].
  ///
  /// Throws [RangeError] if [from] is out of range, or [to] is outside
  /// `0..length` (`length` moves the track to the end).
  Future<void> move(int from, int to) async {
    RangeError.checkNotNegative(from, 'from');
    RangeError.checkNotNegative(to, 'to');
    await _gate();
    final count = await _checkPlaylistIndex(from, 'from');
    if (count == null) return;
    RangeError.checkValueInInterval(to, 0, count, 'to');
    await _commandChecked(['playlist-move', from.toString(), to.toString()]);
  }

  /// Replaces the track at [index] with a new [media] item.
  ///
  /// `media.httpHeaders` ride along as file-local options on the
  /// inserted entry, same as [add] / [Player.open].
  ///
  /// When [index] is the currently-playing entry, the swap is routed
  /// through `playlist-next` so it inherits mpv's prefetch-driven
  /// transition path instead of stopping and restarting playback.
  /// (Audible only with [setPrefetchPlaylist] on, which is off by
  /// default.)
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    RangeError.checkNotNegative(index, 'index');
    _validateLoadOptions(media);
    // Snapshot the load epoch — same staleness rule as [add].
    final load = _snapshotLoad();
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    _mediaCache[media.uri] = media;
    final resolved = _hold(await resolveUri(media.uri));
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    // Execute in-flight transport writes before the playlist surgery —
    // see [_settleWrites].
    await _settleWrites();
    if (load.superseded) return;
    final (posErr, posValue) = await _getAsync(
      'playlist-pos',
      MpvFormat.mpvFormatString,
    );
    if (load.superseded) return;
    final currentPos = posErr < 0
        ? -1
        : (int.tryParse(posValue as String? ?? '') ?? -1);
    final opts = _buildLoadfileOptions(media);
    Future<void> insertAt(int at) {
      if (opts.isEmpty) {
        return _loadfile([
          'loadfile',
          resolved.uri,
          'insert-at',
          at.toString(),
        ], media);
      }
      // 4th-arg options require an explicit index argument (mpv 0.38+).
      return _loadfile([
        'loadfile',
        resolved.uri,
        'insert-at',
        at.toString(),
        opts,
      ], media);
    }

    // Re-check the epoch between each of the multi-command surgeries below:
    // every await now spans an event-isolate reply round-trip, during which a
    // concurrent content-replacing call (stop / open / clearPlaylist) can bump
    // _loadEpoch and own the queue. Without the guard, `playlist-next force`
    // would RESTART playback a concurrent stop() meant to halt, and
    // `playlist-remove` would delete a now-stale index. Bail and let the later
    // call own the surgery, matching the open() family's per-await discipline.
    if (currentPos == index) {
      // Currently-playing entry: insert the replacement right after
      // the active position, then advance — with prefetch on (see
      // [setPrefetchPlaylist]) mpv has the next entry open ahead, so the
      // switch is gapless for typical music files. Finally drop the
      // original.
      await insertAt(index + 1);
      if (load.superseded) return;
      await _commandChecked(['playlist-next', 'force']);
      if (load.superseded) return;
      await _commandChecked(['playlist-remove', index.toString()]);
    } else {
      await _commandChecked(['playlist-remove', index.toString()]);
      if (load.superseded) return;
      await insertAt(index);
    }
  }

  /// Clears the playlist, **including the currently-playing track**.
  /// Playback stops; `state.playlist.items` becomes empty and
  /// `state.playing` becomes `false`. Use [remove] for selective
  /// clearing that keeps the active entry alive.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open()/add()
    // can't repopulate the queue this call is clearing (see [Player.open]).
    final load = _claimLoad();
    await _gate();
    _mediaCache.clear();
    // Execute in-flight transport writes first — see [_settleWrites].
    await _settleWrites();
    if (load.superseded) return;
    // mpv's `playlist-clear` alone keeps the active entry; the
    // explicit `playlist-remove current` makes the call match the
    // method name.
    await _commandChecked(['playlist-clear']);
    if (load.superseded) return;
    // Fails when nothing is current (an idle player): nothing to clear then.
    await _command(['playlist-remove', 'current']);
  }

  /// Sets the playlist repeat mode.
  ///
  /// Backed by two mpv properties (`loop-file` + `loop-playlist`); if
  /// the second write fails the first is rolled back so the consumer
  /// never observes a half-applied loop mode.
  Future<void> setLoop(Loop loop) async {
    await _gate();
    String loopFile(Loop l) => l == Loop.file ? 'inf' : 'no';
    String loopPlaylist(Loop l) => l == Loop.playlist ? 'inf' : 'no';
    final previous = state.loop;
    // Write the option that turns on first: going from file to playlist,
    // `loop-file=no` first would echo a passing Loop.off.
    final writes = [
      ('loop-file', loopFile(loop), loopFile(previous)),
      ('loop-playlist', loopPlaylist(loop), loopPlaylist(previous)),
    ];
    if (loop == Loop.playlist) writes.insert(0, writes.removeAt(1));
    final done = <(String, String, String)>[];
    try {
      for (final w in writes) {
        await _prop(w.$1, w.$2);
        done.add(w);
      }
    } catch (_) {
      for (final (name, _, prior) in done.reversed) {
        await _propRc(name, prior);
      }
      rethrow;
    }
    // Optimistic update — `state.loop` reflects the requested mode
    // without waiting for the two underlying observers to round-trip.
    _updateField((s) => s.copyWith(loop: loop), _loop, loop);
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    await _gate();
    await _prop('shuffle', shuffle ? 'yes' : 'no');
    if (shuffle) {
      await _commandChecked(['playlist-shuffle']);
    } else {
      await _commandChecked(['playlist-unshuffle']);
    }
    _updateField(
      (s) => s.copyWith(shuffle: shuffle),
      _reactives.shuffle,
      shuffle,
    );
  }

  /// Enables or disables background prefetch of the next playlist item.
  ///
  /// When enabled, mpv opens the demuxer for the next track before the
  /// current one finishes, so playback continues without an opening-thread
  /// stall on file boundaries. Observe progress via
  /// [PlayerStream.prefetchState].
  Future<void> setPrefetchPlaylist(bool enabled) async {
    await _gate();
    await _prop('prefetch-playlist', enabled ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(prefetchPlaylist: enabled),
      _reactives.prefetchPlaylist,
      enabled,
    );
  }
}
