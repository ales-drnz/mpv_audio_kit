// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/audio_filter.dart';
import 'package:mpv_audio_kit/src/models/cache_config.dart';
import 'package:mpv_audio_kit/src/models/chapter.dart';
import 'package:mpv_audio_kit/src/models/enums.dart';
import 'package:mpv_audio_kit/src/models/mpv_track.dart';
import 'package:mpv_audio_kit/src/models/replay_gain_config.dart';

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

    /// ReplayGain configuration aggregate (mode + preamp + clip +
    /// fallback). Set the whole config atomically via
    /// [Player.setReplayGain]; modify a single field through
    /// `state.replayGain.copyWith(...)`.
    @Default(ReplayGainConfig()) ReplayGainConfig replayGain,

    /// Software volume gain in dB.
    @Default(0.0) double volumeGain,

    /// Cache configuration aggregate (mode + secs + onDisk + pause +
    /// pauseWait). Set atomically via [Player.setCache]; modify a single
    /// field through `state.cache.copyWith(...)`.
    @Default(CacheConfig()) CacheConfig cache,

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

    /// All tracks reported by mpv for the current file (audio, video,
    /// embedded picture, …). Filter by [MpvTrack.type] for a typed
    /// "audio tracks only" view; switch via [Player.setAudioTrack].
    @Default(<MpvTrack>[]) List<MpvTrack> tracks,

    /// Currently-active audio track, or `null` when no audio is
    /// selected. Mirrors mpv's `current-tracks/audio`.
    MpvTrack? currentAudioTrack,

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

    /// How long a still image (e.g. cover art) is held as a displayable
    /// video frame after the file is loaded.
    ///
    /// `null` keeps the frame alive indefinitely (mpv's `inf`);
    /// `Duration.zero` drops it as soon as audio playback starts. Mirrors
    /// mpv's `--image-display-duration` option.
    Duration? imageDisplayDuration,

    /// Whether mpv prefetches the next playlist item in the background.
    ///
    /// When `true`, the demuxer for the next track opens before the current
    /// one finishes, eliminating the file-boundary stall. Observe progress
    /// via [PlayerStream.prefetchState].
    @Default(false) bool prefetchPlaylist,

    /// Audio frame timestamp at the playhead. Advances per audio frame
    /// (more granular than `position`, which mpv updates on a fixed
    /// schedule) and includes audio driver latency. Useful for
    /// audio-only sync calculations.
    @Default(Duration.zero) Duration audioPts,

    /// Time remaining until the file ends, ignoring playback speed.
    @Default(Duration.zero) Duration timeRemaining,

    /// Time remaining until the file ends, adjusted for playback speed —
    /// what the listener will actually wait. At 2.0x speed on a 60 s
    /// remaining file this is 30 s.
    @Default(Duration.zero) Duration playtimeRemaining,

    /// Whether playback has reached end-of-file. Distinct from
    /// `completed` (lifecycle flag): `eofReached` mirrors mpv's
    /// `eof-reached` and disambiguates a natural EOF from a user pause.
    @Default(false) bool eofReached,

    /// Whether the current stream supports seeking at all (live streams
    /// often do not).
    @Default(false) bool seekable,

    /// Whether the stream is partially seekable — only some ranges are
    /// reachable (typical for HLS / DASH when only a sliding window is
    /// available).
    @Default(false) bool partiallySeekable,

    /// Display name for the current track. Falls back to the file name
    /// when no `title` tag is available. Mirrors mpv's `media-title`.
    @Default('') String mediaTitle,

    /// Container format (e.g. `mp4`, `m4a`, `flac`, `mp3`). Comma-separated
    /// list when the demuxer matches multiple formats.
    @Default('') String fileFormat,

    /// Total stream size in bytes. Zero when unknown (live streams).
    @Default(0) int fileSize,

    /// Buffered duration ahead of the playhead — `demuxer-cache-duration`.
    /// Complements [buffer] (which is `demuxer-cache-time`, an absolute
    /// timestamp): [bufferDuration] is the headroom.
    @Default(Duration.zero) Duration bufferDuration,

    /// Whether the demuxer thread is idle. `true` while the demuxer has
    /// no data to fetch (cache full or EOF); `false` while pulling.
    /// Combined with `pausedForCache` it disambiguates "starved network"
    /// from "fully cached, sitting idle".
    @Default(true) bool demuxerIdle,

    /// Index of the active chapter (0-based), or `null` when no chapter
    /// is active or the file has none. Setter: [Player.setChapter].
    int? currentChapter,

    /// Chapters in the current file (audiobook / podcast markers).
    /// Empty list when the file carries no chapter table.
    @Default(<Chapter>[]) List<Chapter> chapters,
  }) = _PlayerState;
}
