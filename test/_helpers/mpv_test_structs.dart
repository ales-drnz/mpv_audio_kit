// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The client API structs the package does not read through FFI (the
// decoder reads them at the offsets of lib/src/internals/struct_layout.dart),
// laid out for the tests: they build events in memory with them, and
// test/packaging/struct_layout_test.dart holds them to the manifest.

import 'dart:ffi';

import 'package:mpv_audio_kit/src/mpv_bindings.dart';

// ---------------------------------------------------------------------------
// mpv_event_start_file
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_start_file`, the payload of a start-file event.
final class MpvEventStartFileData extends Struct {
  /// The `playlist_entry_id` of the entry that starts loading.
  @Int64()
  external int playlistEntryId;
}

// ---------------------------------------------------------------------------
// mpv_event_end_file
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_end_file`, the payload of an end-file event,
/// with the four fields the patch read_error of libmpv-scripts appends.
final class MpvEventEndFile extends Struct {
  /// Why playback ended, one of the [MpvEndFileReason] constants.
  @Int32()
  external int reason;

  /// Error code ([MpvError]) when [reason] is an error; otherwise 0.
  @Int32()
  external int error;

  /// The `playlist_entry_id` of the entry that ended.
  @Int64()
  external int playlistEntryId;

  /// The `playlist_insert_id` of a redirect.
  @Int64()
  external int playlistInsertId;

  /// The `playlist_insert_num_entries` of a redirect.
  @Int32()
  external int playlistInsertNumEntries;

  /// `mak_read_error`: 1 when the file stopped on a read error, else 0.
  @Int32()
  external int makReadError;

  /// `mak_skipped_segments`: the HLS or DASH segments lost to errors.
  @Int64()
  external int makSkippedSegments;

  /// `mak_duration`: the duration of the entry when the file was closed,
  /// in seconds, or -1 when mpv knew none (a live stream, a file that
  /// never opened).
  @Double()
  external double makDuration;

  /// `mak_position`: the playback position of the entry when the file was
  /// closed, in seconds, or -1 when mpv knew none.
  @Double()
  external double makPosition;
}

// ---------------------------------------------------------------------------
// mpv_event_property
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_property`, the payload of a property-change event.
final class MpvEventProperty extends Struct {
  /// The property name (`const char *`). Held as `Pointer<Void>` to satisfy
  /// FFI struct rules; cast to `Pointer<Utf8>` when reading.
  external Pointer<Void> name;

  /// The data format of [data], one of the [MpvFormat] constants.
  @Int32()
  external int format;

  // On 64-bit targets the C ABI puts 4 bytes of padding before the next
  // pointer; on 32-bit ones (armeabi-v7a) there is none. Dart FFI computes
  // the layout for each ABI.

  /// Pointer to the new property value, decoded according to [format].
  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_event_log_message
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_log_message`, the payload of a log-message event.
final class MpvEventLogMessage extends Struct {
  /// The originating component prefix (`const char *`, e.g. `"vd"`).
  external Pointer<Void> prefix;

  /// The log level as text (`const char *`, e.g. `"warn"`, `"error"`).
  external Pointer<Void> level;

  /// The message text (`const char *`), including its trailing newline.
  external Pointer<Void> text;

  /// The numeric `mpv_log_level` corresponding to [level].
  @Int32()
  external int logLevel;
}

// ---------------------------------------------------------------------------
// mpv_event_hook
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event_hook`, the payload of a hook event.
final class MpvEventHook extends Struct {
  /// The hook name (`const char *`, e.g. `"on_load"`).
  external Pointer<Void> name;

  /// The hook id to pass to `mpv_hook_continue` once handling completes.
  @Uint64()
  external int id;
}
