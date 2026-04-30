// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mpv_track.freezed.dart';

/// A single track entry from mpv's `track-list` (or
/// `current-tracks/audio`).
///
/// mpv reports every track in a multi-track file as a node-map: an
/// integer [id] (used for switching via [Player.setAudioTrack]), a
/// [type] (`'audio'`, `'video'`, `'sub'`, etc.), and metadata like
/// [title] / [lang] / [defaultTrack] / [forced]. Audio tracks
/// additionally expose decoder-side parameters ([samplerate],
/// [channels], [channelCount]).
///
/// The [image] / [albumart] flags distinguish embedded picture streams
/// (`attached_pic`) from regular audio tracks — set [image] to skip
/// such pseudo-tracks when populating a "switch audio track" UI.
@freezed
abstract class MpvTrack with _$MpvTrack {
  const factory MpvTrack({
    /// mpv's integer track ID. Pass to [Player.setAudioTrack] to switch.
    required int id,

    /// `'audio'` / `'video'` / `'sub'`. Empty when mpv omits the field.
    required String type,

    /// Whether mpv currently has this track selected for output.
    @Default(false) bool selected,

    /// Track title from container metadata. `null` when absent.
    String? title,

    /// ISO 639 language code from the container. `null` when absent.
    String? lang,

    /// Container's default-track flag.
    @Default(false) bool defaultTrack,

    /// Container's forced-track flag (mostly relevant for subtitles).
    @Default(false) bool forced,

    /// Whether this track is an embedded picture / cover art stream
    /// (`attached_pic`). UI track switchers should typically skip these.
    @Default(false) bool image,

    /// Whether this track is specifically marked as album art.
    @Default(false) bool albumart,

    /// Codec short name (e.g. `'flac'`, `'aac'`).
    String? codec,

    /// Human-readable codec description from libavcodec.
    String? codecDesc,

    /// Decoder-side sample rate in Hz. Audio tracks only.
    int? samplerate,

    /// Decoder-side channel layout (e.g. `'stereo'`, `'5.1'`).
    String? channels,

    /// Decoder-side channel count.
    int? channelCount,
  }) = _MpvTrack;
}
