// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/audio_filter.dart';
import 'package:mpv_audio_kit/src/models/mpv_log_entry.dart';

/// Typed event streams for subscribing to individual [Player] state changes.
///
/// Access via `player.stream`:
/// ```dart
/// player.stream.playing.listen((isPlaying) { ... });
/// player.stream.position.listen((pos) { ... });
/// ```
class PlayerStream {
  /// Emits whenever the active playlist changes (adds, removes, reorders).
  final Stream<Playlist> playlist;

  /// Emits `true` when playback starts, `false` when paused or stopped.
  final Stream<bool> playing;

  /// Emits `true` when the current track finishes playing to its end.
  final Stream<bool> completed;

  /// Emits the current playback position as a [Duration].
  final Stream<Duration> position;

  /// Emits the duration of the current track. Zero for live / unknown streams.
  final Stream<Duration> duration;

  /// Emits the current volume level (0–100+).
  final Stream<double> volume;

  /// Emits the current playback speed multiplier.
  final Stream<double> rate;

  /// Emits the current pitch multiplier.
  final Stream<double> pitch;

  /// Emits `true` while buffering data; `false` once playback resumes.
  final Stream<bool> buffering;

  /// Emits the current demuxer buffer depth as a [Duration].
  final Stream<Duration> buffer;

  /// Emits the buffer fill percentage (0.0–100.0).
  final Stream<double> bufferingPercentage;

  /// Emits the current [PlaylistMode] when it changes.
  final Stream<PlaylistMode> playlistMode;

  /// Emits `true` when shuffle mode is enabled.
  final Stream<bool> shuffle;

  /// Emits updated [AudioParams] from the decoder (track source).
  final Stream<AudioParams> audioParams;

  /// Emits updated [AudioParams] from the hardware output (post-processing).
  final Stream<AudioParams> audioOutParams;

  /// Emits the current audio bitrate in bps. `null` = unavailable.
  final Stream<double?> audioBitrate;

  /// Emits the currently selected [AudioDevice].
  final Stream<AudioDevice> audioDevice;

  /// Emits the full list of detected [AudioDevice]s when it changes.
  final Stream<List<AudioDevice>> audioDevices;

  /// Emits `true` when the player is muted.
  final Stream<bool> mute;

  /// Emits the current audio delay in seconds.
  final Stream<double> audioDelay;

  /// Emits `true` when pitch correction is enabled.
  final Stream<bool> pitchCorrection;

  /// Emits the metadata dictionary for the current track.
  final Stream<Map<String, String>> metadata;

  /// Emits the gapless playback mode.
  final Stream<String> gaplessMode;

  /// Emits the ReplayGain mode.
  final Stream<String> replayGainMode;

  /// Emits the ReplayGain preamp value in dB.
  final Stream<double> replayGainPreamp;

  /// Emits the ReplayGain fallback value in dB.
  final Stream<double> replayGainFallback;

  /// Emits whether ReplayGain clipping is allowed.
  final Stream<bool> replayGainClip;

  /// Emits the software volume gain in dB.
  final Stream<double> volumeGain;

  /// Emits the cache mode.
  final Stream<String> cacheMode;

  /// Emits the target cache duration in seconds.
  final Stream<double> cacheSecs;

  /// Emits whether cache on disk is enabled.
  final Stream<bool> cacheOnDisk;

  /// Emits whether pause on buffer is enabled.
  final Stream<bool> cachePause;

  /// Emits the cache pause wait duration in seconds.
  final Stream<double> cachePauseWait;

  /// Emits the max demuxer bytes.
  final Stream<int> demuxerMaxBytes;

  /// Emits the demuxer readahead duration in seconds.
  final Stream<int> demuxerReadaheadSecs;

  /// Emits the max demuxer back bytes.
  final Stream<int> demuxerMaxBackBytes;

  /// Emits the network timeout duration in seconds.
  final Stream<double> networkTimeout;

  /// Emits whether TLS verification is enabled.
  final Stream<bool> tlsVerify;

  /// Emits whether audio exclusive mode is enabled.
  final Stream<bool> audioExclusive;

  /// Emits the audio buffer duration in seconds.
  final Stream<double> audioBuffer;

  /// Emits whether stream silence is enabled.
  final Stream<bool> streamSilence;

  /// Emits whether fallback to null output is enabled.
  final Stream<bool> aoNullUntimed;

  /// Emits the current audio track ID.
  final Stream<String> audioTrack;

  /// Emits the current S/PDIF passthrough mode.
  final Stream<String> audioSpdif;

  /// Emits the max volume limit.
  final Stream<double> volumeMax;

  /// Emits the target sample rate.
  final Stream<int> audioSampleRate;

  /// Emits the target audio format.
  final Stream<String> audioFormat;

  /// Emits the target audio channels.
  final Stream<String> audioChannels;

  /// Emits the audio client name.
  final Stream<String> audioClientName;

  /// Emits the audio output driver.
  final Stream<String> audioDriver;

  /// Emits the list of currently active audio filters.
  final Stream<List<AudioFilter>> activeFilters;

  /// Emits the current equalizer gains.
  final Stream<List<double>> equalizerGains;

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Emits the current [PlayerState.audioDisplay] mode.
  final Stream<String> audioDisplay;

  /// Emits the current [PlayerState.coverArtAuto] mode.
  final Stream<String> coverArtAuto;

  /// Emits the current [PlayerState.imageDisplayDuration] value.
  final Stream<String> imageDisplayDuration;

  /// Emits human-readable error messages from the mpv engine.
  final Stream<String> error;

  /// Emits structured log entries from the mpv engine at the configured log level.
  final Stream<MpvLogEntry> log;

  const PlayerStream({
    required this.playlist,
    required this.playing,
    required this.completed,
    required this.position,
    required this.duration,
    required this.volume,
    required this.rate,
    required this.pitch,
    required this.buffering,
    required this.buffer,
    required this.bufferingPercentage,
    required this.playlistMode,
    required this.shuffle,
    required this.audioParams,
    required this.audioOutParams,
    required this.audioBitrate,
    required this.audioDevice,
    required this.audioDevices,
    required this.mute,
    required this.audioDelay,
    required this.pitchCorrection,
    required this.metadata,
    required this.gaplessMode,
    required this.replayGainMode,
    required this.replayGainPreamp,
    required this.replayGainFallback,
    required this.replayGainClip,
    required this.volumeGain,
    required this.cacheMode,
    required this.cacheSecs,
    required this.cacheOnDisk,
    required this.cachePause,
    required this.cachePauseWait,
    required this.demuxerMaxBytes,
    required this.demuxerReadaheadSecs,
    required this.demuxerMaxBackBytes,
    required this.networkTimeout,
    required this.tlsVerify,
    required this.audioExclusive,
    required this.audioBuffer,
    required this.streamSilence,
    required this.aoNullUntimed,
    required this.audioTrack,
    required this.audioSpdif,
    required this.volumeMax,
    required this.audioSampleRate,
    required this.audioFormat,
    required this.audioChannels,
    required this.audioClientName,
    required this.audioDriver,
    required this.activeFilters,
    required this.equalizerGains,
    required this.audioDisplay,
    required this.coverArtAuto,
    required this.imageDisplayDuration,
    required this.error,
    required this.log,
  });
}
