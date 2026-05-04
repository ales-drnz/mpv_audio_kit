// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

const _Unset _unset = _Unset();

class _Unset {
  const _Unset();
}

bool _mapEq(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// A single track entry from mpv's `track-list` (or
/// `current-tracks/audio`).
///
/// mpv reports every track in a multi-track file as a node-map: an
/// integer [id] (used for switching via
/// `Player.setAudioTrack(Track.id(...))`), a
/// [type] (`'audio'`, `'video'`, `'sub'`, etc.), and metadata like
/// [title] / [lang] / [defaultTrack] / [forced]. Audio tracks
/// additionally expose decoder-side parameters ([samplerate],
/// [channels], [channelCount]).
///
/// The [image] / [albumart] flags distinguish embedded picture streams
/// (`attached_pic`) from regular audio tracks — set [image] to skip
/// such pseudo-tracks when populating a "switch audio track" UI.
final class MpvTrack {
  /// mpv's integer track ID. Wrap in [Track.id] and pass to
  /// `Player.setAudioTrack` to switch to this track.
  final int id;

  /// `'audio'` / `'video'` / `'sub'`. Empty when mpv omits the field.
  final String type;

  /// Whether mpv currently has this track selected for output.
  final bool selected;

  /// Track title from container metadata. `null` when absent.
  final String? title;

  /// ISO 639 language code from the container. `null` when absent.
  final String? lang;

  /// Container's default-track flag.
  final bool defaultTrack;

  /// Container's forced-track flag (mostly relevant for subtitles).
  final bool forced;

  /// Container's dependent-track flag. Tracks marked dependent are
  /// auxiliary streams (e.g. commentary depending on a main mix).
  final bool dependent;

  /// Container's visual-impaired flag (audio descriptions for
  /// visually-impaired listeners).
  final bool visualImpaired;

  /// Container's hearing-impaired flag (sub-mixes adapted for
  /// hearing-impaired listeners; common in broadcast).
  final bool hearingImpaired;

  /// Whether this track is an embedded picture / cover art stream
  /// (`attached_pic`). UI track switchers should typically skip these.
  final bool image;

  /// Whether this track is specifically marked as album art.
  final bool albumart;

  /// Codec short name (e.g. `'flac'`, `'aac'`).
  final String? codec;

  /// Human-readable codec description from libavcodec.
  final String? codecDesc;

  /// Short decoder name actually used by mpv at runtime (`'flac'`,
  /// `'libfdk-aac'`, …). Differs from [codec] when multiple decoders
  /// are available for the same codec or when the chosen decoder is
  /// vendor-specific.
  final String? decoder;

  /// Human-readable description of the decoder in use.
  final String? decoderDesc;

  /// Sample format short name (e.g. `'fltp'`, `'s16'`).
  final String? formatName;

  /// Decoder-side sample rate in Hz. Audio tracks only.
  final int? samplerate;

  /// Decoder-side channel layout (e.g. `'stereo'`, `'5.1'`).
  final String? channels;

  /// Decoder-side channel count.
  final int? channelCount;

  /// Average bitrate as reported by the demuxer, in bits per second.
  /// Complements [codec] when the source's bitrate is variable or when
  /// the container's metadata doesn't carry it elsewhere.
  final double? demuxBitrate;

  /// Track duration as reported by the demuxer. May differ from the
  /// file/container duration in multi-track or chapter-edited files.
  final Duration? demuxDuration;

  /// HLS variant bitrate when the source is an HLS playlist, in bits
  /// per second. `null` for non-HLS sources.
  final double? hlsBitrate;

  /// ReplayGain track-level gain in dB. Only present for audio tracks
  /// with corresponding tag information.
  final double? replaygainTrackGain;

  /// ReplayGain track-level peak as a linear amplitude (1.0 = full
  /// scale). Only present for audio tracks with corresponding tag
  /// information.
  final double? replaygainTrackPeak;

  /// ReplayGain album-level gain in dB. mpv falls back to the
  /// per-track value when the file carries only per-track tags.
  final double? replaygainAlbumGain;

  /// ReplayGain album-level peak as a linear amplitude. Same per-track
  /// fallback as [replaygainAlbumGain].
  final double? replaygainAlbumPeak;

  /// Per-track tag dictionary. Distinct from [PlayerState.metadata]
  /// (which is global / file-level): this is the metadata mpv keeps
  /// per stream, useful in multi-track containers where each track
  /// carries its own title / artist / role tags.
  final Map<String, String> metadata;

  const MpvTrack({
    required this.id,
    required this.type,
    this.selected = false,
    this.title,
    this.lang,
    this.defaultTrack = false,
    this.forced = false,
    this.dependent = false,
    this.visualImpaired = false,
    this.hearingImpaired = false,
    this.image = false,
    this.albumart = false,
    this.codec,
    this.codecDesc,
    this.decoder,
    this.decoderDesc,
    this.formatName,
    this.samplerate,
    this.channels,
    this.channelCount,
    this.demuxBitrate,
    this.demuxDuration,
    this.hlsBitrate,
    this.replaygainTrackGain,
    this.replaygainTrackPeak,
    this.replaygainAlbumGain,
    this.replaygainAlbumPeak,
    this.metadata = const <String, String>{},
  });

  MpvTrack copyWith({
    int? id,
    String? type,
    bool? selected,
    Object? title = _unset,
    Object? lang = _unset,
    bool? defaultTrack,
    bool? forced,
    bool? dependent,
    bool? visualImpaired,
    bool? hearingImpaired,
    bool? image,
    bool? albumart,
    Object? codec = _unset,
    Object? codecDesc = _unset,
    Object? decoder = _unset,
    Object? decoderDesc = _unset,
    Object? formatName = _unset,
    Object? samplerate = _unset,
    Object? channels = _unset,
    Object? channelCount = _unset,
    Object? demuxBitrate = _unset,
    Object? demuxDuration = _unset,
    Object? hlsBitrate = _unset,
    Object? replaygainTrackGain = _unset,
    Object? replaygainTrackPeak = _unset,
    Object? replaygainAlbumGain = _unset,
    Object? replaygainAlbumPeak = _unset,
    Map<String, String>? metadata,
  }) =>
      MpvTrack(
        id: id ?? this.id,
        type: type ?? this.type,
        selected: selected ?? this.selected,
        title: identical(title, _unset) ? this.title : title as String?,
        lang: identical(lang, _unset) ? this.lang : lang as String?,
        defaultTrack: defaultTrack ?? this.defaultTrack,
        forced: forced ?? this.forced,
        dependent: dependent ?? this.dependent,
        visualImpaired: visualImpaired ?? this.visualImpaired,
        hearingImpaired: hearingImpaired ?? this.hearingImpaired,
        image: image ?? this.image,
        albumart: albumart ?? this.albumart,
        codec: identical(codec, _unset) ? this.codec : codec as String?,
        codecDesc: identical(codecDesc, _unset)
            ? this.codecDesc
            : codecDesc as String?,
        decoder:
            identical(decoder, _unset) ? this.decoder : decoder as String?,
        decoderDesc: identical(decoderDesc, _unset)
            ? this.decoderDesc
            : decoderDesc as String?,
        formatName: identical(formatName, _unset)
            ? this.formatName
            : formatName as String?,
        samplerate:
            identical(samplerate, _unset) ? this.samplerate : samplerate as int?,
        channels:
            identical(channels, _unset) ? this.channels : channels as String?,
        channelCount: identical(channelCount, _unset)
            ? this.channelCount
            : channelCount as int?,
        demuxBitrate: identical(demuxBitrate, _unset)
            ? this.demuxBitrate
            : demuxBitrate as double?,
        demuxDuration: identical(demuxDuration, _unset)
            ? this.demuxDuration
            : demuxDuration as Duration?,
        hlsBitrate: identical(hlsBitrate, _unset)
            ? this.hlsBitrate
            : hlsBitrate as double?,
        replaygainTrackGain: identical(replaygainTrackGain, _unset)
            ? this.replaygainTrackGain
            : replaygainTrackGain as double?,
        replaygainTrackPeak: identical(replaygainTrackPeak, _unset)
            ? this.replaygainTrackPeak
            : replaygainTrackPeak as double?,
        replaygainAlbumGain: identical(replaygainAlbumGain, _unset)
            ? this.replaygainAlbumGain
            : replaygainAlbumGain as double?,
        replaygainAlbumPeak: identical(replaygainAlbumPeak, _unset)
            ? this.replaygainAlbumPeak
            : replaygainAlbumPeak as double?,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MpvTrack &&
          other.id == id &&
          other.type == type &&
          other.selected == selected &&
          other.title == title &&
          other.lang == lang &&
          other.defaultTrack == defaultTrack &&
          other.forced == forced &&
          other.dependent == dependent &&
          other.visualImpaired == visualImpaired &&
          other.hearingImpaired == hearingImpaired &&
          other.image == image &&
          other.albumart == albumart &&
          other.codec == codec &&
          other.codecDesc == codecDesc &&
          other.decoder == decoder &&
          other.decoderDesc == decoderDesc &&
          other.formatName == formatName &&
          other.samplerate == samplerate &&
          other.channels == channels &&
          other.channelCount == channelCount &&
          other.demuxBitrate == demuxBitrate &&
          other.demuxDuration == demuxDuration &&
          other.hlsBitrate == hlsBitrate &&
          other.replaygainTrackGain == replaygainTrackGain &&
          other.replaygainTrackPeak == replaygainTrackPeak &&
          other.replaygainAlbumGain == replaygainAlbumGain &&
          other.replaygainAlbumPeak == replaygainAlbumPeak &&
          _mapEq(metadata, other.metadata));

  @override
  int get hashCode => Object.hashAll([
        id,
        type,
        selected,
        title,
        lang,
        defaultTrack,
        forced,
        dependent,
        visualImpaired,
        hearingImpaired,
        image,
        albumart,
        codec,
        codecDesc,
        decoder,
        decoderDesc,
        formatName,
        samplerate,
        channels,
        channelCount,
        demuxBitrate,
        demuxDuration,
        hlsBitrate,
        replaygainTrackGain,
        replaygainTrackPeak,
        replaygainAlbumGain,
        replaygainAlbumPeak,
        Object.hashAllUnordered(
          metadata.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      ]);

  @override
  String toString() => 'MpvTrack(id: $id, type: $type, selected: $selected, '
      'title: $title, lang: $lang)';
}
