// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';

import '../internals/cover_art_extractor.dart';
import '../models/cover_art_raw.dart';
import '../internals/event_isolate.dart';
import '../events/exceptions.dart';
import '../internals/audio_output_error.dart';
import '../internals/lifecycle_transitions.dart';
import '../reactive/node_parsers.dart';
import '../internals/library_loader.dart';
import '../mpv_bindings.dart' hide MpvEndFileReason;
import '../internals/orphan_handle_tracker.dart';
import '../reactive/default_specs.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../internals/duration_seconds.dart';
import '../internals/uri_resolver.dart';

import '../internals/audio_filter_chain.dart';
import '../types/sealed/track.dart';
import '../types/enums/loop.dart';
import '../models/media.dart';
import '../models/playlist.dart';
import '../types/sealed/channels.dart';
import '../models/device.dart';
import '../types/enums/format.dart';
import '../types/enums/display.dart';
import '../types/enums/cover.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hook.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/compressor_settings.dart';
import '../types/settings/equalizer_settings.dart';
import '../types/settings/loudness_settings.dart';
import '../events/mpv_log_entry.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_player_error.dart';
import '../types/settings/pitch_tempo_settings.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/enums/spdif.dart';
import 'player_stream.dart';

export '../models/cover_art_raw.dart';
export '../types/enums/loop.dart';
export '../models/media.dart';
export '../models/playlist.dart';
export '../types/sealed/channels.dart';
export '../models/device.dart';
export '../types/enums/format.dart';
export '../models/audio_params.dart';
export '../types/sealed/track.dart';
export '../types/settings/compressor_settings.dart';
export '../types/settings/equalizer_settings.dart';
export '../types/settings/loudness_settings.dart';
export '../events/mpv_log_entry.dart';
export '../events/mpv_hook_event.dart';
export '../types/settings/pitch_tempo_settings.dart';
export 'player_configuration.dart';
export 'player_state.dart';
export 'player_stream.dart';

part 'player_playback.part.dart';
part 'player_playlist.part.dart';
part 'player_audio.part.dart';
part 'player_network.part.dart';
part 'player_hooks.part.dart';

/// A high-performance audio player powered by libmpv.
class Player extends _PlayerBase
    with
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _NetworkModule,
        _HooksModule {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration});

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// `pause` is set as a global property before `loadfile` so the
  /// property observer always fires on the first-load transition
  /// (a per-file option can skip the `PROPERTY_CHANGE` emit).
  /// Rapid back-to-back `open()` calls don't race: `loadfile replace`
  /// aborts the previous load, so the last `(pause, loadfile)` pair wins.
  Future<void> open(Media media, {bool? play}) async {
    _checkNotDisposed();
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    final resolved = await resolveUri(media.uri);
    if (_disposed) {
      await resolved.dispose?.call();
      return;
    }
    _mediaCache[resolved.uri] = media;
    final shouldPlay = play ?? configuration.autoPlay;
    _applyFileLocalHeaders(media.httpHeaders);
    _prop('pause', shouldPlay ? 'no' : 'yes');
    _command(['loadfile', resolved.uri, 'replace']);
  }

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// Multi-media counterpart of [open]. [index] is clamped to
  /// `[0, medias.length - 1]`. When non-zero the first item is loaded
  /// briefly, then mpv jumps to the requested position.
  Future<void> openAll(List<Media> medias, {bool? play, int index = 0}) async {
    _checkNotDisposed();
    if (medias.isEmpty) {
      return;
    }
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    _mediaCache.clear();
    // Resolve once per media — content:// resolutions detach a JVM-side
    // FD, doing it twice would leak one FD per track.
    final resolved = <ResolvedUri>[];
    for (final m in medias) {
      _mediaCache[m.uri] = m;
      final r = await resolveUri(m.uri);
      if (_disposed) {
        await r.dispose?.call();
        for (final prior in resolved) {
          await prior.dispose?.call();
        }
        return;
      }
      _mediaCache[r.uri] = m;
      resolved.add(r);
    }
    // Apply per-file headers only for the first item — it's the one
    // mpv loads synchronously on `loadfile replace`. Headers for
    // queued items (append) cannot be applied here without racing
    // mpv's playlist advance; consumers needing per-track headers on
    // a playlist should register an `on_load` hook (see
    // [_HooksModule.registerHook]) and set the per-file option from
    // the hook handler.
    _applyFileLocalHeaders(medias.first.httpHeaders);
    _prop('pause', shouldPlay ? 'no' : 'yes');
    _command(['loadfile', resolved.first.uri, 'replace']);
    for (var i = 1; i < medias.length; i++) {
      _command(['loadfile', resolved[i].uri, 'append']);
    }
    if (clampedIndex > 0) {
      _command(['playlist-play-index', clampedIndex.toString()]);
    }
  }

  /// Reads any mpv property as a string.
  ///
  /// **Escape hatch for properties not surfaced by the typed API.** For
  /// observed properties (`volume`, `pause`, `cache-secs`, …), prefer
  /// `player.state.<field>` — the cached value is updated on every
  /// property-change event from mpv and avoids an FFI round-trip.
  ///
  /// Returns `null` if the property doesn't exist or the FFI call
  /// fails. Throws [StateError] if the player has been disposed.
  Future<String?> getRawProperty(String name) async {
    _checkNotDisposed();
    return using((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final ptr = _lib.mpvGetPropertyString(_handle, n);
      if (ptr == nullptr) {
        return null;
      }
      final s = ptr.cast<Utf8>().toDartString();
      _lib.mpvFree(ptr.cast());
      return s;
    });
  }

  /// Writes any mpv property as a string.
  ///
  /// **Warning:** this is an escape hatch for properties the typed API
  /// doesn't yet cover. If [name] is one of the registry-observed
  /// properties (volume, pause, cache-*, replaygain*, ao, af, …), the
  /// resulting state mutation will *also* flow through the property
  /// observer on mpv's side, so `player.state` and `player.stream` will
  /// stay consistent — but expect a one-event-loop-tick delay between
  /// the call returning and the cached state catching up. Prefer the
  /// typed setters (`setVolume`, `setCache`, `setReplayGain`, …) when
  /// they exist, both for type-safety and for synchronous state update.
  ///
  /// Throws [StateError] if the player has been disposed, or
  /// [MpvException] if mpv rejects the property write (unknown name,
  /// out-of-range value, etc.).
  Future<void> setRawProperty(String name, String value) async {
    _checkNotDisposed();
    final rc = _prop(name, value);
    if (rc < 0) {
      throw MpvException(
        name: name,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  /// Sends a raw mpv command.
  ///
  /// **Escape hatch.** Same caveats as [setRawProperty]: prefer the
  /// typed playback / playlist methods (`play`, `pause`, `seek`,
  /// `add`, `jump`, …) when they cover your use case.
  ///
  /// Throws [StateError] if the player has been disposed, or
  /// [MpvException] if mpv rejects the command (unknown command,
  /// invalid argument, etc.). A successful return guarantees mpv
  /// accepted the command; the actual side-effect on playback state
  /// is observed asynchronously via [Player.stream].
  Future<void> sendRawCommand(List<String> args) async {
    _checkNotDisposed();
    final rc = _command(args);
    if (rc < 0) {
      throw MpvException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  @override
  Future<void> dispose() async {
    _cancelHookTimers();
    await super.dispose();
  }
}

/// Base class for [Player] containing shared state and native communication
/// logic.
///
/// Owns:
/// - the FFI handle and event-isolate plumbing,
/// - the [PropertyRegistry] for the ~60 simple mpv properties,
/// - the small set of standalone [ReactiveProperty]s and [StreamController]s
///   that back state fields not directly mirrored by an mpv property
///   (lifecycle: `buffering`/`completed`; complex JSON parses: `playlist`,
///   `metadata`, `audioDevices`, `bufferingPercentage`; pure events: log,
///   error, hook, end-of-file, seek-completed).
abstract class _PlayerBase {
  final PlayerConfiguration configuration;

  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  late final MpvEventIsolate _eventIsolate;
  StreamSubscription<MpvIsolateEvent>? _eventSub;
  bool _disposed = false;

  // `_activeHookIds` is authoritative for [Player.continueHook]: mpv's
  // behaviour on stale ids is undefined across versions, so duplicate
  // continues are rejected here before they reach FFI.
  // `_registeredHookNames` collapses duplicate registrations per name —
  // mpv allows multiples, but its shutdown path can stall when several
  // events for the same hook are still in flight at quit time.
  final _hookTimeouts = <String, Duration>{};
  final _hookTimers = <int, Timer>{};
  final _activeHookIds = <int>{};
  final _registeredHookNames = <String>{};

  PlayerState _state = const PlayerState();
  final Map<String, Media> _mediaCache = {};

  // ── Property registry (the bulk of state — one spec per mpv property) ──
  late final DefaultPropertyReactives _reactives;
  late final PropertyRegistry _registry;

  // ── Standalone reactive properties (no 1:1 mpv property backing) ───────
  // Lifecycle flags driven by file-boundary events, not by a single property.
  final ReactiveProperty<bool> _buffering = ReactiveProperty<bool>(false);
  final ReactiveProperty<bool> _completed = ReactiveProperty<bool>(false);
  // Derived from JSON properties that need access to player-side context.
  final ReactiveProperty<Playlist> _playlist =
      ReactiveProperty<Playlist>(Playlist.empty);
  final ReactiveProperty<Loop> _loop = ReactiveProperty<Loop>(Loop.off);
  final ReactiveProperty<List<Device>> _audioDevices =
      ReactiveProperty<List<Device>>(const [Device('auto', 'Auto')]);
  final ReactiveProperty<Map<String, String>> _metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> _bufferingPercentage =
      ReactiveProperty<double>(0.0);

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> _endFileCtrl =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<MpvPlayerError> _errorCtrl =
      StreamController<MpvPlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec / demux / ao / …).
  final StreamController<MpvLogEntry> _logCtrl =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart wrapper itself — JSON parse warnings, hook
  // timeouts, etc. Kept disjoint from `_logCtrl` so consumers can filter
  // wrapper-side noise from genuine engine messages without inspecting
  // the prefix.
  final StreamController<MpvLogEntry> _internalLogCtrl =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> _hookCtrl =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> _seekCompletedCtrl =
      StreamController<void>.broadcast();
  // Nullable payload: each file-loaded transition emits exactly once,
  // with `null` when the new file has no embedded cover. This lets
  // consumers clear / reset their UI on every track change without
  // having to compare against a separate file-transition signal.
  final StreamController<CoverArtRaw?> _coverArtRawCtrl =
      StreamController<CoverArtRaw?>.broadcast();

  PlayerState get state => _state;
  late final PlayerStream stream;

  _PlayerBase({this.configuration = const PlayerConfiguration()}) {
    _lib = MpvLibrary.open(MpvAudioKit.libraryPath);
    _handle = _lib.mpvCreate();
    if (_handle == nullptr) {
      throw StateError('mpv_create() returned NULL');
    }

    _applyPreInitOptions();
    final rc = _lib.mpvInitialize(_handle);
    if (rc < 0) {
      _lib.mpvTerminateDestroy(_handle);
      throw StateError('mpv_initialize() failed: ${_errorString(rc)}');
    }
    _applyPostInitOptions();

    _reactives = DefaultPropertyReactives();
    _registry = PropertyRegistry()
      ..registerAll(buildDefaultSpecs(
        _reactives,
        onIdleActive: (idle) {
          if (idle) _updateLifecycle(playing: false, buffering: false);
        },
        onAudioOutputState: (state) {
          final err = buildAudioOutputError(state);
          if (err != null) _errorCtrl.add(err);
        },
      ));
    _registry.observeAll(_lib, _handle);

    // Out-of-registry observers. NODE for structured data (avoids a
    // string-encode/JSON-parse round trip); STRING for `loop-*` (flag-
    // like values: `no` / `inf` / a number) and `audio-device` (whose
    // description is cross-referenced from `audio-device-list`).
    _observe('playlist', MpvFormat.mpvFormatNode);
    _observe('audio-device-list', MpvFormat.mpvFormatNode);
    _observe('audio-device', MpvFormat.mpvFormatString);
    _observe('metadata', MpvFormat.mpvFormatNode);
    _observe('demuxer-cache-state', MpvFormat.mpvFormatNode);
    _observe('loop-file', MpvFormat.mpvFormatString);
    _observe('loop-playlist', MpvFormat.mpvFormatString);

    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      loop: _loop,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      equalizer: _reactives.equalizer,
      compressor: _reactives.compressor,
      loudness: _reactives.loudness,
      pitchTempo: _reactives.pitchTempo,
      customAudioFilters: _reactives.customAudioFilters,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArtRaw: _coverArtRawCtrl.stream,
    );

    _startEventIsolate();
    OrphanHandleTracker.instance.add(_handle);
  }

  // --- Core Lifecycle ---

  void _applyPreInitOptions() {
    _opt('vid', 'auto');
    _opt('vo', 'null');
    // Cover-art handling: prefer the embedded picture, never scan the
    // surrounding directory, and hold the still frame alive so the
    // wrapper can extract it via `embedded-cover-art-data` after load.
    _opt('audio-display', 'embedded-first');
    _opt('cover-art-auto', 'no');
    _opt('image-display-duration', 'inf');

    _opt('keep-open', 'yes');
    _opt('idle', 'yes');

    // Disable mpv's built-in scripts and key bindings — irrelevant for a
    // library embedded in a host app.
    _opt('osc', 'no');
    _opt('ytdl', 'no');
    _opt('load-stats-overlay', 'no');
    _opt('load-console', 'no');
    _opt('load-commands', 'no');
    _opt('load-auto-profiles', 'no');
    _opt('load-select', 'no');
    _opt('load-context-menu', 'no');
    _opt('load-positioning', 'no');
    _opt('load-scripts', 'no');
    _opt('input-builtin-bindings', 'no');
    _opt('audio-client-name', 'mpv_audio_kit');

    // Wrapper diverges from mpv's permissive `tls-verify=no` default for
    // security. Consumers that need self-signed cert support can opt out
    // via `setTlsVerify(false)` post-construction.
    _opt('tls-verify', 'yes');

    if (configuration.logLevel != 'no') {
      using((arena) {
        _lib.mpvRequestLogMessages(
            _handle, configuration.logLevel.toNativeUtf8(allocator: arena));
      });
    }
  }

  void _applyPostInitOptions() {
    _prop('volume', configuration.initialVolume.toStringAsFixed(1));
  }

  Future<void> _startEventIsolate() async {
    _eventIsolate = MpvEventIsolate();
    await _eventIsolate.start(_handle, libraryPath: MpvAudioKit.libraryPath);
    _eventSub = _eventIsolate.events.listen(_handleEvent);
  }

  void _handleEvent(MpvIsolateEvent event) {
    // Single fence for every controller add() in this method — dispose()
    // flips `_disposed` before awaiting `_eventSub.cancel()`, so passing
    // this check guarantees every downstream add() lands on an open
    // controller without per-call isClosed checks.
    if (_disposed) return;
    switch (event) {
      case MpvEventStartFile():
        _updateLifecycle(buffering: true, completed: false);
      case MpvEventFileLoaded():
        // `state.playing` is driven by the `core-idle` observer; here we
        // only clear buffering/completed and trigger cover-art capture.
        _updateLifecycle(buffering: false, completed: false);
        _pollPosition();
        _extractEmbeddedCover();
      case MpvEventPlaybackSeek():
        // No-op: mutating position here would flash 0 before the
        // post-restart poll lands.
        break;
      case MpvEventPlaybackRestart():
        _pollPosition();
        _seekCompletedCtrl.add(null);
      case MpvEndFileEvent(:final reason, :final error):
        final typedReason = MpvEndFileReason.fromValue(reason);
        _endFileCtrl.add(MpvFileEndedEvent(
          reason: typedReason,
          error: error,
        ));
        if (error < 0) {
          _errorCtrl.add(MpvEndFileError(
            reason: typedReason,
            code: error,
            message: _errorString(error),
          ));
        }
        final isEof = reason == MpvEndFileReason.eof.value;
        _updateLifecycle(playing: false, buffering: false, completed: isEof);
      case MpvEventShutdown():
        _updateLifecycle(playing: false, buffering: false);
      case MpvEventPropertyDouble(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyInt(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyString(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventPropertyNode(:final name, :final value):
        _dispatchProperty(name, value);
      case MpvEventLog(:final prefix, :final level, :final text):
        final entry = MpvLogEntry(prefix: prefix, level: level, text: text);
        _logCtrl.add(entry);
        if (level == 'error' || level == 'fatal') {
          _errorCtrl.add(MpvLogError(
            prefix: prefix,
            level: level,
            text: text,
          ));
        }
      case MpvEventHookFired(:final id, :final name):
        final hook = Hook.fromMpv(name);
        if (hook == null) {
          // Unknown hook name — likely a future mpv build added a new
          // phase. Auto-continue so mpv never stalls, log it on the
          // internal channel for diagnostics.
          _internalLog(
            'Received unknown hook "$name" (id=$id) — auto-continuing. '
            'Update the Hook enum if mpv has added a new lifecycle phase.',
            level: 'warn',
          );
          _lib.mpvHookContinue(_handle, id);
          return;
        }
        _activeHookIds.add(id);
        final timeout = _hookTimeouts[name];
        if (timeout != null) _startHookTimeout(id, name, timeout);
        _hookCtrl.add(MpvHookEvent(id, hook));
    }
  }

  /// Routes a property-change to the registry first, then falls back to the
  /// custom handlers for properties whose update logic doesn't fit a simple
  /// (parser, reducer) pair (JSON parsing with player-side context, derived
  /// fields aggregating multiple mpv properties, etc.).
  void _dispatchProperty(String name, dynamic raw) {
    final next = _registry.dispatch(name, raw, _state);
    if (next != null) {
      _state = next;
      return;
    }
    if (_registry.specFor(name) != null) {
      // Spec exists but value was deduplicated — nothing to do.
      return;
    }
    // Custom out-of-registry handlers for the few properties whose update
    // logic touches more than `(parse → reduce)` (player-side context like
    // `_mediaCache`, `_state.playlist`, `_state.cache.secs`, or the
    // two-property aggregation behind `loop`).
    switch (name) {
      case 'loop-file':
      case 'loop-playlist':
        _updateLoopFromMpv(name, raw as String);
      case 'playlist':
        _updatePlaylistFromNode(raw);
      case 'audio-device':
        _updateActiveAudioDevice(raw as String);
      case 'audio-device-list':
        _updateDevicesFromNode(raw);
      case 'metadata':
        _updateMetadataFromNode(raw);
      case 'demuxer-cache-state':
        _updateBufferingPercentageFromNode(raw);
    }
  }

  // --- Low Level Native Bridge ---

  /// Returns the mpv error code (negative on failure, 0 on success).
  /// Internal setters discard it; the public escape hatches surface it
  /// via [MpvException].
  int _opt(String name, String value) {
    return using((arena) => _lib.mpvSetOptionString(
        _handle,
        name.toNativeUtf8(allocator: arena),
        value.toNativeUtf8(allocator: arena)));
  }

  int _prop(String name, String value) {
    return using((arena) => _lib.mpvSetPropertyString(
        _handle,
        name.toNativeUtf8(allocator: arena),
        value.toNativeUtf8(allocator: arena)));
  }

  int _command(List<String> args) {
    return using((arena) {
      final arr = arena<Pointer<Utf8>>(args.length + 1);
      for (var i = 0; i < args.length; i++) {
        arr[i] = args[i].toNativeUtf8(allocator: arena);
      }
      arr[args.length] = nullptr;
      return _lib.mpvCommand(_handle, arr);
    });
  }

  // Reply IDs for hand-rolled observers, starting past the registry's
  // reserved range so the two dispatch paths are distinguishable in
  // `mpv -v` logs. Diagnostic-only — mpv dispatches by name on receive.
  int _customReplyId = PropertyRegistry.registryReplyIdMax + 1;
  void _observe(String name, int format) {
    using((arena) => _lib.mpvObserveProperty(_handle, _customReplyId++,
        name.toNativeUtf8(allocator: arena), format));
  }

  String _errorString(int code) {
    final p = _lib.mpvErrorString(code);
    return p == nullptr ? 'error $code' : p.cast<Utf8>().toDartString();
  }

  void _startHookTimeout(int id, String name, Duration timeout) {
    _hookTimers[id] = Timer(timeout, () {
      _hookTimers.remove(id);
      // The active-id set is the source of truth: if a manual
      // continueHook beat us to it, the id is gone and we skip the
      // redundant FFI call.
      if (!_activeHookIds.remove(id)) return;
      _internalLog(
        'Hook "$name" (id=$id) timed out after ${timeout.inSeconds}s — '
        'auto-continuing to unblock mpv',
        level: 'warn',
      );
      if (!_disposed) _lib.mpvHookContinue(_handle, id);
    });
  }

  void _cancelHookTimers() {
    for (final timer in _hookTimers.values) {
      timer.cancel();
    }
    _hookTimers.clear();
    // Continue every still-active hook on mpv's side BEFORE we drop
    // them from the active set. Without this, mpv blocks on the
    // pending hooks during its shutdown path: `dispose()` issues
    // `quit`, mpv tries to drain the hook queue first, and never
    // fires MPV_EVENT_SHUTDOWN — so the event isolate never exits.
    // `_cancelHookTimers` is called from dispose BEFORE `_disposed`
    // is flipped, so the handle is still valid here.
    for (final id in _activeHookIds) {
      _lib.mpvHookContinue(_handle, id);
    }
    _activeHookIds.clear();
  }

  /// Sets `file-local-options/http-header-fields` for the next
  /// `loadfile`. mpv resets the option once the loaded file stops
  /// playing, so the headers do NOT leak to subsequent loads.
  /// No-op when [headers] is null or empty.
  void _applyFileLocalHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return;
    final joined = headers.entries.map((e) => '${e.key}: ${e.value}').join(',');
    _prop('file-local-options/http-header-fields', joined);
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
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

  /// Updates the lifecycle triple (playing/buffering/completed) and
  /// emits per-reactive only for fields that actually changed. Used
  /// for compound transitions (start-file, file-loaded, end-file,
  /// shutdown, idle-active). The pure diff lives in [computeLifecycle].
  void _updateLifecycle({bool? playing, bool? buffering, bool? completed}) {
    final result = computeLifecycle(
      prev: _state,
      playing: playing,
      buffering: buffering,
      completed: completed,
    );
    _state = result.newState;
    if (result.playingDidChange) _reactives.playing.update(playing!);
    if (result.bufferingDidChange) _buffering.update(buffering!);
    if (result.completedDidChange) _completed.update(completed!);
  }

  // --- Custom property handlers (JSON / derived) ---

  void _updateLoopFromMpv(String name, String value) {
    final next = deriveLoop(name, value, _state.loop);
    if (next == null) return;
    _updateField(
      (s) => s.copyWith(loop: next),
      _loop,
      next,
    );
  }

  void _updatePlaylistFromNode(dynamic raw) {
    try {
      final playlist = parsePlaylistNode(
        raw: raw,
        mediaCache: _mediaCache,
        previous: _state.playlist,
      );
      _updateField((s) => s.copyWith(playlist: playlist), _playlist, playlist);
    } catch (e) {
      _internalLog('Failed to parse playlist: $e', level: 'warn');
    }
  }

  void _updateActiveAudioDevice(String name) {
    // mpv only echoes the device name back on `audio-device`. Recover
    // the proper description by looking it up in the parsed
    // `audio-device-list` (state.audioDevices). Falls back to the name
    // on cache miss — typical at boot, before the list arrives.
    final list = _state.audioDevices;
    String description = name;
    for (final d in list) {
      if (d.name == name) {
        description = d.description;
        break;
      }
    }
    final device = Device(name, description);
    _updateField(
      (s) => s.copyWith(audioDevice: device),
      _reactives.audioDevice,
      device,
    );
  }

  void _updateDevicesFromNode(dynamic raw) {
    try {
      final devices = parseDeviceListNode(raw);
      _updateField(
          (s) => s.copyWith(audioDevices: devices), _audioDevices, devices);
    } catch (e) {
      _internalLog('Failed to parse audio devices: $e', level: 'warn');
    }
  }

  void _updateMetadataFromNode(dynamic raw) {
    try {
      final metadata = parseMetadataNode(raw);
      if (metadata == null) return;
      _updateField((s) => s.copyWith(metadata: metadata), _metadata, metadata);
    } catch (e) {
      _internalLog('Failed to parse metadata: $e', level: 'warn');
    }
  }

  void _updateBufferingPercentageFromNode(dynamic raw) {
    try {
      final pct = parseDemuxerCacheStateNode(raw, _state.cache.secs);
      _updateField((s) => s.copyWith(bufferingPercentage: pct),
          _bufferingPercentage, pct);
    } catch (e) {
      _internalLog('Failed to parse cache state: $e', level: 'warn');
    }
  }

  // --- Misc helpers ---

  void _pollPosition() {
    if (_disposed) return;
    using((arena) {
      final n = 'time-pos'.toNativeUtf8(allocator: arena);
      final buf = arena<Double>();
      final rc = _lib.mpvGetProperty(
          _handle, n, MpvFormat.mpvFormatDouble, buf.cast());
      if (rc == MpvError.mpvErrorSuccess) {
        final pos = Duration(microseconds: (buf.value * 1e6).round());
        _updateField(
            (s) => s.copyWith(position: pos), _reactives.position, pos);
      }
    });
  }

  /// Internal log helper — emits on the wrapper-side log channel
  /// ([Player.stream.internalLog]), kept separate from mpv's engine log
  /// stream ([Player.stream.log]).
  void _internalLog(String message, {String level = 'info'}) => _internalLogCtrl
      .add(MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message));

  void _extractEmbeddedCover() {
    if (_disposed) return;
    // Emit unconditionally — `null` signals "no cover on the new
    // file" so consumers can clear stale artwork on track changes.
    _coverArtRawCtrl.add(CoverArtExtractor.capture(_lib, _handle));
  }

  /// Tears down the player.
  ///
  /// The teardown order is load-bearing. The sequence is:
  ///
  /// 1. **Flip `_disposed`** so any subsequent setter / public-API call
  ///    fails fast via `_checkNotDisposed()`.
  /// 2. **Drop the [OrphanHandleTracker] entry** so a hot-restart that
  ///    fires before the destroy completes doesn't try to clean up a
  ///    handle we're already cleaning up.
  /// 3. **Await `_eventSub.cancel()`** so no further `_handleEvent`
  ///    invocations land after this point.
  /// 4. **Send the `quit` command** to mpv. mpv processes it
  ///    asynchronously and fires `MPV_EVENT_SHUTDOWN` inside its own
  ///    event queue, which unblocks the isolate's `mpv_wait_event`
  ///    on the next iteration.
  /// 5. **Await `_eventIsolate.stop()`**: waits for the isolate to
  ///    actually exit (the `quit`-driven `MPV_EVENT_SHUTDOWN` lets the
  ///    run-loop unwind naturally).
  /// 6. **`mpvTerminateDestroy(_handle)`** AFTER the isolate is gone.
  ///    Calling destroy while the isolate is still inside
  ///    `mpv_wait_event` would race the event-loop thread and crash
  ///    libmpv when the handle is freed mid-syscall.
  /// 7. **Close all reactive properties + controllers**. Order within
  ///    this group does not matter for correctness (they tolerate
  ///    `close()` while a listener is attached); grouping by ownership
  ///    is for auditability.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    OrphanHandleTracker.instance.remove(_handle);
    await _eventSub?.cancel();
    // Cooperative quit: mpv fires MPV_EVENT_SHUTDOWN, the isolate's
    // mpv_wait_event returns, and the loop unwinds naturally. Calling
    // mpv_terminate_destroy here would race the isolate and crash
    // libmpv when the handle is freed mid-syscall.
    _command(['quit']);
    await _eventIsolate.stop();
    _lib.mpvTerminateDestroy(_handle);

    // Close registry-backed reactives, then standalone ones, then
    // pure-event controllers. Order is for auditability — close() is
    // safe with attached listeners.
    await _registry.closeAll();
    await Future.wait<void>([
      _buffering.close(),
      _completed.close(),
      _playlist.close(),
      _loop.close(),
      _audioDevices.close(),
      _metadata.close(),
      _bufferingPercentage.close(),
      // The four DSP config reactives are owned by the typed setters
      // (no mpv property observer drives them), so the registry's
      // closeAll() does not see them.
      _reactives.equalizer.close(),
      _reactives.compressor.close(),
      _reactives.loudness.close(),
      _reactives.pitchTempo.close(),
    ]);
    await Future.wait<void>([
      _endFileCtrl.close(),
      _errorCtrl.close(),
      _logCtrl.close(),
      _internalLogCtrl.close(),
      _hookCtrl.close(),
      _seekCompletedCtrl.close(),
      _coverArtRawCtrl.close(),
    ]);
  }
}
