// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of 'player.dart';

/// Audio setters: volume, mute, output device, format / channel layout,
/// the four typed DSP stages, and the cover-art display options.
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
  ///
  /// The `description` field of [device] is ignored — the wrapper
  /// resolves the description from `state.audioDevices` (mpv's
  /// authoritative `audio-device-list`). Pass [Device]s built
  /// from that list, or use the `name` only.
  Future<void> setAudioDevice(Device device) async {
    _checkNotDisposed();
    _prop('audio-device', device.name);
    _updateActiveAudioDevice(device.name);
  }

  /// Enables or disables pitch correction (mpv's `scaletempo` engine)
  /// for non-1.0 playback rates. When disabled, raising the rate also
  /// raises pitch (chipmunk effect); enabled keeps pitch constant.
  Future<void> setPitchCorrection(bool enable) async {
    _checkNotDisposed();
    _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField((s) => s.copyWith(pitchCorrection: enable),
        _reactives.pitchCorrection, enable);
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

  /// Enables or disables gapless playback. See [Gapless] for the
  /// available variants.
  Future<void> setGapless(Gapless mode) async {
    _checkNotDisposed();
    _prop('gapless-audio', mode.mpvValue);
    _updateField((s) => s.copyWith(gapless: mode), _reactives.gapless, mode);
  }

  /// Sets the ReplayGain normalization configuration atomically.
  ///
  /// Writes the four backing mpv properties (`replaygain`,
  /// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`) in
  /// one shot. Modify a single field via
  /// `await player.setReplayGain(state.replayGain.copyWith(preamp: -3))`.
  Future<void> setReplayGain(ReplayGainSettings config) async {
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
    _updateField(
        (s) => s.copyWith(volumeGain: gainDb), _reactives.volumeGain, gainDb);
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
    _updateField((s) => s.copyWith(audioExclusive: exclusive),
        _reactives.audioExclusive, exclusive);
  }

  /// Sets HDMI/S/PDIF audio passthrough codecs.
  ///
  /// Pass a [Set] of [Spdif] values to enable passthrough for those
  /// codecs (e.g. `{Spdif.ac3, Spdif.dts}`); pass `{}` to disable
  /// passthrough entirely. Order does not matter.
  Future<void> setAudioSpdif(Set<Spdif> codecs) async {
    _checkNotDisposed();
    _prop('audio-spdif', Spdif.formatMpvList(codecs));
    _updateField(
        (s) => s.copyWith(audioSpdif: codecs), _reactives.audioSpdif, codecs);
  }

  /// Selects the audio track via a typed [Track] —
  /// [Track.auto] defers to mpv's automatic choice
  /// (container default or first audio track),
  /// [Track.off] disables audio output entirely, and
  /// [Track.id] selects a specific track by its mpv ID
  /// (match an entry in [PlayerState.tracks]).
  ///
  /// State updates flow through the `current-tracks/audio` observer
  /// (no optimistic update — mpv may reject an unknown id).
  Future<void> setAudioTrack(Track mode) async {
    _checkNotDisposed();
    _prop('aid', mode.mpvValue);
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    _checkNotDisposed();
    _command(['ao-reload']);
  }

  // ── DSP filter chain ────────────────────────────────────────────────
  // The full DSP rack lives in a single [AudioEffects] bundle. Apply
  // it atomically with [setAudioEffects] (replace) or
  // [updateAudioEffects] (Freezed-style copyWith mapper). Each effect
  // inside the bundle owns a reserved label (see
  // [AudioFilterChainLabels]) and a per-effect `enabled` flag —
  // disabling a stage strips it from the chain at zero CPU cost while
  // preserving its parameters.

  /// Replaces the entire DSP filter chain in one atomic mpv `af`
  /// write.
  ///
  /// Use for full-bundle config (initial setup, preset application,
  /// preset restore from JSON). To mutate a single field — typical of
  /// UI sliders — prefer [updateAudioEffects].
  ///
  /// `effects.custom` carries raw mpv lavfi filter strings; each
  /// entry must NOT begin with a wrapper-reserved label
  /// ([AudioFilterChainLabels.all]) — those are owned by the typed
  /// effects in the bundle.
  Future<void> setAudioEffects(AudioEffects effects) async {
    _checkNotDisposed();
    if (effects.equalizer.gains.length != 10) {
      throw ArgumentError.value(
        effects.equalizer.gains.length,
        'effects.equalizer.gains',
        'EqualizerSettings requires exactly 10 gain values',
      );
    }
    for (final f in effects.custom) {
      final trimmed = f.trimLeft();
      if (!trimmed.startsWith('@')) continue;
      final colon = trimmed.indexOf(':');
      if (colon <= 1) continue;
      final label = trimmed.substring(1, colon);
      if (AudioFilterChainLabels.all.contains(label)) {
        throw ArgumentError.value(
          f,
          'effects.custom',
          'Custom filter carries a wrapper-reserved label `@$label:` — '
              'configure the matching typed effect on the bundle instead.',
        );
      }
    }
    final normalised = effects.copyWith(
      equalizer: effects.equalizer.copyWith(
        gains: List<double>.from(effects.equalizer.gains),
      ),
      custom: List<String>.from(effects.custom),
    );
    _prop('af', composeAfChain(normalised));
    _updateField(
      (s) => s.copyWith(audioEffects: normalised),
      _reactives.audioEffects,
      normalised,
    );
  }

  /// Mutates the audio-effects bundle with a Freezed-style copyWith
  /// mapper.
  ///
  /// Convenience over `setAudioEffects(state.audioEffects.copyWith(...))`.
  /// The mapper receives the current bundle and must return the new
  /// one — same semantics as Riverpod's `update`.
  ///
  /// Example:
  /// ```dart
  /// // Toggle the equalizer:
  /// await player.updateAudioEffects((e) =>
  ///   e.copyWith(equalizer: e.equalizer.copyWith(enabled: !e.equalizer.enabled)));
  ///
  /// // Replace one effect entirely:
  /// await player.updateAudioEffects((e) => e.copyWith(
  ///   compressor: CompressorSettings(enabled: true, threshold: -20, ratio: 4),
  /// ));
  /// ```
  Future<void> updateAudioEffects(
    AudioEffects Function(AudioEffects) mapper,
  ) async {
    await setAudioEffects(mapper(_state.audioEffects));
  }

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Controls whether mpv automatically loads external cover art files
  /// sitting next to the audio file (e.g. `cover.jpg`). See [Cover] for
  /// the available variants. Embedded cover bytes are surfaced through
  /// [Player.stream.coverArt] regardless of this setting.
  Future<void> setCoverArtAuto(Cover mode) async {
    _checkNotDisposed();
    _prop('cover-art-auto', mode.mpvValue);
    _updateField(
        (s) => s.copyWith(coverArtAuto: mode), _reactives.coverArtAuto, mode);
  }

  /// Sets the target audio sample rate.
  Future<void> setAudioSampleRate(int rate) async {
    _checkNotDisposed();
    _prop('audio-samplerate', rate.toString());
    _updateField((s) => s.copyWith(audioSampleRate: rate),
        _reactives.audioSampleRate, rate);
  }

  /// Sets the target audio sample format. Use [Format.auto] to
  /// reset to mpv's pick.
  Future<void> setAudioFormat(Format format) async {
    _checkNotDisposed();
    _prop('audio-format', format.mpvValue);
    _updateField(
        (s) => s.copyWith(audioFormat: format), _reactives.audioFormat, format);
  }

  /// Sets the target audio channel layout. Use the named static
  /// constants on [Channels] for common presets, or
  /// [Channels.custom] for any other mpv-recognised layout
  /// string.
  Future<void> setAudioChannels(Channels channels) async {
    _checkNotDisposed();
    _prop('audio-channels', channels.mpvValue);
    _updateField((s) => s.copyWith(audioChannels: channels),
        _reactives.audioChannels, channels);
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    _checkNotDisposed();
    _prop('audio-client-name', name);
    _updateField((s) => s.copyWith(audioClientName: name),
        _reactives.audioClientName, name);
  }

  /// Sets the audio output driver (e.g. 'auto', 'coreaudio', 'pulse', 'alsa', 'wasapi').
  Future<void> setAudioDriver(String driver) async {
    _checkNotDisposed();
    _prop('ao', driver);
    _updateField(
        (s) => s.copyWith(audioDriver: driver), _reactives.audioDriver, driver);
  }
}
