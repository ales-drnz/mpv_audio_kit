// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

/// Aggregate playback lifecycle.
///
/// Convenience enum derived from `playing` / `buffering` / `completed` /
/// `pausedForCache` / `duration`. Subscribe via
/// `PlayerStream.playbackLifecycle` when a single, mutually-exclusive
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
