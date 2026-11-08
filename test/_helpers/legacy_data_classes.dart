// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The copyWith, == and hashCode of PlayerState and MpvTrack as written by
// hand up to 0.6.1, before tool/data_classes generated them. The property
// test of the generated ones (test/models/data_classes_test.dart) compares
// with these. Frozen: never regenerate or edit them.
//
// The oracle reads the flat fields of PlayerState, deprecated since
// 0.7.0, on purpose: it is the 0.6.1 shape.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/foundation.dart' show listEquals;
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/unset_sentinel.dart';

bool _setEq<T>(Set<T> a, Set<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final e in a) {
    if (!b.contains(e)) return false;
  }
  return true;
}

bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

bool _trackMapEq(Map<String, String> a, Map<String, String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// The PlayerState of 0.6.1 built from its flat fields, by hand on the
/// group constructors of 0.7.0: the only change to this frozen oracle
/// when PlayerState took its groups.
PlayerState _legacyBuild({
  required Playlist playlist,
  required bool playing,
  required bool playWhenReady,
  required bool completed,
  required Duration position,
  required Duration duration,
  required bool seeking,
  required bool seekable,
  required bool partiallySeekable,
  required double percentPos,
  required Duration timeRemaining,
  required Duration playtimeRemaining,
  required bool eofReached,
  required Duration audioPts,
  required int? currentChapter,
  required Loop loop,
  required bool shuffle,
  required Duration? abLoopA,
  required Duration? abLoopB,
  required int? abLoopCount,
  required int? remainingAbLoops,
  required bool buffering,
  required Duration buffer,
  required double bufferingPercentage,
  required Duration bufferDuration,
  required DemuxerCacheState demuxerCacheState,
  required bool pausedForCache,
  required bool demuxerViaNetwork,
  required bool demuxerIdle,
  required double cacheSpeed,
  required int cacheBufferingState,
  required bool? readError,
  required int? skippedSegments,
  required Map<String, String> metadata,
  required Map<String, String> chapterMetadata,
  required List<Chapter> chapters,
  required List<MpvTrack> tracks,
  required MpvTrack? currentAudioTrack,
  required AudioParams audioParams,
  required double? audioBitrate,
  required CoverArt? coverArt,
  required String mediaTitle,
  required String fileFormat,
  required int fileSize,
  required String path,
  required String filename,
  required String streamPath,
  required String streamOpenFilename,
  required String playlistPath,
  required String currentDemuxer,
  required Duration demuxerStartTime,
  required AudioParams audioOutParams,
  required Device audioDevice,
  required List<Device> audioDevices,
  required AudioOutputState audioOutputState,
  required String currentAo,
  required double? systemVolume,
  required bool? systemMute,
  required double volume,
  required bool mute,
  required double volumeMax,
  required double volumeGain,
  required double volumeGainMin,
  required double volumeGainMax,
  required double rate,
  required double pitch,
  required bool pitchCorrection,
  required Duration audioDelay,
  required Gapless gapless,
  required ReplayGainSettings replayGain,
  required List<AudioEffect> audioEffects,
  required SpectrumSettings spectrum,
  required Cover coverArtAuto,
  required bool prefetchPlaylist,
  required CacheSettings cache,
  required DemuxerSettings demuxer,
  required Duration networkTimeout,
  required bool tlsVerify,
  required String tlsCaFile,
  required HlsBitrate hlsBitrate,
  required bool cookies,
  required String httpProxy,
  required bool audioExclusive,
  required bool audioMediaRole,
  required Duration audioBuffer,
  required bool audioStreamSilence,
  required bool audioNullUntimed,
  required Set<Spdif> audioSpdif,
  required int audioSampleRate,
  required Format audioFormat,
  required Channels audioChannels,
  required String audioClientName,
  required String audioDriver,
  required MediaSession? mediaSession,
  required String mpvVersion,
  required String ffmpegVersion,
}) => PlayerState(
  playback: PlaybackState(
    playlist: playlist,
    playing: playing,
    playWhenReady: playWhenReady,
    completed: completed,
    position: position,
    duration: duration,
    seeking: seeking,
    seekable: seekable,
    partiallySeekable: partiallySeekable,
    percentPos: percentPos,
    timeRemaining: timeRemaining,
    playtimeRemaining: playtimeRemaining,
    eofReached: eofReached,
    audioPts: audioPts,
    currentChapter: currentChapter,
    loop: loop,
    shuffle: shuffle,
    abLoopA: abLoopA,
    abLoopB: abLoopB,
    abLoopCount: abLoopCount,
    remainingAbLoops: remainingAbLoops,
  ),
  network: NetworkState(
    buffering: buffering,
    buffer: buffer,
    bufferingPercentage: bufferingPercentage,
    bufferDuration: bufferDuration,
    demuxerCacheState: demuxerCacheState,
    pausedForCache: pausedForCache,
    demuxerViaNetwork: demuxerViaNetwork,
    demuxerIdle: demuxerIdle,
    cacheSpeed: cacheSpeed,
    cacheBufferingState: cacheBufferingState,
    readError: readError,
    skippedSegments: skippedSegments,
  ),
  file: FileState(
    metadata: metadata,
    chapterMetadata: chapterMetadata,
    chapters: chapters,
    tracks: tracks,
    currentAudioTrack: currentAudioTrack,
    audioParams: audioParams,
    audioBitrate: audioBitrate,
    coverArt: coverArt,
    mediaTitle: mediaTitle,
    fileFormat: fileFormat,
    fileSize: fileSize,
    path: path,
    filename: filename,
    streamPath: streamPath,
    streamOpenFilename: streamOpenFilename,
    playlistPath: playlistPath,
    currentDemuxer: currentDemuxer,
    demuxerStartTime: demuxerStartTime,
  ),
  output: OutputState(
    audioOutParams: audioOutParams,
    audioDevice: audioDevice,
    audioDevices: audioDevices,
    audioOutputState: audioOutputState,
    currentAo: currentAo,
    systemVolume: systemVolume,
    systemMute: systemMute,
  ),
  settings: PlayerSettings(
    volume: volume,
    mute: mute,
    volumeMax: volumeMax,
    volumeGain: volumeGain,
    volumeGainMin: volumeGainMin,
    volumeGainMax: volumeGainMax,
    rate: rate,
    pitch: pitch,
    pitchCorrection: pitchCorrection,
    audioDelay: audioDelay,
    gapless: gapless,
    replayGain: replayGain,
    audioEffects: audioEffects,
    spectrum: spectrum,
    coverArtAuto: coverArtAuto,
    prefetchPlaylist: prefetchPlaylist,
    cache: cache,
    demuxer: demuxer,
    networkTimeout: networkTimeout,
    tlsVerify: tlsVerify,
    tlsCaFile: tlsCaFile,
    hlsBitrate: hlsBitrate,
    cookies: cookies,
    httpProxy: httpProxy,
    audioExclusive: audioExclusive,
    audioMediaRole: audioMediaRole,
    audioBuffer: audioBuffer,
    audioStreamSilence: audioStreamSilence,
    audioNullUntimed: audioNullUntimed,
    audioSpdif: audioSpdif,
    audioSampleRate: audioSampleRate,
    audioFormat: audioFormat,
    audioChannels: audioChannels,
    audioClientName: audioClientName,
    audioDriver: audioDriver,
    mediaSession: mediaSession,
  ),
  versions: LibraryVersions(
    mpvVersion: mpvVersion,
    ffmpegVersion: ffmpegVersion,
  ),
);

extension LegacyPlayerState on PlayerState {
  PlayerState legacyCopyWith({
    Playlist? playlist,
    bool? playing,
    bool? playWhenReady,
    bool? completed,
    Object? readError = unset,
    Object? skippedSegments = unset,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? buffering,
    Duration? buffer,
    double? bufferingPercentage,
    DemuxerCacheState? demuxerCacheState,
    Loop? loop,
    bool? shuffle,
    AudioParams? audioParams,
    AudioParams? audioOutParams,
    Object? audioBitrate = unset,
    Device? audioDevice,
    List<Device>? audioDevices,
    bool? mute,
    Duration? audioDelay,
    bool? pitchCorrection,
    Map<String, String>? metadata,
    Gapless? gapless,
    ReplayGainSettings? replayGain,
    double? volumeGain,
    double? volumeGainMin,
    double? volumeGainMax,
    Object? systemVolume = unset,
    Object? systemMute = unset,
    CacheSettings? cache,
    DemuxerSettings? demuxer,
    Duration? networkTimeout,
    bool? pausedForCache,
    bool? demuxerViaNetwork,
    bool? tlsVerify,
    String? tlsCaFile,
    HlsBitrate? hlsBitrate,
    bool? cookies,
    String? httpProxy,
    bool? audioExclusive,
    bool? audioMediaRole,
    Duration? audioBuffer,
    bool? audioStreamSilence,
    bool? audioNullUntimed,
    List<MpvTrack>? tracks,
    Object? currentAudioTrack = unset,
    Set<Spdif>? audioSpdif,
    double? volumeMax,
    int? audioSampleRate,
    Format? audioFormat,
    Channels? audioChannels,
    String? audioClientName,
    String? audioDriver,
    AudioOutputState? audioOutputState,
    List<AudioEffect>? audioEffects,
    SpectrumSettings? spectrum,
    Object? coverArt = unset,
    Cover? coverArtAuto,
    bool? prefetchPlaylist,
    Duration? audioPts,
    Duration? timeRemaining,
    Duration? playtimeRemaining,
    bool? eofReached,
    bool? seekable,
    bool? partiallySeekable,
    String? mediaTitle,
    String? fileFormat,
    int? fileSize,
    Duration? bufferDuration,
    bool? demuxerIdle,
    Object? currentChapter = unset,
    List<Chapter>? chapters,
    String? path,
    String? filename,
    String? streamPath,
    String? streamOpenFilename,
    String? playlistPath,
    Object? abLoopA = unset,
    Object? abLoopB = unset,
    Object? abLoopCount = unset,
    Object? remainingAbLoops = unset,
    bool? seeking,
    double? percentPos,
    double? cacheSpeed,
    int? cacheBufferingState,
    String? currentDemuxer,
    String? currentAo,
    Duration? demuxerStartTime,
    Map<String, String>? chapterMetadata,
    String? mpvVersion,
    String? ffmpegVersion,
    Object? mediaSession = unset,
  }) => _legacyBuild(
    playlist: playlist ?? this.playlist,
    playing: playing ?? this.playing,
    playWhenReady: playWhenReady ?? this.playWhenReady,
    completed: completed ?? this.completed,
    readError: identical(readError, unset)
        ? this.readError
        : readError as bool?,
    skippedSegments: identical(skippedSegments, unset)
        ? this.skippedSegments
        : skippedSegments as int?,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    volume: volume ?? this.volume,
    rate: rate ?? this.rate,
    pitch: pitch ?? this.pitch,
    buffering: buffering ?? this.buffering,
    buffer: buffer ?? this.buffer,
    bufferingPercentage: bufferingPercentage ?? this.bufferingPercentage,
    demuxerCacheState: demuxerCacheState ?? this.demuxerCacheState,
    loop: loop ?? this.loop,
    shuffle: shuffle ?? this.shuffle,
    audioParams: audioParams ?? this.audioParams,
    audioOutParams: audioOutParams ?? this.audioOutParams,
    audioBitrate: identical(audioBitrate, unset)
        ? this.audioBitrate
        : audioBitrate as double?,
    audioDevice: audioDevice ?? this.audioDevice,
    audioDevices: audioDevices ?? this.audioDevices,
    mute: mute ?? this.mute,
    audioDelay: audioDelay ?? this.audioDelay,
    pitchCorrection: pitchCorrection ?? this.pitchCorrection,
    metadata: metadata ?? this.metadata,
    gapless: gapless ?? this.gapless,
    replayGain: replayGain ?? this.replayGain,
    volumeGain: volumeGain ?? this.volumeGain,
    volumeGainMin: volumeGainMin ?? this.volumeGainMin,
    volumeGainMax: volumeGainMax ?? this.volumeGainMax,
    systemVolume: identical(systemVolume, unset)
        ? this.systemVolume
        : systemVolume as double?,
    systemMute: identical(systemMute, unset)
        ? this.systemMute
        : systemMute as bool?,
    cache: cache ?? this.cache,
    demuxer: demuxer ?? this.demuxer,
    networkTimeout: networkTimeout ?? this.networkTimeout,
    pausedForCache: pausedForCache ?? this.pausedForCache,
    demuxerViaNetwork: demuxerViaNetwork ?? this.demuxerViaNetwork,
    tlsVerify: tlsVerify ?? this.tlsVerify,
    tlsCaFile: tlsCaFile ?? this.tlsCaFile,
    hlsBitrate: hlsBitrate ?? this.hlsBitrate,
    cookies: cookies ?? this.cookies,
    httpProxy: httpProxy ?? this.httpProxy,
    audioExclusive: audioExclusive ?? this.audioExclusive,
    audioMediaRole: audioMediaRole ?? this.audioMediaRole,
    audioBuffer: audioBuffer ?? this.audioBuffer,
    audioStreamSilence: audioStreamSilence ?? this.audioStreamSilence,
    audioNullUntimed: audioNullUntimed ?? this.audioNullUntimed,
    tracks: tracks ?? this.tracks,
    currentAudioTrack: identical(currentAudioTrack, unset)
        ? this.currentAudioTrack
        : currentAudioTrack as MpvTrack?,
    audioSpdif: audioSpdif ?? this.audioSpdif,
    volumeMax: volumeMax ?? this.volumeMax,
    audioSampleRate: audioSampleRate ?? this.audioSampleRate,
    audioFormat: audioFormat ?? this.audioFormat,
    audioChannels: audioChannels ?? this.audioChannels,
    audioClientName: audioClientName ?? this.audioClientName,
    audioDriver: audioDriver ?? this.audioDriver,
    audioOutputState: audioOutputState ?? this.audioOutputState,
    audioEffects: audioEffects ?? this.audioEffects,
    spectrum: spectrum ?? this.spectrum,
    coverArt: identical(coverArt, unset)
        ? this.coverArt
        : coverArt as CoverArt?,
    coverArtAuto: coverArtAuto ?? this.coverArtAuto,
    prefetchPlaylist: prefetchPlaylist ?? this.prefetchPlaylist,
    audioPts: audioPts ?? this.audioPts,
    timeRemaining: timeRemaining ?? this.timeRemaining,
    playtimeRemaining: playtimeRemaining ?? this.playtimeRemaining,
    eofReached: eofReached ?? this.eofReached,
    seekable: seekable ?? this.seekable,
    partiallySeekable: partiallySeekable ?? this.partiallySeekable,
    mediaTitle: mediaTitle ?? this.mediaTitle,
    fileFormat: fileFormat ?? this.fileFormat,
    fileSize: fileSize ?? this.fileSize,
    bufferDuration: bufferDuration ?? this.bufferDuration,
    demuxerIdle: demuxerIdle ?? this.demuxerIdle,
    currentChapter: identical(currentChapter, unset)
        ? this.currentChapter
        : currentChapter as int?,
    chapters: chapters ?? this.chapters,
    path: path ?? this.path,
    filename: filename ?? this.filename,
    streamPath: streamPath ?? this.streamPath,
    streamOpenFilename: streamOpenFilename ?? this.streamOpenFilename,
    playlistPath: playlistPath ?? this.playlistPath,
    abLoopA: identical(abLoopA, unset) ? this.abLoopA : abLoopA as Duration?,
    abLoopB: identical(abLoopB, unset) ? this.abLoopB : abLoopB as Duration?,
    abLoopCount: identical(abLoopCount, unset)
        ? this.abLoopCount
        : abLoopCount as int?,
    remainingAbLoops: identical(remainingAbLoops, unset)
        ? this.remainingAbLoops
        : remainingAbLoops as int?,
    seeking: seeking ?? this.seeking,
    percentPos: percentPos ?? this.percentPos,
    cacheSpeed: cacheSpeed ?? this.cacheSpeed,
    cacheBufferingState: cacheBufferingState ?? this.cacheBufferingState,
    currentDemuxer: currentDemuxer ?? this.currentDemuxer,
    currentAo: currentAo ?? this.currentAo,
    demuxerStartTime: demuxerStartTime ?? this.demuxerStartTime,
    chapterMetadata: chapterMetadata ?? this.chapterMetadata,
    mpvVersion: mpvVersion ?? this.mpvVersion,
    ffmpegVersion: ffmpegVersion ?? this.ffmpegVersion,
    mediaSession: identical(mediaSession, unset)
        ? this.mediaSession
        : mediaSession as MediaSession?,
  );

  bool legacyEquals(Object other) =>
      identical(this, other) ||
      (other is PlayerState &&
          other.playlist == playlist &&
          other.playing == playing &&
          other.playWhenReady == playWhenReady &&
          other.completed == completed &&
          other.readError == readError &&
          other.skippedSegments == skippedSegments &&
          other.position == position &&
          other.duration == duration &&
          other.volume == volume &&
          other.rate == rate &&
          other.pitch == pitch &&
          other.buffering == buffering &&
          other.buffer == buffer &&
          other.bufferingPercentage == bufferingPercentage &&
          other.demuxerCacheState == demuxerCacheState &&
          other.loop == loop &&
          other.shuffle == shuffle &&
          other.audioParams == audioParams &&
          other.audioOutParams == audioOutParams &&
          other.audioBitrate == audioBitrate &&
          other.audioDevice == audioDevice &&
          _listEq(audioDevices, other.audioDevices) &&
          other.mute == mute &&
          other.audioDelay == audioDelay &&
          other.pitchCorrection == pitchCorrection &&
          _mapEq(metadata, other.metadata) &&
          other.gapless == gapless &&
          other.replayGain == replayGain &&
          other.volumeGain == volumeGain &&
          other.volumeGainMin == volumeGainMin &&
          other.volumeGainMax == volumeGainMax &&
          other.systemVolume == systemVolume &&
          other.systemMute == systemMute &&
          other.cache == cache &&
          other.demuxer == demuxer &&
          other.networkTimeout == networkTimeout &&
          other.pausedForCache == pausedForCache &&
          other.demuxerViaNetwork == demuxerViaNetwork &&
          other.tlsVerify == tlsVerify &&
          other.tlsCaFile == tlsCaFile &&
          other.hlsBitrate == hlsBitrate &&
          other.cookies == cookies &&
          other.httpProxy == httpProxy &&
          other.audioExclusive == audioExclusive &&
          other.audioMediaRole == audioMediaRole &&
          other.audioBuffer == audioBuffer &&
          other.audioStreamSilence == audioStreamSilence &&
          other.audioNullUntimed == audioNullUntimed &&
          _listEq(tracks, other.tracks) &&
          other.currentAudioTrack == currentAudioTrack &&
          _setEq(audioSpdif, other.audioSpdif) &&
          other.volumeMax == volumeMax &&
          other.audioSampleRate == audioSampleRate &&
          other.audioFormat == audioFormat &&
          other.audioChannels == audioChannels &&
          other.audioClientName == audioClientName &&
          other.audioDriver == audioDriver &&
          other.audioOutputState == audioOutputState &&
          listEquals(other.audioEffects, audioEffects) &&
          other.spectrum == spectrum &&
          other.coverArt == coverArt &&
          other.coverArtAuto == coverArtAuto &&
          other.prefetchPlaylist == prefetchPlaylist &&
          other.audioPts == audioPts &&
          other.timeRemaining == timeRemaining &&
          other.playtimeRemaining == playtimeRemaining &&
          other.eofReached == eofReached &&
          other.seekable == seekable &&
          other.partiallySeekable == partiallySeekable &&
          other.mediaTitle == mediaTitle &&
          other.fileFormat == fileFormat &&
          other.fileSize == fileSize &&
          other.bufferDuration == bufferDuration &&
          other.demuxerIdle == demuxerIdle &&
          other.currentChapter == currentChapter &&
          _listEq(chapters, other.chapters) &&
          other.path == path &&
          other.filename == filename &&
          other.streamPath == streamPath &&
          other.streamOpenFilename == streamOpenFilename &&
          other.playlistPath == playlistPath &&
          other.abLoopA == abLoopA &&
          other.abLoopB == abLoopB &&
          other.abLoopCount == abLoopCount &&
          other.remainingAbLoops == remainingAbLoops &&
          other.seeking == seeking &&
          other.percentPos == percentPos &&
          other.cacheSpeed == cacheSpeed &&
          other.cacheBufferingState == cacheBufferingState &&
          other.currentDemuxer == currentDemuxer &&
          other.currentAo == currentAo &&
          other.demuxerStartTime == demuxerStartTime &&
          _mapEq(chapterMetadata, other.chapterMetadata) &&
          other.mpvVersion == mpvVersion &&
          other.ffmpegVersion == ffmpegVersion &&
          other.mediaSession == mediaSession);

  int get legacyHashCode => Object.hashAll([
    playlist,
    playing,
    playWhenReady,
    completed,
    readError,
    skippedSegments,
    position,
    duration,
    volume,
    rate,
    pitch,
    buffering,
    buffer,
    bufferingPercentage,
    demuxerCacheState,
    loop,
    shuffle,
    audioParams,
    audioOutParams,
    audioBitrate,
    audioDevice,
    Object.hashAll(audioDevices),
    mute,
    audioDelay,
    pitchCorrection,
    Object.hashAllUnordered(
      metadata.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    gapless,
    replayGain,
    volumeGain,
    volumeGainMin,
    volumeGainMax,
    systemVolume,
    systemMute,
    cache,
    demuxer,
    networkTimeout,
    pausedForCache,
    demuxerViaNetwork,
    tlsVerify,
    tlsCaFile,
    hlsBitrate,
    cookies,
    httpProxy,
    audioExclusive,
    audioMediaRole,
    audioBuffer,
    audioStreamSilence,
    audioNullUntimed,
    Object.hashAll(tracks),
    currentAudioTrack,
    Object.hashAllUnordered(audioSpdif),
    volumeMax,
    audioSampleRate,
    audioFormat,
    audioChannels,
    audioClientName,
    audioDriver,
    audioOutputState,
    Object.hashAll(audioEffects),
    spectrum,
    coverArt,
    coverArtAuto,
    prefetchPlaylist,
    audioPts,
    timeRemaining,
    playtimeRemaining,
    eofReached,
    seekable,
    partiallySeekable,
    mediaTitle,
    fileFormat,
    fileSize,
    bufferDuration,
    demuxerIdle,
    currentChapter,
    Object.hashAll(chapters),
    path,
    filename,
    streamPath,
    streamOpenFilename,
    playlistPath,
    abLoopA,
    abLoopB,
    abLoopCount,
    remainingAbLoops,
    seeking,
    percentPos,
    cacheSpeed,
    cacheBufferingState,
    currentDemuxer,
    currentAo,
    demuxerStartTime,
    Object.hashAllUnordered(
      chapterMetadata.entries.map((e) => Object.hash(e.key, e.value)),
    ),
    mpvVersion,
    ffmpegVersion,
    mediaSession,
  ]);
}

extension LegacyMpvTrack on MpvTrack {
  MpvTrack legacyCopyWith({
    int? id,
    String? type,
    bool? selected,
    Object? title = unset,
    Object? lang = unset,
    bool? defaultTrack,
    bool? forced,
    bool? dependent,
    bool? visualImpaired,
    bool? hearingImpaired,
    bool? image,
    bool? albumArt,
    bool? external,
    Object? externalFilename = unset,
    Object? codec = unset,
    Object? codecDesc = unset,
    Object? codecProfile = unset,
    Object? decoder = unset,
    Object? decoderDesc = unset,
    Object? formatName = unset,
    Object? sampleRate = unset,
    Object? channels = unset,
    Object? channelCount = unset,
    Object? demuxBitrate = unset,
    Object? hlsBitrate = unset,
    Object? replayGainTrackGain = unset,
    Object? replayGainTrackPeak = unset,
    Object? replayGainAlbumGain = unset,
    Object? replayGainAlbumPeak = unset,
    Map<String, String>? metadata,
  }) => MpvTrack(
    id: id ?? this.id,
    type: type ?? this.type,
    selected: selected ?? this.selected,
    title: identical(title, unset) ? this.title : title as String?,
    lang: identical(lang, unset) ? this.lang : lang as String?,
    defaultTrack: defaultTrack ?? this.defaultTrack,
    forced: forced ?? this.forced,
    dependent: dependent ?? this.dependent,
    visualImpaired: visualImpaired ?? this.visualImpaired,
    hearingImpaired: hearingImpaired ?? this.hearingImpaired,
    image: image ?? this.image,
    albumArt: albumArt ?? this.albumArt,
    external: external ?? this.external,
    externalFilename: identical(externalFilename, unset)
        ? this.externalFilename
        : externalFilename as String?,
    codec: identical(codec, unset) ? this.codec : codec as String?,
    codecDesc: identical(codecDesc, unset)
        ? this.codecDesc
        : codecDesc as String?,
    codecProfile: identical(codecProfile, unset)
        ? this.codecProfile
        : codecProfile as String?,
    decoder: identical(decoder, unset) ? this.decoder : decoder as String?,
    decoderDesc: identical(decoderDesc, unset)
        ? this.decoderDesc
        : decoderDesc as String?,
    formatName: identical(formatName, unset)
        ? this.formatName
        : formatName as String?,
    sampleRate: identical(sampleRate, unset)
        ? this.sampleRate
        : sampleRate as int?,
    channels: identical(channels, unset) ? this.channels : channels as String?,
    channelCount: identical(channelCount, unset)
        ? this.channelCount
        : channelCount as int?,
    demuxBitrate: identical(demuxBitrate, unset)
        ? this.demuxBitrate
        : demuxBitrate as double?,
    hlsBitrate: identical(hlsBitrate, unset)
        ? this.hlsBitrate
        : hlsBitrate as double?,
    replayGainTrackGain: identical(replayGainTrackGain, unset)
        ? this.replayGainTrackGain
        : replayGainTrackGain as double?,
    replayGainTrackPeak: identical(replayGainTrackPeak, unset)
        ? this.replayGainTrackPeak
        : replayGainTrackPeak as double?,
    replayGainAlbumGain: identical(replayGainAlbumGain, unset)
        ? this.replayGainAlbumGain
        : replayGainAlbumGain as double?,
    replayGainAlbumPeak: identical(replayGainAlbumPeak, unset)
        ? this.replayGainAlbumPeak
        : replayGainAlbumPeak as double?,
    metadata: metadata ?? this.metadata,
  );

  bool legacyEquals(Object other) =>
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
          other.albumArt == albumArt &&
          other.external == external &&
          other.externalFilename == externalFilename &&
          other.codec == codec &&
          other.codecDesc == codecDesc &&
          other.codecProfile == codecProfile &&
          other.decoder == decoder &&
          other.decoderDesc == decoderDesc &&
          other.formatName == formatName &&
          other.sampleRate == sampleRate &&
          other.channels == channels &&
          other.channelCount == channelCount &&
          other.demuxBitrate == demuxBitrate &&
          other.hlsBitrate == hlsBitrate &&
          other.replayGainTrackGain == replayGainTrackGain &&
          other.replayGainTrackPeak == replayGainTrackPeak &&
          other.replayGainAlbumGain == replayGainAlbumGain &&
          other.replayGainAlbumPeak == replayGainAlbumPeak &&
          _trackMapEq(metadata, other.metadata));

  int get legacyHashCode => Object.hashAll([
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
    albumArt,
    external,
    externalFilename,
    codec,
    codecDesc,
    codecProfile,
    decoder,
    decoderDesc,
    formatName,
    sampleRate,
    channels,
    channelCount,
    demuxBitrate,
    hlsBitrate,
    replayGainTrackGain,
    replayGainTrackPeak,
    replayGainAlbumGain,
    replayGainAlbumPeak,
    Object.hashAllUnordered(
      metadata.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  ]);
}
