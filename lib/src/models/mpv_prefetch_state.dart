// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

/// Lifecycle phase of mpv's background playlist-prefetch.
///
/// Emitted by [PlayerStream.prefetchState] whenever mpv transitions
/// between phases, so clients can show "Prefetching…" UI, verify that
/// gapless transitions are actually reusing the buffered stream, or log
/// warnings when a prefetch is aborted/dropped.
///
/// Backed by mpv's `prefetch-state` property, with the same lifecycle
/// across every demuxer backend — HLS, DASH, raw HTTP range reads,
/// SMB, local files.
enum MpvPrefetchState {
  /// No background prefetch is active. Default state.
  idle,

  /// `prefetch_next()` fired: the opener thread is creating the demuxer
  /// for the next playlist item, and once open, the secondary cache is
  /// filling in the background.
  loading,

  /// The secondary demuxer is open AND its reader reports idle (= mpv's
  /// `cache-secs` threshold has been hit and no further segment fetches
  /// are outstanding). Gapless transition is armed.
  ready,

  /// The prefetched stream was just consumed — the current track ended
  /// and mpv reused the secondary demuxer instead of re-opening. This
  /// is an edge-triggered notification: the property fires [used] and
  /// then immediately returns to [idle], so observers see two
  /// consecutive events and can treat [used] as a one-shot signal.
  used;

  /// Parses the string emitted by mpv. Unknown values fall back to
  /// [idle] so future mpv additions don't crash clients — they just
  /// see the phase treated as "not actively prefetching".
  static MpvPrefetchState parse(String value) {
    switch (value) {
      case 'loading':
        return MpvPrefetchState.loading;
      case 'ready':
        return MpvPrefetchState.ready;
      case 'used':
        return MpvPrefetchState.used;
      default:
        return MpvPrefetchState.idle;
    }
  }
}
