// This file includes implementations derived from media_kit (https://github.com/media-kit/media-kit).
// Copyright © 2021 & onwards, Hitesh Kumar Saini <saini123hitesh@gmail.com>.
// All rights reserved.
// Use of this source code is governed by MIT license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

/// NativeReferenceHolder
/// ---------------------
/// Holds references to [Pointer<MpvHandle>]s created during the application runtime.
/// Since Flutter Hot-Restart destroys the Dart VM but keeps the parent native process alive,
/// any instantiated libmpv handles will leak and keep audio paths locked (e.g., in Windows/WASAPI).
///
/// Stores tracking addresses in a cross-isolate, persistent way (via a tmp file keyed by PID)
/// so that when Dart is hot-restarted, we can find the orphaned mpv handles and send 'quit' to them.
class NativeReferenceHolder {
  static const int _kBufferSize = 256;
  static final NativeReferenceHolder instance = NativeReferenceHolder._();
  static bool _initialized = false;

  late final File _file;
  late final Pointer<IntPtr> _buffer;
  final Completer<void> _completer = Completer<void>();

  bool get _isDebug => !const bool.fromEnvironment('dart.vm.product');

  NativeReferenceHolder._() {
    // We use the process ID to identify the current run.
    // Hot Restart leaves the PID unchanged.
    _file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}mpv_audio_kit_refs_$pid.txt');
  }

  /// Called at the very beginning of the app (e.g. `MpvAudioKit.ensureInitialized()`)
  void ensureInitialized(
      void Function(List<Pointer<MpvHandle>>) onOrphanFound) {
    if (!_isDebug) return;
    if (_initialized) return;
    _initialized = true;

    try {
      if (!_file.existsSync()) {
        // Allocate buffer and store its raw memory address to the file
        _buffer = calloc<IntPtr>(_kBufferSize);
        _file.writeAsStringSync(_buffer.address.toString());
      } else {
        // We survived a hot restart! The file exists, let's read the address
        final addressStr = _file.readAsStringSync().trim();
        final address = int.parse(addressStr);
        _buffer = Pointer<IntPtr>.fromAddress(address);
      }

      // Collect orphaned handles
      final orphans = <Pointer<MpvHandle>>[];
      for (int i = 0; i < _kBufferSize; i++) {
        final ref = _buffer + i;
        final refAddr = ref.value;
        if (refAddr != 0) {
          orphans.add(Pointer.fromAddress(refAddr));
          ref.value = 0; // Clear it out
        }
      }

      if (orphans.isNotEmpty) {
        onOrphanFound(orphans);
      }
    } catch (e) {
      // Fallback if IO fails
      debugPrint(
          'mpv_audio_kit: NativeReferenceHolder initialization failed: $e');
    } finally {
      if (!_completer.isCompleted) {
        _completer.complete();
      }
    }
  }

  void add(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) return;
    _completer.future.then((_) {
      if (handle == nullptr) return;
      for (int i = 0; i < _kBufferSize; i++) {
        final ref = _buffer + i;
        if (ref.value == 0) {
          ref.value = handle.address;
          break;
        }
      }
    });
  }

  void remove(Pointer<MpvHandle> handle) {
    if (!_isDebug || !_initialized) return;
    _completer.future.then((_) {
      if (handle == nullptr) return;
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
