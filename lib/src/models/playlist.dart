// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/models/media.dart';

/// The repeat / loop mode for the player's playlist.
enum PlaylistMode {
  /// Stop playback when the end of the playlist is reached.
  none,

  /// Loop the currently playing track indefinitely.
  single,

  /// Loop over the entire playlist, restarting from the beginning when the
  /// last track ends.
  loop,
}

/// An ordered list of [Media] items loaded into the [Player].
class Playlist {
  /// The ordered list of tracks.
  final List<Media> medias;

  /// The index of the currently active track. `-1` when no track is loaded.
  final int index;

  const Playlist(this.medias, {this.index = 0});

  const Playlist.empty()
      : medias = const [],
        index = 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist &&
          index == other.index &&
          _listEqual(medias, other.medias);

  @override
  int get hashCode => medias.hashCode ^ index.hashCode;

  @override
  String toString() => 'Playlist(index: $index, length: ${medias.length})';

  static bool _listEqual(List<Media> a, List<Media> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
