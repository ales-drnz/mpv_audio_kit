// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/audio_filter.dart';

/// Immutable snapshot of the [Player]'s complete playback state.
///
/// Retrieve the current snapshot synchronously via `player.state`, or subscribe
/// to individual fields via the typed streams in `player.stream`.
class PlayerState {
  /// The currently loaded playlist and active track index.
  final Playlist playlist;

  /// Whether the player is currently playing (not paused and not buffering).
  final bool playing;

  /// Whether the current track has played to its end.
  ///
  /// Resets to `false` on the next [Player.play] or [Player.open] call.
  final bool completed;

  /// Current playback position.
  final Duration position;

  /// Total duration of the current track. Zero when unknown (e.g. live streams).
  final Duration duration;

  /// Current volume level, 0–100. Values above 100 amplify the signal.
  final double volume;

  /// Playback speed multiplier. 1.0 = normal speed.
  final double rate;

  /// Pitch multiplier. 1.0 = original pitch.
  final double pitch;

  /// Whether the player is currently buffering.
  final bool buffering;

  /// Absolute position up to which the demuxer has buffered content.
  ///
  /// This is an absolute timestamp from the start of the track (equivalent
  /// to `demuxer-cache-time` in mpv), not a relative duration. For example,
  /// if the current position is 1:00 and 30 s are cached ahead, [buffer] is
  /// 1:30. Use this value directly as the buffered position in audio_service
  /// or any progress-bar UI without adding [position].
  final Duration buffer;

  /// Buffer fill percentage (0.0–100.0).
  final double bufferingPercentage;

  /// Current loop / repeat mode.
  final PlaylistMode playlistMode;

  /// Whether the playlist is in shuffle mode.
  final bool shuffle;

  /// Audio format parameters from the decoder (track source).
  final AudioParams audioParams;

  /// Audio format parameters as sent to the hardware (post-processing).
  final AudioParams audioOutParams;

  /// Current audio bitrate in bps. `null` if unavailable.
  final double? audioBitrate;

  /// The currently selected audio output device.
  final AudioDevice audioDevice;

  /// All audio output devices detected by mpv.
  final List<AudioDevice> audioDevices;

  /// Whether the player is muted.
  final bool mute;

  /// Audio delay in seconds.
  final double audioDelay;

  /// Whether pitch correction is enabled when changing playback speed.
  final bool pitchCorrection;

  /// Dictionary of tags/metadata for the current track (e.g. Title, Artist).
  final Map<String, String> metadata;

  /// Gapless playback mode ('no', 'yes', 'weak').
  final String gaplessMode;

  /// ReplayGain normalization mode ('no', 'track', 'album').
  final String replayGainMode;

  /// Pre-amplification in dB for ReplayGain.
  final double replayGainPreamp;

  /// Gain applied to files without ReplayGain tags.
  final double replayGainFallback;

  /// Whether to allow clipping after ReplayGain.
  final bool replayGainClip;

  /// Software volume gain in dB.
  final double volumeGain;

  /// Cache mode ('yes', 'no', 'auto').
  final String cacheMode;

  /// Target cache duration in seconds.
  final double cacheSecs;

  /// Whether to spill cache to disk.
  final bool cacheOnDisk;

  /// Whether to pause for buffering.
  final bool cachePause;

  /// Seconds of pre-buffering required before resuming.
  final double cachePauseWait;

  /// Max bytes the demuxer can cache.
  final int demuxerMaxBytes;

  /// Seconds the demuxer fetches ahead.
  final int demuxerReadaheadSecs;

  /// Max bytes for seekback buffer.
  final int demuxerMaxBackBytes;

  /// Network timeout in seconds.
  final double networkTimeout;

  /// Whether to verify TLS/SSL certificates.
  final bool tlsVerify;

  /// Whether audio exclusive mode is enabled.
  final bool audioExclusive;

  /// Audio buffer size in seconds.
  final double audioBuffer;

  /// Whether to stream silence when nothing is playing.
  final bool streamSilence;

  /// Whether to fallback to untimed null output.
  final bool aoNullUntimed;

  /// Audio output track ID ('auto', 'no', or a number).
  final String audioTrack;

  /// S/PDIF passthrough mode.
  final String audioSpdif;

  /// Max volume limit (up to 1000).
  final double volumeMax;

  /// Target sample rate (0 for auto).
  final int audioSampleRate;

  /// Audio format ('auto', 's16', 's32', 'f32', etc.).
  final String audioFormat;

  /// Audio channel layout ('auto', 'mono', 'stereo', etc.).
  final String audioChannels;

  /// Audio client name (used by backend drivers like PulseAudio).
  final String audioClientName;

  /// Currently active audio filters.
  final List<AudioFilter> activeFilters;

  /// Current 10-band equalizer gains in dB.
  final List<double> equalizerGains;

  const PlayerState({
    this.playlist = const Playlist.empty(),
    this.playing = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 100.0,
    this.rate = 1.0,
    this.pitch = 1.0,
    this.buffering = false,
    this.buffer = Duration.zero,
    this.bufferingPercentage = 0.0,
    this.playlistMode = PlaylistMode.none,
    this.shuffle = false,
    this.audioParams = const AudioParams(),
    this.audioOutParams = const AudioParams(),
    this.audioBitrate,
    this.audioDevice = const AudioDevice('auto', 'Auto'),
    this.audioDevices = const [AudioDevice('auto', 'Auto')],
    this.mute = false,
    this.audioDelay = 0.0,
    this.pitchCorrection = true,
    this.metadata = const {},
    this.gaplessMode = 'weak',
    this.replayGainMode = 'no',
    this.replayGainPreamp = 0.0,
    this.replayGainFallback = 0.0,
    this.replayGainClip = false,
    this.volumeGain = 0.0,
    this.cacheMode = 'auto',
    this.cacheSecs = 1.0,
    this.cacheOnDisk = false,
    this.cachePause = true,
    this.cachePauseWait = 1.0,
    this.demuxerMaxBytes = 150 * 1024 * 1024,
    this.demuxerReadaheadSecs = 1,
    this.demuxerMaxBackBytes = 50 * 1024 * 1024,
    this.networkTimeout = 30.0,
    this.tlsVerify = true,
    this.audioExclusive = false,
    this.audioBuffer = 0.2,
    this.streamSilence = false,
    this.aoNullUntimed = false,
    this.audioTrack = 'auto',
    this.audioSpdif = '',
    this.volumeMax = 130.0,
    this.audioSampleRate = 0,
    this.audioFormat = 'auto',
    this.audioChannels = 'auto',
    this.audioClientName = 'mpv_audio_kit',
    this.activeFilters = const [],
    this.equalizerGains = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  });

  PlayerState copyWith({
    Playlist? playlist,
    bool? playing,
    bool? completed,
    Duration? position,
    Duration? duration,
    double? volume,
    double? rate,
    double? pitch,
    bool? buffering,
    Duration? buffer,
    double? bufferingPercentage,
    PlaylistMode? playlistMode,
    bool? shuffle,
    AudioParams? audioParams,
    AudioParams? audioOutParams,
    double? audioBitrate,
    AudioDevice? audioDevice,
    List<AudioDevice>? audioDevices,
    bool? mute,
    double? audioDelay,
    bool? pitchCorrection,
    Map<String, String>? metadata,
    String? gaplessMode,
    String? replayGainMode,
    double? replayGainPreamp,
    double? replayGainFallback,
    bool? replayGainClip,
    double? volumeGain,
    String? cacheMode,
    double? cacheSecs,
    bool? cacheOnDisk,
    bool? cachePause,
    double? cachePauseWait,
    int? demuxerMaxBytes,
    int? demuxerReadaheadSecs,
    int? demuxerMaxBackBytes,
    double? networkTimeout,
    bool? tlsVerify,
    bool? audioExclusive,
    double? audioBuffer,
    bool? streamSilence,
    bool? aoNullUntimed,
    String? audioTrack,
    String? audioSpdif,
    double? volumeMax,
    int? audioSampleRate,
    String? audioFormat,
    String? audioChannels,
    String? audioClientName,
    List<AudioFilter>? activeFilters,
    List<double>? equalizerGains,
  }) {
    return PlayerState(
      playlist: playlist ?? this.playlist,
      playing: playing ?? this.playing,
      completed: completed ?? this.completed,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      rate: rate ?? this.rate,
      pitch: pitch ?? this.pitch,
      buffering: buffering ?? this.buffering,
      buffer: buffer ?? this.buffer,
      bufferingPercentage: bufferingPercentage ?? this.bufferingPercentage,
      playlistMode: playlistMode ?? this.playlistMode,
      shuffle: shuffle ?? this.shuffle,
      audioParams: audioParams ?? this.audioParams,
      audioOutParams: audioOutParams ?? this.audioOutParams,
      audioBitrate: audioBitrate ?? this.audioBitrate,
      audioDevice: audioDevice ?? this.audioDevice,
      audioDevices: audioDevices ?? this.audioDevices,
      mute: mute ?? this.mute,
      audioDelay: audioDelay ?? this.audioDelay,
      pitchCorrection: pitchCorrection ?? this.pitchCorrection,
      metadata: metadata ?? this.metadata,
      gaplessMode: gaplessMode ?? this.gaplessMode,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      replayGainPreamp: replayGainPreamp ?? this.replayGainPreamp,
      replayGainFallback: replayGainFallback ?? this.replayGainFallback,
      replayGainClip: replayGainClip ?? this.replayGainClip,
      volumeGain: volumeGain ?? this.volumeGain,
      cacheMode: cacheMode ?? this.cacheMode,
      cacheSecs: cacheSecs ?? this.cacheSecs,
      cacheOnDisk: cacheOnDisk ?? this.cacheOnDisk,
      cachePause: cachePause ?? this.cachePause,
      cachePauseWait: cachePauseWait ?? this.cachePauseWait,
      demuxerMaxBytes: demuxerMaxBytes ?? this.demuxerMaxBytes,
      demuxerReadaheadSecs: demuxerReadaheadSecs ?? this.demuxerReadaheadSecs,
      demuxerMaxBackBytes: demuxerMaxBackBytes ?? this.demuxerMaxBackBytes,
      networkTimeout: networkTimeout ?? this.networkTimeout,
      tlsVerify: tlsVerify ?? this.tlsVerify,
      audioExclusive: audioExclusive ?? this.audioExclusive,
      audioBuffer: audioBuffer ?? this.audioBuffer,
      streamSilence: streamSilence ?? this.streamSilence,
      aoNullUntimed: aoNullUntimed ?? this.aoNullUntimed,
      audioTrack: audioTrack ?? this.audioTrack,
      audioSpdif: audioSpdif ?? this.audioSpdif,
      volumeMax: volumeMax ?? this.volumeMax,
      audioSampleRate: audioSampleRate ?? this.audioSampleRate,
      audioFormat: audioFormat ?? this.audioFormat,
      audioChannels: audioChannels ?? this.audioChannels,
      audioClientName: audioClientName ?? this.audioClientName,
      activeFilters: activeFilters ?? this.activeFilters,
      equalizerGains: equalizerGains ?? this.equalizerGains,
    );
  }

  @override
  String toString() => 'PlayerState('
      'playing: $playing, '
      'completed: $completed, '
      'position: $position, '
      'duration: $duration, '
      'volume: $volume, '
      'audioDelay: $audioDelay, '
      'pitchCorrection: $pitchCorrection, '
      'metadataCount: ${metadata.length})';
}
