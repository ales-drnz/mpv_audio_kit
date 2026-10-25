// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Playlist setters: queue mutation (add, remove, move, replace),
/// navigation (next, previous, jump), and the repeat, shuffle and
/// prefetch modes.
mixin _PlaylistModule on _PlayerBase {
  /// Appends [media] to the end of the current playlist.
  ///
  /// `media.httpHeaders` ride along as the 4th `loadfile` argument
  /// (mpv 0.38+: `loadfile <url> append -1 <opts>`), so mpv scopes
  /// them as file-local for this exact entry, even if the entry
  /// only loads minutes later when playback advances.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    _validateLoadOptions(media);
    // Snapshot (not bump: appends don't supersede each other) the load
    // epoch: if a content-replacing call (open, stop, clearPlaylist)
    // lands while this append is still resolving its URI, the append is
    // stale and must not graft the old queue's entry onto the new one.
    final load = _transport.snapshotLoad();
    await _gate();
    await _addEntry(media, load);
  }

  /// Inserts [media] at [index] in the playlist: the entry there and the
  /// ones after it move down by one, and [index] equal to the playlist
  /// length appends, as [add] does. The current entry keeps playing.
  ///
  /// The per-entry options of [media] ride along as in [add]. To play it
  /// next, pass `state.playlist.index + 1`.
  ///
  /// Throws [RangeError] if [index] is outside `0..length`.
  Future<void> insert(int index, Media media) async {
    _checkNotDisposed();
    RangeError.checkNotNegative(index, 'index');
    _validateLoadOptions(media);
    // The same staleness rule as [add].
    final load = _transport.snapshotLoad();
    await _gate();
    // mpv's own count, as in [move]: the state can lag an add in flight.
    final (rc, count) = await _calls.get(
      'playlist-count',
      MpvFormat.mpvFormatInt64,
    );
    if (_disposed) return;
    RangeError.checkValueInInterval(
      index,
      0,
      rc < 0 ? 0 : count as int,
      'index',
    );
    await _addEntry(media, load, at: index);
  }

  /// The load of [add] and [insert]: resolves [media] and appends it, or
  /// inserts it at [at]. An index past the end, after a concurrent remove,
  /// appends in mpv.
  Future<void> _addEntry(Media media, _LoadTicket load, {int? at}) async {
    _mediaCache[media.uri] = media;
    final source = OwnedSource(await resolveUri(media.uri));
    // Released on every way out unless mpv took the entry: a later load,
    // or a refusal, after which nothing will ever read the source.
    try {
      if (load.superseded) return;
      _mediaCache[source.uri] = media;
      await _forgetFdResume(source.uri);
      final opts = _buildLoadfileOptions(media);
      await _loadfile(
        [
          'loadfile',
          source.uri,
          if (at == null) 'append' else 'insert-at',
          // The options need the index argument (mpv 0.38+), -1 to append.
          if (at != null) '$at' else if (opts.isNotEmpty) '-1',
          if (opts.isNotEmpty) opts,
        ],
        media,
        source,
      );
    } finally {
      await source.release();
    }
  }

  /// Throws [RangeError] unless [index] is a valid playlist position, per
  /// mpv's own `playlist-count` (the Dart state can lag behind an `add`
  /// still in flight). Returns the count, or `null` when a dispose landed
  /// meanwhile: it drained the read as failed, and the call then ends
  /// without effect, like any call under way at dispose, instead of
  /// reporting an index out of an empty playlist.
  Future<int?> _checkPlaylistIndex(int index, String name) async {
    final (rc, value) = await _calls.get(
      'playlist-count',
      MpvFormat.mpvFormatInt64,
    );
    if (_disposed) return null;
    final count = rc < 0 ? 0 : value as int;
    RangeError.checkValidIndex(index, null, name, count);
    return count;
  }

  /// Removes the track at [index] from the playlist.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> remove(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    await _calls.commandChecked(['playlist-remove', index.toString()]);
  }

  /// Skips to the next track and returns `true`, or `false` when there is
  /// none. With [force] `true`, advancing past the last entry stops
  /// playback (mpv's `force` flag); the default (`weak`) does nothing when
  /// the last entry is already playing.
  Future<bool> next({bool force = false}) async {
    await _gate();
    // Execute in-flight transport writes (e.g. an un-awaited seek) before
    // the track change, so they apply to the OLD entry; see
    // [CoreCalls.settleWrites].
    await _calls.settleWrites();
    return _calls.navigate(['playlist-next', force ? 'force' : 'weak']);
  }

  /// Skips to the previous track and returns `true`, or `false` when there
  /// is none. With [force] `true`, going back past the first entry stops
  /// playback; the default (`weak`) does nothing when the first entry is
  /// already playing.
  Future<bool> previous({bool force = false}) async {
    await _gate();
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    return _calls.navigate(['playlist-prev', force ? 'force' : 'weak']);
  }

  /// Jumps to the next entry whose source playlist (`playlist-path`) differs
  /// from the current one, for navigating across concatenated playlists
  /// (e.g. several internet-radio `.m3u` lists appended into one queue).
  /// Returns `false`, doing nothing, when no later entry comes from a
  /// different playlist.
  Future<bool> nextPlaylist() async {
    await _gate();
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    return _calls.navigate(['playlist-next-playlist']);
  }

  /// Jumps to the first of the previous entries whose source playlist
  /// (`playlist-path`) differs from the current one. The reverse of
  /// [nextPlaylist], with the same return value.
  ///
  /// On Windows it needs the libmpv this package bundles, or one built
  /// with the patches of libmpv-scripts 0.1.7 or later: an unpatched mpv
  /// can corrupt its heap in `playlist-prev-playlist` and crash the
  /// process.
  Future<bool> previousPlaylist() async {
    await _gate();
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    return _calls.navigate(['playlist-prev-playlist']);
  }

  /// Jumps to the track at [index] in the playlist and starts playback.
  ///
  /// Writes `pause=no` before issuing the playlist jump (and once more
  /// after it when mpv was parked at the end of content), so the new
  /// track starts playing as soon as `MPV_EVENT_FILE_LOADED` arrives. A
  /// [pause] called after it has the last word: the track then loads
  /// paused.
  ///
  /// Throws [RangeError] if [index] is out of range.
  Future<void> jump(int index) async {
    RangeError.checkNotNegative(index, 'index');
    await _gate();
    // Optimistic intent, same as play(), claimed at the call so that the
    // call order decides: this call unpauses, and `pause` is deliberately
    // unobserved, so skipping the write here would leave
    // `state.playWhenReady` (and the OS play-pause button bound to it)
    // stuck on "paused" while audio is audibly playing.
    final previous = _state.playWhenReady;
    final intent = _transport.claimIntent(true);
    try {
      if (await _checkPlaylistIndex(index, 'index') == null) return;
    } catch (_) {
      // Out of range: nothing moved, so the intent goes back.
      if (_transport.owns(intent)) _transport.writeIntent(previous);
      rethrow;
    }
    // See [next]: in-flight transport writes apply to the old entry.
    await _calls.settleWrites();
    // See [Player.open]: parked at EOF (`keep-open`) the unpause below
    // doesn't survive: the playloop hits EOF again and re-pauses before
    // the jump command is processed. The corrective write after it sticks.
    final parkedAtEof = await _parkedAtEof();
    await _calls.prop(
      'pause',
      _transport.intendedPlay(intent, true) ? 'no' : 'yes',
    );
    await _calls.commandChecked(['playlist-play-index', index.toString()]);
    if (parkedAtEof && _transport.intendedPlay(intent, true)) {
      await _calls.prop('pause', 'no');
    }
    // A park read on its way when this call began clears the intent on
    // arrival, as in [play]: set again while this call still owns it.
    if (_transport.owns(intent)) _transport.writeIntent(true);
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
    await _calls.commandChecked([
      'playlist-move',
      from.toString(),
      to.toString(),
    ]);
  }

  /// Replaces the track at [index] with a new [media] item.
  ///
  /// `media.httpHeaders` ride along as file-local options on the
  /// inserted entry, same as [add] and [Player.open].
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
    // Snapshot the load epoch: same staleness rule as [add].
    final load = _transport.snapshotLoad();
    await _gate();
    if (await _checkPlaylistIndex(index, 'index') == null) return;
    _mediaCache[media.uri] = media;
    final source = OwnedSource(await resolveUri(media.uri));
    // Until mpv takes the entry its source is this call's to release, on
    // every way out: a later load, a command that fails. Once taken, it
    // stays with [_entries] while mpv lists it.
    try {
      if (load.superseded) return;
      _mediaCache[source.uri] = media;
      await _forgetFdResume(source.uri);
      // Execute in-flight transport writes before the playlist surgery:
      // see [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      final (posErr, posValue) = await _calls.get(
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
          return _loadfile(
            ['loadfile', source.uri, 'insert-at', at.toString()],
            media,
            source,
          );
        }
        // 4th-arg options require an explicit index argument (mpv 0.38+).
        return _loadfile(
          ['loadfile', source.uri, 'insert-at', at.toString(), opts],
          media,
          source,
        );
      }

      // Re-check the epoch between each of the multi-command surgeries
      // below: every await now spans an event-isolate reply round-trip,
      // during which a concurrent content-replacing call (stop, open,
      // clearPlaylist) can claim the load epoch and own the queue. Without the
      // guard, `playlist-next force` would RESTART playback a concurrent
      // stop() meant to halt, and `playlist-remove` would delete a now-stale
      // index. Bail and let the later call own the surgery, matching the
      // open() family's per-await discipline.
      if (currentPos == index) {
        // Currently-playing entry: insert the replacement right after
        // the active position, then advance: with prefetch on (see
        // [setPrefetchPlaylist]) mpv has the next entry open ahead, so the
        // switch is gapless for typical music files. Finally drop the
        // original.
        await insertAt(index + 1);
        if (load.superseded) return;
        await _calls.commandChecked(['playlist-next', 'force']);
        if (load.superseded) return;
        await _calls.commandChecked(['playlist-remove', index.toString()]);
      } else {
        await _calls.commandChecked(['playlist-remove', index.toString()]);
        if (load.superseded) return;
        await insertAt(index);
      }
    } finally {
      await source.release();
    }
  }

  /// Clears the playlist, **including the currently-playing track**.
  /// Playback stops; `state.playlist.items` becomes empty and
  /// `state.playing` becomes `false`. Use [remove] for selective
  /// clearing that keeps the active entry alive.
  ///
  /// With [keepCurrent] true only the other entries go: the current one
  /// keeps playing as the only entry. With nothing current, both forms
  /// empty the playlist. Either way an open, openAll or add still
  /// resolving its source when this is called does not load.
  Future<void> clearPlaylist({bool keepCurrent = false}) async {
    _checkNotDisposed();
    // Claim the load epoch synchronously so an in-flight open()/add()
    // can't repopulate the queue this call is clearing (see [Player.open]).
    final load = _transport.claimLoad();
    await _gate();
    // The kept entry keeps its Media, under every URI it is cached by: the
    // source resolver looks it up there when the entry loads again (a
    // playlist loop).
    final playlist = _state.playlist;
    final current = keepCurrent && playlist.index >= 0
        ? playlist.items.elementAtOrNull(playlist.index)
        : null;
    _mediaCache.removeWhere((_, media) => current == null || media != current);
    // Execute in-flight transport writes first; see [CoreCalls.settleWrites].
    await _calls.settleWrites();
    if (load.superseded) return;
    // mpv's `playlist-clear` alone keeps the active entry; the
    // explicit `playlist-remove current` makes the call match the
    // method name.
    await _calls.commandChecked(['playlist-clear']);
    if (load.superseded || keepCurrent) return;
    // Fails when nothing is current (an idle player): nothing to clear then.
    await _calls.command(['playlist-remove', 'current']);
  }

  /// Sets the playlist repeat mode.
  ///
  /// Backed by two mpv properties (`loop-file` + `loop-playlist`); if
  /// the second write fails the first is rolled back so the consumer
  /// never observes a half-applied loop mode.
  ///
  /// Turned on once the queue has ended ([PlayerState.completed]), a loop
  /// rewinds: [Loop.file] seeks the track to its start, [Loop.playlist]
  /// moves to the first entry, and both stay paused, since the play
  /// intent was spent at the end. Call [Player.play] to start again.
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
        await _calls.prop(w.$1, w.$2);
        done.add(w);
      }
    } catch (_) {
      for (final (name, _, prior) in done.reversed) {
        await _calls.propRc(name, prior);
      }
      rethrow;
    }
    // Optimistic update: `state.loop` reflects the requested mode
    // without waiting for the two underlying observers to round-trip.
    _updateField((s) => s.copyWith(loop: loop), _loop, loop);
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    await _gate();
    await _calls.prop('shuffle', shuffle ? 'yes' : 'no');
    if (shuffle) {
      await _calls.commandChecked(['playlist-shuffle']);
    } else {
      await _calls.commandChecked(['playlist-unshuffle']);
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
  ///
  /// The `on_load` hook, and with it the source resolver, runs for the
  /// next entry while the current one plays. Until it continues, mpv
  /// stops feeding the playing entry: a resolver or hook listener slower
  /// than the output buffer leaves a gap in the playing track. A hook of
  /// [Player.registerHook] runs once more when the entry starts, and a
  /// `file-local-options` write in its first run lands on the playing
  /// entry. The source resolver is not asked again then: the entry opens
  /// with the URL it gave for the prefetch.
  ///
  /// Some entries open when they start, not from the prefetch:
  /// - an entry whose [Media] options (headers, chunk size, demuxer
  ///   options, start, end) differ from the playing entry's;
  /// - an entry with [Media.demuxerLavfOptions], and the entry after it;
  /// - a live [PcmSource] entry, and the entry after it.
  Future<void> setPrefetchPlaylist(bool enabled) async {
    await _gate();
    await _calls.prop('prefetch-playlist', enabled ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(prefetchPlaylist: enabled),
      _reactives.prefetchPlaylist,
      enabled,
    );
  }
}
