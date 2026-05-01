// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'media.dart';

part 'playlist.freezed.dart';

/// An ordered list of [Media] items loaded into the [Player].
///
/// Equality is structural across both [medias] (deep comparison) and
/// [index] — Freezed-generated, so `Playlist.copyWith(...)` and
/// `==`/`hashCode` follow the same contract as the rest of the
/// model layer.
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
