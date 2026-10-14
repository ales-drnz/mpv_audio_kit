// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'package:meta/meta.dart';

/// The platform resources behind the playlist entries, released once mpv
/// can no longer read them.
///
/// An Android `content://` URI reaches mpv as `fd://N`, and mpv never
/// closes an `fd://` descriptor: it reads it again for every open of the
/// entry (a previous, a loop, a prefetch). So the player keeps the
/// descriptor while the entry is in the playlist, keyed by the URI mpv
/// lists (`N` is unique while the descriptor is open).
///
/// An entry that leaves the playlist can still be read for a while: the
/// stream of the current file closes when mpv ends it, and a prefetched
/// next entry stays open until mpv starts another file and drops the
/// prefetch. A descriptor closed earlier could be reused by the next open
/// and read by the stream on its way out. So a release waits for a file
/// start after the entry left, then for that start to settle (the file
/// loaded or failed), and runs at the latest when the player is disposed.
@internal
class HeldSources {
  final _holds = <String, _Hold>{};
  int _starts = 0;

  /// Whether nothing is held.
  bool get isEmpty => _holds.isEmpty;

  /// Holds [release] for the entries mpv lists as [uri]. Returns the
  /// release to call when the load aborts before mpv got the URI: it runs
  /// once and drops the hold.
  Future<void> Function() hold(String uri, Future<void> Function() release) {
    final h = _Hold(release);
    _holds[uri] = h;
    return () {
      if (identical(_holds[uri], h)) _holds.remove(uri);
      return h.run();
    };
  }

  /// A playlist report: the URIs of every entry it lists.
  void onPlaylist(Iterable<String> listed) {
    if (_holds.isEmpty) return;
    final live = listed.toSet();
    for (final MapEntry(key: uri, value: h) in _holds.entries) {
      if (live.contains(uri)) {
        h
          ..listed = true
          ..leftAt = null;
      } else if (h.listed) {
        h.leftAt ??= _starts;
      }
    }
  }

  /// mpv started a file (START_FILE).
  void onStartFile() => _starts++;

  /// mpv loaded a file or ended one (FILE_LOADED, END_FILE): returns the
  /// releases whose entry left before the last file start.
  List<Future<void> Function()> takeSettled() {
    final out = <Future<void> Function()>[];
    _holds.removeWhere((_, h) {
      final left = h.leftAt;
      if (left == null || left >= _starts) return false;
      out.add(h.run);
      return true;
    });
    return out;
  }

  /// Every release still held, for dispose.
  List<Future<void> Function()> takeAll() {
    final out = [for (final h in _holds.values) h.run];
    _holds.clear();
    return out;
  }
}

class _Hold {
  _Hold(this._release);

  final Future<void> Function() _release;
  bool _done = false;

  /// Whether a playlist report has listed the entry.
  bool listed = false;

  /// The file-start count when the entry left the playlist.
  int? leftAt;

  Future<void> run() async {
    if (_done) return;
    _done = true;
    await _release();
  }
}
