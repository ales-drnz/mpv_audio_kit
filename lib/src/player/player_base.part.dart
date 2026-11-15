// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

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

  /// The effects chain mpv holds, against the list in the state.
  late final _EffectsChain _effects = _EffectsChain(this);

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

  final MediaCache _mediaCache = MediaCache();

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

  /// Every call to libmpv once the player runs, on top of [_session]. All
  /// of them ride the async client API (`mpv_*_async`): the main isolate
  /// never waits for the playloop. Most setters update the state once the
  /// reply confirms the write; the play-pause intent and the settings
  /// bundles ([CoreCalls.writeBundle]) update it before the write.
  late final CoreCalls _calls;

  // The mixins reach one another through their `on` clauses, and the
  // constructors of [Player] start the bring-up: the base declares none
  // of their members. These two stay, as they were before the mixins
  // declared their dependencies: they are part of the API surface that
  // tool/metrics checks line by line.

  /// See `_RawModule`: the raw property escape hatches of the public API.
  /// The player's own reads and writes go through [_readString] and
  /// [_calls] instead.
  Future<String?> getRawProperty(String name);
  Future<void> setRawProperty(String name, String value);

  /// Reads the mpv property [name] as a string for a call already past
  /// [_gate]: `null` when the read fails, also once dispose closed the
  /// session. Unlike the public `getRawProperty` it does not refuse a
  /// disposed player, so a call under way at dispose ends without effect,
  /// as its writes do, instead of throwing from the middle.
  Future<String?> _readString(String name) async {
    final (rc, value) = await _calls.get(name, MpvFormat.mpvFormatString);
    return rc < 0 ? null : value as String?;
  }

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

    // The bring-up starts in the constructors of [Player], right after
    // this one: see `_InitModule._start`.
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

  /// Set by `_InitModule._start`, which the constructors of [Player]
  /// call.
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

  /// The body of a typed setter: past the [_gate], writes [wire] to the
  /// mpv property [name], then, once mpv confirmed the write, folds
  /// [value] into [cell] and into the state through [fold] (see
  /// [_updateField]). A failed write throws [MpvCommandException] and
  /// changes nothing.
  Future<void> _write<T>(
    String name,
    String wire,
    ReactiveProperty<T> cell,
    T value,
    PlayerState Function(PlayerState) fold,
  ) async {
    await _gate();
    await _calls.prop(name, wire);
    _updateField(fold, cell, value);
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

  /// The teardown [dispose] runs once: see `_TeardownModule`.
  Future<void> _disposeImpl();

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
