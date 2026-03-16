// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Registry-based property handling system.
///
/// Instead of hardcoded switch blocks, properties are dispatched
/// by name to their respective handlers.
mixin _PropertyRegistry on _PlayerBase {
  @override
  void _handleDoubleProperty(String name, double value) {
    switch (name) {
      case 'time-pos':
      case '_seek':
        _updatePosition(value);
      case 'duration':
        _updateDuration(value);
      case 'volume':
        _updateState((s) => s.copyWith(volume: value), _volumeCtrl, value);
      case 'speed':
        _updateState((s) => s.copyWith(rate: value), _rateCtrl, value);
      case 'pitch':
        _updateState((s) => s.copyWith(pitch: value), _pitchCtrl, value);
      case 'demuxer-cache-time':
        _updateBuffer(value);
      case 'audio-bitrate':
        _updateBitrate(value);
      case 'audio-params/samplerate':
        _updateAudioParams((p) => p.copyWith(sampleRate: value.toInt()));
      case 'audio-params/channel-count':
        _updateAudioParams((p) => p.copyWith(channelCount: value.toInt()));
      case 'audio-out-params/samplerate':
        _updateAudioOutParams((p) => p.copyWith(sampleRate: value.toInt()));
      case 'audio-out-params/channel-count':
        _updateAudioOutParams((p) => p.copyWith(channelCount: value.toInt()));
      case 'audio-delay':
        _updateState(
            (s) => s.copyWith(audioDelay: value), _audioDelayCtrl, value);
      case 'replaygain-preamp':
        _updateState((s) => s.copyWith(replayGainPreamp: value),
            _replayGainPreampCtrl, value);
      case 'replaygain-fallback':
        _updateState((s) => s.copyWith(replayGainFallback: value),
            _replayGainFallbackCtrl, value);
      case 'volume-gain':
        _updateState(
            (s) => s.copyWith(volumeGain: value), _volumeGainCtrl, value);
      case 'cache-secs':
        _updateState(
            (s) => s.copyWith(cacheSecs: value), _cacheSecsCtrl, value);
      case 'cache-pause-wait':
        _updateState((s) => s.copyWith(cachePauseWait: value),
            _cachePauseWaitCtrl, value);
      case 'network-timeout':
        _updateState((s) => s.copyWith(networkTimeout: value),
            _networkTimeoutCtrl, value);
      case 'audio-buffer':
        _updateState(
            (s) => s.copyWith(audioBuffer: value), _audioBufferCtrl, value);
      case 'volume-max':
        _updateState(
            (s) => s.copyWith(volumeMax: value), _volumeMaxCtrl, value);
    }
  }

  @override
  void _handleIntProperty(String name, int value) {
    final flag = value == 1;
    switch (name) {
      case 'pause':
        _updateState((s) => s.copyWith(playing: !flag), _playingCtrl, !flag);
        if (!flag) {
          _scheduleAudioOutputCheck();
        }
      case 'mute':
        _updateState((s) => s.copyWith(mute: flag), _muteCtrl, flag);
      case 'idle-active':
        if (flag) {
          _updateState(
              (s) => s.copyWith(playing: false, buffering: false),
              _playingCtrl,
              false);
        }
      case 'shuffle':
        _updateState((s) => s.copyWith(shuffle: flag), _shuffleCtrl, flag);
      case 'audio-pitch-correction':
        _updateState((s) => s.copyWith(pitchCorrection: flag),
            _pitchCorrectionCtrl, flag);
      case 'replaygain-clip':
        _updateState(
            (s) => s.copyWith(replayGainClip: flag), _replayGainClipCtrl, flag);
      case 'cache-on-disk':
        _updateState(
            (s) => s.copyWith(cacheOnDisk: flag), _cacheOnDiskCtrl, flag);
      case 'cache-pause':
        _updateState(
            (s) => s.copyWith(cachePause: flag), _cachePauseCtrl, flag);
      case 'tls-verify':
        _updateState((s) => s.copyWith(tlsVerify: flag), _tlsVerifyCtrl, flag);
      case 'demuxer-max-bytes':
        _updateState((s) => s.copyWith(demuxerMaxBytes: value),
            _demuxerMaxBytesCtrl, value);
      case 'demuxer-readahead-secs':
        _updateState((s) => s.copyWith(demuxerReadaheadSecs: value),
            _demuxerReadaheadSecsCtrl, value);
      case 'demuxer-max-back-bytes':
        _updateState((s) => s.copyWith(demuxerMaxBackBytes: value),
            _demuxerMaxBackBytesCtrl, value);
      case 'audio-exclusive':
        _updateState(
            (s) => s.copyWith(audioExclusive: flag), _audioExclusiveCtrl, flag);
      case 'stream-silence':
        _updateState(
            (s) => s.copyWith(streamSilence: flag), _streamSilenceCtrl, flag);
      case 'ao-null-untimed':
        _updateState(
            (s) => s.copyWith(aoNullUntimed: flag), _aoNullUntimedCtrl, flag);
      case 'audio-samplerate':
        _updateState((s) => s.copyWith(audioSampleRate: value),
            _audioSampleRateCtrl, value);
    }
  }

  @override
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
        _updateState(
            (s) => s.copyWith(audioDevice: device), _audioDeviceCtrl, device);
      case 'audio-params/format':
        _updateAudioParams((p) => p.copyWith(format: value));
      case 'audio-params/channels':
        _updateAudioParams((p) => p.copyWith(channels: value));
      case 'audio-params/hr-channels':
        _updateAudioParams((p) => p.copyWith(hrChannels: value));
      case 'audio-codec':
        _updateAudioParams((p) => p.copyWith(codec: value));
      case 'audio-codec-name':
        _updateAudioParams((p) => p.copyWith(codecName: value));
      case 'audio-out-params/format':
        _updateAudioOutParams((p) => p.copyWith(format: value));
      case 'audio-out-params/channels':
        _updateAudioOutParams((p) => p.copyWith(channels: value));
      case 'audio-out-params/hr-channels':
        _updateAudioOutParams((p) => p.copyWith(hrChannels: value));
      case 'metadata':
        _updateMetadata(value);
      case 'gapless-audio':
        _updateState(
            (s) => s.copyWith(gaplessMode: value), _gaplessModeCtrl, value);
      case 'replaygain':
        _updateState((s) => s.copyWith(replayGainMode: value),
            _replayGainModeCtrl, value);
      case 'cache':
        _updateState(
            (s) => s.copyWith(cacheMode: value), _cacheModeCtrl, value);
      case 'aid':
        _updateState(
            (s) => s.copyWith(audioTrack: value), _audioTrackCtrl, value);
      case 'audio-spdif':
        _updateState(
            (s) => s.copyWith(audioSpdif: value), _audioSpdifCtrl, value);
      case 'audio-format':
        _updateState(
            (s) => s.copyWith(audioFormat: value), _audioFormatCtrl, value);
      case 'audio-channels':
        _updateState(
            (s) => s.copyWith(audioChannels: value), _audioChannelsCtrl, value);
      case 'audio-client-name':
        _updateState((s) => s.copyWith(audioClientName: value),
            _audioClientNameCtrl, value);
      case 'af':
        final filters =
            value.split(',').where((e) => e.isNotEmpty).map((e) => AudioFilter.custom(e)).toList();
        _updateState((s) => s.copyWith(activeFilters: filters),
            _activeFiltersCtrl, filters);
      case 'demuxer-cache-state':
        _parseCacheState(value);
    }
  }

  @override
  void _registerObservedProperties() {
    // Basic Playback
    _observe('time-pos', MpvFormat.mpvFormatDouble, 1);
    _observe('duration', MpvFormat.mpvFormatDouble, 2);
    _observe('pause', MpvFormat.mpvFormatFlag, 3);
    _observe('volume', MpvFormat.mpvFormatDouble, 4);
    _observe('idle-active', MpvFormat.mpvFormatFlag, 5);
    _observe('mute', MpvFormat.mpvFormatFlag, 6);
    _observe('pitch', MpvFormat.mpvFormatDouble, 7);
    _observe('speed', MpvFormat.mpvFormatDouble, 8);
    _observe('shuffle', MpvFormat.mpvFormatFlag, 14);

    // Playback Mechanics
    _observe('demuxer-cache-time', MpvFormat.mpvFormatDouble, 9);
    _observe('demuxer-cache-state', MpvFormat.mpvFormatString, 10);
    _observe('audio-bitrate', MpvFormat.mpvFormatDouble, 11);
    _observe('playlist', MpvFormat.mpvFormatString, 17);
    _observe('loop-file', MpvFormat.mpvFormatString, 15);
    _observe('loop-playlist', MpvFormat.mpvFormatString, 16);
    _observe('metadata', MpvFormat.mpvFormatString, 32);

    // Audio Output & Routing
    _observe('audio-device-list', MpvFormat.mpvFormatString, 12);
    _observe('audio-device', MpvFormat.mpvFormatString, 13);
    _observe('audio-delay', MpvFormat.mpvFormatDouble, 30);
    _observe('audio-pitch-correction', MpvFormat.mpvFormatFlag, 31);

    // Track Source Parameters (Decoder)
    _observe('audio-params/format', MpvFormat.mpvFormatString, 18);
    _observe('audio-params/samplerate', MpvFormat.mpvFormatDouble, 19);
    _observe('audio-params/channels', MpvFormat.mpvFormatString, 20);
    _observe('audio-params/channel-count', MpvFormat.mpvFormatDouble, 21);
    _observe('audio-params/hr-channels', MpvFormat.mpvFormatString, 22);
    _observe('audio-codec', MpvFormat.mpvFormatString, 23);
    _observe('audio-codec-name', MpvFormat.mpvFormatString, 29);

    // Hardware Output Parameters (Device)
    _observe('audio-out-params/format', MpvFormat.mpvFormatString, 24);
    _observe('audio-out-params/samplerate', MpvFormat.mpvFormatDouble, 25);
    _observe('audio-out-params/channels', MpvFormat.mpvFormatString, 26);
    _observe('audio-out-params/channel-count', MpvFormat.mpvFormatDouble, 27);
    _observe('audio-out-params/hr-channels', MpvFormat.mpvFormatString, 28);

    // Advanced Audio & Normalization
    _observe('gapless-audio', MpvFormat.mpvFormatString, 34);
    _observe('replaygain', MpvFormat.mpvFormatString, 35);
    _observe('replaygain-preamp', MpvFormat.mpvFormatDouble, 36);
    _observe('replaygain-fallback', MpvFormat.mpvFormatDouble, 37);
    _observe('replaygain-clip', MpvFormat.mpvFormatFlag, 38);
    _observe('volume-gain', MpvFormat.mpvFormatDouble, 39);

    // Network & Cache
    _observe('cache', MpvFormat.mpvFormatString, 40);
    _observe('cache-secs', MpvFormat.mpvFormatDouble, 41);
    _observe('cache-on-disk', MpvFormat.mpvFormatFlag, 42);
    _observe('cache-pause', MpvFormat.mpvFormatFlag, 43);
    _observe('cache-pause-wait', MpvFormat.mpvFormatDouble, 44);
    _observe('demuxer-max-bytes', MpvFormat.mpvFormatInt64, 45);
    _observe('demuxer-readahead-secs', MpvFormat.mpvFormatInt64, 46);
    _observe('demuxer-max-back-bytes', MpvFormat.mpvFormatInt64, 47);
    _observe('network-timeout', MpvFormat.mpvFormatDouble, 48);
    _observe('tls-verify', MpvFormat.mpvFormatFlag, 49);
    _observe('audio-buffer', MpvFormat.mpvFormatDouble, 50);
    _observe('audio-exclusive', MpvFormat.mpvFormatFlag, 51);
    _observe('stream-silence', MpvFormat.mpvFormatFlag, 52);
    _observe('ao-null-untimed', MpvFormat.mpvFormatFlag, 53);
    _observe('aid', MpvFormat.mpvFormatString, 54);
    _observe('audio-spdif', MpvFormat.mpvFormatString, 55);
    _observe('volume-max', MpvFormat.mpvFormatDouble, 56);
    _observe('audio-samplerate', MpvFormat.mpvFormatInt64, 57);
    _observe('audio-format', MpvFormat.mpvFormatString, 58);
    _observe('audio-channels', MpvFormat.mpvFormatString, 59);
    _observe('audio-client-name', MpvFormat.mpvFormatString, 60);
    _observe('af', MpvFormat.mpvFormatString, 61);
  }

  // --- Specialized Update Helpers ---

  void _updatePosition(double value) {
    final pos = Duration(microseconds: (value * 1e6).round());
    _updateState((s) => s.copyWith(position: pos), _positionCtrl, pos);
  }

  void _updateDuration(double value) {
    final dur = Duration(microseconds: (value * 1e6).round());
    _updateState((s) => s.copyWith(duration: dur), _durationCtrl, dur);
  }

  void _updateBuffer(double value) {
    final buf = Duration(microseconds: (value * 1e6).round());
    _updateState((s) => s.copyWith(buffer: buf), _bufferCtrl, buf);
  }

  void _updateBitrate(double value) {
    final bps = value > 0 ? value : null;
    _updateState((s) => s.copyWith(audioBitrate: bps), _audioBitrateCtrl, bps);
  }
}
