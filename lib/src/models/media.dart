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
/// // Attach arbitrary data to a track (available via Player.state.playlist),
/// // and start it 5 minutes in.
/// final rich = Media(
///   'https://cdn.example.com/episode-42.mp3',
///   extras: {
///     'title':  'Episode 42',
///     'artist': 'The Podcast',
///     'art':    'https://cdn.example.com/art.jpg',
///   },
///   httpHeaders: {
///     'User-Agent': 'mpv_audio_kit',
///   },
///   start: Duration(minutes: 5),
/// );
///
/// // Opt in to chunked range requests so a throttling CDN (YouTube or
/// // googlevideo) keeps serving at full speed after a seek.
/// final yt = Media(googlevideoUrl, httpChunkSize: 8 * 1024 * 1024);
/// ```
///
/// Equality compares every field ([uri], [extras], [httpHeaders],
/// [httpChunkSize], [demuxerLavfOptions] and [start]), so two instances
/// that differ in any of them are not equal: useful when diffing playlists
/// for re-render decisions. The maps compare by content, their values by
/// `==`.
final class Media {
  /// The URI of the media resource.
  ///
  /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`,
  /// `rtsp://`, `rtmp://`, and anything else that libmpv accepts.
  final String uri;

  /// Optional user-supplied metadata attached to this track.
  ///
  /// The values are carried through the playlist so the UI layer can
  /// access them without a separate lookup. Playback ignores them; the OS
  /// media session reads four string keys as a fallback for files without
  /// tags (a transcoded stream, a radio):
  /// - `title`, `artist` and `album`: used when the file has no such tag
  ///   and [MediaSession] sets no override. `title` comes before mpv's
  ///   `media-title`, which falls back to the file name or URL.
  /// - `art`: an `http(s)://` or `file://` URL of the cover, used when the
  ///   artwork is [MediaSessionArtwork.embedded] and the file has none.
  final Map<String, Object?>? extras;

  /// Optional HTTP headers for network streams.
  ///
  /// Applied automatically on every load path: [Player.open],
  /// [Player.openAll], [Player.add] and [Player.replace] all attach
  /// these headers to the matching mpv `loadfile` as file-local
  /// options (`http-header-fields=...`), so the headers ride along
  /// with that exact playlist entry without leaking onto other
  /// entries or the global `http-header-fields` option.
  ///
  /// If you need headers that depend on runtime state computed at
  /// load time (e.g. a token refreshed asynchronously), register an
  /// `on_load` hook (see `Player.registerHook`) and set
  /// `file-local-options/http-header-fields` from the handler.
  final Map<String, String>? httpHeaders;

  /// Optional per-track options for libmpv's libavformat (`lavf`) demuxer,
  /// applied as the file-local `demuxer-lavf-o`, the demuxer-side analogue of
  /// [httpHeaders]. Each `key: value` becomes one `key=value` entry, scoped to
  /// this exact playlist entry.
  ///
  /// A common use is reaching the segment demuxer of an HLS or DASH stream via the
  /// HLS demuxer's `seg_format_options` dictionary, e.g.
  /// `{'seg_format_options': 'advanced_editlist=0'}`.
  ///
  /// Values must not contain a comma; keys must be non-empty. `null` (default)
  /// sets nothing.
  final Map<String, String>? demuxerLavfOptions;

  /// Opt-in maximum size, in bytes, of each HTTP range request for this
  /// source. `null` (default) leaves mpv's normal behaviour: one open-ended
  /// request for the rest of the file.
  ///
  /// Set it to fetch the stream in bounded chunks instead. Some CDNs
  /// (notably progressive YouTube or `googlevideo` audio) rate-limit a single
  /// open-ended request for the whole file to a crawl, so seeking back
  /// freezes once the buffered audio drains. Capping each request below the
  /// CDN's threshold (a common value is `8 * 1024 * 1024`, 8 MiB) keeps it
  /// serving at full speed. The same technique yt-dlp uses (`--http-chunk-size`).
  ///
  /// Leave it `null` for fast, trusted servers (Plex, Jellyfin, your own
  /// library) where one large request buffers fastest. Like [httpHeaders],
  /// the value is scoped to this exact `loadfile` and never leaks onto other
  /// playlist entries. Must be positive when set.
  final int? httpChunkSize;

  /// Where this entry starts playing, as a time from the start of the
  /// file (mpv's per-file `start`). `null` (default) starts at the
  /// beginning, or at a resume point saved for the file.
  ///
  /// It holds each time the entry loads: going back to it with
  /// [Player.previous] or [Player.jump], or a playlist loop, starts it here
  /// again. [Loop.file] and [Player.play] at the end of the queue start the
  /// file from its beginning. It wins over a resume point saved with
  /// [Player.writeResumeConfig], whose other values (speed, volume and so
  /// on) still apply, and the load uses that point up as any resume does.
  /// With [Player.setPrefetchPlaylist] on, an entry whose
  /// options differ from the playing entry's, a start included, is not
  /// opened ahead from libmpv-r18 on, so the change to it is not gapless.
  ///
  /// Must not be negative. Past the end of the file the entry ends at
  /// once. Like the other per-entry options it does not apply to
  /// [Player.openPlaylistFile], and a live [PcmSource] entry refuses it:
  /// it plays from its first chunk.
  final Duration? start;

  /// Creates an immutable media item for [uri], with optional consumer
  /// [extras], per-request [httpHeaders] and [httpChunkSize], per-entry
  /// [demuxerLavfOptions], and a [start] position.
  const Media(
    this.uri, {
    this.extras,
    this.httpHeaders,
    this.httpChunkSize,
    this.demuxerLavfOptions,
    this.start,
  });

  /// Whether this media is a live PCM input made by `PcmSource.toMedia`
  /// (a `mak-pcm://` URI): read once, not seekable, of a length not known
  /// in advance.
  bool get isPcmStream => uri.startsWith('mak-pcm://');

  /// Returns a copy with the given fields replaced. Pass `null` for
  /// [extras], [httpHeaders], [httpChunkSize], [demuxerLavfOptions] or
  /// [start] to clear them; omitted fields keep their current value.
  Media copyWith({
    String? uri,
    Object? extras = unset,
    Object? httpHeaders = unset,
    Object? httpChunkSize = unset,
    Object? demuxerLavfOptions = unset,
    Object? start = unset,
  }) => Media(
    uri ?? this.uri,
    extras: identical(extras, unset)
        ? this.extras
        : extras as Map<String, Object?>?,
    httpHeaders: identical(httpHeaders, unset)
        ? this.httpHeaders
        : httpHeaders as Map<String, String>?,
    httpChunkSize: identical(httpChunkSize, unset)
        ? this.httpChunkSize
        : httpChunkSize as int?,
    demuxerLavfOptions: identical(demuxerLavfOptions, unset)
        ? this.demuxerLavfOptions
        : demuxerLavfOptions as Map<String, String>?,
    start: identical(start, unset) ? this.start : start as Duration?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Media &&
          other.uri == uri &&
          other.httpChunkSize == httpChunkSize &&
          other.start == start &&
          _mapEqDyn(extras, other.extras) &&
          _mapEq(httpHeaders, other.httpHeaders) &&
          _mapEq(demuxerLavfOptions, other.demuxerLavfOptions));

  @override
  int get hashCode => Object.hash(
    uri,
    httpChunkSize,
    start,
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
    demuxerLavfOptions == null
        ? null
        : Object.hashAllUnordered(
            demuxerLavfOptions!.entries.map((e) => Object.hash(e.key, e.value)),
          ),
  );

  /// Prints the [httpHeaders] names only: their values often carry
  /// credentials (an `Authorization` token) that must not reach a log.
  @override
  String toString() {
    final headers = httpHeaders == null
        ? null
        : '{${httpHeaders!.keys.map((k) => '$k: <redacted>').join(', ')}}';
    return 'Media(uri: $uri, extras: $extras, '
        'httpHeaders: $headers, httpChunkSize: $httpChunkSize, '
        'demuxerLavfOptions: $demuxerLavfOptions, start: $start)';
  }
}
