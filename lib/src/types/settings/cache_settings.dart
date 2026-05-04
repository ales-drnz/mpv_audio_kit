// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/types/enums/cache.dart';

/// Aggregate of mpv's five cache properties (`cache`, `cache-secs`,
/// `cache-on-disk`, `cache-pause`, `cache-pause-wait`).
///
/// Apply atomically via [Player.setCache]. For one-off tweaks use
/// `state.cache.copyWith(...)`. Read the current configuration via
/// [PlayerState.cache] or observe live changes via [PlayerStream.cache].
final class CacheSettings {
  /// Caching policy. Default mirrors mpv's `--cache=auto`.
  final Cache mode;

  /// Target cache duration ahead of the playhead. Default 1 hour
  /// mirrors mpv's `--cache-secs=3600`. Actual memory usage is bounded
  /// by [PlayerState.demuxerMaxBytes] (150 MiB by default), whichever
  /// comes first.
  final Duration secs;

  /// Whether to spill cache to disk instead of holding it in memory.
  final bool onDisk;

  /// Whether playback pauses when the cache runs empty (network stall).
  final bool pause;

  /// Pre-buffer required before resuming after a [pause] stall. Default
  /// 1 second mirrors mpv's `--cache-pause-wait=1.0`.
  final Duration pauseWait;

  const CacheSettings({
    this.mode = Cache.auto,
    this.secs = const Duration(hours: 1),
    this.onDisk = false,
    this.pause = true,
    this.pauseWait = const Duration(seconds: 1),
  });

  CacheSettings copyWith({
    Cache? mode,
    Duration? secs,
    bool? onDisk,
    bool? pause,
    Duration? pauseWait,
  }) =>
      CacheSettings(
        mode: mode ?? this.mode,
        secs: secs ?? this.secs,
        onDisk: onDisk ?? this.onDisk,
        pause: pause ?? this.pause,
        pauseWait: pauseWait ?? this.pauseWait,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CacheSettings &&
          other.mode == mode &&
          other.secs == secs &&
          other.onDisk == onDisk &&
          other.pause == pause &&
          other.pauseWait == pauseWait);

  @override
  int get hashCode => Object.hash(mode, secs, onDisk, pause, pauseWait);

  @override
  String toString() =>
      'CacheSettings(mode: $mode, secs: $secs, onDisk: $onDisk, '
      'pause: $pause, pauseWait: $pauseWait)';
}
