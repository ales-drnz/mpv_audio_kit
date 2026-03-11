import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/utils/native_reference_holder.dart';
import 'package:flutter/foundation.dart';

import 'event_isolate.dart';
import 'mpv_bindings.dart';
import 'utils/android_helper.dart';

import 'models/media.dart';
import 'models/playlist.dart';
import 'models/audio_device.dart';
import 'models/audio_filter.dart';
import 'models/audio_params.dart';
import 'models/player_configuration.dart';
import 'models/player_state.dart';
import 'models/player_stream.dart';
import 'models/replay_gain.dart';
import 'models/gapless_mode.dart';

export 'models/media.dart';
export 'models/playlist.dart';
export 'models/audio_device.dart';
export 'models/audio_filter.dart';
export 'models/audio_params.dart';
export 'models/player_configuration.dart';
export 'models/player_state.dart';
export 'models/player_stream.dart';
export 'models/replay_gain.dart';
export 'models/gapless_mode.dart';

/// A high-performance audio player powered by libmpv.
///
/// ## Quick start
/// ```dart
/// import 'package:mpv_audio_kit/mpv_audio_kit.dart';
///
/// final player = Player();
/// await player.open(Media('https://example.com/audio.mp3'));
///
/// player.stream.position.listen((pos) => print(pos));
/// player.stream.playing.listen((p) => print('playing: $p'));
///
/// await player.play();
/// // ...
/// await player.dispose();
/// ```
///
/// ## State access
/// - `player.state` — synchronous snapshot of the current state.
/// - `player.stream.*` — typed [Stream]s for each individual field.
///
/// The event loop runs in a dedicated [Isolate] so it never blocks the
/// Flutter render thread.
class Player {
  /// The static configuration for this player instance.
  final PlayerConfiguration configuration;

  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  late final MpvEventIsolate _eventIsolate;
  StreamSubscription<MpvIsolateEvent>? _eventSub;
  bool _disposed = false;

  // ── Internal state ────────────────────────────────────────────────────────

  PlayerState _state = const PlayerState();

  /// Internal playlist tracking (mirrors mpv's JSON output).
  List<_RawPlaylistEntry> _rawPlaylist = [];

  /// Cache to retain Dart-side metadata ([Media.extras], [Media.httpHeaders]) 
  /// for tracks, keyed by their URI.
  final Map<String, Media> _mediaCache = {};

  // ── Stream controllers ────────────────────────────────────────────────────

  final _playlistCtrl       = StreamController<Playlist>.broadcast();
  final _playingCtrl        = StreamController<bool>.broadcast();
  final _completedCtrl      = StreamController<bool>.broadcast();
  final _positionCtrl       = StreamController<Duration>.broadcast();
  final _durationCtrl       = StreamController<Duration>.broadcast();
  final _volumeCtrl         = StreamController<double>.broadcast();
  final _rateCtrl           = StreamController<double>.broadcast();
  final _pitchCtrl          = StreamController<double>.broadcast();
  final _bufferingCtrl      = StreamController<bool>.broadcast();
  final _bufferCtrl         = StreamController<Duration>.broadcast();
  final _bufferPctCtrl      = StreamController<double>.broadcast();
  final _playlistModeCtrl   = StreamController<PlaylistMode>.broadcast();
  final _shuffleCtrl        = StreamController<bool>.broadcast();
  final _audioParamsCtrl    = StreamController<AudioParams>.broadcast();
  final _audioBitrateCtrl   = StreamController<double?>.broadcast();
  final _audioDeviceCtrl    = StreamController<AudioDevice>.broadcast();
  final _audioDevicesCtrl   = StreamController<List<AudioDevice>>.broadcast();
  final _muteCtrl           = StreamController<bool>.broadcast();
  final _errorCtrl          = StreamController<String>.broadcast();
  final _logCtrl            = StreamController<String>.broadcast();

  // ── Public API ───────────────────────────────────────────────────────────

  /// The current player state as a synchronous snapshot.
  PlayerState get state => _state;

  /// Typed event streams for subscribing to individual state changes.
  late final PlayerStream stream;

  /// Creates a [Player] instance with optional [configuration].
  ///
  /// Spawns the libmpv context and the background event-loop isolate.
  /// Call [dispose] when done to free all native resources.
  Player({this.configuration = const PlayerConfiguration()}) {
    _lib = MpvLibrary.open();
    _handle = _lib.mpvCreate();
    if (_handle == nullptr) throw StateError('mpv_create() returned NULL');

    _applyPreInitOptions();
    final rc = _lib.mpvInitialize(_handle);
    if (rc < 0) {
      _lib.mpvTerminateDestroy(_handle);
      throw StateError('mpv_initialize() failed: ${_errorString(rc)}');
    }
    _applyPostInitOptions();
    _registerObservedProperties();

    stream = PlayerStream(
      playlist:           _playlistCtrl.stream,
      playing:            _playingCtrl.stream,
      completed:          _completedCtrl.stream,
      position:           _positionCtrl.stream,
      duration:           _durationCtrl.stream,
      volume:             _volumeCtrl.stream,
      rate:               _rateCtrl.stream,
      pitch:              _pitchCtrl.stream,
      buffering:          _bufferingCtrl.stream,
      buffer:             _bufferCtrl.stream,
      bufferingPercentage: _bufferPctCtrl.stream,
      playlistMode:       _playlistModeCtrl.stream,
      shuffle:            _shuffleCtrl.stream,
      audioParams:        _audioParamsCtrl.stream,
      audioBitrate:       _audioBitrateCtrl.stream,
      audioDevice:        _audioDeviceCtrl.stream,
      audioDevices:       _audioDevicesCtrl.stream,
      mute:               _muteCtrl.stream,
      error:              _errorCtrl.stream,
      log:                _logCtrl.stream,
    );

    _startEventIsolate();

    // Register our mpv handle to prevent memory leaks on hot-restart
    NativeReferenceHolder.instance.add(_handle);
  }

  // ── Initialization ────────────────────────────────────────────────────────

  void _applyPreInitOptions() {
    _opt('vid', 'no');
    _opt('vo', 'null');
    _opt('keep-open', 'yes');
    _opt('idle', 'yes');

    if (configuration.audioOutputDriver?.isNotEmpty == true) {
      _opt('ao', configuration.audioOutputDriver!);
    }
    if (configuration.audioClientName?.isNotEmpty == true) {
      _opt('audio-client-name', configuration.audioClientName!);
    } else {
      _opt('audio-client-name', 'mpv_audio_kit');
    }
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

  void _registerObservedProperties() {
    _observe('time-pos',               MpvFormat.mpvFormatDouble, 1);
    _observe('duration',               MpvFormat.mpvFormatDouble, 2);
    _observe('pause',                  MpvFormat.mpvFormatFlag,   3);
    _observe('volume',                 MpvFormat.mpvFormatDouble, 4);
    _observe('idle-active',            MpvFormat.mpvFormatFlag,   5);
    _observe('mute',                   MpvFormat.mpvFormatFlag,   6);
    _observe('pitch',                  MpvFormat.mpvFormatDouble, 7);
    _observe('speed',                  MpvFormat.mpvFormatDouble, 8);
    _observe('demuxer-cache-duration', MpvFormat.mpvFormatDouble, 9);
    _observe('demuxer-cache-state',    MpvFormat.mpvFormatString, 10);
    _observe('audio-bitrate',          MpvFormat.mpvFormatDouble, 11);
    _observe('audio-device-list',      MpvFormat.mpvFormatString, 12);
    _observe('audio-device',           MpvFormat.mpvFormatString, 13);
    _observe('shuffle',                MpvFormat.mpvFormatFlag,   14);
    _observe('loop-file',              MpvFormat.mpvFormatString, 15);
    _observe('loop-playlist',          MpvFormat.mpvFormatString, 16);
    _observe('playlist',               MpvFormat.mpvFormatString, 17);
    _observe('audio-params/format',    MpvFormat.mpvFormatString, 18);
    _observe('audio-params/samplerate',MpvFormat.mpvFormatDouble, 19);
    _observe('audio-params/channels',  MpvFormat.mpvFormatString, 20);
    _observe('audio-params/channel-count', MpvFormat.mpvFormatDouble, 21);
    _observe('audio-params/hr-channels', MpvFormat.mpvFormatString, 22);
  }

  Future<void> _startEventIsolate() async {
    _eventIsolate = MpvEventIsolate();
    await _eventIsolate.start(_handle);
    _eventSub = _eventIsolate.events.listen(_handleEvent);
  }

  // ── Event handling ────────────────────────────────────────────────────────

  void _handleEvent(MpvIsolateEvent event) {
    switch (event) {
      case MpvEventStartFile():
        _patchState((s) => s.copyWith(buffering: true, completed: false));

      case MpvEventFileLoaded():
        _patchState((s) => s.copyWith(
          buffering: false,
          playing: configuration.autoPlay,
          completed: false,
        ));
        _pollPosition();

      case MpvEndFileEvent(:final reason, :final error):
        if (error < 0) {
          _errorCtrl.add(_errorString(error));
        }
        final isEof = reason == MpvEndFileReason.mpvEndFileReasonEof;
        _patchState((s) => s.copyWith(
          playing: false,
          buffering: false,
          completed: isEof,
        ));

      case MpvEventShutdown():
        _patchState((s) => s.copyWith(playing: false, buffering: false));

      case MpvEventPropertyDouble(:final name, :final value):
        _handleDoubleProperty(name, value);

      case MpvEventPropertyInt(:final name, :final value):
        _handleIntProperty(name, value);

      case MpvEventPropertyString(:final name, :final value):
        _handleStringProperty(name, value);

      case MpvEventLog(:final prefix, :final level, :final text):
        final line = '[$prefix] $level: $text';
        _logCtrl.add(line);
        if (level == 'error' || level == 'fatal') {
          _errorCtrl.add(line);
        }

      case MpvEventError(:final message):
        _errorCtrl.add(message);
    }
  }

  void _handleDoubleProperty(String name, double value) {
    switch (name) {
      case 'time-pos':
      case '_seek':
        final pos = Duration(microseconds: (value * 1e6).round());
        _patchState((s) => s.copyWith(position: pos));
        _positionCtrl.add(pos);

      case 'duration':
        final dur = Duration(microseconds: (value * 1e6).round());
        _patchState((s) => s.copyWith(duration: dur));
        _durationCtrl.add(dur);

      case 'volume':
        _patchState((s) => s.copyWith(volume: value));
        _volumeCtrl.add(value);

      case 'speed':
        _patchState((s) => s.copyWith(rate: value));
        _rateCtrl.add(value);

      case 'pitch':
        _patchState((s) => s.copyWith(pitch: value));
        _pitchCtrl.add(value);

      case 'demuxer-cache-duration':
        final buf = Duration(microseconds: (value * 1e6).round());
        _patchState((s) => s.copyWith(buffer: buf));
        _bufferCtrl.add(buf);

      case 'audio-bitrate':
        final bps = value > 0 ? value : null;
        _patchState((s) => s.copyWith(audioBitrate: bps));
        _audioBitrateCtrl.add(bps);

      case 'audio-params/samplerate':
        final updated = _state.audioParams.copyWith(sampleRate: value.toInt());
        _patchState((s) => s.copyWith(audioParams: updated));
        _audioParamsCtrl.add(updated);

      case 'audio-params/channel-count':
        final updated = _state.audioParams.copyWith(channelCount: value.toInt());
        _patchState((s) => s.copyWith(audioParams: updated));
        _audioParamsCtrl.add(updated);
    }
  }

  void _handleIntProperty(String name, int value) {
    switch (name) {
      case 'pause':
        final paused = value == 1;
        _patchState((s) => s.copyWith(playing: !paused));
        _playingCtrl.add(!paused);

      case 'mute':
        final muted = value == 1;
        _patchState((s) => s.copyWith(mute: muted));
        _muteCtrl.add(muted);

      case 'idle-active':
        if (value == 1) {
          _patchState((s) => s.copyWith(playing: false, buffering: false));
        }

      case 'shuffle':
        final sh = value == 1;
        _patchState((s) => s.copyWith(shuffle: sh));
        _shuffleCtrl.add(sh);
    }
  }

  void _handleStringProperty(String name, String value) {
    switch (name) {
      case 'loop-file':
      case 'loop-playlist':
        _updatePlaylistMode(name, value);

      case 'playlist':
        _updatePlaylist(value);

      case 'audio-device-list':
        _updateAudioDevices(value);

      case 'audio-device':
        final device = AudioDevice(value, value);
        _patchState((s) => s.copyWith(audioDevice: device));
        _audioDeviceCtrl.add(device);

      case 'audio-params/format':
        final updated = _state.audioParams.copyWith(format: value);
        _patchState((s) => s.copyWith(audioParams: updated));
        _audioParamsCtrl.add(updated);

      case 'audio-params/channels':
        final updated = _state.audioParams.copyWith(channels: value);
        _patchState((s) => s.copyWith(audioParams: updated));
        _audioParamsCtrl.add(updated);

      case 'audio-params/hr-channels':
        final updated = _state.audioParams.copyWith(hrChannels: value);
        _patchState((s) => s.copyWith(audioParams: updated));
        _audioParamsCtrl.add(updated);

      case 'demuxer-cache-state':
        _parseCacheState(value);
    }
  }

  void _updatePlaylistMode(String prop, String value) {
    final loopFile     = prop == 'loop-file'     ? value : getRawProperty('loop-file')     ?? 'no';
    final loopPlaylist = prop == 'loop-playlist'  ? value : getRawProperty('loop-playlist') ?? 'no';

    final mode = loopFile == 'inf' || loopFile == 'yes'
        ? PlaylistMode.single
        : (loopPlaylist == 'inf' || loopPlaylist == 'yes')
            ? PlaylistMode.loop
            : PlaylistMode.none;

    _patchState((s) => s.copyWith(playlistMode: mode));
    _playlistModeCtrl.add(mode);
  }

  void _updatePlaylist(String jsonStr) {
    try {
      final list = (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
      _rawPlaylist = list.map((e) => _RawPlaylistEntry.fromJson(e)).toList();

      final currentIndex = _rawPlaylist.indexWhere((e) => e.current);
      final medias = _rawPlaylist.map((e) => _mediaCache[e.filename] ?? Media(e.filename)).toList();
      final playlist = Playlist(medias, index: currentIndex.clamp(0, medias.length));

      _patchState((s) => s.copyWith(playlist: playlist));
      _playlistCtrl.add(playlist);
    } catch (e) {
      debugPrint('mpv_audio_kit: failed to parse playlist: $e');
    }
  }

  void _updateAudioDevices(String jsonStr) {
    try {
      final list = (json.decode(jsonStr) as List<dynamic>).cast<Map<String, dynamic>>();
      final devices = list
          .map((d) => AudioDevice(d['name'] as String? ?? 'unknown',
                                  d['description'] as String? ?? ''))
          .toList();

      _patchState((s) => s.copyWith(audioDevices: devices));
      _audioDevicesCtrl.add(devices);
    } catch (e) {
      debugPrint('mpv_audio_kit: failed to parse audio-device-list: $e');
    }
  }

  void _parseCacheState(String jsonStr) {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      final pct = (map['cache-duration'] as num?)?.toDouble() ?? 0.0;
      _patchState((s) => s.copyWith(bufferingPercentage: pct));
      _bufferPctCtrl.add(pct);
    } catch (_) {}
  }

  void _pollPosition() {
    using((arena) {
      final n = 'time-pos'.toNativeUtf8(allocator: arena);
      final buf = arena<Double>();
      final rc = _lib.mpvGetProperty(_handle, n, MpvFormat.mpvFormatDouble, buf.cast());
      if (rc == MpvError.mpvErrorSuccess) {
        final pos = Duration(microseconds: (buf.value * 1e6).round());
        _patchState((s) => s.copyWith(position: pos));
        _positionCtrl.add(pos);
      }
    });
  }

  void _patchState(PlayerState Function(PlayerState) updater) {
    _state = updater(_state);
  }

  // ── Playback API ──────────────────────────────────────────────────────────

  /// Opens a [Media] and optionally starts playback immediately.
  ///
  /// Replaces the entire current playlist with this single track.
  Future<void> open(Media media, {bool? play}) async {
    _checkNotDisposed();
    _mediaCache.clear();
    _mediaCache[media.uri] = media;
    if (media.httpHeaders != null) {
      final headers = media.httpHeaders!.entries.map((e) => '${e.key}: ${e.value}').join(',');
      _opt('http-header-fields', headers);
    }
    
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
    // Note: We use the normalized URI for mpv, but keep original in `_mediaCache`
    // so `AndroidHelper` caches and `playlist` matches.
    // Wait, if mpv returns fd://15 in playlist, `_mediaCache` will NOT match `fd://15`.
    // Let's store BOTH `fd://x` and `asset://` mapping in `_mediaCache`.
    _mediaCache[normalizedUri] = media;
    
    _command(['loadfile', normalizedUri, 'replace']);
    if (!(play ?? configuration.autoPlay)) _prop('pause', 'yes');
  }

  /// Opens a list of [Media] items as the new playlist.
  Future<void> openPlaylist(List<Media> medias, {bool? play}) async {
    _checkNotDisposed();
    if (medias.isEmpty) return;
    _mediaCache.clear();
    for (final m in medias) {
      _mediaCache[m.uri] = m;
      final normalizedUri = await AndroidHelper.normalizeUri(m.uri);
      _mediaCache[normalizedUri] = m;
    }
    
    final firstNormalizedUri = await AndroidHelper.normalizeUri(medias.first.uri);
    _command(['loadfile', firstNormalizedUri, 'replace']);
    
    for (final m in medias.skip(1)) {
      final normalizedUri = await AndroidHelper.normalizeUri(m.uri);
      _command(['loadfile', normalizedUri, 'append']);
    }
    if (!(play ?? configuration.autoPlay)) _prop('pause', 'yes');
  }

  /// Starts or resumes playback.
  Future<void> play() async {
    _checkNotDisposed();
    _prop('pause', 'no');
  }

  /// Pauses playback.
  Future<void> pause() async {
    _checkNotDisposed();
    _prop('pause', 'yes');
  }

  /// Toggles between play and pause.
  Future<void> playOrPause() async {
    _checkNotDisposed();
    _commandString('cycle pause');
  }

  /// Stops playback and unloads the current file.
  Future<void> stop() async {
    _checkNotDisposed();
    _command(['stop']);
  }

  /// Seeks to [position].
  ///
  /// Set [relative] to `true` to seek by an offset from the current position.
  Future<void> seek(Duration position, {bool relative = false}) async {
    _checkNotDisposed();
    final secs = position.inMicroseconds / 1e6;
    _command(['seek', secs.toStringAsFixed(6), relative ? 'relative' : 'absolute']);
  }

  // ── Playlist API ──────────────────────────────────────────────────────────

  /// Appends [media] to the end of the current playlist.
  Future<void> add(Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    if (media.httpHeaders != null) {
      final headers = media.httpHeaders!.entries.map((e) => '${e.key}: ${e.value}').join(',');
      _opt('http-header-fields', headers);
    }
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
    _mediaCache[normalizedUri] = media;
    _command(['loadfile', normalizedUri, 'append']);
  }

  /// Removes the track at [index] from the playlist.
  Future<void> remove(int index) async {
    _checkNotDisposed();
    _command(['playlist-remove', index.toString()]);
  }

  /// Skips to the next track.
  Future<void> next() async {
    _checkNotDisposed();
    _command(['playlist-next']);
  }

  /// Skips to the previous track.
  Future<void> previous() async {
    _checkNotDisposed();
    _command(['playlist-prev']);
  }

  /// Jumps to the track at [index] in the playlist.
  Future<void> jump(int index) async {
    _checkNotDisposed();
    _command(['playlist-play-index', index.toString()]);
  }

  /// Moves the track at [from] to position [to].
  Future<void> move(int from, int to) async {
    _checkNotDisposed();
    _command(['playlist-move', from.toString(), to.toString()]);
  }

  /// Replaces the track at [index] with a new [media] item.
  Future<void> replace(int index, Media media) async {
    _checkNotDisposed();
    _mediaCache[media.uri] = media;
    final normalizedUri = await AndroidHelper.normalizeUri(media.uri);
    _mediaCache[normalizedUri] = media;
    // Complex operation: insert new, move to position, remove old.
    _command(['loadfile', normalizedUri, 'append']);
    // Note: This relies on the internal state for index calculation.
    final lastIndex = _state.playlist.medias.length;
    _command(['playlist-move', lastIndex.toString(), index.toString()]);
    _command(['playlist-remove', (index + 1).toString()]);
  }

  /// Clears all tracks from the playlist.
  Future<void> clearPlaylist() async {
    _checkNotDisposed();
    _mediaCache.clear();
    _command(['playlist-clear']);
  }

  /// Sets the playlist repeat mode.
  Future<void> setPlaylistMode(PlaylistMode mode) async {
    _checkNotDisposed();
    switch (mode) {
      case PlaylistMode.none:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'no');
      case PlaylistMode.single:
        _prop('loop-file', 'inf');
        _prop('loop-playlist', 'no');
      case PlaylistMode.loop:
        _prop('loop-file', 'no');
        _prop('loop-playlist', 'inf');
    }
  }

  /// Enables or disables shuffle mode.
  Future<void> setShuffle(bool shuffle) async {
    _checkNotDisposed();
    _prop('shuffle', shuffle ? 'yes' : 'no');
  }

  // ── Audio API ─────────────────────────────────────────────────────────────

  /// Sets volume (0–100; values above 100 amplify the signal).
  Future<void> setVolume(double volume) async {
    _checkNotDisposed();
    _prop('volume', volume.toStringAsFixed(1));
  }

  /// Sets playback rate (1.0 = normal speed).
  Future<void> setRate(double rate) async {
    _checkNotDisposed();
    _prop('speed', rate.toStringAsFixed(4));
  }

  /// Sets pitch (1.0 = original pitch).
  Future<void> setPitch(double pitch) async {
    _checkNotDisposed();
    _prop('pitch', pitch.toStringAsFixed(4));
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    _checkNotDisposed();
    _prop('mute', mute ? 'yes' : 'no');
  }

  /// Sets the active audio output device.
  Future<void> setAudioDevice(AudioDevice device) async {
    _checkNotDisposed();
    _prop('audio-device', device.name);
  }

  /// Sets the audio output driver (e.g. `'coreaudio'`, `'wasapi'`, `'alsa'`).
  Future<void> setAudioOutputDriver(String driver) async {
    _checkNotDisposed();
    _prop('ao', driver);
  }

  /// Enables or disables pitch correction when changing playback rate.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
  }

  /// Sets audio delay (positive = audio plays later).
  Future<void> setAudioDelay(Duration delay) async {
    _checkNotDisposed();
    final secs = delay.inMicroseconds / 1e6;
    _prop('audio-delay', secs.toStringAsFixed(3));
  }

  /// Enables or disables gapless playback.
  Future<void> setGaplessPlayback(GaplessMode mode) async {
    _checkNotDisposed();
    _prop('gapless-audio', mode.value);
  }

  /// Configures ReplayGain normalization.
  Future<void> setReplayGain(ReplayGainMode mode) async {
    _checkNotDisposed();
    _prop('replaygain', mode.value);
  }

  /// Sets volume gain in dB (pre-amplification).
  Future<void> setVolumeGain(double gainDb) async {
    _checkNotDisposed();
    _prop('volume-gain', gainDb.toStringAsFixed(2));
  }

  /// Sets maximum volume limit (default 130).
  Future<void> setVolumeMax(double max) async {
    _checkNotDisposed();
    _prop('volume-max', max.toStringAsFixed(1));
  }

  /// Pre-amplification in dB applied before ReplayGain normalization.
  Future<void> setReplayGainPreamp(double db) async {
    _checkNotDisposed();
    _prop('replaygain-preamp', db.toStringAsFixed(2));
  }

  /// Whether to allow clipping after ReplayGain.
  Future<void> setReplayGainClip(bool clip) async {
    _checkNotDisposed();
    _prop('replaygain-clip', clip ? 'yes' : 'no');
  }

  /// Gain applied to files without ReplayGain tags.
  Future<void> setReplayGainFallback(double db) async {
    _checkNotDisposed();
    _prop('replaygain-fallback', db.toStringAsFixed(2));
  }

  /// Enables exclusive audio mode (WASAPI / ALSA / CoreAudio).
  Future<void> setAudioExclusive(bool exclusive) async {
    _checkNotDisposed();
    _prop('audio-exclusive', exclusive ? 'yes' : 'no');
  }

  /// Sets HDMI/S/PDIF audio passthrough codecs (e.g. `'ac3,dts'`).
  Future<void> setAudioSpdif(String codecs) async {
    _checkNotDisposed();
    _prop('audio-spdif', codecs);
  }

  /// Selects an audio track by ID.
  Future<void> setAudioTrack(String trackId) async {
    _checkNotDisposed();
    _prop('aid', trackId);
  }

  // ── Audio filter chain ────────────────────────────────────────────────────

  /// Replaces the entire audio filter chain with [filters].
  Future<void> setAudioFilters(List<AudioFilter> filters) async {
    _checkNotDisposed();
    _prop('af', filters.isEmpty ? '' : filters.map((f) => f.value).join(','));
  }

  /// Removes all active audio filters.
  Future<void> clearAudioFilters() => setAudioFilters([]);

  /// Appends a single [filter] to the current filter chain.
  Future<void> addAudioFilter(AudioFilter filter) async {
    _checkNotDisposed();
    _command(['af', 'add', filter.value]);
  }

  // ── Network / Cache API ───────────────────────────────────────────────────

  /// Seconds of network data fetched ahead of the playback position.
  Future<void> setCacheSecs(double seconds) async {
    _checkNotDisposed();
    _prop('cache-secs', seconds.toStringAsFixed(1));
  }

  /// Cache behavior: `'yes'`, `'no'`, or `'auto'`.
  Future<void> setCache(String mode) async {
    _checkNotDisposed();
    _prop('cache', mode);
  }

  /// Whether to spill overflow cache to temporary disk files.
  Future<void> setCacheOnDisk(bool enable) async {
    _checkNotDisposed();
    _prop('cache-on-disk', enable ? 'yes' : 'no');
  }

  /// Sets the audio buffer size in seconds.
  Future<void> setAudioBuffer(double seconds) async {
    _checkNotDisposed();
    _prop('audio-buffer', seconds.toStringAsFixed(3));
  }

  /// Enables or disables streaming silence when no audio is playing.
  Future<void> setStreamSilence(bool enable) async {
    _checkNotDisposed();
    _prop('stream-silence', enable ? 'yes' : 'no');
  }

  /// Whether to automatically pause when the cache runs empty.
  Future<void> setCachePause(bool enable) async {
    _checkNotDisposed();
    _prop('cache-pause', enable ? 'yes' : 'no');
  }

  /// Seconds of pre-buffering required before auto-resuming after a stall.
  Future<void> setCachePauseWait(double seconds) async {
    _checkNotDisposed();
    _prop('cache-pause-wait', seconds.toStringAsFixed(1));
  }

  /// Network connection timeout in seconds.
  Future<void> setNetworkTimeout(double seconds) async {
    _checkNotDisposed();
    _prop('network-timeout', seconds.toString());
  }

  // ── Raw access ────────────────────────────────────────────────────────────

  /// Reads any mpv property as a string. Returns `null` if unavailable.
  String? getRawProperty(String name) {
    _checkNotDisposed();
    return using((arena) {
      final n = name.toNativeUtf8(allocator: arena);
      final ptr = _lib.mpvGetPropertyString(_handle, n);
      if (ptr == nullptr) return null;
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

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _opt(String name, String value) {
    using((arena) {
      _lib.mpvSetOptionString(_handle, name.toNativeUtf8(allocator: arena),
          value.toNativeUtf8(allocator: arena));
    });
  }

  void _prop(String name, String value) {
    using((arena) {
      _lib.mpvSetPropertyString(_handle, name.toNativeUtf8(allocator: arena),
          value.toNativeUtf8(allocator: arena));
    });
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
    using((arena) {
      _lib.mpvCommandString(_handle, cmd.toNativeUtf8(allocator: arena));
    });
  }

  void _observe(String name, int format, int replyId) {
    using((arena) {
      _lib.mpvObserveProperty(
          _handle, replyId, name.toNativeUtf8(allocator: arena), format);
    });
  }

  String _errorString(int code) {
    final p = _lib.mpvErrorString(code);
    if (p == nullptr) return 'error $code';
    return p.cast<Utf8>().toDartString();
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('Player has been disposed');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  /// Releases all native resources and closes event streams.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    
    // Remove from hot-restart tracking
    NativeReferenceHolder.instance.remove(_handle);

    _eventSub?.cancel();
    _eventIsolate.stop();
    _lib.mpvTerminateDestroy(_handle);
    _playlistCtrl.close();
    _playingCtrl.close();
    _completedCtrl.close();
    _positionCtrl.close();
    _durationCtrl.close();
    _volumeCtrl.close();
    _rateCtrl.close();
    _pitchCtrl.close();
    _bufferingCtrl.close();
    _bufferCtrl.close();
    _bufferPctCtrl.close();
    _playlistModeCtrl.close();
    _shuffleCtrl.close();
    _audioParamsCtrl.close();
    _audioBitrateCtrl.close();
    _audioDeviceCtrl.close();
    _audioDevicesCtrl.close();
    _muteCtrl.close();
    _errorCtrl.close();
    _logCtrl.close();
  }
}

// ── Internal playlist entry ───────────────────────────────────────────────────

class _RawPlaylistEntry {
  final String filename;
  final bool current;
  final bool playing;
  final String? title;

  _RawPlaylistEntry({
    required this.filename,
    required this.current,
    required this.playing,
    this.title,
  });

  factory _RawPlaylistEntry.fromJson(Map<String, dynamic> json) =>
      _RawPlaylistEntry(
        filename: json['filename'] as String? ?? '',
        current:  json['current'] == true,
        playing:  json['playing'] == true,
        title:    json['title'] as String?,
      );
}

