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
class Media {
  /// The URI of the media resource.
  ///
  /// Supported schemes: `http://`, `https://`, `file://`, `asset:///`, `rtsp://`,
  /// `rtmp://`, and anything else that libmpv accepts.
  final String uri;

  /// Optional user-supplied metadata attached to this track.
  ///
  /// The player itself does not interpret these values; they are carried through
  /// the playlist so the UI layer can access them without a separate lookup.
  final Map<String, dynamic>? extras;

  /// Optional HTTP headers for network streams.
  final Map<String, String>? httpHeaders;

  /// Creates a [Media] from a URI.
  ///
  /// [uri] must be a non-empty string that libmpv can open.
  const Media(this.uri, {this.extras, this.httpHeaders});

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Media && uri == other.uri;

  @override
  int get hashCode => uri.hashCode;

  @override
  String toString() => 'Media($uri)';
}
