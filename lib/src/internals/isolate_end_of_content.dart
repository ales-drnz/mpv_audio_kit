// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_isolate.dart';

// The end of content, read on the event isolate: which notifications take
// a read, the read itself ([MpvEventEndOfContent]) and the last-entry check
// of END_FILE.

/// The observed properties whose notifications take a fresh
/// [MpvEventEndOfContent] read. `eof-reached` is the direct one; `pause`
/// is observed here only for this (the player does not observe it): the
/// keep-open park pauses the core, which mpv notifies even when the
/// `eof-reached` change around it was skipped. A loop change at the park
/// turns the end of content on or off with nothing else moving.
const Set<String> _kEndOfContentTriggers = {
  'eof-reached',
  'pause',
  'loop-file',
  'loop-playlist',
};

/// Reply id of the isolate's own `pause` observer, above every id the main
/// isolate hands out.
const int _kPauseObserverReplyId = 1 << 62;

/// Reads where the core stands against the end of content and sends it as
/// [MpvEventEndOfContent]. The reads run when this isolate gets to them,
/// which under load can be well after mpv queued the events still waiting
/// here: a short entry can already have loaded and reached its end while
/// its START_FILE (and the previous entry's END_FILE) are still queued, and
/// a read sent ahead of them would raise `completed` for the player to
/// clear again on those events. So a read counts only for the entry whose
/// START_FILE this isolate already forwarded
/// ([_PropertyCache.started]); the newer entry's own FILE_LOADED and
/// PLAYBACK_RESTART read again. The current entry is read before and after
/// `eof-reached` and `pause`, so both belong to it.
void _sendEndOfContent(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  _PropertyCache cache,
) {
  final started = cache.started;
  if (started == null) return;
  final pos = _getPropInt64(lib, handle, 'playlist-pos');
  if (pos == null || pos < 0) return;
  if (_getPropInt64(lib, handle, 'playlist/$pos/id') != started.id) return;
  final eof = _getPropFlag(lib, handle, 'eof-reached') == 1;
  // With gapless audio mpv reports EOF once the decoder is done, while the
  // output buffer still plays; keep-open pauses the core only after it has
  // played out. Without `keep-open-pause` no pause comes, and EOF is the
  // closest signal left.
  final parked =
      eof &&
      (_getPropFlag(lib, handle, 'pause') == 1 ||
          _getPropFlag(lib, handle, 'keep-open-pause') == 0);
  final file = parked
      ? _getPropString(lib, handle, 'playlist/$pos/filename')
      : null;
  final live = file?.startsWith('mak-pcm://') ?? false;
  final timePos = parked ? _getPropDouble(lib, handle, 'time-pos') : null;
  final count = _getPropInt64(lib, handle, 'playlist-count');
  if (_getPropInt64(lib, handle, 'playlist-pos') != pos ||
      _getPropInt64(lib, handle, 'playlist/$pos/id') != started.id) {
    return;
  }
  // The park position supersedes a throttled time-pos still held back,
  // which would land after the event, as at PLAYBACK_RESTART. It is also
  // where the entry ended, for its END_FILE.
  if (parked) cache.trailing.remove('time-pos');
  if (timePos != null) started.position = timePos;
  toMain.send(
    MpvEventEndOfContent(
      eof: eof,
      parked: parked,
      lastEntry: count != null && pos == count - 1,
      live: live,
      timePos: timePos,
    ),
  );
}

/// Whether the playlist entry with id [entryId] is the last one.
bool _isLastEntry(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  int entryId,
) {
  final count = _getPropInt64(lib, handle, 'playlist-count');
  if (count == null || count <= 0) return false;
  return _getPropInt64(lib, handle, 'playlist/${count - 1}/id') == entryId;
}
