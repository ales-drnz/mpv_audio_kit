// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/utils/debug_log.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

/// Recovers libmpv handles leaked across a Flutter Hot-Restart.
///
/// Flutter replaces the Dart VM but keeps the parent process alive,
/// so handles allocated by the previous VM stay open (and block
/// exclusive-mode audio devices like WASAPI) until the process exits.
/// The tracker stashes a per-pid native buffer of live handle
/// addresses in a tmp file; on startup the new VM rehydrates that
/// buffer and surfaces every still-tracked handle to the caller's
/// cleanup callback.
///
/// **Production no-op** — guarded by `dart.vm.product`. Hot-Restart
/// is a development concern; in product builds the parent process
/// dies with the VM and there are no orphans to rescue.
///
/// **Single-isolate** — [add] / [remove] are not synchronized across
/// isolates that share a pid. The test suite disables the tracker
/// via `MpvAudioKit.ensureInitialized(hotRestartCleanup: false)`.
class OrphanHandleTracker {
  static const int _kBufferSize = 256;
  static final OrphanHandleTracker instance = OrphanHandleTracker._();
  static bool _initialized = false;

  late final File _file;
  late final Pointer<IntPtr> _buffer;
  final Completer<void> _completer = Completer<void>();

  bool get _isDebug => !const bool.fromEnvironment('dart.vm.product');

  OrphanHandleTracker._() {
    _file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_audio_kit_refs_$pid.txt');
  }

  /// Initializes the tracker once per Dart VM.
  ///
  /// On a fresh launch the buffer is allocated and the file written;
  /// on a Hot-Restart the file already exists and the existing buffer
  /// is reattached. Any non-zero entries in the buffer are surfaced
  /// to [onOrphanFound] for the caller to clean up.
  void ensureInitialized(
      void Function(List<Pointer<MpvHandle>>) onOrphanFound) {
    if (!_isDebug) {
      return;
    }
    if (_initialized) {
      return;
    }
    _initialized = true;

    try {
      if (!_file.existsSync()) {
        _buffer = calloc<IntPtr>(_kBufferSize);
        _file.writeAsStringSync(_buffer.address.toString());
      } else {
        final addressStr = _file.readAsStringSync().trim();
        final address = int.parse(addressStr);
        _buffer = Pointer<IntPtr>.fromAddress(address);
      }

      final orphans = <Pointer<MpvHandle>>[];
      for (int i = 0; i < _kBufferSize; i++) {
        final ref = _buffer + i;
        final refAddr = ref.value;
        if (refAddr != 0) {
          orphans.add(Pointer.fromAddress(refAddr));
          ref.value = 0;
        }
      }

      if (orphans.isNotEmpty) {
        onOrphanFound(orphans);
      }
    } catch (e) {
      debugLog(
          'mpv_audio_kit: OrphanHandleTracker initialization failed: $e');
    } finally {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  /// Records [handle] in the first free slot.
  ///
  /// Silently drops the handle when the buffer is full and emits a
  /// stderr warning. Hot-Restart cleanup will then miss this handle
  /// — on Windows that means a WASAPI exclusive-mode device may
  /// stay locked until the parent process terminates.
  void add(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      if (handle == nullptr) {
        return;
      }
      for (int i = 0; i < _kBufferSize; i++) {
        final ref = _buffer + i;
        if (ref.value == 0) {
          ref.value = handle.address;
          return;
        }
      }
      debugLog(
        'mpv_audio_kit: OrphanHandleTracker buffer full ($_kBufferSize '
        'handles tracked). Handle ${handle.address} not registered for '
        'hot-restart cleanup — dispose Player instances before creating '
        'more.',
      );
    });
  }

  /// Clears [handle] from the buffer when [Player.dispose] runs
  /// normally — keeps the orphan list accurate so the next
  /// Hot-Restart only sees handles the consumer actually leaked.
  void remove(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) {
      return;
    }
    _completer.future.then((_) {
      if (handle == nullptr) {
        return;
      }
      for (int i = 0; i < _kBufferSize; i++) {
        final ref = _buffer + i;
        if (ref.value == handle.address) {
          ref.value = 0;
          break;
        }
      }
    });
  }
}
