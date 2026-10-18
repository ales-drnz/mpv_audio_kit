// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of '../player.dart';

/// mpv's input command prefixes, which may precede the command name.
const _kCommandPrefixes = {
  'no-osd',
  'osd-auto',
  'osd-bar',
  'osd-msg',
  'osd-msg-bar',
  'raw',
  'expand-properties',
  'repeatable',
  'nonrepeatable',
  'nonscalable',
  'async',
  'sync',
};

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

/// Low-level native bridge: the raw property and command calls every typed
/// setter funnels through, the `chapter-list` NODE writer, and the mpv
/// error-string lookup. Declared `on _PlayerBase` so the constructor,
/// `dispose`, and the domain mixins can reach these across part boundaries
/// (their abstract signatures live on `_PlayerBase`).
///
/// Every write and read here goes through the ASYNC client API: the FFI call
/// only enqueues the request (libmpv deep-copies the arguments) and the
/// future completes when the event isolate forwards the matching reply.
/// The synchronous client API waits for the core's playloop to serve the
/// request, and the playloop can be stuck for seconds inside audio-output
/// init (a Bluetooth or AirPlay device waking up): on the main isolate that
/// wait is the macOS beachball. Never reintroduce a synchronous
/// set, get or command on the main isolate.
mixin _FfiModule on _PlayerBase {
  /// Writes a property and throws [MpvCommandException] on rejection.
  ///
  /// The typed setters (setVolume, setRate, …) flow through this method;
  /// the effects chain goes through the `af set` command instead. Errors
  /// are surfaced rather than swallowed so the caller can react
  /// (out-of-range value, unknown name, etc.). `_propRc` is the
  /// rc-returning variant for the few call sites that need to tolerate
  /// failures explicitly.
  @override
  Future<void> _prop(String name, String value) async {
    final rc = await _propRc(name, value);
    if (rc < 0) {
      throw MpvCommandException(
        name: name,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  @override
  Future<int> _propRc(String name, String value) =>
      _client.setProperty(name, value);

  @override
  Future<int> _command(List<String> args) =>
      _commandResult(args).then((reply) => reply.$1);

  /// [_command] that also returns the command's decoded result node.
  Future<(int, Object?)> _commandResult(List<String> args) =>
      _client.command(args);

  /// Applies a settings bundle backed by several mpv properties: [writes]
  /// holds `(property, value, prior value)`. The state takes [next] first,
  /// so mpv's echo of each write matches it instead of emitting a
  /// half-applied bundle. If a write fails, the written properties and
  /// the state go back to [previous] before the error is rethrown.
  @override
  Future<void> _writeBundle<T>(
    List<(String, String, String)> writes,
    ReactiveProperty<T> reactive,
    PlayerState Function(PlayerState state, T value) put,
    T next,
    T previous,
  ) async {
    _updateField((s) => put(s, next), reactive, next);
    final committed = <(String, String)>[];
    try {
      for (final (name, value, prior) in writes) {
        await _prop(name, value);
        committed.add((name, prior));
      }
    } catch (_) {
      for (final (name, prior) in committed.reversed) {
        await _propRc(name, prior);
      }
      _updateField((s) => put(s, previous), reactive, previous);
      rethrow;
    }
  }

  /// Runs a playlist navigation command and returns whether it moved:
  /// mpv answers [MpvError.mpvErrorCommand] when there is nowhere to go,
  /// which is a normal outcome, not an error.
  @override
  Future<bool> _navigate(List<String> args) async {
    final rc = await _command(args);
    if (rc >= 0) return true;
    if (rc == MpvError.mpvErrorCommand) return false;
    throw MpvCommandException(
      name: args.first,
      code: rc,
      message: _errorString(rc),
    );
  }

  /// Throws [RangeError] unless [index] is a valid playlist position, per
  /// mpv's own `playlist-count` (the Dart state can lag behind an `add`
  /// still in flight). Returns the count, or `null` when a dispose landed
  /// meanwhile: it drained the read as failed, and the call then ends
  /// without effect, like any call under way at dispose, instead of
  /// reporting an index out of an empty playlist.
  @override
  Future<int?> _checkPlaylistIndex(int index, String name) async {
    final (rc, value) = await _getAsync(
      'playlist-count',
      MpvFormat.mpvFormatInt64,
    );
    if (_disposed) return null;
    final count = rc < 0 ? 0 : value as int;
    RangeError.checkValidIndex(index, null, name, count);
    return count;
  }

  /// Runs a `loadfile` [args] for [media] and records the new playlist
  /// entry's id, so the playlist maps that entry back to [media] even when
  /// another entry has the same URI. Throws like [_commandChecked].
  @override
  Future<void> _loadfile(List<String> args, Media media) async {
    final id = await _loadfileEntry(args, media);
    if (id != null) _remapReported({id});
  }

  /// The part of [_loadfile] before the remap: runs the command and
  /// records the entry, returning its id. A batch of appends remaps once,
  /// after the last reply, instead of once per entry.
  Future<int?> _loadfileEntry(List<String> args, Media media) async {
    final (rc, result) = await _commandResult(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
    final id = result is Map ? result['playlist_entry_id'] : null;
    if (media.isPcmStream) _holdPcm(id is int ? id : null, media);
    if (id is! int) return null;
    _mediaByEntry[id] = media;
    _heldSources.onAdded(args[1], id);
    return id;
  }

  /// mpv may report the playlist before the `loadfile` replies: when the
  /// last playlist node already lists one of [ids], parse it again so the
  /// entries map to their [Media].
  void _remapReported(Set<int> ids) {
    final node = _lastPlaylistNode;
    if (node is List &&
        node.any((entry) => entry is Map && ids.contains(entry['id']))) {
      _updatePlaylistFromNode(node);
    }
  }

  /// [_command] that throws [MpvCommandException] on rejection: the command
  /// counterpart of [_prop], used by the typed methods whose failure is
  /// a caller-visible error (seek with nothing loaded, loadfile with
  /// malformed options). Call sites where a non-zero rc is an expected
  /// outcome use [_navigate] (`playlist-next weak` at the last entry) or
  /// keep the raw rc-returning variant (`playlist-remove current` on an
  /// empty playlist, the internal steps of `openAll`).
  @override
  Future<void> _commandChecked(List<String> args) async {
    final rc = await _command(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  @override
  Future<(int, dynamic)> _getAsync(String name, int format) =>
      _client.getProperty(name, format);

  /// Writes [chapters] to mpv's `chapter-list` (a NODE-array property)
  /// via `mpv_set_property_async`, resolving with the raw mpv rc.
  ///
  /// `chapter-list` is an array of maps `{title: string, time: double secs}`.
  /// The whole node tree is built in an [Arena]; the async setter deep-copies
  /// it before returning (`m_option_copy` on the NODE option type), so every
  /// allocation is freed on return. An empty list writes an empty array
  /// (clears the chapters).
  @override
  Future<int> _setChapterListNode(List<Chapter> chapters) =>
      _client.setNodeProperty('chapter-list', (arena) {
        final n = chapters.length;
        final arrayList = arena<MpvNodeList>();
        arrayList.ref.num = n;
        // Arrays carry no keys (maps do); leave them null.
        arrayList.ref.keys = nullptr;
        if (n > 0) {
          final elements = arena<MpvNode>(n);
          for (var i = 0; i < n; i++) {
            final ch = chapters[i];
            // Two map entries per chapter: title (string) + time (double secs).
            final entryValues = arena<MpvNode>(2);
            final entryKeys = arena<Pointer<Utf8>>(2);

            entryKeys[0] = 'title'.toNativeUtf8(allocator: arena);
            entryValues[0].format = MpvFormat.mpvFormatString;
            entryValues[0].u.string = (ch.title ?? '').toNativeUtf8(
              allocator: arena,
            );

            entryKeys[1] = 'time'.toNativeUtf8(allocator: arena);
            entryValues[1].format = MpvFormat.mpvFormatDouble;
            entryValues[1].u.double_ = ch.time.inMicroseconds / 1e6;

            final map = arena<MpvNodeList>();
            map.ref.num = 2;
            map.ref.values = entryValues;
            map.ref.keys = entryKeys;

            elements[i].format = MpvFormat.mpvFormatNodeMap;
            elements[i].u.list = map;
          }
          arrayList.ref.values = elements;
        } else {
          arrayList.ref.values = nullptr;
        }

        final root = arena<MpvNode>();
        root.ref.format = MpvFormat.mpvFormatNodeArray;
        root.ref.u.list = arrayList;
        return root;
      });

  @override
  String _errorString(int code) => _client.errorString(code);

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
    final (error, value) = await _getAsync(name, MpvFormat.mpvFormatString);
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
    final (error, value) = await _getAsync(name, MpvFormat.mpvFormatNode);
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
    await _prop(name, value);
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
    var i = 0;
    while (i < args.length && _kCommandPrefixes.contains(args[i])) {
      i++;
    }
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
    final rc = await _command(args);
    if (rc < 0) {
      throw MpvCommandException(
        name: args.isEmpty ? '<empty>' : args.first,
        code: rc,
        message: _errorString(rc),
      );
    }
  }

  /// Changes the engine log verbosity at runtime (the initial value comes
  /// from [PlayerConfiguration.logLevel]). Synchronous: before the player
  /// has finished starting, the level is kept and applied once it has.
  void setLogLevel(LogLevel level) {
    _checkNotDisposed();
    _pendingLogLevel = level;
    if (_bringUpCompleted) _applyLogLevel(level);
  }

  @override
  void _applyLogLevel(LogLevel level) {
    if (_client.isClosed) return;
    // `mpv_request_log_messages` is thread-safe and operates on the shared
    // client handle the same way the main-thread getRawProperty path does,
    // so there's no need to round-trip through the event isolate.
    // [LogLevel.off] already maps to mpv's `no`.
    using(
      (arena) => _lib.mpvRequestLogMessages(
        _handle,
        level.mpvValue.toNativeUtf8(allocator: arena),
      ),
    );
  }
}
