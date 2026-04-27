// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../models/audio_device.dart';
import '../models/audio_filter.dart';
import '../models/mpv_prefetch_state.dart';
// player_state.dart re-exports enums.dart, so we don't need a direct import.
import '../models/player_state.dart';
import '../utils/duration_seconds.dart';
import 'mpv_property_spec.dart';
import 'reactive_property.dart';

/// Bundles the [ReactiveProperty]s that back state fields the registry
/// "owns" — for the most part one per observed mpv property, but the
/// `pause` spec writes into [playing] (after inverting the flag) so the
/// player's lifecycle helpers can also push into the same reactive.
class DefaultPropertyReactives {
  DefaultPropertyReactives();

  // Lifecycle (shared with custom lifecycle helpers in Player).
  final ReactiveProperty<bool> playing = ReactiveProperty<bool>(false);

  // Playback / timing.
  final ReactiveProperty<Duration> position =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<Duration> duration =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<Duration> buffer =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<double> volume = ReactiveProperty<double>(100.0);
  final ReactiveProperty<double> rate = ReactiveProperty<double>(1.0);
  final ReactiveProperty<double> pitch = ReactiveProperty<double>(1.0);
  final ReactiveProperty<bool> mute = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> shuffle = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> pitchCorrection = ReactiveProperty<bool>(true);
  final ReactiveProperty<Duration> audioDelay =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<double?> audioBitrate =
      ReactiveProperty<double?>(null);
  final ReactiveProperty<AudioDevice> audioDevice =
      ReactiveProperty<AudioDevice>(const AudioDevice('auto', 'Auto'));

  // Audio params (decoder side).
  final ReactiveProperty<String> audioParamsFormat =
      ReactiveProperty<String>('');
  final ReactiveProperty<int> audioParamsSampleRate = ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioParamsChannels =
      ReactiveProperty<String>('');
  final ReactiveProperty<int> audioParamsChannelCount =
      ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioParamsHrChannels =
      ReactiveProperty<String>('');
  final ReactiveProperty<String> audioCodec = ReactiveProperty<String>('');
  final ReactiveProperty<String> audioCodecName = ReactiveProperty<String>('');

  // Audio out params (hardware side).
  final ReactiveProperty<String> audioOutParamsFormat =
      ReactiveProperty<String>('');
  final ReactiveProperty<int> audioOutParamsSampleRate =
      ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioOutParamsChannels =
      ReactiveProperty<String>('');
  final ReactiveProperty<int> audioOutParamsChannelCount =
      ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioOutParamsHrChannels =
      ReactiveProperty<String>('');

  // ReplayGain.
  final ReactiveProperty<ReplayGainMode> replayGainMode =
      ReactiveProperty<ReplayGainMode>(ReplayGainMode.no);
  final ReactiveProperty<double> replayGainPreamp =
      ReactiveProperty<double>(0.0);
  final ReactiveProperty<double> replayGainFallback =
      ReactiveProperty<double>(0.0);
  final ReactiveProperty<bool> replayGainClip = ReactiveProperty<bool>(false);
  final ReactiveProperty<double> volumeGain = ReactiveProperty<double>(0.0);
  final ReactiveProperty<GaplessMode> gaplessMode =
      ReactiveProperty<GaplessMode>(GaplessMode.weak);

  // Cache / network.
  final ReactiveProperty<CacheMode> cacheMode =
      ReactiveProperty<CacheMode>(CacheMode.auto);
  final ReactiveProperty<Duration> cacheSecs =
      ReactiveProperty<Duration>(const Duration(seconds: 1));
  final ReactiveProperty<bool> cacheOnDisk = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> cachePause = ReactiveProperty<bool>(true);
  final ReactiveProperty<Duration> cachePauseWait =
      ReactiveProperty<Duration>(const Duration(seconds: 1));
  final ReactiveProperty<int> demuxerMaxBytes =
      ReactiveProperty<int>(150 * 1024 * 1024);
  final ReactiveProperty<int> demuxerReadaheadSecs = ReactiveProperty<int>(1);
  final ReactiveProperty<int> demuxerMaxBackBytes =
      ReactiveProperty<int>(50 * 1024 * 1024);
  final ReactiveProperty<Duration> networkTimeout =
      ReactiveProperty<Duration>(const Duration(seconds: 30));
  final ReactiveProperty<bool> tlsVerify = ReactiveProperty<bool>(true);
  final ReactiveProperty<bool> pausedForCache = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> demuxerViaNetwork =
      ReactiveProperty<bool>(false);

  // Audio output / driver.
  final ReactiveProperty<bool> audioExclusive = ReactiveProperty<bool>(false);
  final ReactiveProperty<Duration> audioBuffer =
      ReactiveProperty<Duration>(const Duration(milliseconds: 200));
  final ReactiveProperty<bool> audioStreamSilence =
      ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> audioNullUntimed = ReactiveProperty<bool>(false);
  final ReactiveProperty<String> audioTrack = ReactiveProperty<String>('auto');
  final ReactiveProperty<String> audioSpdif = ReactiveProperty<String>('');
  final ReactiveProperty<double> volumeMax = ReactiveProperty<double>(130.0);
  final ReactiveProperty<int> audioSampleRate = ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioFormat = ReactiveProperty<String>('auto');
  final ReactiveProperty<String> audioChannels =
      ReactiveProperty<String>('auto');
  final ReactiveProperty<String> audioClientName =
      ReactiveProperty<String>('mpv_audio_kit');
  final ReactiveProperty<String> audioDriver = ReactiveProperty<String>('auto');
  final ReactiveProperty<List<AudioFilter>> activeFilters =
      ReactiveProperty<List<AudioFilter>>(const []);

  // Cover art.
  final ReactiveProperty<AudioDisplayMode> audioDisplay =
      ReactiveProperty<AudioDisplayMode>(AudioDisplayMode.embeddedFirst);
  final ReactiveProperty<CoverArtAutoMode> coverArtAuto =
      ReactiveProperty<CoverArtAutoMode>(CoverArtAutoMode.no);
  final ReactiveProperty<String> imageDisplayDuration =
      ReactiveProperty<String>('inf');

  // Patched property — emitted only as a stream (no [PlayerState] field).
  final ReactiveProperty<MpvPrefetchState> prefetchState =
      ReactiveProperty<MpvPrefetchState>(MpvPrefetchState.idle);
}

/// Builds the default list of [MpvPropertySpec]s mapping mpv property names
/// to their [PlayerState] reducers.
///
/// The two callbacks let the caller hook side effects to property changes
/// without leaking the player object into the spec list:
/// - [onPlayingChanged]: fires every time `pause`'s inverse changes; the
///   player uses it to schedule the audio-output sanity check when playback
///   resumes.
/// - [onIdleActive]: fires every time mpv toggles `idle-active`; used by the
///   player to clear its lifecycle (`playing=false, buffering=false`) when
///   mpv has nothing left to do.
List<MpvPropertySpec> buildDefaultSpecs(
  DefaultPropertyReactives r, {
  required void Function(bool playing) onPlayingChanged,
  required void Function(bool idle) onIdleActive,
}) {
  return <MpvPropertySpec>[
    // ── Playback / timing ────────────────────────────────────────────────
    MpvDoubleSpec<Duration>(
      name: 'time-pos',
      reactive: r.position,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(position: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'duration',
      reactive: r.duration,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(duration: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'demuxer-cache-time',
      reactive: r.buffer,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(buffer: v),
    ),
    // We bind `state.playing` to mpv's `core-idle` property, NOT `pause`.
    //
    // `pause` is just "audio output suspended" — it is `no` by default
    // even when mpv has no file loaded. Subscribing to `pause` therefore
    // gave us false positives at boot (`pause=no` while idle) and false
    // negatives mid-session (calling `set pause no` when pause was
    // already `no` doesn't trigger PROPERTY_CHANGE, so the observer
    // never sees the load → playing transition for the *first* file).
    //
    // `core-idle` is the property that genuinely tracks "is mpv producing
    // audio right now": it flips to `false` when a file actually starts
    // playing, back to `true` when paused / seeking / buffering / EOF.
    // The mapping is identical (`playing = !core-idle`) but the events
    // arrive on every meaningful transition.
    MpvFlagSpec<bool>(
      name: 'core-idle',
      reactive: r.playing,
      parse: (raw) => !raw,
      reduce: (playing, s) => s.copyWith(playing: playing),
      onChange: onPlayingChanged,
    ),
    MpvDoubleSpec<double>(
      name: 'volume',
      reactive: r.volume,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volume: v),
    ),
    MpvDoubleSpec<double>(
      name: 'speed',
      reactive: r.rate,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(rate: v),
    ),
    MpvDoubleSpec<double>(
      name: 'pitch',
      reactive: r.pitch,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(pitch: v),
    ),
    MpvFlagSpec<bool>(
      name: 'mute',
      reactive: r.mute,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(mute: v),
    ),
    MpvFlagSpec<bool>(
      name: 'idle-active',
      // No state field for idle-active; the side-effect (`onIdleActive`) does
      // the lifecycle work. We still need a reactive for dedup so repeated
      // `true → true` events don't refire the lifecycle helper.
      reactive: ReactiveProperty<bool>(false),
      parse: _identityBool,
      reduce: (_, s) => s,
      onChange: onIdleActive,
    ),
    MpvFlagSpec<bool>(
      name: 'shuffle',
      reactive: r.shuffle,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(shuffle: v),
    ),
    MpvFlagSpec<bool>(
      name: 'audio-pitch-correction',
      reactive: r.pitchCorrection,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(pitchCorrection: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'audio-delay',
      reactive: r.audioDelay,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(audioDelay: v),
    ),
    MpvDoubleSpec<double?>(
      name: 'audio-bitrate',
      reactive: r.audioBitrate,
      parse: (raw) => raw > 0 ? raw : null,
      reduce: (v, s) => s.copyWith(audioBitrate: v),
    ),
    MpvStringSpec<AudioDevice>(
      name: 'audio-device',
      reactive: r.audioDevice,
      parse: (raw) => AudioDevice(raw, raw),
      reduce: (v, s) => s.copyWith(audioDevice: v),
    ),

    // ── Audio params (decoder side) ──────────────────────────────────────
    MpvStringSpec<String>(
      name: 'audio-params/format',
      reactive: r.audioParamsFormat,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(format: v)),
    ),
    MpvDoubleSpec<int>(
      name: 'audio-params/samplerate',
      reactive: r.audioParamsSampleRate,
      parse: (raw) => raw.toInt(),
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(sampleRate: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-params/channels',
      reactive: r.audioParamsChannels,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(channels: v)),
    ),
    MpvDoubleSpec<int>(
      name: 'audio-params/channel-count',
      reactive: r.audioParamsChannelCount,
      parse: (raw) => raw.toInt(),
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(channelCount: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-params/hr-channels',
      reactive: r.audioParamsHrChannels,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(hrChannels: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-codec',
      reactive: r.audioCodec,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(codec: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-codec-name',
      reactive: r.audioCodecName,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(codecName: v)),
    ),

    // ── Audio params (hardware side) ─────────────────────────────────────
    MpvStringSpec<String>(
      name: 'audio-out-params/format',
      reactive: r.audioOutParamsFormat,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioOutParams: s.audioOutParams.copyWith(format: v)),
    ),
    MpvDoubleSpec<int>(
      name: 'audio-out-params/samplerate',
      reactive: r.audioOutParamsSampleRate,
      parse: (raw) => raw.toInt(),
      reduce: (v, s) =>
          s.copyWith(audioOutParams: s.audioOutParams.copyWith(sampleRate: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-out-params/channels',
      reactive: r.audioOutParamsChannels,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioOutParams: s.audioOutParams.copyWith(channels: v)),
    ),
    MpvDoubleSpec<int>(
      name: 'audio-out-params/channel-count',
      reactive: r.audioOutParamsChannelCount,
      parse: (raw) => raw.toInt(),
      reduce: (v, s) => s.copyWith(
          audioOutParams: s.audioOutParams.copyWith(channelCount: v)),
    ),
    MpvStringSpec<String>(
      name: 'audio-out-params/hr-channels',
      reactive: r.audioOutParamsHrChannels,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioOutParams: s.audioOutParams.copyWith(hrChannels: v)),
    ),

    // ── ReplayGain & gapless ─────────────────────────────────────────────
    MpvStringSpec<GaplessMode>(
      name: 'gapless-audio',
      reactive: r.gaplessMode,
      parse: GaplessMode.fromMpv,
      reduce: (v, s) => s.copyWith(gaplessMode: v),
    ),
    MpvStringSpec<ReplayGainMode>(
      name: 'replaygain',
      reactive: r.replayGainMode,
      parse: ReplayGainMode.fromMpv,
      reduce: (v, s) => s.copyWith(replayGainMode: v),
    ),
    MpvDoubleSpec<double>(
      name: 'replaygain-preamp',
      reactive: r.replayGainPreamp,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(replayGainPreamp: v),
    ),
    MpvDoubleSpec<double>(
      name: 'replaygain-fallback',
      reactive: r.replayGainFallback,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(replayGainFallback: v),
    ),
    MpvFlagSpec<bool>(
      name: 'replaygain-clip',
      reactive: r.replayGainClip,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(replayGainClip: v),
    ),
    MpvDoubleSpec<double>(
      name: 'volume-gain',
      reactive: r.volumeGain,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volumeGain: v),
    ),

    // ── Cache / network ──────────────────────────────────────────────────
    MpvStringSpec<CacheMode>(
      name: 'cache',
      reactive: r.cacheMode,
      parse: CacheMode.fromMpv,
      reduce: (v, s) => s.copyWith(cacheMode: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'cache-secs',
      reactive: r.cacheSecs,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(cacheSecs: v),
    ),
    MpvFlagSpec<bool>(
      name: 'cache-on-disk',
      reactive: r.cacheOnDisk,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(cacheOnDisk: v),
    ),
    MpvFlagSpec<bool>(
      name: 'cache-pause',
      reactive: r.cachePause,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(cachePause: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'cache-pause-wait',
      reactive: r.cachePauseWait,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(cachePauseWait: v),
    ),
    MpvIntSpec<int>(
      name: 'demuxer-max-bytes',
      reactive: r.demuxerMaxBytes,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerMaxBytes: v),
    ),
    MpvIntSpec<int>(
      name: 'demuxer-readahead-secs',
      reactive: r.demuxerReadaheadSecs,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerReadaheadSecs: v),
    ),
    MpvIntSpec<int>(
      name: 'demuxer-max-back-bytes',
      reactive: r.demuxerMaxBackBytes,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerMaxBackBytes: v),
    ),
    MpvDoubleSpec<Duration>(
      name: 'network-timeout',
      reactive: r.networkTimeout,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(networkTimeout: v),
    ),
    MpvFlagSpec<bool>(
      name: 'tls-verify',
      reactive: r.tlsVerify,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(tlsVerify: v),
    ),
    MpvFlagSpec<bool>(
      name: 'paused-for-cache',
      reactive: r.pausedForCache,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(pausedForCache: v),
    ),
    MpvFlagSpec<bool>(
      name: 'demuxer-via-network',
      reactive: r.demuxerViaNetwork,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(demuxerViaNetwork: v),
    ),

    // ── Audio output / driver ────────────────────────────────────────────
    MpvDoubleSpec<Duration>(
      name: 'audio-buffer',
      reactive: r.audioBuffer,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(audioBuffer: v),
    ),
    MpvFlagSpec<bool>(
      name: 'audio-exclusive',
      reactive: r.audioExclusive,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioExclusive: v),
    ),
    MpvFlagSpec<bool>(
      name: 'audio-stream-silence',
      reactive: r.audioStreamSilence,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioStreamSilence: v),
    ),
    MpvFlagSpec<bool>(
      name: 'ao-null-untimed',
      reactive: r.audioNullUntimed,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioNullUntimed: v),
    ),
    MpvStringSpec<String>(
      name: 'aid',
      reactive: r.audioTrack,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioTrack: v),
    ),
    MpvStringSpec<String>(
      name: 'audio-spdif',
      reactive: r.audioSpdif,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioSpdif: v),
    ),
    MpvDoubleSpec<double>(
      name: 'volume-max',
      reactive: r.volumeMax,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volumeMax: v),
    ),
    MpvIntSpec<int>(
      name: 'audio-samplerate',
      reactive: r.audioSampleRate,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(audioSampleRate: v),
    ),
    MpvStringSpec<String>(
      name: 'audio-format',
      reactive: r.audioFormat,
      // mpv emits an empty string when the format has been reset; surface
      // that as 'no' to keep the public API consistent with the setter.
      parse: (raw) => raw.isEmpty ? 'no' : raw,
      reduce: (v, s) => s.copyWith(audioFormat: v),
    ),
    MpvStringSpec<String>(
      name: 'audio-channels',
      reactive: r.audioChannels,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioChannels: v),
    ),
    MpvStringSpec<String>(
      name: 'audio-client-name',
      reactive: r.audioClientName,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioClientName: v),
    ),
    MpvStringSpec<List<AudioFilter>>(
      name: 'af',
      reactive: r.activeFilters,
      parse: _parseAudioFilters,
      reduce: (v, s) => s.copyWith(activeFilters: v),
    ),
    MpvStringSpec<String>(
      name: 'ao',
      reactive: r.audioDriver,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioDriver: v),
    ),

    // ── Cover art ────────────────────────────────────────────────────────
    MpvStringSpec<AudioDisplayMode>(
      name: 'audio-display',
      reactive: r.audioDisplay,
      parse: AudioDisplayMode.fromMpv,
      reduce: (v, s) => s.copyWith(audioDisplay: v),
    ),
    MpvStringSpec<CoverArtAutoMode>(
      name: 'cover-art-auto',
      reactive: r.coverArtAuto,
      parse: CoverArtAutoMode.fromMpv,
      reduce: (v, s) => s.copyWith(coverArtAuto: v),
    ),
    MpvStringSpec<String>(
      name: 'image-display-duration',
      reactive: r.imageDisplayDuration,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(imageDisplayDuration: v),
    ),

    // ── Patched: stream-only (not in PlayerState) ────────────────────────
    MpvStringSpec<MpvPrefetchState>(
      name: 'prefetch-state',
      reactive: r.prefetchState,
      parse: MpvPrefetchState.parse,
      reduce: (_, s) => s,
    ),
  ];
}

// ── Tiny inline parsers used by buildDefaultSpecs ──────────────────────────

double _identityDouble(double raw) => raw;
int _identityInt(int raw) => raw;
bool _identityBool(bool raw) => raw;
String _identityString(String raw) => raw;
Duration _toDuration(double raw) => secondsToDuration(raw);
List<AudioFilter> _parseAudioFilters(String raw) => raw
    .split(',')
    .where((e) => e.isNotEmpty)
    .map((e) => AudioFilter.custom(e))
    .toList();
