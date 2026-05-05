// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internals/unset_sentinel.dart';

bool _mapEqDyn(Map<String, Object?>? a, Map<String, Object?>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) return false;
  }
  return true;
}

bool _mapEq(Map<String, String>? a, Map<String, String>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

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
/// when diffing playlists for re-render decisions.
final class Media {
  /// The URI of the media resource.
  ///
  /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`,
  /// `rtsp://`, `rtmp://`, and anything else that libmpv accepts.
  final String uri;

  /// Optional user-supplied metadata attached to this track.
  ///
  /// The player itself does not interpret these values; they are carried
  /// through the playlist so the UI layer can access them without a
  /// separate lookup.
  final Map<String, Object?>? extras;

  /// Optional HTTP headers for network streams.
  ///
  /// Applied automatically by [Player.open] (the single-file replace
  /// path is the only one that can synchronously attach the headers
  /// to the next mpv load). For [Player.add], [Player.replace], and
  /// [Player.openAll] entries beyond the first, register an
  /// `on_load` hook and set
  /// `file-local-options/http-header-fields` from the handler —
  /// headers are not auto-applied there to avoid races with mpv's
  /// playlist advance.
  final Map<String, String>? httpHeaders;

  const Media(this.uri, {this.extras, this.httpHeaders});

  Media copyWith({
    String? uri,
    Object? extras = unset,
    Object? httpHeaders = unset,
  }) =>
      Media(
        uri ?? this.uri,
        extras: identical(extras, unset)
            ? this.extras
            : extras as Map<String, Object?>?,
        httpHeaders: identical(httpHeaders, unset)
            ? this.httpHeaders
            : httpHeaders as Map<String, String>?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Media &&
          other.uri == uri &&
          _mapEqDyn(extras, other.extras) &&
          _mapEq(httpHeaders, other.httpHeaders));

  @override
  int get hashCode => Object.hash(
        uri,
        extras == null
            ? null
            : Object.hashAllUnordered(
                extras!.entries.map((e) => Object.hash(e.key, e.value)),
              ),
        httpHeaders == null
            ? null
            : Object.hashAllUnordered(
                httpHeaders!.entries.map((e) => Object.hash(e.key, e.value)),
              ),
      );

  @override
  String toString() =>
      'Media(uri: $uri, extras: $extras, httpHeaders: $httpHeaders)';
}
