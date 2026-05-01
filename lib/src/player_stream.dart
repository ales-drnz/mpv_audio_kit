// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:mpv_audio_kit/src/cover/cover_art_raw.dart';
import 'package:mpv_audio_kit/src/models/playback/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio/audio_params.dart';
import 'package:mpv_audio_kit/src/models/cache_config.dart';
import 'package:mpv_audio_kit/src/models/playback/chapter.dart';
import 'package:mpv_audio_kit/src/models/dsp/compressor_config.dart';
import 'package:mpv_audio_kit/src/models/enums.dart';
import 'package:mpv_audio_kit/src/models/dsp/equalizer_config.dart';
import 'package:mpv_audio_kit/src/models/dsp/loudness_config.dart';
import 'package:mpv_audio_kit/src/models/playback/mpv_track.dart';
import 'package:mpv_audio_kit/src/models/dsp/pitch_tempo_config.dart';
import 'package:mpv_audio_kit/src/models/replay_gain_config.dart';
import 'package:mpv_audio_kit/src/models/events/mpv_log_entry.dart';
import 'package:mpv_audio_kit/src/models/events/mpv_hook_event.dart';
import 'package:mpv_audio_kit/src/models/events/mpv_prefetch_state.dart';
import 'package:mpv_audio_kit/src/models/events/mpv_player_error.dart';
import 'package:mpv_audio_kit/src/internal/playback_lifecycle.dart';
import 'package:mpv_audio_kit/src/reactive/default_specs.dart';
import 'package:mpv_audio_kit/src/reactive/reactive_property.dart';

/// Typed event streams for subscribing to individual [Player] state changes.
///
/// Access via `player.stream`:
/// ```dart
/// player.stream.playing.listen((isPlaying) { ... });
/// player.stream.position.listen((pos) { ... });
/// ```
///
/// Internally each stream is the broadcast view of a [ReactiveProperty]
/// (for state-backed signals like `playing`, `volume`, `position`, …) or a
/// plain [Stream] from a [StreamController] (for transient events like
/// `error`, `endFile`, `log`).
class PlayerStream {
  PlayerStream.fromInternals({
    required DefaultPropertyReactives reactives,
    required ReactiveProperty<bool> buffering,
    required ReactiveProperty<bool> completed,
    required ReactiveProperty<Playlist> playlist,
    required ReactiveProperty<PlaylistMode> playlistMode,
    required ReactiveProperty<List<AudioDevice>> audioDevices,
    required ReactiveProperty<Map<String, String>> metadata,
    required ReactiveProperty<double> bufferingPercentage,
    required ReactiveProperty<EqualizerConfig> equalizer,
    required ReactiveProperty<CompressorConfig> compressor,
    required ReactiveProperty<LoudnessConfig> loudness,
    required ReactiveProperty<PitchTempoConfig> pitchTempo,
    required ReactiveProperty<List<String>> customAudioFilters,
    required this.endFile,
    required this.error,
    required this.log,
    required this.internalLog,
    required this.hook,
    required this.seekCompleted,
    required this.coverArtRaw,
  })  : playing = reactives.playing.stream,
        position = reactives.position.stream,
        duration = reactives.duration.stream,
        buffer = reactives.buffer.stream,
        volume = reactives.volume.stream,
        rate = reactives.rate.stream,
        pitch = reactives.pitch.stream,
        mute = reactives.mute.stream,
        shuffle = reactives.shuffle.stream,
        pitchCorrection = reactives.pitchCorrection.stream,
        audioDelay = reactives.audioDelay.stream,
        audioBitrate = reactives.audioBitrate.stream,
        audioDevice = reactives.audioDevice.stream,
        audioParams = reactives.audioParams.stream,
        // mpv exposes `audio-out-params` as a single MPV_FORMAT_NODE_MAP
        // and there is no codec / codec-name sibling on the output side, so
        // the aggregator is a direct passthrough of the node reactive.
        audioOutParams = reactives.audioOutParamsNode.stream,
        gaplessMode = reactives.gaplessMode.stream,
        replayGain = reactives.replayGain.stream,
        volumeGain = reactives.volumeGain.stream,
        cache = reactives.cache.stream,
        demuxerMaxBytes = reactives.demuxerMaxBytes.stream,
        demuxerReadaheadSecs = reactives.demuxerReadaheadSecs.stream,
        demuxerMaxBackBytes = reactives.demuxerMaxBackBytes.stream,
        networkTimeout = reactives.networkTimeout.stream,
        tlsVerify = reactives.tlsVerify.stream,
        pausedForCache = reactives.pausedForCache.stream,
        demuxerViaNetwork = reactives.demuxerViaNetwork.stream,
        audioExclusive = reactives.audioExclusive.stream,
        audioBuffer = reactives.audioBuffer.stream,
        audioStreamSilence = reactives.audioStreamSilence.stream,
        audioNullUntimed = reactives.audioNullUntimed.stream,
        tracks = reactives.tracks.stream,
        currentAudioTrack = reactives.currentAudioTrack.stream,
        audioSpdif = reactives.audioSpdif.stream,
        volumeMax = reactives.volumeMax.stream,
        audioSampleRate = reactives.audioSampleRate.stream,
        audioFormat = reactives.audioFormat.stream,
        audioChannels = reactives.audioChannels.stream,
        audioClientName = reactives.audioClientName.stream,
        audioDriver = reactives.audioDriver.stream,
        audioOutputState = reactives.audioOutputState.stream,
        audioDisplayMode = reactives.audioDisplayMode.stream,
        coverArtAutoMode = reactives.coverArtAutoMode.stream,
        imageDisplayDuration = reactives.imageDisplayDuration.stream,
        prefetchState = reactives.prefetchState.stream,
        prefetchPlaylist = reactives.prefetchPlaylist.stream,
        audioPts = reactives.audioPts.stream,
        timeRemaining = reactives.timeRemaining.stream,
        playtimeRemaining = reactives.playtimeRemaining.stream,
        eofReached = reactives.eofReached.stream,
        seekable = reactives.seekable.stream,
        partiallySeekable = reactives.partiallySeekable.stream,
        mediaTitle = reactives.mediaTitle.stream,
        fileFormat = reactives.fileFormat.stream,
        fileSize = reactives.fileSize.stream,
        bufferDuration = reactives.bufferDuration.stream,
        demuxerIdle = reactives.demuxerIdle.stream,
        currentChapter = reactives.currentChapter.stream,
        chapters = reactives.chapters.stream,
        path = reactives.path.stream,
        filename = reactives.filename.stream,
        streamPath = reactives.streamPath.stream,
        streamOpenFilename = reactives.streamOpenFilename.stream,
        abLoopA = reactives.abLoopA.stream,
        abLoopB = reactives.abLoopB.stream,
        abLoopCount = reactives.abLoopCount.stream,
        remainingAbLoops = reactives.remainingAbLoops.stream,
        seeking = reactives.seeking.stream,
        percentPos = reactives.percentPos.stream,
        cacheSpeed = reactives.cacheSpeed.stream,
        cacheBufferingState = reactives.cacheBufferingState.stream,
        currentDemuxer = reactives.currentDemuxer.stream,
        currentAo = reactives.currentAo.stream,
        demuxerStartTime = reactives.demuxerStartTime.stream,
        chapterMetadata = reactives.chapterMetadata.stream,
        mpvVersion = reactives.mpvVersion.stream,
        ffmpegVersion = reactives.ffmpegVersion.stream,
        buffering = buffering.stream,
        completed = completed.stream,
        playbackLifecycle =
            _playbackLifecycleStream(reactives, buffering, completed),
        playlist = playlist.stream,
        playlistMode = playlistMode.stream,
        audioDevices = audioDevices.stream,
        metadata = metadata.stream,
        bufferingPercentage = bufferingPercentage.stream,
        equalizer = equalizer.stream,
        compressor = compressor.stream,
        loudness = loudness.stream,
        pitchTempo = pitchTempo.stream,
        customAudioFilters = customAudioFilters.stream;

  /// Aggregate [PlaybackLifecycle] derived from the 5 underlying signals
  /// the wrapper already tracks (`playing`, `buffering`, `completed`,
  /// `pausedForCache`, `duration`). Lazy: subscriptions to the source
  /// streams open only on the first listener.
  static Stream<PlaybackLifecycle> _playbackLifecycleStream(
    DefaultPropertyReactives r,
    ReactiveProperty<bool> bufferingProp,
    ReactiveProperty<bool> completedProp,
  ) {
    PlaybackLifecycle snapshot() => derivePlaybackLifecycle(
          playing: r.playing.value,
          buffering: bufferingProp.value,
          completed: completedProp.value,
          pausedForCache: r.pausedForCache.value,
          duration: r.duration.value,
        );

    return _bindAggregate<PlaybackLifecycle>(snapshot, [
      r.playing.stream,
      bufferingProp.stream,
      completedProp.stream,
      r.pausedForCache.stream,
      r.duration.stream,
    ]);
  }

  /// Generic helper for building a broadcast aggregator stream.
  ///
  /// On the first listener, subscribes to every input [sources] stream and
  /// pipes a fresh `snapshot()` value to the output controller on each
  /// upstream event. On the last cancel, tears the subscriptions down. The
  /// controller itself is reused across listen/cancel cycles, so the same
  /// [Stream] instance can be passed around freely (e.g. as a `final`
  /// `PlayerStream.audioParams` field).
  static Stream<T> _bindAggregate<T>(
    T Function() snapshot,
    List<Stream<dynamic>> sources,
  ) {
    late final StreamController<T> ctrl;
    List<StreamSubscription<dynamic>>? subs;
    ctrl = StreamController<T>.broadcast(
      onListen: () {
        subs = [
          for (final s in sources) s.listen((_) => ctrl.add(snapshot())),
        ];
      },
      onCancel: () async {
        final toCancel = subs;
        subs = null;
        if (toCancel == null) return;
        for (final s in toCancel) {
          await s.cancel();
        }
      },
    );
    return ctrl.stream;
  }

  // ── Playback / lifecycle ─────────────────────────────────────────────────

  /// Emits whenever the active playlist changes (adds, removes, reorders).
  final Stream<Playlist> playlist;

  /// Emits `true` when playback starts, `false` when paused or stopped.
  final Stream<bool> playing;

  /// Emits `true` when the current track finishes playing to its end.
  final Stream<bool> completed;

  /// Emits the current playback position as a [Duration].
  final Stream<Duration> position;

  /// Emits once after a seek request has been fully reinitialized by mpv
  /// and playback is about to resume — i.e. the authoritative
  /// `MPV_EVENT_PLAYBACK_RESTART` signal.
  final Stream<void> seekCompleted;

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

  /// Emits aggregated [AudioParams] from the decoder (track source).
  final Stream<AudioParams> audioParams;

  /// Emits aggregated [AudioParams] from the hardware output (post-processing).
  final Stream<AudioParams> audioOutParams;

  /// Emits the current audio bitrate in bps. `null` = unavailable.
  final Stream<double?> audioBitrate;

  /// Emits the currently selected [AudioDevice].
  final Stream<AudioDevice> audioDevice;

  /// Emits the full list of detected [AudioDevice]s when it changes.
  final Stream<List<AudioDevice>> audioDevices;

  /// Emits `true` when the player is muted.
  final Stream<bool> mute;

  /// Emits the current audio delay.
  final Stream<Duration> audioDelay;

  /// Emits `true` when pitch correction is enabled.
  final Stream<bool> pitchCorrection;

  /// Emits the metadata dictionary for the current track.
  final Stream<Map<String, String>> metadata;

  /// Emits the gapless playback mode.
  final Stream<GaplessMode> gaplessMode;

  /// Aggregate ReplayGain configuration — emits a fresh
  /// [ReplayGainConfig] whenever any of mode / preamp / clip /
  /// fallback changes. Set with [Player.setReplayGain].
  final Stream<ReplayGainConfig> replayGain;

  /// Emits the software volume gain in dB.
  final Stream<double> volumeGain;

  /// Aggregate cache configuration — emits a fresh [CacheConfig]
  /// whenever any of mode / secs / onDisk / pause / pauseWait changes.
  /// Set with [Player.setCache].
  final Stream<CacheConfig> cache;

  /// Emits the max demuxer bytes.
  final Stream<int> demuxerMaxBytes;

  /// Emits the demuxer readahead duration in seconds.
  final Stream<int> demuxerReadaheadSecs;

  /// Emits the max demuxer back bytes.
  final Stream<int> demuxerMaxBackBytes;

  /// Emits the network timeout duration.
  final Stream<Duration> networkTimeout;

  /// Emits whether TLS verification is enabled.
  final Stream<bool> tlsVerify;

  /// Emits `true` when playback is paused because the network cache ran
  /// empty; `false` once mpv resumes after [cache] `pauseWait` seconds
  /// of buffered data are available again.
  final Stream<bool> pausedForCache;

  /// Emits `true` when the current stream is being read via a network
  /// protocol (HTTP, RTMP, …); `false` for local files.
  final Stream<bool> demuxerViaNetwork;

  /// Emits whether audio exclusive mode is enabled.
  final Stream<bool> audioExclusive;

  /// Emits the audio buffer duration.
  final Stream<Duration> audioBuffer;

  /// Emits whether stream silence is enabled.
  final Stream<bool> audioStreamSilence;

  /// Emits whether fallback to null output is enabled.
  final Stream<bool> audioNullUntimed;

  /// All tracks reported by mpv for the current file (audio + embedded
  /// picture + any other type the demuxer surfaced). See
  /// [PlayerState.tracks] for the filtering pattern.
  final Stream<List<MpvTrack>> tracks;

  /// Currently-active audio track, or `null` when none is selected.
  final Stream<MpvTrack?> currentAudioTrack;

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

  /// Lifecycle of mpv's audio output: `closed → initializing → active`
  /// in the success path, `→ failed` if `ao_init_best()` returns a
  /// NULL handle. The wrapper surfaces a typed [MpvLogError] on
  /// [error] the moment this stream emits [AudioOutputState.failed].
  final Stream<AudioOutputState> audioOutputState;

  /// 10-band graphic equalizer config (`@_mak_eq` filter stage).
  /// Set with [Player.setEqualizer]; modify a single field through
  /// `state.equalizer.copyWith(...)`.
  final Stream<EqualizerConfig> equalizer;

  /// Dynamic-range compressor config (`@_mak_comp` filter stage).
  /// Set with [Player.setCompressor].
  final Stream<CompressorConfig> compressor;

  /// EBU R128 loudness normalization config (`@_mak_loud` filter stage).
  /// Set with [Player.setLoudness].
  final Stream<LoudnessConfig> loudness;

  /// Pitch / tempo shifter config (`@_mak_pt` filter stage; rubberband).
  /// Set with [Player.setPitchTempo].
  final Stream<PitchTempoConfig> pitchTempo;

  /// Raw mpv `--af` filter strings inserted at the head of the chain
  /// (before any wrapper-managed DSP stage). Set with
  /// [Player.setCustomAudioFilters].
  final Stream<List<String>> customAudioFilters;

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Emits the current cover-art display mode.
  final Stream<AudioDisplayMode> audioDisplayMode;

  /// Emits the current external cover-art auto-load mode.
  final Stream<CoverArtAutoMode> coverArtAutoMode;

  /// Emits the current `image-display-duration` value. `null` = mpv's `inf`
  /// (frame held indefinitely); finite Duration = explicit hold time.
  final Stream<Duration?> imageDisplayDuration;

  /// Emits for **every** file-end event — clean completions, stops, errors,
  /// and premature EOFs alike.
  ///
  /// Use [MpvFileEndedEvent.reachedNaturalEnd] to detect whether an EOF
  /// was genuine or caused by a network disconnection.
  final Stream<MpvFileEndedEvent> endFile;

  /// Emits typed error events from the mpv engine.
  ///
  /// Use pattern matching to distinguish [MpvEndFileError] (playback
  /// failures) from [MpvLogError] (informational engine errors).
  final Stream<MpvPlayerError> error;

  /// Engine-side log entries from mpv at the configured log level
  /// (`PlayerConfiguration.logLevel`).
  ///
  /// Prefix examples: `'ffmpeg'`, `'demux'`, `'ao'`, `'cplayer'`.
  /// For wrapper-side messages (parse warnings, hook timeouts, manual
  /// `Player.log()` injections), see [internalLog].
  final Stream<MpvLogEntry> log;

  /// Wrapper-side log entries — JSON parse warnings, hook timeouts, and
  /// other messages produced by the Dart wrapper itself. Always carries
  /// `prefix: 'mpv_audio_kit'`.
  ///
  /// Disjoint from [log] so consumers can route engine and wrapper noise
  /// to different sinks (e.g. show only [log] in a debug overlay while
  /// routing [internalLog] to crash reporting).
  final Stream<MpvLogEntry> internalLog;

  /// Emits whenever mpv fires a registered hook (see `Player.registerHook`).
  final Stream<MpvHookEvent> hook;

  /// Lifecycle of mpv's background playlist-prefetch — works uniformly
  /// across HLS, DASH, raw HTTP, SMB, and local files.
  final Stream<MpvPrefetchState> prefetchState;

  /// Whether mpv prefetches the next playlist item in the background.
  /// Toggle via [Player.setPrefetchPlaylist].
  final Stream<bool> prefetchPlaylist;

  /// Audio frame timestamp at the playhead (mpv's `audio-pts`). More
  /// granular than [position] for audio-only sync.
  final Stream<Duration> audioPts;

  /// Time until end-of-file ignoring playback speed.
  final Stream<Duration> timeRemaining;

  /// Time until end-of-file adjusted for playback speed.
  final Stream<Duration> playtimeRemaining;

  /// Whether playback has reached EOF (mpv's `eof-reached`).
  final Stream<bool> eofReached;

  /// Whether the current stream supports seeking.
  final Stream<bool> seekable;

  /// Whether the stream is only partially seekable (HLS / DASH window).
  final Stream<bool> partiallySeekable;

  /// Display name for the current track (`media-title`); falls back to
  /// the file name when no `title` tag is present.
  final Stream<String> mediaTitle;

  /// Container format (e.g. `mp4`, `flac`, `mp3`).
  final Stream<String> fileFormat;

  /// Total stream size in bytes; `0` when unknown.
  final Stream<int> fileSize;

  /// Buffered duration ahead of the playhead (`demuxer-cache-duration`).
  /// Complements [buffer] (absolute timestamp) with the headroom amount.
  final Stream<Duration> bufferDuration;

  /// Whether the demuxer thread is idle (cache full or EOF).
  final Stream<bool> demuxerIdle;

  /// Active chapter index, or `null` when no chapter is active.
  /// Set via [Player.setChapter].
  final Stream<int?> currentChapter;

  /// Chapter markers for the current file.
  final Stream<List<Chapter>> chapters;

  /// Full path or URI of the current file, post-redirect.
  /// Mirrors mpv's `path`. Empty when no file is loaded.
  final Stream<String> path;

  /// File name only (no directory) of the current file.
  /// Mirrors mpv's `filename`. Empty when no file is loaded.
  final Stream<String> filename;

  /// URI as originally requested, before any `on_load` hook redirect.
  /// Mirrors mpv's `stream-path`.
  final Stream<String> streamPath;

  /// URI as actually opened post-redirect. Mirrors mpv's
  /// `stream-open-filename`.
  final Stream<String> streamOpenFilename;

  /// A-B loop start point. `null` when disabled. Set via
  /// [Player.setAbLoopA].
  final Stream<Duration?> abLoopA;

  /// A-B loop end point. `null` when disabled. Set via
  /// [Player.setAbLoopB].
  final Stream<Duration?> abLoopB;

  /// Total A-B loop repetitions. `null` = infinite. Set via
  /// [Player.setAbLoopCount].
  final Stream<int?> abLoopCount;

  /// Remaining A-B loop repetitions in the active loop. `null` when no
  /// loop is active or count is infinite. Read-only — mirrors mpv's
  /// `remaining-ab-loops`.
  final Stream<int?> remainingAbLoops;

  /// Whether mpv is currently seeking. UI gate to suppress concurrent
  /// seek commands during a long (network) seek.
  final Stream<bool> seeking;

  /// Playback position as percentage of duration (0–100).
  final Stream<double> percentPos;

  /// Demuxer cache download speed in bytes per second.
  final Stream<double> cacheSpeed;

  /// Cache fill state as percentage (0–100). mpv's own metric, distinct
  /// from [bufferingPercentage].
  final Stream<int> cacheBufferingState;

  /// Name of the active demuxer (e.g. `mkv`, `lavf`, `mp3`).
  final Stream<String> currentDemuxer;

  /// Name of the audio output driver actually in use post-resolution.
  final Stream<String> currentAo;

  /// Initial timestamp offset of the current file as reported by the
  /// demuxer.
  final Stream<Duration> demuxerStartTime;

  /// Tag dictionary for the active chapter (per-chapter metadata).
  final Stream<Map<String, String>> chapterMetadata;

  /// mpv version string. Stable for the lifetime of the [Player].
  final Stream<String> mpvVersion;

  /// FFmpeg version string. Stable for the lifetime of the [Player].
  final Stream<String> ffmpegVersion;

  /// Aggregate playback lifecycle as a single mutually-exclusive enum.
  ///
  /// Derived lazily from `playing` / `buffering` / `completed` /
  /// `pausedForCache` / `duration` — subscribing here opens
  /// subscriptions to those 5 streams only for as long as a listener
  /// is attached. See [PlaybackLifecycle] for the state mapping.
  final Stream<PlaybackLifecycle> playbackLifecycle;

  /// Embedded cover-art payload after each file load — the original
  /// codec bytes (PNG / JPEG / WEBP / …) from the file's attached
  /// picture stream, plus the MIME type. Hand straight to
  /// `Image.memory(raw.bytes)` or run your own pipeline (resize, encode,
  /// cache) — the wrapper does not process the bytes.
  ///
  /// Emits exactly once per file load: a [CoverArtRaw] when the new
  /// file has embedded artwork, or `null` when it does not. Listen for
  /// `null` to clear stale artwork on tracks without a cover.
  final Stream<CoverArtRaw?> coverArtRaw;
}
