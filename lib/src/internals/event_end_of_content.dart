// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_logic.dart';

// The end of content, read by the event pump: which notifications take a
// read, the read itself ([MpvEventEndOfContent]) and the last-entry check
// of END_FILE.

/// How long after a read that may miss the park the pump reads the end of
/// content again ([_sendEndOfContent]).
const int _kEndOfContentAgainMs = 50;

/// The observed properties whose notifications take a fresh
/// [MpvEventEndOfContent] read. `eof-reached` is the direct one; `pause`
/// is observed by the pump only for this (the player does not observe
/// it): the keep-open park pauses the core, which mpv notifies even when
/// the `eof-reached` change around it was skipped. A loop change at the park
/// turns the end of content on or off with nothing else moving.
const Set<String> _kEndOfContentTriggers = {
  'eof-reached',
  'pause',
  'loop-file',
  'loop-playlist',
};

/// Reads where the core stands against the end of content and sends it as
/// [MpvEventEndOfContent]. The reads run when the pump gets to them,
/// which under load can be well after mpv queued the events still waiting
/// in its queue: a short entry can already have loaded and reached its end
/// while its START_FILE (and the previous entry's END_FILE) are still
/// queued, and a read sent ahead of them would raise `completed` for the
/// player to clear again on those events. So a read counts only for the
/// entry whose START_FILE the pump already forwarded
/// ([_PropertyCache.started]); the newer entry's own FILE_LOADED and
/// PLAYBACK_RESTART read again. The current entry is read before and after
/// `eof-reached` and `pause`, so both belong to it.
Future<void> _sendEndOfContent(
  CoreReader reader,
  _Send send,
  _PropertyCache cache,
) async {
  // A read that starts now takes the place of the one that was due.
  cache.endOfContentAgainAt = null;
  final started = cache.started;
  if (started == null) return;
  final pos = await reader.int64('playlist-pos');
  if (pos == null || pos < 0) return;
  if (await reader.int64('playlist/$pos/id') != started.id) return;
  final eof = await reader.flag('eof-reached') == 1;
  // With gapless audio mpv reports EOF once the decoder is done, while the
  // output buffer still plays; keep-open pauses the core only after it has
  // played out. Without `keep-open-pause` no pause comes, and EOF is the
  // closest signal left.
  //
  // No await sits in a branch of `&&`, `||` or `?:` here: compiled to
  // WebAssembly (Dart 3.13), resuming such an await after the other side
  // decided the result traps ("illegal cast"), and the trap takes the
  // whole microtask loop with it. Statements keep the same reads in the
  // same order.
  var parked = false;
  int? pause;
  if (eof) {
    pause = await reader.flag('pause');
    parked = pause == 1;
    if (!parked) parked = await reader.flag('keep-open-pause') == 0;
  }
  _Park? park;
  if (parked) park = await _readPark(reader, pos, cache);
  final live = park?.file?.startsWith('mak-pcm://') ?? false;
  final timePos = park?.timePos;
  final count = await reader.int64('playlist-count');
  if (await reader.int64('playlist-pos') != pos) return;
  if (await reader.int64('playlist/$pos/id') != started.id) return;
  // The park position supersedes a throttled time-pos still held back,
  // which would land after the event, as at PLAYBACK_RESTART, and a change
  // mpv sampled before it, which is read again. It is also where the entry
  // ended, for its END_FILE.
  if (parked) cache.trailing.remove('time-pos');
  // At the end, unpaused, while mpv last sent pause 1: an unpause that
  // keep-open undoes before mpv samples pause again (play() at a seek
  // that lands on the end at once) brings pause back to the value mpv
  // sent, and mpv sends nothing. eof-reached it samples only at a restart
  // or a change of core-idle. So no notification may follow the park:
  // read again shortly, until the read or a change of pause settles it.
  if (eof && !parked && pause == 0 && cache.sentPause == 1) {
    cache.endOfContentAgainAt =
        _throttleClock.elapsedMilliseconds + _kEndOfContentAgainMs;
  }
  if (timePos != null) started.position = timePos;
  send(
    MpvEventEndOfContent(
      eof: eof,
      parked: parked,
      lastEntry: count != null && pos == count - 1,
      live: live,
      timePos: timePos,
      readError: park?.readError,
      skippedSegments: park?.skipped,
    ),
  );
}

/// What the park reads of entry [pos]: its filename, where it ended and how.
typedef _Park = ({
  String? file,
  double? timePos,
  bool? readError,
  int? skipped,
});

/// The reads of the park of entry [pos]. `demuxer-read-error` and
/// `demuxer-skipped-segments` come with libmpv-r20 (patch read_error): the
/// demuxer marks the error under the lock it marks the end with, before the
/// output can play out to the park, so the values read now are the file's.
Future<_Park> _readPark(
  CoreReader reader,
  int pos,
  _PropertyCache cache,
) async {
  final file = await reader.string('playlist/$pos/filename');
  final timePos = await _readTimePos(reader, cache);
  final readError = await reader.flag('demuxer-read-error');
  final skipped = await reader.int64('demuxer-skipped-segments');
  return (
    file: file,
    timePos: timePos,
    readError: readError == null ? null : readError != 0,
    skipped: skipped,
  );
}

/// Whether the playlist entry with id [entryId] is the last one.
Future<bool> _isLastEntry(CoreReader reader, int entryId) async {
  final count = await reader.int64('playlist-count');
  if (count == null || count <= 0) return false;
  return await reader.int64('playlist/${count - 1}/id') == entryId;
}
