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
  /// `media.httpHeaders` is NOT applied automatically — the appended
  /// entry may be loaded much later by mpv (after the current track
  /// ends), and the wrapper has no synchronous moment to attach
  /// per-file options. Consumers that need per-track HTTP headers on a
  /// playlist should register an `on_load` hook
  /// (see [_HooksModule.registerHook]) and set
  /// `file-local-options/http-header-fields` from the handler.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    _command(['loadfile', resolved.uri, 'append']);
  }

  /// Removes the track at [index] from the playlist.
  Future<void> remove(int index) async {
    _checkNotDisposed();
    _command(['playlist-remove', index.toString()]);
  }

  /// Skips to the next track.
  Future<void> next() async {
    _checkNotDisposed();
    _command(['playlist-next']);
  }

  /// Skips to the previous track.
  Future<void> previous() async {
    _checkNotDisposed();
    _command(['playlist-prev']);
  }

  /// Jumps to the track at [index] in the playlist and starts playback.
  ///
  /// Unpauses synchronously *before* issuing the playlist jump so the new
  /// track starts playing as soon as `MPV_EVENT_FILE_LOADED` arrives — no
  /// shared `_pendingPlay` field to race on with concurrent `open()` calls.
  Future<void> jump(int index) async {
    _checkNotDisposed();
    _prop('pause', 'no');
    _command(['playlist-play-index', index.toString()]);
  }

  /// Moves the track at [from] to position [to].
  Future<void> move(int from, int to) async {
    _checkNotDisposed();
    _command(['playlist-move', from.toString(), to.toString()]);
  }

  /// Replaces the track at [index] with a new [media] item.
  ///
  /// `media.httpHeaders` is NOT applied automatically — see [add] for
  /// the rationale and the recommended `on_load` hook pattern.
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    _command(['playlist-remove', index.toString()]);
    _command(['loadfile', resolved.uri, 'insert-at', index.toString()]);
  }

  /// Clears all tracks from the playlist.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    _mediaCache.clear();
    _command(['playlist-clear']);
    _command(['playlist-remove', 'current']);
  }

  /// Sets the playlist repeat mode.
  Future<void> setLoop(LoopMode mode) async {
    _checkNotDisposed();
    switch (mode) {
      case LoopMode.off:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'no');
      case LoopMode.file:
        _prop('loop-file', 'inf');
        _prop('loop-playlist', 'no');
      case LoopMode.playlist:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'inf');
    }
    // Optimistic update — `state.loop` reflects the requested mode
    // without waiting for the two underlying observers to round-trip.
    _updateField(
      (s) => s.copyWith(loop: mode),
      _loop,
      mode,
    );
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    _checkNotDisposed();
    _prop('shuffle', shuffle ? 'yes' : 'no');
    if (shuffle) {
      _command(['playlist-shuffle']);
    } else {
      _command(['playlist-unshuffle']);
    }
    _updateField(
        (s) => s.copyWith(shuffle: shuffle), _reactives.shuffle, shuffle);
  }

  /// Enables or disables background prefetch of the next playlist item.
  ///
  /// When enabled, mpv opens the demuxer for the next track before the
  /// current one finishes, so playback continues without an opening-thread
  /// stall on file boundaries. Observe progress via
  /// [PlayerStream.prefetchState].
  Future<void> setPrefetchPlaylist(bool enabled) async {
    _checkNotDisposed();
    _prop('prefetch-playlist', enabled ? 'yes' : 'no');
    _updateField((s) => s.copyWith(prefetchPlaylist: enabled),
        _reactives.prefetchPlaylist, enabled);
  }
}
