// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Replaces stringly-typed mpv option values with closed Dart enums.
///
/// Each enum exposes:
/// - [mpvValue]: the wire-level string mpv expects (used by setters and
///   the default registry's serializer hooks).
/// - `fromMpv(String)`: factory that maps a raw mpv-side value back into
///   the typed enum. Unknown values fall back to the enum's default
///   variant (typically `no` / `auto`) rather than throwing — mpv may
///   ship new option values in the future and we don't want a single
///   property change to crash the app.
library;

/// Gapless playback mode, mirroring `--gapless-audio=<no|yes|weak>`.
enum GaplessMode {
  /// Disabled.
  no('no'),

  /// Strict gapless: re-uses the audio decoder across track boundaries.
  /// Requires identical format/sample-rate/channels between tracks.
  yes('yes'),

  /// Weak gapless (mpv default): no underruns, but allows minor format
  /// switches. Recommended for mixed-format playlists.
  weak('weak');

  const GaplessMode(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [weak] (mpv default).
  static GaplessMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'yes' => yes,
        'weak' => weak,
        _ => weak,
      };
}

/// ReplayGain normalization mode, mirroring `--replaygain=<no|track|album>`.
enum ReplayGainMode {
  /// Disabled — no normalization.
  no('no'),

  /// Per-track ReplayGain.
  track('track'),

  /// Per-album ReplayGain. Useful for cohesive albums where inter-track
  /// dynamics matter.
  album('album');

  const ReplayGainMode(this.mpvValue);

  final String mpvValue;

  static ReplayGainMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'track' => track,
        'album' => album,
        _ => no,
      };
}

/// Cover-art display priority, mirroring
/// `--audio-display=<no|embedded-first|external-first>`.
enum AudioDisplayMode {
  /// Disable video/cover-art display entirely. Recommended when the host
  /// app reads artwork out-of-band (e.g. via `metadata_god`).
  no('no'),

  /// Show embedded cover art first, fall back to external files (mpv default).
  embeddedFirst('embedded-first'),

  /// Show external cover-art files first, fall back to embedded.
  externalFirst('external-first');

  const AudioDisplayMode(this.mpvValue);

  final String mpvValue;

  static AudioDisplayMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'embedded-first' => embeddedFirst,
        'external-first' => externalFirst,
        _ => embeddedFirst,
      };
}

/// External cover-art auto-load behaviour, mirroring
/// `--cover-art-auto=<no|exact|fuzzy|all>`.
enum CoverArtAutoMode {
  /// Disabled — no external cover-art loading. The library default
  /// (mpv's own default is [exact]).
  no('no'),

  /// Match a file whose base name equals the audio file's base name with
  /// an image extension, plus the names in `--cover-art-whitelist`.
  exact('exact'),

  /// Match any file whose name *contains* the audio file's base name.
  fuzzy('fuzzy'),

  /// Load every image file in the same directory as the audio file.
  all('all');

  const CoverArtAutoMode(this.mpvValue);

  final String mpvValue;

  static CoverArtAutoMode fromMpv(String raw) => switch (raw) {
        'no' => no,
        'exact' => exact,
        'fuzzy' => fuzzy,
        'all' => all,
        _ => no,
      };
}

/// Lifecycle of mpv's audio output (AO), reported by the
/// `audio-output-state` mpv property. Authoritative replacement for
/// inferring AO state from `audio-out-params/format` after a delay —
/// the four values below cover every transition `ao_init_best()` can
/// produce.
enum AudioOutputState {
  /// No audio output is currently active. Default state and what mpv reports
  /// when no file is loaded or the file has been unloaded.
  closed('closed'),

  /// `ao_init_best()` is in flight. Useful for "connecting…" UI feedback on
  /// slow audio backends (PipeWire negotiation, BT device init, …).
  initializing('initializing'),

  /// AO opened successfully and is producing samples.
  active('active'),

  /// `ao_init_best()` returned a NULL handle — the audio output failed to
  /// open. mpv emits a parallel error on the engine log channel; the
  /// wrapper surfaces a typed [MpvLogError] on `Player.stream.error` when
  /// this state arrives.
  failed('failed');

  const AudioOutputState(this.mpvValue);

  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [closed].
  static AudioOutputState fromMpv(String raw) => switch (raw) {
        'closed' => closed,
        'initializing' => initializing,
        'active' => active,
        'failed' => failed,
        _ => closed,
      };
}

/// Aggregate playback lifecycle.
///
/// Convenience enum derived from `playing` / `buffering` / `completed` /
/// `pausedForCache` / `duration`. Subscribe via
/// [PlayerStream.playbackLifecycle] when a single, mutually-exclusive
/// state fits the UI better than three separate booleans (e.g. a single
/// "▶ / ⏸ / ⏳" indicator). The underlying booleans are still available
/// on `PlayerStream` for granular use cases.
///
/// Named `PlaybackLifecycle` rather than `PlaybackState` to avoid an
/// import collision with `audio_service`'s own `PlaybackState`.
enum PlaybackLifecycle {
  /// No file loaded. UI should hide transport controls.
  idle,

  /// File is opening — demuxer / decoder init, before the first audio frame.
  loading,

  /// Mid-playback network stall (`paused-for-cache=true`). Distinct from
  /// `loading` (initial open) and `paused` (user-initiated).
  buffering,

  /// Producing audio.
  playing,

  /// File loaded but not producing audio (user pause, EOF without natural
  /// completion, etc.).
  paused,

  /// Reached natural end-of-file. Consumers can advance the queue here.
  completed,
}

/// Network cache mode, mirroring `--cache=<auto|yes|no>`.
enum CacheMode {
  /// Auto (mpv default): enabled for network sources, disabled for local files.
  auto('auto'),

  /// Always cache.
  yes('yes'),

  /// Never cache.
  no('no');

  const CacheMode(this.mpvValue);

  final String mpvValue;

  static CacheMode fromMpv(String raw) => switch (raw) {
        'auto' => auto,
        'yes' => yes,
        'no' => no,
        _ => auto,
      };
}
