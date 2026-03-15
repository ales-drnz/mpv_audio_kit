part of '../player.dart';

/// Module for comprehensive audio control, DSP, and hardware synchronization.
mixin _AudioModule on _PlayerBase {
  /// Sets volume (0–100; values above 100 amplify the signal).
  Future<void> setVolume(double volume) async {
    _checkNotDisposed();
    _prop('volume', volume.toStringAsFixed(1));
    _updateState((s) => s.copyWith(volume: volume), _volumeCtrl, volume);
  }

  /// Sets playback rate (1.0 = normal speed).
  Future<void> setRate(double rate) async {
    _checkNotDisposed();
    _prop('speed', rate.toStringAsFixed(4));
    _updateState((s) => s.copyWith(rate: rate), _rateCtrl, rate);
  }

  /// Sets pitch (1.0 = original pitch).
  Future<void> setPitch(double pitch) async {
    _checkNotDisposed();
    _prop('pitch', pitch.toStringAsFixed(4));
    _updateState((s) => s.copyWith(pitch: pitch), _pitchCtrl, pitch);
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    _checkNotDisposed();
    _prop('mute', mute ? 'yes' : 'no');
    _updateState((s) => s.copyWith(mute: mute), _muteCtrl, mute);
  }

  /// Sets the active audio output device.
  Future<void> setAudioDevice(AudioDevice device) async {
    _checkNotDisposed();
    _prop('audio-device', device.name);
    _updateState((s) => s.copyWith(audioDevice: device), _audioDeviceCtrl, device);
  }

  /// Whether to enable pitch correction ("scaletempo") when playback rate is changed.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateState((s) => s.copyWith(pitchCorrection: enable), _pitchCorrectionCtrl, enable);
  }

  /// Sets the audio delay in seconds (e.g. `0.05` for 50ms).
  Future<void> setAudioDelay(double seconds) async {
    _checkNotDisposed();
    _prop('audio-delay', seconds.toStringAsFixed(3));
    _updateState((s) => s.copyWith(audioDelay: seconds), _audioDelayCtrl, seconds);
  }

  /// Enables or disables gapless playback ('no', 'yes', 'weak').
  Future<void> setGaplessPlayback(String mode) async {
    _checkNotDisposed();
    _prop('gapless-audio', mode);
    _updateState((s) => s.copyWith(gaplessMode: mode), _gaplessModeCtrl, mode);
  }

  /// Configures ReplayGain normalization ('no', 'track', 'album').
  Future<void> setReplayGain(String mode) async {
    _checkNotDisposed();
    _prop('replaygain', mode);
    _updateState((s) => s.copyWith(replayGainMode: mode), _replayGainModeCtrl, mode);
  }

  /// Sets volume gain in dB (pre-amplification).
  Future<void> setVolumeGain(double gainDb) async {
    _checkNotDisposed();
    _prop('volume-gain', gainDb.toStringAsFixed(2));
    _updateState((s) => s.copyWith(volumeGain: gainDb), _volumeGainCtrl, gainDb);
  }

  /// Sets maximum volume limit (default 130).
  Future<void> setVolumeMax(double max) async {
    _checkNotDisposed();
    _prop('volume-max', max.toStringAsFixed(1));
    _updateState((s) => s.copyWith(volumeMax: max), _volumeMaxCtrl, max);
  }

  /// Pre-amplification in dB applied before ReplayGain normalization.
  Future<void> setReplayGainPreamp(double db) async {
    _checkNotDisposed();
    _prop('replaygain-preamp', db.toStringAsFixed(2));
    _updateState((s) => s.copyWith(replayGainPreamp: db), _replayGainPreampCtrl, db);
  }

  /// Whether to allow clipping after ReplayGain.
  Future<void> setReplayGainClip(bool clip) async {
    _checkNotDisposed();
    _prop('replaygain-clip', clip ? 'yes' : 'no');
    _updateState((s) => s.copyWith(replayGainClip: clip), _replayGainClipCtrl, clip);
  }

  /// Gain applied to files without ReplayGain tags.
  Future<void> setReplayGainFallback(double db) async {
    _checkNotDisposed();
    _prop('replaygain-fallback', db.toStringAsFixed(2));
    _updateState((s) => s.copyWith(replayGainFallback: db), _replayGainFallbackCtrl, db);
  }

  /// Enables exclusive audio mode (WASAPI / ALSA / CoreAudio).
  Future<void> setAudioExclusive(bool exclusive) async {
    _checkNotDisposed();
    _prop('audio-exclusive', exclusive ? 'yes' : 'no');
    _updateState((s) => s.copyWith(audioExclusive: exclusive), _audioExclusiveCtrl, exclusive);
  }

  /// Sets HDMI/S/PDIF audio passthrough codecs (e.g. `'ac3,dts'`).
  Future<void> setAudioSpdif(String codecs) async {
    _checkNotDisposed();
    _prop('audio-spdif', codecs);
    _updateState((s) => s.copyWith(audioSpdif: codecs), _audioSpdifCtrl, codecs);
  }

  /// Selects an audio track by ID.
  Future<void> setAudioTrack(String trackId) async {
    _checkNotDisposed();
    _prop('aid', trackId);
    _updateState((s) => s.copyWith(audioTrack: trackId), _audioTrackCtrl, trackId);
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    _checkNotDisposed();
    _command(['ao-reload']);
  }

  /// Replaces the entire audio filter chain with [filters].
  Future<void> setAudioFilters(List<AudioFilter> filters) async {
    _checkNotDisposed();
    final afString = filters.isEmpty ? '' : filters.map((f) => f.value).join(',');
    _prop('af', afString);
    _state = _state.copyWith(activeFilters: filters);
    _activeFiltersCtrl.add(filters);
  }

  /// Sets the 10-band equalizer gains and updates the internal state.
  /// Note: This does not automatically re-apply filters; call [setAudioFilters] or
  /// individual filter triggers to commit.
  void setEqualizerGains(List<double> gains) {
    _state = _state.copyWith(equalizerGains: List.from(gains));
    _equalizerGainsCtrl.add(_state.equalizerGains);
  }

  /// Removes all active audio filters.
  Future<void> clearAudioFilters() => setAudioFilters([]);

  /// Appends a single [filter] to the current filter chain.
  Future<void> addAudioFilter(AudioFilter filter) async {
    _checkNotDisposed();
    _command(['af', 'add', filter.value]);
  }

  /// Sets the target audio sample rate.
  Future<void> setAudioSampleRate(int rate) async {
    _checkNotDisposed();
    _prop('audio-samplerate', rate.toString());
    _updateState((s) => s.copyWith(audioSampleRate: rate), _audioSampleRateCtrl, rate);
  }

  /// Sets the target audio output format.
  Future<void> setAudioFormat(String format) async {
    _checkNotDisposed();
    _prop('audio-format', format);
    _updateState((s) => s.copyWith(audioFormat: format), _audioFormatCtrl, format);
  }

  /// Sets the target audio channel layout.
  Future<void> setAudioChannels(String channels) async {
    _checkNotDisposed();
    _prop('audio-channels', channels);
    _updateState((s) => s.copyWith(audioChannels: channels), _audioChannelsCtrl, channels);
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    _checkNotDisposed();
    _prop('audio-client-name', name);
    _updateState((s) => s.copyWith(audioClientName: name), _audioClientNameCtrl, name);
  }
}
