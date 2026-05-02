// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// ---------------------------------------------------------------------------
// mpv_error  (subset — limited to required error codes)
// ---------------------------------------------------------------------------
abstract final class MpvError {
  static const int mpvErrorSuccess = 0;
  static const int mpvErrorEventQueueFull = -1;
  static const int mpvErrorNomem = -2;
  static const int mpvErrorUninitialized = -3;
  static const int mpvErrorInvalidParameter = -4;
  static const int mpvErrorOptionNotFound = -5;
  static const int mpvErrorOptionFormat = -6;
  static const int mpvErrorOptionError = -7;
  static const int mpvErrorPropertyNotFound = -8;
  static const int mpvErrorPropertyFormat = -9;
  static const int mpvErrorPropertyUnavailable = -10;
  static const int mpvErrorPropertyError = -11;
  static const int mpvErrorCommand = -12;
  static const int mpvErrorLoadingFailed = -13;
  static const int mpvErrorAoInitFailed = -14;
  static const int mpvErrorVoInitFailed = -15;
  static const int mpvErrorNothingToPlay = -16;
  static const int mpvErrorUnknownFormat = -17;
  static const int mpvErrorUnsupported = -18;
  static const int mpvErrorNotImplemented = -19;
  static const int mpvErrorGeneric = -20;
}

// ---------------------------------------------------------------------------
// mpv_format
// ---------------------------------------------------------------------------
abstract final class MpvFormat {
  static const int mpvFormatNone = 0;
  static const int mpvFormatString = 1;
  static const int mpvFormatOsdString = 2;
  static const int mpvFormatFlag = 3;
  static const int mpvFormatInt64 = 4;
  static const int mpvFormatDouble = 5;
  static const int mpvFormatNode = 6;
  static const int mpvFormatNodeArray = 7;
  static const int mpvFormatNodeMap = 8;
  static const int mpvFormatByteArray = 9;
}

// ---------------------------------------------------------------------------
// mpv_event_id
// ---------------------------------------------------------------------------
abstract final class MpvEventId {
  static const int mpvEventNone = 0;
  static const int mpvEventShutdown = 1;
  static const int mpvEventLogMessage = 2;
  static const int mpvEventGetPropertyReply = 3;
  static const int mpvEventSetPropertyReply = 4;
  static const int mpvEventCommandReply = 5;
  static const int mpvEventStartFile = 6;
  static const int mpvEventEndFile = 7;
  static const int mpvEventFileLoaded = 8;
  static const int mpvEventIdle = 11;
  static const int mpvEventTick = 14;
  static const int mpvEventClientMessage = 16;
  static const int mpvEventVideoReconfig = 17;
  static const int mpvEventAudioReconfig = 18;
  static const int mpvEventSeek = 20;
  static const int mpvEventPlaybackRestart = 21;
  static const int mpvEventPropertyChange = 22;
  static const int mpvEventQueueOverflow = 24;
  static const int mpvEventHook = 25;
}

// ---------------------------------------------------------------------------
// mpv_end_file_reason
// ---------------------------------------------------------------------------
abstract final class MpvEndFileReason {
  static const int mpvEndFileReasonEof = 0;
  static const int mpvEndFileReasonStop = 2;
  static const int mpvEndFileReasonQuit = 3;
  static const int mpvEndFileReasonError = 4;
  static const int mpvEndFileReasonRedirect = 5;
}

// ---------------------------------------------------------------------------
// Opaque handle type
// ---------------------------------------------------------------------------
final class MpvHandle extends Opaque {}

// ---------------------------------------------------------------------------
// mpv_event  (layout matches mpv.h)
// ---------------------------------------------------------------------------
final class MpvEvent extends Struct {
  @Int32()
  external int eventId;

  @Int32()
  external int error;

  @Uint64()
  external int replyUserdata;

  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_event_end_file
// ---------------------------------------------------------------------------
final class MpvEventEndFile extends Struct {
  @Int32()
  external int reason;

  @Int32()
  external int error;
}

// ---------------------------------------------------------------------------
// mpv_event_property
// ---------------------------------------------------------------------------
final class MpvEventProperty extends Struct {
  // In mpv.h: const char *name
  // Stored as Pointer<Void> to avoid ffi Utf8 restrictions in Struct;
  // cast to Pointer<Utf8> when reading.
  external Pointer<Void> name;

  @Int32()
  external int format;

  // 4 bytes of implicit padding before the next 8-byte pointer (C ABI).
  // Dart FFI calculates struct layout automatically via @Int32 + Pointer alignment.

  external Pointer<Void> data;
}

// ---------------------------------------------------------------------------
// mpv_event_log_message
// ---------------------------------------------------------------------------
final class MpvEventLogMessage extends Struct {
  // const char *prefix  (component name, e.g. "vd")
  external Pointer<Void> prefix;

  // const char *level   (e.g. "warn", "error")
  external Pointer<Void> level;

  // const char *text    (the actual message, includes trailing newline)
  external Pointer<Void> text;

  // mpv_log_level logLevel (int32)
  @Int32()
  external int logLevel;
}

// ---------------------------------------------------------------------------
// mpv_node & co
// ---------------------------------------------------------------------------

final class MpvNode extends Struct {
  external MpvNodeUnion u;
  @Int32()
  external int format;
}

final class MpvNodeUnion extends Union {
  external Pointer<Utf8> string;
  @Int32()
  external int flag;
  @Int64()
  external int int64;
  @Double()
  external double double_;
  external Pointer<MpvNodeList> list;
  external Pointer<MpvByteArray> ba;
}

final class MpvNodeList extends Struct {
  @Int32()
  external int num;
  external Pointer<MpvNode> values;
  external Pointer<Pointer<Utf8>> keys;
}

final class MpvByteArray extends Struct {
  external Pointer<Void> data;
  @Size()
  external int size;
}

// ---------------------------------------------------------------------------
// mpv_event_hook
// ---------------------------------------------------------------------------
final class MpvEventHook extends Struct {
  // const char *name — hook name (e.g. "on_load")
  external Pointer<Void> name;

  @Uint64()
  external int id;
}

// ---------------------------------------------------------------------------
// Function typedefs — native side
// ---------------------------------------------------------------------------

// mpv_handle *mpv_create(void)
typedef _MpvCreateNative = Pointer<MpvHandle> Function();
typedef MpvCreate = Pointer<MpvHandle> Function();

// int mpv_initialize(mpv_handle *ctx)
typedef _MpvInitializeNative = Int32 Function(Pointer<MpvHandle> ctx);
typedef MpvInitialize = int Function(Pointer<MpvHandle> ctx);

// void mpv_destroy(mpv_handle *ctx)
typedef _MpvDestroyNative = Void Function(Pointer<MpvHandle> ctx);
typedef MpvDestroy = void Function(Pointer<MpvHandle> ctx);

// void mpv_terminate_destroy(mpv_handle *ctx)
typedef _MpvTerminateDestroyNative = Void Function(Pointer<MpvHandle> ctx);
typedef MpvTerminateDestroy = void Function(Pointer<MpvHandle> ctx);

// int mpv_set_option_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetOptionStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data);
typedef MpvSetOptionString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data);

// int mpv_set_property_string(mpv_handle *ctx, const char *name, const char *data)
typedef _MpvSetPropertyStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data);
typedef MpvSetPropertyString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, Pointer<Utf8> data);

// char *mpv_get_property_string(mpv_handle *ctx, const char *name)
typedef _MpvGetPropertyStringNative = Pointer<Utf8> Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name);
typedef MpvGetPropertyString = Pointer<Utf8> Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name);

// int mpv_get_property(mpv_handle*, const char*, int format, void *data)
typedef _MpvGetPropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Pointer<Utf8> name, Int32 format, Pointer<Void> data);
typedef MpvGetProperty = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, int format, Pointer<Void> data);

// int mpv_set_property(mpv_handle*, const char*, int format, void *data)
typedef _MpvSetPropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Pointer<Utf8> name, Int32 format, Pointer<Void> data);
typedef MpvSetProperty = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> name, int format, Pointer<Void> data);

// int mpv_command(mpv_handle *ctx, const char **args)
typedef _MpvCommandNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Pointer<Utf8>> args);
typedef MpvCommand = int Function(
    Pointer<MpvHandle> ctx, Pointer<Pointer<Utf8>> args);

// int mpv_command_string(mpv_handle *ctx, const char *args)
typedef _MpvCommandStringNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> args);
typedef MpvCommandString = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> args);

// mpv_event *mpv_wait_event(mpv_handle *ctx, double timeout)
typedef _MpvWaitEventNative = Pointer<MpvEvent> Function(
    Pointer<MpvHandle> ctx, Double timeout);
typedef MpvWaitEvent = Pointer<MpvEvent> Function(
    Pointer<MpvHandle> ctx, double timeout);

// int mpv_command_ret(mpv_handle *ctx, const char **args, mpv_node *result)
typedef _MpvCommandRetNative = Int32 Function(Pointer<MpvHandle> ctx,
    Pointer<Pointer<Utf8>> args, Pointer<MpvNode> result);
typedef MpvCommandRet = int Function(Pointer<MpvHandle> ctx,
    Pointer<Pointer<Utf8>> args, Pointer<MpvNode> result);

// int mpv_observe_property(mpv_handle*, uint64_t reply_userdata, const char*, int format)
typedef _MpvObservePropertyNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 format);
typedef MpvObserveProperty = int Function(
    Pointer<MpvHandle> ctx, int replyUserdata, Pointer<Utf8> name, int format);

// int mpv_unobserve_property(mpv_handle*, uint64_t registered_reply_userdata)
typedef _MpvUnobservePropertyNative = Int32 Function(
    Pointer<MpvHandle> ctx, Uint64 registeredReplyUserdata);
typedef MpvUnobserveProperty = int Function(
    Pointer<MpvHandle> ctx, int registeredReplyUserdata);

// void mpv_free(void *data)
typedef _MpvFreeNative = Void Function(Pointer<Void> data);
typedef MpvFree = void Function(Pointer<Void> data);

// void mpv_free_node_contents(mpv_node *node)
typedef _MpvFreeNodeContentsNative = Void Function(Pointer<MpvNode> node);
typedef MpvFreeNodeContents = void Function(Pointer<MpvNode> node);

// const char *mpv_error_string(int error)
typedef _MpvErrorStringNative = Pointer<Utf8> Function(Int32 error);
typedef MpvErrorString = Pointer<Utf8> Function(int error);

// int mpv_request_log_messages(mpv_handle*, const char *min_level)
typedef _MpvRequestLogMessagesNative = Int32 Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel);
typedef MpvRequestLogMessages = int Function(
    Pointer<MpvHandle> ctx, Pointer<Utf8> minLevel);

// unsigned long mpv_client_api_version(void)
typedef _MpvClientApiVersionNative = UnsignedLong Function();
typedef MpvClientApiVersion = int Function();

// int mpv_hook_add(mpv_handle *ctx, uint64_t reply_userdata, const char *name, int priority)
typedef _MpvHookAddNative = Int32 Function(Pointer<MpvHandle> ctx,
    Uint64 replyUserdata, Pointer<Utf8> name, Int32 priority);
typedef MpvHookAdd = int Function(Pointer<MpvHandle> ctx, int replyUserdata,
    Pointer<Utf8> name, int priority);

// int mpv_hook_continue(mpv_handle *ctx, uint64_t id)
typedef _MpvHookContinueNative = Int32 Function(
    Pointer<MpvHandle> ctx, Uint64 id);
typedef MpvHookContinue = int Function(Pointer<MpvHandle> ctx, int id);

// ---------------------------------------------------------------------------
// Loaded library wrapper
// ---------------------------------------------------------------------------

class MpvLibrary {
  final DynamicLibrary _lib;

  late final MpvCreate mpvCreate;
  late final MpvInitialize mpvInitialize;
  late final MpvDestroy mpvDestroy;
  late final MpvTerminateDestroy mpvTerminateDestroy;
  late final MpvSetOptionString mpvSetOptionString;
  late final MpvSetPropertyString mpvSetPropertyString;
  late final MpvGetPropertyString mpvGetPropertyString;
  late final MpvGetProperty mpvGetProperty;
  late final MpvSetProperty mpvSetProperty;
  late final MpvCommand mpvCommand;
  late final MpvCommandString mpvCommandString;
  late final MpvWaitEvent mpvWaitEvent;
  late final MpvObserveProperty mpvObserveProperty;
  late final MpvUnobserveProperty mpvUnobserveProperty;
  late final MpvFree mpvFree;
  late final MpvFreeNodeContents mpvFreeNodeContents;
  late final MpvErrorString mpvErrorString;
  late final MpvRequestLogMessages mpvRequestLogMessages;
  late final MpvCommandRet mpvCommandRet;
  late final MpvClientApiVersion mpvClientApiVersion;
  late final MpvHookAdd mpvHookAdd;
  late final MpvHookContinue mpvHookContinue;

  /// Creates a wrapper from an already opened library (same process).
  factory MpvLibrary.fromExisting(DynamicLibrary lib) => MpvLibrary._(lib);

  MpvLibrary._(this._lib) {
    mpvCreate = _lib.lookupFunction<_MpvCreateNative, MpvCreate>('mpv_create');
    mpvInitialize = _lib
        .lookupFunction<_MpvInitializeNative, MpvInitialize>('mpv_initialize');
    mpvDestroy =
        _lib.lookupFunction<_MpvDestroyNative, MpvDestroy>('mpv_destroy');
    mpvTerminateDestroy =
        _lib.lookupFunction<_MpvTerminateDestroyNative, MpvTerminateDestroy>(
            'mpv_terminate_destroy');
    mpvSetOptionString =
        _lib.lookupFunction<_MpvSetOptionStringNative, MpvSetOptionString>(
            'mpv_set_option_string');
    mpvSetPropertyString =
        _lib.lookupFunction<_MpvSetPropertyStringNative, MpvSetPropertyString>(
            'mpv_set_property_string');
    mpvGetPropertyString =
        _lib.lookupFunction<_MpvGetPropertyStringNative, MpvGetPropertyString>(
            'mpv_get_property_string');
    mpvGetProperty = _lib.lookupFunction<_MpvGetPropertyNative, MpvGetProperty>(
        'mpv_get_property');
    mpvSetProperty = _lib.lookupFunction<_MpvSetPropertyNative, MpvSetProperty>(
        'mpv_set_property');
    mpvCommand =
        _lib.lookupFunction<_MpvCommandNative, MpvCommand>('mpv_command');
    mpvCommandString =
        _lib.lookupFunction<_MpvCommandStringNative, MpvCommandString>(
            'mpv_command_string');
    mpvWaitEvent = _lib
        .lookupFunction<_MpvWaitEventNative, MpvWaitEvent>('mpv_wait_event');
    mpvObserveProperty =
        _lib.lookupFunction<_MpvObservePropertyNative, MpvObserveProperty>(
            'mpv_observe_property');
    mpvUnobserveProperty =
        _lib.lookupFunction<_MpvUnobservePropertyNative, MpvUnobserveProperty>(
            'mpv_unobserve_property');
    mpvFree = _lib.lookupFunction<_MpvFreeNative, MpvFree>('mpv_free');
    mpvFreeNodeContents =
        _lib.lookupFunction<_MpvFreeNodeContentsNative, MpvFreeNodeContents>(
            'mpv_free_node_contents');
    mpvErrorString = _lib.lookupFunction<_MpvErrorStringNative, MpvErrorString>(
        'mpv_error_string');
    mpvRequestLogMessages = _lib.lookupFunction<_MpvRequestLogMessagesNative,
        MpvRequestLogMessages>('mpv_request_log_messages');
    mpvCommandRet = _lib
        .lookupFunction<_MpvCommandRetNative, MpvCommandRet>('mpv_command_ret');
    mpvClientApiVersion =
        _lib.lookupFunction<_MpvClientApiVersionNative, MpvClientApiVersion>(
            'mpv_client_api_version');
    mpvHookAdd =
        _lib.lookupFunction<_MpvHookAddNative, MpvHookAdd>('mpv_hook_add');
    mpvHookContinue =
        _lib.lookupFunction<_MpvHookContinueNative, MpvHookContinue>(
            'mpv_hook_continue');
  }

  /// Opens libmpv from the platform-specific path or a custom [path].
  /// Throws [MpvLibraryException] if the library cannot be found.
  factory MpvLibrary.open([String? path]) {
    if (Platform.isIOS) {
      // On iOS libmpv is statically linked via xcframework.
      // DynamicLibrary.process() exposes all symbols from the current process.
      return MpvLibrary._(DynamicLibrary.process());
    }
    final resolvedPath = path ?? _resolvePath();
    try {
      return MpvLibrary._(DynamicLibrary.open(resolvedPath));
    } catch (e) {
      throw MpvLibraryException('Failed to load libmpv from "$resolvedPath".\n'
          'Error: $e\n'
          'Ensure the library is present and all its dependencies are installed.');
    }
  }

  static String _resolvePath() {
    if (Platform.isMacOS) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final inPlugin =
          '$exeDir/../Frameworks/mpv_audio_kit.framework/Versions/A/libmpv.dylib';
      final inApp = '$exeDir/../Frameworks/libmpv.dylib';

      final candidates = [
        inPlugin, // inside the plugin framework (standard for pods)
        inApp, // top-level Frameworks (manual deploy)
      ];
      for (final c in candidates) {
        if (File(c).existsSync()) {
          return c;
        }
      }
      throw const MpvLibraryException(
          'libmpv.dylib not found in the app bundle.\n'
          'Ensure libmpv.dylib is present in the Frameworks/ folder.');
    } else if (Platform.isLinux) {
      // Check local folder first (common for portable builds/AppImage)
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final localSo = '$exeDir/lib/libmpv.so.2';
      final bundleSo = '$exeDir/libmpv.so.2';

      if (File(localSo).existsSync()) {
        return localSo;
      }
      if (File(bundleSo).existsSync()) {
        return bundleSo;
      }

      // Fallback to system search path
      return 'libmpv.so.2';
    } else if (Platform.isWindows) {
      // On Windows, use an absolute path relative to the executable.
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final localDll = '$exeDir\\libmpv-2.dll';
      if (File(localDll).existsSync()) {
        return localDll;
      }
      // Fallback to searching in PATH.
      return 'libmpv-2.dll';
    } else if (Platform.isAndroid) {
      // Precompiled in android/src/main/jniLibs/<abi>/libmpv.so
      return 'libmpv.so';
    }
    throw MpvLibraryException(
        'Platform not supported: ${Platform.operatingSystem}');
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
