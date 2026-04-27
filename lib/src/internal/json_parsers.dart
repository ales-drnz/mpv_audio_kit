// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:meta/meta.dart';

import '../models/audio_device.dart';
import '../models/media.dart';
import '../models/playlist.dart';
import '../utils/duration_seconds.dart';

/// Parses mpv's `playlist` JSON property into a typed [Playlist].
///
/// The mpv-emitted JSON looks like:
/// ```json
/// [{"filename": "track1.flac", "current": true},
///  {"filename": "track2.flac"}]
/// ```
///
/// [mediaCache] holds the [Media] instances that were originally passed
/// to `Player.open()` / `openPlaylist()` so we can re-attach their
/// `extras` and `httpHeaders` here — mpv only round-trips the URI,
/// everything else lives on the wrapper side.
///
/// [previous] is the previous [Playlist] state, used to recover a
/// reasonable `index` when mpv's payload omits the `current` flag (which
/// it does transiently during `playlist-move`). The caller should pass
/// the existing `state.playlist`.
///
/// Throws [FormatException] (via the underlying `json.decode`) on
/// malformed JSON. The caller is expected to wrap in try-catch and log.
@internal
Playlist parsePlaylistJson({
  required String jsonStr,
  required Map<String, Media> mediaCache,
  required Playlist previous,
}) {
  final list =
      (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
  final filenames = <String>[];
  var currentIndex = -1;
  for (var i = 0; i < list.length; i++) {
    final entry = list[i];
    filenames.add(entry['filename'] as String? ?? '');
    if (entry['current'] == true) currentIndex = i;
  }
  final medias =
      filenames.map((f) => mediaCache[f] ?? Media(f)).toList(growable: false);
  // currentIndex is -1 when mpv emits the playlist without a `current`
  // flag (e.g. transiently during playlist-move). Fall back to the last
  // known index, clamped to the new playlist's bounds — never to 0,
  // which would incorrectly mark the first item as "now playing".
  final idx = currentIndex >= 0
      ? currentIndex
      : previous.index.clamp(0, medias.isEmpty ? 0 : medias.length - 1);
  return Playlist(medias, index: idx);
}

/// Parses mpv's `audio-device-list` JSON property into a typed list.
///
/// The mpv-emitted JSON looks like:
/// ```json
/// [{"name": "auto", "description": "Autoselect device"},
///  {"name": "coreaudio/AppleHDA", "description": "Built-in Speakers"}]
/// ```
///
/// Throws [FormatException] on malformed JSON.
@internal
List<AudioDevice> parseAudioDeviceListJson(String jsonStr) {
  final list =
      (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
  return list
      .map((d) => AudioDevice(
            d['name'] as String? ?? 'unknown',
            d['description'] as String? ?? '',
          ))
      .toList(growable: false);
}

/// Parses mpv's `metadata` JSON property into a `String → String` map.
///
/// mpv emits all metadata values as strings, but the JSON encoder may
/// occasionally use `int` / `double` / `bool` literals depending on the
/// metadata source. We normalise to `String` for a stable Dart-side type.
///
/// Returns `null` (sentinel for "no update") when the input is empty
/// after trimming — mpv emits `""` rather than `"{}"` when a track has no
/// tags, and overwriting the existing map with an empty one would be
/// wrong (e.g. during a brief track-change window).
///
/// Throws [FormatException] on malformed JSON.
@internal
Map<String, String>? parseMetadataJson(String jsonStr) {
  final clean = jsonStr.trim();
  if (clean.isEmpty) return null;
  final raw = json.decode(clean) as Map<String, dynamic>;
  return raw.map((k, v) => MapEntry(k, v.toString()));
}

/// Computes the buffering percentage from mpv's `demuxer-cache-state`
/// JSON property.
///
/// The relevant field is `cache-duration` (in seconds), which is the
/// length of the buffered window from the current playback position
/// forward. The percentage is `cache-duration / cacheSecsTarget * 100`,
/// clamped to `[0, 100]`.
///
/// [cacheSecsTarget] is `state.cacheSecs`. When it is zero (default
/// before mpv reports its initial value), the function falls back to
/// 1 second — without that floor, the division would always be
/// "100% buffered" because we'd be dividing by zero.
///
/// Throws [FormatException] on malformed JSON.
@internal
double parseBufferingPercentage(
  String jsonStr,
  Duration cacheSecsTarget,
) {
  final map = json.decode(jsonStr) as Map<String, dynamic>;
  final cacheDuration = (map['cache-duration'] as num?)?.toDouble() ?? 0.0;
  final targetSecs = cacheSecsTarget > Duration.zero
      ? durationToSeconds(cacheSecsTarget)
      : 1.0;
  return (cacheDuration / targetSecs * 100.0).clamp(0.0, 100.0);
}
