// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:meta/meta.dart';

import '../models/player_state.dart';
import '../models/playlist.dart';

/// Result of a lifecycle transition, used by [computeLifecycle].
///
/// The three `*DidChange` flags tell the caller which of the three
/// observable lifecycle reactives (playing / buffering / completed) needs
/// to be fed an `update()`. Splitting the diff out of the dispatch site
/// keeps `state.copyWith(...)` and `controller.add(...)` from drifting
/// out of sync — they share one decision point and one set of flags.
@internal
class LifecycleResult {
  const LifecycleResult({
    required this.newState,
    required this.playingDidChange,
    required this.bufferingDidChange,
    required this.completedDidChange,
  });

  final PlayerState newState;
  final bool playingDidChange;
  final bool bufferingDidChange;
  final bool completedDidChange;
}

/// Pure-function core of the lifecycle update used on file boundaries
/// (`MpvEventStartFile`, `MpvEventFileLoaded`, `MpvEndFileEvent`,
/// `MpvEventShutdown`, `idle-active=true`).
///
/// Given the previous [PlayerState] and any subset of `playing` /
/// `buffering` / `completed` overrides, returns the new state plus a
/// per-field "did-change" flag. The caller is responsible for pushing
/// those flags to the corresponding broadcast reactives.
///
/// The design intentionally keeps the dispatch logic out of this
/// function so it stays trivially testable — see
/// `test/internal/lifecycle_transitions_test.dart` for the suite that
/// pins down every transition produced by the player.
@internal
LifecycleResult computeLifecycle({
  required PlayerState prev,
  bool? playing,
  bool? buffering,
  bool? completed,
}) {
  var next = prev;
  if (playing != null) next = next.copyWith(playing: playing);
  if (buffering != null) next = next.copyWith(buffering: buffering);
  if (completed != null) next = next.copyWith(completed: completed);
  return LifecycleResult(
    newState: next,
    playingDidChange: playing != null && prev.playing != playing,
    bufferingDidChange: buffering != null && prev.buffering != buffering,
    completedDidChange: completed != null && prev.completed != completed,
  );
}

/// Pure mapping from mpv's two boolean-ish loop properties (`loop-file`,
/// `loop-playlist`) to the typed [PlaylistMode] state field.
///
/// mpv reports each loop independently: `loop-file=inf` → repeat current
/// track, `loop-playlist=inf` → repeat the queue, both `'no'` → no loop.
/// The wrapper aggregates these two events into one `playlistMode` value
/// because consumers care about the user-facing repeat mode, not the raw
/// pair.
///
/// Returns `null` when the event isn't a meaningful state change (e.g.
/// `loop-file=no` arrives but the previous mode was `loop` from the
/// playlist-loop side — toggling loop-file off shouldn't reset the
/// playlist loop).
@internal
PlaylistMode? derivePlaylistMode(
  String mpvName,
  String value,
  PlaylistMode prevMode,
) {
  switch (mpvName) {
    case 'loop-file':
      if (value == 'inf') return PlaylistMode.single;
      if (prevMode == PlaylistMode.single) return PlaylistMode.none;
      return null;
    case 'loop-playlist':
      if (value == 'inf') return PlaylistMode.loop;
      if (prevMode == PlaylistMode.loop) return PlaylistMode.none;
      return null;
    default:
      return null;
  }
}
