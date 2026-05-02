// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import '../dsp/audio_filter_chain.dart';
import '../reactive/node_parsers.dart';
import '../audio/audio_device.dart';
import '../cover/audio_display_mode.dart';
import '../audio/audio_output_state.dart';
import '../audio/audio_params.dart';
import '../cover/cover_art_auto_mode.dart';
import '../audio/gapless_mode.dart';
import '../network/cache_config.dart';
import '../playback/chapter.dart';
import '../dsp/compressor_config.dart';
import '../dsp/equalizer_config.dart';
import '../dsp/loudness_config.dart';
import '../events/mpv_prefetch_state.dart';
import '../playback/mpv_track.dart';
import '../dsp/pitch_tempo_config.dart';
import '../player_state.dart';
import '../audio/replay_gain_config.dart';
import '../utils/duration_seconds.dart';
import 'mpv_property_spec.dart';
import 'reactive_property.dart';

/// Bundles the [ReactiveProperty]s that back state fields the registry
/// "owns" — for the most part one per observed mpv property, but a few
/// (`playing`, `audioParams`, `cache`, `replayGain`) are aggregate cells
/// that several specs share so dedup happens on the full struct.
class DefaultPropertyReactives {
  DefaultPropertyReactives();

  // Lifecycle.
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

  // Audio params (decoder side) — aggregate of `audio-params` (NODE) +
  // `audio-codec` + `audio-codec-name`. The 3 specs all dedup and emit
  // on this single cell so listeners see one [AudioParams] snapshot per
  // change.
  final ReactiveProperty<AudioParams> audioParams =
      ReactiveProperty<AudioParams>(const AudioParams());

  // Audio out params (hardware side) — single node-map; mpv exposes no
  // codec/codec-name siblings on the output side.
  final ReactiveProperty<AudioParams> audioOutParamsNode =
      ReactiveProperty<AudioParams>(const AudioParams());

  // ReplayGain — aggregate of the 4 mpv properties (replaygain,
  // replaygain-preamp, replaygain-fallback, replaygain-clip). All 4 specs
  // dedup and emit on this single cell.
  final ReactiveProperty<ReplayGainConfig> replayGain =
      ReactiveProperty<ReplayGainConfig>(const ReplayGainConfig());
  final ReactiveProperty<double> volumeGain = ReactiveProperty<double>(0.0);
  final ReactiveProperty<GaplessMode> gapless =
      ReactiveProperty<GaplessMode>(GaplessMode.weak);

  // Cache — aggregate of the 5 mpv cache properties (cache, cache-secs,
  // cache-on-disk, cache-pause, cache-pause-wait). All 5 specs dedup and
  // emit on this single cell.
  final ReactiveProperty<CacheConfig> cache =
      ReactiveProperty<CacheConfig>(const CacheConfig());
  final ReactiveProperty<int> demuxerMaxBytes =
      ReactiveProperty<int>(150 * 1024 * 1024);
  final ReactiveProperty<int> demuxerReadaheadSecs = ReactiveProperty<int>(1);
  final ReactiveProperty<int> demuxerMaxBackBytes =
      ReactiveProperty<int>(50 * 1024 * 1024);
  final ReactiveProperty<Duration> networkTimeout =
      ReactiveProperty<Duration>(const Duration(seconds: 60));
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
  final ReactiveProperty<List<MpvTrack>> tracks =
      ReactiveProperty<List<MpvTrack>>(const []);
  final ReactiveProperty<MpvTrack?> currentAudioTrack =
      ReactiveProperty<MpvTrack?>(null);
  final ReactiveProperty<String> audioSpdif = ReactiveProperty<String>('');
  final ReactiveProperty<double> volumeMax = ReactiveProperty<double>(130.0);
  final ReactiveProperty<int> audioSampleRate = ReactiveProperty<int>(0);
  final ReactiveProperty<String> audioFormat = ReactiveProperty<String>('auto');
  final ReactiveProperty<String> audioChannels =
      ReactiveProperty<String>('auto');
  final ReactiveProperty<String> audioClientName =
      ReactiveProperty<String>('mpv_audio_kit');
  final ReactiveProperty<String> audioDriver = ReactiveProperty<String>('auto');
  // DSP filter chain stages — each owns a reserved label and is upserted
  // atomically by the matching typed setter. Custom filters carry no
  // managed label and live at the head of the chain.
  final ReactiveProperty<EqualizerConfig> equalizer =
      ReactiveProperty<EqualizerConfig>(const EqualizerConfig());
  final ReactiveProperty<CompressorConfig> compressor =
      ReactiveProperty<CompressorConfig>(const CompressorConfig());
  final ReactiveProperty<LoudnessConfig> loudness =
      ReactiveProperty<LoudnessConfig>(const LoudnessConfig());
  final ReactiveProperty<PitchTempoConfig> pitchTempo =
      ReactiveProperty<PitchTempoConfig>(const PitchTempoConfig());
  final ReactiveProperty<List<String>> customAudioFilters =
      ReactiveProperty<List<String>>(const []);

  // Audio output lifecycle (read-only string).
  final ReactiveProperty<AudioOutputState> audioOutputState =
      ReactiveProperty<AudioOutputState>(AudioOutputState.closed);

  // Cover art.
  final ReactiveProperty<AudioDisplayMode> audioDisplay =
      ReactiveProperty<AudioDisplayMode>(AudioDisplayMode.embeddedFirst);
  final ReactiveProperty<CoverArtAutoMode> coverArtAuto =
      ReactiveProperty<CoverArtAutoMode>(CoverArtAutoMode.no);
  // `null` = mpv's `inf` (frame held indefinitely); finite Duration is
  // the explicit hold time.
  final ReactiveProperty<Duration?> imageDisplayDuration =
      ReactiveProperty<Duration?>(null);

  // Stream-only: `prefetch-state` is an event-shaped signal, not a
  // snapshot value. The reactive cell exists for dedup + dispose
  // bookkeeping, but the value is exposed exclusively through
  // [PlayerStream.prefetchState] — never read `.value` from outside.
  final ReactiveProperty<MpvPrefetchState> prefetchState =
      ReactiveProperty<MpvPrefetchState>(MpvPrefetchState.idle);

  // Background prefetch toggle. Default mirrors mpv's own default.
  final ReactiveProperty<bool> prefetchPlaylist = ReactiveProperty<bool>(false);

  // Playback timing extras.
  final ReactiveProperty<Duration> audioPts =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<Duration> timeRemaining =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<Duration> playtimeRemaining =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<bool> eofReached = ReactiveProperty<bool>(false);

  // Stream capability.
  final ReactiveProperty<bool> seekable = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> partiallySeekable =
      ReactiveProperty<bool>(false);

  // Display / file metadata.
  final ReactiveProperty<String> mediaTitle = ReactiveProperty<String>('');
  final ReactiveProperty<String> fileFormat = ReactiveProperty<String>('');
  final ReactiveProperty<int> fileSize = ReactiveProperty<int>(0);

  // Buffering depth (lookahead beyond the current playhead).
  final ReactiveProperty<Duration> bufferDuration =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<bool> demuxerIdle = ReactiveProperty<bool>(true);

  // Chapter navigation.
  final ReactiveProperty<int?> currentChapter = ReactiveProperty<int?>(null);
  final ReactiveProperty<List<Chapter>> chapters =
      ReactiveProperty<List<Chapter>>(const []);

  // Path / URI introspection (read-only).
  final ReactiveProperty<String> path = ReactiveProperty<String>('');
  final ReactiveProperty<String> filename = ReactiveProperty<String>('');
  final ReactiveProperty<String> streamPath = ReactiveProperty<String>('');
  final ReactiveProperty<String> streamOpenFilename =
      ReactiveProperty<String>('');

  // A-B loop. Setters write `no` for null; observers parse it back.
  final ReactiveProperty<Duration?> abLoopA =
      ReactiveProperty<Duration?>(null);
  final ReactiveProperty<Duration?> abLoopB =
      ReactiveProperty<Duration?>(null);
  final ReactiveProperty<int?> abLoopCount = ReactiveProperty<int?>(null);
  final ReactiveProperty<int?> remainingAbLoops = ReactiveProperty<int?>(null);

  // Tier 2 introspection.
  final ReactiveProperty<bool> seeking = ReactiveProperty<bool>(false);
  final ReactiveProperty<double> percentPos = ReactiveProperty<double>(0.0);
  final ReactiveProperty<double> cacheSpeed = ReactiveProperty<double>(0.0);
  final ReactiveProperty<int> cacheBufferingState = ReactiveProperty<int>(0);
  final ReactiveProperty<String> currentDemuxer =
      ReactiveProperty<String>('');
  final ReactiveProperty<String> currentAo = ReactiveProperty<String>('');
  final ReactiveProperty<Duration> demuxerStartTime =
      ReactiveProperty<Duration>(Duration.zero);
  final ReactiveProperty<Map<String, String>> chapterMetadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<String> mpvVersion = ReactiveProperty<String>('');
  final ReactiveProperty<String> ffmpegVersion = ReactiveProperty<String>('');
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
    // `state.playing = !core-idle`. mpv's `pause` defaults to `no`
    // while idle and doesn't fire PROPERTY_CHANGE on the load → playing
    // transition for the first file; `core-idle` flips reliably on
    // every start/stop/pause/seek/buffer/EOF.
    MpvPropertySpec<bool>.flag(
      name: 'core-idle',
      reactive: r.playing,
      parse: (raw, _) => !raw,
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
      parse: (raw, _) => raw > 0 ? raw : null,
      reduce: (v, s) => s.copyWith(audioBitrate: v),
    ),
    // `audio-device` lives outside the registry: the description must
    // cross-reference `state.audioDevices` (parsed from
    // `audio-device-list`), and specs don't have access to that
    // sibling state — the player's custom dispatcher does.

    // ── Audio params (decoder side) ──────────────────────────────────────
    // Aggregate cell shared by three specs. The `audio-params` node
    // carries five of the eight fields; codec and codecName arrive as
    // separate string properties below. Each spec folds its slice via
    // copyWith so the reactive dedups on the full struct.
    MpvPropertySpec<AudioParams>.node(
      name: 'audio-params',
      reactive: r.audioParams,
      parse: (raw, s) {
        final node = parseAudioParamsNode(raw);
        return s.audioParams.copyWith(
          format: node.format,
          sampleRate: node.sampleRate,
          channels: node.channels,
          channelCount: node.channelCount,
          hrChannels: node.hrChannels,
        );
      },
      reduce: (v, s) => s.copyWith(audioParams: v),
    ),
    // `codec` and `codecName` mirror mpv's two codec properties one-to-one;
    // their content varies across mpv builds (`mp3` vs `mp3float`, `aac`
    // vs `aac_lc`, and the short-vs-descriptive split is not stable
    // either). Treat both fields as opaque hints — see the field-level
    // dartdoc on [AudioParams] for the matching contract.
    MpvPropertySpec<AudioParams>.string(
      name: 'audio-codec',
      reactive: r.audioParams,
      parse: (raw, s) =>
          s.audioParams.copyWith(codec: raw.isEmpty ? null : raw),
      reduce: (v, s) => s.copyWith(audioParams: v),
    ),
    MpvPropertySpec<AudioParams>.string(
      name: 'audio-codec-name',
      reactive: r.audioParams,
      parse: (raw, s) =>
          s.audioParams.copyWith(codecName: raw.isEmpty ? null : raw),
      reduce: (v, s) => s.copyWith(audioParams: v),
    ),

    // ── Audio params (hardware side) ─────────────────────────────────────
    MpvPropertySpec<AudioParams>.node(
      name: 'audio-out-params',
      reactive: r.audioOutParamsNode,
      parse: (raw, _) => parseAudioParamsNode(raw),
      reduce: (v, s) => s.copyWith(audioOutParams: v),
    ),

    // ── ReplayGain & gapless ─────────────────────────────────────────────
    MpvPropertySpec<GaplessMode>.string(
      name: 'gapless-audio',
      reactive: r.gapless,
      parse: (raw, _) => GaplessMode.fromMpv(raw),
      reduce: (v, s) => s.copyWith(gapless: v),
    ),
    // ── ReplayGain ───────────────────────────────────────────────────────
    // Aggregate cell — same pattern as audio-params above: four specs
    // share one reactive that dedups on the full [ReplayGainConfig].
    MpvPropertySpec<ReplayGainConfig>.string(
      name: 'replaygain',
      reactive: r.replayGain,
      parse: (raw, s) =>
          s.replayGain.copyWith(mode: ReplayGainMode.fromMpv(raw)),
      reduce: (v, s) => s.copyWith(replayGain: v),
    ),
    MpvPropertySpec<ReplayGainConfig>.double(
      name: 'replaygain-preamp',
      reactive: r.replayGain,
      parse: (raw, s) => s.replayGain.copyWith(preamp: raw),
      reduce: (v, s) => s.copyWith(replayGain: v),
    ),
    MpvPropertySpec<ReplayGainConfig>.double(
      name: 'replaygain-fallback',
      reactive: r.replayGain,
      parse: (raw, s) => s.replayGain.copyWith(fallback: raw),
      reduce: (v, s) => s.copyWith(replayGain: v),
    ),
    MpvPropertySpec<ReplayGainConfig>.flag(
      name: 'replaygain-clip',
      reactive: r.replayGain,
      parse: (raw, s) => s.replayGain.copyWith(clip: raw),
      reduce: (v, s) => s.copyWith(replayGain: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'volume-gain',
      reactive: r.volumeGain,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(volumeGain: v),
    ),

    // ── Cache ────────────────────────────────────────────────────────────
    // Aggregate cell — five specs share one reactive that dedups on the
    // full [CacheConfig].
    MpvPropertySpec<CacheConfig>.string(
      name: 'cache',
      reactive: r.cache,
      parse: (raw, s) => s.cache.copyWith(mode: CacheMode.fromMpv(raw)),
      reduce: (v, s) => s.copyWith(cache: v),
    ),
    MpvPropertySpec<CacheConfig>.double(
      name: 'cache-secs',
      reactive: r.cache,
      parse: (raw, s) => s.cache.copyWith(secs: secondsToDuration(raw)),
      reduce: (v, s) => s.copyWith(cache: v),
    ),
    MpvPropertySpec<CacheConfig>.flag(
      name: 'cache-on-disk',
      reactive: r.cache,
      parse: (raw, s) => s.cache.copyWith(onDisk: raw),
      reduce: (v, s) => s.copyWith(cache: v),
    ),
    MpvPropertySpec<CacheConfig>.flag(
      name: 'cache-pause',
      reactive: r.cache,
      parse: (raw, s) => s.cache.copyWith(pause: raw),
      reduce: (v, s) => s.copyWith(cache: v),
    ),
    MpvPropertySpec<CacheConfig>.double(
      name: 'cache-pause-wait',
      reactive: r.cache,
      parse: (raw, s) => s.cache.copyWith(pauseWait: secondsToDuration(raw)),
      reduce: (v, s) => s.copyWith(cache: v),
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
    // Track inventory + currently-active audio track. mpv exposes these
    // as structured node trees; the typed [MpvTrack] model lets the
    // consumer build a "switch audio track" UI without touching `aid`
    // strings.
    MpvPropertySpec<List<MpvTrack>>.node(
      name: 'track-list',
      reactive: r.tracks,
      parse: (raw, _) => parseTrackListNode(raw),
      reduce: (v, s) => s.copyWith(tracks: v),
    ),
    MpvPropertySpec<MpvTrack?>.node(
      name: 'current-tracks/audio',
      reactive: r.currentAudioTrack,
      parse: (raw, _) => parseCurrentAudioTrackNode(raw),
      reduce: (v, s) => s.copyWith(currentAudioTrack: v),
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
      parse: (raw, _) => raw.isEmpty ? 'no' : raw,
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
    // The `af` observer surfaces *external* mutations to the filter
    // chain (e.g. via `setRawProperty('af', ...)`) by recomputing the
    // unmanaged segment as `customAudioFilters`. Wrapper-managed stages
    // (equalizer/compressor/loudness/pitchTempo) are owned by their typed
    // setters, not parsed back from the af string — bypassing the typed
    // setters with a raw write leaves their state stale by design.
    MpvPropertySpec<List<String>>.string(
      name: 'af',
      reactive: r.customAudioFilters,
      parse: (raw, _) => extractCustomFilters(raw),
      reduce: (v, s) => s.copyWith(customAudioFilters: v),
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
      reactive: r.audioDisplay,
      parse: (raw, _) => AudioDisplayMode.fromMpv(raw),
      reduce: (v, s) => s.copyWith(audioDisplay: v),
    ),
    MpvPropertySpec<CoverArtAutoMode>.string(
      name: 'cover-art-auto',
      reactive: r.coverArtAuto,
      parse: (raw, _) => CoverArtAutoMode.fromMpv(raw),
      reduce: (v, s) => s.copyWith(coverArtAuto: v),
    ),
    MpvPropertySpec<Duration?>.string(
      name: 'image-display-duration',
      reactive: r.imageDisplayDuration,
      parse: (raw, _) => _parseImageDisplayDuration(raw),
      reduce: (v, s) => s.copyWith(imageDisplayDuration: v),
    ),

    // `prefetch-state` is stream-only (no PlayerState field) — the
    // wrapper exposes it through `Player.stream.prefetchState`.
    MpvPropertySpec<MpvPrefetchState>.string(
      name: 'prefetch-state',
      reactive: r.prefetchState,
      parse: (raw, _) => MpvPrefetchState.parse(raw),
      reduce: (_, s) => s,
    ),
    MpvPropertySpec<AudioOutputState>.string(
      name: 'audio-output-state',
      reactive: r.audioOutputState,
      parse: (raw, _) => AudioOutputState.fromMpv(raw),
      reduce: (v, s) => s.copyWith(audioOutputState: v),
      onChange: onAudioOutputState,
    ),
    MpvPropertySpec<bool>.flag(
      name: 'prefetch-playlist',
      reactive: r.prefetchPlaylist,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(prefetchPlaylist: v),
    ),

    // ── Playback timing extras ───────────────────────────────────────────
    MpvPropertySpec<Duration>.double(
      name: 'audio-pts',
      reactive: r.audioPts,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(audioPts: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'time-remaining',
      reactive: r.timeRemaining,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(timeRemaining: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'playtime-remaining',
      reactive: r.playtimeRemaining,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(playtimeRemaining: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'eof-reached',
      reactive: r.eofReached,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(eofReached: v),
    ),

    // ── Stream capability ────────────────────────────────────────────────
    MpvPropertySpec<bool>.flag(
      name: 'seekable',
      reactive: r.seekable,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(seekable: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'partially-seekable',
      reactive: r.partiallySeekable,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(partiallySeekable: v),
    ),

    // ── Display / file metadata ──────────────────────────────────────────
    MpvPropertySpec<String>.string(
      name: 'media-title',
      reactive: r.mediaTitle,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(mediaTitle: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'file-format',
      reactive: r.fileFormat,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(fileFormat: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'file-size',
      reactive: r.fileSize,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(fileSize: v),
    ),

    // ── Buffering depth ──────────────────────────────────────────────────
    MpvPropertySpec<Duration>.double(
      name: 'demuxer-cache-duration',
      reactive: r.bufferDuration,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(bufferDuration: v),
    ),
    MpvPropertySpec<bool>.flag(
      name: 'demuxer-cache-idle',
      reactive: r.demuxerIdle,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(demuxerIdle: v),
    ),

    // ── Chapter navigation ───────────────────────────────────────────────
    // mpv emits `chapter = -1` when no chapter is active; map to `null`.
    MpvPropertySpec<int?>.int64(
      name: 'chapter',
      reactive: r.currentChapter,
      parse: (raw, _) => raw < 0 ? null : raw,
      reduce: (v, s) => s.copyWith(currentChapter: v),
    ),
    MpvPropertySpec<List<Chapter>>.node(
      name: 'chapter-list',
      reactive: r.chapters,
      parse: (raw, _) => parseChapterListNode(raw),
      reduce: (v, s) => s.copyWith(chapters: v),
    ),

    // ── Path / URI introspection (read-only) ─────────────────────────────
    MpvPropertySpec<String>.string(
      name: 'path',
      reactive: r.path,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(path: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'filename',
      reactive: r.filename,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(filename: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'stream-path',
      reactive: r.streamPath,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(streamPath: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'stream-open-filename',
      reactive: r.streamOpenFilename,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(streamOpenFilename: v),
    ),

    // ── A-B loop ────────────────────────────────────────────────────────
    // mpv emits `ab-loop-a` / `-b` as STRING (`'no'` when disabled, a
    // numeric string otherwise — `OPT_TIME` with `M_OPT_ALLOW_NO`).
    MpvPropertySpec<Duration?>.string(
      name: 'ab-loop-a',
      reactive: r.abLoopA,
      parse: (raw, _) => _parseAbLoopTime(raw),
      reduce: (v, s) => s.copyWith(abLoopA: v),
    ),
    MpvPropertySpec<Duration?>.string(
      name: 'ab-loop-b',
      reactive: r.abLoopB,
      parse: (raw, _) => _parseAbLoopTime(raw),
      reduce: (v, s) => s.copyWith(abLoopB: v),
    ),
    // `ab-loop-count` is `OPT_CHOICE` with `'inf'=-1` and a non-negative
    // numeric range. We surface it as a nullable int (`null` = inf).
    MpvPropertySpec<int?>.string(
      name: 'ab-loop-count',
      reactive: r.abLoopCount,
      parse: (raw, _) => _parseAbLoopCount(raw),
      reduce: (v, s) => s.copyWith(abLoopCount: v),
    ),
    // Read-only int. `-1` from mpv == infinity; map to `null`.
    MpvPropertySpec<int?>.int64(
      name: 'remaining-ab-loops',
      reactive: r.remainingAbLoops,
      parse: (raw, _) => raw < 0 ? null : raw,
      reduce: (v, s) => s.copyWith(remainingAbLoops: v),
    ),

    // ── Tier 2 introspection ────────────────────────────────────────────
    MpvPropertySpec<bool>.flag(
      name: 'seeking',
      reactive: r.seeking,
      parse: _identityBool,
      reduce: (v, s) => s.copyWith(seeking: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'percent-pos',
      reactive: r.percentPos,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(percentPos: v),
    ),
    MpvPropertySpec<double>.double(
      name: 'cache-speed',
      reactive: r.cacheSpeed,
      parse: _identityDouble,
      reduce: (v, s) => s.copyWith(cacheSpeed: v),
    ),
    MpvPropertySpec<int>.int64(
      name: 'cache-buffering-state',
      reactive: r.cacheBufferingState,
      parse: _identityInt,
      reduce: (v, s) => s.copyWith(cacheBufferingState: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'current-demuxer',
      reactive: r.currentDemuxer,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(currentDemuxer: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'current-ao',
      reactive: r.currentAo,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(currentAo: v),
    ),
    MpvPropertySpec<Duration>.double(
      name: 'demuxer-start-time',
      reactive: r.demuxerStartTime,
      parse: _toDuration,
      reduce: (v, s) => s.copyWith(demuxerStartTime: v),
    ),
    MpvPropertySpec<Map<String, String>>.node(
      name: 'chapter-metadata',
      reactive: r.chapterMetadata,
      parse: (raw, _) => _parseStringMap(raw),
      reduce: (v, s) => s.copyWith(chapterMetadata: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'mpv-version',
      reactive: r.mpvVersion,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(mpvVersion: v),
    ),
    MpvPropertySpec<String>.string(
      name: 'ffmpeg-version',
      reactive: r.ffmpegVersion,
      parse: _identityString,
      reduce: (v, s) => s.copyWith(ffmpegVersion: v),
    ),
  ];
}

/// Decodes a `MPV_FORMAT_NODE_MAP` whose values are uniformly strings
/// (mpv emits this shape for `chapter-metadata`, `vf-metadata`, …).
/// Falls back to an empty map on a non-map payload — a single malformed
/// emission shouldn't tear down the consumer's metadata view.
Map<String, String> _parseStringMap(dynamic raw) {
  if (raw is! Map) return const <String, String>{};
  return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
}

// ── Tiny inline parsers used by buildDefaultSpecs ──────────────────────────

double _identityDouble(double raw, PlayerState _) => raw;
int _identityInt(int raw, PlayerState _) => raw;
bool _identityBool(bool raw, PlayerState _) => raw;
String _identityString(String raw, PlayerState _) => raw;
Duration _toDuration(double raw, PlayerState _) => secondsToDuration(raw);

/// `ab-loop-a` / `ab-loop-b` parser. mpv emits `'no'` when disabled
/// (the `M_OPT_ALLOW_NO` flag on `OPT_TIME`); any other value is a
/// numeric string in seconds.
Duration? _parseAbLoopTime(String raw) {
  if (raw == 'no' || raw.isEmpty) return null;
  final secs = double.tryParse(raw);
  if (secs == null || secs.isNaN) return null;
  return secondsToDuration(secs);
}

/// `ab-loop-count` parser. `'inf'` = infinite; non-negative int = explicit
/// repetition count.
int? _parseAbLoopCount(String raw) {
  if (raw == 'inf' || raw.isEmpty) return null;
  return int.tryParse(raw);
}

/// `image-display-duration` parser: mpv emits `'inf'` for "keep
/// indefinitely", a numeric string (seconds) otherwise. Maps to
/// `Duration?` with `null = inf`. Unparseable values fall back to `null`.
Duration? _parseImageDisplayDuration(String raw) {
  if (raw == 'inf' || raw.isEmpty) return null;
  final secs = double.tryParse(raw);
  if (secs == null) return null;
  return secondsToDuration(secs);
}
