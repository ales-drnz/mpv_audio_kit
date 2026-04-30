// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Module for managing the media queue and track selection.
mixin _PlaylistModule on _PlayerBase {
  /// Appends [media] to the end of the current playlist.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    if (media.httpHeaders != null) {
      final headers = media.httpHeaders!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      _opt('http-header-fields', headers);
    }
    final normalizedUri = await _resolveUri(media.uri);
    if (_disposed) return;
    _mediaCache[normalizedUri] = media;
    _command(['loadfile', normalizedUri, 'append']);
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
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    final normalizedUri = await _resolveUri(media.uri);
    if (_disposed) return;
    _mediaCache[normalizedUri] = media;
    _command(['playlist-remove', index.toString()]);
    _command(['loadfile', normalizedUri, 'insert-at', index.toString()]);
  }

  /// Clears all tracks from the playlist.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    _mediaCache.clear();
    _command(['playlist-clear']);
    _command(['playlist-remove', 'current']);
  }

  /// Sets the playlist repeat mode.
  Future<void> setPlaylistMode(PlaylistMode mode) async {
    _checkNotDisposed();
    switch (mode) {
      case PlaylistMode.none:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'no');
      case PlaylistMode.single:
        _prop('loop-file', 'inf');
        _prop('loop-playlist', 'no');
      case PlaylistMode.loop:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'inf');
    }
    // Optimistic update so `state.playlistMode` and the matching stream
    // reflect the requested mode without waiting for the two `loop-file`
    // and `loop-playlist` observers to round-trip from mpv. Matches the
    // pattern used by every other setter in this package.
    _updateField(
      (s) => s.copyWith(playlistMode: mode),
      _playlistMode,
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
    // Optimistic update *after* the FFI side-effects, matching the
    // `_prop → _updateField` ordering of every other setter.
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
