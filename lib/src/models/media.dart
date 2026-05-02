// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';

/// A piece of media that can be loaded into the [Player].
///
/// Wraps a URI string with optional metadata and per-track configuration.
///
/// ```dart
/// final track = Media('https://example.com/audio.mp3');
/// final local = Media('file:///home/user/music/song.flac');
/// final asset = Media('asset:///assets/audio/sample.mp3');
///
/// // Attach arbitrary data to a track (available via Player.state.playlist).
/// final rich = Media(
///   'https://cdn.example.com/episode-42.mp3',
///   extras: {
///     'title':   'Episode 42',
///     'artist':  'The Podcast',
///     'artUri':  'https://cdn.example.com/art.jpg',
///     'startAt': Duration(minutes: 5),
///   },
///   httpHeaders: {
///     'User-Agent': 'mpv_audio_kit',
///   },
/// );
/// ```
///
/// Equality considers all fields ([uri], [extras] and [httpHeaders]) so two
/// instances that differ in any of them sort and compare distinctly — useful
/// when consumers diff playlists for re-render decisions.
@freezed
abstract class Media with _$Media {
  const factory Media(
    /// The URI of the media resource.
    ///
    /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`,
    /// `rtsp://`, `rtmp://`, and anything else that libmpv accepts.
    String uri, {
    /// Optional user-supplied metadata attached to this track.
    ///
    /// The player itself does not interpret these values; they are carried
    /// through the playlist so the UI layer can access them without a
    /// separate lookup.
    Map<String, dynamic>? extras,

    /// Optional HTTP headers for network streams.
    ///
    /// Applied automatically by [Player.open] (the single-file replace
    /// path is the only one that can synchronously attach the headers
    /// to the next mpv load). For [Player.add], [Player.replace], and
    /// [Player.openAll] entries beyond the first, register an
    /// `on_load` hook and set
    /// `file-local-options/http-header-fields` from the handler — the
    /// wrapper does not auto-apply headers there to avoid races with
    /// mpv's playlist advance.
    Map<String, String>? httpHeaders,
  }) = _Media;
}
