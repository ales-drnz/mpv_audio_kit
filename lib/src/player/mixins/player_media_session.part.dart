// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Media-session setter: publishes the [Player] to the OS lockscreen,
/// SMTC or MPRIS entry, wires Bluetooth AVRCP and headset buttons, and
/// (when enabled) integrates with the platform's audio-session
/// lifecycle for phone-call, Siri and navigation auto-pause.
///
/// Pass `null` to disable. Only one [Player] per process can hold the
/// session; see [Player._mediaSessionOwner]. `dispose()` releases the
/// session automatically before tearing down libmpv.
///
/// Lifecycle:
/// - First non-null call: registers the static guard, allocates a
///   [MediaSessionController] that pushes state to the native side
///   and listens for inbound OS commands.
/// - Subsequent non-null calls: reconfigure (controller stays alive,
///   the new config flows through `state.mediaSession` → stream →
///   controller).
/// - `null` call: tears the controller down, clears the static guard.
///
/// Inbound commands are auto-applied to the [Player] (play → play(),
/// seek → seek(), …) AND emitted on
/// [PlayerStream.mediaSessionCommands] for analytics or interception.
/// `next` and `previous` are routed to mpv's playlist when one is
/// loaded; otherwise they only emit on the consumer stream so the
/// app's queue logic can react.
mixin _MediaSessionModule on _PlayerBase {
  /// Publishes the [Player] to the OS media session, or removes it when
  /// [session] is `null`. Only one [Player] per process can have an
  /// active session: a non-null [session] on a second [Player] throws
  /// [StateError].
  ///
  /// The session needs the root isolate, the one the OS sends its commands
  /// to: a non-null [session] on a [Player] of another isolate throws
  /// [StateError].
  Future<void> setMediaSession(MediaSession? session) async {
    _checkNotDisposed();

    // 1. Root isolate only: platform messages reach no other isolate, and
    //    the channels of a background isolate fail. `null` is allowed
    //    anywhere, as there is nothing to undo.
    if (session != null && RootIsolateToken.instance == null) {
      throw StateError(
        'setMediaSession needs the root isolate: the OS media session '
        'sends its commands only there. Publish from a Player created in '
        'the root isolate.',
      );
    }

    // 2. Single-instance guard.
    if (session != null) {
      final owner = Player._mediaSessionOwner;
      if (owner != null && !identical(owner, this)) {
        throw StateError(
          'Another Player instance already owns the OS media session. '
          'SMTC (Windows) and MPNowPlayingInfoCenter (Apple) are '
          'single-instance per process, so only one Player can publish '
          'to the lockscreen at a time. Disable the existing session '
          'with `setMediaSession(null)` on the other Player before '
          'enabling this one.',
        );
      }
      Player._mediaSessionOwner = this as Player;
    } else if (identical(Player._mediaSessionOwner, this)) {
      Player._mediaSessionOwner = null;
    }

    // 3. Update state synchronously (optimistic). The controller's
    //    own subscription to `stream.mediaSession` will pick up the
    //    config change and push it to native via `updateConfig`.
    _updateField(
      (s) => s.copyWith(mediaSession: session),
      _mediaSession,
      session,
    );

    // 4. Bring the controller in line with the state, in turn with the
    //    other calls: see [_queueMediaSessionSync].
    try {
      await _queueMediaSessionSync();
    } catch (_) {
      // The controller could not be created: undo the owner and the state
      // this call wrote, unless a later call has replaced them.
      if (session != null &&
          identical(_state.mediaSession, session) &&
          _mediaSessionController == null) {
        if (identical(Player._mediaSessionOwner, this)) {
          Player._mediaSessionOwner = null;
        }
        _updateField(
          (s) => s.copyWith(mediaSession: null),
          _mediaSession,
          null,
        );
      }
      rethrow;
    }
  }

  /// Drops the OS media session without the public checks: called by
  /// dispose, which has already refused new calls. It takes its turn
  /// after the calls queued before it, so a controller still being
  /// created is torn down once it exists.
  Future<void> _releaseMediaSession() async {
    if (identical(Player._mediaSessionOwner, this)) {
      Player._mediaSessionOwner = null;
    }
    await _queueMediaSessionSync();
  }

  /// Runs [_syncMediaSessionController] after the media-session work every
  /// [Player] of the isolate queued before it. Calls that are not awaited
  /// overlap: two enables in one turn, a `null` followed by a session, a
  /// dispose followed by a new [Player]. Run side by side, a controller
  /// torn down late sent its `disable` after the `enable` of the next one,
  /// and its cancel removed the command channel handler the next one
  /// listens on. A failure reaches the caller and does not stop the queue.
  Future<void> _queueMediaSessionSync() {
    final run = Player._mediaSessionQueue.then(
      (_) => _syncMediaSessionController(),
    );
    Player._mediaSessionQueue = run.then<void>((_) {}, onError: (Object _) {});
    return run;
  }

  /// Creates the controller when this [Player] publishes and has none,
  /// and tears it down when it no longer does. It reads the state at its
  /// turn, so overlapping calls settle on the last one: the config of a
  /// later call reaches the native side with the `enable`, or through
  /// `updateConfig` once the controller exists.
  Future<void> _syncMediaSessionController() async {
    final wanted =
        !_disposed &&
        _state.mediaSession != null &&
        identical(Player._mediaSessionOwner, this);
    final current = _mediaSessionController;
    if (wanted && current == null) {
      _mediaSessionController = await MediaSessionController.create(
        stateSnapshot: () => _state,
        // The changes only: the controller pushes the current state
        // itself, so the replaying state streams are not what it needs.
        inputs: MediaSessionInputs(
          playWhenReady: _reactives.playWhenReady.changes,
          playing: _reactives.playing.changes,
          buffering: _buffering.changes,
          rate: _reactives.rate.changes,
          seekCompleted: _seekCompletedCtrl.stream,
          seekable: _reactives.seekable.changes,
          loop: _loop.changes,
          shuffle: _reactives.shuffle.changes,
          duration: _reactives.duration.changes,
          metadata: _metadata.changes,
          coverArt: _coverArtCtrl.stream,
          mediaTitle: _reactives.mediaTitle.changes,
          mediaSession: _mediaSession.changes,
        ),
        onCommand: _handleSessionCommand,
        onAudioOutputReset: _reloadAudioOutput,
      );
    } else if (!wanted && current != null) {
      _mediaSessionController = null;
      await current.dispose();
    }
  }

  /// Handles a remote command issued by the OS media session.
  ///
  /// Auto-applies the command to the [Player] (the optimistic update
  /// pattern guarantees `state` reflects the new value synchronously),
  /// then emits on [PlayerStream.mediaSessionCommands] so consumer
  /// subscribers can observe the resolved order.
  ///
  /// [MediaSessionCommandNext] and [MediaSessionCommandPrevious] use
  /// the smart-default routing: if the active playlist has more than
  /// one entry, the package calls mpv's `playlist-next` or
  /// `playlist-prev`. Otherwise the command is emit-only, leaving
  /// the consumer's queue logic to handle it.
  void _handleSessionCommand(MediaSessionCommand command) {
    // Auto-apply. We deliberately don't `await` these: the command stream
    // callback is synchronous, and each setter updates the state when mpv
    // confirms. A late rejection is caught by [_applySessionCommand].
    switch (command) {
      case MediaSessionCommandPlay():
        _applySessionCommand((this as Player).play());
      case MediaSessionCommandPause():
        _applySessionCommand((this as Player).pause());
      case MediaSessionCommandPlayPause():
        // Resolve against the INTENT axis, not actual output: `_state.playing`
        // (core-idle inverted) toggles transiently on every seek and buffer, so
        // a single-button PlayPause landing during a transient would flip the
        // wrong way. The OS button itself binds to `playWhenReady`; match it.
        if (_state.playWhenReady) {
          _applySessionCommand((this as Player).pause());
        } else {
          _applySessionCommand((this as Player).play());
        }
      case MediaSessionCommandStop():
        _applySessionCommand((this as Player).stop());
      case MediaSessionCommandNext():
        if (shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation:
              _state.mediaSession?.autoApplyPlaylistNavigation,
          playlistLength: _state.playlist.items.length,
        )) {
          _applySessionCommand((this as Player).next());
        }
      case MediaSessionCommandPrevious():
        if (shouldAutoApplyPlaylistNav(
          autoApplyPlaylistNavigation:
              _state.mediaSession?.autoApplyPlaylistNavigation,
          playlistLength: _state.playlist.items.length,
        )) {
          _applySessionCommand((this as Player).previous());
        }
      case MediaSessionCommandLike():
        // Emit-only: there is no built-in favourite concept, so it is not
        // auto-applied. The consumer reacts on the stream below and reflects
        // the new state via `MediaSession.isFavorite`.
        break;
      case MediaSessionCommandSeekTo(:final position):
        _applySessionCommand((this as Player).seek(position));
      case MediaSessionCommandSeekBy(:final offset):
        // Apply as a TRUE relative seek so mpv does the base-position
        // arithmetic against its own live playhead. Computing an absolute
        // target from `_state.position` here would compose off a stale
        // base when skip buttons repeat faster than the position observer
        // updates; rapid lockscreen or headset double-taps would under-skip.
        _applySessionCommand((this as Player).seek(offset, relative: true));
      case MediaSessionCommandSetRepeatMode(:final loop):
        _applySessionCommand((this as Player).setLoop(loop));
      case MediaSessionCommandSetShuffle(:final shuffle):
        _applySessionCommand((this as Player).setShuffle(shuffle));
      case MediaSessionCommandSetPlaybackRate(:final rate):
        _applySessionCommand((this as Player).setRate(rate));
    }
    // Always emit on the consumer-facing stream, regardless of
    // whether the command was auto-applied. Even for next and previous
    // on a single-media playlist (where auto-apply is a no-op) the
    // consumer needs to see the command to drive its own queue.
    _mediaSessionCommandsCtrl.add(command);
  }

  /// Reopens mpv's audio output after the OS restored the audio session
  /// without it (see [MediaSessionChannel.audioOutputResets]): the
  /// AudioUnit the system stopped for an interruption or a media services
  /// reset stays silent, while mpv keeps reporting playback.
  void _reloadAudioOutput() {
    _applySessionCommand(_commandChecked(const ['ao-reload']));
  }

  /// Fires an inbound-command action without awaiting it (the command-stream
  /// callback is synchronous and the typed setters are optimistic), but
  /// catches a late rejection. A command mpv rejects, for example a
  /// lockscreen seek arriving with nothing loaded ([Player.seek] throws via
  /// `_commandChecked`), would otherwise escape as an unhandled async error.
  /// [runSessionCommand] also takes the `Future<bool>` of `next` and
  /// `previous`.
  void _applySessionCommand(Future<Object?> action) {
    runSessionCommand(action, (e) {
      _internalLog('Media-session command failed: $e', level: LogLevel.warn);
    });
  }
}
