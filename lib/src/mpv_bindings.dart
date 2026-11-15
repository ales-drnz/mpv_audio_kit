// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The client API structs of libmpv the package reads over FFI, with the
// constants and the functions (ffi/mpv_library.dart).

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'mpv_constants.dart';

export 'ffi/mpv_library.dart';
export 'mpv_constants.dart';

// ---------------------------------------------------------------------------
// Opaque handle type
// ---------------------------------------------------------------------------
/// Opaque FFI type for `mpv_handle *`, the client context returned by
/// `mpv_create` and passed to every other client-API call.
final class MpvHandle extends Opaque {}

// ---------------------------------------------------------------------------
// mpv_event  (layout matches mpv.h)
// ---------------------------------------------------------------------------
/// FFI layout of `mpv_event`, the struct returned by `mpv_wait_event`.
final class MpvEvent extends Struct {
  /// The event type, one of the [MpvEventId] constants.
  @Int32()
  external int eventId;

  /// Error code for reply events ([MpvError]); 0 on success.
  @Int32()
  external int error;

  /// The user-data value associated with the originating async request.
  @Uint64()
  external int replyUserdata;

  /// Pointer to the event-specific payload struct (e.g. [MpvEventProperty]),
  /// or `nullptr` when the event carries no data.
  external Pointer<Void> data;
}

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
// mpv_node & co
// ---------------------------------------------------------------------------

/// FFI layout of `mpv_node`, mpv's tagged-union container for arbitrary
/// property and command values.
final class MpvNode extends Struct {
  /// The value union; the active member is selected by [format].
  external MpvNodeUnion u;

  /// The active union member, one of the [MpvFormat] constants.
  @Int32()
  external int format;
}

/// FFI layout of the `mpv_node` value union (`u`).
final class MpvNodeUnion extends Union {
  /// String value, valid when the node format is `MPV_FORMAT_STRING`.
  external Pointer<Utf8> string;

  /// Boolean flag, valid when the node format is `MPV_FORMAT_FLAG`.
  @Int32()
  external int flag;

  /// Integer value, valid when the node format is `MPV_FORMAT_INT64`.
  @Int64()
  external int int64;

  /// Floating-point value, valid when the node format is `MPV_FORMAT_DOUBLE`.
  @Double()
  external double double_;

  /// List or map contents, valid for `MPV_FORMAT_NODE_ARRAY` or `_NODE_MAP`.
  external Pointer<MpvNodeList> list;

  /// Byte-array contents, valid when the node format is
  /// `MPV_FORMAT_BYTE_ARRAY`.
  external Pointer<MpvByteArray> ba;
}

/// FFI layout of `mpv_node_list`, the backing store for node arrays and maps.
final class MpvNodeList extends Struct {
  /// Number of entries in [values] (and [keys] for maps).
  @Int32()
  external int num;

  /// Pointer to the array of [num] [MpvNode] values.
  external Pointer<MpvNode> values;

  /// Pointer to the array of [num] string keys (maps only); `nullptr` for
  /// arrays.
  external Pointer<Pointer<Utf8>> keys;
}

/// FFI layout of `mpv_byte_array`, a raw byte buffer carried in an [MpvNode].
final class MpvByteArray extends Struct {
  /// Pointer to the raw bytes.
  external Pointer<Void> data;

  /// Number of bytes available at [data].
  @Size()
  external int size;
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
