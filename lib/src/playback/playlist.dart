// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'media.dart';

part 'playlist.freezed.dart';

/// An ordered list of [Media] items loaded into the [Player].
///
/// Two playlists compare equal only when both [medias] (deep equality)
/// and [index] match — useful when consumers diff playlists for
/// re-render decisions.
@freezed
abstract class Playlist with _$Playlist {
  const Playlist._();

  const factory Playlist(
    /// The ordered list of tracks.
    List<Media> medias, {
    /// The index of the currently active track. `0` for an empty playlist.
    @Default(0) int index,
  }) = _Playlist;

  /// The empty playlist — no tracks, index 0. Const-evaluable so it can
  /// seed default fields without runtime allocation.
  static const empty = Playlist(<Media>[]);
}
