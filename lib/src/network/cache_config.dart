// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_config.freezed.dart';

/// Network cache mode, mirroring `--cache=<auto|yes|no>`.
enum CacheMode {
  /// Auto (mpv default): enabled for network sources, disabled for local files.
  auto('auto'),

  /// Always cache.
  yes('yes'),

  /// Never cache.
  no('no');

  const CacheMode(this.mpvValue);

  /// The wire-level string mpv expects.
  final String mpvValue;

  /// Maps a raw mpv-side value back to the enum. Unknown → [auto].
  static CacheMode fromMpv(String raw) => switch (raw) {
        'auto' => auto,
        'yes' => yes,
        'no' => no,
        _ => auto,
      };
}

/// Aggregate of mpv's five cache properties (`cache`, `cache-secs`,
/// `cache-on-disk`, `cache-pause`, `cache-pause-wait`).
///
/// Apply atomically via [Player.setCache]. For one-off tweaks use
/// `state.cache.copyWith(...)`. Read the current configuration via
/// [PlayerState.cache] or observe live changes via [PlayerStream.cache].
@freezed
abstract class CacheConfig with _$CacheConfig {
  const factory CacheConfig({
    /// Caching policy. Default mirrors mpv's `--cache=auto`.
    @Default(CacheMode.auto) CacheMode mode,

    /// Target cache duration ahead of the playhead. Default 1 hour
    /// mirrors mpv's `--cache-secs=3600`. Actual memory usage is bounded
    /// by [PlayerState.demuxerMaxBytes] (150 MiB by default), whichever
    /// comes first.
    @Default(Duration(hours: 1)) Duration secs,

    /// Whether to spill cache to disk instead of holding it in memory.
    @Default(false) bool onDisk,

    /// Whether playback pauses when the cache runs empty (network stall).
    @Default(true) bool pause,

    /// Pre-buffer required before resuming after a [pause] stall. Default
    /// 1 second mirrors mpv's `--cache-pause-wait=1.0`.
    @Default(Duration(seconds: 1)) Duration pauseWait,
  }) = _CacheConfig;
}
