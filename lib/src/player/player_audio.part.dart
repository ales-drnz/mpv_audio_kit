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

  /// Enables or disables pitch correction (mpv's `scaletempo` engine)
  /// for non-1.0 playback rates. When disabled, raising the rate also
  /// raises pitch (chipmunk effect); enabled keeps pitch constant.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(pitchCorrection: enable), _reactives.pitchCorrection, enable);
  }

  /// Sets the audio delay relative to video (mpv's `audio-delay`).
  ///
  /// Sign convention: positive values **delay** audio relative to video
  /// (audio plays later), negative values **advance** it (audio plays
  /// earlier). This matches mpv's convention but is counterintuitive
  /// when thought of as "audio offset" — positive does NOT mean "audio
  /// ahead".
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

  /// Sets the ReplayGain normalization configuration atomically.
  ///
  /// Writes the four backing mpv properties (`replaygain`,
  /// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`) in
  /// one shot. Modify a single field via
  /// `await player.setReplayGain(state.replayGain.copyWith(preamp: -3))`.
  Future<void> setReplayGain(ReplayGainConfig config) async {
    _checkNotDisposed();
    _prop('replaygain', config.mode.mpvValue);
    _prop('replaygain-preamp', config.preamp.toStringAsFixed(2));
    _prop('replaygain-clip', config.clip ? 'yes' : 'no');
    _prop('replaygain-fallback', config.fallback.toStringAsFixed(2));
    _updateField(
        (s) => s.copyWith(replayGain: config), _reactives.replayGain, config);
  }

  /// Sets volume gain in dB (pre-amplification on top of [setVolume]).
  ///
  /// Hard range: -150 to +150 dB. The default soft clamp mpv applies is
  /// -96 to +12 dB (configurable with mpv's `volume-gain-min` /
  /// `volume-gain-max`). 0 dB = unity. Values above ~+6 dB risk clipping
  /// unless [setReplayGain] or a downstream limiter is in the chain.
  Future<void> setVolumeGain(double gainDb) async {
    _checkNotDisposed();
    _prop('volume-gain', gainDb.toStringAsFixed(2));
    _updateField((s) => s.copyWith(volumeGain: gainDb), _reactives.volumeGain, gainDb);
  }

  /// Sets the upper bound the user-facing volume scale is clamped to.
  ///
  /// Range: 100 to 1000. Default 130 (matches mpv's default and the slider
  /// range most apps expose). Setting above 100 lets [setVolume] amplify
  /// past unity; values up to 1000 = +20 dB digital boost. mpv hard-rejects
  /// values below 100.
  Future<void> setVolumeMax(double max) async {
    _checkNotDisposed();
    _prop('volume-max', max.toStringAsFixed(1));
    _updateField((s) => s.copyWith(volumeMax: max), _reactives.volumeMax, max);
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

  /// Selects the audio track with [trackId].
  ///
  /// IDs match [MpvTrack.id] entries in [PlayerState.tracks] / [Player.stream.tracks].
  /// State updates flow through the `current-tracks/audio` observer (no
  /// optimistic update — mpv may reject an unknown id).
  Future<void> setAudioTrack(int trackId) async {
    _checkNotDisposed();
    _prop('aid', trackId.toString());
  }

  /// Reverts audio track selection to mpv's automatic choice (the
  /// container's default track or the first audio track if no default
  /// is flagged).
  Future<void> setAudioTrackAuto() async {
    _checkNotDisposed();
    _prop('aid', 'auto');
  }

  /// Disables audio output entirely (`aid=no`). Useful for files where
  /// the consumer wants only metadata / cover art without playing audio.
  Future<void> setAudioTrackOff() async {
    _checkNotDisposed();
    _prop('aid', 'no');
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    _checkNotDisposed();
    _command(['ao-reload']);
  }

  // ── DSP filter chain ───────────────────────────────────────────────────────
  //
  // Four typed DSP stages plus a raw escape for everything else. Each
  // typed stage is upserted into mpv's `af` chain via a reserved label so
  // the wrapper can flip a single stage without touching the others. Chain
  // order is fixed: custom filters first, then compressor → equalizer →
  // pitch/tempo → loudnorm. `enabled=false` removes the stage from the
  // chain (zero-CPU) but preserves its parameters in state for re-enable.

  /// Sets the 10-band graphic equalizer config and applies it to mpv's
  /// filter chain in one atomic operation.
  ///
  /// Modify a single field via `state.equalizer.copyWith(...)`. Reset
  /// with [EqualizerConfig.flat]. Toggle on/off via
  /// `state.equalizer.copyWith(enabled: ...)` — the gains are preserved
  /// while disabled.
  Future<void> setEqualizer(EqualizerConfig config) async {
    _checkNotDisposed();
    if (config.gains.length != 10) {
      throw ArgumentError.value(
        config.gains.length,
        'config.gains',
        'EqualizerConfig requires exactly 10 gain values',
      );
    }
    final copy = config.copyWith(gains: List<double>.from(config.gains));
    _writeAfChain(equalizer: copy);
    _updateField(
      (s) => s.copyWith(equalizer: copy),
      _reactives.equalizer,
      copy,
    );
  }

  /// Sets the dynamic-range compressor config and applies it to mpv's
  /// filter chain in one atomic operation.
  Future<void> setCompressor(CompressorConfig config) async {
    _checkNotDisposed();
    _writeAfChain(compressor: config);
    _updateField(
      (s) => s.copyWith(compressor: config),
      _reactives.compressor,
      config,
    );
  }

  /// Sets the EBU R128 loudness normalization config and applies it to
  /// mpv's filter chain in one atomic operation.
  Future<void> setLoudness(LoudnessConfig config) async {
    _checkNotDisposed();
    _writeAfChain(loudness: config);
    _updateField(
      (s) => s.copyWith(loudness: config),
      _reactives.loudness,
      config,
    );
  }

  /// Sets the pitch / tempo shifter config (rubberband) and applies it
  /// to mpv's filter chain in one atomic operation.
  Future<void> setPitchTempo(PitchTempoConfig config) async {
    _checkNotDisposed();
    _writeAfChain(pitchTempo: config);
    _updateField(
      (s) => s.copyWith(pitchTempo: config),
      _reactives.pitchTempo,
      config,
    );
  }

  /// Sets raw mpv `--af` filter strings to live at the head of the chain,
  /// before any wrapper-managed DSP stage.
  ///
  /// Use for filters not covered by the typed setters
  /// ([setEqualizer], [setCompressor], [setLoudness], [setPitchTempo]) —
  /// e.g. `pan=stereo|c0=c1|c1=c0`, `aresample=async=1`,
  /// `lavfi-aecho=...`. Each entry must NOT carry a wrapper-reserved
  /// label (`@_mak_eq`, `@_mak_comp`, `@_mak_loud`, `@_mak_pt`).
  Future<void> setCustomAudioFilters(List<String> filters) async {
    _checkNotDisposed();
    final copy = List<String>.from(filters);
    _writeAfChain(customFilters: copy);
    _updateField(
      (s) => s.copyWith(customAudioFilters: copy),
      _reactives.customAudioFilters,
      copy,
    );
  }

  /// Recomposes the full mpv `af` value from the current state, with the
  /// caller's overrides applied. Internal helper for the five DSP setters.
  void _writeAfChain({
    EqualizerConfig? equalizer,
    CompressorConfig? compressor,
    LoudnessConfig? loudness,
    PitchTempoConfig? pitchTempo,
    List<String>? customFilters,
  }) {
    final af = composeAfChain(
      customFilters: customFilters ?? _state.customAudioFilters,
      compressor: compressor ?? _state.compressor,
      equalizer: equalizer ?? _state.equalizer,
      pitchTempo: pitchTempo ?? _state.pitchTempo,
      loudness: loudness ?? _state.loudness,
    );
    _prop('af', af);
  }

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

  /// Sets how long an image frame (e.g. cover art) is held as a
  /// displayable video frame after the file is loaded.
  ///
  /// Pass `null` (default) to keep the frame alive indefinitely (mpv's
  /// `inf`); pass [Duration.zero] to drop it as soon as audio playback
  /// starts. Mirrors mpv's `--image-display-duration` option.
  Future<void> setImageDisplayDuration(Duration? duration) async {
    _checkNotDisposed();
    final mpvValue =
        duration == null ? 'inf' : durationToSeconds(duration).toString();
    _prop('image-display-duration', mpvValue);
    _updateField((s) => s.copyWith(imageDisplayDuration: duration),
        _reactives.imageDisplayDuration, duration);
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
