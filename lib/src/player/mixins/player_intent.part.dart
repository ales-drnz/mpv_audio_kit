// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// The play-pause intent ([PlayerState.playWhenReady]) across the calls
/// that set it. Each public call claims an epoch
/// ([_PlayerBase._intentEpoch]), so a call that corrects the intent after
/// an await (a failed load, the pause write of a load) leaves it alone
/// once a later call claimed it. The loads in flight
/// ([_PlayerBase._loadsInFlight]) hold back the intent reset of an idle
/// core while they give it content.
extension _IntentAxis on _PlayerBase {
  /// Runs a content-replacing load, counted in [_loadsInFlight].
  Future<void> _trackLoad(Future<void> Function() load) async {
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
    if (_disposed) return;
    final (rc, idle) = await _getAsync(
      'idle-active',
      MpvFormat.mpvFormatString,
    );
    if (!_idleResetPending || _loadsInFlight > 0 || _disposed) return;
    _idleResetPending = false;
    if (rc >= 0 && idle == 'yes') _writeIntent(false);
  }

  /// Sets the play-pause intent for a public call and returns the epoch
  /// that call owns.
  int _claimIntent(bool value) {
    _writeIntent(value);
    return ++_intentEpoch;
  }

  /// Whether a load that claimed [intent] for [shouldPlay] starts playing:
  /// a play() or pause() called after it, while it resolved, has the last
  /// word, so its pause write must not undo theirs.
  bool _intendedPlay(int intent, bool shouldPlay) =>
      intent == _intentEpoch ? shouldPlay : _state.playWhenReady;

  /// Writes the play-pause intent ([PlayerState.playWhenReady]).
  void _writeIntent(bool value) => _updateField(
    (s) => s.copyWith(playWhenReady: value),
    _reactives.playWhenReady,
    value,
  );

  /// Puts back the intent a failed load replaced, unless a later call took
  /// over the load or the intent. Returns whether it did.
  bool _restoreIntent(_LoadTicket load, int intent, bool previous) {
    if (load.superseded || intent != _intentEpoch) return false;
    _writeIntent(previous);
    return true;
  }
}
