// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// What the player logs on [PlayerStream.internalLog] when mpv refuses a
/// live `af-command` update and the chain is rewritten instead. Tests
/// count refusals by it.
@visibleForTesting
const afCommandRefusedLog =
    'A live effects update was refused; rebuilding the chain.';

/// Audio setters: volume, mute, output device, format and channel layout,
/// the effects chain, and the cover-art display options.
mixin _AudioModule on _PlayerBase {
  /// Sets the soft volume in percent: 100 plays at unity and values above
  /// it amplify. mpv's scale is cubic: 130 is about +7 dB, 1000 is +60 dB.
  ///
  /// Takes 0 to 1000. Throws [RangeError] when negative, and
  /// [MpvCommandException] above 1000, which mpv refuses.
  /// [PlayerState.volumeMax] does not cap this call: it bounds mpv's
  /// relative steps (`add`, `cycle`) only. Clamp a slider to it yourself.
  Future<void> setVolume(double volume) async {
    _checkRange(volume, 0, double.maxFinite, 'volume');
    await _gate();
    final value = canonicalFloat(volume);
    await _calls.prop('volume', value.toString());
    _updateField((s) => s.copyWith(volume: value), _reactives.volume, value);
  }

  /// Sets playback rate (1.0 = normal speed). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setRate(double rate) async {
    _checkRange(rate, 0.01, 100, 'rate');
    await _gate();
    await _calls.prop('speed', rate.toString());
    _updateField((s) => s.copyWith(rate: rate), _reactives.rate, rate);
  }

  /// Sets pitch (1.0 = original pitch). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setPitch(double pitch) async {
    _checkRange(pitch, 0.01, 100, 'pitch');
    await _gate();
    await _calls.prop('pitch', pitch.toString());
    _updateField((s) => s.copyWith(pitch: pitch), _reactives.pitch, pitch);
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    await _gate();
    await _calls.prop('mute', mute ? 'yes' : 'no');
    _updateField((s) => s.copyWith(mute: mute), _reactives.mute, mute);
  }

  /// Sets the active audio output device.
  ///
  /// The `description` field of [device] is ignored: the description
  /// is resolved from `state.audioDevices` (mpv's authoritative
  /// `audio-device-list`). Pass [Device]s built from that list, or use
  /// the `name` only.
  Future<void> setAudioDevice(Device device) async {
    await _gate();
    await _calls.prop('audio-device', device.name);
    _updateActiveAudioDevice(device.name);
  }

  /// Enables or disables pitch correction (mpv's `audio-pitch-correction`,
  /// which inserts `scaletempo2`) for non-1.0 playback rates. Enabled by
  /// default. When disabled, raising the rate also raises the pitch.
  Future<void> setPitchCorrection(bool enable) async {
    await _gate();
    await _calls.prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(pitchCorrection: enable),
      _reactives.pitchCorrection,
      enable,
    );
  }

  /// Sets the audio delay against the playback clock (mpv's
  /// `audio-delay`), for example to match a Bluetooth output to a visual.
  ///
  /// Sign convention: positive values **delay** the audio (it plays
  /// later), negative values **advance** it (it plays earlier). This
  /// matches mpv's convention but is counterintuitive when thought of as
  /// "audio offset": positive does NOT mean "audio ahead".
  ///
  /// Sent to mpv in seconds with six decimals, so microseconds are kept.
  Future<void> setAudioDelay(Duration delay) async {
    await _gate();
    await _calls.prop(
      'audio-delay',
      durationToSeconds(delay).toStringAsFixed(6),
    );
    _updateField(
      (s) => s.copyWith(audioDelay: delay),
      _reactives.audioDelay,
      delay,
    );
  }

  /// Enables or disables gapless playback. See [Gapless] for the
  /// available variants. During a live [PcmSource] entry, which plays
  /// without gapless, a new value holds only until that entry ends.
  Future<void> setGapless(Gapless gapless) async {
    await _gate();
    await _calls.prop('gapless-audio', gapless.mpvValue);
    _updateField(
      (s) => s.copyWith(gapless: gapless),
      _reactives.gapless,
      gapless,
    );
  }

  /// Sets the ReplayGain normalization configuration atomically.
  ///
  /// Writes the four backing mpv properties (`replaygain`,
  /// `replaygain-preamp`, `replaygain-clip`, `replaygain-fallback`) in
  /// one shot. If any of the writes fails, the previously-committed
  /// fields and the state go back to the prior [ReplayGainSettings]
  /// before the error is rethrown, so the consumer never observes a
  /// half-applied state.
  Future<void> setReplayGain(ReplayGainSettings requested) async {
    await _gate();
    final settings = requested.copyWith(
      preamp: canonicalFloat(requested.preamp),
      fallback: canonicalFloat(requested.fallback),
    );
    final previous = state.replayGain;
    final writes = <(String, String, String)>[
      ('replaygain', settings.mode.mpvValue, previous.mode.mpvValue),
      (
        'replaygain-preamp',
        settings.preamp.toString(),
        previous.preamp.toString(),
      ),
      (
        'replaygain-clip',
        settings.clip ? 'yes' : 'no',
        previous.clip ? 'yes' : 'no',
      ),
      (
        'replaygain-fallback',
        settings.fallback.toString(),
        previous.fallback.toString(),
      ),
    ];
    await _calls.writeBundle(
      writes,
      (v) => _updateField(
        (s) => s.copyWith(replayGain: v),
        _reactives.replayGain,
        v,
      ),
      settings,
      previous,
    );
  }

  /// Sets volume gain in dB (pre-amplification on top of [setVolume]).
  ///
  /// Takes -150 to +150 dB: mpv refuses a value outside it, and the call
  /// throws [MpvCommandException]. [setVolumeGainMin] and
  /// [setVolumeGainMax] do not cap this call: they bound mpv's relative
  /// steps (`add`, `cycle`) only. 0 dB = unity. Values above about +6 dB
  /// risk clipping unless [setReplayGain] or a downstream limiter is in
  /// the chain.
  Future<void> setVolumeGain(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _calls.prop('volume-gain', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGain: value),
      _reactives.volumeGain,
      value,
    );
  }

  /// Sets mpv's `volume-gain-min`, in dB. Range -150 to 0; default -96.
  ///
  /// It is the floor of mpv's relative steps on the gain (`add` and
  /// `cycle` through [Player.sendRawCommand]), not of [setVolumeGain],
  /// which takes down to -150 whatever this value.
  Future<void> setVolumeGainMin(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _calls.prop('volume-gain-min', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGainMin: value),
      _reactives.volumeGainMin,
      value,
    );
  }

  /// Sets mpv's `volume-gain-max`, in dB. Range 0 to 150; default +12.
  ///
  /// It is the top of mpv's relative steps on the gain (`add` and `cycle`
  /// through [Player.sendRawCommand]), not of [setVolumeGain], which takes
  /// up to +150 whatever this value.
  Future<void> setVolumeGainMax(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _calls.prop('volume-gain-max', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGainMax: value),
      _reactives.volumeGainMax,
      value,
    );
  }

  /// Sets the volume the audio driver exposes, in percent (mpv's
  /// `ao-volume`), distinct from the soft [setVolume]. Throws [RangeError]
  /// outside `[0, 100]`.
  ///
  /// What it moves depends on the driver:
  /// - the app's own stream with PulseAudio, PipeWire, WASAPI in shared
  ///   mode and CoreAudio on macOS;
  /// - the whole device, for every app, with ALSA (the card's mixer) and
  ///   with WASAPI in exclusive mode (the device's hardware volume, when it
  ///   has one). The system keeps that value after [Player.dispose].
  ///
  /// Best-effort: where the driver exposes no volume (iOS, Android, macOS
  /// in exclusive mode, the null AO) the call is silently ignored: it does
  /// NOT throw, and [PlayerState.systemVolume] stays `null`. On Android the
  /// app's volume is the system's media volume, which the app sets through
  /// the platform's AudioManager.
  Future<void> setSystemVolume(double volume) async {
    _checkRange(volume, 0, 100, 'volume');
    await _gate();
    final value = canonicalFloat(volume);
    final rc = await _calls.propRc('ao-volume', value.toString());
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemVolume: value),
        _reactives.systemVolume,
        value,
      );
    }
  }

  /// Sets the mute the audio driver exposes (`ao-mute`), distinct from the
  /// soft [setMute]. It reaches as far as [setSystemVolume] does: the
  /// whole device with ALSA and with WASAPI in exclusive mode.
  ///
  /// Best-effort, like [setSystemVolume]: silently ignored (no throw) when the
  /// active audio output doesn't expose system mute (coreaudio on macOS,
  /// iOS, Android).
  Future<void> setSystemMute(bool mute) async {
    await _gate();
    final rc = await _calls.propRc('ao-mute', mute ? 'yes' : 'no');
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemMute: mute),
        _reactives.systemMute,
        mute,
      );
    }
  }

  /// Sets mpv's `volume-max`, in percent.
  ///
  /// Range: 100 to 1000; default 130, mpv's own. It is the top of mpv's
  /// relative volume steps (`add` and `cycle` through
  /// [Player.sendRawCommand]), and a natural top for a volume slider, read
  /// back from [PlayerState.volumeMax]. It does not cap [setVolume], which
  /// takes up to 1000 whatever this value. mpv refuses values outside the
  /// range.
  Future<void> setVolumeMax(double limit) async {
    _checkFinite(limit, 'limit');
    await _gate();
    final value = canonicalFloat(limit);
    await _calls.prop('volume-max', value.toString());
    _updateField(
      (s) => s.copyWith(volumeMax: value),
      _reactives.volumeMax,
      value,
    );
  }

  /// Requests exclusive use of the audio device (mpv's `audio-exclusive`).
  ///
  /// - WASAPI (Windows) and CoreAudio (macOS) take the device for the
  ///   player and switch it to the track's rate when it supports it, so
  ///   the system mixer neither resamples nor sets the volume. Other apps
  ///   have no sound on that device. The player keeps it while paused and
  ///   at the end of the queue, until [Player.stop], a call with `false`
  ///   or [Player.dispose].
  /// - PipeWire keeps other streams off the sink, but the stream still
  ///   goes through PipeWire: its volume applies, and the audio is
  ///   resampled when the rate is not one the server allows.
  /// - On Android the default `audiotrack` driver ignores it. `aaudio`
  ///   gets an exclusive stream only with mpv's `aaudio-performance-mode`
  ///   set to `low-latency`, on Android 8.1 or later with a device that
  ///   supports it, and the system has the last word. Other apps keep
  ///   playing.
  /// - On iOS it has no effect: the audio never mixes with other apps,
  ///   and changing the value only reopens the output.
  ///
  /// Other drivers ignore it.
  Future<void> setAudioExclusive(bool exclusive) async {
    await _gate();
    await _calls.prop('audio-exclusive', exclusive ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(audioExclusive: exclusive),
      _reactives.audioExclusive,
      exclusive,
    );
  }

  /// Whether mpv reports a "music" media role to the OS audio server
  /// (mpv's `audio-set-media-role`). On PulseAudio and PipeWire (Linux) this
  /// lets the server apply the right routing and volume profile for music.
  /// On Android the `audiotrack` driver, and `aaudio` from API 28, only tag
  /// the content type as music: the usage stays media, so routing and
  /// volume do not change. Other drivers ignore it.
  Future<void> setAudioMediaRole(bool enable) async {
    await _gate();
    await _calls.prop('audio-set-media-role', enable ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(audioMediaRole: enable),
      _reactives.audioMediaRole,
      enable,
    );
  }

  /// Sets HDMI and S/PDIF audio passthrough codecs.
  ///
  /// Pass a [Set] of [Spdif] values to enable passthrough for those
  /// codecs (e.g. `{Spdif.ac3, Spdif.dts}`); pass `{}` to disable
  /// passthrough entirely. Order does not matter.
  ///
  /// While a track passes through, the receiver decodes it and mpv cannot
  /// touch the audio: the effects chain, the soft volume and mute,
  /// ReplayGain, the volume gain, pitch, and the output rate, format and
  /// channels do not apply, a speed other than 1 drops or repeats parts of
  /// the stream instead of stretching it, and [PlayerStream.fft],
  /// [PlayerStream.pcm], the taps and [PlayerStream.loudnessMeter] emit
  /// nothing. When the output refuses the format, mpv decodes the track
  /// instead. Changed during playback, the list reopens the decoder, with
  /// a short gap.
  Future<void> setAudioSpdif(Set<Spdif> codecs) async {
    await _gate();
    await _calls.prop('audio-spdif', Spdif.formatMpvList(codecs));
    _updateField(
      (s) => s.copyWith(audioSpdif: codecs),
      _reactives.audioSpdif,
      codecs,
    );
  }

  /// Selects the audio track via a typed [Track]:
  /// [Track.auto] defers to mpv's automatic choice
  /// (container default or first audio track),
  /// [Track.off] disables audio output entirely, and
  /// [Track.id] selects a specific track by its mpv ID
  /// (match an entry in [PlayerState.tracks]).
  ///
  /// State updates flow through the `current-tracks/audio` observer
  /// (no optimistic update: mpv may reject an unknown id).
  Future<void> setAudioTrack(Track track) async {
    await _gate();
    await _calls.prop('aid', track.mpvValue);
  }

  /// Loads an external audio file as an additional selectable track on the
  /// currently-playing file (mpv's `audio-add`), e.g. a separate-language
  /// dub or a commentary track. The new track appears in
  /// [PlayerState.tracks]; switch to it with [setAudioTrack].
  ///
  /// [select] `true` (default) selects the new track immediately; `false`
  /// adds it without switching. [title] and [lang] tag it for the track list.
  /// Per-[Media] options (`httpHeaders`, …) are validated but not applied:
  /// `audio-add` has no file-local options slot.
  ///
  /// Throws [MpvCommandException] when mpv refuses the track: a file it
  /// cannot open, or no file loaded to add it to.
  Future<void> addAudioTrack(
    Media file, {
    bool select = true,
    String? title,
    String? lang,
  }) async {
    _checkNotDisposed();
    _rejectPcm(file, 'file');
    _validateLoadOptions(file);
    // Snapshot the load epoch: a content-replacing call landing while the
    // URI resolves makes this add stale: the track belongs to the file
    // that is no longer playing (see [Player.open]).
    final load = _snapshotLoad();
    await _gate();
    final source = OwnedSource(await resolveUri(file.uri));
    // The call's to release until the track takes it over.
    try {
      if (load.superseded) return;
      final args = <String>[
        'audio-add',
        source.uri,
        select ? 'select' : 'auto',
      ];
      // mpv's args are positional: to pass `lang` you must also pass `title`.
      if (title != null || lang != null) args.add(title ?? '');
      if (lang != null) args.add(lang);
      // An Android content:// URI arrives as an fd:// descriptor that mpv
      // never closes: held until the file the track joins ends.
      final dispose = source.handOver();
      final settle = dispose == null ? null : _entries.holdTrack(dispose);
      var rc = -1;
      try {
        rc = await _calls.command(args);
      } finally {
        await settle?.call(rc >= 0);
      }
      if (rc < 0) {
        throw MpvCommandException(
          name: 'audio-add',
          code: rc,
          message: _calls.errorString(rc),
        );
      }
    } finally {
      await source.release();
    }
  }

  /// Removes an audio track (mpv's `audio-remove`). Pass [Track.id] to remove
  /// a specific track (typically one added via [addAudioTrack]); [Track.auto]
  /// removes the currently-selected audio track. The track-list observer
  /// folds the removal back into [PlayerState.tracks].
  ///
  /// [Track.off] is rejected with an [ArgumentError]: mpv's `audio-remove`
  /// takes an optional track id and has no "off" notion, so removing "no
  /// track" is meaningless. Use [setAudioTrack] with [Track.off] to mute the
  /// selection instead.
  ///
  /// Throws [MpvCommandException] when mpv refuses: an id with no audio
  /// track, or no track to remove.
  Future<void> removeAudioTrack(Track track) async {
    _checkNotDisposed();
    if (track is TrackOff) {
      throw ArgumentError.value(
        track,
        'track',
        'Track.off has no meaning for removeAudioTrack: pass Track.id to '
            'remove a specific track or Track.auto to remove the current one.',
      );
    }
    await _gate();
    await _calls.commandChecked(
      track is TrackId
          ? ['audio-remove', '${track.trackId}']
          : ['audio-remove'],
    );
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    await _gate();
    await _calls.commandChecked(['ao-reload']);
  }

  /// Re-scans the external files next to the current file: mpv's
  /// `rescan-external-files`. With [keepSelection] the current track
  /// selection is preserved; otherwise mpv reselects the default streams.
  ///
  /// It loads only what mpv's auto-load options allow, and the player's
  /// defaults allow none of it: cover images need [setCoverArtAuto], and
  /// companion audio files need mpv's `audio-file-auto`, set with
  /// [Player.setRawProperty]. What it finds shows in [PlayerState.tracks]
  /// only; a cover image does not reach [PlayerStream.coverArt].
  Future<void> rescanExternalFiles({bool keepSelection = false}) async {
    await _gate();
    await _calls.commandChecked([
      'rescan-external-files',
      keepSelection ? 'keep-selection' : 'reselect',
    ]);
  }

  // ── DSP pipeline ────────────────────────────────────────────────────
  // The DSP pipeline is an ordered list of [AudioEffect] stages, applied
  // atomically with [setAudioEffects] (replace) or [updateAudioEffects]
  // (mapper). Each stage owns an `enabled` flag: disabling one drops it
  // from the chain while keeping it, and its settings, in the list.

  /// Replaces the effects chain in one atomic write: [effects] run in
  /// list order, and the same filter may appear more than once.
  ///
  /// Use for a whole chain (initial setup, presets). To change one stage,
  /// typical of UI sliders, prefer [updateAudioEffects].
  ///
  /// Throws [MpvCommandException], with the state back on the last list
  /// mpv accepted, when mpv rejects the chain: a syntax error, an unknown
  /// filter, or an option value the filter refuses when it is created. A
  /// filter that fails later, while it configures on its first frame, is
  /// disabled by mpv instead, with a message on [PlayerStream.log]. With
  /// no file loaded there is no graph to build yet, so a refused value
  /// surfaces at the next load instead, on [PlayerStream.error].
  ///
  /// Throws [ArgumentError], before anything reaches mpv and with the
  /// state unchanged, when a stage holds a value its filter would take and
  /// then read or write out of its buffers with, or turn the audio to NaN
  /// with:
  /// - chorus lists with different numbers of voices, a negative or NaN
  ///   delay or depth, or a speed that is not above 0 and at most 100 Hz;
  /// - aecho delays that are not above 0 and at most 90000 ms, or decays
  ///   that are not above 0 and at most 1;
  /// - an anequalizer band value that is NaN or infinite;
  /// - a pan input channel named UNK, UNSD or AMBI, which pan has no slot
  ///   for;
  /// - an mcompand band with an empty attack or decay among an even number
  ///   of them, or a NaN crossover frequency;
  /// - compand attacks and decays that both start with no number.
  ///
  /// A [RawAudioEffect] is not checked here. The filters themselves refuse
  /// such values, so a raw stage that carries one fails as described above
  /// for a value a filter refuses, instead of reading or writing out of its
  /// buffers.
  ///
  /// A [RawAudioEffect] carries a lavfi entry written by hand, for
  /// expression-based filters or anything without a typed effect. The
  /// chain is the only writer of mpv's `af` property: raw writes via
  /// `setRawProperty('af', ...)` are rejected. An `af` value already
  /// there, such as the chain a resume point saved by 0.5.1 or earlier
  /// brings back with its file, is replaced by the first call here, and
  /// after that call at every load.
  ///
  /// ```dart
  /// await player.setAudioEffects([
  ///   EqualizerEffect(frequency: 100, width: 50, gain: 3),
  ///   EqualizerEffect(frequency: 8000, width: 1000, gain: -2),
  ///   AcompressorEffect(ratio: 4),
  ///   AlimiterEffect(limit: 0.9),
  /// ]);
  /// ```
  Future<void> setAudioEffects(List<AudioEffect> effects) async {
    await _gate();
    await _applyAudioEffects(effects);
  }

  // ── Chain state ────────────────────────────────────────────────────
  // mpv keeps each filter with the arguments it was created with, and
  // af-command moves only the live graph. Whenever mpv rebuilds a filter
  // from its stored arguments (a file load; a seek or loop wrap, since
  // lavfi frees its graph on reset; a track switch or format change) the
  // live values would be lost, so the chain is rewritten from the state
  // there while diffs are ahead of the stored arguments. mpv keeps every
  // filter whose arguments already match, so only the stages moved live
  // are rebuilt.

  /// The last list mpv accepted, through `af set` or a whole diff of
  /// `af-command`s: what it plays when a later write is refused, and so
  /// what the state rolls back to. `null` until the first write, which
  /// always goes through to override an `af` already there, even empty.
  List<AudioEffect>? _afAccepted;

  /// The af-command diffs sent, and how many of them a chain write that
  /// landed already carries. mpv's stored arguments are behind the live
  /// values while [_afStale].
  int _afDiffsSent = 0;
  int _afDiffsSynced = 0;
  bool get _afStale => _afDiffsSynced < _afDiffsSent;

  /// Chain writes (`af set`) sent and not answered yet. Each one makes mpv
  /// emit AUDIO_RECONFIG before its reply without resetting the filters it
  /// keeps, so that event is no reason to resync.
  int _afWritesInFlight = 0;

  /// The [_afDiffsSent] a resync in flight carries, so a burst of seeks
  /// sends one.
  int? _afResyncing;

  /// The confirmation of the last write, which the next one waits for
  /// before it looks at [_afAccepted]: an empty diff has no reply to wait
  /// on and would otherwise settle ahead of an earlier write.
  Future<void> _afSettled = Future.value();

  /// mpv's `af` as read right after the last chain write, in mpv's own
  /// printing, or `null` when unknown: a file started between the write
  /// and the read, or the read failed. The player is the only other
  /// writer of `af`, so a different value at a load comes from a resume
  /// point that still holds a chain.
  String? _afHeld;

  /// Write + commit shared by [setAudioEffects] and [updateAudioEffects].
  /// The diff computation, the wire enqueue and the state commit are all
  /// SUSPENSION-FREE: [updateAudioEffects] relies on mapper → enqueue →
  /// commit happening in one microtask so that concurrent un-awaited calls
  /// each observe the previous commit, and the async client API enqueues
  /// in call order so the core sees the writes FIFO. Only the mpv
  /// confirmation (the returned future) is deferred.
  ///
  /// Parameter-only changes on command-capable filters go through
  /// `af-command`: the live graph updates in place instead of being
  /// torn down and rebuilt (glitch-free slider drags). Any change to the
  /// list's shape, non-runtime options and command failures fall back to
  /// the full `af` rewrite, which is always correct.
  Future<void> _applyAudioEffects(List<AudioEffect> requested) {
    final effects = List<AudioEffect>.unmodifiable(requested);
    // Before the diff, so a refused list reaches neither mpv nor the state.
    validateAudioEffects(effects);
    final previous = _state.audioEffects;
    final written = _afAccepted != null;
    // No-op writes skip the serialization + FFI round-trip entirely.
    if (written && listEquals(effects, previous)) {
      return Future.value();
    }
    final cmds = written ? audioEffectsDiff(previous, effects) : null;
    final Future<void> settled;
    if (cmds != null) {
      // Enqueue the whole diff now (in order); validate the outcomes when
      // the replies land.
      final rcs = <Future<int>>[
        for (final c in cmds)
          _calls.command([
            'af-command',
            c.label,
            c.option,
            c.value,
            c.filterName,
          ]),
      ];
      if (cmds.isNotEmpty) _afDiffsSent++;
      settled = _settleAfCommands(_afSettled, rcs, effects, previous);
    } else {
      // A rebuild keeps every filter whose new arguments equal its stored
      // ones: a stage moved live from 0 to 6 and set back to 0 would stay
      // at 6. Rebuilding once from the current list first brings the
      // stored arguments level with the live values. Enqueued now, ahead
      // of the rewrite, like the diff.
      final resync = _afStale ? _setAfChain(audioEffectsChain(previous)) : null;
      settled = _rewriteAfChain(_afSettled, effects, resync);
    }
    _afSettled = settled.then((_) {}, onError: (Object _) {});
    _updateField(
      (s) => s.copyWith(audioEffects: effects),
      _reactives.audioEffects,
      effects,
    );
    return settled;
  }

  /// Replaces mpv's filter chain with [chain] through the `af set`
  /// command, which rebuilds the running graph and answers an error, with
  /// the old chain kept, when the rebuild fails. A write of the `af`
  /// property instead succeeds once the string parses and drops a failed
  /// rebuild silently. Resolves with mpv's rc.
  Future<int> _setAfChain(String chain) {
    final reply = _calls.command(['af', 'set', chain]);
    _afWritesInFlight++;
    // Queued right behind the write: mpv runs the two in order, so the
    // read sees the chain the write left, refused or not, unless a file
    // started in between and its resume point set `af`.
    final starts = _fileStarts;
    unawaited(
      _calls.get('af', MpvFormat.mpvFormatString).then((r) {
        final (rc, af) = r;
        _afHeld = rc >= 0 && af is String && starts == _fileStarts ? af : null;
      }),
    );
    return reply.whenComplete(() => _afWritesInFlight--);
  }

  /// Records that a chain write queued when [sent] diffs had gone out
  /// landed, and so carries them.
  void _afSynced(int sent) {
    if (sent > _afDiffsSynced) _afDiffsSynced = sent;
  }

  @override
  void _onAfChainReset() => _resyncStaleAfChain();

  /// A resume point written by 0.5.1 or earlier holds an `af` line, which
  /// mpv applies as it loads the file. Once the player wrote a chain, a
  /// chain it did not write gives way to the state's. Before that, a
  /// chain already there stays until the first write, as documented on
  /// [setAudioEffects].
  @override
  void _reassertAfChain() {
    if (_afAccepted != null) unawaited(_reassertAfChainFor(_fileStarts));
  }

  Future<void> _reassertAfChainFor(int starts) async {
    final (rc, af) = await _calls.get('af', MpvFormat.mpvFormatString);
    // A newer load checks for itself.
    if (rc < 0 || _disposed || starts != _fileStarts || af == _afHeld) return;
    final sent = _afDiffsSent;
    final effects = _state.audioEffects;
    final setRc = await _setAfChain(audioEffectsChain(effects));
    if (setRc < 0) {
      _internalLog(
        'Restoring the effects chain over a resume point failed: '
        '${_calls.errorString(setRc)}',
        level: LogLevel.debug,
      );
      return;
    }
    _afAccepted = effects;
    _afSynced(sent);
  }

  @override
  void _onAudioReconfig() {
    if (_afWritesInFlight == 0) _resyncStaleAfChain();
  }

  /// Rewrites the chain from the state while diffs are ahead of mpv's
  /// stored arguments. One resync at a time per diff count.
  void _resyncStaleAfChain() {
    if (!_afStale || _afResyncing == _afDiffsSent) return;
    final sent = _afResyncing = _afDiffsSent;
    final effects = _state.audioEffects;
    unawaited(
      _setAfChain(audioEffectsChain(effects)).then((rc) {
        if (_afResyncing == sent) _afResyncing = null;
        if (rc < 0) {
          _internalLog(
            'Rewriting the effects chain after a reset failed: '
            '${_calls.errorString(rc)}',
            level: LogLevel.debug,
          );
          return;
        }
        _afAccepted = effects;
        _afSynced(sent);
      }),
    );
  }

  /// Puts the state back on [_afAccepted] after mpv refused [effects],
  /// unless a later call already replaced them, and throws. A diff that
  /// mpv took meanwhile may have moved the live graph: the resync brings
  /// it back in line with the state.
  Never _refuseAudioEffects(List<AudioEffect> effects, int rc) {
    if (identical(_state.audioEffects, effects)) {
      final accepted = _afAccepted ?? const <AudioEffect>[];
      _updateField(
        (s) => s.copyWith(audioEffects: accepted),
        _reactives.audioEffects,
        accepted,
      );
      _resyncStaleAfChain();
    }
    throw MpvCommandException(
      name: 'af',
      code: rc,
      message: _calls.errorString(rc),
    );
  }

  /// Awaits the diff's replies. The diff was computed against [previous]:
  /// when that is not what mpv last accepted (an earlier write in flight
  /// was refused), or when a command was refused, the chain is rewritten
  /// from the LATEST committed list, healing a partial apply (and any
  /// later updates already committed). A command mpv refuses while it
  /// rebuilds a graph (until the graph sees a frame) is healed that way
  /// without an error. Only when the rewrite is refused too, a value the
  /// filter itself refuses, the state goes back to the last accepted list
  /// and the call throws, as a refused rewrite does.
  Future<void> _settleAfCommands(
    Future<void> prior,
    List<Future<int>> rcs,
    List<AudioEffect> effects,
    List<AudioEffect> previous,
  ) async {
    await prior;
    final results = await Future.wait(rcs);
    final refused = results.any((rc) => rc < 0);
    if (!refused && identical(_afAccepted, previous)) {
      _afAccepted = effects;
      return;
    }
    if (refused) {
      _internalLog(afCommandRefusedLog, level: LogLevel.debug);
    }
    final sent = _afDiffsSent;
    final healed = _state.audioEffects;
    final healRc = await _setAfChain(audioEffectsChain(healed));
    if (healRc >= 0) {
      _afAccepted = healed;
      _afSynced(sent);
      return;
    }
    _refuseAudioEffects(effects, healRc);
  }

  /// Awaits the full-rewrite reply. On success the stored arguments carry
  /// every diff sent before it. On rejection (e.g. a malformed
  /// [RawAudioEffect]) mpv keeps the old chain, the optimistic commit is
  /// rolled back to the last list mpv accepted (unless a later update
  /// already replaced it), and the [MpvCommandException] propagates to the
  /// caller.
  Future<void> _rewriteAfChain(
    Future<void> prior,
    List<AudioEffect> effects,
    Future<int>? resync,
  ) async {
    final sent = _afDiffsSent;
    final rewrite = _setAfChain(audioEffectsChain(effects));
    await prior;
    // The resync only levels mpv's stored arguments; the rewrite after it
    // decides the outcome either way.
    if (resync != null) await resync;
    final rc = await rewrite;
    if (rc >= 0) {
      _afAccepted = effects;
      _afSynced(sent);
      return;
    }
    _refuseAudioEffects(effects, rc);
  }

  /// Changes the effects chain through [mapper], which receives the
  /// current list and returns the new one.
  ///
  /// Throws [MpvCommandException] like [setAudioEffects] when mpv refuses
  /// the result, and [ArgumentError] like it for a stage that is not safe
  /// to run, so a call that is not awaited, typical of a slider, ends in
  /// an unhandled error then.
  ///
  /// ```dart
  /// // A slider on the second stage (an EqualizerEffect):
  /// await player.updateAudioEffects((fx) => [
  ///   for (final (i, e) in fx.indexed)
  ///     i == 1 ? (e as EqualizerEffect).copyWith(gain: gain) : e,
  /// ]);
  ///
  /// // Bypass every compressor without losing its settings:
  /// await player.updateAudioEffects((fx) => [
  ///   for (final e in fx)
  ///     e is AcompressorEffect ? e.copyWith(enabled: false) : e,
  /// ]);
  /// ```
  Future<void> updateAudioEffects(
    List<AudioEffect> Function(List<AudioEffect>) mapper,
  ) async {
    _checkNotDisposed();
    // Run the mapper only AFTER the ready gate, and commit in the same
    // microtask: two un-awaited calls in one synchronous turn would
    // otherwise both run their mapper on the same pre-commit list, and
    // the second commit would silently drop the first mutation. The
    // single suspension point serializes each read-modify-write in call
    // order on the microtask queue.
    await _gate();
    await _applyAudioEffects(mapper(_state.audioEffects));
  }

  // ── Cover Art ──────────────────────────────────────────────────────────────

  /// Controls whether mpv automatically loads external cover art files
  /// sitting next to the audio file (e.g. `cover.jpg`) as extra tracks.
  /// See [Cover] for the available variants. A loaded image shows in
  /// [PlayerState.tracks] with `albumArt` and `externalFilename` set; it
  /// does not reach [PlayerStream.coverArt], which carries only embedded
  /// cover bytes, whatever this setting.
  Future<void> setCoverArtAuto(Cover cover) async {
    await _gate();
    await _calls.prop('cover-art-auto', cover.mpvValue);
    _updateField(
      (s) => s.copyWith(coverArtAuto: cover),
      _reactives.coverArtAuto,
      cover,
    );
  }

  /// Sets the target audio sample rate.
  ///
  /// The output driver can still change it: [PlayerState.audioOutParams]
  /// shows the rate the device gets. On Android `audiotrack` plays at most
  /// at the device's native rate, usually 48 kHz. Changed during playback,
  /// it reopens the output, with a short gap. A track in passthrough
  /// ([setAudioSpdif]) ignores it.
  Future<void> setAudioSampleRate(int rate) async {
    await _gate();
    await _calls.prop('audio-samplerate', rate.toString());
    _updateField(
      (s) => s.copyWith(audioSampleRate: rate),
      _reactives.audioSampleRate,
      rate,
    );
  }

  /// Sets the target audio sample format. Use [Format.auto] to
  /// reset to mpv's pick.
  ///
  /// The output driver can still change it: [PlayerState.audioOutParams]
  /// shows the format the device gets. On Android `audiotrack` plays only
  /// 8-bit, 16-bit and float samples, so other integer formats become
  /// 16-bit, and `aaudio` takes 32-bit integers from Android 12 (API 31).
  /// For a source above 16 bits there, [Format.float32] keeps the
  /// resolution. Changed during playback, it reopens the output, with a
  /// short gap. A track in passthrough ([setAudioSpdif]) ignores it.
  Future<void> setAudioFormat(Format format) async {
    await _gate();
    await _calls.prop('audio-format', format.mpvValue);
    _updateField(
      (s) => s.copyWith(audioFormat: format),
      _reactives.audioFormat,
      format,
    );
  }

  /// Sets the target audio channel layout. Use the named static
  /// constants on [Channels] for common presets, or
  /// [Channels.custom] for any other mpv-recognised layout
  /// string. Changed during playback, it reopens the output, with a short
  /// gap. A track in passthrough ([setAudioSpdif]) ignores it.
  Future<void> setAudioChannels(Channels channels) async {
    await _gate();
    await _calls.prop('audio-channels', channels.mpvValue);
    _updateField(
      (s) => s.copyWith(audioChannels: channels),
      _reactives.audioChannels,
      channels,
    );
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    await _gate();
    await _calls.prop('audio-client-name', name);
    _updateField(
      (s) => s.copyWith(audioClientName: name),
      _reactives.audioClientName,
      name,
    );
  }

  /// Sets the audio output driver, e.g. `'coreaudio'` (macOS),
  /// `'wasapi'` (Windows), `'pulse'`, `'alsa'` or `'pipewire'` (Linux).
  ///
  /// On Android the automatic choice is `audiotrack`. `aaudio` needs
  /// Android 8 (API 26): below it mpv falls back to its null output and
  /// nothing is heard. `opensles` plays stereo only.
  ///
  /// Pass `'auto'` or an empty string to let mpv auto-probe the best
  /// available backend (the default). mpv has no backend literally named
  /// `auto` (setting `ao=auto` fails to initialize any output), so both
  /// are normalized to an empty `ao`, which is mpv's auto-probe value.
  Future<void> setAudioDriver(String driver) async {
    await _gate();
    // 'auto' is a convenience alias for mpv's empty-string auto-probe;
    // the literal string 'auto' is not a valid AO backend.
    final ao = driver == 'auto' ? '' : driver;
    await _calls.prop('ao', ao);
    _updateField(
      (s) => s.copyWith(audioDriver: ao),
      _reactives.audioDriver,
      ao,
    );
  }

  // ── Spectrum and PCM streams ───────────────────────────────────────
  // The FFT spectrum + raw PCM streams are a separate subsystem from
  // the typed mpv setters above: they don't write any mpv property,
  // they configure the polling pipeline that reads the
  // `pcm-tap-frame` property at the configured emit rate.

  /// Replaces the spectrum and PCM pipeline configuration.
  ///
  /// Use for full-bundle config (initial setup, preset application).
  /// To mutate a single field (typical of UI sliders), prefer
  /// [updateSpectrum].
  ///
  /// Reallocates FFT memory only when [SpectrumSettings.fftSize],
  /// window or band layout actually changes; idempotent on no-op
  /// settings. Re-arms the poll timer when [SpectrumSettings.emitInterval]
  /// changes mid-stream.
  ///
  /// Synchronous: the pipeline is Dart-side, so the new settings are in
  /// [PlayerState.spectrum] when the call returns, even before the player
  /// has finished starting. The pipeline is **lazy**: with no subscriber
  /// to [PlayerStream.fft] or [PlayerStream.pcm] this only stores the
  /// configuration; the poll loop starts on the first subscriber.
  ///
  /// Throws [ArgumentError] (a [RangeError] for a bound), with the state
  /// unchanged, when a field is outside the range its doc gives. The
  /// constructor's asserts check the same ranges, but a release build
  /// skips them.
  void setSpectrum(SpectrumSettings settings) {
    _checkNotDisposed();
    settings.validate();
    assert(
      settings.emitInterval >= SpectrumPipeline.minEmitInterval,
      'emitInterval must be at least 8 ms',
    );
    _updateField(
      (s) => s.copyWith(spectrum: settings),
      _reactives.spectrum,
      settings,
    );
    if (_bringUpCompleted) _spectrumPipeline.setSettings(settings);
  }

  /// Mutates the spectrum settings with a Freezed-style copyWith
  /// mapper.
  ///
  /// Convenience over `setSpectrum(state.spectrum.copyWith(...))`.
  /// The mapper receives the current bundle and must return the new
  /// one: same semantics as `Player.updateAudioEffects`.
  ///
  /// Example:
  /// ```dart
  /// // Switch to 60 fps with a Blackman-Harris window:
  /// player.updateSpectrum((s) => s.copyWith(
  ///   emitInterval: const Duration(milliseconds: 16),
  ///   window: WindowFunction.blackmanHarris,
  /// ));
  /// ```
  void updateSpectrum(SpectrumSettings Function(SpectrumSettings) mapper) {
    setSpectrum(mapper(_state.spectrum));
  }
}
