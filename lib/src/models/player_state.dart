// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/audio_filter.dart';
import 'package:mpv_audio_kit/src/models/enums.dart';

export 'package:mpv_audio_kit/src/models/enums.dart';

part 'player_state.freezed.dart';

const _kEmptyPlaylist = Playlist.empty();
const _kAutoDevice = AudioDevice('auto', 'Auto');
const _kDefaultEqualizerGains = <double>[
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
  0.0,
];
const _kDefaultAudioDevices = <AudioDevice>[_kAutoDevice];
const _kDemuxerMaxBytesDefault = 150 * 1024 * 1024;
const _kDemuxerMaxBackBytesDefault = 50 * 1024 * 1024;

/// Immutable snapshot of the [Player]'s complete playback state.
///
/// Retrieve the current snapshot synchronously via `player.state`, or subscribe
/// to individual fields via the typed streams in `player.stream`.
@freezed
abstract class PlayerState with _$PlayerState {
  const factory PlayerState({
    /// The currently loaded playlist and active track index.
    @Default(_kEmptyPlaylist) Playlist playlist,

    /// Whether the player is currently playing (not paused and not buffering).
    @Default(false) bool playing,

    /// Whether the current track has played to its end.
    ///
    /// Resets to `false` on the next [Player.play] or [Player.open] call.
    @Default(false) bool completed,

    /// Current playback position.
    @Default(Duration.zero) Duration position,

    /// Total duration of the current track. Zero when unknown (e.g. live streams).
    @Default(Duration.zero) Duration duration,

    /// Current volume level, 0–100. Values above 100 amplify the signal.
    @Default(100.0) double volume,

    /// Playback speed multiplier. 1.0 = normal speed.
    @Default(1.0) double rate,

    /// Pitch multiplier. 1.0 = original pitch.
    @Default(1.0) double pitch,

    /// Whether the player is currently buffering.
    @Default(false) bool buffering,

    /// Absolute position up to which the demuxer has buffered content.
    ///
    /// This is an absolute timestamp from the start of the track (equivalent
    /// to `demuxer-cache-time` in mpv), not a relative duration. For example,
    /// if the current position is 1:00 and 30 s are cached ahead, [buffer] is
    /// 1:30. Use this value directly as the buffered position in audio_service
    /// or any progress-bar UI without adding [position].
    @Default(Duration.zero) Duration buffer,

    /// Buffer fill percentage (0.0–100.0).
    @Default(0.0) double bufferingPercentage,

    /// Current loop / repeat mode.
    @Default(PlaylistMode.none) PlaylistMode playlistMode,

    /// Whether the playlist is in shuffle mode.
    @Default(false) bool shuffle,

    /// Audio format parameters from the decoder (track source).
    @Default(AudioParams()) AudioParams audioParams,

    /// Audio format parameters as sent to the hardware (post-processing).
    @Default(AudioParams()) AudioParams audioOutParams,

    /// Current audio bitrate in bps. `null` if unavailable.
    double? audioBitrate,

    /// The currently selected audio output device.
    @Default(_kAutoDevice) AudioDevice audioDevice,

    /// All audio output devices detected by mpv.
    @Default(_kDefaultAudioDevices) List<AudioDevice> audioDevices,

    /// Whether the player is muted.
    @Default(false) bool mute,

    /// Audio delay applied to the output stream. Positive values delay
    /// audio relative to video; negative values advance it.
    @Default(Duration.zero) Duration audioDelay,

    /// Whether pitch correction is enabled when changing playback speed.
    @Default(true) bool pitchCorrection,

    /// Dictionary of tags/metadata for the current track (e.g. Title, Artist).
    @Default(<String, String>{}) Map<String, String> metadata,

    /// Gapless playback mode.
    @Default(GaplessMode.weak) GaplessMode gaplessMode,

    /// ReplayGain normalization mode.
    @Default(ReplayGainMode.no) ReplayGainMode replayGainMode,

    /// Pre-amplification in dB for ReplayGain.
    @Default(0.0) double replayGainPreamp,

    /// Gain applied to files without ReplayGain tags.
    @Default(0.0) double replayGainFallback,

    /// Whether to allow clipping after ReplayGain.
    @Default(false) bool replayGainClip,

    /// Software volume gain in dB.
    @Default(0.0) double volumeGain,

    /// Cache mode.
    @Default(CacheMode.auto) CacheMode cacheMode,

    /// Target cache duration.
    @Default(Duration(seconds: 1)) Duration cacheSecs,

    /// Whether to spill cache to disk.
    @Default(false) bool cacheOnDisk,

    /// Whether to pause for buffering.
    @Default(true) bool cachePause,

    /// Pre-buffer required before resuming after a stall.
    @Default(Duration(seconds: 1)) Duration cachePauseWait,

    /// Max bytes the demuxer can cache.
    @Default(_kDemuxerMaxBytesDefault) int demuxerMaxBytes,

    /// Seconds the demuxer fetches ahead.
    @Default(1) int demuxerReadaheadSecs,

    /// Max bytes for seekback buffer.
    @Default(_kDemuxerMaxBackBytesDefault) int demuxerMaxBackBytes,

    /// Network connection timeout.
    @Default(Duration(seconds: 30)) Duration networkTimeout,

    /// Whether playback is paused because the network cache ran empty.
    ///
    /// This is mpv's `paused-for-cache` property — the authoritative signal
    /// for network buffering stalls. When `true`, mpv is waiting for data
    /// and will auto-resume once [cachePauseWait] seconds are buffered.
    @Default(false) bool pausedForCache,

    /// Whether the current stream is being read via a network protocol.
    ///
    /// Mirrors mpv's `demuxer-via-network` property. Useful for deciding
    /// whether an error is likely network-related.
    @Default(false) bool demuxerViaNetwork,

    /// Whether to verify TLS/SSL certificates.
    @Default(true) bool tlsVerify,

    /// Whether audio exclusive mode is enabled.
    @Default(false) bool audioExclusive,

    /// Audio buffer size.
    @Default(Duration(milliseconds: 200)) Duration audioBuffer,

    /// Whether to stream silence when nothing is playing.
    @Default(false) bool audioStreamSilence,

    /// Whether to fallback to untimed null output.
    @Default(false) bool audioNullUntimed,

    /// Audio output track ID ('auto', 'no', or a number).
    @Default('auto') String audioTrack,

    /// S/PDIF passthrough mode.
    @Default('') String audioSpdif,

    /// Max volume limit (up to 1000).
    @Default(130.0) double volumeMax,

    /// Target sample rate (0 for auto).
    @Default(0) int audioSampleRate,

    /// Audio format ('auto', 's16', 's32', 'f32', etc.).
    @Default('auto') String audioFormat,

    /// Audio channel layout ('auto', 'mono', 'stereo', etc.).
    @Default('auto') String audioChannels,

    /// Audio client name (used by backend drivers like PulseAudio).
    @Default('mpv_audio_kit') String audioClientName,

    /// Audio output driver ('auto', 'coreaudio', 'pulse', 'alsa', 'wasapi', etc.).
    @Default('auto') String audioDriver,

    /// Audio output lifecycle (`closed` / `initializing` / `active` /
    /// `failed`). See [AudioOutputState].
    @Default(AudioOutputState.closed) AudioOutputState audioOutputState,

    /// Currently active audio filters.
    @Default(<AudioFilter>[]) List<AudioFilter> activeFilters,

    /// Current 10-band equalizer gains in dB.
    @Default(_kDefaultEqualizerGains) List<double> equalizerGains,

    /// Controls how mpv handles embedded and external cover images. See
    /// [AudioDisplayMode] for the available variants.
    @Default(AudioDisplayMode.embeddedFirst) AudioDisplayMode audioDisplayMode,

    /// Controls whether mpv automatically loads external cover art files.
    /// See [CoverArtAutoMode] for the available variants.
    @Default(CoverArtAutoMode.no) CoverArtAutoMode coverArtAutoMode,

    /// Duration in seconds for which a still image (e.g. cover art) is held
    /// as a displayable video frame after the file is loaded.
    ///
    /// `'inf'` keeps the frame alive indefinitely; `'0'` (or any small
    /// value) drops it as soon as audio playback starts. Mirrors mpv's
    /// `--image-display-duration` option.
    @Default('inf') String imageDisplayDuration,
  }) = _PlayerState;
}
