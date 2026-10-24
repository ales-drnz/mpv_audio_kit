// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

// The `%n%` length prefix and the list actions of an option name.
final _kCountedPrefix = RegExp(r'^%\d+%');
final _kListAction = RegExp(
  r'^(.+)-(add|append|pre|set|clr|del|remove|toggle)$',
);

/// The option names in a `key=value,key=value` list, the per-file options
/// of `loadfile`, unquoted: mpv also takes `"key"`, `[key]` and `%n%key`.
/// A value can itself hold commas, so this may also return a word from
/// inside one: good enough to spot `af` and `pause`.
Iterable<String> _optionKeys(String options) sync* {
  for (final part in options.split(',')) {
    final eq = part.indexOf('=');
    var key = (eq < 0 ? part : part.substring(0, eq)).trim();
    final counted = _kCountedPrefix.firstMatch(key);
    if (counted != null) key = key.substring(counted.end);
    if (key.length >= 2 &&
        ((key.startsWith('"') && key.endsWith('"')) ||
            (key.startsWith('[') && key.endsWith(']')))) {
      key = key.substring(1, key.length - 1);
    }
    yield key;
  }
}

/// The property an option name on the command line writes: `no-pause`
/// sets `pause`, and `af-add`, `af-set` and the other list actions edit
/// `af`.
String _optionProperty(String key) {
  if (key.startsWith('no-')) return key.substring(3);
  final list = _kListAction.firstMatch(key);
  return list == null ? key : list.group(1)!;
}

/// Commands whose second argument names a property they write.
const _kPropertyCommands = {
  'set',
  'add',
  'multiply',
  'cycle',
  'cycle-values',
  'change-list',
};

/// Test only: awaited by the cut of an aborted source between its read of
/// the playlist and the removal of a queued entry, so a test can put
/// another playlist change in that window. Not exported: the library shows
/// only [Player].
@visibleForTesting
Future<void> Function()? debugBeforePcmCutRemove;

/// The `loadfile` of a [Media] with its entry bookkeeping (the entry in
/// [_PlayerBase._entries], the cut of an aborted live source), and the
/// public raw escape hatches (property reads and writes, commands, log
/// level). The calls themselves go through [_PlayerBase._calls]
/// ([CoreCalls]), on the async client API.
mixin _FfiModule on _PlayerBase {
  /// Runs a `loadfile` [args] for [media] and records the new playlist
  /// entry's id, so the playlist maps that entry back to [media] even when
  /// another entry has the same URI. Hands [source] over to the entry as
  /// the command goes out. Throws like [CoreCalls.commandChecked].
  @override
  Future<void> _loadfile(
    List<String> args,
    Media media,
    OwnedSource source,
  ) async {
    final id = await _loadfileEntry(args, media, source);
    if (id != null) _remapReported({id});
  }

  /// The part of [_loadfile] before the remap: runs the command and
  /// records the entry, returning its id. A batch of appends remaps once,
  /// after the last reply, instead of once per entry.
  Future<int?> _loadfileEntry(
    List<String> args,
    Media media,
    OwnedSource source,
  ) async {
    final reply = _calls.commandResult(args);
    // Sent: mpv has the entry from now on, even if a later load supersedes
    // this one before the reply (F6). Only a refusal gives the source back.
    final entry = _entries.pending(args[1], media, source.handOver());
    final (rc, result) = await reply;
    if (rc < 0) {
      source.revoke();
      _entries.drop(entry);
      throw MpvCommandException(
        name: args.first,
        code: rc,
        message: _calls.errorString(rc),
      );
    }
    final id = result is Map ? result['playlist_entry_id'] : null;
    final entryId = id is int ? id : null;
    _entries.onAdded(entry, entryId, live: _liveSource(media));
    return entryId;
  }

  /// mpv may report the playlist before the `loadfile` replies: when the
  /// last playlist node already lists one of [ids], parse it again so the
  /// entries map to their [Media].
  void _remapReported(Set<int> ids) {
    final node = _entries.lastNode;
    if (node is List &&
        node.any((entry) => entry is Map && ids.contains(entry['id']))) {
      _updatePlaylistFromNode(node);
    }
  }

  /// The live PCM source [media] plays, when it is not done: its entry
  /// holds it while it is in the playlist, and an abort of the source
  /// takes the entry out first ([_cutPcm]).
  LiveSource? _liveSource(Media media) {
    if (!media.isPcmStream) return null;
    final source = pcmSourceFor(media.uri);
    if (source == null || source.isDone) return null;
    source.addCutter(_cutPcm);
    return (key: source, done: source.done, end: source.endUnread);
  }

  /// Takes the entries of [source], which is being aborted, out of
  /// playback. The entry mpv plays is left: the next entry starts, or
  /// playback stops at the last one (wraps to the first with
  /// `loop-playlist` on), without the audio output playing out what it
  /// holds. A queued entry leaves the playlist: loaded later, it would
  /// fail. Asks mpv for the playlist, since the one in the state can lag
  /// it, and again before each removal, since mpv removes by index and an
  /// index read earlier can be stale: until no command that moves the
  /// indices went out between the read and the removal. Not behind the
  /// playlist calls: abort waits for the cut 1 s at most. `null` when this
  /// player holds no entry of [source].
  Future<void>? _cutPcm(PcmSource source) {
    if (_disposed) return null;
    // Taken now: the abort completes `done`, which drops the entries.
    final ids = _entries.liveIds(source);
    if (ids.isEmpty) return null;
    return () async {
      final node = await _readPlaylist();
      if (node == null) return;
      final queued = <Object?>[];
      var playing = false;
      for (final entry in node) {
        if (entry is! Map || !ids.contains(entry['id'])) continue;
        if (entry['playing'] == true) {
          playing = true;
        } else {
          queued.add(entry['id']);
        }
      }
      if (playing) await _calls.command(['playlist-next', 'force']);
      for (final id in queued) {
        // A command that moved the indices after the read (a remove or an
        // insert of the app) makes the read stale: read again. The removal
        // then goes out with nothing between, so mpv takes it in order.
        // Bounded: the abort waits for the cut 1 s at most anyway.
        for (var tries = 0; tries < 8; tries++) {
          final shifts = _calls.playlistShifts;
          final now = await _readPlaylist();
          if (now == null) return;
          await debugBeforePcmCutRemove?.call();
          if (shifts != _calls.playlistShifts) continue;
          final at = now.indexWhere((e) => e is Map && e['id'] == id);
          // Gone already, or taken by a later call. One that became the
          // current entry meanwhile is cut by the removal too.
          if (at >= 0) await _calls.command(['playlist-remove', '$at']);
          break;
        }
      }
    }();
  }

  // ── Public raw escape hatches ────────────────────────────────────────────

  /// Reads any mpv property as a string.
  ///
  /// **Escape hatch for properties not surfaced by the typed API.** For
  /// observed properties (`volume`, `pause`, `cache-secs`, …), prefer
  /// `player.state.<field>`: the cached value is updated on every
  /// property-change event from mpv and avoids an FFI round-trip.
  ///
  /// Returns `null` if the property doesn't exist or the read
  /// fails. Throws [PlayerDisposedException] if the player has been disposed.
  @override
  Future<String?> getRawProperty(String name) async {
    await _gate();
    final (error, value) = await _calls.get(name, MpvFormat.mpvFormatString);
    return error < 0 ? null : value as String?;
  }

  /// Reads any mpv property as a decoded node tree.
  ///
  /// Typed counterpart of [getRawProperty] for structured properties
  /// (`track-list`, `metadata`, `demuxer-cache-state`, …): returns the
  /// same shapes the event pipeline produces (`Map<String, dynamic>`,
  /// `List<dynamic>`, [String], [int], [double], [bool], byte arrays),
  /// with no string re-parsing on the caller's side.
  ///
  /// Returns `null` if the property doesn't exist or is currently
  /// unavailable. Throws [PlayerDisposedException] if the player has been disposed.
  Future<Object?> getRawPropertyNode(String name) async {
    await _gate();
    final (error, value) = await _calls.get(name, MpvFormat.mpvFormatNode);
    return error < 0 ? null : value;
  }

  /// Writes any mpv property as a string.
  ///
  /// **Warning:** this is an escape hatch for properties the typed API
  /// doesn't yet cover. If [name] is one of the registry-observed
  /// properties (volume, cache-*, replaygain*, ao, …), the
  /// resulting state mutation will *also* flow through the property
  /// observer on mpv's side, so `player.state` and `player.stream` will
  /// stay consistent, but expect a one-event-loop-tick delay between
  /// the call returning and the cached state catching up. Prefer the
  /// typed setters (`setVolume`, `setCache`, `setReplayGain`, …) when
  /// they exist, both for type-safety and because they update the state
  /// as soon as mpv confirms the write, without waiting for the observer.
  ///
  /// Two properties are reserved and rejected:
  /// - `af`: owned by the effects chain (raw lavfi entries included, as
  ///   [RawAudioEffect] stages); a raw write would silently desync
  ///   `state.audioEffects`. Use [setAudioEffects] or [updateAudioEffects].
  /// - `pause`: owned by the transport intent axis. It is deliberately not
  ///   observed (see [PlayerState.playWhenReady]), so a raw write would
  ///   change actual playback while leaving `state.playWhenReady` (and the
  ///   OS play-pause button bound to it) reporting the old intent. Use
  ///   [play] or [pause].
  ///
  /// Throws [PlayerDisposedException] if the player has been disposed,
  /// [ArgumentError] if [name] is reserved, or [MpvCommandException] if mpv
  /// rejects the property write (unknown name, out-of-range value, etc.).
  @override
  Future<void> setRawProperty(String name, String value) async {
    _checkNotOwned(name, 'name');
    await _gate();
    await _calls.prop(name, value);
  }

  /// Throws [ArgumentError] when [name] is a property the player owns:
  /// `af` (the effects chain) or `pause` (the transport intent), also
  /// through the `options/` and `file-local-options/` prefixes, which
  /// write the same option.
  void _checkNotOwned(String name, String argName) {
    for (final prefix in const ['options/', 'file-local-options/']) {
      if (name.startsWith(prefix)) {
        _checkNotOwned(name.substring(prefix.length), argName);
        return;
      }
    }
    if (name == 'af') {
      throw ArgumentError.value(
        name,
        argName,
        'Property `af` is owned by the effects chain. '
        'Use Player.setAudioEffects or updateAudioEffects, and pass '
        'experimental or expression-based filters as a RawAudioEffect.',
      );
    }
    if (name == 'pause') {
      throw ArgumentError.value(
        name,
        argName,
        'Property `pause` is owned by the transport intent axis and is not '
        'observed, so a raw write would desync state.playWhenReady (and '
        'the OS play-pause button) from actual playback. '
        'Use Player.play() or Player.pause() instead.',
      );
    }
  }

  /// Sends a raw mpv command.
  ///
  /// **Escape hatch.** Same caveats as [setRawProperty]: prefer the
  /// typed playback and playlist methods (`play`, `pause`, `seek`,
  /// `add`, `jump`, …) when they cover your use case.
  ///
  /// The two properties [setRawProperty] reserves stay reserved here:
  /// `af` and `af-command`, and a command that writes `af` or `pause`
  /// (`set`, `add`, `multiply`, `cycle`, `cycle-values`, `change-list`),
  /// also after a prefix such as `no-osd`, through `options/` or
  /// `file-local-options/`, or in the per-file options of `loadfile`,
  /// throw [ArgumentError] before anything reaches mpv.
  ///
  /// Throws [PlayerDisposedException] if the player has been disposed,
  /// [ArgumentError] for a reserved command as above, or
  /// [MpvCommandException] if mpv rejects the command (unknown command,
  /// invalid argument, etc.). A successful return guarantees mpv
  /// accepted the command; the actual side-effect on playback state
  /// is observed asynchronously via [Player.stream].
  Future<void> sendRawCommand(List<String> args) async {
    // Symmetric guard with setRawProperty: mpv exposes `af` and
    // `af-command` as commands that mutate the audio chain incrementally,
    // and `set`, `change-list`, `cycle` and the like write any property,
    // `af` and `pause` included. Skip the command prefixes (`no-osd`, …)
    // before looking.
    final i = commandStart(args);
    if (i < args.length) {
      // mpv reads `_` in a command name as `-` (`change_list`).
      final command = args[i].replaceAll('_', '-');
      if (command == 'af' || command == 'af-command') {
        throw ArgumentError.value(
          command,
          'args',
          'Command `$command` is owned by the effects chain. '
              'Use Player.setAudioEffects or updateAudioEffects, and pass '
              'experimental or expression-based filters as a RawAudioEffect.',
        );
      }
      if (_kPropertyCommands.contains(command)) {
        // `cycle-values` takes flags such as `!reverse` before the name.
        var p = i + 1;
        while (p < args.length && args[p].startsWith('!')) {
          p++;
        }
        if (p < args.length) _checkNotOwned(args[p], 'args');
      }
      // `loadfile <url> <flags> <index> <options>` sets per-file options,
      // which can name `af` or `pause` too.
      if (command == 'loadfile' && i + 4 < args.length) {
        for (final key in _optionKeys(args[i + 4])) {
          _checkNotOwned(_optionProperty(key), 'args');
        }
      }
    }
    await _gate();
    final rc = await _calls.command(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _calls.errorString(rc),
      );
    }
  }

  /// Changes the engine log verbosity at runtime (the initial value comes
  /// from [PlayerConfiguration.logLevel]). Synchronous: before the player
  /// has finished starting, the level is kept and applied once it has.
  void setLogLevel(LogLevel level) {
    _checkNotDisposed();
    _pendingLogLevel = level;
    if (_bringUpCompleted) _calls.requestLogMessages(level);
  }
}
