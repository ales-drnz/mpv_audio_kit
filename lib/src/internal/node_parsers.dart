// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../models/audio_device.dart';
import '../models/audio_params.dart';
import '../models/media.dart';
import '../models/playlist.dart';
import '../utils/duration_seconds.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Pure parsers for mpv properties delivered as `MPV_FORMAT_NODE`.
//
// Each function takes a Dart-native tree decoded by [decodeMpvNode] in
// `event_isolate.dart` (`Map<String, dynamic>` / `List<dynamic>` / scalar /
// `null`) and produces a typed model value. They are deliberately
// side-effect-free so the property dispatch pipeline can stay testable
// without spinning up a real player.
// ─────────────────────────────────────────────────────────────────────────────

/// Decodes mpv's `playlist` property (`MPV_FORMAT_NODE_ARRAY`) into a
/// [Playlist].
///
/// [mediaCache] is the wrapper-side `uri → Media` map that retains the
/// `extras` and `httpHeaders` (mpv only echoes back the filename, never the
/// extras a consumer attached). On cache miss we fall back to a bare
/// `Media(uri)` so the playlist stays consistent rather than dropping
/// entries silently.
///
/// [previous] is the previous [Playlist] state, used to recover a reasonable
/// `index` when mpv's payload omits the `current` flag (which it does
/// transiently during `playlist-move`). Without this fallback the index
/// would snap to 0 mid-reorder, briefly highlighting the wrong entry on the
/// consumer's UI.
Playlist parsePlaylistNode({
  required dynamic raw,
  required Map<String, Media> mediaCache,
  required Playlist previous,
}) {
  if (raw is! List) {
    return previous;
  }
  final filenames = <String>[];
  var currentIndex = -1;
  for (var i = 0; i < raw.length; i++) {
    final entry = raw[i];
    if (entry is! Map) {
      filenames.add('');
      continue;
    }
    filenames.add(entry['filename'] as String? ?? '');
    if (entry['current'] == true) currentIndex = i;
  }
  final medias =
      filenames.map((f) => mediaCache[f] ?? Media(f)).toList(growable: false);
  final idx = currentIndex >= 0
      ? currentIndex
      : previous.index.clamp(0, medias.isEmpty ? 0 : medias.length - 1);
  return Playlist(medias, index: idx);
}

/// Decodes mpv's `audio-device-list` property (`MPV_FORMAT_NODE_ARRAY`).
///
/// Each entry in the array is a `MPV_FORMAT_NODE_MAP` with `name` and
/// `description` fields. Missing fields fall back to `'unknown'` / `''`
/// rather than throwing — `audio-device-list` is queried on every
/// `audio-reconfig` and a single malformed entry shouldn't tear down the
/// stream.
List<AudioDevice> parseAudioDeviceListNode(dynamic raw) {
  if (raw is! List) return const [];
  return raw.map((entry) {
    final m = entry is Map ? entry : const <String, dynamic>{};
    return AudioDevice(
      m['name'] as String? ?? 'unknown',
      m['description'] as String? ?? '',
    );
  }).toList(growable: false);
}

/// Decodes mpv's `metadata` property (`MPV_FORMAT_NODE_MAP`) into a flat
/// `String → String` map.
///
/// Returns `null` (rather than `{}`) on empty / null input. mpv sometimes
/// emits an empty payload when a track has no tags, and overwriting the
/// existing map with an empty one would clobber tags consumers had already
/// observed (e.g. during a brief track-change window). The caller treats
/// `null` as "no update".
Map<String, String>? parseMetadataNode(dynamic raw) {
  if (raw == null) return null;
  if (raw is! Map) return null;
  if (raw.isEmpty) return null;
  return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
}

/// Decodes mpv's `demuxer-cache-state` property (`MPV_FORMAT_NODE_MAP`)
/// into a 0..100 buffering percentage normalized against the user's
/// `cache-secs` target.
///
/// Falls back to a 1-second denominator if [cacheSecsTarget] is zero
/// (which can happen during boot before `cache-secs` is observed). The
/// result is clamped to `[0, 100]` because mpv may overshoot the target
/// briefly when rebuffering.
double parseDemuxerCacheStateNode(
  dynamic raw,
  Duration cacheSecsTarget,
) {
  if (raw is! Map) return 0.0;
  final cacheDuration = (raw['cache-duration'] as num?)?.toDouble() ?? 0.0;
  final targetSecs = cacheSecsTarget > Duration.zero
      ? durationToSeconds(cacheSecsTarget)
      : 1.0;
  return (cacheDuration / targetSecs * 100.0).clamp(0.0, 100.0);
}

/// Decodes mpv's `audio-params` (or `audio-out-params`) property
/// (`MPV_FORMAT_NODE_MAP`) into an [AudioParams] populated with the 5 fields
/// mpv exposes on the wire (`format`, `samplerate`, `channels`,
/// `channel-count`, `hr-channels`).
///
/// `codec` and `codecName` are NOT emitted by these node maps — they live
/// on separate properties (`audio-codec`, `audio-codec-name`). The caller's
/// `reduce` function should `copyWith` only the fields this parser
/// populates so the codec fields, populated by their own observers, survive
/// the merge.
AudioParams parseAudioParamsNode(dynamic raw) {
  if (raw is! Map) return const AudioParams();
  return AudioParams(
    format: _stringOrNull(raw['format']),
    sampleRate: _intOrNull(raw['samplerate']),
    channels: _stringOrNull(raw['channels']),
    channelCount: _intOrNull(raw['channel-count']),
    hrChannels: _stringOrNull(raw['hr-channels']),
  );
}

String? _stringOrNull(dynamic v) {
  if (v is! String) return null;
  if (v.isEmpty) return null;
  return v;
}

int? _intOrNull(dynamic v) {
  if (v is int) return v == 0 ? null : v;
  if (v is num) return v == 0 ? null : v.toInt();
  return null;
}
