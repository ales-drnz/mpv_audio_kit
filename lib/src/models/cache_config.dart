// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'enums.dart';

part 'cache_config.freezed.dart';

/// Aggregate of mpv's five cache properties.
///
/// Useful when restoring a saved configuration or applying a coherent
/// preset (e.g. "low-latency streaming" vs. "long-buffer audiobook")
/// via [Player.setCache] — the wrapper writes `cache`, `cache-secs`,
/// `cache-on-disk`, `cache-pause`, and `cache-pause-wait` atomically.
///
/// For one-off tweaks the granular setters ([Player.setCacheMode],
/// [Player.setCacheSecs], …) remain available and slightly more
/// ergonomic.
///
/// Read the current configuration via [PlayerState.cache] or observe
/// live changes via [PlayerStream.cache].
@freezed
abstract class CacheConfig with _$CacheConfig {
  const factory CacheConfig({
    /// Caching policy (auto = enabled for network sources).
    @Default(CacheMode.auto) CacheMode mode,

    /// Target cache duration ahead of the playhead.
    @Default(Duration(seconds: 1)) Duration secs,

    /// Whether to spill cache to disk instead of holding it in memory.
    @Default(false) bool onDisk,

    /// Whether playback pauses when the cache runs empty (network stall).
    @Default(true) bool pause,

    /// Pre-buffer required before resuming after a [pause] stall.
    @Default(Duration(seconds: 1)) Duration pauseWait,
  }) = _CacheConfig;
}
