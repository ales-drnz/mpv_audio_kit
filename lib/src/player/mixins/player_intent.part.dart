// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The transport axis of a player: the load epoch, the loads in flight,
/// the play-pause intent ([PlayerState.playWhenReady]) across the calls
/// that set it, and the file starts. Its events move counters; the callers
/// read them as before.
///
/// Each content-replacing call claims the load epoch, and every load path
/// checks its [_LoadTicket] after each await. Each public call that sets
/// the intent claims an intent epoch, so a call that corrects the intent
/// after an await (a failed load, the pause write of a load) leaves it
/// alone once a later call claimed it. The loads in flight hold back the
/// intent reset of an idle core while they give it content.
final class _Transport {
  _Transport(this._player);

  final _PlayerBase _player;

  bool _hasLoadedFile = false;
  int _fileStarts = 0;

  // Monotonic generation counter for content-replacing transport calls.
  // Bumped synchronously at the head of open(), openAll(),
  // openPlaylistFile(), stop() and clearPlaylist(); every load path
  // re-checks it after each await and aborts when stale. Without it,
  // per-scheme resolve latencies (asset:// does real I/O, a plain path
  // resolves in one microtask) let an EARLIER call issue its loadfile
  // AFTER a later one: the superseded media would win, and an in-flight
  // open() could resume past a stop() and restart playback.
  int _loadEpoch = 0;

  int _loadsInFlight = 0;

  // mpv went idle while a load was running (openAll steps through idle
  // at the end of the queue), and the intent reset that idle makes waits
  // for the loads to end. Cleared when mpv leaves idle.
  bool _idleResetPending = false;

  // Bumped by every public call that sets the play-pause intent, so a
  // call that corrects the intent after an await can tell whether a later
  // call set it meanwhile (and then leaves it alone).
  int _intentEpoch = 0;

  /// Latched true on the first MPV_EVENT_START_FILE. Gates the idle-active
  /// intent reset and `_settleEndOfContent`: the initial observe burst
  /// delivers `idle-active=true` (the player starts idle) BEFORE any file
  /// load is attempted, and that stale value must not clear a
  /// `playWhenReady` intent set by an open(play: true) that is still
  /// settling. Port delivery is FIFO, so the startup idle-active always
  /// precedes the first START_FILE. Latching on START_FILE (which fires
  /// even for a load that fails to open) rather than FILE_LOADED means a
  /// failed first open() still arms the reset, so its intent doesn't stick
  /// true.
  bool get hasLoadedFile => _hasLoadedFile;

  /// The MPV_EVENT_START_FILE events seen so far. A reply that arrives
  /// after a newer one may describe the file that load opened.
  int get fileStarts => _fileStarts;

  /// How many open(), openAll() and openPlaylistFile() calls are running.
  /// While one is, an idle core is about to get content, so [Player.play]
  /// and the idle-active observer keep the intent.
  int get loadsInFlight => _loadsInFlight;

  /// mpv started a file (MPV_EVENT_START_FILE).
  void onStartFile() {
    _hasLoadedFile = true;
    _fileStarts++;
  }

  /// mpv entered its idle loop ([idle]) or left it.
  void onIdle(bool idle) {
    if (idle) {
      _player._updateLifecycle(playing: false, buffering: false);
      // mpv has entered its idle loop (nothing loaded) → the
      // play-pause intent is spent; settle the OS button on "play".
      // Gated on [hasLoadedFile] so the startup idle-active burst
      // can't clear a fresh open(play: true) intent. mpv reaches idle
      // after a `stop`, or after a load that ends with no next entry
      // and is NOT held by keep-open (e.g. a failed first open). The
      // natural end of playable content under the shipped
      // `keep-open: yes` does NOT fire idle-active; that path is
      // handled by `_settleEndOfContent` instead. A mid-playlist
      // advance also doesn't fire idle-active. While a load runs
      // the idle is its own step (openAll at the end of the queue
      // removes the parked entry before its appends), so the reset
      // waits for the loads to end ([_settleIdleReset]): made
      // now, it flickered the OS button and undid a play() called
      // during the load.
      if (_hasLoadedFile) {
        if (_loadsInFlight > 0) {
          _idleResetPending = true;
        } else {
          writeIntent(false);
        }
        // No file is loaded any more (stop, a cleared playlist, a
        // failed load): nothing of the last one should linger.
        _player._clearFinishedFile();
      }
    } else {
      _idleResetPending = false;
    }
  }

  /// Claims the load epoch for a content-replacing call: every earlier
  /// load in flight is superseded from now on.
  _LoadTicket claimLoad() => _LoadTicket(_player, ++_loadEpoch);

  /// Snapshots the load epoch for a call that adds to the content (an
  /// append): superseded if a content-replacing call lands meanwhile.
  _LoadTicket snapshotLoad() => _LoadTicket(_player, _loadEpoch);

  /// Runs a content-replacing load, counted in [loadsInFlight].
  Future<void> trackLoad(Future<void> Function() load) async {
    _loadsInFlight++;
    try {
      await load();
    } finally {
      _loadsInFlight--;
      if (_loadsInFlight == 0 && _idleResetPending) await _settleIdleReset();
    }
  }

  /// The intent reset left to the end of the loads: still idle with no
  /// load running (one failed, or a later call cleared the playlist),
  /// nothing will play. Read from the core, since the notification that
  /// mpv left idle can come after the loads end.
  Future<void> _settleIdleReset() async {
    if (_player._disposed) return;
    final (rc, idle) = await _player._calls.get(
      'idle-active',
      MpvFormat.mpvFormatString,
    );
    if (!_idleResetPending || _loadsInFlight > 0 || _player._disposed) return;
    _idleResetPending = false;
    if (rc >= 0 && idle == 'yes') writeIntent(false);
  }

  /// Sets the play-pause intent for a public call and returns the epoch
  /// that call owns.
  int claimIntent(bool value) {
    writeIntent(value);
    return ++_intentEpoch;
  }

  /// Whether the call that claimed [intent] still owns the intent: no
  /// later call set it.
  bool owns(int intent) => intent == _intentEpoch;

  /// Whether a load that claimed [intent] for [shouldPlay] starts playing:
  /// a play() or pause() called after it, while it resolved, has the last
  /// word, so its pause write must not undo theirs.
  bool intendedPlay(int intent, bool shouldPlay) =>
      intent == _intentEpoch ? shouldPlay : _player._state.playWhenReady;

  /// Writes the play-pause intent ([PlayerState.playWhenReady]).
  void writeIntent(bool value) => _player._updateField(
    (s) => s.copyWith(playWhenReady: value),
    _player._reactives.playWhenReady,
    value,
  );

  /// Puts back the intent a failed load replaced, unless a later call took
  /// over the load or the intent. Returns whether it did.
  bool restoreIntent(_LoadTicket load, int intent, bool previous) {
    if (load.superseded || intent != _intentEpoch) return false;
    writeIntent(previous);
    return true;
  }
}

/// A load-path call's view of the load epoch, taken with
/// [_Transport.claimLoad] or [_Transport.snapshotLoad].
final class _LoadTicket {
  _LoadTicket(this._player, this._epoch);

  final _PlayerBase _player;
  final int _epoch;

  /// Whether the player was disposed, or a later content-replacing call
  /// took over, since the ticket was taken. Re-check after every await.
  bool get superseded =>
      _player._disposed || _player._transport._loadEpoch != _epoch;
}
