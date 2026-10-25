// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

part of 'event_logic.dart';

// The end of content, read by the event pump: which notifications take a
// read, the read itself ([MpvEventEndOfContent]) and the last-entry check
// of END_FILE.

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
  if (eof) {
    parked = await reader.flag('pause') == 1;
    if (!parked) parked = await reader.flag('keep-open-pause') == 0;
  }
  String? file;
  if (parked) file = await reader.string('playlist/$pos/filename');
  final live = file?.startsWith('mak-pcm://') ?? false;
  double? timePos;
  if (parked) timePos = await reader.float('time-pos');
  final count = await reader.int64('playlist-count');
  if (await reader.int64('playlist-pos') != pos) return;
  if (await reader.int64('playlist/$pos/id') != started.id) return;
  // The park position supersedes a throttled time-pos still held back,
  // which would land after the event, as at PLAYBACK_RESTART. It is also
  // where the entry ended, for its END_FILE.
  if (parked) cache.trailing.remove('time-pos');
  if (timePos != null) started.position = timePos;
  send(
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
Future<bool> _isLastEntry(CoreReader reader, int entryId) async {
  final count = await reader.int64('playlist-count');
  if (count == null || count <= 0) return false;
  return await reader.int64('playlist/${count - 1}/id') == entryId;
}
