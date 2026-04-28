// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../internal/node_parsers.dart';
import '../models/audio_device.dart';
import '../models/audio_filter.dart';
import '../models/audio_params.dart';
import '../models/mpv_prefetch_state.dart';
// player_state.dart re-exports enums.dart, so we don't need a direct import.
import '../models/player_state.dart';
import '../utils/duration_seconds.dart';
import 'mpv_property_spec.dart';
import 'reactive_property.dart';

/// Bundles the [ReactiveProperty]s that back state fields the registry
/// "owns" — for the most part one per observed mpv property, but a few
/// (`playing`, `audioParamsNode`, …) are written into by more than one
/// helper.
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

  // Audio params (decoder side) — one node-map property + the two
  // sibling string properties (`audio-codec`, `audio-codec-name`) that mpv
  // does NOT bundle into the `audio-params` node.
  final ReactiveProperty<AudioParams> audioParamsNode =
      ReactiveProperty<AudioParams>(const AudioParams());
  final ReactiveProperty<String> audioCodec = ReactiveProperty<String>('');
  final ReactiveProperty<String> audioCodecName = ReactiveProperty<String>('');

  // Audio out params (hardware side) — single node-map; mpv exposes no
  // codec/codec-name siblings on the output side.
  final ReactiveProperty<AudioParams> audioOutParamsNode =
      ReactiveProperty<AudioParams>(const AudioParams());

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

  // Audio output lifecycle (read-only string).
  final ReactiveProperty<AudioOutputState> audioOutputState =
      ReactiveProperty<AudioOutputState>(AudioOutputState.closed);

  // Cover art.
  final ReactiveProperty<AudioDisplayMode> audioDisplayMode =
      ReactiveProperty<AudioDisplayMode>(AudioDisplayMode.embeddedFirst);
  final ReactiveProperty<CoverArtAutoMode> coverArtAutoMode =
      ReactiveProperty<CoverArtAutoMode>(CoverArtAutoMode.no);
  final ReactiveProperty<String> imageDisplayDuration =
      ReactiveProperty<String>('inf');

  // Stream-only — no PlayerState field; exposed through
  // `Player.stream.prefetchState`.
  final ReactiveProperty<MpvPrefetchState> prefetchState =
      ReactiveProperty<MpvPrefetchState>(MpvPrefetchState.idle);
}

/// Builds the default list of [MpvPropertySpec]s mapping mpv property names
/// to their [PlayerState] reducers.
///
/// The callbacks let the caller hook side effects to property changes
/// without leaking the player object into the spec list:
/// - [onIdleActive]: fires every time mpv toggles `idle-active`; used by the
///   player to clear its lifecycle (`playing=false, buffering=false`) when
///   mpv has nothing left to do.
/// - [onAudioOutputState]: fires on every transition of
///   `audio-output-state`; the player uses it to surface a typed
///   error when the AO fails to initialise.
List<MpvPropertySpec> buildDefaultSpecs(
  DefaultPropertyReactives r, {
  required void Function(bool idle) onIdleActive,
  required void Function(AudioOutputState state) onAudioOutputState,
}) {
  return <MpvPropertySpec>[
    // ── Playback / timing ────────────────────────────────────────────────
    MpvPropertySpec<Duration>.double(
      name: 'time-pos',
      reactive: r.position,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(position: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'duration',
      reactive: r.duration,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(duration: v),
    ),
    MpvPropertySpec<Duration>.double(
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
    // arrive on every meaningful transition. mpv docs:
    // https://mpv.io/manual/master/#command-interface-core-idle
    MpvPropertySpec<bool>.flag(
      name: 'core-idle',
      reactive: r.playing,
      parse: (raw) => !raw,
      reduce: (playing, s) => s.copyWith(playing: playing),
    ),
    MpvPropertySpec<double>.double(
      name: 'volume',
      reactive: r.volume,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volume: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'speed',
      reactive: r.rate,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(rate: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'pitch',
      reactive: r.pitch,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(pitch: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'mute',
      reactive: r.mute,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(mute: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'idle-active',
      // No state field for idle-active; the side-effect (`onIdleActive`) does
      // the lifecycle work. We still need a reactive for dedup so repeated
      // `true → true` events don't refire the lifecycle helper.
      reactive: ReactiveProperty<bool>(false),
      parse: _identityBool,
      reduce: (_, s) => s,
      onChange: onIdleActive,
    ),
    MpvPropertySpec<bool>.flag(
      name: 'shuffle',
      reactive: r.shuffle,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(shuffle: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'audio-pitch-correction',
      reactive: r.pitchCorrection,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(pitchCorrection: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'audio-delay',
      reactive: r.audioDelay,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(audioDelay: v),
    ),
    MpvPropertySpec<double?>.double(
      name: 'audio-bitrate',
      reactive: r.audioBitrate,
      parse: (raw) => raw > 0 ? raw : null,
      reduce: (v, s) => s.copyWith(audioBitrate: v),
    ),
    MpvPropertySpec<AudioDevice>.string(
      name: 'audio-device',
      reactive: r.audioDevice,
      parse: (raw) => AudioDevice(raw, raw),
      reduce: (v, s) => s.copyWith(audioDevice: v),
    ),

    // ── Audio params (decoder side) ──────────────────────────────────────
    //
    // mpv exposes `audio-params` as a single MPV_FORMAT_NODE_MAP with the 5
    // wire-side fields (`format`, `samplerate`, `channels`, `channel-count`,
    // `hr-channels`). We observe the node directly instead of subscribing
    // to 5 sub-property strings and aggregating. Codec / codec-name are
    // separate properties that the node map does not contain — they keep
    // their own specs below and merge into the same `state.audioParams`.
    MpvPropertySpec<AudioParams>.node(
      name: 'audio-params',
      reactive: r.audioParamsNode,
      parse: parseAudioParamsNode,
      reduce: (v, s) => s.copyWith(
        audioParams: s.audioParams.copyWith(
          format: v.format,
          sampleRate: v.sampleRate,
          channels: v.channels,
          channelCount: v.channelCount,
          hrChannels: v.hrChannels,
        ),
      ),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-codec',
      reactive: r.audioCodec,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(codec: v)),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-codec-name',
      reactive: r.audioCodecName,
      parse: _identityString,
      reduce: (v, s) =>
          s.copyWith(audioParams: s.audioParams.copyWith(codecName: v)),
    ),

    // ── Audio params (hardware side) ─────────────────────────────────────
    MpvPropertySpec<AudioParams>.node(
      name: 'audio-out-params',
      reactive: r.audioOutParamsNode,
      parse: parseAudioParamsNode,
      reduce: (v, s) => s.copyWith(audioOutParams: v),
    ),

    // ── ReplayGain & gapless ─────────────────────────────────────────────
    MpvPropertySpec<GaplessMode>.string(
      name: 'gapless-audio',
      reactive: r.gaplessMode,
      parse: GaplessMode.fromMpv,
      reduce: (v, s) => s.copyWith(gaplessMode: v),
    ),
    MpvPropertySpec<ReplayGainMode>.string(
      name: 'replaygain',
      reactive: r.replayGainMode,
      parse: ReplayGainMode.fromMpv,
      reduce: (v, s) => s.copyWith(replayGainMode: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'replaygain-preamp',
      reactive: r.replayGainPreamp,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(replayGainPreamp: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'replaygain-fallback',
      reactive: r.replayGainFallback,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(replayGainFallback: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'replaygain-clip',
      reactive: r.replayGainClip,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(replayGainClip: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'volume-gain',
      reactive: r.volumeGain,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volumeGain: v),
    ),

    // ── Cache / network ──────────────────────────────────────────────────
    MpvPropertySpec<CacheMode>.string(
      name: 'cache',
      reactive: r.cacheMode,
      parse: CacheMode.fromMpv,
      reduce: (v, s) => s.copyWith(cacheMode: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'cache-secs',
      reactive: r.cacheSecs,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(cacheSecs: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'cache-on-disk',
      reactive: r.cacheOnDisk,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(cacheOnDisk: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'cache-pause',
      reactive: r.cachePause,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(cachePause: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'cache-pause-wait',
      reactive: r.cachePauseWait,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(cachePauseWait: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'demuxer-max-bytes',
      reactive: r.demuxerMaxBytes,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerMaxBytes: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'demuxer-readahead-secs',
      reactive: r.demuxerReadaheadSecs,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerReadaheadSecs: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'demuxer-max-back-bytes',
      reactive: r.demuxerMaxBackBytes,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(demuxerMaxBackBytes: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'network-timeout',
      reactive: r.networkTimeout,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(networkTimeout: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'tls-verify',
      reactive: r.tlsVerify,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(tlsVerify: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'paused-for-cache',
      reactive: r.pausedForCache,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(pausedForCache: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'demuxer-via-network',
      reactive: r.demuxerViaNetwork,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(demuxerViaNetwork: v),
    ),

    // ── Audio output / driver ────────────────────────────────────────────
    MpvPropertySpec<Duration>.double(
      name: 'audio-buffer',
      reactive: r.audioBuffer,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(audioBuffer: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'audio-exclusive',
      reactive: r.audioExclusive,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioExclusive: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'audio-stream-silence',
      reactive: r.audioStreamSilence,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioStreamSilence: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'ao-null-untimed',
      reactive: r.audioNullUntimed,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(audioNullUntimed: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'aid',
      reactive: r.audioTrack,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioTrack: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-spdif',
      reactive: r.audioSpdif,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioSpdif: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'volume-max',
      reactive: r.volumeMax,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volumeMax: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'audio-samplerate',
      reactive: r.audioSampleRate,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(audioSampleRate: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-format',
      reactive: r.audioFormat,
      // mpv emits an empty string when the format has been reset; surface
      // that as 'no' to keep the public API consistent with the setter.
      parse: (raw) => raw.isEmpty ? 'no' : raw,
      reduce: (v, s) => s.copyWith(audioFormat: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-channels',
      reactive: r.audioChannels,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioChannels: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'audio-client-name',
      reactive: r.audioClientName,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioClientName: v),
    ),
    MpvPropertySpec<List<AudioFilter>>.string(
      name: 'af',
      reactive: r.activeFilters,
      parse: _parseAudioFilters,
      reduce: (v, s) => s.copyWith(activeFilters: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'ao',
      reactive: r.audioDriver,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(audioDriver: v),
    ),

    // ── Cover art ────────────────────────────────────────────────────────
    MpvPropertySpec<AudioDisplayMode>.string(
      name: 'audio-display',
      reactive: r.audioDisplayMode,
      parse: AudioDisplayMode.fromMpv,
      reduce: (v, s) => s.copyWith(audioDisplayMode: v),
    ),
    MpvPropertySpec<CoverArtAutoMode>.string(
      name: 'cover-art-auto',
      reactive: r.coverArtAutoMode,
      parse: CoverArtAutoMode.fromMpv,
      reduce: (v, s) => s.copyWith(coverArtAutoMode: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'image-display-duration',
      reactive: r.imageDisplayDuration,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(imageDisplayDuration: v),
    ),

    // `prefetch-state` is stream-only (no PlayerState field) — the
    // wrapper exposes it through `Player.stream.prefetchState`.
    MpvPropertySpec<MpvPrefetchState>.string(
      name: 'prefetch-state',
      reactive: r.prefetchState,
      parse: MpvPrefetchState.parse,
      reduce: (_, s) => s,
    ),
    MpvPropertySpec<AudioOutputState>.string(
      name: 'audio-output-state',
      reactive: r.audioOutputState,
      parse: AudioOutputState.fromMpv,
      reduce: (v, s) => s.copyWith(audioOutputState: v),
      onChange: onAudioOutputState,
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
