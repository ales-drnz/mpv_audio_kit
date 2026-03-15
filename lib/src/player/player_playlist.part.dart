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
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
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

  /// Jumps to the track at [index] in the playlist.
  Future<void> jump(int index) async {
    _checkNotDisposed();
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
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
    _mediaCache[normalizedUri] = media;
    _command(['loadfile', normalizedUri, 'append']);
    final lastIndex = _state.playlist.medias.length;
    _command(['playlist-move', lastIndex.toString(), index.toString()]);
    _command(['playlist-remove', (index + 1).toString()]);
  }

  /// Clears all tracks from the playlist.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    _mediaCache.clear();
    _command(['playlist-clear']);
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
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    _checkNotDisposed();
    _prop('shuffle', shuffle ? 'yes' : 'no');
  }
}
