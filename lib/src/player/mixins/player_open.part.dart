// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// How many `loadfile append` requests [Player.openAll] has in flight at
/// most: well under the 1000 replies mpv queues per client, so the appends
/// leave room for the events and the other calls.
const _kAppendWindow = 512;

/// The loads that replace the content: [Player.open], [Player.openAll] and
/// [Player.openPlaylistFile], with the entry bookkeeping of [Player.openAll]
/// (the old entry it keeps in mpv until its jump, hidden from the state
/// through [EntryTable.retained]). [Player] keeps the public methods and
/// their contract; the bodies run here.
mixin _OpenModule on _PlayerBase, _FfiModule {
  Future<void> _open(Media media, bool? play) async {
    _checkNotDisposed();
    _validateLoadOptions(media);
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent (the play-pause axis), written at the call point,
    // BEFORE the `resolveUri` and trust-bundle awaits below, so a play() or
    // pause() issued right after open() (without awaiting it) wins by call
    // order instead of racing this write past the I/O hops. mpv leaves
    // `pause` at `no` and fires no PROPERTY_CHANGE on the first autoplay
    // load, so the observer alone would never surface this intent.
    final previousIntent = _state.playback.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _mediaCache.clear();
    _resolvedKeys.clear();
    _mediaCache[media.uri] = media;
    final OwnedSource source;
    try {
      source = OwnedSource(await resolveUri(media.uri));
    } catch (_) {
      // Nothing was loaded: the intent goes back to what still plays.
      _transport.restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Released on every way out unless mpv took the entry: a later load,
    // an error, a refusal.
    try {
      if (load.superseded) return;
      _mediaCache[source.uri] = media;
      await _forgetFdResume(source.uri);
      // Execute in-flight transport writes (e.g. an un-awaited seek) before
      // the replace below, so they apply to the OLD file; see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // Captured BEFORE the pause write: when true, mpv is parked paused on
      // the last frame (`keep-open`), and the pre-loadfile `pause=no` below
      // does not survive: unpausing at EOF makes the playloop hit EOF again
      // and `keep-open-pause` re-pauses the core before the loadfile (queued
      // behind this write's async reply round-trip) is ever processed. The
      // corrective write after the replace is what actually sticks.
      final parkedAtEof = await _parkedAtEof();
      if (load.superseded) return;
      final playNow = _transport.intendedPlay(intent, shouldPlay);
      await _calls.prop('pause', playNow ? 'no' : 'yes');
      final opts = _buildLoadfileOptions(media);
      try {
        if (opts.isEmpty) {
          await _loadfile(['loadfile', source.uri, 'replace'], media, source);
        } else {
          // Per-Media `httpHeaders` and `httpChunkSize` ride along as the 4th
          // `loadfile` arg (mpv 0.38+: index must be `-1` when options are
          // present), so mpv scopes them as file-local for this exact
          // playlist entry, never writing the global `http-header-fields` or
          // `stream-lavf-o`.
          await _loadfile(
            ['loadfile', source.uri, 'replace', '-1', opts],
            media,
            source,
          );
        }
      } catch (_) {
        // mpv refused the entry and kept what it had: nothing will ever read
        // the source, and the track there goes on with its own intent and
        // pause, as after a failed [openPlaylistFile].
        if (_transport.restoreIntent(load, intent, previousIntent) &&
            playNow != previousIntent) {
          await _calls.propRc('pause', previousIntent ? 'no' : 'yes');
        }
        rethrow;
      }
      // The replace leaves the park of the old file: its START_FILE is
      // queued behind this reply, and can reach the player after the load
      // ends. A park of the old file reached while this load ran keeps the
      // intent (see [TransportMachine.park]).
      _transport.takePark();
      // Asked again, not reused: a pause() called while the loadfile was in
      // flight has the last word.
      if (parkedAtEof && _transport.intendedPlay(intent, shouldPlay)) {
        await _calls.prop('pause', 'no');
      }
      // Drop visible per-track state (cover art, chapter list and current
      // chapter index) so a UI that reads the state immediately after
      // `open()` returns doesn't render the previous track's data. Placed
      // AFTER the loadfile reply (not before): the async writes above
      // suspend, and by FIFO port delivery every still-queued OLD-file
      // PROPERTY_CHANGE (e.g. a trailing `chapter-list`) has been received
      // and applied by the time that reply lands: clearing here is the last
      // word before return, so none of those stale events survive into the
      // post-`open()` snapshot. The NEW file's FILE_LOADED arrives later and
      // repopulates.
      _clearPerFileState();
    } finally {
      await source.release();
    }
  }

  Future<void> _openAll(List<Media> requested, bool? play, int index) async {
    _checkNotDisposed();
    // A copy: the list is read across many awaits, and the caller's may
    // change meanwhile.
    final medias = List<Media>.of(requested, growable: false);
    if (medias.isEmpty) {
      return;
    }
    // Validate the full batch before any side-effect, so a bad header
    // on entry N can't leave entries 0..N-1 half-loaded.
    for (final m in medias) {
      _validateLoadOptions(m);
    }
    // Claim the load epoch synchronously; see [Player.open].
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point, before the resolve and tls
    // awaits below; see [Player.open] for the rationale.
    final previousIntent = _state.playback.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _keepOutgoingMedia();
    // Resolved once per media ([_resolveAll]). Each source is released on
    // every way out unless mpv took its entry.
    final sources = <OwnedSource>[];
    // The old entry kept in mpv until phase 4, hidden from the state once
    // the jump moved past it.
    int? retainedId;
    try {
      try {
        if (!await _resolveAll(medias, sources, load)) return;
      } catch (_) {
        // Mid-loop failure: the caller observes the original error, and the
        // sources resolved so far are released on the way out.
        _transport.restoreIntent(load, intent, previousIntent);
        rethrow;
      }
      // Execute in-flight transport writes before the replace: see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // ── Phase 1: clear the outgoing playlist ──────────────────────────
      final retainedOld = await _openAllClear(load);
      if (retainedOld == null) return;
      retainedId = await _holdRetained(retainedOld);

      // ── Phase 2: append every entry; playback never starts here ──────
      final failure = await _openAllAppend(medias, sources, load);
      // mpv never had the refused entries, nor the ones not sent after a
      // refusal or a later load: their sources are released on the way out.
      if (failure != null) {
        // mpv turns an append down only when its reply queue is full.
        // The call fails as a whole: the entries that went in come out
        // again. `playlist-clear` keeps only the current entry, the track
        // that still plays (none at the park, removed above). The pause was
        // not written yet, so only the intent goes back. A later load owns
        // the playlist instead, and the entries mpv took stay with
        // [_entries] until they leave.
        if (!load.superseded) {
          _transport.restoreIntent(load, intent, previousIntent);
          await _calls.command(['playlist-clear']);
        }
        Error.throwWithStackTrace(failure.$1, failure.$2);
      }
      // From here on mpv has the entries, and may read them again until it
      // leaves them (a previous, a loop, a prefetch): their sources stay with
      // [_entries], which releases each one once it left the playlist and
      // mpv moved on. Released now, an Android descriptor would go to the
      // next file the app opens while mpv still lists its number.
      if (load.superseded) return;

      // ── Phases 3 and 4: the jump, then the retained entry leaves ────
      final played = await _openAllPlay(
        load,
        playNow: _transport.intendedPlay(intent, shouldPlay),
        retainedOld: retainedOld,
        index: clampedIndex,
      );
      if (!played) return;
      _forgetRetained(retainedId);
      // Clear per-track state AFTER the jump's reply; see [Player.open] for
      // why the placement (post-reply) is what makes the clear the last
      // word over trailing OLD-file PROPERTY_CHANGE events.
      _clearPerFileState();
    } finally {
      _forgetRetained(retainedId);
      for (final source in sources) {
        await source.release();
      }
    }
  }

  /// Keeps the [Media] of the outgoing current entry in the cache, so it
  /// keeps its metadata while still visible in playlist events during the
  /// transition of an [Player.openAll] (retained until the post-jump
  /// remove).
  void _keepOutgoingMedia() {
    final old = _state.playback.playlist;
    final index = old.index;
    _mediaCache.clear();
    _resolvedKeys.clear();
    if (index < 0 || index >= old.items.length) return;
    final current = old.items[index];
    _mediaCache[current.uri] = current;
  }

  /// Resolves [medias] into [sources], one source per media: content://
  /// resolutions detach a JVM-side FD, doing it twice would leak one FD
  /// per track. Returns `false` once a later load took over.
  Future<bool> _resolveAll(
    List<Media> medias,
    List<OwnedSource> sources,
    _LoadTicket load,
  ) async {
    for (final m in medias) {
      _mediaCache[m.uri] = m;
      final source = OwnedSource(await resolveUri(m.uri));
      sources.add(source);
      if (load.superseded) return false;
      _mediaCache[source.uri] = m;
      await _forgetFdResume(source.uri);
    }
    return true;
  }

  /// Phases 3 and 4 of [Player.openAll]: the pause from [playNow], the
  /// jump to entry [index] of the new list, and the removal of the old
  /// entry when [retainedOld] kept it at position 0. Returns `false` when
  /// a later load took over before the removal.
  Future<bool> _openAllPlay(
    _LoadTicket load, {
    required bool playNow,
    required bool retainedOld,
    required int index,
  }) async {
    // ── Phase 3: intent, then one direct jump to the target ───────────
    // The pause write cannot be fought by keep-open here: the parked
    // flow already left EOF (idle after the remove above), and the
    // playing flow is mid-track. `playlist-play-index` sets
    // playlist->current straight to the target entry (mp_set_playlist_
    // entry): entries before it are never loaded or made current.
    await _calls.prop('pause', playNow ? 'no' : 'yes');
    final target = (retainedOld ? 1 : 0) + index;
    // The parked flow went through idle, which does not spend the intent
    // while this call runs: see the idle-active observer.
    await _calls.commandChecked(['playlist-play-index', target.toString()]);
    // The jump leaves the park, as the replace of [Player.open] does.
    _transport.takePark();

    // ── Phase 4: drop the retained old entry ──────────────────────────
    // Non-current by now (the jump moved current to the target), so the
    // removal is pure bookkeeping; indices shift down to their final
    // positions. Tolerant [CoreCalls.command]: a concurrent surgery that
    // already emptied position 0 must not surface as an openAll error.
    if (retainedOld) {
      // The target plays from its source now: see the check after phase 2.
      if (load.superseded) return false;
      await debugBeforeRetainedRemove?.call();
      await _calls.command(['playlist-remove', '0']);
    }
    return true;
  }

  /// Hides from the state the old entry an [Player.openAll] [kept] in
  /// mpv, once its jump moved past it ([EntryTable.retained]). Returns its
  /// id, `null` when none was kept. A later load that took over meanwhile ends the
  /// call before its jump, and the call's `finally` ends the hiding.
  Future<int?> _holdRetained(bool kept) async {
    _entries.retained = null;
    if (!kept) return null;
    return _entries.retained = int.tryParse(
      await _readString('playlist/0/id') ?? '',
    );
  }

  /// Ends the hiding of the old entry [id] of an [Player.openAll]: removed,
  /// or left to a later load. Another openAll's entry stays hidden.
  void _forgetRetained(int? id) {
    if (id == null || _entries.retained != id) return;
    _entries
      ..retained = null
      ..hiddenAt = null;
  }

  /// Phase 1 of [Player.openAll]: clears the outgoing playlist. Returns
  /// whether an old entry still occupies position 0 (the playing flow): the
  /// append targets shift by one until the post-jump remove drops it.
  /// `null` once a later load took over.
  Future<bool?> _openAllClear(_LoadTicket load) async {
    // `playlist-clear` keeps ONLY the current entry (mpv's
    // playlist_clear_except_current), so the outgoing track keeps
    // playing while the new entries build up: no idle gap, no silence.
    // The flow is decided from mpv's own properties AFTER the clear
    // (`playlist-count`, `eof-reached`), not from the Dart-side state
    // snapshot: state can lag the core by an event round-trip, and a
    // wrong guess here would offset every append target below.
    await _calls.command(['playlist-clear']);
    if (load.superseded) return null;
    final retainedCount =
        int.tryParse(await _readString('playlist-count') ?? '') ?? 0;
    if (load.superseded) return null;
    var parkedAtEof = false;
    if (retainedCount > 0) {
      // A retained entry parked at EOF cannot survive the appends:
      // `keep-open` holds the park only while no next entry exists (mpv's
      // handle_keep_open), so the first append would create a "next" and
      // mpv would auto-advance into the new album's entry 0,
      // resurrecting the exact transient this flow eliminates. Remove it
      // NOW instead: the playlist is single-entry after the clear, so
      // PT_NEXT_ENTRY finds nothing and the core goes idle, where
      // appends provably never autostart.
      parkedAtEof = await _parkedAtEof();
      if (load.superseded) return null;
      if (parkedAtEof) {
        await _calls.command(['playlist-remove', '0']);
        if (load.superseded) return null;
        // Barrier: wait for the core to actually reach idle before any
        // append. The remove's playback teardown runs asynchronously on
        // the playloop, and an append landing before it completes gets
        // picked up by the end-of-file advancement (playlist_get_next
        // from a NULL current with the playlist not started returns
        // entry 0), which would start the incoming album's first track:
        // the exact transient this flow eliminates. Idle lands within a
        // playloop iteration; the bound only guards a wedged core.
        var idle = false;
        for (var i = 0; i < 100; i++) {
          idle = await _readString('idle-active') == 'yes';
          if (load.superseded) return null;
          if (idle) break;
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
        if (load.superseded) return null;
        if (!idle) {
          _internalLog(
            'openAll: the core did not reach idle after the removal of the '
            'parked entry; the first new entry may start before the jump',
            level: LogLevel.warn,
          );
        }
      }
    }
    return retainedCount > 0 && !parkedAtEof;
  }

  /// Phase 2 of [Player.openAll]: appends [medias] from their [sources].
  /// Returns the first refusal, `null` when mpv took every entry sent;
  /// sending stops at a refusal or once a later load took over.
  Future<(Object, StackTrace)?> _openAllAppend(
    List<Media> medias,
    List<OwnedSource> sources,
    _LoadTicket load,
  ) async {
    // mpv's `loadfile append` is play=false unconditionally (unlike
    // append-play), even on an idle core. Per-Media `httpHeaders` ride
    // along as the 4th `loadfile` arg, so mpv scopes them as file-local
    // without ever writing the global `http-header-fields` option.
    // The appends go out in windows of [_kAppendWindow], each sent at once:
    // mpv runs them in order, and the playlist changes they cause fold into
    // a few notifications. Awaited one by one, every append made mpv report
    // the whole playlist again, which grew with the square of the album
    // size. Each append holds one of the 1000 reply slots mpv keeps per
    // client until its reply is read, and a full queue refuses the next
    // request: a window waits for its replies before the next goes out.
    final appended = <int>{};
    (Object, StackTrace)? failure;
    var sent = 0;
    while (sent < medias.length && failure == null && !load.superseded) {
      final end = sent + _kAppendWindow < medias.length
          ? sent + _kAppendWindow
          : medias.length;
      // A refused append fails at once, before the loop below awaits it:
      // marked handled here, so its error reaches that loop instead of
      // surfacing as unhandled.
      final window = <Future<int?>>[
        for (var i = sent; i < end; i++)
          _loadfileEntry(
            switch (_buildLoadfileOptions(medias[i])) {
              '' => ['loadfile', sources[i].uri, 'append'],
              final opts => ['loadfile', sources[i].uri, 'append', '-1', opts],
            },
            medias[i],
            sources[i],
          )..ignore(),
      ];
      for (var j = 0; j < window.length; j++) {
        try {
          final id = await window[j];
          if (id != null) appended.add(id);
        } catch (e, st) {
          failure ??= (e, st);
        }
      }
      sent = end;
    }
    if (appended.isNotEmpty) _remapReported(appended);
    return failure;
  }

  Future<void> _openPlaylistFile(Media playlist, bool? play) async {
    _checkNotDisposed();
    _rejectPcm(playlist, 'playlist');
    _validateLoadOptions(playlist);
    // Claim the load epoch synchronously; see [Player.open].
    final load = _transport.claimLoad();
    await _gate();
    if (load.superseded) return;
    final shouldPlay = play ?? configuration.autoPlay;
    // Optimistic intent written at the call point: same rationale as
    // [Player.open].
    final previousIntent = _state.playback.playWhenReady;
    final intent = _transport.claimIntent(shouldPlay);
    _mediaCache.clear();
    _resolvedKeys.clear();
    final OwnedSource source;
    try {
      source = OwnedSource(await resolveUri(playlist.uri));
    } catch (_) {
      _transport.restoreIntent(load, intent, previousIntent);
      rethrow;
    }
    // Never handed over: mpv reads the list inside the command, and its
    // entries are the playlist, so nothing reads the list itself again.
    // Released on every way out.
    try {
      if (load.superseded) return;
      // Execute in-flight transport writes before the replace: see
      // [CoreCalls.settleWrites].
      await _calls.settleWrites();
      if (load.superseded) return;
      // See [Player.open]: parked at EOF the pre-loadlist unpause doesn't
      // survive mpv's keep-open re-pause; a corrective write after the
      // replace does.
      final parkedAtEof = await _parkedAtEof();
      if (load.superseded) return;
      final playNow = _transport.intendedPlay(intent, shouldPlay);
      await _calls.prop('pause', playNow ? 'no' : 'yes');
      try {
        await _calls.commandChecked(['loadlist', source.uri, 'replace']);
      } catch (_) {
        // mpv keeps the playlist it had when the list cannot be read, and
        // the track there goes on: the intent and the pause written above
        // go back to what they were, unless a later call took them over.
        // Tolerant write, so the error the caller sees is the loadlist one.
        if (_transport.restoreIntent(load, intent, previousIntent) &&
            playNow != previousIntent) {
          await _calls.propRc('pause', previousIntent ? 'no' : 'yes');
        }
        rethrow;
      }
      // See [Player.open]: the replace leaves the park.
      _transport.takePark();
      // See [Player.open]: asked again, a pause() during the loadlist wins.
      if (parkedAtEof && _transport.intendedPlay(intent, shouldPlay)) {
        await _calls.prop('pause', 'no');
      }
      // Clear per-track state AFTER the replace's reply; see [Player.open].
      _clearPerFileState();
    } finally {
      await source.release();
    }
  }
}
