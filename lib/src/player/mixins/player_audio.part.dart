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
  /// Sets volume (0–100; values above 100 amplify the signal, up to
  /// [PlayerState.volumeMax]). Throws [RangeError] when negative.
  Future<void> setVolume(double volume) async {
    _checkRange(volume, 0, double.maxFinite, 'volume');
    await _gate();
    final value = canonicalFloat(volume);
    await _prop('volume', value.toString());
    _updateField((s) => s.copyWith(volume: value), _reactives.volume, value);
  }

  /// Sets playback rate (1.0 = normal speed). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setRate(double rate) async {
    _checkRange(rate, 0.01, 100, 'rate');
    await _gate();
    await _prop('speed', rate.toString());
    _updateField((s) => s.copyWith(rate: rate), _reactives.rate, rate);
  }

  /// Sets pitch (1.0 = original pitch). Throws [RangeError] outside
  /// mpv's `[0.01, 100]`.
  Future<void> setPitch(double pitch) async {
    _checkRange(pitch, 0.01, 100, 'pitch');
    await _gate();
    await _prop('pitch', pitch.toString());
    _updateField((s) => s.copyWith(pitch: pitch), _reactives.pitch, pitch);
  }

  /// Mutes or unmutes audio output.
  Future<void> setMute(bool mute) async {
    await _gate();
    await _prop('mute', mute ? 'yes' : 'no');
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
    await _prop('audio-device', device.name);
    _updateActiveAudioDevice(device.name);
  }

  /// Enables or disables pitch correction (mpv's `audio-pitch-correction`,
  /// which inserts `scaletempo2`) for non-1.0 playback rates. Enabled by
  /// default. When disabled, raising the rate also raises the pitch.
  Future<void> setPitchCorrection(bool enable) async {
    await _gate();
    await _prop('audio-pitch-correction', enable ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(pitchCorrection: enable),
      _reactives.pitchCorrection,
      enable,
    );
  }

  /// Sets the audio delay relative to video (mpv's `audio-delay`).
  ///
  /// Sign convention: positive values **delay** audio relative to video
  /// (audio plays later), negative values **advance** it (audio plays
  /// earlier). This matches mpv's convention but is counterintuitive
  /// when thought of as "audio offset": positive does NOT mean "audio
  /// ahead".
  ///
  /// Sent to mpv in seconds with six decimals, so microseconds are kept.
  Future<void> setAudioDelay(Duration delay) async {
    await _gate();
    await _prop('audio-delay', durationToSeconds(delay).toStringAsFixed(6));
    _updateField(
      (s) => s.copyWith(audioDelay: delay),
      _reactives.audioDelay,
      delay,
    );
  }

  /// Enables or disables gapless playback. See [Gapless] for the
  /// available variants.
  Future<void> setGapless(Gapless gapless) async {
    await _gate();
    await _prop('gapless-audio', gapless.mpvValue);
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
    await _writeBundle(
      writes,
      _reactives.replayGain,
      (s, v) => s.copyWith(replayGain: v),
      settings,
      previous,
    );
  }

  /// Sets volume gain in dB (pre-amplification on top of [setVolume]).
  ///
  /// Hard range: -150 to +150 dB. The default soft clamp mpv applies is
  /// -96 to +12 dB, configurable via [setVolumeGainMin] and [setVolumeGainMax].
  /// 0 dB = unity. Values above ~+6 dB risk clipping unless [setReplayGain]
  /// or a downstream limiter is in the chain.
  Future<void> setVolumeGain(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _prop('volume-gain', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGain: value),
      _reactives.volumeGain,
      value,
    );
  }

  /// Sets the lower clamp applied to [setVolumeGain], in dB
  /// (mpv's `volume-gain-min`). Range -150 to 0; default -96.
  Future<void> setVolumeGainMin(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _prop('volume-gain-min', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGainMin: value),
      _reactives.volumeGainMin,
      value,
    );
  }

  /// Sets the upper clamp applied to [setVolumeGain], in dB
  /// (mpv's `volume-gain-max`). Range 0 to 150; default +12.
  Future<void> setVolumeGainMax(double gainDb) async {
    _checkFinite(gainDb, 'gainDb');
    await _gate();
    final value = canonicalFloat(gainDb);
    await _prop('volume-gain-max', value.toString());
    _updateField(
      (s) => s.copyWith(volumeGainMax: value),
      _reactives.volumeGainMax,
      value,
    );
  }

  /// Sets the OS per-app mixer volume in percent (`ao-volume`): the system
  /// volume slider for this app, distinct from the soft [setVolume].
  ///
  /// Best-effort: when the active audio output doesn't expose system volume
  /// (the null AO, or a backend without per-app volume) the call is silently
  /// ignored: it does NOT throw, and [PlayerState.systemVolume] stays `null`.
  Future<void> setSystemVolume(double volume) async {
    _checkFinite(volume, 'volume');
    await _gate();
    final value = canonicalFloat(volume);
    final rc = await _propRc('ao-volume', value.toString());
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemVolume: value),
        _reactives.systemVolume,
        value,
      );
    }
  }

  /// Sets the OS per-app mute (`ao-mute`), distinct from the soft [setMute].
  ///
  /// Best-effort, like [setSystemVolume]: silently ignored (no throw) when the
  /// active audio output doesn't expose system mute (e.g. coreaudio on macOS).
  Future<void> setSystemMute(bool mute) async {
    await _gate();
    final rc = await _propRc('ao-mute', mute ? 'yes' : 'no');
    if (rc >= 0) {
      _updateField(
        (s) => s.copyWith(systemMute: mute),
        _reactives.systemMute,
        mute,
      );
    }
  }

  /// Sets the upper bound the user-facing volume scale is clamped to.
  ///
  /// Range: 100 to 1000. Default 130 (matches mpv's default and the slider
  /// range most apps expose). Setting above 100 lets [setVolume] amplify
  /// past unity; values up to 1000 = +20 dB digital boost. mpv hard-rejects
  /// values below 100.
  Future<void> setVolumeMax(double limit) async {
    _checkFinite(limit, 'limit');
    await _gate();
    final value = canonicalFloat(limit);
    await _prop('volume-max', value.toString());
    _updateField(
      (s) => s.copyWith(volumeMax: value),
      _reactives.volumeMax,
      value,
    );
  }

  /// Requests exclusive use of the audio device (mpv's `audio-exclusive`).
  /// WASAPI, CoreAudio, AAudio and PipeWire honor it; on iOS AudioUnit it
  /// only turns off mixing with other apps, and other drivers ignore it.
  Future<void> setAudioExclusive(bool exclusive) async {
    await _gate();
    await _prop('audio-exclusive', exclusive ? 'yes' : 'no');
    _updateField(
      (s) => s.copyWith(audioExclusive: exclusive),
      _reactives.audioExclusive,
      exclusive,
    );
  }

  /// Whether mpv reports a "music" media role to the OS audio server
  /// (mpv's `audio-set-media-role`). On PulseAudio and PipeWire (Linux) this
  /// lets the server apply the right routing and volume profile for music;
  /// a no-op on backends without a media-role concept.
  Future<void> setAudioMediaRole(bool enable) async {
    await _gate();
    await _prop('audio-set-media-role', enable ? 'yes' : 'no');
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
  Future<void> setAudioSpdif(Set<Spdif> codecs) async {
    await _gate();
    await _prop('audio-spdif', Spdif.formatMpvList(codecs));
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
    await _prop('aid', track.mpvValue);
  }

  /// Loads an external audio file as an additional selectable track on the
  /// currently-playing file (mpv's `audio-add`), e.g. a separate-language
  /// dub or a commentary track. The new track appears in
  /// [PlayerState.tracks]; switch to it with [setAudioTrack].
  ///
  /// [select] `true` (default) selects the new track immediately; `false`
  /// adds it without switching. [title] and [lang] tag it for the track list.
  /// Requires a file to be loaded first. Per-[Media] options
  /// (`httpHeaders`, …) are validated but not applied: `audio-add` has no
  /// file-local options slot.
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
    final resolved = await resolveUri(file.uri);
    if (load.superseded) {
      await resolved.dispose?.call();
      return;
    }
    final args = <String>[
      'audio-add',
      resolved.uri,
      select ? 'select' : 'auto',
    ];
    // mpv's args are positional: to pass `lang` you must also pass `title`.
    if (title != null || lang != null) args.add(title ?? '');
    if (lang != null) args.add(lang);
    // An Android content:// URI arrives as an fd:// descriptor that mpv
    // never closes: held until the file the track joins ends.
    final dispose = resolved.dispose;
    final settle = dispose == null ? null : _heldSources.holdTrack(dispose);
    var added = false;
    try {
      added = await _command(args) >= 0;
    } finally {
      await settle?.call(added);
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
  Future<void> removeAudioTrack(Track track) async {
    _checkNotDisposed();
    if (track is TrackOff) {
      throw ArgumentError.value(
        track,
        'track',
        'Track.off has no meaning for removeAudioTrack — pass Track.id to '
            'remove a specific track or Track.auto to remove the current one.',
      );
    }
    await _gate();
    await _command(
      track is TrackId
          ? ['audio-remove', '${track.trackId}']
          : ['audio-remove'],
    );
  }

  /// Forcibly reloads the audio output.
  Future<void> reloadAudio() async {
    await _gate();
    await _commandChecked(['ao-reload']);
  }

  /// Re-scans sidecar external files (auto-loaded audio and cover art) for the
  /// current file: mpv's `rescan-external-files`. Use after dropping a cover
  /// or companion audio file next to the playing file so it gets picked up
  /// without reopening. With [keepSelection] the current track selection is
  /// preserved; otherwise mpv reselects the default streams. Newly found
  /// tracks and cover art fold into [PlayerState.tracks] and the cover-art
  /// stream.
  Future<void> rescanExternalFiles({bool keepSelection = false}) async {
    await _gate();
    await _commandChecked([
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
  /// then read or write out of its buffers with: chorus lists with
  /// different numbers of voices. A [RawAudioEffect] is not checked.
  ///
  /// A [RawAudioEffect] carries a lavfi entry written by hand, for
  /// expression-based filters or anything without a typed effect. The
  /// chain is the only writer of mpv's `af` property: raw writes via
  /// `setRawProperty('af', ...)` are rejected, and any pre-existing `af`
  /// value (e.g. from `mpv.conf`) is overridden by the first call here.
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
  /// always goes through to override any `af` from `mpv.conf`, even empty.
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
          _command(['af-command', c.label, c.option, c.value, c.filterName]),
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
    final reply = _command(['af', 'set', chain]);
    _afWritesInFlight++;
    return reply.whenComplete(() => _afWritesInFlight--);
  }

  /// Records that a chain write queued when [sent] diffs had gone out
  /// landed, and so carries them.
  void _afSynced(int sent) {
    if (sent > _afDiffsSynced) _afDiffsSynced = sent;
  }

  @override
  void _onAfChainReset() => _resyncStaleAfChain();

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
            '${_errorString(rc)}',
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
    throw MpvCommandException(name: 'af', code: rc, message: _errorString(rc));
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
    await _prop('cover-art-auto', cover.mpvValue);
    _updateField(
      (s) => s.copyWith(coverArtAuto: cover),
      _reactives.coverArtAuto,
      cover,
    );
  }

  /// Sets the target audio sample rate.
  Future<void> setAudioSampleRate(int rate) async {
    await _gate();
    await _prop('audio-samplerate', rate.toString());
    _updateField(
      (s) => s.copyWith(audioSampleRate: rate),
      _reactives.audioSampleRate,
      rate,
    );
  }

  /// Sets the target audio sample format. Use [Format.auto] to
  /// reset to mpv's pick.
  Future<void> setAudioFormat(Format format) async {
    await _gate();
    await _prop('audio-format', format.mpvValue);
    _updateField(
      (s) => s.copyWith(audioFormat: format),
      _reactives.audioFormat,
      format,
    );
  }

  /// Sets the target audio channel layout. Use the named static
  /// constants on [Channels] for common presets, or
  /// [Channels.custom] for any other mpv-recognised layout
  /// string.
  Future<void> setAudioChannels(Channels channels) async {
    await _gate();
    await _prop('audio-channels', channels.mpvValue);
    _updateField(
      (s) => s.copyWith(audioChannels: channels),
      _reactives.audioChannels,
      channels,
    );
  }

  /// Sets the audio client name.
  Future<void> setAudioClientName(String name) async {
    await _gate();
    await _prop('audio-client-name', name);
    _updateField(
      (s) => s.copyWith(audioClientName: name),
      _reactives.audioClientName,
      name,
    );
  }

  /// Sets the audio output driver, e.g. `'coreaudio'` (macOS),
  /// `'wasapi'` (Windows), `'pulse'`, `'alsa'` or `'pipewire'` (Linux).
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
    await _prop('ao', ao);
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
  void setSpectrum(SpectrumSettings settings) {
    _checkNotDisposed();
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
