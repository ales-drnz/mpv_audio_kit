// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';

import 'package:mpv_audio_kit/src/cover/cover_art_raw.dart';
import 'package:mpv_audio_kit/src/models/playlist.dart';
import 'package:mpv_audio_kit/src/models/audio_device.dart';
import 'package:mpv_audio_kit/src/models/audio_params.dart';
import 'package:mpv_audio_kit/src/models/audio_filter.dart';
import 'package:mpv_audio_kit/src/models/enums.dart';
import 'package:mpv_audio_kit/src/models/mpv_log_entry.dart';
import 'package:mpv_audio_kit/src/models/mpv_hook_event.dart';
import 'package:mpv_audio_kit/src/models/mpv_prefetch_state.dart';
import 'package:mpv_audio_kit/src/models/mpv_player_error.dart';
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
    required ReactiveProperty<List<double>> equalizerGains,
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
        audioParams = _audioParamsStream(reactives),
        audioOutParams = _audioOutParamsStream(reactives),
        gaplessMode = reactives.gaplessMode.stream,
        replayGainMode = reactives.replayGainMode.stream,
        replayGainPreamp = reactives.replayGainPreamp.stream,
        replayGainFallback = reactives.replayGainFallback.stream,
        replayGainClip = reactives.replayGainClip.stream,
        volumeGain = reactives.volumeGain.stream,
        cacheMode = reactives.cacheMode.stream,
        cacheSecs = reactives.cacheSecs.stream,
        cacheOnDisk = reactives.cacheOnDisk.stream,
        cachePause = reactives.cachePause.stream,
        cachePauseWait = reactives.cachePauseWait.stream,
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
        audioTrack = reactives.audioTrack.stream,
        audioSpdif = reactives.audioSpdif.stream,
        volumeMax = reactives.volumeMax.stream,
        audioSampleRate = reactives.audioSampleRate.stream,
        audioFormat = reactives.audioFormat.stream,
        audioChannels = reactives.audioChannels.stream,
        audioClientName = reactives.audioClientName.stream,
        audioDriver = reactives.audioDriver.stream,
        activeFilters = reactives.activeFilters.stream,
        audioDisplay = reactives.audioDisplay.stream,
        coverArtAuto = reactives.coverArtAuto.stream,
        imageDisplayDuration = reactives.imageDisplayDuration.stream,
        prefetchState = reactives.prefetchState.stream,
        buffering = buffering.stream,
        completed = completed.stream,
        playlist = playlist.stream,
        playlistMode = playlistMode.stream,
        audioDevices = audioDevices.stream,
        metadata = metadata.stream,
        bufferingPercentage = bufferingPercentage.stream,
        equalizerGains = equalizerGains.stream;

  /// Builds a synthetic [AudioParams] broadcast stream that emits a fresh
  /// aggregated snapshot whenever any of the 7 backing reactive properties
  /// changes (format, sampleRate, channels, channelCount, hrChannels, codec,
  /// codecName).
  ///
  /// Subscribers can still observe individual sub-properties through the
  /// per-field [ReactiveProperty]s, but most consumers use the aggregated
  /// snapshot.
  ///
  /// Implementation: a single broadcast controller is created once per
  /// [PlayerStream]; the 7 source subscriptions are opened lazily on the
  /// first listener (`onListen`) and torn down once the last listener
  /// cancels (`onCancel`). This is functionally equivalent to the previous
  /// `async* + yield* + finally` plumbing but doesn't depend on Dart's
  /// generator finally semantics for correctness.
  static Stream<AudioParams> _audioParamsStream(
    DefaultPropertyReactives r,
  ) {
    AudioParams snapshot() => AudioParams(
          format: r.audioParamsFormat.value.isEmpty
              ? null
              : r.audioParamsFormat.value,
          sampleRate: r.audioParamsSampleRate.value == 0
              ? null
              : r.audioParamsSampleRate.value,
          channels: r.audioParamsChannels.value.isEmpty
              ? null
              : r.audioParamsChannels.value,
          channelCount: r.audioParamsChannelCount.value == 0
              ? null
              : r.audioParamsChannelCount.value,
          hrChannels: r.audioParamsHrChannels.value.isEmpty
              ? null
              : r.audioParamsHrChannels.value,
          codec: r.audioCodec.value.isEmpty ? null : r.audioCodec.value,
          codecName:
              r.audioCodecName.value.isEmpty ? null : r.audioCodecName.value,
        );
    return _bindAggregate<AudioParams>(snapshot, [
      r.audioParamsFormat.stream,
      r.audioParamsSampleRate.stream,
      r.audioParamsChannels.stream,
      r.audioParamsChannelCount.stream,
      r.audioParamsHrChannels.stream,
      r.audioCodec.stream,
      r.audioCodecName.stream,
    ]);
  }

  static Stream<AudioParams> _audioOutParamsStream(
    DefaultPropertyReactives r,
  ) {
    AudioParams snapshot() => AudioParams(
          format: r.audioOutParamsFormat.value.isEmpty
              ? null
              : r.audioOutParamsFormat.value,
          sampleRate: r.audioOutParamsSampleRate.value == 0
              ? null
              : r.audioOutParamsSampleRate.value,
          channels: r.audioOutParamsChannels.value.isEmpty
              ? null
              : r.audioOutParamsChannels.value,
          channelCount: r.audioOutParamsChannelCount.value == 0
              ? null
              : r.audioOutParamsChannelCount.value,
          hrChannels: r.audioOutParamsHrChannels.value.isEmpty
              ? null
              : r.audioOutParamsHrChannels.value,
        );
    return _bindAggregate<AudioParams>(snapshot, [
      r.audioOutParamsFormat.stream,
      r.audioOutParamsSampleRate.stream,
      r.audioOutParamsChannels.stream,
      r.audioOutParamsChannelCount.stream,
      r.audioOutParamsHrChannels.stream,
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

  /// Emits the ReplayGain mode.
  final Stream<ReplayGainMode> replayGainMode;

  /// Emits the ReplayGain preamp value in dB.
  final Stream<double> replayGainPreamp;

  /// Emits the ReplayGain fallback value in dB.
  final Stream<double> replayGainFallback;

  /// Emits whether ReplayGain clipping is allowed.
  final Stream<bool> replayGainClip;

  /// Emits the software volume gain in dB.
  final Stream<double> volumeGain;

  /// Emits the cache mode.
  final Stream<CacheMode> cacheMode;

  /// Emits the target cache duration.
  final Stream<Duration> cacheSecs;

  /// Emits whether cache on disk is enabled.
  final Stream<bool> cacheOnDisk;

  /// Emits whether pause on buffer is enabled.
  final Stream<bool> cachePause;

  /// Emits the cache pause wait duration.
  final Stream<Duration> cachePauseWait;

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

  /// Whether playback is paused because the network cache ran empty.
  final Stream<bool> pausedForCache;

  /// Whether the current stream is being read via a network protocol.
  final Stream<bool> demuxerViaNetwork;

  /// Emits whether audio exclusive mode is enabled.
  final Stream<bool> audioExclusive;

  /// Emits the audio buffer duration.
  final Stream<Duration> audioBuffer;

  /// Emits whether stream silence is enabled.
  final Stream<bool> audioStreamSilence;

  /// Emits whether fallback to null output is enabled.
  final Stream<bool> audioNullUntimed;

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

  /// Emits the current cover-art display mode.
  final Stream<AudioDisplayMode> audioDisplay;

  /// Emits the current external cover-art auto-load mode.
  final Stream<CoverArtAutoMode> coverArtAuto;

  /// Emits the current `image-display-duration` value.
  final Stream<String> imageDisplayDuration;

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
  /// any [Player.log] injection. Always carries `prefix: 'mpv_audio_kit'`.
  ///
  /// Split from [log] in 0.1.0 so consumers can route engine and wrapper
  /// noise to different sinks (e.g. show only [log] in a debug overlay
  /// while routing [internalLog] to crash reporting).
  final Stream<MpvLogEntry> internalLog;

  /// Emits whenever mpv fires a registered hook (see `Player.registerHook`).
  final Stream<MpvHookEvent> hook;

  /// Lifecycle of mpv's background playlist-prefetch.
  ///
  /// Backed by the patched `prefetch-state` mpv property — works
  /// uniformly across HLS, DASH, raw HTTP, SMB, local files.
  final Stream<MpvPrefetchState> prefetchState;

  /// Raw cover-art frames as captured by mpv's `screenshot-raw video`
  /// command after each file load.
  ///
  /// Always emitted regardless of `PlayerConfiguration.processCoverArt`,
  /// so consumers can run their own image pipeline (resize / format /
  /// color-space) instead of the library's default 800px PNG path.
  /// Pixel format is BGRA8888 — see [CoverArtRaw] for the layout
  /// (and especially the [CoverArtRaw.stride] caveat).
  final Stream<CoverArtRaw> coverArtRaw;
}
