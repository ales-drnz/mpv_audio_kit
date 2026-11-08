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

/// The effects chain: the [AudioEffect] list written to mpv's `af`, its
/// live updates through `af-command`, and the chain written again at each
/// load.
mixin _EffectsModule on _PlayerBase {
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
  /// It throws the same way for a `params` key that is no option name,
  /// such as one with a `:` or a `,`, which would add options or filters
  /// to the chain.
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
  // mpv keeps each filter with its arguments, and rebuilds it from them
  // at a file load, at a seek or loop wrap (lavfi frees its graph on
  // reset), at a track switch and at a format change. The patch
  // af_command_args saves an af-command that took in the arguments of its
  // filter, and in `af`, so those rebuilds keep the values set live, and an
  // `af set` rebuilds only the filters whose arguments it changes.

  /// The last list mpv accepted, through `af set` or a whole diff of
  /// `af-command`s: what it plays when a later write is refused, and so
  /// what the state rolls back to. `null` until the first write, which
  /// always goes through to override an `af` already there, even empty.
  List<AudioEffect>? _afAccepted;

  /// The confirmation of the last write, which the next one waits for
  /// before it looks at [_afAccepted]: an empty diff has no reply to wait
  /// on and would otherwise settle ahead of an earlier write.
  Future<void> _afSettled = Future.value();

  /// mpv's `af` as read right after the last chain write or live diff, in
  /// mpv's own printing, or `null` when unknown: a file started between
  /// the write and the read, or the read failed. The player is the only
  /// other writer of `af`, so a different value at a load comes from a
  /// resume point that still holds a chain.
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
    final previous = _state.settings.audioEffects;
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
      // af_command_args moves `af` with each command that takes.
      if (cmds.isNotEmpty) _readAfHeld();
      settled = _settleAfCommands(_afSettled, rcs, effects, previous);
    } else {
      settled = _rewriteAfChain(_afSettled, effects);
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
    _readAfHeld();
    return reply;
  }

  /// Reads `af` into [_afHeld]. Queued right behind a chain write or a
  /// diff: mpv runs them in order, so the read sees the chain they left,
  /// refused or not, unless a file started in between and its resume point
  /// set `af`.
  void _readAfHeld() {
    final starts = _transport.fileStarts;
    unawaited(
      _calls.get('af', MpvFormat.mpvFormatString).then((r) {
        final (rc, af) = r;
        _afHeld = rc >= 0 && af is String && starts == _transport.fileStarts
            ? af
            : null;
      }),
    );
  }

  /// A resume point written by 0.5.1 or earlier holds an `af` line, which
  /// mpv applies as it loads the file. Once the player wrote a chain, a
  /// chain it did not write gives way to the state's. Before that, a
  /// chain already there stays until the first write, as documented on
  /// [setAudioEffects].
  @override
  void _reassertAfChain() {
    if (_afAccepted != null) {
      unawaited(_reassertAfChainFor(_transport.fileStarts));
    }
  }

  Future<void> _reassertAfChainFor(int starts) async {
    final (rc, af) = await _calls.get('af', MpvFormat.mpvFormatString);
    // A newer load checks for itself.
    if (rc < 0 ||
        _disposed ||
        starts != _transport.fileStarts ||
        af == _afHeld) {
      return;
    }
    final effects = _state.settings.audioEffects;
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
  }

  /// Puts the state back on [_afAccepted] after mpv refused [effects],
  /// unless a later call already replaced them, and throws. A diff that
  /// mpv took meanwhile may have moved the live graph, and saved its
  /// values (af_command_args): the chain is written again from the accepted
  /// list, which rebuilds every stage whose values moved (F50).
  Never _refuseAudioEffects(List<AudioEffect> effects, int rc) {
    if (identical(_state.settings.audioEffects, effects)) {
      final accepted = _afAccepted ?? const <AudioEffect>[];
      _updateField(
        (s) => s.copyWith(audioEffects: accepted),
        _reactives.audioEffects,
        accepted,
      );
      unawaited(
        _setAfChain(audioEffectsChain(accepted)).then((rc) {
          if (rc < 0) {
            _internalLog(
              'Writing back the effects chain mpv accepted failed: '
              '${_calls.errorString(rc)}',
              level: LogLevel.debug,
            );
          }
        }),
      );
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
    final healed = _state.settings.audioEffects;
    final healRc = await _setAfChain(audioEffectsChain(healed));
    if (healRc >= 0) {
      _afAccepted = healed;
      return;
    }
    _refuseAudioEffects(effects, healRc);
  }

  /// Awaits the full-rewrite reply. On rejection (e.g. a malformed
  /// [RawAudioEffect]) mpv keeps the old chain, the optimistic commit is
  /// rolled back to the last list mpv accepted (unless a later update
  /// already replaced it), and the [MpvCommandException] propagates to the
  /// caller.
  Future<void> _rewriteAfChain(
    Future<void> prior,
    List<AudioEffect> effects,
  ) async {
    final rewrite = _setAfChain(audioEffectsChain(effects));
    await prior;
    final rc = await rewrite;
    if (rc >= 0) {
      _afAccepted = effects;
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
    await _applyAudioEffects(mapper(_state.settings.audioEffects));
  }
}
