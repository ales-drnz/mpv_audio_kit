// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
part of '../player.dart';

/// Live PCM input: [openPcmStream] creates a [PcmSource] and opens it. The
/// player holds every source whose media it loaded while the entry is in
/// its playlist, so a source the app no longer references still plays,
/// and ends a source as stopped when its entry leaves the playlist unread
/// or the player is disposed.
mixin _PcmModule on _PlayerBase {
  /// Creates a live [PcmSource] of [format] and opens it as the sole
  /// playlist entry, like [Player.open] with its [PcmSource.toMedia].
  /// Feed the returned source and [PcmSource.close] it when the input
  /// ends: the entry then ends normally after the last sample.
  ///
  /// Playback starts a fraction of a second after the first chunk, as
  /// soon as mpv has read its first block of audio. [maxBuffered] and
  /// [lowLatency] are those of [PcmSource.create], [extras] that of
  /// [PcmSource.toMedia].
  ///
  /// When a later `open()` or `stop()` takes over before this one loads,
  /// the source ends as [PcmSourceState.stopped]. To queue several sources
  /// back to back, create them with [PcmSource.create] and pass their
  /// media to [Player.openAll] or [Player.add].
  ///
  /// ```dart
  /// final source = await player.openPcmStream(
  ///   const PcmFormat(sampleRate: 24000, channels: 1),
  /// );
  /// socket.listen(
  ///   (message) => source.add(message as Uint8List),
  ///   onDone: source.close,
  /// );
  /// ```
  Future<PcmSource> openPcmStream(
    PcmFormat format, {
    bool play = true,
    Duration maxBuffered = const Duration(seconds: 30),
    bool lowLatency = false,
    Map<String, Object?>? extras,
  }) async {
    _checkNotDisposed();
    final source = PcmSource.create(
      format,
      maxBuffered: maxBuffered,
      lowLatency: lowLatency,
    );
    try {
      await (this as Player).open(source.toMedia(extras: extras), play: play);
    } catch (_) {
      source.abort();
      rethrow;
    }
    // Superseded by a later open() or stop(), or a dispose: no entry, so
    // no reader will ever come.
    if (_disposed || !_pcmByEntry.containsValue(source)) source.endUnread();
    return source;
  }

  /// Holds the source of [media], loaded as playlist entry [entryId].
  @override
  void _holdPcm(int? entryId, Media media) {
    final source = pcmSourceFor(media.uri);
    if (source == null || source.isDone) return;
    // abort() first leaves the entry this player plays (see [_cutPcm]).
    source.addCutter(_cutPcm);
    if (entryId == null) return;
    _pcmByEntry[entryId] = source;
    // mpv does not always report the playlist again when the entry goes
    // (a stop while idle after a failed load): check it once in a while.
    _pcmCheckTimer ??= Timer(const Duration(milliseconds: 300), () {
      _pcmCheckTimer = null;
      if (_pcmByEntry.keys.any((id) => !_pcmSeen.contains(id))) {
        _confirmPcmEntries();
      }
    });
    unawaited(
      source.done.then((_) {
        _pcmByEntry.removeWhere((id, s) {
          if (!identical(s, source)) return false;
          _pcmSeen.remove(id);
          return true;
        });
      }),
    );
  }

  /// Lets go of the sources whose entries left the playlist: [live] holds
  /// the ids mpv reports now. An entry is dropped only once a playlist
  /// node showed it, so a node older than its loadfile does not end it.
  /// An entry missing before any node showed it (the observation merges
  /// changes: a stop right after the load) is checked against a fresh
  /// read of the playlist, which comes after its loadfile. A source no
  /// entry holds any more ends as stopped: read or not, the player will
  /// not come back to it.
  @override
  void _prunePcm(Set<int> live) {
    if (_pcmByEntry.isEmpty) return;
    final dropped = <PcmSource>[];
    var unseenMissing = false;
    _pcmByEntry.removeWhere((id, source) {
      if (live.contains(id)) {
        _pcmSeen.add(id);
        return false;
      }
      if (!_pcmSeen.remove(id)) {
        unseenMissing = true;
        return false;
      }
      dropped.add(source);
      return true;
    });
    _endDropped(dropped);
    if (unseenMissing) _confirmPcmEntries();
  }

  // A playlist read for [_confirmPcmEntries] is under way, and whether
  // another node asked for one meanwhile.
  bool _pcmConfirming = false;
  bool _pcmConfirmAgain = false;
  Timer? _pcmCheckTimer;

  /// Reads the playlist and drops the held entries it does not list. The
  /// read is issued after every held entry's loadfile reply, so an entry
  /// it misses has left the playlist.
  void _confirmPcmEntries() {
    if (_pcmConfirming) {
      _pcmConfirmAgain = true;
      return;
    }
    _pcmConfirming = true;
    final held = _pcmByEntry.keys.toSet();
    unawaited(() async {
      try {
        final (rc, node) = await _getAsync('playlist', MpvFormat.mpvFormatNode);
        if (rc < 0 || node is! List || _disposed) return;
        final live = {
          for (final entry in node)
            if (entry is Map && entry['id'] is int) entry['id'] as int,
        };
        final dropped = <PcmSource>[];
        _pcmByEntry.removeWhere((id, source) {
          if (!held.contains(id)) return false;
          if (live.contains(id)) {
            _pcmSeen.add(id);
            return false;
          }
          _pcmSeen.remove(id);
          dropped.add(source);
          return true;
        });
        _endDropped(dropped);
      } finally {
        _pcmConfirming = false;
        if (_pcmConfirmAgain && !_disposed) {
          _pcmConfirmAgain = false;
          _confirmPcmEntries();
        }
      }
    }());
  }

  void _endDropped(List<PcmSource> dropped) {
    for (final source in dropped) {
      if (!_pcmByEntry.containsValue(source)) source.endUnread();
    }
  }

  /// Leaves the entry when mpv plays [source], which is being aborted: the
  /// next entry starts, or playback stops at the last one (wraps to the
  /// first with `loop-playlist` on), without the audio output playing out
  /// what it holds. Asks mpv which entry plays, since the playlist in the
  /// state can lag it. `null` when this player holds no entry of [source].
  Future<void>? _cutPcm(PcmSource source) {
    if (_disposed) return null;
    // Taken now: the abort completes `done`, which drops the entries.
    final ids = {
      for (final e in _pcmByEntry.entries)
        if (identical(e.value, source)) e.key,
    };
    if (ids.isEmpty) return null;
    return () async {
      final (rc, node) = await _getAsync('playlist', MpvFormat.mpvFormatNode);
      if (rc < 0 || node is! List || _disposed) return;
      for (final entry in node) {
        if (entry is! Map || entry['playing'] != true) continue;
        if (ids.contains(entry['id'])) {
          await _command(['playlist-next', 'force']);
        }
        return;
      }
    }();
  }

  /// Ends every source the player holds as stopped (dispose).
  void _endPcmSources() {
    _pcmCheckTimer?.cancel();
    _pcmCheckTimer = null;
    final sources = _pcmByEntry.values.toSet();
    _pcmByEntry.clear();
    _pcmSeen.clear();
    for (final source in sources) {
      source.endUnread();
    }
  }
}
