// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

// The libmpv the build hook bundles (hook/build.dart), which every @Native
// declaration below binds to.
@DefaultAsset('package:mpv_audio_kit/libmpv')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:meta/meta.dart';

import 'mpv_constants.dart';

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
/// FFI layout of `mpv_event_end_file`, the payload of an end-file event.
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
}

/// FFI layout of `mpv_event_end_file` in a libmpv of libmpv-r20 or later
/// (patch read_error), which appends two fields: whether the file stopped
/// on a read error, and how many HLS or DASH segments it lost. The same
/// offsets on every ABI of the release. Read it only from a libmpv that has
/// the patch: an older one copies a shorter event, and the fields past it
/// are not its memory.
final class MpvEventEndFileReadError extends Struct {
  /// As [MpvEventEndFile.reason].
  @Int32()
  external int reason;

  /// As [MpvEventEndFile.error].
  @Int32()
  external int error;

  /// As [MpvEventEndFile.playlistEntryId].
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

// ---------------------------------------------------------------------------
// Function typedefs: native side
// ---------------------------------------------------------------------------

// mpv_handle *mpv_create(void)
typedef _MpvCreateNative = Pointer<MpvHandle> Function();

/// Dart signature for `mpv_create`: allocates a new mpv client handle.
typedef MpvCreate = Pointer<MpvHandle> Function();

// int mpv_initialize(mpv_handle *ctx)
typedef _MpvInitializeNative = Int32 Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_initialize`: starts the mpv core for [ctx].
typedef MpvInitialize = int Function(Pointer<MpvHandle> ctx);

// void mpv_terminate_destroy(mpv_handle *ctx)
typedef _MpvTerminateDestroyNative = Void Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_terminate_destroy`: stops the core and releases
/// [ctx], blocking until shutdown completes.
typedef MpvTerminateDestroy = void Function(Pointer<MpvHandle> ctx);

// void mpv_wakeup(mpv_handle *ctx)
typedef _MpvWakeupNative = Void Function(Pointer<MpvHandle> ctx);

/// Dart signature for `mpv_wakeup`: interrupts a thread parked in
/// `mpv_wait_event` on [ctx], making that call return `MPV_EVENT_NONE`. If no
/// thread is currently waiting, the next `mpv_wait_event` returns immediately
/// (libmpv guarantees no lost wakeups). Safe to call from any thread.
typedef MpvWakeup = void Function(Pointer<MpvHandle> ctx);

// int mpv_set_option_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetOptionStringNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      Pointer<Utf8> data,
    );

/// Dart signature for `mpv_set_option_string`: sets a pre-init option by name.
typedef MpvSetOptionString =
    int Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      Pointer<Utf8> data,
    );

// int mpv_set_property_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetPropertyStringNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      Pointer<Utf8> data,
    );

/// Dart signature for `mpv_set_property_string`: sets a property from a
/// string value.
typedef MpvSetPropertyString =
    int Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      Pointer<Utf8> data,
    );

// char *mpv_get_property_string(mpv_handle *ctx, const char *name)
typedef _MpvGetPropertyStringNative =
    Pointer<Utf8> Function(Pointer<MpvHandle> ctx, Pointer<Utf8> name);

/// Dart signature for `mpv_get_property_string`: reads a property as a
/// newly allocated string the caller must release with `mpv_free`.
typedef MpvGetPropertyString =
    Pointer<Utf8> Function(Pointer<MpvHandle> ctx, Pointer<Utf8> name);

// int mpv_get_property(mpv_handle*, const char*, int format, void *data)
typedef _MpvGetPropertyNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      Int32 format,
      Pointer<Void> data,
    );

/// Dart signature for `mpv_get_property`: reads a property into `data`
/// using the given [MpvFormat].
typedef MpvGetProperty =
    int Function(
      Pointer<MpvHandle> ctx,
      Pointer<Utf8> name,
      int format,
      Pointer<Void> data,
    );

// int mpv_set_property_async(mpv_handle*, uint64_t reply_userdata,
//                            const char *name, int format, void *data)
typedef _MpvSetPropertyAsyncNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Uint64 replyUserdata,
      Pointer<Utf8> name,
      Int32 format,
      Pointer<Void> data,
    );

/// Dart signature for `mpv_set_property_async`: queues a property write and
/// returns immediately; libmpv deep-copies [name] and the value before
/// returning, and delivers the outcome as an `MPV_EVENT_SET_PROPERTY_REPLY`
/// tagged with `reply_userdata`. Unlike the synchronous setter it never
/// waits for the core's playloop, so it cannot stall the calling isolate.
typedef MpvSetPropertyAsync =
    int Function(
      Pointer<MpvHandle> ctx,
      int replyUserdata,
      Pointer<Utf8> name,
      int format,
      Pointer<Void> data,
    );

// int mpv_get_property_async(mpv_handle*, uint64_t reply_userdata,
//                            const char *name, int format)
typedef _MpvGetPropertyAsyncNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Uint64 replyUserdata,
      Pointer<Utf8> name,
      Int32 format,
    );

/// Dart signature for `mpv_get_property_async`: queues a property read and
/// returns immediately; the value arrives as an `MPV_EVENT_GET_PROPERTY_REPLY`
/// carrying an `mpv_event_property` payload, tagged with `reply_userdata`.
typedef MpvGetPropertyAsync =
    int Function(
      Pointer<MpvHandle> ctx,
      int replyUserdata,
      Pointer<Utf8> name,
      int format,
    );

// int mpv_command_async(mpv_handle *ctx, uint64_t reply_userdata, const char **args)
typedef _MpvCommandAsyncNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Uint64 replyUserdata,
      Pointer<Pointer<Utf8>> args,
    );

/// Dart signature for `mpv_command_async`: parses [args] client-side,
/// queues the command and returns immediately; the outcome arrives as an
/// `MPV_EVENT_COMMAND_REPLY` tagged with `reply_userdata`.
typedef MpvCommandAsync =
    int Function(
      Pointer<MpvHandle> ctx,
      int replyUserdata,
      Pointer<Pointer<Utf8>> args,
    );

// int mpv_command_string(mpv_handle *ctx, const char *args)
typedef _MpvCommandStringNative =
    Int32 Function(Pointer<MpvHandle> ctx, Pointer<Utf8> args);

/// Dart signature for `mpv_command_string`: runs a command from a single
/// command-line string.
typedef MpvCommandString =
    int Function(Pointer<MpvHandle> ctx, Pointer<Utf8> args);

// mpv_event *mpv_wait_event(mpv_handle *ctx, double timeout)
typedef _MpvWaitEventNative =
    Pointer<MpvEvent> Function(Pointer<MpvHandle> ctx, Double timeout);

/// Dart signature for `mpv_wait_event`: blocks up to `timeout` seconds for
/// the next [MpvEvent].
typedef MpvWaitEvent =
    Pointer<MpvEvent> Function(Pointer<MpvHandle> ctx, double timeout);

// int mpv_observe_property(mpv_handle*, uint64_t reply_userdata, const char*, int format)
typedef _MpvObservePropertyNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Uint64 replyUserdata,
      Pointer<Utf8> name,
      Int32 format,
    );

/// Dart signature for `mpv_observe_property`: subscribes to change events
/// for a property, tagged with `reply_userdata`.
typedef MpvObserveProperty =
    int Function(
      Pointer<MpvHandle> ctx,
      int replyUserdata,
      Pointer<Utf8> name,
      int format,
    );

// void mpv_free(void *data)
typedef _MpvFreeNative = Void Function(Pointer<Void> data);

/// Dart signature for `mpv_free`: frees memory allocated by libmpv.
typedef MpvFree = void Function(Pointer<Void> data);

// void mpv_free_node_contents(mpv_node *node)
typedef _MpvFreeNodeContentsNative = Void Function(Pointer<MpvNode> node);

/// Dart signature for `mpv_free_node_contents`: frees memory owned by the
/// contents of an [MpvNode].
typedef MpvFreeNodeContents = void Function(Pointer<MpvNode> node);

// const char *mpv_error_string(int error)
typedef _MpvErrorStringNative = Pointer<Utf8> Function(Int32 error);

/// Dart signature for `mpv_error_string`: maps an [MpvError] code to a
/// human-readable description.
typedef MpvErrorString = Pointer<Utf8> Function(int error);

// int mpv_request_log_messages(mpv_handle*, const char *min_level)
typedef _MpvRequestLogMessagesNative =
    Int32 Function(Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel);

/// Dart signature for `mpv_request_log_messages`: enables log-message events
/// at or above `min_level`.
typedef MpvRequestLogMessages =
    int Function(Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel);

// int mpv_hook_add(mpv_handle *ctx, uint64_t reply_userdata, const char *name, int priority)
typedef _MpvHookAddNative =
    Int32 Function(
      Pointer<MpvHandle> ctx,
      Uint64 replyUserdata,
      Pointer<Utf8> name,
      Int32 priority,
    );

/// Dart signature for `mpv_hook_add`: registers a hook handler for the named
/// hook at the given priority.
typedef MpvHookAdd =
    int Function(
      Pointer<MpvHandle> ctx,
      int replyUserdata,
      Pointer<Utf8> name,
      int priority,
    );

// int mpv_hook_continue(mpv_handle *ctx, uint64_t id)
typedef _MpvHookContinueNative =
    Int32 Function(Pointer<MpvHandle> ctx, Uint64 id);

/// Dart signature for `mpv_hook_continue`: resumes mpv after a hook with the
/// given id has been handled.
typedef MpvHookContinue = int Function(Pointer<MpvHandle> ctx, int id);

// ---------------------------------------------------------------------------
// Loaded library wrapper
// ---------------------------------------------------------------------------

/// Holds an opened libmpv [DynamicLibrary] and the resolved client-API
/// function pointers, looked up once at construction.
class MpvLibrary {
  /// Bound `mpv_create`.
  late final MpvCreate mpvCreate;

  /// Bound `mpv_initialize`.
  late final MpvInitialize mpvInitialize;

  /// Bound `mpv_terminate_destroy`.
  late final MpvTerminateDestroy mpvTerminateDestroy;

  /// Bound `mpv_wakeup`: unblocks a parked `mpv_wait_event`.
  late final MpvWakeup mpvWakeup;

  /// Bound `mpv_set_option_string`.
  late final MpvSetOptionString mpvSetOptionString;

  /// Bound `mpv_set_property_string`.
  late final MpvSetPropertyString mpvSetPropertyString;

  /// Bound `mpv_get_property_string`.
  late final MpvGetPropertyString mpvGetPropertyString;

  /// Bound `mpv_get_property`.
  late final MpvGetProperty mpvGetProperty;

  /// Bound `mpv_set_property_async`.
  late final MpvSetPropertyAsync mpvSetPropertyAsync;

  /// Bound `mpv_get_property_async`.
  late final MpvGetPropertyAsync mpvGetPropertyAsync;

  /// Bound `mpv_command_async`.
  late final MpvCommandAsync mpvCommandAsync;

  /// Bound `mpv_command_string`.
  late final MpvCommandString mpvCommandString;

  /// Bound `mpv_wait_event`.
  late final MpvWaitEvent mpvWaitEvent;

  /// Bound `mpv_observe_property`.
  late final MpvObserveProperty mpvObserveProperty;

  /// Bound `mpv_free`.
  late final MpvFree mpvFree;

  /// Bound `mpv_free_node_contents`.
  late final MpvFreeNodeContents mpvFreeNodeContents;

  /// Bound `mpv_error_string`.
  late final MpvErrorString mpvErrorString;

  /// Bound `mpv_request_log_messages`.
  late final MpvRequestLogMessages mpvRequestLogMessages;

  /// Bound `mpv_hook_add`.
  late final MpvHookAdd mpvHookAdd;

  /// Bound `mpv_hook_continue`.
  late final MpvHookContinue mpvHookContinue;

  /// Test-only: builds an [MpvLibrary] with every `mpv*` field left
  /// as an unassigned `late final`. The caller must set the entries
  /// it exercises; touching an unset one throws
  /// [LateInitializationError], so misuse surfaces as a test failure
  /// instead of a silent FFI crash.
  @visibleForTesting
  MpvLibrary.uninitializedForTest();

  MpvLibrary._(DynamicLibrary lib) {
    mpvCreate = lib.lookupFunction<_MpvCreateNative, MpvCreate>('mpv_create');
    mpvInitialize = lib.lookupFunction<_MpvInitializeNative, MpvInitialize>(
      'mpv_initialize',
    );
    mpvTerminateDestroy = lib
        .lookupFunction<_MpvTerminateDestroyNative, MpvTerminateDestroy>(
          'mpv_terminate_destroy',
        );
    // isLeaf: documented non-blocking and callback-free (libmpv client.h),
    // so the call skips the generated trampoline's thread-state transition.
    // NEVER mark a call that can block on the core (wait_event, command,
    // set or get property) or re-enter Dart as leaf.
    mpvWakeup = lib.lookupFunction<_MpvWakeupNative, MpvWakeup>(
      'mpv_wakeup',
      isLeaf: true,
    );
    mpvSetOptionString = lib
        .lookupFunction<_MpvSetOptionStringNative, MpvSetOptionString>(
          'mpv_set_option_string',
        );
    mpvSetPropertyString = lib
        .lookupFunction<_MpvSetPropertyStringNative, MpvSetPropertyString>(
          'mpv_set_property_string',
        );
    mpvGetPropertyString = lib
        .lookupFunction<_MpvGetPropertyStringNative, MpvGetPropertyString>(
          'mpv_get_property_string',
        );
    mpvGetProperty = lib.lookupFunction<_MpvGetPropertyNative, MpvGetProperty>(
      'mpv_get_property',
    );
    // The async variants enqueue on the core's dispatch and return without
    // waiting for the playloop (verified against the bundled source:
    // `run_async` = reserve_reply + mp_dispatch_enqueue; name and value are
    // deep-copied first). They still take short-lived internal locks, so
    // they are NOT leaf-safe.
    mpvSetPropertyAsync = lib
        .lookupFunction<_MpvSetPropertyAsyncNative, MpvSetPropertyAsync>(
          'mpv_set_property_async',
        );
    mpvGetPropertyAsync = lib
        .lookupFunction<_MpvGetPropertyAsyncNative, MpvGetPropertyAsync>(
          'mpv_get_property_async',
        );
    mpvCommandAsync = lib
        .lookupFunction<_MpvCommandAsyncNative, MpvCommandAsync>(
          'mpv_command_async',
        );
    mpvCommandString = lib
        .lookupFunction<_MpvCommandStringNative, MpvCommandString>(
          'mpv_command_string',
        );
    mpvWaitEvent = lib.lookupFunction<_MpvWaitEventNative, MpvWaitEvent>(
      'mpv_wait_event',
    );
    mpvObserveProperty = lib
        .lookupFunction<_MpvObservePropertyNative, MpvObserveProperty>(
          'mpv_observe_property',
        );
    mpvFree = lib.lookupFunction<_MpvFreeNative, MpvFree>(
      'mpv_free',
      isLeaf: true,
    );
    mpvFreeNodeContents = lib
        .lookupFunction<_MpvFreeNodeContentsNative, MpvFreeNodeContents>(
          'mpv_free_node_contents',
          isLeaf: true,
        );
    mpvErrorString = lib.lookupFunction<_MpvErrorStringNative, MpvErrorString>(
      'mpv_error_string',
      isLeaf: true,
    );
    mpvRequestLogMessages = lib
        .lookupFunction<_MpvRequestLogMessagesNative, MpvRequestLogMessages>(
          'mpv_request_log_messages',
        );
    mpvHookAdd = lib.lookupFunction<_MpvHookAddNative, MpvHookAdd>(
      'mpv_hook_add',
    );
    mpvHookContinue = lib
        .lookupFunction<_MpvHookContinueNative, MpvHookContinue>(
          'mpv_hook_continue',
        );
  }

  /// Binds the libmpv the build hook bundles with the app, through the
  /// @Native declarations at the end of this file.
  MpvLibrary._bundled() {
    mpvCreate = _mpvCreate;
    mpvInitialize = _mpvInitialize;
    mpvTerminateDestroy = _mpvTerminateDestroy;
    mpvWakeup = _mpvWakeup;
    mpvSetOptionString = _mpvSetOptionString;
    mpvSetPropertyString = _mpvSetPropertyString;
    mpvGetPropertyString = _mpvGetPropertyString;
    mpvGetProperty = _mpvGetProperty;
    mpvSetPropertyAsync = _mpvSetPropertyAsync;
    mpvGetPropertyAsync = _mpvGetPropertyAsync;
    mpvCommandAsync = _mpvCommandAsync;
    mpvCommandString = _mpvCommandString;
    mpvWaitEvent = _mpvWaitEvent;
    mpvObserveProperty = _mpvObserveProperty;
    mpvFree = _mpvFree;
    mpvFreeNodeContents = _mpvFreeNodeContents;
    mpvErrorString = _mpvErrorString;
    mpvRequestLogMessages = _mpvRequestLogMessages;
    mpvHookAdd = _mpvHookAdd;
    mpvHookContinue = _mpvHookContinue;
  }

  /// Opens libmpv: the one the build hook bundles with the app, or the
  /// library at [path] when given (a custom libmpv build).
  /// Throws [MpvLibraryException] if the library cannot be found.
  factory MpvLibrary.open([String? path]) {
    if (path == null) {
      try {
        // @Native symbols resolve on first use; resolve one now so a
        // missing asset fails here, with a useful message.
        Native.addressOf<NativeFunction<_MpvCreateNative>>(_mpvCreate);
      } catch (e) {
        throw MpvLibraryException(
          'Failed to load the libmpv bundled with mpv_audio_kit.\n'
          'Error: $e\n'
          'The build hook (hook/build.dart) provides it; check the build '
          'output for a hook failure.',
        );
      }
      return MpvLibrary._bundled();
    }
    try {
      return MpvLibrary._(DynamicLibrary.open(path));
    } catch (e) {
      throw MpvLibraryException(
        'Failed to load libmpv from "$path".\n'
        'Error: $e\n'
        'Ensure the library is present and all its dependencies are installed.',
      );
    }
  }
}

/// Exception thrown when the `libmpv` shared library cannot be loaded or resolved.
class MpvLibraryException implements Exception {
  /// The error message describing the failure.
  final String message;

  /// Creates a new [MpvLibraryException] with the given [message].
  const MpvLibraryException(this.message);

  @override
  String toString() => 'MpvLibraryException: $message';
}

// ---------------------------------------------------------------------------
// The bundled libmpv (see MpvLibrary._bundled). Leaf calls follow the same
// rule as MpvLibrary._: only the documented non-blocking, callback-free ones.
// ---------------------------------------------------------------------------

@Native<_MpvCreateNative>(symbol: 'mpv_create')
external Pointer<MpvHandle> _mpvCreate();

@Native<_MpvInitializeNative>(symbol: 'mpv_initialize')
external int _mpvInitialize(Pointer<MpvHandle> ctx);

@Native<_MpvTerminateDestroyNative>(symbol: 'mpv_terminate_destroy')
external void _mpvTerminateDestroy(Pointer<MpvHandle> ctx);

@Native<_MpvWakeupNative>(symbol: 'mpv_wakeup', isLeaf: true)
external void _mpvWakeup(Pointer<MpvHandle> ctx);

@Native<_MpvSetOptionStringNative>(symbol: 'mpv_set_option_string')
external int _mpvSetOptionString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  Pointer<Utf8> data,
);

@Native<_MpvSetPropertyStringNative>(symbol: 'mpv_set_property_string')
external int _mpvSetPropertyString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  Pointer<Utf8> data,
);

@Native<_MpvGetPropertyStringNative>(symbol: 'mpv_get_property_string')
external Pointer<Utf8> _mpvGetPropertyString(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
);

@Native<_MpvGetPropertyNative>(symbol: 'mpv_get_property')
external int _mpvGetProperty(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> name,
  int format,
  Pointer<Void> data,
);

@Native<_MpvSetPropertyAsyncNative>(symbol: 'mpv_set_property_async')
external int _mpvSetPropertyAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
  Pointer<Void> data,
);

@Native<_MpvGetPropertyAsyncNative>(symbol: 'mpv_get_property_async')
external int _mpvGetPropertyAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
);

@Native<_MpvCommandAsyncNative>(symbol: 'mpv_command_async')
external int _mpvCommandAsync(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Pointer<Utf8>> args,
);

@Native<_MpvCommandStringNative>(symbol: 'mpv_command_string')
external int _mpvCommandString(Pointer<MpvHandle> ctx, Pointer<Utf8> args);

@Native<_MpvWaitEventNative>(symbol: 'mpv_wait_event')
external Pointer<MpvEvent> _mpvWaitEvent(
  Pointer<MpvHandle> ctx,
  double timeout,
);

@Native<_MpvObservePropertyNative>(symbol: 'mpv_observe_property')
external int _mpvObserveProperty(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int format,
);

@Native<_MpvFreeNative>(symbol: 'mpv_free', isLeaf: true)
external void _mpvFree(Pointer<Void> data);

@Native<_MpvFreeNodeContentsNative>(
  symbol: 'mpv_free_node_contents',
  isLeaf: true,
)
external void _mpvFreeNodeContents(Pointer<MpvNode> node);

@Native<_MpvErrorStringNative>(symbol: 'mpv_error_string', isLeaf: true)
external Pointer<Utf8> _mpvErrorString(int error);

@Native<_MpvRequestLogMessagesNative>(symbol: 'mpv_request_log_messages')
external int _mpvRequestLogMessages(
  Pointer<MpvHandle> ctx,
  Pointer<Utf8> minLevel,
);

@Native<_MpvHookAddNative>(symbol: 'mpv_hook_add')
external int _mpvHookAdd(
  Pointer<MpvHandle> ctx,
  int replyUserdata,
  Pointer<Utf8> name,
  int priority,
);

@Native<_MpvHookContinueNative>(symbol: 'mpv_hook_continue')
external int _mpvHookContinue(Pointer<MpvHandle> ctx, int id);
