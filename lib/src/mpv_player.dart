import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'mpv_bindings.dart';
import 'player_types.dart';

/// Audio player based on libmpv.
///
/// Example:
/// ```dart
/// final player = MpvPlayer();
/// player.stateStream.listen((s) => print(s));
/// await player.open('https://example.com/audio.mp3', play: true);
/// // ...
/// player.dispose();
/// ```
class MpvPlayer {
  final PlayerConfig config;

  late final MpvLibrary _lib;
  late final Pointer<MpvHandle> _handle;
  Timer? _eventTimer;
  bool _disposed = false;

  final _stateCtrl = StreamController<PlayerState>.broadcast();
  final _positionCtrl = StreamController<double>.broadcast();
  final _durationCtrl = StreamController<double?>.broadcast();
  final _volumeCtrl = StreamController<double>.broadcast();
  final _muteCtrl = StreamController<bool>.broadcast();
  final _audioDelayCtrl = StreamController<double>.broadcast();
  final _pitchCtrl = StreamController<double>.broadcast();
  final _mediaInfoCtrl = StreamController<MediaInfo>.broadcast();
  final _logCtrl = StreamController<String>.broadcast();
  final _cacheCtrl = StreamController<double>.broadcast();
  final _bitrateCtrl = StreamController<int?>.broadcast();
  final _audioDeviceListCtrl = StreamController<List<AudioDevice>>.broadcast();

  PlayerState _state = PlayerState.idle;
  double _position = 0.0;
  double? _duration;
  double _volume;
  bool _mute = false;
  double _audioDelay = 0.0;
  double _pitch = 1.0;
  MediaInfo? _mediaInfo;
  double? _lastCacheDuration;
  int? _lastBitrate;

  Stream<PlayerState> get stateStream => _stateCtrl.stream;
  Stream<double> get positionStream => _positionCtrl.stream;
  Stream<double?> get durationStream => _durationCtrl.stream;
  Stream<double> get volumeStream => _volumeCtrl.stream;
  Stream<bool> get muteStream => _muteCtrl.stream;
  Stream<double> get audioDelayStream => _audioDelayCtrl.stream;
  Stream<double> get pitchStream => _pitchCtrl.stream;
  Stream<MediaInfo> get mediaInfoStream => _mediaInfoCtrl.stream;
  Stream<String> get logStream => _logCtrl.stream;
  Stream<double> get cacheStream => _cacheCtrl.stream;
  Stream<int?> get bitrateStream => _bitrateCtrl.stream;
  Stream<List<AudioDevice>> get audioDeviceListStream => _audioDeviceListCtrl.stream;

  PlayerState get state => _state;
  double get position => _position;
  double? get duration => _duration;
  double get volume => _volume;
  bool get mute => _mute;
  double get audioDelay => _audioDelay;
  double get pitch => _pitch;
  MediaInfo? get mediaInfo => _mediaInfo;
  double? get cacheDuration => _lastCacheDuration;
  int? get bitrate => _lastBitrate;
  List<AudioDevice> get audioDeviceList => _parseDeviceList(getAudioDeviceList() ?? '[]');
  bool get isPlaying => _state == PlayerState.playing;
  bool get isPaused => _state == PlayerState.paused;

  MpvPlayer({this.config = const PlayerConfig()})
      : _volume = config.initialVolume {
    _lib = MpvLibrary.open();
    _handle = _lib.mpvCreate();
    if (_handle == nullptr) {
      throw StateError('mpvCreate() returned NULL');
    }
    _applyPreInitOptions();
    final rc = _lib.mpvInitialize(_handle);
    if (rc < 0) {
      _lib.mpvTerminateDestroy(_handle);
      throw StateError('mpvInitialize() failed: ${_errorString(rc)}');
    }
    _applyPostInitOptions();
    _registerObservedProperties();
    _startEventLoop();
  }

  void _applyPreInitOptions() {
    _opt('vid', 'no');
    _opt('vo', 'null');
    _opt('keep-open', 'yes');
    _opt('idle', 'yes');
    if (config.audioOutput != null && config.audioOutput!.isNotEmpty) {
      _opt('ao', config.audioOutput!);
    }
    if (config.logLevel != 'no') {
      using((arena) {
        _lib.mpvRequestLogMessages(
            _handle, config.logLevel.toNativeUtf8(allocator: arena));
      });
    }
  }

  void _applyPostInitOptions() {
    _prop('volume', config.initialVolume.toStringAsFixed(1));
  }

  void _registerObservedProperties() {
    _observe('time-pos', MpvFormat.mpvFormatDouble, 1);
    _observe('duration', MpvFormat.mpvFormatDouble, 2);
    _observe('pause', MpvFormat.mpvFormatFlag, 3);
    _observe('volume', MpvFormat.mpvFormatDouble, 4);
    _observe('idle-active', MpvFormat.mpvFormatFlag, 5);
    _observe('mute', MpvFormat.mpvFormatFlag, 6);
    _observe('audio-delay', MpvFormat.mpvFormatDouble, 7);
    _observe('pitch', MpvFormat.mpvFormatDouble, 8);
    _observe('metadata', MpvFormat.mpvFormatString, 9);
    _observe('demuxer-cache-duration', MpvFormat.mpvFormatDouble, 10);
    _observe('audio-bitrate', MpvFormat.mpvFormatDouble, 11);
    _observe('audio-device-list', MpvFormat.mpvFormatString, 12);
  }

  void _observe(String name, int format, int replyId) {
    using((arena) {
      _lib.mpvObserveProperty(
          _handle, replyId, name.toNativeUtf8(allocator: arena), format);
    });
  }

  // Events polling every 10ms: great reactivity with negligible CPU impact on audio.
  void _startEventLoop() {
    _eventTimer =
        Timer.periodic(const Duration(milliseconds: 10), (_) => _drainEvents());
  }

  void _drainEvents() {
    while (true) {
      final event = _lib.mpvWaitEvent(_handle, 0);
      final id = event.ref.event_id;
      if (id == MpvEventId.mpvEventNone) break;
      _handleEvent(event);
      if (id == MpvEventId.mpvEventShutdown) break;
    }
  }
 
  void _handleEvent(Pointer<MpvEvent> event) {
    final id = event.ref.event_id;
    switch (id) {
      case MpvEventId.mpvEventShutdown:
        _eventTimer?.cancel();
        _updateState(PlayerState.idle);
      case MpvEventId.mpvEventStartFile:
        _updateState(PlayerState.buffering);
      case MpvEventId.mpvEventFileLoaded:
        _updateState(
            config.autoPlay ? PlayerState.playing : PlayerState.paused);
        _emitMediaInfo();
      case MpvEventId.mpvEventEndFile:
        final ef = event.ref.data.cast<MpvEventEndFile>().ref;
        if (ef.error < 0) {
          _updateState(PlayerState.error);
        } else if (ef.reason == MpvEndFileReason.mpvEndFileReasonEof) {
          _updateState(PlayerState.ended);
        } else {
          _updateState(PlayerState.idle);
        }
      case MpvEventId.mpvEventPropertyChange:
        _onPropertyChange(event.ref.data.cast<MpvEventProperty>().ref);
      case MpvEventId.mpvEventSeek:
        _pollPosition();
      case MpvEventId.mpvEventPlaybackRestart:
        _pollPosition();
      case MpvEventId.mpvEventLogMessage:
        _onLogMessage(event.ref.data.cast<MpvEventLogMessage>().ref);
    }
  }

  void _onLogMessage(MpvEventLogMessage msg) {
    final level = msg.level.cast<Utf8>().toDartString();
    final prefix = msg.prefix.cast<Utf8>().toDartString();
    final text = msg.text.cast<Utf8>().toDartString().trimRight();
    final line = 'mpv_audio_kit [$prefix] $level: $text';
    debugPrint(line);
    _logCtrl.add(line);
  }

  void _onPropertyChange(MpvEventProperty prop) {
    final name = prop.name.cast<Utf8>().toDartString();
    switch (name) {
      case 'time-pos':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          final v = prop.data.cast<Double>().value;
          _position = v;
          _positionCtrl.add(v);
        }
      case 'duration':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          _duration = prop.data.cast<Double>().value;
          _durationCtrl.add(_duration);
        }
      case 'pause':
        if (prop.format == MpvFormat.mpvFormatFlag && prop.data != nullptr) {
          final paused = prop.data.cast<Int32>().value == 1;
          if (paused && _state == PlayerState.playing) {
            _updateState(PlayerState.paused);
          } else if (!paused && _state == PlayerState.paused) {
            _updateState(PlayerState.playing);
          }
        }
      case 'volume':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          _volume = prop.data.cast<Double>().value;
          _volumeCtrl.add(_volume);
        }
      case 'mute':
        if (prop.format == MpvFormat.mpvFormatFlag && prop.data != nullptr) {
          _mute = prop.data.cast<Int32>().value == 1;
          _muteCtrl.add(_mute);
        }
      case 'audio-delay':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          _audioDelay = prop.data.cast<Double>().value;
          _audioDelayCtrl.add(_audioDelay);
        }
      case 'pitch':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          _pitch = prop.data.cast<Double>().value;
          _pitchCtrl.add(_pitch);
        }
      case 'metadata':
        // When metadata changes (e.g. ICY tags from a radio), update MediaInfo.
        _emitMediaInfo();
      case 'demuxer-cache-duration':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          _cacheCtrl.add(prop.data.cast<Double>().value);
        }
      case 'audio-bitrate':
        if (prop.format == MpvFormat.mpvFormatDouble &&
            prop.data != nullptr) {
          final bps = prop.data.cast<Double>().value;
          _bitrateCtrl.add(bps > 0 ? (bps / 1).round() : null);
        }
      case 'idle-active':
        if (prop.format == MpvFormat.mpvFormatFlag &&
            prop.data != nullptr &&
            prop.data.cast<Int32>().value == 1) {
          if (_state != PlayerState.error && _state != PlayerState.ended) {
            _updateState(PlayerState.idle);
          }
        }
      case 'audio-device-list':
        if (prop.format == MpvFormat.mpvFormatString && prop.data != nullptr) {
          final jsonStr = prop.data.cast<Pointer<Utf8>>().value.cast<Utf8>().toDartString();
          _audioDeviceListCtrl.add(_parseDeviceList(jsonStr));
        }
    }
  }

  void _pollPosition() {
    using((arena) {
      final n = 'time-pos'.toNativeUtf8(allocator: arena);
      final data = arena<Double>();
      final rc = _lib.mpvGetProperty(
          _handle, n, MpvFormat.mpvFormatDouble, data.cast());
      if (rc == MpvError.mpvErrorSuccess) {
        _position = data.value;
        _positionCtrl.add(_position);
      }
    });
  }

  void _updateState(PlayerState s) {
    if (_state == s) return;
    _state = s;
    _stateCtrl.add(s);
  }

  void _emitMediaInfo() {
    String? gs(String propName) => using((arena) {
          final n = propName.toNativeUtf8(allocator: arena);
          final ptr = _lib.mpvGetPropertyString(_handle, n);
          if (ptr == nullptr) return null;
          final s = ptr.cast<Utf8>().toDartString();
          _lib.mpvFree(ptr.cast());
          return s;
        });

    double? gd(String propName) => using((arena) {
          final n = propName.toNativeUtf8(allocator: arena);
          final buf = arena<Double>();
          final rc = _lib.mpvGetProperty(
              _handle, n, MpvFormat.mpvFormatDouble, buf.cast());
          return rc == MpvError.mpvErrorSuccess ? buf.value : null;
        });

    _mediaInfo = MediaInfo(
      duration: gd('duration'),
      title: gs('media-title') ?? gs('metadata/by-key/Title'),
      artist: gs('metadata/by-key/Artist'),
      album: gs('metadata/by-key/Album'),
      year: gs('metadata/by-key/Date'),
      bitrate: gd('audio-bitrate')?.toInt(),
      sampleRate: gd('audio-params/samplerate')?.toInt(),
      channels: gd('audio-params/channel-count')?.toInt(),
      codec: gs('audio-codec') ?? gs('audio-params/codec'),
    );
    _mediaInfoCtrl.add(_mediaInfo!);
  }

  // ── Playback API ──────────────────────────────────────────────────────────

  /// Loads [url] and starts playback if [play] or [PlayerConfig.autoPlay] is true.
  Future<void> open(String url, {bool? play}) async {
    _checkNotDisposed();
    final shouldPlay = play ?? config.autoPlay;
    _command(['loadfile', url, 'replace']);
    if (!shouldPlay) _prop('pause', 'yes');
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

  /// Toggles play/pause.
  Future<void> playOrPause() async {
    _checkNotDisposed();
    _commandString('cycle pause');
  }

  /// Stops playback and unloads the file.
  Future<void> stop() async {
    _checkNotDisposed();
    _command(['stop']);
  }

  /// Seeks to [seconds] (absolute, or relative if [relative] is true).
  Future<void> seek(double seconds, {bool relative = false}) async {
    _checkNotDisposed();
    _command([
      'seek',
      seconds.toStringAsFixed(3),
      relative ? 'relative' : 'absolute'
    ]);
  }

  // ── Playlist / Queues API ─────────────────────────────────────────────────

  /// Enqueues [url] to the end of the current playback playlist.
  Future<void> enqueue(String url) async {
    _checkNotDisposed();
    _command(['loadfile', url, 'append']);
  }

  /// Skips to the next track in the playlist.
  Future<void> playlistNext() async {
    _checkNotDisposed();
    _command(['playlist-next']);
  }

  /// Skips to the previous track in the playlist.
  Future<void> playlistPrev() async {
    _checkNotDisposed();
    _command(['playlist-prev']);
  }

  /// Clears the entire playlist (leaving the current track playing).
  Future<void> playlistClear() async {
    _checkNotDisposed();
    _command(['playlist-clear']);
  }

  /// Sets loop mode for the current file ("no", "inf", "yes", or "1").
  Future<void> setLoopFile(String mode) async {
    _checkNotDisposed();
    _prop('loop-file', mode);
  }

  /// Sets loop mode for the whole playlist ("no", "inf", "yes", or "force").
  Future<void> setLoopPlaylist(String mode) async {
    _checkNotDisposed();
    _prop('loop-playlist', mode);
  }

  // ── Audio API ─────────────────────────────────────────────────────────────

  /// Sets volume (0-100; values >100 amplify).
  Future<void> setVolume(double vol) async {
    _checkNotDisposed();
    _prop('volume', vol.toStringAsFixed(1));
  }

  /// Sets playback speed (1.0 = normal).
  Future<void> setSpeed(double speed) async {
    _checkNotDisposed();
    _prop('speed', speed.toStringAsFixed(4));
  }

  /// Sets maximum volume limit (e.g. 150.0).
  Future<void> setVolumeMax(double max) async {
    _checkNotDisposed();
    _prop('volume-max', max.toStringAsFixed(1));
  }

  /// Toggles mute.
  Future<void> setMute(bool mute) async {
    _checkNotDisposed();
    _prop('mute', mute ? 'yes' : 'no');
  }

  /// Sets audio delay in seconds.
  Future<void> setAudioDelay(double delay) async {
    _checkNotDisposed();
    _prop('audio-delay', delay.toStringAsFixed(3));
  }

  /// Sets audio pitch.
  Future<void> setPitch(double pitch) async {
    _checkNotDisposed();
    _prop('pitch', pitch.toStringAsFixed(4));
  }

  /// Enables pitch correction when changing speed.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
  }

  /// Enables normalized downmix.
  Future<void> setAudioNormalizeDownmix(bool enable) async {
    _checkNotDisposed();
    _prop('audio-normalize-downmix', enable ? 'yes' : 'no');
  }

  /// Sets audio channels (e.g. 'auto', 'stereo').
  Future<void> setAudioChannels(String channels) async {
    _checkNotDisposed();
    _prop('audio-channels', channels);
  }

  /// Sets audio sample rate in Hz (0 for original).
  Future<void> setAudioSamplerate(int hz) async {
    _checkNotDisposed();
    _prop('audio-samplerate', hz.toString());
  }

  /// Sets audio sample format (e.g. 'auto', 's16', 'f32').
  Future<void> setAudioFormat(String format) async {
    _checkNotDisposed();
    _prop('audio-format', format);
  }

  /// Sets audio exclusive mode (only some APIs like WASAPI or ALSA).
  Future<void> setAudioExclusive(bool exclusive) async {
    _checkNotDisposed();
    _prop('audio-exclusive', exclusive ? 'yes' : 'no');
  }

  /// Sets automatic fallback to "null" output if hardware fails.
  Future<void> setAudioFallbackToNull(bool fallback) async {
    _checkNotDisposed();
    _prop('audio-fallback-to-null', fallback ? 'yes' : 'no');
  }

  /// Sets minimum audio output buffer in seconds (default: 0.2s).
  Future<void> setAudioBuffer(double seconds) async {
    _checkNotDisposed();
    _prop('audio-buffer', seconds.toStringAsFixed(3));
  }

  /// Sends silence packets when paused/ended to keep hardware awake.
  Future<void> setAudioStreamSilence(bool silence) async {
    _checkNotDisposed();
    _prop('audio-stream-silence', silence ? 'yes' : 'no');
  }

  /// Sets the audio client name shown in the system mixer.
  Future<void> setAudioClientName(String name) async {
    _checkNotDisposed();
    _prop('audio-client-name', name);
  }

  /// Sets gapless playback mode ("yes", "no", "weak").
  Future<void> setGaplessAudio(String mode) async {
    _checkNotDisposed();
    _prop('gapless-audio', mode);
  }

  /// Adjusts volume based on ReplayGain tags ("no", "track", "album").
  Future<void> setReplayGain(String mode) async {
    _checkNotDisposed();
    _prop('replaygain', mode);
  }

  /// Pre-amplification gain in dB applied to ReplayGain (default: 0).
  Future<void> setReplayGainPreamp(double db) async {
    _checkNotDisposed();
    _prop('replaygain-preamp', db.toStringAsFixed(2));
  }

  /// Allows or disallows clipping if peaks exceed threshold after ReplayGain.
  Future<void> setReplayGainClip(bool clip) async {
    _checkNotDisposed();
    _prop('replaygain-clip', clip ? 'yes' : 'no');
  }

  /// Gain in dB for files without ReplayGain tags (default: 0).
  Future<void> setReplayGainFallback(double db) async {
    _checkNotDisposed();
    _prop('replaygain-fallback', db.toStringAsFixed(2));
  }

  /// Sets audio device (e.g. 'auto', 'coreaudio/...').
  Future<void> setAudioDevice(String device) async {
    _checkNotDisposed();
    _prop('audio-device', device);
  }

  /// Sets audio output driver (e.g. 'auto', 'coreaudio', 'wasapi', 'alsa', 'null').
  Future<void> setAudioOutputDriver(String driver) async {
    _checkNotDisposed();
    _prop('ao', driver);
  }

  /// Sets HDMI/SPDIF passthrough codecs (e.g. '', 'ac3,dts').
  Future<void> setAudioSpdif(String codecs) async {
    _checkNotDisposed();
    _prop('audio-spdif', codecs);
  }

  /// Selects audio track (e.g. "1", "2", "auto", "no").
  Future<void> setAudioTrack(String trackId) async {
    _checkNotDisposed();
    _prop('aid', trackId);
  }

  /// Applies additional volume gain in dB (e.g. +5.0 or -3.0).
  Future<void> setVolumeGain(double db) async {
    _checkNotDisposed();
    _prop('volume-gain', db.toStringAsFixed(2));
  }

  /// Max limit in dB for global volume gain.
  Future<void> setVolumeGainMax(double db) async {
    _checkNotDisposed();
    _prop('volume-gain-max', db.toStringAsFixed(2));
  }

  /// Min limit in dB for global volume gain.
  Future<void> setVolumeGainMin(double db) async {
    _checkNotDisposed();
    _prop('volume-gain-min', db.toStringAsFixed(2));
  }

  /// Appends an external audio trck to the current file.
  Future<void> addAudioFile(String url) async {
    _checkNotDisposed();
    _prop('audio-files-append', url);
  }

  /// Enables hardware downmix in the decoder if supported (e.g. AC-3/DTS to stereo).
  Future<void> setAudioDecoderDownmix(bool enabled) async {
    _checkNotDisposed();
    _prop('ad-lavc-downmix', enabled ? 'yes' : 'no');
  }

  /// Replaces the entire audio filter chain.
  Future<void> setAudioFilters(List<AudioFilter> filters) async {
    _checkNotDisposed();
    _prop('af', filters.isEmpty ? '' : filters.map((f) => f.value).join(','));
  }

  /// Removes all active audio filters.
  Future<void> clearAudioFilters() => setAudioFilters([]);

  /// Appends a filter to the current chain.
  Future<void> addAudioFilter(AudioFilter filter) async {
    _checkNotDisposed();
    _command(['af', 'add', filter.value]);
  }

  /// Returns the raw JSON device list for the current driver.
  String? getAudioDeviceList() {
    _checkNotDisposed();
    return getRawProperty('audio-device-list');
  }

  // ── Network & Cache API ───────────────────────────────────────────────────

  /// Sets network connection timeout limit.
  Future<void> setNetworkTimeout(double seconds) async {
    _checkNotDisposed();
    _prop('network-timeout', seconds.toString());
  }

  /// Enables/disables YouTube-DL/yt-dlp integration.
  Future<void> setYtdl(bool enable) async {
    _checkNotDisposed();
    _prop('ytdl', enable ? 'yes' : 'no');
  }

  /// Sets cache duration in seconds for network streams.
  Future<void> setCacheSecs(double seconds) async {
    _checkNotDisposed();
    _prop('cache-secs', seconds.toStringAsFixed(1));
  }

  /// Sets cache behavior (e.g. "yes", "no", "auto").
  Future<void> setCache(String mode) async {
    _checkNotDisposed();
    _prop('cache', mode);
  }

  /// Whether to write cache to temporary files on disk.
  Future<void> setCacheOnDisk(bool enable) async {
    _checkNotDisposed();
    _prop('cache-on-disk', enable ? 'yes' : 'no');
  }

  /// Seconds of pre-buffering before playback starts/resumes.
  Future<void> setCachePauseWait(double seconds) async {
    _checkNotDisposed();
    _prop('cache-pause-wait', seconds.toStringAsFixed(1));
  }

  /// Enables automatic pausing for network buffering.
  Future<void> setCachePause(bool enable) async {
    _checkNotDisposed();
    _prop('cache-pause', enable ? 'yes' : 'no');
  }

  // ── Raw access ────────────────────────────────────────────────────────────

  void setRawProperty(String name, String value) {
    _checkNotDisposed();
    _prop(name, value);
  }

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
      // mpv_command expects const char** — pass arr directly.
      _lib.mpvCommand(_handle, arr);
    });
  }

  void _commandString(String cmd) {
    using((arena) {
      _lib.mpvCommandString(_handle, cmd.toNativeUtf8(allocator: arena));
    });
  }

  String _errorString(int code) {
    final p = _lib.mpvErrorString(code);
    if (p == nullptr) return 'error $code';
    return p.cast<Utf8>().toDartString();
  }

  void _checkNotDisposed() {
    if (_disposed) throw StateError('MpvPlayer has been disposed');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  /// Stops playback, releases mpv handle and closes all streams.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _eventTimer?.cancel();
    _lib.mpvTerminateDestroy(_handle);
    _stateCtrl.close();
    _positionCtrl.close();
    _durationCtrl.close();
    _volumeCtrl.close();
    _muteCtrl.close();
    _audioDelayCtrl.close();
    _pitchCtrl.close();
    _mediaInfoCtrl.close();
    _logCtrl.close();
    _audioDeviceListCtrl.close();
  }

  List<AudioDevice> _parseDeviceList(String jsonStr) {
    try {
      final List<dynamic> list = json.decode(jsonStr);
      return list.map((d) {
        return AudioDevice(
          name: d['name'] ?? 'unknown',
          description: d['description'] ?? 'No description',
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing audio-device-list: $e');
      return [];
    }
  }
}
