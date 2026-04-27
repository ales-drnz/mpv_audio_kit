// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/utils/native_reference_holder.dart';

import 'event_isolate.dart';
import 'mpv_bindings.dart' hide MpvEndFileReason;
import 'mpv_audio_kit.dart';
import 'utils/android_helper.dart';

import 'models/media.dart';
import 'models/playlist.dart';
import 'models/audio_device.dart';
import 'models/audio_filter.dart';
import 'models/audio_params.dart';
import 'models/mpv_log_entry.dart';
import 'models/mpv_hook_event.dart';
import 'models/mpv_prefetch_state.dart';
import 'models/mpv_player_error.dart';
import 'models/player_configuration.dart';
import 'models/player_state.dart';
import 'models/player_stream.dart';

export 'models/media.dart';
export 'models/playlist.dart';
export 'models/audio_device.dart';
export 'models/audio_filter.dart';
export 'models/audio_params.dart';
export 'models/mpv_log_entry.dart';
export 'models/mpv_hook_event.dart';
export 'models/player_configuration.dart';
export 'models/player_state.dart';
export 'models/player_stream.dart';

part 'player/player_playback.part.dart';
part 'player/player_playlist.part.dart';
part 'player/player_audio.part.dart';
part 'player/player_network.part.dart';
part 'player/player_hooks.part.dart';
part 'player/player_property_registry.part.dart';

/// A high-performance audio player powered by libmpv.
class Player extends _PlayerBase
    with
        _PlaybackModule,
        _PlaylistModule,
        _AudioModule,
        _NetworkModule,
        _HooksModule,
        _PropertyRegistry {
  /// Creates a [Player] instance with optional [configuration].
  Player({super.configuration});

  // --- Public Specialized API ---

  /// Opens a [Media] and optionally starts playback immediately.
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
    _pendingPlay = play ?? configuration.autoPlay;
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
  Future<void> openPlaylist(List<Media> medias,
      {bool? play, int index = 0}) async {
    _checkNotDisposed();
    if (medias.isEmpty) {
      return;
    }
    final clampedIndex = index.clamp(0, medias.length - 1);
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
    _command(['loadfile', firstNormalizedUri, 'replace']);
    for (final m in medias.skip(1)) {
      final normalizedUri = await AndroidHelper.normalizeUri(m.uri);
      if (_disposed) return;
      _command(['loadfile', normalizedUri, 'append']);
    }
    _pendingPlay = play ?? configuration.autoPlay;
    if (clampedIndex > 0) {
      _command(['playlist-play-index', clampedIndex.toString()]);
    }
  }

  /// Manually injects an entry into the player's log stream.
  void log(String message, {String level = 'info'}) {
    _logCtrl
        .add(MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message));
  }

  /// Reads any mpv property as a string.
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
  void setRawProperty(String name, String value) {
    _checkNotDisposed();
    _prop(name, value);
  }

  /// Sends a raw mpv command.
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

/// Base class for [Player] containing shared state and native communication logic.
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
  bool _pendingPlay = false;
  List<_RawPlaylistEntry> _rawPlaylist = [];
  final Map<String, Media> _mediaCache = {};

  // --- Controllers ---
  final _playlistCtrl = StreamController<Playlist>.broadcast();
  final _playingCtrl = StreamController<bool>.broadcast();
  final _completedCtrl = StreamController<bool>.broadcast();
  final _positionCtrl = StreamController<Duration>.broadcast();
  final _seekCompletedCtrl = StreamController<void>.broadcast();
  final _durationCtrl = StreamController<Duration>.broadcast();
  final _volumeCtrl = StreamController<double>.broadcast();
  final _rateCtrl = StreamController<double>.broadcast();
  final _pitchCtrl = StreamController<double>.broadcast();
  final _bufferingCtrl = StreamController<bool>.broadcast();
  final _bufferCtrl = StreamController<Duration>.broadcast();
  final _bufferPctCtrl = StreamController<double>.broadcast();
  final _playlistModeCtrl = StreamController<PlaylistMode>.broadcast();
  final _shuffleCtrl = StreamController<bool>.broadcast();
  final _audioParamsCtrl = StreamController<AudioParams>.broadcast();
  final _audioOutParamsCtrl = StreamController<AudioParams>.broadcast();
  final _audioBitrateCtrl = StreamController<double?>.broadcast();
  final _audioDeviceCtrl = StreamController<AudioDevice>.broadcast();
  final _audioDevicesCtrl = StreamController<List<AudioDevice>>.broadcast();
  final _muteCtrl = StreamController<bool>.broadcast();
  final _audioDelayCtrl = StreamController<double>.broadcast();
  final _pitchCorrectionCtrl = StreamController<bool>.broadcast();
  final _metadataCtrl = StreamController<Map<String, String>>.broadcast();
  final _gaplessModeCtrl = StreamController<String>.broadcast();
  final _replayGainModeCtrl = StreamController<String>.broadcast();
  final _replayGainPreampCtrl = StreamController<double>.broadcast();
  final _replayGainFallbackCtrl = StreamController<double>.broadcast();
  final _replayGainClipCtrl = StreamController<bool>.broadcast();
  final _volumeGainCtrl = StreamController<double>.broadcast();
  final _cacheModeCtrl = StreamController<String>.broadcast();
  final _cacheSecsCtrl = StreamController<double>.broadcast();
  final _cacheOnDiskCtrl = StreamController<bool>.broadcast();
  final _cachePauseCtrl = StreamController<bool>.broadcast();
  final _cachePauseWaitCtrl = StreamController<double>.broadcast();
  final _demuxerMaxBytesCtrl = StreamController<int>.broadcast();
  final _demuxerReadaheadSecsCtrl = StreamController<int>.broadcast();
  final _demuxerMaxBackBytesCtrl = StreamController<int>.broadcast();
  final _networkTimeoutCtrl = StreamController<double>.broadcast();
  final _tlsVerifyCtrl = StreamController<bool>.broadcast();
  final _pausedForCacheCtrl = StreamController<bool>.broadcast();
  final _demuxerViaNetworkCtrl = StreamController<bool>.broadcast();
  final _audioExclusiveCtrl = StreamController<bool>.broadcast();
  final _audioBufferCtrl = StreamController<double>.broadcast();
  final _audioStreamSilenceCtrl = StreamController<bool>.broadcast();
  final _aoNullUntimedCtrl = StreamController<bool>.broadcast();
  final _audioTrackCtrl = StreamController<String>.broadcast();
  final _audioSpdifCtrl = StreamController<String>.broadcast();
  final _volumeMaxCtrl = StreamController<double>.broadcast();
  final _audioSampleRateCtrl = StreamController<int>.broadcast();
  final _audioFormatCtrl = StreamController<String>.broadcast();
  final _audioChannelsCtrl = StreamController<String>.broadcast();
  final _audioClientNameCtrl = StreamController<String>.broadcast();
  final _audioDriverCtrl = StreamController<String>.broadcast();
  final _activeFiltersCtrl = StreamController<List<AudioFilter>>.broadcast();
  final _equalizerGainsCtrl = StreamController<List<double>>.broadcast();
  final _audioDisplayCtrl = StreamController<String>.broadcast();
  final _coverArtAutoCtrl = StreamController<String>.broadcast();
  final _imageDisplayDurationCtrl = StreamController<String>.broadcast();
  final _endFileCtrl = StreamController<MpvFileEndedEvent>.broadcast();
  final _errorCtrl = StreamController<MpvPlayerError>.broadcast();
  final _logCtrl = StreamController<MpvLogEntry>.broadcast();
  final _hookCtrl = StreamController<MpvHookEvent>.broadcast();
  // Surface the patched `prefetch-state` mpv property as a typed stream.
  // See [MpvPrefetchState] and the `patch_prefetch_state.py` patch in
  // scripts/patches/mpv/ for the native side. We expose every state
  // transition including the transient `used` → `idle` pair so clients
  // can treat `used` as a one-shot "track just transitioned gaplessly"
  // signal without polling.
  final _prefetchStateCtrl = StreamController<MpvPrefetchState>.broadcast();

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
    _registerObservedProperties();

    stream = PlayerStream(
      playlist: _playlistCtrl.stream,
      playing: _playingCtrl.stream,
      completed: _completedCtrl.stream,
      position: _positionCtrl.stream,
      seekCompleted: _seekCompletedCtrl.stream,
      duration: _durationCtrl.stream,
      volume: _volumeCtrl.stream,
      rate: _rateCtrl.stream,
      pitch: _pitchCtrl.stream,
      buffering: _bufferingCtrl.stream,
      buffer: _bufferCtrl.stream,
      bufferingPercentage: _bufferPctCtrl.stream,
      playlistMode: _playlistModeCtrl.stream,
      shuffle: _shuffleCtrl.stream,
      audioParams: _audioParamsCtrl.stream,
      audioOutParams: _audioOutParamsCtrl.stream,
      audioBitrate: _audioBitrateCtrl.stream,
      audioDevice: _audioDeviceCtrl.stream,
      audioDevices: _audioDevicesCtrl.stream,
      mute: _muteCtrl.stream,
      audioDelay: _audioDelayCtrl.stream,
      pitchCorrection: _pitchCorrectionCtrl.stream,
      metadata: _metadataCtrl.stream,
      gaplessMode: _gaplessModeCtrl.stream,
      replayGainMode: _replayGainModeCtrl.stream,
      replayGainPreamp: _replayGainPreampCtrl.stream,
      replayGainFallback: _replayGainFallbackCtrl.stream,
      replayGainClip: _replayGainClipCtrl.stream,
      volumeGain: _volumeGainCtrl.stream,
      cacheMode: _cacheModeCtrl.stream,
      cacheSecs: _cacheSecsCtrl.stream,
      cacheOnDisk: _cacheOnDiskCtrl.stream,
      cachePause: _cachePauseCtrl.stream,
      cachePauseWait: _cachePauseWaitCtrl.stream,
      demuxerMaxBytes: _demuxerMaxBytesCtrl.stream,
      demuxerReadaheadSecs: _demuxerReadaheadSecsCtrl.stream,
      demuxerMaxBackBytes: _demuxerMaxBackBytesCtrl.stream,
      networkTimeout: _networkTimeoutCtrl.stream,
      tlsVerify: _tlsVerifyCtrl.stream,
      pausedForCache: _pausedForCacheCtrl.stream,
      demuxerViaNetwork: _demuxerViaNetworkCtrl.stream,
      audioExclusive: _audioExclusiveCtrl.stream,
      audioBuffer: _audioBufferCtrl.stream,
      audioStreamSilence: _audioStreamSilenceCtrl.stream,
      aoNullUntimed: _aoNullUntimedCtrl.stream,
      audioTrack: _audioTrackCtrl.stream,
      audioSpdif: _audioSpdifCtrl.stream,
      volumeMax: _volumeMaxCtrl.stream,
      audioSampleRate: _audioSampleRateCtrl.stream,
      audioFormat: _audioFormatCtrl.stream,
      audioChannels: _audioChannelsCtrl.stream,
      audioClientName: _audioClientNameCtrl.stream,
      audioDriver: _audioDriverCtrl.stream,
      activeFilters: _activeFiltersCtrl.stream,
      equalizerGains: _equalizerGainsCtrl.stream,
      audioDisplay: _audioDisplayCtrl.stream,
      coverArtAuto: _coverArtAutoCtrl.stream,
      imageDisplayDuration: _imageDisplayDurationCtrl.stream,
      endFile: _endFileCtrl.stream,
      error: _errorCtrl.stream,
      log: _logCtrl.stream,
      hook: _hookCtrl.stream,
      prefetchState: _prefetchStateCtrl.stream,
    );

    _startEventIsolate();
    NativeReferenceHolder.instance.add(_handle);
  }

  // --- Handlers (Implemented by Mixins) ---
  void _handleDoubleProperty(String name, double value);
  void _handleIntProperty(String name, int value);
  void _handleStringProperty(String name, String value);
  void _registerObservedProperties();

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
    switch (event) {
      case MpvEventStartFile():
        _updateLifecycle(buffering: true, completed: false);
      case MpvEventFileLoaded():
        _prop('pause', _pendingPlay ? 'no' : 'yes');
        _updateLifecycle(
            buffering: false, playing: _pendingPlay, completed: false);
        _pollPosition();
        _extractEmbeddedCover();
      case MpvEventPlaybackSeek():
        // mpv accepted the seek; playback is suspended until
        // MpvEventPlaybackRestart fires. Intentionally a no-op: we
        // don't want to mutate the position stream here (that caused
        // the pre-fix "position=0 flash" bug).
        break;
      case MpvEventPlaybackRestart():
        // Authoritative "seek finished" signal. Poll time-pos
        // immediately so positionStream emits the real post-seek
        // value before the 33ms-throttled time-pos observer can,
        // then notify listeners waiting on seekCompleted.
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
        _handleDoubleProperty(name, value);
      case MpvEventPropertyInt(:final name, :final value):
        _handleIntProperty(name, value);
      case MpvEventPropertyString(:final name, :final value):
        _handleStringProperty(name, value);
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

  void _observe(String name, int format, int replyId) {
    using((arena) => _lib.mpvObserveProperty(
        _handle, replyId, name.toNativeUtf8(allocator: arena), format));
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
      _log(
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

  void _patchState(PlayerState Function(PlayerState) updater) {
    _state = updater(_state);
  }

  /// Updates state and notifies a specific controller.
  void _updateState<T>(PlayerState Function(PlayerState) updater,
      StreamController<T> ctrl, T newValue) {
    _state = updater(_state);
    ctrl.add(newValue);
  }

  /// Updates the playback-lifecycle triple (playing / buffering / completed)
  /// and emits on each underlying stream only for fields whose value actually
  /// changed. Use this for compound transitions (start-file, file-loaded,
  /// end-file, shutdown, idle-active) so all three streams stay in sync with
  /// `state` instead of going silent on `_patchState`.
  void _updateLifecycle({bool? playing, bool? buffering, bool? completed}) {
    final prev = _state;
    _state = _state.copyWith(
      playing: playing,
      buffering: buffering,
      completed: completed,
    );
    if (playing != null && prev.playing != playing) {
      _playingCtrl.add(playing);
    }
    if (buffering != null && prev.buffering != buffering) {
      _bufferingCtrl.add(buffering);
    }
    if (completed != null && prev.completed != completed) {
      _completedCtrl.add(completed);
    }
  }

  void _updateAudioParams(AudioParams Function(AudioParams) updater) {
    final updated = updater(_state.audioParams);
    _patchState((s) => s.copyWith(audioParams: updated));
    _audioParamsCtrl.add(updated);
  }

  void _updateAudioOutParams(AudioParams Function(AudioParams) updater) {
    final updated = updater(_state.audioOutParams);
    _patchState((s) => s.copyWith(audioOutParams: updated));
    _audioOutParamsCtrl.add(updated);
  }

  void _updateMetadata(String value) {
    try {
      final String cleanValue = value.trim();
      if (cleanValue.isEmpty) {
        return;
      }
      final Map<String, dynamic> raw = json.decode(cleanValue);
      final metadata = raw.map((k, v) => MapEntry(k, v.toString()));
      _patchState((s) => s.copyWith(metadata: metadata));
      _metadataCtrl.add(metadata);
    } catch (e) {
      _log('Failed to parse metadata: $e', level: 'warn');
    }
  }

  void _updatePlaylist(String jsonStr) {
    try {
      final list =
          (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
      _rawPlaylist = list.map((e) => _RawPlaylistEntry.fromJson(e)).toList();
      final currentIndex = _rawPlaylist.indexWhere((e) => e.current);
      final medias = _rawPlaylist
          .map((e) => _mediaCache[e.filename] ?? Media(e.filename))
          .toList();
      // currentIndex is -1 when mpv emits the playlist without a `current` flag
      // (e.g. transiently during playlist-move). Fall back to the last known index
      // instead of clamping -1 to 0, which would incorrectly mark the first item.
      final idx = currentIndex >= 0
          ? currentIndex
          : _state.playlist.index.clamp(0, medias.isEmpty ? 0 : medias.length - 1);
      final playlist = Playlist(medias, index: idx);
      _patchState((s) => s.copyWith(playlist: playlist));
      _playlistCtrl.add(playlist);
    } catch (e) {
      _log('Failed to parse playlist: $e', level: 'warn');
    }
  }

  void _updateAudioDevices(String jsonStr) {
    try {
      final list =
          (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
      final devices = list
          .map((d) => AudioDevice(d['name'] as String? ?? 'unknown',
              d['description'] as String? ?? ''))
          .toList();
      _patchState((s) => s.copyWith(audioDevices: devices));
      _audioDevicesCtrl.add(devices);
    } catch (e) {
      _log('Failed to parse audio devices: $e', level: 'warn');
    }
  }

  void _parseCacheState(String jsonStr) {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final cacheDuration = (map['cache-duration'] as num?)?.toDouble() ?? 0.0;
      final targetSecs = _state.cacheSecs > 0 ? _state.cacheSecs : 1.0;
      final pct = (cacheDuration / targetSecs * 100.0).clamp(0.0, 100.0);
      _patchState((s) => s.copyWith(bufferingPercentage: pct));
      _bufferPctCtrl.add(pct);
    } catch (e) {
      _log('Failed to parse cache state: $e', level: 'warn');
    }
  }

  void _pollPosition() {
    if (_disposed) return;
    using((arena) {
      final n = 'time-pos'.toNativeUtf8(allocator: arena);
      final buf = arena<Double>();
      final rc = _lib.mpvGetProperty(
          _handle, n, MpvFormat.mpvFormatDouble, buf.cast());
      if (rc == MpvError.mpvErrorSuccess) {
        final pos = Duration(microseconds: (buf.value * 1e6).round());
        _patchState((s) => s.copyWith(position: pos));
        _positionCtrl.add(pos);
      }
    });
  }

  void _updatePlaylistMode(String name, String value) {
    if (name == 'loop-file') {
      if (value == 'inf') {
        _updateState((s) => s.copyWith(playlistMode: PlaylistMode.single),
            _playlistModeCtrl, PlaylistMode.single);
      } else if (_state.playlistMode == PlaylistMode.single) {
        _updateState((s) => s.copyWith(playlistMode: PlaylistMode.none),
            _playlistModeCtrl, PlaylistMode.none);
      }
    } else if (name == 'loop-playlist') {
      if (value == 'inf') {
        _updateState((s) => s.copyWith(playlistMode: PlaylistMode.loop),
            _playlistModeCtrl, PlaylistMode.loop);
      } else if (_state.playlistMode == PlaylistMode.loop) {
        _updateState((s) => s.copyWith(playlistMode: PlaylistMode.none),
            _playlistModeCtrl, PlaylistMode.none);
      }
    }
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
      _updateState((s) => s.copyWith(playlist: updatedPlaylist), _playlistCtrl,
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

  void _log(String message, {String level = 'info'}) => _logCtrl
      .add(MpvLogEntry(prefix: 'mpv_audio_kit', level: level, text: message));

  int _currentCoverOpId = 0;

  void _extractEmbeddedCover() {
    if (_disposed) return;
    final vid = _getPropString('vid');
    if (vid == null || vid == 'no' || vid == '0') {
      return;
    }

    final result = calloc<MpvNode>();
    final args = ['screenshot-raw', 'video'];

    using((arena) {
      final argPtrs = arena
          .allocate<Pointer<Utf8>>((args.length + 1) * sizeOf<Pointer<Utf8>>());
      for (int i = 0; i < args.length; i++) {
        argPtrs[i] = args[i].toNativeUtf8(allocator: arena);
      }
      argPtrs[args.length] = nullptr;

      final res = _lib.mpvCommandRet(_handle, argPtrs, result);
      if (res < 0) {
        _lib.mpvFreeNodeContents(result);
        calloc.free(result);
        return;
      }

      if (result.ref.format == MpvFormat.mpvFormatNodeMap) {
        int? w, h, stride;
        Uint8List? rawBytes;

        final map = result.ref.u.list;
        for (int i = 0; i < map.ref.num; i++) {
          final key = map.ref.keys[i].toDartString();
          final val = map.ref.values[i];
          if (key == 'w' && val.format == MpvFormat.mpvFormatInt64) {
            w = val.u.int64;
          }
          if (key == 'h' && val.format == MpvFormat.mpvFormatInt64) {
            h = val.u.int64;
          }
          if (key == 'stride' && val.format == MpvFormat.mpvFormatInt64) {
            stride = val.u.int64;
          }
          if (key == 'data' && val.format == MpvFormat.mpvFormatByteArray) {
            rawBytes = Uint8List.fromList(
                val.u.ba.ref.data.cast<Uint8>().asTypedList(val.u.ba.ref.size));
          }
        }

        if (w != null && h != null && stride != null && rawBytes != null) {
          // Process in background
          _processRawCover(w, h, stride, rawBytes);
        }
      }

      _lib.mpvFreeNodeContents(result);
      calloc.free(result);
    });
  }

  Future<void> _processRawCover(
      int w, int h, int stride, Uint8List bytes) async {
    final opId = ++_currentCoverOpId;
    try {
      // 1. Optimized buffer handling
      Uint8List workingBuffer;
      if (stride == w * 4) {
        // Zero-copy: reuse the bytes previously copied from C
        workingBuffer = bytes;
      } else {
        // Re-align if stride has padding
        workingBuffer = Uint8List(w * h * 4);
        for (int y = 0; y < h; y++) {
          workingBuffer.setRange(y * w * 4, (y + 1) * w * 4,
              bytes.sublist(y * stride, y * stride + w * 4));
        }
      }

      if (opId != _currentCoverOpId) {
        return;
      }

      // Ensure Alpha is opaque (BGR0 -> BGRA)
      for (int i = 3; i < workingBuffer.length; i += 4) {
        workingBuffer[i] = 255;
      }

      if (opId != _currentCoverOpId || _disposed) {
        return;
      }

      final buffer = await ui.ImmutableBuffer.fromUint8List(workingBuffer);
      if (opId != _currentCoverOpId || _disposed) {
        buffer.dispose();
        return;
      }
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: w,
        height: h,
        pixelFormat: ui.PixelFormat.bgra8888,
      );

      try {
        // 2. Resize to max 800px
        double ratio = 800 / (w > h ? w : h);
        if (ratio > 1.0) {
          ratio = 1.0;
        }

        final codec = await descriptor.instantiateCodec(
          targetWidth: (w * ratio).round(),
          targetHeight: (h * ratio).round(),
        );

        try {
          final frame = await codec.getNextFrame();
          try {
            if (opId != _currentCoverOpId || _disposed) return;
            final data =
                await frame.image.toByteData(format: ui.ImageByteFormat.png);
            if (opId != _currentCoverOpId || _disposed) return;
            if (data != null) {
              _updateMediaCover(bytes: data.buffer.asUint8List());
            }
          } finally {
            frame.image.dispose();
          }
        } finally {
          codec.dispose();
        }
      } finally {
        descriptor.dispose();
      }
    } catch (e) {
      if (opId == _currentCoverOpId) {
        _log('Error processing embedded cover: $e');
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;

    // Invalidate any in-flight async cover-art processing so it bails before
    // touching state or the (about-to-close) media-cover stream.
    _currentCoverOpId++;

    NativeReferenceHolder.instance.remove(_handle);
    // Cancel the main-isolate subscription FIRST so no further _handleEvent
    // calls fire after _disposed=true. After cancel completes, in-flight
    // events queued on the isolate's stream are dropped on the floor.
    await _eventSub?.cancel();
    // Tearing down mpv before stopping the isolate is safe: mpv's blocking
    // mpvWaitEvent unblocks with MPV_EVENT_SHUTDOWN as soon as the handle is
    // destroyed, letting the isolate's run-loop exit cleanly.
    _lib.mpvTerminateDestroy(_handle);
    _eventIsolate.stop();

    final ctrls = [
      _playlistCtrl,
      _playingCtrl,
      _completedCtrl,
      _positionCtrl,
      _seekCompletedCtrl,
      _durationCtrl,
      _volumeCtrl,
      _rateCtrl,
      _pitchCtrl,
      _bufferingCtrl,
      _bufferCtrl,
      _bufferPctCtrl,
      _playlistModeCtrl,
      _shuffleCtrl,
      _audioParamsCtrl,
      _audioOutParamsCtrl,
      _audioBitrateCtrl,
      _audioDeviceCtrl,
      _audioDevicesCtrl,
      _muteCtrl,
      _audioDelayCtrl,
      _pitchCorrectionCtrl,
      _metadataCtrl,
      _gaplessModeCtrl,
      _replayGainModeCtrl,
      _replayGainPreampCtrl,
      _replayGainFallbackCtrl,
      _replayGainClipCtrl,
      _volumeGainCtrl,
      _cacheModeCtrl,
      _cacheSecsCtrl,
      _cacheOnDiskCtrl,
      _cachePauseCtrl,
      _cachePauseWaitCtrl,
      _demuxerMaxBytesCtrl,
      _demuxerReadaheadSecsCtrl,
      _demuxerMaxBackBytesCtrl,
      _networkTimeoutCtrl,
      _tlsVerifyCtrl,
      _pausedForCacheCtrl,
      _demuxerViaNetworkCtrl,
      _audioExclusiveCtrl,
      _audioBufferCtrl,
      _audioStreamSilenceCtrl,
      _aoNullUntimedCtrl,
      _audioTrackCtrl,
      _audioSpdifCtrl,
      _volumeMaxCtrl,
      _audioSampleRateCtrl,
      _audioFormatCtrl,
      _audioChannelsCtrl,
      _audioClientNameCtrl,
      _audioDriverCtrl,
      _activeFiltersCtrl,
      _equalizerGainsCtrl,
      _audioDisplayCtrl,
      _coverArtAutoCtrl,
      _imageDisplayDurationCtrl,
      _prefetchStateCtrl,
      _endFileCtrl,
      _errorCtrl,
      _logCtrl,
      _hookCtrl,
    ];
    for (final c in ctrls) {
      c.close();
    }
  }
}

class _RawPlaylistEntry {
  final String filename;
  final bool current;
  final bool playing;
  final String? title;

  _RawPlaylistEntry(
      {required this.filename,
      required this.current,
      required this.playing,
      this.title});

  factory _RawPlaylistEntry.fromJson(Map<String, dynamic> json) =>
      _RawPlaylistEntry(
        filename: json['filename'] as String? ?? '',
        current: json['current'] == true,
        playing: json['playing'] == true,
        title: json['title'] as String?,
      );
}
