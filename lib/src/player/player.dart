// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, listEquals;
import 'package:flutter/services.dart' show RootIsolateToken;
import 'package:meta/meta.dart';

import '../backend/backend.dart';
import '../dsp/filter_tap_pipeline.dart';
import '../dsp/loudness_meter_pipeline.dart';
import '../dsp/loudness_scan_pipeline.dart';
import '../dsp/spectrum_pipeline.dart';
import '../dsp/waveform_pipeline.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_log_entry.dart';
import '../events/player_error.dart';
import '../events/player_exception.dart';
import '../generated/audio_effects_settings.dart';
import '../internals/audio_effects_validation.dart';
import '../internals/core_calls.dart';
import '../internals/core_events.dart';
import '../internals/debug_log.dart';
import '../internals/duration_seconds.dart';
import '../internals/entry_table.dart';
import '../internals/hook_table.dart';
import '../internals/mpv_audio_kit.dart';
import '../internals/mpv_float.dart';
import '../internals/owned_source.dart';
import '../internals/transport_machine.dart';
import '../internals/uri_resolver.dart';
import '../media_session/media_session_controller.dart';
import '../media_session/media_session_inputs.dart';
import '../models/chapter.dart';
import '../models/cover_art.dart';
import '../models/demuxer_cache_state.dart';
import '../models/device.dart';
import '../models/fft_frame.dart';
import '../models/loudness.dart';
import '../models/loudness_scan.dart';
import '../models/media.dart';
import '../models/media_session.dart';
import '../models/pcm_frame.dart';
import '../models/playlist.dart';
import '../models/source_resolve_request.dart';
import '../models/waveform_data.dart';
import '../mpv_constants.dart' hide MpvEndFileReason;
import '../pcm/pcm_format.dart';
import '../pcm/pcm_source.dart';
import '../reactive/default_reactives.dart';
import '../reactive/default_specs.dart';
import '../reactive/duration_hint.dart';
import '../reactive/node_parsers.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../types/enums/cover.dart';
import '../types/enums/format.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hls_bitrate.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/enums/loop.dart';
import '../types/enums/spdif.dart';
import '../types/enums/tap_side.dart';
import '../types/sealed/channels.dart';
import '../types/sealed/media_session_command.dart';
import '../types/sealed/track.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/demuxer_settings.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../types/state/audio_output_state.dart';
import 'audio_output_error.dart';
import 'lifecycle_transitions.dart';
import 'player_api.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import 'player_stream.dart';
import 'playlist_nav_gate.dart';

part 'mixins/player_audio.part.dart';
part 'mixins/player_dispatch.part.dart';
part 'mixins/player_effects.part.dart';
part 'mixins/player_ffi.part.dart';
part 'mixins/player_hooks.part.dart';
part 'mixins/player_init.part.dart';
part 'mixins/player_intent.part.dart';
part 'mixins/player_lifecycle.part.dart';
part 'mixins/player_load_validation.part.dart';
part 'mixins/player_media_session.part.dart';
part 'mixins/player_network.part.dart';
part 'mixins/player_open.part.dart';
part 'mixins/player_output.part.dart';
part 'mixins/player_pcm.part.dart';
part 'mixins/player_playback.part.dart';
part 'mixins/player_playlist.part.dart';

/// An audio player on libmpv: a queue, effects, analysis and the OS media
/// session.
///
/// Implements [PlayerApi] so test code can mock the player without
/// dragging in the FFI handle and event isolate
/// (`class MockPlayer extends Mock implements PlayerApi {}`).
///
/// {@category Playback}
class Player extends _PlayerBase
    with
        _FfiModule,
        _LoadValidationModule,
        _OpenModule,
        _InitModule,
        _DispatchModule,
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _OutputModule,
        _EffectsModule,
        _NetworkModule,
        _PcmModule,
        _HooksModule,
        _MediaSessionModule
    implements PlayerApi {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration});

  /// Test-only. The event isolate writes to [wakeupCounterAddress] on
  /// every wakeup: a bogus value corrupts process memory.
  @visibleForTesting
  Player.testInstrumented({
    super.configuration,
    required int super.wakeupCounterAddress,
  });

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// `pause` is set as a global property before `loadfile` so the
  /// property observer always fires on the first-load transition
  /// (a per-file option can skip the `PROPERTY_CHANGE` emit).
  /// Rapid back-to-back `open()` calls don't race: each call claims the
  /// load epoch synchronously and aborts at its next await once a later
  /// content-replacing call (open, openAll, openPlaylistFile, stop,
  /// clearPlaylist) has claimed a newer one, so the call that is LAST
  /// in program order wins, regardless of per-URI resolve latency.
  @override
  Future<void> open(Media media, {bool? play}) =>
      _transport.trackLoad(() => _open(media, play));

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// Multi-media counterpart of [open]. [index] is clamped to
  /// `[0, medias.length - 1]`.
  ///
  /// Entries are appended on the core WITHOUT starting playback (mpv's
  /// `loadfile append` never autostarts), then a single
  /// `playlist-play-index` starts directly at [index]. The entry at
  /// position 0 is never loaded, played, or reported as current unless
  /// it IS the requested index, so a UI bound to
  /// [PlaybackState.playlist]'s `index` never flashes track 1 before the
  /// selected track, and no audio from track 1 leaks out. During the
  /// transition the outgoing track keeps playing (or stays parked) until
  /// the jump; while entries build up on an idle core the playlist
  /// `index` reports `-1` (see [Playlist.index]).
  ///
  /// The call succeeds or fails as a whole. When mpv refuses an entry it
  /// throws [MpvCommandException], the entries it already added leave the
  /// playlist, the track that was playing keeps playing (parked at the
  /// end, the playlist is left empty), and the play intent goes back to
  /// what it was.
  @override
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) =>
      _transport.trackLoad(() => _openAll(medias, play, index));

  /// Loads a playlist FILE or URL (`.m3u`, `.m3u8`, `.pls` or `.cue`) and
  /// optionally starts playback. Unlike [open], which loads [playlist] as a
  /// single entry, this parses it with mpv's `loadlist`, so its entries
  /// become the playlist. This is the path for internet-radio station lists
  /// and remote `.m3u` playlists.
  ///
  /// [PlayerStream.playlist] and [PlaybackState.playlist] reflect the parsed
  /// entries once mpv expands them. When [play] is null the configuration's
  /// autoplay value decides. Replaces any currently loaded file or playlist.
  ///
  /// Per-[Media] options (`httpHeaders`, `demuxerLavfOptions`, `httpChunkSize`,
  /// `start`, `end`, `waveformDurationHint`) are validated but NOT applied
  /// to the playlist fetch:
  /// `loadlist` has no file-local options slot. Entries parsed out of the playlist inherit the
  /// global network and demuxer settings.
  @override
  Future<void> openPlaylistFile(Media playlist, {bool? play}) =>
      _transport.trackLoad(() => _openPlaylistFile(playlist, play));

  @override
  Future<void> _disposeImpl() async {
    // New calls are refused from the first line, as the teardown order
    // in [_PlayerBase.dispose] says.
    _disposed = true;
    // Before the first await: a hook timer firing during the session
    // release would drop its id without continuing it (it skips the FFI
    // call once disposed), and mpv would wait on that hook at shutdown.
    // Every pending hook continues now, so the `quit` that follows finds
    // no operation held by this client. (The event isolate exits anyway,
    // on its stop flag, and mpv_terminate_destroy completes the hooks of
    // the removed client; the continue keeps the core from waiting on them
    // meanwhile.) An event is pending only once bring-up delivered it, so
    // the handle exists here.
    for (final (mpvId, name) in _hooks.takeAll()) {
      _continueMpvHook(mpvId, name);
    }
    // Before the quit: an ended source wakes a reader blocked on it.
    _entries.endLive();
    // Release the OS media session BEFORE tearing libmpv down. After
    // the base teardown the FFI handle is gone: leaving the native
    // session published would surface a stale lockscreen entry
    // pointing at a dead Player, and incoming commands (play from
    // the lockscreen) would land on disposed state.
    try {
      await _releaseMediaSession();
    } catch (_) {
      // Best effort: session teardown must never block disposal.
    }
    await super._disposeImpl();
  }
}

/// Base class for [Player] containing shared state and native communication
/// logic.
///
/// Owns:
/// - the session to the core (the backend's event pump and client),
/// - the [PropertyRegistry] for the ~90 simple mpv properties,
/// - the small set of standalone [ReactiveProperty]s and [StreamController]s
///   that back state fields not directly mirrored by an mpv property
///   (lifecycle: `buffering`/`completed`; complex node parses: `playlist`,
///   `metadata`, `audioDevices`, `bufferingPercentage`; pure events: log,
///   error, hook, end-of-file, seek-completed).
abstract class _PlayerBase {
  /// The configuration captured at construction time.
  final PlayerConfiguration configuration;

  // The core and the client to it, through the backend of the platform
  // (an event isolate over FFI, or the module in WebAssembly on the web).
  // Created with the player so `dispose()` is safe even when invoked
  // synchronously after construction; the core starts in bring-up, driven
  // by `_ready`.
  final MpvSession _session;
  bool _disposed = false;

  /// The transport axis: the load epoch, the loads in flight, the
  /// play-pause intent and the file starts.
  late final _Transport _transport = _Transport(this);

  // The registered hooks and the pending hook events, with the ids the
  // library hands out and the deadlines.
  late final _hooks = HookTable(
    onTimeout: (id, name, timeout, mpvId) {
      _internalLog(
        'Hook "$name" (id=$id) timed out after ${timeout.inSeconds}s, '
        'auto-continuing to unblock mpv',
        level: LogLevel.warn,
      );
      if (!_disposed) _continueMpvHook(mpvId, name);
    },
  );

  /// Continues mpv's event [mpvId] of hook [name]. `mpv_hook_continue`
  /// locks the core: for a hook that holds a load (`on_load` and the
  /// others) mpv waits in the hook's dispatch loop for exactly this call,
  /// so the lock comes at once. For `on_prefetch` the playloop keeps
  /// running, and the call waits for whatever the core is doing (an audio
  /// output that takes seconds to open), so it goes off the main isolate
  /// (kit-core-1).
  void _continueMpvHook(int mpvId, String name) =>
      _calls.hookContinue(mpvId, prefetch: name == Hook.prefetch.mpvValue);

  // The installed [SourceResolver]; null = feature off. Set by
  // [Player.setSourceResolver], consulted by `_routeHookEvent` on every
  // `on_load` or `on_load_fail` event.
  SourceResolver? _sourceResolver;

  // Latched when the resolver services an `on_load_fail` for the current
  // load attempt, cleared on the next START_FILE only (not on `on_load`,
  // which mpv re-enters for the same attempt after the retry). Caps the
  // resolver-driven retry at ONE per load: a resolver that keeps minting
  // fresh-but-broken URLs (e.g. a timestamped query string) would
  // otherwise put mpv in an infinite open-fail-reopen loop.
  bool _resolverRetried = false;

  // What the resolver gave for the prefetch of the next entry: the URL mpv
  // was about to open, the one it opened instead, the load epoch then, and
  // the entry (`null` when its read failed). The
  // load of that entry, or of that URL without one, in the same epoch takes
  // it once (F10, kit-core-3).
  (String, String, _LoadTicket, int?)? _prefetchResolved;

  PlayerState _state = const PlayerState();

  /// Reused `commit` callback for every registry dispatch: tearing off (or
  /// closing over) per event would be one piece of garbage per property
  /// change, so the tear-off is captured once.
  late final void Function(PlayerState) _commitState = _assignState;

  void _assignState(PlayerState s) => _state = s;

  final Map<String, Media> _mediaCache = {};

  /// The keys of [_mediaCache] a source resolver gave, which
  /// `_cacheResolved` turns over at each load.
  final Set<String> _resolvedKeys = {};

  /// How many add, insert and replace calls are between their first write
  /// to [_mediaCache] and mpv's answer: the cache is not pruned meanwhile.
  int _entryLoads = 0;

  /// The playlist entries this player loaded, by mpv's `playlist_entry_id`:
  /// their [Media] (unlike [_mediaCache], two entries with the same URI keep
  /// their own `extras`), and the live PCM sources and `fd://` descriptors
  /// they hold until mpv can no longer read them, so the app need not keep
  /// a reference.
  late final EntryTable _entries = EntryTable(readPlaylist: _readPlaylist);

  /// mpv's playlist, read now; `null` when the read failed or the player
  /// was disposed meanwhile.
  Future<List<Object?>?> _readPlaylist() async {
    final (rc, node) = await _calls.get('playlist', MpvFormat.mpvFormatNode);
    return rc < 0 || node is! List || _disposed ? null : node;
  }

  /// Deletes a resume point saved under the descriptor number of an
  /// `fd://` source [uri], before its load. mpv keys the point by
  /// that number, which the system hands out again to the next file
  /// opened, so a point saved for one file (0.5.1 and earlier wrote them)
  /// started another at its position. mpv reads the point as the entry
  /// loads, before any option of the entry applies, so no option can turn
  /// it off for one entry.
  Future<void> _forgetFdResume(String uri) async {
    if (!isFdUri(uri)) return;
    await _calls.command(['delete-watch-later-config', uri]);
  }

  // ── Property registry (the bulk of state: one spec per mpv property) ──
  late final DefaultPropertyReactives _reactives;

  /// mpv's duration and its flag with the entry's hint; applied again at
  /// each playlist update (see [DurationHint]).
  late final DurationHint _durationHint;
  late final PropertyRegistry _registry;

  // ── Standalone reactive properties (no 1:1 mpv property backing) ───────
  // Lifecycle flags driven by file-boundary events, not by a single property.
  final ReactiveProperty<bool> _buffering = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> _completed = ReactiveProperty<bool>(false);
  // Derived from node properties that need access to player-side context.
  final ReactiveProperty<Playlist> _playlist = ReactiveProperty<Playlist>(
    Playlist.empty,
  );
  final ReactiveProperty<Loop> _loop = ReactiveProperty<Loop>(Loop.off);
  final ReactiveProperty<List<Device>> _audioDevices =
      ReactiveProperty<List<Device>>(const [
        Device(name: 'auto', description: 'Auto'),
      ]);
  final ReactiveProperty<Map<String, String>> _metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> _bufferingPercentage =
      ReactiveProperty<double>(0.0);
  final ReactiveProperty<DemuxerCacheState> _demuxerCacheState =
      ReactiveProperty<DemuxerCacheState>(DemuxerCacheState.empty);
  // OS media-session config + metadata override. Null = disabled.
  // Updated synchronously by [_MediaSessionModule.setMediaSession].
  final ReactiveProperty<MediaSession?> _mediaSession =
      ReactiveProperty<MediaSession?>(null);

  // Dart-side orchestrator that ferries state from `PlayerStream` to
  // the native media-session channel and routes inbound OS commands
  // back. Null while the session is disabled; lazily allocated on
  // first `setMediaSession(non-null)` and torn down on disable or
  // on `dispose()`.
  MediaSessionController? _mediaSessionController;

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> _endFileCtrl =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<PlayerError> _errorCtrl =
      StreamController<PlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec, demux, ao and so on).
  final StreamController<MpvLogEntry> _logCtrl =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart layer itself: node parse warnings, hook
  // timeouts, etc. Kept disjoint from `_logCtrl` so library-side noise
  // can be filtered from genuine engine messages without inspecting
  // the prefix.
  final StreamController<MpvLogEntry> _internalLogCtrl =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> _hookCtrl =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> _seekCompletedCtrl =
      StreamController<void>.broadcast();
  // Nullable payload: each file-loaded transition emits exactly once,
  // with `null` when the new file has no embedded cover. This lets a
  // UI clear or reset on every track change without having to compare
  // against a separate file-transition signal.
  final StreamController<CoverArt?> _coverArtCtrl =
      StreamController<CoverArt?>.broadcast();
  // Incoming commands from the OS media session (lockscreen, BT
  // headset, Siri, Assistant), routed back from the per-platform
  // native implementation.
  final StreamController<MediaSessionCommand> _mediaSessionCommandsCtrl =
      StreamController<MediaSessionCommand>.broadcast();

  // Real-time FFT + raw PCM pipeline. Lazy: the poll loop starts only
  // when something subscribes to `stream.spectrum` or `stream.pcm`.
  late final SpectrumPipeline _spectrumPipeline;

  // Static waveform analyzer. Listener-gated: arms the native
  // analyzer and polls only while `stream.waveform` has a listener.
  late final WaveformPipeline _waveformPipeline;

  // Per-filter pre and post audio tap. Lazy: arms the analyzer-taps
  // property only when at least one [PlayerStream.tap] stream has a
  // listener.
  late final FilterTapPipeline _filterTapPipeline;

  // Live EBU R128 meter. Listener-gated: polls `af-metadata` only while
  // `stream.loudnessMeter` has a listener (the `ebur128` effect itself
  // is a stage the consumer puts in the effects chain).
  late final LoudnessMeterPipeline _loudnessMeterPipeline;

  // Offline loudness scan. Listener-gated: arms the native whole-file
  // scan and polls only while `stream.loudnessScan` has a listener.
  late final LoudnessScanPipeline _loudnessScanPipeline;

  /// Synchronous snapshot of the player's complete state. Updated on
  /// every observed property change before the corresponding stream
  /// emits.
  PlayerState get state => _state;

  /// Typed event streams for individual state fields and transient
  /// events.
  late final PlayerStream stream;

  // ── Cross-mixin surface ──────────────────────────────────────────────────
  // These members live in the `.part` mixins below but are declared here
  // (abstract) so `_PlayerBase`'s constructor, `dispose` and the sibling
  // domain mixins can call across part boundaries: `on _PlayerBase` only
  // exposes what `_PlayerBase` itself declares.

  /// See `_FfiModule` (player_ffi.part.dart).
  Future<void> _loadfile(List<String> args, Media media, OwnedSource source);

  /// See `_DispatchModule` (player_dispatch.part.dart).
  void _updatePlaylistFromNode(dynamic raw);

  /// Every call to libmpv once the player runs, on top of [_session]. All
  /// of them ride the async client API (`mpv_*_async`): the main isolate
  /// never waits for the playloop. Most setters update the state once the
  /// reply confirms the write; the play-pause intent and the settings
  /// bundles ([CoreCalls.writeBundle]) update it before the write.
  late final CoreCalls _calls;

  /// See `_LoadValidationModule` (player_load_validation.part.dart).
  String _buildLoadfileOptions(Media media);
  void _validateLoadOptions(Media media);
  void _rejectPcm(Media media, String name);

  /// Reads the mpv property [name] as a string for a call already past
  /// [_gate]: `null` when the read fails, also once dispose closed the
  /// session. Unlike the public `getRawProperty` it does not refuse a
  /// disposed player, so a call under way at dispose ends without effect,
  /// as its writes do, instead of throwing from the middle.
  Future<String?> _readString(String name) async {
    final (rc, value) = await _calls.get(name, MpvFormat.mpvFormatString);
    return rc < 0 ? null : value as String?;
  }

  /// See `_HooksModule` (player_hooks.part.dart): called by the dispatch
  /// layer for every MPV_EVENT_HOOK: runs the source resolver when one is
  /// installed, then either surfaces the event on [PlayerStream.hook]
  /// (user-registered hook) or continues it internally.
  Future<void> _routeHookEvent(int id, Hook hook, String name);

  /// mpv loaded a file, after applying the resume point it may hold: see
  /// `_EffectsModule` (player_effects.part.dart).
  void _reassertAfChain();

  /// See `_InitModule` (player_init.part.dart): called by the constructor.
  Future<void> _bringUp();

  /// See `_DispatchModule` (player_dispatch.part.dart): wired as the event
  /// pump's `onEvent` during bring-up.
  void _handleEvent(MpvIsolateEvent event);

  /// See `_DispatchModule`: `setAudioDevice` reuses it to optimistically
  /// resolve the device description from the parsed `audio-device-list`.
  void _updateActiveAudioDevice(String name);

  _PlayerBase({
    this.configuration = const PlayerConfiguration(),
    int? wakeupCounterAddress,
  }) : _session = createMpvSession(wakeupCounterAddress: wakeupCounterAddress) {
    // Pure-Dart setup runs on the main isolate (microseconds).
    _reactives = DefaultPropertyReactives();
    _durationHint = DurationHint(_reactives);
    _registry = PropertyRegistry()
      ..registerAll(
        buildDefaultSpecs(
          _reactives,
          onIdleActive: _transport.onIdle,
          onAudioOutputState: _onAudioOutputState,
          durationHint: _durationHint,
        ),
      );

    // Streams that don't need the core can be wired immediately:
    // a consumer subscribing right after `Player()` sees no events
    // until init completes, which is the correct semantics.
    _wireAnalysisControllers();
    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      loop: _loop,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      demuxerCacheState: _demuxerCacheState,
      audioEffects: _reactives.audioEffects,
      mediaSession: _mediaSession,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArt: replayStream(() => _state.file.coverArt, _coverArtCtrl.stream),
      fft: _fftCtrl.stream,
      pcm: _pcmStreamCtrl.stream,
      spectrum: _reactives.spectrum.stream,
      waveform: replayStream(() => _lastWaveform, _waveformCtrl.stream),
      loudnessMeter: _loudnessMeterCtrl.stream,
      loudnessScan: replayStream(
        () => _lastLoudnessScan,
        _loudnessScanCtrl.stream,
      ),
      tap: (filter, {instance = 0, required side}) => switch (side) {
        TapSide.pre => _filterTapPipeline.tapPre(
          audioEffectLabel(filter.filterName, instance),
        ),
        TapSide.post => _filterTapPipeline.tapPost(
          audioEffectLabel(filter.filterName, instance),
        ),
      },
      mediaSessionCommands: _mediaSessionCommandsCtrl.stream,
    );

    // Build the recipe and hand it to the session, which starts the core
    // off the UI thread's way. A failed init reaches every call that awaits
    // it; a player nobody uses yet must not report it as an unhandled
    // error.
    _ready = _bringUp()..ignore();
  }

  /// The controllers of the analysis streams (fft, pcm, waveform, loudness
  /// meter and scan), whose listeners arm the pipelines built at bring-up.
  void _wireAnalysisControllers() {
    // The fft and pcm bridges into the spectrum pipeline are listener-gated:
    // the pipeline arms its 30fps `pcm-tap-frame` poll as soon as its own
    // streams have a listener, so bridging unconditionally would keep the
    // poll running for the player's whole lifetime with zero consumers.
    // Subscribers that land before bring-up are reconciled once the
    // pipeline exists (see `_bringUp`).
    _fftCtrl = StreamController<FftFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _fftPipeSub ??= _spectrumPipeline.fftStream.listen(_fftCtrl.add);
        }
      },
      onCancel: () {
        final sub = _fftPipeSub;
        _fftPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    _pcmStreamCtrl = StreamController<PcmFrame>.broadcast(
      onListen: () {
        if (_bringUpCompleted) {
          _pcmPipeSub ??= _spectrumPipeline.pcmStream.listen(
            _pcmStreamCtrl.add,
          );
        }
      },
      onCancel: () {
        final sub = _pcmPipeSub;
        _pcmPipeSub = null;
        if (sub != null) unawaited(sub.cancel());
      },
    );
    // Listener-gated: the native waveform analyzer arms only while a
    // consumer is subscribed. The pipeline is built during bring-up; a
    // subscriber that lands before then is reconciled once bring-up
    // finishes (see `_bringUp`).
    _waveformCtrl = StreamController<WaveformData?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _waveformPipeline.setEnabled(true);
      },
      onCancel: () {
        if (!_bringUpCompleted) return;
        _waveformPipeline.setEnabled(false);
      },
    );
    // Same listener-gating as the waveform: the af-metadata poll runs
    // only while someone is subscribed to `stream.loudnessMeter`.
    _loudnessMeterCtrl = StreamController<Loudness>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessMeterPipeline.setEnabled(false);
      },
    );
    // Listener-gated like the waveform: the native whole-file scan runs
    // only while someone is subscribed to `stream.loudnessScan`.
    _loudnessScanCtrl = StreamController<LoudnessScan?>.broadcast(
      onListen: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(true);
      },
      onCancel: () {
        if (_bringUpCompleted) _loudnessScanPipeline.setEnabled(false);
      },
    );
  }

  /// Test-only: allows tests to await the post-`Player()` init that
  /// runs in the background. Public methods already
  /// `await _ready` internally so consumers don't normally need this.
  @visibleForTesting
  Future<void> get ready => _ready;

  late final Future<void> _ready;
  bool _bringUpCompleted = false;

  /// The path of the last FILE_LOADED, to tell the same file loaded again
  /// for the analyses (see `_onFileLoaded`).
  String? _analysisPath;

  /// The level of the last [setLogLevel] call, applied at the end of
  /// bring-up when the call came before it.
  LogLevel? _pendingLogLevel;

  late final StreamController<FftFrame> _fftCtrl;
  late final StreamController<PcmFrame> _pcmStreamCtrl;
  // Lazy bridges into the spectrum pipeline: non-null exactly while the
  // matching public stream has a listener (they keep the pipeline's
  // listener-gated poll loop armed; see the controllers' onListen).
  StreamSubscription<FftFrame>? _fftPipeSub;
  StreamSubscription<PcmFrame>? _pcmPipeSub;
  late final StreamController<WaveformData?> _waveformCtrl;
  // The last envelope and scan result, replayed to a new subscriber of
  // `stream.waveform` and `stream.loudnessScan`.
  WaveformData? _lastWaveform;
  LoudnessScan? _lastLoudnessScan;
  late final StreamController<Loudness> _loudnessMeterCtrl;
  late final StreamController<LoudnessScan?> _loudnessScanCtrl;

  void _checkNotDisposed() {
    if (_disposed) {
      throw const PlayerDisposedException();
    }
  }

  /// Shared prologue for every public method that touches the core: fail
  /// fast when already disposed, await bring-up, then verify bring-up
  /// actually completed. A dispose() that lands while the caller is parked
  /// on [_ready] aborts bring-up early: [_ready] still completes normally,
  /// but [_calls] was never assigned, so resuming into a call would throw
  /// [LateInitializationError] instead of the [PlayerDisposedException]
  /// the API contract promises.
  Future<void> _gate() async {
    _checkNotDisposed();
    await _ready;
    if (!_bringUpCompleted) {
      throw const PlayerDisposedException();
    }
  }

  /// Rejects NaN, +Inf and -Inf before they reach `toStringAsFixed`,
  /// which would emit the literal `'NaN'` or `'Infinity'` and have mpv
  /// reject the property write at the FFI boundary. Catching it on the
  /// wrapper side gives the caller a precise [ArgumentError] naming the
  /// parameter, instead of an opaque [MpvCommandException] from libmpv.
  /// Throws [RangeError] unless [value] is finite and within
  /// `[min, max]`, the range mpv accepts for the option behind it.
  void _checkRange(double value, double min, double max, String paramName) {
    _checkFinite(value, paramName);
    if (value < min || value > max) {
      throw RangeError.value(
        value,
        paramName,
        max == double.maxFinite ? 'must be >= $min' : 'must be in [$min, $max]',
      );
    }
  }

  void _checkFinite(double value, String paramName) {
    if (!value.isFinite) {
      throw ArgumentError.value(
        value,
        paramName,
        'Expected a finite double (got NaN/Infinity)',
      );
    }
  }

  // --- Internal State Pipeline ---

  /// Optimistic state update used by every typed setter after pushing
  /// a value to mpv. Writes [value] into [reactive] (which dedups, so
  /// equal writes are silent on the stream) and folds it into [_state]
  /// via [updater]. Short-circuits on dedup to skip a redundant
  /// [PlayerState] allocation.
  void _updateField<T>(
    PlayerState Function(PlayerState) updater,
    ReactiveProperty<T> reactive,
    T value,
  ) {
    if (!reactive.update(value)) return;
    _state = updater(_state);
  }

  /// mpv reported the output [state]: an output that failed is an error on
  /// [PlayerStream.error], and one that opened may be the null driver.
  void _onAudioOutputState(AudioOutputState state) {
    final err = buildAudioOutputError(state);
    if (err != null) _errorCtrl.add(err);
    if (state == AudioOutputState.active) {
      unawaited(_reportNullFallback());
    }
  }

  /// The output just opened. With `audio-fallback-to-null` (pre-init
  /// options) mpv opens the null driver when no device can be opened: the
  /// state says `active` and the position runs, but nothing is heard.
  /// Reported on [PlayerStream.error] once for each opening, unless the
  /// app chose the null driver itself. Read from the core, not the state:
  /// `current-ao` is reported after `audio-output-state`.
  Future<void> _reportNullFallback() async {
    if (!_bringUpCompleted || _disposed) return;
    final (rc, current) = await _calls.get(
      'current-ao',
      MpvFormat.mpvFormatString,
    );
    if (rc < 0 || current != 'null' || _disposed) return;
    final (aoRc, ao) = await _calls.get('ao', MpvFormat.mpvFormatString);
    if (aoRc < 0 || ao is! String || aoListHasNull(ao) || _disposed) return;
    _errorCtrl.add(nullOutputError);
  }

  /// Internal log helper: emits on the library-side log channel
  /// ([PlayerStream.internalLog]), kept separate from mpv's engine log
  /// stream ([PlayerStream.log]). Dropped once dispose closed the channel:
  /// an async path (a source resolver failing late) can still log then.
  void _internalLog(String message, {LogLevel level = LogLevel.info}) {
    if (_internalLogCtrl.isClosed) return;
    _internalLogCtrl.add(
      MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message),
    );
  }

  /// Tears down the player.
  ///
  /// The teardown order is load-bearing. The sequence is:
  ///
  /// 1. **Flip `_disposed`** so any subsequent setter or public-API call
  ///    fails fast via `_checkNotDisposed()`. Before any await, continue
  ///    the pending hooks and end the live PCM sources (a reader blocked
  ///    on one wakes up), then release the OS media session.
  /// 2. **Await bring-up**, then **drop the core from the Hot Restart
  ///    cleanup** ([MpvSession.untrack]) so a hot-restart that fires before
  ///    the destroy completes doesn't try to clean up a handle we're
  ///    already cleaning up, and **dispose the DSP pipelines** (each turns
  ///    off what it armed).
  /// 3. **Send the `quit` command** to mpv. mpv processes it
  ///    asynchronously and fires `MPV_EVENT_SHUTDOWN` inside its own
  ///    event queue.
  /// 4. **`requestStop` (stop flag + `mpv_wakeup` natively)** so the event loop
  ///    unwinds deterministically even if `quit` was dropped or
  ///    `MPV_EVENT_SHUTDOWN` is delayed by a stalled hook. Then dispose
  ///    the filter taps, whose streams the app listens to directly.
  /// 5. **Await [MpvSession.stop]**, which returns `true` only once the
  ///    event pump has ACTUALLY stopped (natively, the isolate exited), so
  ///    it is provably off `mpv_wait_event`. Then wait (bounded) for any
  ///    `registerHook` still running `mpv_hook_add`, and **close the
  ///    client**, which settles every in-flight call.
  /// 6. **[MpvSession.terminateDestroy]** ONLY when the exit and the hook
  ///    registrations are confirmed, in a throwaway isolate and awaited
  ///    (it waits for the core to shut down and the output to close),
  ///    then release the held `content://` descriptors. Destroying the
  ///    handle while the isolate is still inside `mpv_wait_event` would
  ///    race the event-loop thread and crash libmpv when the handle is
  ///    freed mid-syscall; on an unconfirmed exit dispose goes on without
  ///    the destroy, which follows once the pump has stopped.
  /// 7. **Close all reactive properties + controllers**. Order within
  ///    this group does not matter for correctness (they tolerate
  ///    `close()` while a listener is attached); grouping by ownership
  ///    is for auditability. The closes are not awaited: an active
  ///    listener gets `done` right after dispose completes, a paused one
  ///    when it resumes.
  ///
  /// Idempotent AND await-safe: every call, including concurrent ones,
  /// returns the same teardown future, so a second `await dispose()`
  /// completes only when the teardown has actually finished (a bare
  /// `_disposed` early-return would let the second caller proceed while
  /// native resources are still being released).
  Future<void> dispose() => _disposeFuture ??= _disposeImpl();

  Future<void>? _disposeFuture;

  Future<void> _disposeImpl() async {
    // `_disposed` is already set: [Player._disposeImpl] sets it on its
    // first line, before its own steps.

    // Wait for init to settle. The handle, lib and native-resources
    // fields are only assigned when bring-up reaches the very end of
    // its body, so `_bringUpCompleted` is the authoritative gate for
    // touching them, even if `_ready` resolved without throwing it
    // may have early-returned because dispose flipped during init.
    try {
      await _ready;
    } catch (_) {}

    if (_bringUpCompleted) {
      _session.untrack();
      await _waveformPipeline.dispose();
      await _spectrumPipeline.dispose();
      await _loudnessMeterPipeline.dispose();
      await _loudnessScanPipeline.dispose();
      // Cooperative quit: mpv fires MPV_EVENT_SHUTDOWN and the isolate's
      // mpv_wait_event returns. requestStop (stop flag + mpv_wakeup) unblocks
      // the loop deterministically even if `quit` was dropped or SHUTDOWN is
      // delayed by a stalled hook. mpv_terminate_destroy runs only AFTER the
      // confirmed exit below: destroying mid-syscall would crash libmpv.
      // Fire-and-forget: quit's reply may never be forwarded (the isolate is
      // about to stop): the drain below settles the dangling future.
      unawaited(_calls.command(['quit']));
      _session.requestStop();
      // The taps after the quit: their streams are the app's own, and
      // nothing a listener does may keep mpv alive. The analyzer-taps write
      // still reaches the core, which serves it before the destroy below.
      await _filterTapPipeline.dispose();
      final exited = await _session.stop();
      // A registerHook may still be running mpv_hook_add against this
      // handle: it MUST finish before the handle is freed below. quit + the
      // stop above have driven the core toward a dispatch point, so the
      // core-locked hook_add is granted and returns. Bounded: if it doesn't
      // settle (a pathologically stuck playloop), skip the destroy and leak
      // the handle rather than free it under the running call (same
      // trade-off as an unconfirmed event-isolate exit).
      final hooksSettled = await _session.settleHookAdds(
        const Duration(seconds: 2),
      );
      // From here no FFI may touch the handle, and no reply can arrive:
      // closing the client resolves every in-flight call, so an
      // `await player.setX(...)` racing dispose never hangs, and turns the
      // continuations that resumes (a setter suspended between writes)
      // into no-ops, while the destroy below frees the handle.
      _session.close();
      if (exited && hooksSettled) {
        // Off the main isolate: the destroy waits for the core to shut down.
        await _session.terminateDestroy();
        // mpv is gone: nothing reads the descriptors any more.
        for (final release in _entries.takeAll()) {
          await release();
        }
      } else {
        // The worker did not confirm it left mpv_wait_event within the bound.
        // No mpv_terminate_destroy now: freeing the handle while the isolate
        // may still be inside the syscall would SIGSEGV. The destroy follows
        // once the worker has left, without holding dispose.
        debugLog(
          'mpv_audio_kit: event isolate did not confirm exit; '
          'mpv_terminate_destroy waits for it.',
        );
        unawaited(_destroyOnceStopped());
      }
    } else {
      // Bring-up never completed: either init failed, or this dispose
      // aborted it, in which case bring-up's early-return branch (the
      // only code that ever saw the handle) has already quit the core
      // and stopped the worker, and the `await _ready` above waited for
      // that teardown. The stop() here is a best-effort no-op backstop.
      try {
        await _session.stop();
      } catch (_) {}
    }

    // Tear down the media-session controller before closing the
    // backing reactives: its subscriptions need live streams to
    // cancel cleanly, and its final `disable()` call to native
    // needs the controller still wired. `Player._disposeImpl` already
    // calls `_releaseMediaSession()` (which tears the controller
    // down) before reaching here, but we double-check for safety in
    // case a future code path skips that step.
    final controller = _mediaSessionController;
    _mediaSessionController = null;
    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {
        // Best effort: never block disposal on session teardown.
      }
    }

    await _closeStreams();
  }

  /// Destroys a core [dispose] had to leave alone, once its event pump has
  /// stopped and no hook registration runs against it: an event isolate
  /// held in a read behind a busy core (an output that takes seconds to
  /// open) exits after the bound of [MpvSession.stop]. Asks again for about
  /// a minute, then leaves the core to the process exit.
  Future<void> _destroyOnceStopped() async {
    try {
      for (var tries = 0; tries < 30; tries++) {
        if (await _session.stop() &&
            await _session.settleHookAdds(const Duration(seconds: 2))) {
          await _session.terminateDestroy();
          for (final release in _entries.takeAll()) {
            await release();
          }
          return;
        }
      }
      debugLog(
        'mpv_audio_kit: event isolate never confirmed exit; the core is '
        'left to the process exit.',
      );
    } catch (e) {
      debugLog('mpv_audio_kit: late destroy of the core failed: $e');
    }
  }

  /// The last step of [dispose]: closes every reactive property and stream
  /// controller, so each stream of [stream] ends.
  Future<void> _closeStreams() async {
    // Close registry-backed reactives, then standalone ones, then
    // pure-event controllers. Order is for auditability: close() is
    // safe with attached listeners. None is awaited: a listener the app
    // keeps paused takes the done only when it resumes, so waiting would
    // hold dispose forever. An active listener gets it right after.
    unawaited(_registry.closeAll());
    unawaited(
      Future.wait<void>([
        _buffering.close(),
        _completed.close(),
        _playlist.close(),
        _loop.close(),
        _audioDevices.close(),
        _metadata.close(),
        _bufferingPercentage.close(),
        _demuxerCacheState.close(),
        _mediaSession.close(),
        // Reactives the player writes itself, outside the registry.
        _reactives.playWhenReady.close(),
        _reactives.audioDevice.close(),
        _reactives.audioEffects.close(),
        _reactives.tlsCaFile.close(),
        _reactives.spectrum.close(),
        // Set by the duration specs, outside their own cells.
        _reactives.durationEstimated.close(),
      ]),
    );
    // Drop the lazy spectrum bridges before closing their controllers:
    // a dispose with a live fft or pcm listener must not leave the pipeline's
    // poll loop armed against a torn-down handle.
    await _fftPipeSub?.cancel();
    _fftPipeSub = null;
    await _pcmPipeSub?.cancel();
    _pcmPipeSub = null;
    unawaited(
      Future.wait<void>([
        _endFileCtrl.close(),
        _errorCtrl.close(),
        _logCtrl.close(),
        _internalLogCtrl.close(),
        _hookCtrl.close(),
        _seekCompletedCtrl.close(),
        _coverArtCtrl.close(),
        _mediaSessionCommandsCtrl.close(),
        // Player-side DSP controllers: the pipelines close their own
        // internal streams, which completes the forwarding subscriptions
        // but does NOT propagate `done` to these: without an explicit
        // close, a consumer awaiting `stream.fft.first` (etc.) across a
        // dispose would hang forever.
        _fftCtrl.close(),
        _pcmStreamCtrl.close(),
        _waveformCtrl.close(),
        _loudnessMeterCtrl.close(),
        _loudnessScanCtrl.close(),
      ]),
    );
  }
}

/// The chain label of the first enabled [Ebur128Effect] in [effects] with
/// its `metadata` option on, the stage the live loudness meter reads;
/// `null` when none runs. A stage without metadata publishes nothing.
String? _meterLabel(List<AudioEffect> effects) {
  final labels = audioEffectLabels(effects);
  for (var i = 0; i < effects.length; i++) {
    final e = effects[i];
    if (e is Ebur128Effect && e.enabled && e.metadata) return labels[i];
  }
  return null;
}
