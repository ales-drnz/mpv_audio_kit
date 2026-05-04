// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'media.dart';

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// An ordered list of [Media] items loaded into the [Player].
///
/// Two playlists compare equal only when both [medias] (deep equality)
/// and [index] match — useful when diffing playlists for re-render
/// decisions.
final class Playlist {
  /// The ordered list of tracks.
  final List<Media> medias;

  /// The index of the currently active track. `0` for an empty playlist.
  final int index;

  const Playlist(this.medias, {this.index = 0});

  /// The empty playlist — no tracks, index 0. Const-evaluable so it can
  /// seed default fields without runtime allocation.
  static const Playlist empty = Playlist(<Media>[]);

  Playlist copyWith({List<Media>? medias, int? index}) => Playlist(
        medias ?? this.medias,
        index: index ?? this.index,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Playlist &&
          other.index == index &&
          _listEq(medias, other.medias));

  @override
  int get hashCode => Object.hash(Object.hashAll(medias), index);

  @override
  String toString() => 'Playlist(medias: $medias, index: $index)';
}
