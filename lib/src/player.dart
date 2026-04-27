// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/utils/native_reference_holder.dart';

import 'cover/cover_art_extractor.dart';
import 'cover/cover_art_processor.dart';
import 'cover/cover_art_raw.dart';
import 'event_isolate.dart';
import 'internal/json_parsers.dart';
import 'internal/lifecycle_transitions.dart';
import 'library_loader.dart';
import 'mpv_bindings.dart' hide MpvEndFileReason;
import 'reactive/default_specs.dart';
import 'reactive/property_registry.dart';
import 'reactive/reactive_property.dart';
import 'utils/android_helper.dart';
import 'utils/duration_seconds.dart';

import 'models/media.dart';
import 'models/playlist.dart';
import 'models/audio_device.dart';
import 'models/audio_filter.dart';
import 'models/mpv_log_entry.dart';
import 'models/mpv_hook_event.dart';
import 'models/mpv_player_error.dart';
import 'models/player_configuration.dart';
import 'models/player_state.dart';
import 'player_stream.dart';

export 'cover/cover_art_raw.dart';
export 'models/media.dart';
export 'models/playlist.dart';
export 'models/audio_device.dart';
export 'models/audio_filter.dart';
export 'models/audio_params.dart';
export 'models/mpv_log_entry.dart';
export 'models/mpv_hook_event.dart';
export 'models/player_configuration.dart';
export 'models/player_state.dart';
export 'player_stream.dart';

part 'player/player_playback.part.dart';
part 'player/player_playlist.part.dart';
part 'player/player_audio.part.dart';
part 'player/player_network.part.dart';
part 'player/player_hooks.part.dart';

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
  /// The play/pause decision is committed to mpv's global `pause` property
  /// BEFORE the `loadfile` command. mpv processes commands in arrival order
  /// on a single thread, so rapid consecutive calls
  /// (e.g. `open(A, play:true)` followed immediately by `open(B, play:false)`)
  /// cannot race: each `open()` issues a `(set pause, loadfile replace)`
  /// pair atomically, and the *last* pair wins because `replace` aborts any
  /// in-flight load. Setting `pause` as a global property (rather than as
  /// a `loadfile` per-file option) also guarantees the property observer
  /// fires — the file-local-option route can silently skip the
  /// `PROPERTY_CHANGE` emission, leaving `state.playing` stale on the very
  /// first `open()`.
  Future<void> open(Media media, {bool? play}) async {
    _checkNotDisposed();
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    if (media.httpHeaders != null) {
      final headers = media.httpHeaders!.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(',');
      _opt('http-header-fields', headers);
    }
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
    if (_disposed) return;
    _mediaCache[normalizedUri] = media;
    final shouldPlay = play ?? configuration.autoPlay;
    _prop('pause', shouldPlay ? 'no' : 'yes');
    _command(['loadfile', normalizedUri, 'replace']);
  }

  /// Opens a list of [Media] items as the new playlist, optionally starting at [index].
  ///
  /// If [index] is greater than zero, the player immediately jumps to that
  /// position after loading the playlist (the first item is loaded briefly then
  /// replaced — this is imperceptible and is the standard mpv approach).
  ///
  /// [index] is clamped to `medias.length - 1`; passing an out-of-range value
  /// silently falls back to the last entry rather than no-oping like raw mpv.
  ///
  /// As with [open], `pause` is committed globally before `loadfile` so
  /// the property observer drives `state.playing`.
  Future<void> openPlaylist(List<Media> medias,
      {bool? play, int index = 0}) async {
    _checkNotDisposed();
    if (medias.isEmpty) {
      return;
    }
    final clampedIndex = index.clamp(0, medias.length - 1);
    final shouldPlay = play ?? configuration.autoPlay;
    _mediaCache.clear();
    for (final m in medias) {
      _mediaCache[m.uri] = m;
      final normalizedUri = await AndroidHelper.normalizeUri(m.uri);
      if (_disposed) return;
      _mediaCache[normalizedUri] = m;
    }
    final firstNormalizedUri =
        await AndroidHelper.normalizeUri(medias.first.uri);
    if (_disposed) return;
    _prop('pause', shouldPlay ? 'no' : 'yes');
    _command(['loadfile', firstNormalizedUri, 'replace']);
    for (final m in medias.skip(1)) {
      final normalizedUri = await AndroidHelper.normalizeUri(m.uri);
      if (_disposed) return;
      _command(['loadfile', normalizedUri, 'append']);
    }
    if (clampedIndex > 0) {
      _command(['playlist-play-index', clampedIndex.toString()]);
    }
  }

  /// Manually appends a log entry to the wrapper's *internal* log stream
  /// ([PlayerStream.internalLog]) — useful for tagging consumer-side
  /// events (e.g. "user pressed retry") into the same stream where
  /// the wrapper itself emits parse warnings and hook timeouts.
  ///
  /// Renamed from `log()` to `appendLog()` in 0.1.0 to disambiguate
  /// from the engine-side log subscription at [PlayerStream.log] —
  /// `player.log` (inject) and `player.stream.log` (subscribe) used
  /// the same verb for opposite roles, which made docstrings ambiguous.
  void appendLog(String message, {String level = 'info'}) {
    _internalLogCtrl.add(
        MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message));
  }

  /// Reads any mpv property as a string.
  ///
  /// **Escape hatch for properties not surfaced by the typed API.** For
  /// observed properties (`volume`, `pause`, `cache-secs`, …), prefer
  /// `player.state.<field>` — the cached value is updated on every
  /// property-change event from mpv and avoids an FFI round-trip.
  String? getRawProperty(String name) {
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
  void setRawProperty(String name, String value) {
    _checkNotDisposed();
    _prop(name, value);
  }

  /// Sends a raw mpv command.
  ///
  /// **Escape hatch.** Same caveats as [setRawProperty]: prefer the
  /// typed playback / playlist methods (`play`, `pause`, `seek`,
  /// `add`, `jump`, …) when they cover your use case.
  void sendRawCommand(List<String> args) {
    _checkNotDisposed();
    _command(args);
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

  // Hook timeout state — lives here because _handleEvent dispatches hooks.
  final _hookTimeouts = <String, Duration>{};
  final _hookTimers = <int, Timer>{};

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
      ReactiveProperty<Playlist>(const Playlist.empty());
  final ReactiveProperty<PlaylistMode> _playlistMode =
      ReactiveProperty<PlaylistMode>(PlaylistMode.none);
  final ReactiveProperty<List<AudioDevice>> _audioDevices =
      ReactiveProperty<List<AudioDevice>>(
          const [AudioDevice('auto', 'Auto')]);
  final ReactiveProperty<Map<String, String>> _metadata =
      ReactiveProperty<Map<String, String>>(const <String, String>{});
  final ReactiveProperty<double> _bufferingPercentage =
      ReactiveProperty<double>(0.0);
  // User-driven (no observed mpv property).
  final ReactiveProperty<List<double>> _equalizerGains =
      ReactiveProperty<List<double>>(
          const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]);

  // ── Pure event streams (no current value) ───────────────────────────────
  final StreamController<MpvFileEndedEvent> _endFileCtrl =
      StreamController<MpvFileEndedEvent>.broadcast();
  final StreamController<MpvPlayerError> _errorCtrl =
      StreamController<MpvPlayerError>.broadcast();
  // Log stream from the mpv engine itself (codec / demux / ao / …).
  final StreamController<MpvLogEntry> _logCtrl =
      StreamController<MpvLogEntry>.broadcast();
  // Log stream from the Dart wrapper itself — JSON parse warnings, hook
  // timeouts, manual `Player.log(...)` injections. Split from `_logCtrl`
  // in 0.1.0 so consumers can filter wrapper-side noise from genuine
  // engine messages without inspecting the prefix.
  final StreamController<MpvLogEntry> _internalLogCtrl =
      StreamController<MpvLogEntry>.broadcast();
  final StreamController<MpvHookEvent> _hookCtrl =
      StreamController<MpvHookEvent>.broadcast();
  final StreamController<void> _seekCompletedCtrl =
      StreamController<void>.broadcast();
  final StreamController<CoverArtRaw> _coverArtRawCtrl =
      StreamController<CoverArtRaw>.broadcast();

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
        onPlayingChanged: (playing) {
          if (playing) _scheduleAudioOutputCheck();
        },
        onIdleActive: (idle) {
          if (idle) _updateLifecycle(playing: false, buffering: false);
        },
      ));
    _registry.observeAll(_lib, _handle);

    // Properties handled outside the registry need an explicit observe call
    // (the registry only observes specs it knows about).
    _observe('playlist', MpvFormat.mpvFormatString);
    _observe('audio-device-list', MpvFormat.mpvFormatString);
    _observe('metadata', MpvFormat.mpvFormatString);
    _observe('demuxer-cache-state', MpvFormat.mpvFormatString);
    _observe('loop-file', MpvFormat.mpvFormatString);
    _observe('loop-playlist', MpvFormat.mpvFormatString);

    stream = PlayerStream.fromInternals(
      reactives: _reactives,
      buffering: _buffering,
      completed: _completed,
      playlist: _playlist,
      playlistMode: _playlistMode,
      audioDevices: _audioDevices,
      metadata: _metadata,
      bufferingPercentage: _bufferingPercentage,
      equalizerGains: _equalizerGains,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      internalLog: _internalLogCtrl.stream,
      hook: _hookCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      coverArtRaw: _coverArtRawCtrl.stream,
    );

    _startEventIsolate();
    NativeReferenceHolder.instance.add(_handle);
  }

  // --- Core Lifecycle ---

  void _applyPreInitOptions() {
    _opt('vid', 'auto');
    _opt('vo', 'null');
    // Standard mpv cover art logic
    _opt('audio-display', 'embedded-first');
    _opt('cover-art-auto', 'no'); // Disable external file scanning
    _opt('image-display-duration', 'inf'); // Keep frame alive for screenshot

    _opt('keep-open', 'yes');
    _opt('idle', 'yes');

    // Disable all builtin scripts and bindings — not needed for a library.
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
    _opt('audio-client-name', configuration.audioClientName ?? 'mpv_audio_kit');

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
    // Defensive early-exit: dispose() awaits `_eventSub.cancel()` before
    // closing controllers, so an in-flight `_handleEvent` invocation
    // already cannot land here after teardown. This guard exists so a
    // future refactor that loosens the dispose ordering can't silently
    // resurrect "Bad state: Cannot add after close" exceptions on the
    // event-emitting controllers below.
    if (_disposed) return;
    switch (event) {
      case MpvEventStartFile():
        _updateLifecycle(buffering: true, completed: false);
      case MpvEventFileLoaded():
        // `pause` is set globally via `_prop('pause', ...)` BEFORE the
        // `loadfile` command in open() / openPlaylist() / jump(). That
        // path triggers mpv's property observer, so the registry
        // updates `state.playing` and `_reactives.playing` on its own
        // — we don't touch them here. We only clear buffering /
        // completed and kick the cover-art pipeline.
        _updateLifecycle(buffering: false, completed: false);
        _pollPosition();
        _extractEmbeddedCover();
      case MpvEventPlaybackSeek():
        // mpv accepted the seek; playback is suspended until
        // MpvEventPlaybackRestart fires. Intentionally a no-op: we
        // don't want to mutate the position stream here (that caused
        // the pre-fix "position=0 flash" bug).
        break;
      case MpvEventPlaybackRestart():
        _pollPosition();
        if (!_seekCompletedCtrl.isClosed) {
          _seekCompletedCtrl.add(null);
        }
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
        final timeout = _hookTimeouts[name];
        if (timeout != null) _startHookTimeout(id, name, timeout);
        _hookCtrl.add(MpvHookEvent(id, name));
      case MpvEventError(:final message):
        _errorCtrl.add(MpvLogError(
          prefix: 'mpv',
          level: 'error',
          text: message,
        ));
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
    // logic touches more than `(parse → reduce)`.
    switch (name) {
      case 'loop-file':
      case 'loop-playlist':
        _updatePlaylistModeFromMpv(name, raw as String);
      case 'playlist':
        _updatePlaylistFromJson(raw as String);
      case 'audio-device-list':
        _updateAudioDevicesFromJson(raw as String);
      case 'metadata':
        _updateMetadataFromJson(raw as String);
      case 'demuxer-cache-state':
        _updateBufferingPercentageFromJson(raw as String);
    }
  }

  // --- Low Level Native Bridge ---

  void _opt(String name, String value) {
    using((arena) => _lib.mpvSetOptionString(
        _handle,
        name.toNativeUtf8(allocator: arena),
        value.toNativeUtf8(allocator: arena)));
  }

  void _prop(String name, String value) {
    using((arena) => _lib.mpvSetPropertyString(
        _handle,
        name.toNativeUtf8(allocator: arena),
        value.toNativeUtf8(allocator: arena)));
  }

  void _command(List<String> args) {
    using((arena) {
      final arr = arena<Pointer<Utf8>>(args.length + 1);
      for (var i = 0; i < args.length; i++) {
        arr[i] = args[i].toNativeUtf8(allocator: arena);
      }
      arr[args.length] = nullptr;
      _lib.mpvCommand(_handle, arr);
    });
  }

  void _commandString(String cmd) {
    using((arena) =>
        _lib.mpvCommandString(_handle, cmd.toNativeUtf8(allocator: arena)));
  }

  /// One-off observe — the registry handles the bulk of properties; this
  /// helper covers the few hand-rolled ones (playlist, metadata, etc.).
  /// Reply IDs are diagnostic-only on the receive side, so we burn a small
  /// pool of high IDs (10001+) to avoid colliding with the registry's range.
  int _customReplyId = 10001;
  void _observe(String name, int format) {
    using((arena) => _lib.mpvObserveProperty(
        _handle, _customReplyId++, name.toNativeUtf8(allocator: arena), format));
  }

  String? _getPropString(String name) {
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

  String _errorString(int code) {
    final p = _lib.mpvErrorString(code);
    return p == nullptr ? 'error $code' : p.cast<Utf8>().toDartString();
  }

  void _startHookTimeout(int id, String name, Duration timeout) {
    _hookTimers[id] = Timer(timeout, () {
      _hookTimers.remove(id);
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
  }

  void _checkNotDisposed() {
    if (_disposed) {
      throw StateError('Player has been disposed');
    }
  }

  // --- Internal State Pipeline ---

  /// Updates [_state] and writes [value] into [reactive]. The reactive
  /// dedups so equal-value writes are silent on the stream.
  ///
  /// This is the API the setter-mixins (audio, network, …) call after
  /// pushing a value to mpv via `_prop`/`_command`, so the public state
  /// reflects the requested value optimistically.
  void _updateField<T>(
    PlayerState Function(PlayerState) updater,
    ReactiveProperty<T> reactive,
    T value,
  ) {
    _state = updater(_state);
    reactive.update(value);
  }

  /// Updates the playback-lifecycle triple (playing / buffering / completed)
  /// and emits on each underlying reactive only for fields whose value
  /// actually changed. Use this for compound transitions (start-file,
  /// file-loaded, end-file, shutdown, idle-active) so all three streams stay
  /// in sync with `state` instead of going silent on `_patchState`.
  ///
  /// The pure-function core lives in [computeLifecycle] (in
  /// `lib/src/internal/lifecycle_transitions.dart`) so the diff logic
  /// can be regression-tested without spinning up a real player — see
  /// `test/internal/lifecycle_transitions_test.dart`.
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

  void _updatePlaylistModeFromMpv(String name, String value) {
    final next = derivePlaylistMode(name, value, _state.playlistMode);
    if (next == null) return;
    _updateField(
      (s) => s.copyWith(playlistMode: next),
      _playlistMode,
      next,
    );
  }

  void _updatePlaylistFromJson(String jsonStr) {
    try {
      final playlist = parsePlaylistJson(
        jsonStr: jsonStr,
        mediaCache: _mediaCache,
        previous: _state.playlist,
      );
      _updateField(
          (s) => s.copyWith(playlist: playlist), _playlist, playlist);
    } catch (e) {
      _internalLog('Failed to parse playlist: $e', level: 'warn');
    }
  }

  void _updateAudioDevicesFromJson(String jsonStr) {
    try {
      final devices = parseAudioDeviceListJson(jsonStr);
      _updateField(
          (s) => s.copyWith(audioDevices: devices), _audioDevices, devices);
    } catch (e) {
      _internalLog('Failed to parse audio devices: $e', level: 'warn');
    }
  }

  void _updateMetadataFromJson(String value) {
    try {
      final metadata = parseMetadataJson(value);
      if (metadata == null) return;
      _updateField((s) => s.copyWith(metadata: metadata), _metadata, metadata);
    } catch (e) {
      _internalLog('Failed to parse metadata: $e', level: 'warn');
    }
  }

  void _updateBufferingPercentageFromJson(String jsonStr) {
    try {
      final pct = parseBufferingPercentage(jsonStr, _state.cacheSecs);
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


  void _updateMediaCover({String? uri, Uint8List? bytes}) {
    final currentIdx = _state.playlist.index;
    if (currentIdx >= 0 && currentIdx < _state.playlist.medias.length) {
      final media = _state.playlist.medias[currentIdx];
      final extras = {...?media.extras};
      if (uri != null) {
        extras['artUri'] = uri;
        extras['cover'] = uri;
      }
      if (bytes != null) {
        extras['artBytes'] = bytes;
        final dataUri = 'data:image/png;base64,${base64Encode(bytes)}';
        extras['artUri'] = dataUri;
        extras['cover'] = dataUri;
      }

      final updatedMedia = Media(
        media.uri,
        extras: extras,
        httpHeaders: media.httpHeaders,
      );

      final updatedMedias = List<Media>.from(_state.playlist.medias);
      updatedMedias[currentIdx] = updatedMedia;

      final updatedPlaylist = Playlist(updatedMedias, index: currentIdx);
      _updateField((s) => s.copyWith(playlist: updatedPlaylist), _playlist,
          updatedPlaylist);
    }
  }

  void _scheduleAudioOutputCheck() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_disposed || !_state.playing) return;
      final fmt = _getPropString('audio-out-params/format');
      if (fmt == null || fmt.isEmpty) {
        _errorCtrl.add(const MpvLogError(
            prefix: 'mpv_audio_kit',
            level: 'error',
            text: 'No audio output driver initialized — playback is silent'));
      }
    });
  }

  /// Internal log helper — emits on the wrapper-side log channel
  /// ([Player.stream.internalLog]), kept separate from mpv's engine log
  /// stream ([Player.stream.log]).
  void _internalLog(String message, {String level = 'info'}) =>
      _internalLogCtrl.add(MpvLogEntry(
          prefix: 'mpv_audio_kit', level: level, text: message));

  int _currentCoverOpId = 0;

  void _extractEmbeddedCover() {
    if (_disposed) return;
    final raw = CoverArtExtractor.capture(_lib, _handle);
    if (raw == null) return;
    // Always surface the raw frame on the public stream — consumers that
    // disabled `processCoverArt` are listening on this for their own
    // pipeline, and even consumers that use the default processor may want
    // a hook to log/inspect the source.
    if (!_coverArtRawCtrl.isClosed) {
      _coverArtRawCtrl.add(raw);
    }
    if (configuration.processCoverArt) {
      _processCoverWithDefaults(raw);
    }
  }

  Future<void> _processCoverWithDefaults(CoverArtRaw raw) async {
    final opId = ++_currentCoverOpId;
    try {
      final png = await CoverArtProcessor.toPng(
        raw,
        isCancelled: () => _disposed || opId != _currentCoverOpId,
      );
      if (png == null) return;
      if (_disposed || opId != _currentCoverOpId) return;
      _updateMediaCover(bytes: png);
    } catch (e) {
      if (opId == _currentCoverOpId) {
        _internalLog('Error processing embedded cover: $e');
      }
    }
  }

  /// Tears down the player.
  ///
  /// The teardown order is load-bearing — changing it has caused crashes
  /// in past releases. The current sequence is:
  ///
  /// 1. **Flip `_disposed`** so any subsequent setter / public-API call
  ///    fails fast via `_checkNotDisposed()`.
  /// 2. **Bump `_currentCoverOpId`** so any in-flight cover-art processing
  ///    bails on its next `isCancelled()` check before touching state or
  ///    the about-to-close media-cover stream.
  /// 3. **Drop the [NativeReferenceHolder] entry** so a hot-restart that
  ///    fires before the destroy completes doesn't try to clean up a
  ///    handle we're already cleaning up.
  /// 4. **Await `_eventSub.cancel()`** before destroying the handle. This
  ///    prevents new `_handleEvent` invocations from landing after the
  ///    destroy. In-flight events queued on the isolate's stream are
  ///    dropped on the floor by Dart's async-cancel semantics.
  /// 5. **`mpvTerminateDestroy(_handle)` BEFORE stopping the isolate**.
  ///    mpv's blocking `mpv_wait_event()` unblocks with
  ///    `MPV_EVENT_SHUTDOWN` as soon as the handle is destroyed, letting
  ///    the isolate's run-loop exit cleanly. The reverse order (stop
  ///    isolate → destroy handle) had a window where the isolate could
  ///    re-enter `mpv_wait_event` between the kill-queue and the destroy.
  /// 6. **Stop the isolate**, which is now guaranteed to exit on its
  ///    next loop iteration.
  /// 7. **Close all reactive properties + controllers**. Order within
  ///    this group does not matter for correctness (they tolerate
  ///    `close()` while a listener is attached); grouping by ownership
  ///    is for auditability.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _currentCoverOpId++;

    NativeReferenceHolder.instance.remove(_handle);
    await _eventSub?.cancel();
    _lib.mpvTerminateDestroy(_handle);
    _eventIsolate.stop();

    // Close the registry-backed reactives, then the standalone ones, then
    // the pure-event stream controllers. Order doesn't matter for
    // correctness — the controllers tolerate close() being called while a
    // listener is still attached — but grouping by ownership keeps
    // teardown auditable.
    await _registry.closeAll();
    await Future.wait<void>([
      _buffering.close(),
      _completed.close(),
      _playlist.close(),
      _playlistMode.close(),
      _audioDevices.close(),
      _metadata.close(),
      _bufferingPercentage.close(),
      _equalizerGains.close(),
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
