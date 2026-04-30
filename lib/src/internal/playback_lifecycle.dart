// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../models/enums.dart';

/// Pure derivation of the aggregate [PlaybackLifecycle] from the five
/// underlying observables the wrapper already tracks.
///
/// The mapping is:
/// - `completed`                                                → completed
/// - `pausedForCache`                                           → buffering
/// - `buffering`                                                → loading
/// - `playing`                                                  → playing
/// - `duration == 0` (no file loaded, not buffering)            → idle
/// - default                                                    → paused
///
/// Two semantically-different "stalled" states are distinguished by
/// `pausedForCache` (mpv's `paused-for-cache`): `loading` is the initial
/// open, `buffering` is a mid-playback network re-buffer.
@internal
PlaybackLifecycle derivePlaybackLifecycle({
  required bool playing,
  required bool buffering,
  required bool completed,
  required bool pausedForCache,
  required Duration duration,
}) {
  if (completed) return PlaybackLifecycle.completed;
  if (pausedForCache) return PlaybackLifecycle.buffering;
  if (buffering) return PlaybackLifecycle.loading;
  if (playing) return PlaybackLifecycle.playing;
  if (duration == Duration.zero) return PlaybackLifecycle.idle;
  return PlaybackLifecycle.paused;
}
