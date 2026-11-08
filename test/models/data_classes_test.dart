// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The copyWith, == and hashCode tool/data_classes generates for
// PlayerState and MpvTrack against the ones written by hand up to 0.6.1
// (test/_helpers/legacy_data_classes.dart), on random states: the same
// equality, the same hash, the same copies.

// The values are built anew on each call, not const: equal collections
// that are not identical are what == must compare.
// ignore_for_file: prefer_const_constructors

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/legacy_data_classes.dart';

/// A field: its name, the values to try (fresh on each call, so equal
/// collections are not identical), and a copy that sets it with the
/// generated copyWith and with the legacy one.
typedef _Field<T> = (
  String,
  List<Object?> Function(),
  T Function(T, Object?),
  T Function(T, Object?),
);

final List<_Field<PlayerState>> _playerState = [
  (
    'playlist',
    () => <Object?>[
      ...[
        Playlist.empty,
        Playlist([Media('a')]),
        Playlist([Media('a'), Media('b')], index: 1),
      ],
    ],
    (s, v) => s.copyWith(playlist: v as Playlist),
    (s, v) => s.legacyCopyWith(playlist: v as Playlist),
  ),
  (
    'playing',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(playing: v as bool),
    (s, v) => s.legacyCopyWith(playing: v as bool),
  ),
  (
    'playWhenReady',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(playWhenReady: v as bool),
    (s, v) => s.legacyCopyWith(playWhenReady: v as bool),
  ),
  (
    'completed',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(completed: v as bool),
    (s, v) => s.legacyCopyWith(completed: v as bool),
  ),
  (
    'readError',
    () => <Object?>[
      ...[true, false],
      null,
    ],
    (s, v) => s.copyWith(readError: v as bool?),
    (s, v) => s.legacyCopyWith(readError: v as bool?),
  ),
  (
    'skippedSegments',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(skippedSegments: v as int?),
    (s, v) => s.legacyCopyWith(skippedSegments: v as int?),
  ),
  (
    'position',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(position: v as Duration),
    (s, v) => s.legacyCopyWith(position: v as Duration),
  ),
  (
    'duration',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(duration: v as Duration),
    (s, v) => s.legacyCopyWith(duration: v as Duration),
  ),
  (
    'volume',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(volume: v as double),
    (s, v) => s.legacyCopyWith(volume: v as double),
  ),
  (
    'rate',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(rate: v as double),
    (s, v) => s.legacyCopyWith(rate: v as double),
  ),
  (
    'pitch',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(pitch: v as double),
    (s, v) => s.legacyCopyWith(pitch: v as double),
  ),
  (
    'buffering',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(buffering: v as bool),
    (s, v) => s.legacyCopyWith(buffering: v as bool),
  ),
  (
    'buffer',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(buffer: v as Duration),
    (s, v) => s.legacyCopyWith(buffer: v as Duration),
  ),
  (
    'bufferingPercentage',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(bufferingPercentage: v as double),
    (s, v) => s.legacyCopyWith(bufferingPercentage: v as double),
  ),
  (
    'demuxerCacheState',
    () => <Object?>[
      ...[
        DemuxerCacheState.empty,
        DemuxerCacheState(
          eofCached: true,
          seekableRanges: [
            CacheRange(Duration.zero, const Duration(seconds: 5)),
          ],
        ),
      ],
    ],
    (s, v) => s.copyWith(demuxerCacheState: v as DemuxerCacheState),
    (s, v) => s.legacyCopyWith(demuxerCacheState: v as DemuxerCacheState),
  ),
  (
    'loop',
    () => <Object?>[...Loop.values],
    (s, v) => s.copyWith(loop: v as Loop),
    (s, v) => s.legacyCopyWith(loop: v as Loop),
  ),
  (
    'shuffle',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(shuffle: v as bool),
    (s, v) => s.legacyCopyWith(shuffle: v as bool),
  ),
  (
    'audioParams',
    () => <Object?>[
      ...[
        const AudioParams(),
        AudioParams(sampleRate: 44100, channels: Channels.stereo),
      ],
    ],
    (s, v) => s.copyWith(audioParams: v as AudioParams),
    (s, v) => s.legacyCopyWith(audioParams: v as AudioParams),
  ),
  (
    'audioOutParams',
    () => <Object?>[
      ...[
        const AudioParams(),
        AudioParams(sampleRate: 44100, channels: Channels.stereo),
      ],
    ],
    (s, v) => s.copyWith(audioOutParams: v as AudioParams),
    (s, v) => s.legacyCopyWith(audioOutParams: v as AudioParams),
  ),
  (
    'audioBitrate',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(audioBitrate: v as double?),
    (s, v) => s.legacyCopyWith(audioBitrate: v as double?),
  ),
  (
    'audioDevice',
    () => <Object?>[
      ...[Device.auto, Device(name: 'x', description: 'X')],
    ],
    (s, v) => s.copyWith(audioDevice: v as Device),
    (s, v) => s.legacyCopyWith(audioDevice: v as Device),
  ),
  (
    'audioDevices',
    () => <Object?>[
      ...[
        <Device>[],
        [Device.auto],
        [Device.auto, Device(name: 'x', description: 'X')],
      ],
    ],
    (s, v) => s.copyWith(audioDevices: v as List<Device>),
    (s, v) => s.legacyCopyWith(audioDevices: v as List<Device>),
  ),
  (
    'mute',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(mute: v as bool),
    (s, v) => s.legacyCopyWith(mute: v as bool),
  ),
  (
    'audioDelay',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(audioDelay: v as Duration),
    (s, v) => s.legacyCopyWith(audioDelay: v as Duration),
  ),
  (
    'pitchCorrection',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(pitchCorrection: v as bool),
    (s, v) => s.legacyCopyWith(pitchCorrection: v as bool),
  ),
  (
    'metadata',
    () => <Object?>[
      ...[
        <String, String>{},
        {'a': '1'},
        {'a': '2'},
        {'a': '1', 'b': '2'},
      ],
    ],
    (s, v) => s.copyWith(metadata: v as Map<String, String>),
    (s, v) => s.legacyCopyWith(metadata: v as Map<String, String>),
  ),
  (
    'gapless',
    () => <Object?>[...Gapless.values],
    (s, v) => s.copyWith(gapless: v as Gapless),
    (s, v) => s.legacyCopyWith(gapless: v as Gapless),
  ),
  (
    'replayGain',
    () => <Object?>[
      ...[const ReplayGainSettings(), ReplayGainSettings(clip: true)],
    ],
    (s, v) => s.copyWith(replayGain: v as ReplayGainSettings),
    (s, v) => s.legacyCopyWith(replayGain: v as ReplayGainSettings),
  ),
  (
    'volumeGain',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(volumeGain: v as double),
    (s, v) => s.legacyCopyWith(volumeGain: v as double),
  ),
  (
    'volumeGainMin',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(volumeGainMin: v as double),
    (s, v) => s.legacyCopyWith(volumeGainMin: v as double),
  ),
  (
    'volumeGainMax',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(volumeGainMax: v as double),
    (s, v) => s.legacyCopyWith(volumeGainMax: v as double),
  ),
  (
    'systemVolume',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(systemVolume: v as double?),
    (s, v) => s.legacyCopyWith(systemVolume: v as double?),
  ),
  (
    'systemMute',
    () => <Object?>[
      ...[true, false],
      null,
    ],
    (s, v) => s.copyWith(systemMute: v as bool?),
    (s, v) => s.legacyCopyWith(systemMute: v as bool?),
  ),
  (
    'cache',
    () => <Object?>[
      ...[const CacheSettings(), CacheSettings(onDisk: true)],
    ],
    (s, v) => s.copyWith(cache: v as CacheSettings),
    (s, v) => s.legacyCopyWith(cache: v as CacheSettings),
  ),
  (
    'demuxer',
    () => <Object?>[
      ...[const DemuxerSettings(), DemuxerSettings(maxBytes: 1)],
    ],
    (s, v) => s.copyWith(demuxer: v as DemuxerSettings),
    (s, v) => s.legacyCopyWith(demuxer: v as DemuxerSettings),
  ),
  (
    'networkTimeout',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(networkTimeout: v as Duration),
    (s, v) => s.legacyCopyWith(networkTimeout: v as Duration),
  ),
  (
    'pausedForCache',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(pausedForCache: v as bool),
    (s, v) => s.legacyCopyWith(pausedForCache: v as bool),
  ),
  (
    'demuxerViaNetwork',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(demuxerViaNetwork: v as bool),
    (s, v) => s.legacyCopyWith(demuxerViaNetwork: v as bool),
  ),
  (
    'tlsVerify',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(tlsVerify: v as bool),
    (s, v) => s.legacyCopyWith(tlsVerify: v as bool),
  ),
  (
    'tlsCaFile',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(tlsCaFile: v as String),
    (s, v) => s.legacyCopyWith(tlsCaFile: v as String),
  ),
  (
    'hlsBitrate',
    () => <Object?>[...HlsBitrate.values],
    (s, v) => s.copyWith(hlsBitrate: v as HlsBitrate),
    (s, v) => s.legacyCopyWith(hlsBitrate: v as HlsBitrate),
  ),
  (
    'cookies',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(cookies: v as bool),
    (s, v) => s.legacyCopyWith(cookies: v as bool),
  ),
  (
    'httpProxy',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(httpProxy: v as String),
    (s, v) => s.legacyCopyWith(httpProxy: v as String),
  ),
  (
    'audioExclusive',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(audioExclusive: v as bool),
    (s, v) => s.legacyCopyWith(audioExclusive: v as bool),
  ),
  (
    'audioMediaRole',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(audioMediaRole: v as bool),
    (s, v) => s.legacyCopyWith(audioMediaRole: v as bool),
  ),
  (
    'audioBuffer',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(audioBuffer: v as Duration),
    (s, v) => s.legacyCopyWith(audioBuffer: v as Duration),
  ),
  (
    'audioStreamSilence',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(audioStreamSilence: v as bool),
    (s, v) => s.legacyCopyWith(audioStreamSilence: v as bool),
  ),
  (
    'audioNullUntimed',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(audioNullUntimed: v as bool),
    (s, v) => s.legacyCopyWith(audioNullUntimed: v as bool),
  ),
  (
    'tracks',
    () => <Object?>[
      ...[
        <MpvTrack>[],
        [MpvTrack(id: 1, type: 'audio')],
        [MpvTrack(id: 2, type: 'audio', title: 'x')],
      ],
    ],
    (s, v) => s.copyWith(tracks: v as List<MpvTrack>),
    (s, v) => s.legacyCopyWith(tracks: v as List<MpvTrack>),
  ),
  (
    'currentAudioTrack',
    () => <Object?>[
      ...[
        MpvTrack(id: 1, type: 'audio'),
        MpvTrack(id: 2, type: 'audio', title: 'x', metadata: {'k': 'v'}),
      ],
      null,
    ],
    (s, v) => s.copyWith(currentAudioTrack: v as MpvTrack?),
    (s, v) => s.legacyCopyWith(currentAudioTrack: v as MpvTrack?),
  ),
  (
    'audioSpdif',
    () => <Object?>[
      ...[
        <Spdif>{},
        {Spdif.values.first},
        Spdif.values.toSet(),
      ],
    ],
    (s, v) => s.copyWith(audioSpdif: v as Set<Spdif>),
    (s, v) => s.legacyCopyWith(audioSpdif: v as Set<Spdif>),
  ),
  (
    'volumeMax',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(volumeMax: v as double),
    (s, v) => s.legacyCopyWith(volumeMax: v as double),
  ),
  (
    'audioSampleRate',
    () => <Object?>[
      ...[0, 1, 42],
    ],
    (s, v) => s.copyWith(audioSampleRate: v as int),
    (s, v) => s.legacyCopyWith(audioSampleRate: v as int),
  ),
  (
    'audioFormat',
    () => <Object?>[...Format.values],
    (s, v) => s.copyWith(audioFormat: v as Format),
    (s, v) => s.legacyCopyWith(audioFormat: v as Format),
  ),
  (
    'audioChannels',
    () => <Object?>[
      ...[Channels.auto, Channels.stereo, Channels.mono],
    ],
    (s, v) => s.copyWith(audioChannels: v as Channels),
    (s, v) => s.legacyCopyWith(audioChannels: v as Channels),
  ),
  (
    'audioClientName',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(audioClientName: v as String),
    (s, v) => s.legacyCopyWith(audioClientName: v as String),
  ),
  (
    'audioDriver',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(audioDriver: v as String),
    (s, v) => s.legacyCopyWith(audioDriver: v as String),
  ),
  (
    'audioOutputState',
    () => <Object?>[...AudioOutputState.values],
    (s, v) => s.copyWith(audioOutputState: v as AudioOutputState),
    (s, v) => s.legacyCopyWith(audioOutputState: v as AudioOutputState),
  ),
  (
    'audioEffects',
    () => <Object?>[
      ...[
        <AudioEffect>[],
        [AtempoEffect(tempo: 1.5)],
        [AtempoEffect(tempo: 1.5), const AtempoEffect()],
      ],
    ],
    (s, v) => s.copyWith(audioEffects: v as List<AudioEffect>),
    (s, v) => s.legacyCopyWith(audioEffects: v as List<AudioEffect>),
  ),
  (
    'spectrum',
    () => <Object?>[
      ...[SpectrumSettings.defaults, SpectrumSettings(fftSize: 1024)],
    ],
    (s, v) => s.copyWith(spectrum: v as SpectrumSettings),
    (s, v) => s.legacyCopyWith(spectrum: v as SpectrumSettings),
  ),
  (
    'coverArt',
    () => <Object?>[
      ...[
        CoverArt(bytes: Uint8List.fromList([1, 2]), mimeType: 'image/png'),
        CoverArt(bytes: Uint8List.fromList([3]), mimeType: 'image/jpeg'),
      ],
      null,
    ],
    (s, v) => s.copyWith(coverArt: v as CoverArt?),
    (s, v) => s.legacyCopyWith(coverArt: v as CoverArt?),
  ),
  (
    'coverArtAuto',
    () => <Object?>[...Cover.values],
    (s, v) => s.copyWith(coverArtAuto: v as Cover),
    (s, v) => s.legacyCopyWith(coverArtAuto: v as Cover),
  ),
  (
    'prefetchPlaylist',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(prefetchPlaylist: v as bool),
    (s, v) => s.legacyCopyWith(prefetchPlaylist: v as bool),
  ),
  (
    'audioPts',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(audioPts: v as Duration),
    (s, v) => s.legacyCopyWith(audioPts: v as Duration),
  ),
  (
    'timeRemaining',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(timeRemaining: v as Duration),
    (s, v) => s.legacyCopyWith(timeRemaining: v as Duration),
  ),
  (
    'playtimeRemaining',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(playtimeRemaining: v as Duration),
    (s, v) => s.legacyCopyWith(playtimeRemaining: v as Duration),
  ),
  (
    'eofReached',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(eofReached: v as bool),
    (s, v) => s.legacyCopyWith(eofReached: v as bool),
  ),
  (
    'seekable',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(seekable: v as bool),
    (s, v) => s.legacyCopyWith(seekable: v as bool),
  ),
  (
    'partiallySeekable',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(partiallySeekable: v as bool),
    (s, v) => s.legacyCopyWith(partiallySeekable: v as bool),
  ),
  (
    'mediaTitle',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(mediaTitle: v as String),
    (s, v) => s.legacyCopyWith(mediaTitle: v as String),
  ),
  (
    'fileFormat',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(fileFormat: v as String),
    (s, v) => s.legacyCopyWith(fileFormat: v as String),
  ),
  (
    'fileSize',
    () => <Object?>[
      ...[0, 1, 42],
    ],
    (s, v) => s.copyWith(fileSize: v as int),
    (s, v) => s.legacyCopyWith(fileSize: v as int),
  ),
  (
    'bufferDuration',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(bufferDuration: v as Duration),
    (s, v) => s.legacyCopyWith(bufferDuration: v as Duration),
  ),
  (
    'demuxerIdle',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(demuxerIdle: v as bool),
    (s, v) => s.legacyCopyWith(demuxerIdle: v as bool),
  ),
  (
    'currentChapter',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(currentChapter: v as int?),
    (s, v) => s.legacyCopyWith(currentChapter: v as int?),
  ),
  (
    'chapters',
    () => <Object?>[
      ...[
        <Chapter>[],
        [Chapter(time: Duration.zero, title: 'c')],
        [Chapter(time: const Duration(seconds: 1))],
      ],
    ],
    (s, v) => s.copyWith(chapters: v as List<Chapter>),
    (s, v) => s.legacyCopyWith(chapters: v as List<Chapter>),
  ),
  (
    'path',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(path: v as String),
    (s, v) => s.legacyCopyWith(path: v as String),
  ),
  (
    'filename',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(filename: v as String),
    (s, v) => s.legacyCopyWith(filename: v as String),
  ),
  (
    'streamPath',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(streamPath: v as String),
    (s, v) => s.legacyCopyWith(streamPath: v as String),
  ),
  (
    'streamOpenFilename',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(streamOpenFilename: v as String),
    (s, v) => s.legacyCopyWith(streamOpenFilename: v as String),
  ),
  (
    'playlistPath',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(playlistPath: v as String),
    (s, v) => s.legacyCopyWith(playlistPath: v as String),
  ),
  (
    'abLoopA',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
      null,
    ],
    (s, v) => s.copyWith(abLoopA: v as Duration?),
    (s, v) => s.legacyCopyWith(abLoopA: v as Duration?),
  ),
  (
    'abLoopB',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
      null,
    ],
    (s, v) => s.copyWith(abLoopB: v as Duration?),
    (s, v) => s.legacyCopyWith(abLoopB: v as Duration?),
  ),
  (
    'abLoopCount',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(abLoopCount: v as int?),
    (s, v) => s.legacyCopyWith(abLoopCount: v as int?),
  ),
  (
    'remainingAbLoops',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(remainingAbLoops: v as int?),
    (s, v) => s.legacyCopyWith(remainingAbLoops: v as int?),
  ),
  (
    'seeking',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(seeking: v as bool),
    (s, v) => s.legacyCopyWith(seeking: v as bool),
  ),
  (
    'percentPos',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(percentPos: v as double),
    (s, v) => s.legacyCopyWith(percentPos: v as double),
  ),
  (
    'cacheSpeed',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
    ],
    (s, v) => s.copyWith(cacheSpeed: v as double),
    (s, v) => s.legacyCopyWith(cacheSpeed: v as double),
  ),
  (
    'cacheBufferingState',
    () => <Object?>[
      ...[0, 1, 42],
    ],
    (s, v) => s.copyWith(cacheBufferingState: v as int),
    (s, v) => s.legacyCopyWith(cacheBufferingState: v as int),
  ),
  (
    'currentDemuxer',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(currentDemuxer: v as String),
    (s, v) => s.legacyCopyWith(currentDemuxer: v as String),
  ),
  (
    'currentAo',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(currentAo: v as String),
    (s, v) => s.legacyCopyWith(currentAo: v as String),
  ),
  (
    'demuxerStartTime',
    () => <Object?>[
      ...[
        Duration.zero,
        const Duration(seconds: 3),
        Duration(milliseconds: 1500),
      ],
    ],
    (s, v) => s.copyWith(demuxerStartTime: v as Duration),
    (s, v) => s.legacyCopyWith(demuxerStartTime: v as Duration),
  ),
  (
    'chapterMetadata',
    () => <Object?>[
      ...[
        <String, String>{},
        {'a': '1'},
        {'a': '2'},
        {'a': '1', 'b': '2'},
      ],
    ],
    (s, v) => s.copyWith(chapterMetadata: v as Map<String, String>),
    (s, v) => s.legacyCopyWith(chapterMetadata: v as Map<String, String>),
  ),
  (
    'mpvVersion',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(mpvVersion: v as String),
    (s, v) => s.legacyCopyWith(mpvVersion: v as String),
  ),
  (
    'ffmpegVersion',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(ffmpegVersion: v as String),
    (s, v) => s.legacyCopyWith(ffmpegVersion: v as String),
  ),
  (
    'mediaSession',
    () => <Object?>[
      ...[const MediaSession(), MediaSession(title: 't')],
      null,
    ],
    (s, v) => s.copyWith(mediaSession: v as MediaSession?),
    (s, v) => s.legacyCopyWith(mediaSession: v as MediaSession?),
  ),
];

final List<_Field<MpvTrack>> _mpvTrack = [
  (
    'id',
    () => <Object?>[
      ...[0, 1, 42],
    ],
    (s, v) => s.copyWith(id: v as int),
    (s, v) => s.legacyCopyWith(id: v as int),
  ),
  (
    'type',
    () => <Object?>[
      ...['', 'a', 'b'],
    ],
    (s, v) => s.copyWith(type: v as String),
    (s, v) => s.legacyCopyWith(type: v as String),
  ),
  (
    'selected',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(selected: v as bool),
    (s, v) => s.legacyCopyWith(selected: v as bool),
  ),
  (
    'title',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(title: v as String?),
    (s, v) => s.legacyCopyWith(title: v as String?),
  ),
  (
    'lang',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(lang: v as String?),
    (s, v) => s.legacyCopyWith(lang: v as String?),
  ),
  (
    'defaultTrack',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(defaultTrack: v as bool),
    (s, v) => s.legacyCopyWith(defaultTrack: v as bool),
  ),
  (
    'forced',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(forced: v as bool),
    (s, v) => s.legacyCopyWith(forced: v as bool),
  ),
  (
    'dependent',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(dependent: v as bool),
    (s, v) => s.legacyCopyWith(dependent: v as bool),
  ),
  (
    'visualImpaired',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(visualImpaired: v as bool),
    (s, v) => s.legacyCopyWith(visualImpaired: v as bool),
  ),
  (
    'hearingImpaired',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(hearingImpaired: v as bool),
    (s, v) => s.legacyCopyWith(hearingImpaired: v as bool),
  ),
  (
    'image',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(image: v as bool),
    (s, v) => s.legacyCopyWith(image: v as bool),
  ),
  (
    'albumArt',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(albumArt: v as bool),
    (s, v) => s.legacyCopyWith(albumArt: v as bool),
  ),
  (
    'external',
    () => <Object?>[
      ...[true, false],
    ],
    (s, v) => s.copyWith(external: v as bool),
    (s, v) => s.legacyCopyWith(external: v as bool),
  ),
  (
    'externalFilename',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(externalFilename: v as String?),
    (s, v) => s.legacyCopyWith(externalFilename: v as String?),
  ),
  (
    'codec',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(codec: v as String?),
    (s, v) => s.legacyCopyWith(codec: v as String?),
  ),
  (
    'codecDesc',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(codecDesc: v as String?),
    (s, v) => s.legacyCopyWith(codecDesc: v as String?),
  ),
  (
    'codecProfile',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(codecProfile: v as String?),
    (s, v) => s.legacyCopyWith(codecProfile: v as String?),
  ),
  (
    'decoder',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(decoder: v as String?),
    (s, v) => s.legacyCopyWith(decoder: v as String?),
  ),
  (
    'decoderDesc',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(decoderDesc: v as String?),
    (s, v) => s.legacyCopyWith(decoderDesc: v as String?),
  ),
  (
    'formatName',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(formatName: v as String?),
    (s, v) => s.legacyCopyWith(formatName: v as String?),
  ),
  (
    'sampleRate',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(sampleRate: v as int?),
    (s, v) => s.legacyCopyWith(sampleRate: v as int?),
  ),
  (
    'channels',
    () => <Object?>[
      ...['', 'a', 'b'],
      null,
    ],
    (s, v) => s.copyWith(channels: v as String?),
    (s, v) => s.legacyCopyWith(channels: v as String?),
  ),
  (
    'channelCount',
    () => <Object?>[
      ...[0, 1, 42],
      null,
    ],
    (s, v) => s.copyWith(channelCount: v as int?),
    (s, v) => s.legacyCopyWith(channelCount: v as int?),
  ),
  (
    'demuxBitrate',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(demuxBitrate: v as double?),
    (s, v) => s.legacyCopyWith(demuxBitrate: v as double?),
  ),
  (
    'hlsBitrate',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(hlsBitrate: v as double?),
    (s, v) => s.legacyCopyWith(hlsBitrate: v as double?),
  ),
  (
    'replayGainTrackGain',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(replayGainTrackGain: v as double?),
    (s, v) => s.legacyCopyWith(replayGainTrackGain: v as double?),
  ),
  (
    'replayGainTrackPeak',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(replayGainTrackPeak: v as double?),
    (s, v) => s.legacyCopyWith(replayGainTrackPeak: v as double?),
  ),
  (
    'replayGainAlbumGain',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(replayGainAlbumGain: v as double?),
    (s, v) => s.legacyCopyWith(replayGainAlbumGain: v as double?),
  ),
  (
    'replayGainAlbumPeak',
    () => <Object?>[
      ...[0.0, -0.0, 1.5, -2.0, double.nan],
      null,
    ],
    (s, v) => s.copyWith(replayGainAlbumPeak: v as double?),
    (s, v) => s.legacyCopyWith(replayGainAlbumPeak: v as double?),
  ),
  (
    'metadata',
    () => <Object?>[
      ...[
        <String, String>{},
        {'a': '1'},
        {'a': '2'},
        {'a': '1', 'b': '2'},
      ],
    ],
    (s, v) => s.copyWith(metadata: v as Map<String, String>),
    (s, v) => s.legacyCopyWith(metadata: v as Map<String, String>),
  ),
];

/// [start] with [count] random fields set through the legacy copyWith.
T _random<T>(Random r, T start, List<_Field<T>> fields, int count) {
  var s = start;
  for (var i = 0; i < count; i++) {
    final (_, values, _, legacy) = fields[r.nextInt(fields.length)];
    final pool = values();
    s = legacy(s, pool[r.nextInt(pool.length)]);
  }
  return s;
}

/// The name of the data class in the library [source].
String _className(String source) => RegExp(
  r'final class (\w+) with',
).firstMatch(File(source).readAsStringSync())![1]!;

/// The parameters of the unnamed constructor of [name] in the library
/// The fields of the groups added after 0.6.1, which the code written by
/// hand never had: the generated code has nothing to match them against.
const _since070 = {'durationEstimated'};

/// [source], in their order: each `this.x`.
List<String> _constructorFields(String source, String name) {
  final text = File(source).readAsStringSync();
  final start = text.indexOf('const $name({');
  final end = text.indexOf('});', start);
  return [
    for (final m in RegExp(
      r'this\.(\w+)',
    ).allMatches(text.substring(start, end)))
      m[1]!,
  ];
}

void _check<T extends Object>({
  required String name,
  required String source,
  required T start,
  required List<_Field<T>> fields,
  required bool Function(T, Object) legacyEquals,
  required int Function(T) legacyHash,
  List<String>? groupSources,
}) {
  group(name, () {
    test('every field of the constructor is in the table', () {
      // A class made of groups: its fields are the ones of the groups.
      final expected = groupSources == null
          ? _constructorFields(source, name)
          : [
              for (final g in groupSources)
                for (final f in _constructorFields(g, _className(g)))
                  if (!_since070.contains(f)) f,
            ];
      expect(fields.map((f) => f.$1).toSet(), expected.toSet());
      expect(fields.length, expected.length);
    });

    test('== and hashCode match the legacy ones on random pairs', () {
      final r = Random(20261104);
      for (var i = 0; i < 3000; i++) {
        final a = _random(r, start, fields, r.nextInt(6));
        // Half the time b starts as a copy of a, so equal pairs come up.
        final b = r.nextBool()
            ? _random(r, a, fields, r.nextInt(2))
            : _random(r, start, fields, r.nextInt(6));
        expect(a == b, legacyEquals(a, b), reason: '$i: $a vs $b');
        expect(b == a, legacyEquals(b, a), reason: '$i');
        // A composite hashes its groups: the legacy hash of the flat
        // fields is another number, and only equal states, equal hashes
        // holds.
        if (groupSources == null) {
          expect(a.hashCode, legacyHash(a), reason: '$i');
        }
        if (a == b) expect(a.hashCode, b.hashCode, reason: '$i');
      }
    });

    test('copyWith of each field and value gives the legacy copy', () {
      final r = Random(4112026);
      for (var i = 0; i < 300; i++) {
        final s = _random(r, start, fields, r.nextInt(8));
        for (final (field, values, copy, legacy) in fields) {
          for (final v in values()) {
            final mine = copy(s, v);
            final theirs = legacy(s, v);
            // A NaN is equal to nothing, itself included: the copy equals
            // the legacy one exactly when two legacy copies are equal.
            final self = legacyEquals(theirs, legacy(s, v));
            expect(legacyEquals(mine, theirs), self, reason: '$field = $v');
            expect(mine == theirs, self, reason: '$field = $v');
          }
        }
      }
    });
  });
}

void main() {
  _check(
    name: 'PlayerState',
    source: 'lib/src/player/player_state.dart',
    start: const PlayerState(),
    fields: _playerState,
    legacyEquals: (a, b) => a.legacyEquals(b),
    legacyHash: (s) => s.legacyHashCode,
    groupSources: [
      'lib/src/player/state/playback_state.dart',
      'lib/src/player/state/network_state.dart',
      'lib/src/player/state/file_state.dart',
      'lib/src/player/state/output_state.dart',
      'lib/src/player/state/player_settings.dart',
      'lib/src/player/state/library_versions.dart',
    ],
  );
  _check(
    name: 'MpvTrack',
    source: 'lib/src/models/mpv_track.dart',
    start: const MpvTrack(id: 0, type: 'audio'),
    fields: _mpvTrack,
    legacyEquals: (a, b) => a.legacyEquals(b),
    legacyHash: (s) => s.legacyHashCode,
  );
}
