// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import '../internals/cover_art_extractor.dart';
import '../internals/player_finalizer.dart';
import '../internals/spectrum_pipeline.dart';
import '../models/cover_art.dart';
import '../internals/event_isolate.dart';
import '../events/mpv_exception.dart';
import 'audio_output_error.dart';
import 'lifecycle_transitions.dart';
import '../reactive/node_parsers.dart';
import '../internals/library_loader.dart';
import '../mpv_bindings.dart' hide MpvEndFileReason;
import '../internals/orphan_handle_tracker.dart';
import '../reactive/default_specs.dart';
import '../reactive/property_registry.dart';
import '../reactive/reactive_property.dart';
import '../internals/duration_seconds.dart';
import '../internals/uri_resolver.dart';

import '../types/sealed/track.dart';
import '../types/enums/loop.dart';
import '../models/media.dart';
import '../models/playlist.dart';
import '../types/sealed/channels.dart';
import '../models/device.dart';
import '../types/enums/format.dart';
import '../types/enums/cover.dart';
import '../types/enums/gapless.dart';
import '../types/enums/hook.dart';
import '../types/enums/log_level.dart';
import '../types/settings/audio_effects_settings.dart';
import '../types/settings/cache_settings.dart';
import '../types/settings/spectrum_settings.dart';
import '../events/mpv_log_entry.dart';
import '../events/mpv_hook_event.dart';
import '../events/mpv_player_error.dart';
import 'player_api.dart';
import 'player_configuration.dart';
import 'player_state.dart';
import '../types/settings/replay_gain_settings.dart';
import '../types/enums/spdif.dart';
import 'player_stream.dart';

export '../models/cover_art.dart';
export '../types/enums/loop.dart';
export '../models/media.dart';
export '../models/playlist.dart';
export '../types/sealed/channels.dart';
export '../models/device.dart';
export '../types/enums/format.dart';
export '../models/audio_params.dart';
export '../types/sealed/track.dart';
export '../types/enums/audio_effects.dart';
export '../types/settings/audio_effects_settings.dart';
export '../events/mpv_log_entry.dart';
export '../events/mpv_hook_event.dart';
export '../types/settings/spectrum_settings.dart';
export 'player_configuration.dart';
export 'player_state.dart';
export 'player_stream.dart';

part 'player_playback.part.dart';
part 'player_playlist.part.dart';
part 'player_audio.part.dart';
part 'player_network.part.dart';
part 'player_hooks.part.dart';

/// A high-performance audio player powered by libmpv.
///
/// Implements [PlayerApi] so test code can mock the player without
/// dragging in the FFI handle and event isolate
/// (`class MockPlayer extends Mock implements PlayerApi {}`).
class Player extends _PlayerBase
    with
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _NetworkModule,
        _HooksModule
    implements PlayerApi {
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
    try {
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
    } catch (_) {
      // Mid-loop failure: dispose the partially-resolved entries to
      // avoid leaking content:// file descriptors / asset cache files,
      // then rethrow so the caller observes the original error.
      for (final prior in resolved) {
        await prior.dispose?.call();
      }
      rethrow;
    }
    // Apply per-file headers only for the first item — it's the one
    // mpv loads synchronously on `loadfile replace`. Headers for
    // queued items (append) cannot be applied here without racing
    // mpv's playlist advance; per-track headers on a playlist need an
    // `on_load` hook (see [_HooksModule.registerHook]) that sets the
    // per-file option from the handler.
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
  /// properties (volume, pause, cache-*, replaygain*, ao, …), the
  /// resulting state mutation will *also* flow through the property
  /// observer on mpv's side, so `player.state` and `player.stream` will
  /// stay consistent — but expect a one-event-loop-tick delay between
  /// the call returning and the cached state catching up. Prefer the
  /// typed setters (`setVolume`, `setCache`, `setReplayGain`, …) when
  /// they exist, both for type-safety and for synchronous state update.
  ///
  /// `af` is reserved: the typed [AudioEffects] bundle owns it
  /// (including raw passthroughs via [AudioEffects.custom]), and a
  /// raw write would silently desync `state.audioEffects`. Use
  /// [setAudioEffects] / [updateAudioEffects] instead.
  ///
  /// Throws [StateError] if the player has been disposed,
  /// [ArgumentError] if [name] is reserved, or [MpvException] if mpv
  /// rejects the property write (unknown name, out-of-range value, etc.).
  Future<void> setRawProperty(String name, String value) async {
    _checkNotDisposed();
    if (name == 'af') {
      throw ArgumentError.value(
        name,
        'name',
        'Property `af` is owned by the typed AudioEffects bundle. '
            'Use Player.setAudioEffects / updateAudioEffects, and pass '
            'experimental or expression-based filters via '
            'AudioEffects.custom.',
      );
    }
    _prop(name, value);
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
    // Symmetric guard with `setRawProperty('af', ...)`: mpv exposes
    // `af` and `af-command` as commands that mutate the audio chain
    // incrementally — bypassing the typed `AudioEffects` bundle and
    // desynchronizing `state.audioEffects`. The bundle is the single
    // writer of mpv's `af` property; raw incremental mutation goes
    // through `AudioEffects.custom` instead.
    if (args.isNotEmpty && (args.first == 'af' || args.first == 'af-command')) {
      throw ArgumentError.value(
        args.first,
        'args[0]',
        'Command `${args.first}` is owned by the typed AudioEffects bundle. '
            'Use Player.setAudioEffects / updateAudioEffects, and pass '
            'experimental or expression-based filters via AudioEffects.custom.',
      );
    }
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
  // Bundled with [_lib] + [_handle] inside a single object so a
  // [Finalizer] can keep a reference and reach the lib even after the
  // player itself is GC'd.
  late final PlayerNativeResources _nativeResources;
  // Eagerly instantiated so `dispose()` is safe even when invoked
  // synchronously after construction — before `_eventIsolateReady`
  // resolves. The actual isolate spawn happens via `start()` driven
  // by `_eventIsolateReady` below.
  final MpvEventIsolate _eventIsolate = MpvEventIsolate();
  late final Future<void> _eventIsolateReady;
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
      ReactiveProperty<List<Device>>(const [Device(name: 'auto', description: 'Auto')]);
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
  // Log stream from the Dart layer itself — JSON parse warnings, hook
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
  // UI clear / reset on every track change without having to compare
  // against a separate file-transition signal.
  final StreamController<CoverArt?> _coverArtCtrl =
      StreamController<CoverArt?>.broadcast();

  // Real-time FFT + raw PCM pipeline. Lazy: the poll loop starts only
  // when something subscribes to `stream.spectrum` or `stream.pcm`.
  late final SpectrumPipeline _spectrumPipeline;

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

    _spectrumPipeline = SpectrumPipeline(lib: _lib, handle: _handle);

    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      loop: _loop,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      audioEffects: _reactives.audioEffects,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArt: _coverArtCtrl.stream,
      spectrum: _spectrumPipeline.spectrumStream,
      pcm: _spectrumPipeline.pcmStream,
    );

    _eventIsolateReady = _eventIsolate.start(
      _handle,
      libraryPath: MpvAudioKit.libraryPath,
      onEvent: _handleEvent,
    );
    OrphanHandleTracker.instance.add(_handle);

    // Safety net for consumers that drop a Player without disposing.
    // The finalizer runs on GC of `this`; if dispose() ran first the
    // resources are flagged and the finalizer is a no-op.
    _nativeResources = PlayerNativeResources(_lib, _handle);
    playerFinalizer.attach(this, _nativeResources, detach: this);
  }

  // --- Core Lifecycle ---

  void _applyPreInitOptions() {
    // Audio-only build: no video / subtitle track selection. Suppresses
    // mpv warnings about missing MJPEG / libass decoders that would
    // otherwise fire on every file with embedded cover art or text
    // metadata streams. Cover-art bytes still flow through the
    // `embedded-cover-art-data` property, which reads at the demuxer
    // level before any decoder runs.
    _opt('vid', 'no');
    _opt('sid', 'no');
    _opt('vo', 'null');
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

    if (configuration.logLevel != LogLevel.off) {
      using((arena) {
        _lib.mpvRequestLogMessages(
            _handle,
            configuration.logLevel.mpvValue.toNativeUtf8(allocator: arena));
      });
    }
  }

  void _applyPostInitOptions() {
    _prop('volume', configuration.initialVolume.toStringAsFixed(1));
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
        final typedLevel = LogLevel.fromMpv(level);
        final entry =
            MpvLogEntry(prefix: prefix, level: typedLevel, text: text);
        _logCtrl.add(entry);
        if (typedLevel == LogLevel.error || typedLevel == LogLevel.fatal) {
          _errorCtrl.add(MpvLogError(
            prefix: prefix,
            level: typedLevel,
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
            level: LogLevel.warn,
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

  /// Test-only entry point that exercises the same dispatch pipeline as
  /// the real event isolate. Lets integration tests force a property
  /// transition (e.g. `audio-output-state == failed`) without depending
  /// on the host AO actually reaching that state.
  @visibleForTesting
  void debugDispatchProperty(String name, dynamic raw) =>
      _dispatchProperty(name, raw);

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

  /// Writes a property and throws [MpvException] on rejection.
  ///
  /// All typed setters (setVolume, setRate, setAudioEffects, …) flow
  /// through this method. Errors are surfaced rather than swallowed so
  /// the caller can react (out-of-range value, unknown name, malformed
  /// `af` chain after `AudioEffects.custom`, etc.). `_propRc` is the
  /// rc-returning variant for the few call sites that need to tolerate
  /// failures explicitly.
  void _prop(String name, String value) {
    final rc = _propRc(name, value);
    if (rc < 0) {
      throw MpvException(name: name, code: rc, message: _errorString(rc));
    }
  }

  int _propRc(String name, String value) {
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
        level: LogLevel.warn,
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
  ///
  /// mpv may return PROPERTY_UNAVAILABLE if no file is currently
  /// loading; in that case the per-file scope is unavailable and the
  /// headers are silently dropped (the consumer would have to register
  /// an `on_load` hook to attach them at the right point in the
  /// load lifecycle). Use [_propRc] here so the typed open() flow
  /// doesn't throw on the unavailable-property path.
  void _applyFileLocalHeaders(Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return;
    final joined = headers.entries.map((e) => '${e.key}: ${e.value}').join(',');
    _propRc('file-local-options/http-header-fields', joined);
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
    }
  }

  /// Rejects NaN / +Inf / -Inf before they reach `toStringAsFixed`,
  /// which would emit the literal `'NaN'` / `'Infinity'` and have mpv
  /// reject the property write at the FFI boundary. Catching it on the
  /// wrapper side gives the caller a precise [ArgumentError] naming the
  /// parameter, instead of an opaque [MpvException] from libmpv.
  void _checkFinite(double value, String paramName) {
    if (!value.isFinite) {
      throw ArgumentError.value(
          value, paramName, 'Expected a finite double (got NaN/Infinity)');
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
      _internalLog('Failed to parse playlist: $e', level: LogLevel.warn);
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
    final device = Device(name: name, description: description);
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
      _internalLog('Failed to parse audio devices: $e', level: LogLevel.warn);
    }
  }

  void _updateMetadataFromNode(dynamic raw) {
    try {
      final metadata = parseMetadataNode(raw);
      if (metadata == null) return;
      _updateField((s) => s.copyWith(metadata: metadata), _metadata, metadata);
    } catch (e) {
      _internalLog('Failed to parse metadata: $e', level: LogLevel.warn);
    }
  }

  void _updateBufferingPercentageFromNode(dynamic raw) {
    try {
      final pct = parseDemuxerCacheStateNode(raw, _state.cache.secs);
      _updateField((s) => s.copyWith(bufferingPercentage: pct),
          _bufferingPercentage, pct);
    } catch (e) {
      _internalLog('Failed to parse cache state: $e', level: LogLevel.warn);
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

  /// Internal log helper — emits on the library-side log channel
  /// ([PlayerStream.internalLog]), kept separate from mpv's engine log
  /// stream ([PlayerStream.log]).
  void _internalLog(String message, {LogLevel level = LogLevel.info}) =>
      _internalLogCtrl.add(
          MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message));

  void _extractEmbeddedCover() {
    if (_disposed) return;
    // Emit unconditionally — `null` signals "no cover on the new
    // file" so subscribers can clear stale artwork on track changes.
    final cover = CoverArtExtractor.capture(_lib, _handle);
    _state = _state.copyWith(coverArt: cover);
    _coverArtCtrl.add(cover);
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
    // Flag the resources so the finalizer (if it ever fires after a
    // late GC) skips the duplicate teardown, and detach the finalizer
    // so this `Player` instance no longer pins a strong reference from
    // the finalization queue.
    _nativeResources.disposed = true;
    playerFinalizer.detach(this);

    OrphanHandleTracker.instance.remove(_handle);
    await _spectrumPipeline.dispose();
    // Wait for isolate startup to complete before stopping it. Without
    // this await, calling `dispose()` synchronously after construction
    // (or before the start microtask drains) raced the spawn and could
    // call `stop()` on a half-initialized isolate.
    try {
      await _eventIsolateReady;
    } catch (_) {
      // If start() failed we still proceed with the rest of teardown.
    }
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
    ]);
    await Future.wait<void>([
      _endFileCtrl.close(),
      _errorCtrl.close(),
      _logCtrl.close(),
      _internalLogCtrl.close(),
      _hookCtrl.close(),
      _seekCompletedCtrl.close(),
      _coverArtCtrl.close(),
    ]);
  }
}
