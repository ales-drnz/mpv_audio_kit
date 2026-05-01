// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'mpv_track.freezed.dart';

/// A single track entry from mpv's `track-list` (or
/// `current-tracks/audio`).
///
/// mpv reports every track in a multi-track file as a node-map: an
/// integer [id] (used for switching via
/// `Player.setAudioTrack(AudioTrackMode.id(...))`), a
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
    /// mpv's integer track ID. Wrap in [AudioTrackMode.id] and pass to
    /// `Player.setAudioTrack` to switch to this track.
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

    /// Container's dependent-track flag. Tracks marked dependent are
    /// auxiliary streams (e.g. commentary depending on a main mix).
    @Default(false) bool dependent,

    /// Container's visual-impaired flag (audio descriptions for
    /// visually-impaired listeners).
    @Default(false) bool visualImpaired,

    /// Container's hearing-impaired flag (sub-mixes adapted for
    /// hearing-impaired listeners; common in broadcast).
    @Default(false) bool hearingImpaired,

    /// Whether this track is an embedded picture / cover art stream
    /// (`attached_pic`). UI track switchers should typically skip these.
    @Default(false) bool image,

    /// Whether this track is specifically marked as album art.
    @Default(false) bool albumart,

    /// Codec short name (e.g. `'flac'`, `'aac'`).
    String? codec,

    /// Human-readable codec description from libavcodec.
    String? codecDesc,

    /// Short decoder name actually used by mpv at runtime (`'flac'`,
    /// `'libfdk-aac'`, …). Differs from [codec] when multiple decoders
    /// are available for the same codec or when the chosen decoder is
    /// vendor-specific.
    String? decoder,

    /// Human-readable description of the decoder in use.
    String? decoderDesc,

    /// Sample format short name (e.g. `'fltp'`, `'s16'`).
    String? formatName,

    /// Decoder-side sample rate in Hz. Audio tracks only.
    int? samplerate,

    /// Decoder-side channel layout (e.g. `'stereo'`, `'5.1'`).
    String? channels,

    /// Decoder-side channel count.
    int? channelCount,

    /// Average bitrate as reported by the demuxer, in bits per second.
    /// Complements [codec] when the source's bitrate is variable or when
    /// the container's metadata doesn't carry it elsewhere.
    double? demuxBitrate,

    /// Track duration as reported by the demuxer. May differ from the
    /// file/container duration in multi-track or chapter-edited files.
    Duration? demuxDuration,

    /// HLS variant bitrate when the source is an HLS playlist, in bits
    /// per second. `null` for non-HLS sources.
    double? hlsBitrate,

    /// ReplayGain track-level gain in dB. Only present for audio tracks
    /// with corresponding tag information.
    double? replaygainTrackGain,

    /// ReplayGain track-level peak as a linear amplitude (1.0 = full
    /// scale). Only present for audio tracks with corresponding tag
    /// information.
    double? replaygainTrackPeak,

    /// ReplayGain album-level gain in dB. Falls back to per-track value
    /// when the file carries only per-track information (mpv-side
    /// behavior; future versions may stop the fallback).
    double? replaygainAlbumGain,

    /// ReplayGain album-level peak as a linear amplitude. Same fallback
    /// behavior as [replaygainAlbumGain].
    double? replaygainAlbumPeak,

    /// Per-track tag dictionary. Distinct from [PlayerState.metadata]
    /// (which is global / file-level): this is the metadata mpv keeps
    /// per stream, useful in multi-track containers where each track
    /// carries its own title / artist / role tags.
    @Default(<String, String>{}) Map<String, String> metadata,
  }) = _MpvTrack;
}
