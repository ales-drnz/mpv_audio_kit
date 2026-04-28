// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Module for comprehensive audio control, DSP, and hardware synchronization.
mixin _AudioModule on _PlayerBase {
  /// Sets volume (0–100; values above 100 amplify the signal).
  Future<void> setVolume(double volume) async {
    _checkNotDisposed();
    _prop('volume', volume.toStringAsFixed(1));
    _updateField((s) => s.copyWith(volume: volume), _reactives.volume, volume);
  }

  /// Sets playback rate (1.0 = normal speed).
  Future<void> setRate(double rate) async {
    _checkNotDisposed();
    _prop('speed', rate.toStringAsFixed(4));
    _updateField((s) => s.copyWith(rate: rate), _reactives.rate, rate);
  }

  /// Sets pitch (1.0 = original pitch).
  Future<void> setPitch(double pitch) async {
    _checkNotDisposed();
    _prop('pitch', pitch.toStringAsFixed(4));
    _updateField((s) => s.copyWith(pitch: pitch), _reactives.pitch, pitch);
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    _checkNotDisposed();
    _prop('mute', mute ? 'yes' : 'no');
    _updateField((s) => s.copyWith(mute: mute), _reactives.mute, mute);
  }

  /// Sets the active audio output device.
  Future<void> setAudioDevice(AudioDevice device) async {
    _checkNotDisposed();
    _prop('audio-device', device.name);
    _updateField((s) => s.copyWith(audioDevice: device), _reactives.audioDevice, device);
  }

  /// Whether to enable pitch correction ("scaletempo") when playback rate is changed.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(pitchCorrection: enable), _reactives.pitchCorrection, enable);
  }

  /// Sets the audio delay (positive: delay audio, negative: advance it).
  ///
  /// Resolution is millisecond-rounded — sub-millisecond precision is
  /// stripped before the value is sent to mpv.
  Future<void> setAudioDelay(Duration delay) async {
    _checkNotDisposed();
    _prop('audio-delay', durationToSeconds(delay).toStringAsFixed(3));
    _updateField(
        (s) => s.copyWith(audioDelay: delay), _reactives.audioDelay, delay);
  }

  /// Enables or disables gapless playback. See [GaplessMode] for the
  /// available variants.
  Future<void> setGaplessMode(GaplessMode mode) async {
    _checkNotDisposed();
    _prop('gapless-audio', mode.mpvValue);
    _updateField(
        (s) => s.copyWith(gaplessMode: mode), _reactives.gaplessMode, mode);
  }

  /// Configures ReplayGain normalization. See [ReplayGainMode] for the
  /// available variants.
  Future<void> setReplayGainMode(ReplayGainMode mode) async {
    _checkNotDisposed();
    _prop('replaygain', mode.mpvValue);
    _updateField((s) => s.copyWith(replayGainMode: mode),
        _reactives.replayGainMode, mode);
  }

  /// Sets volume gain in dB (pre-amplification).
  Future<void> setVolumeGain(double gainDb) async {
    _checkNotDisposed();
    _prop('volume-gain', gainDb.toStringAsFixed(2));
    _updateField((s) => s.copyWith(volumeGain: gainDb), _reactives.volumeGain, gainDb);
  }

  /// Sets maximum volume limit (default 130).
  Future<void> setVolumeMax(double max) async {
    _checkNotDisposed();
    _prop('volume-max', max.toStringAsFixed(1));
    _updateField((s) => s.copyWith(volumeMax: max), _reactives.volumeMax, max);
  }

  /// Pre-amplification in dB applied before ReplayGain normalization.
  Future<void> setReplayGainPreamp(double db) async {
    _checkNotDisposed();
    _prop('replaygain-preamp', db.toStringAsFixed(2));
    _updateField((s) => s.copyWith(replayGainPreamp: db), _reactives.replayGainPreamp, db);
  }

  /// Whether to allow clipping after ReplayGain.
  Future<void> setReplayGainClip(bool clip) async {
    _checkNotDisposed();
    _prop('replaygain-clip', clip ? 'yes' : 'no');
    _updateField((s) => s.copyWith(replayGainClip: clip), _reactives.replayGainClip, clip);
  }

  /// Gain applied to files without ReplayGain tags.
  Future<void> setReplayGainFallback(double db) async {
    _checkNotDisposed();
    _prop('replaygain-fallback', db.toStringAsFixed(2));
    _updateField((s) => s.copyWith(replayGainFallback: db), _reactives.replayGainFallback, db);
  }

  /// Enables exclusive audio mode (WASAPI / ALSA / CoreAudio).
  Future<void> setAudioExclusive(bool exclusive) async {
    _checkNotDisposed();
    _prop('audio-exclusive', exclusive ? 'yes' : 'no');
    _updateField((s) => s.copyWith(audioExclusive: exclusive), _reactives.audioExclusive, exclusive);
  }

  /// Sets HDMI/S/PDIF audio passthrough codecs (e.g. `'ac3,dts'`).
  Future<void> setAudioSpdif(String codecs) async {
    _checkNotDisposed();
    _prop('audio-spdif', codecs);
    _updateField((s) => s.copyWith(audioSpdif: codecs), _reactives.audioSpdif, codecs);
  }

  /// Selects an audio track by ID.
  Future<void> setAudioTrack(String trackId) async {
    _checkNotDisposed();
    _prop('aid', trackId);
    _updateField((s) => s.copyWith(audioTrack: trackId), _reactives.audioTrack, trackId);
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    _checkNotDisposed();
    _command(['ao-reload']);
  }

  /// Replaces the entire audio filter chain with [filters].
  Future<void> setActiveFilters(List<AudioFilter> filters) async {
    _checkNotDisposed();
    final afString = filters.isEmpty ? '' : filters.map((f) => f.value).join(',');
    _prop('af', afString);
    _updateField(
        (s) => s.copyWith(activeFilters: filters), _reactives.activeFilters, filters);
  }

  /// Sets the 10-band equalizer gains and updates the internal state.
  ///
  /// **Note**: this does *not* re-apply the audio filter chain. After
  /// calling this, invoke [setAudioFilters] (typically with
  /// `AudioFilter.equalizer(state.equalizerGains)`) to commit the new
  /// gains to mpv. The split exists so consumers can debounce slider
  /// drags without rebuilding the filter chain on every tick.
  ///
  /// The signature is `Future<void> async` for symmetry with every other
  /// setter, even though no async work is performed — the `await` is a
  /// no-op but lets call-sites use the same `await player.setX(...)`
  /// pattern uniformly.
  Future<void> setEqualizerGains(List<double> gains) async {
    _checkNotDisposed();
    final copy = List<double>.from(gains);
    _updateField(
        (s) => s.copyWith(equalizerGains: copy), _equalizerGains, copy);
  }

  /// Removes all active audio filters.
  Future<void> clearAudioFilters() => setActiveFilters([]);

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Controls how mpv handles embedded and external cover images. See
  /// [AudioDisplayMode] for the available variants.
  ///
  /// Has no effect on files that already have a normal video track.
  /// Changes take effect on the next [open] call.
  Future<void> setAudioDisplayMode(AudioDisplayMode mode) async {
    _checkNotDisposed();
    _prop('audio-display', mode.mpvValue);
    _updateField(
        (s) => s.copyWith(audioDisplayMode: mode), _reactives.audioDisplayMode, mode);
  }

  /// Controls whether mpv automatically loads external cover art files.
  /// See [CoverArtAutoMode] for the available variants.
  Future<void> setCoverArtAutoMode(CoverArtAutoMode mode) async {
    _checkNotDisposed();
    _prop('cover-art-auto', mode.mpvValue);
    _updateField(
        (s) => s.copyWith(coverArtAutoMode: mode), _reactives.coverArtAutoMode, mode);
  }

  /// Sets how long (in seconds) an image frame (e.g. cover art) is held as a
  /// displayable video frame after the file is loaded. Pass `'inf'`
  /// (default) to keep the frame alive indefinitely or `'0'` to drop it as
  /// soon as audio playback starts. Mirrors mpv's
  /// `--image-display-duration` option.
  Future<void> setImageDisplayDuration(String duration) async {
    _checkNotDisposed();
    _prop('image-display-duration', duration);
    _updateField((s) => s.copyWith(imageDisplayDuration: duration),
        _reactives.imageDisplayDuration, duration);
  }

  /// Appends a single [filter] to the current filter chain.
  Future<void> addAudioFilter(AudioFilter filter) async {
    _checkNotDisposed();
    _command(['af', 'add', filter.value]);
  }

  /// Sets the target audio sample rate.
  Future<void> setAudioSampleRate(int rate) async {
    _checkNotDisposed();
    _prop('audio-samplerate', rate.toString());
    _updateField((s) => s.copyWith(audioSampleRate: rate), _reactives.audioSampleRate, rate);
  }

  /// Sets the target audio output format.
  Future<void> setAudioFormat(String format) async {
    _checkNotDisposed();
    _prop('audio-format', format);
    _updateField((s) => s.copyWith(audioFormat: format), _reactives.audioFormat, format);
  }

  /// Sets the target audio channel layout.
  Future<void> setAudioChannels(String channels) async {
    _checkNotDisposed();
    _prop('audio-channels', channels);
    _updateField((s) => s.copyWith(audioChannels: channels), _reactives.audioChannels, channels);
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    _checkNotDisposed();
    _prop('audio-client-name', name);
    _updateField((s) => s.copyWith(audioClientName: name), _reactives.audioClientName, name);
  }

  /// Sets the audio output driver (e.g. 'auto', 'coreaudio', 'pulse', 'alsa', 'wasapi').
  Future<void> setAudioDriver(String driver) async {
    _checkNotDisposed();
    _prop('ao', driver);
    _updateField((s) => s.copyWith(audioDriver: driver), _reactives.audioDriver, driver);
  }
}
