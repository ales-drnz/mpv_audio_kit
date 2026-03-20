// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:ffi/ffi.dart';

import 'mpv_bindings.dart' as mpv;

// ── Messages: main → isolate ─────────────────────────────────────────────────

/// Sent once when the isolate starts to hand it the mpv handle address and
/// the [SendPort] on which it should send events back.
class _InitMessage {
  final int handleAddress;
  final SendPort toMain;
  final String? libraryPath;
  _InitMessage(this.handleAddress, this.toMain, {this.libraryPath});
}

/// Tells the event loop isolate to exit cleanly.
class _ShutdownMessage {}

// ── Events: isolate → main ───────────────────────────────────────────────────

sealed class MpvIsolateEvent {}

class MpvEventStartFile extends MpvIsolateEvent {}

class MpvEventFileLoaded extends MpvIsolateEvent {}

class MpvEndFileEvent extends MpvIsolateEvent {
  final int reason; // MpvEndFileReason.*
  final int error;
  MpvEndFileEvent(this.reason, this.error);
}

class MpvEventShutdown extends MpvIsolateEvent {}

class MpvEventPropertyDouble extends MpvIsolateEvent {
  final String name;
  final double value;
  MpvEventPropertyDouble(this.name, this.value);
}

class MpvEventPropertyInt extends MpvIsolateEvent {
  final String name;
  final int value;
  MpvEventPropertyInt(this.name, this.value);
}

class MpvEventPropertyString extends MpvIsolateEvent {
  final String name;
  final String value;
  MpvEventPropertyString(this.name, this.value);
}

class MpvEventLog extends MpvIsolateEvent {
  final String prefix;
  final String level;
  final String text;
  MpvEventLog(this.prefix, this.level, this.text);
}

class MpvEventError extends MpvIsolateEvent {
  final String message;
  MpvEventError(this.message);
}

// ── Isolate entry point ───────────────────────────────────────────────────────

void _isolateEntry(SendPort initialReplyPort) {
  final fromMain = ReceivePort();
  initialReplyPort.send(fromMain.sendPort);

  SendPort? toMain;
  Pointer<mpv.MpvHandle>? handle;
  mpv.MpvLibrary? lib;
  bool running = true;

  // Per-isolate deduplication state — not shared across Player instances.
  final lastValues = <String, dynamic>{};
  final lastTimestamps = <String, int>{};

  fromMain.listen((message) {
    if (message is _InitMessage) {
      toMain = message.toMain;
      lib = mpv.MpvLibrary.open(message.libraryPath);
      handle = Pointer<mpv.MpvHandle>.fromAddress(message.handleAddress);
      // Start the blocking event loop.
      _runEventLoop(lib!, handle!, toMain!, () => running, lastValues, lastTimestamps);
    } else if (message is _ShutdownMessage) {
      running = false;
      fromMain.close();
    }
  });
}

void _runEventLoop(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  bool Function() isRunning,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  while (isRunning()) {
    // Block up to 500 ms to check isRunning() periodically.
    final event = lib.mpvWaitEvent(handle, 0.5);
    final id = event.ref.eventId;

    if (id == mpv.MpvEventId.mpvEventNone) {
      continue;
    }

    _dispatchEvent(lib, handle, toMain, event, lastValues, lastTimestamps);

    if (id == mpv.MpvEventId.mpvEventShutdown) {
      break;
    }
  }
}

void _dispatchEvent(
  mpv.MpvLibrary lib,
  Pointer<mpv.MpvHandle> handle,
  SendPort toMain,
  Pointer<mpv.MpvEvent> event,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  final id = event.ref.eventId;
  switch (id) {
    case mpv.MpvEventId.mpvEventShutdown:
      toMain.send(MpvEventShutdown());

    case mpv.MpvEventId.mpvEventStartFile:
      toMain.send(MpvEventStartFile());

    case mpv.MpvEventId.mpvEventFileLoaded:
      toMain.send(MpvEventFileLoaded());

    case mpv.MpvEventId.mpvEventEndFile:
      final ef = event.ref.data.cast<mpv.MpvEventEndFile>().ref;
      toMain.send(MpvEndFileEvent(ef.reason, ef.error));

    case mpv.MpvEventId.mpvEventPropertyChange:
      _dispatchProperty(lib, toMain,
          event.ref.data.cast<mpv.MpvEventProperty>().ref,
          lastValues, lastTimestamps);

    case mpv.MpvEventId.mpvEventLogMessage:
      _dispatchLog(toMain, event.ref.data.cast<mpv.MpvEventLogMessage>().ref);

    case mpv.MpvEventId.mpvEventSeek:
    case mpv.MpvEventId.mpvEventPlaybackRestart:
      // Handled on main isolate by polling time-pos.
      toMain.send(MpvEventPropertyDouble('_seek', 0));
  }
}

void _dispatchProperty(
  mpv.MpvLibrary lib,
  SendPort toMain,
  mpv.MpvEventProperty prop,
  Map<String, dynamic> lastValues,
  Map<String, int> lastTimestamps,
) {
  final name = prop.name.cast<Utf8>().toDartString();

  // Optimization: Throttling for high-frequency updates (e.g., time-pos)
  // and generic diffing to avoid redundant UI thread load.
  if (prop.format == mpv.MpvFormat.mpvFormatDouble && prop.data != nullptr) {
    final v = prop.data.cast<Double>().value;

    if (name == 'time-pos') {
      final now = DateTime.now().millisecondsSinceEpoch;
      final last = lastTimestamps[name] ?? 0;
      // Throttle time-pos to roughly 30fps (33ms) to avoid over-saturating the message bus
      if (now - last < 33) {
        return;
      }
      lastTimestamps[name] = now;
    }

    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;

    toMain.send(MpvEventPropertyDouble(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatFlag && prop.data != nullptr) {
    final v = prop.data.cast<Int32>().value;
    if (lastValues[name] == v) {
      return;
    }
    lastValues[name] = v;
    toMain.send(MpvEventPropertyInt(name, v));
    return;
  }

  if (prop.format == mpv.MpvFormat.mpvFormatString && prop.data != nullptr) {
    final s = prop.data.cast<Pointer<Utf8>>().value.cast<Utf8>().toDartString();
    if (lastValues[name] == s) {
      return;
    }
    lastValues[name] = s;
    toMain.send(MpvEventPropertyString(name, s));
  }
}

void _dispatchLog(SendPort toMain, mpv.MpvEventLogMessage msg) {
  final prefix = msg.prefix.cast<Utf8>().toDartString();
  final level = msg.level.cast<Utf8>().toDartString();
  final text = msg.text.cast<Utf8>().toDartString().trimRight();
  toMain.send(MpvEventLog(prefix, level, text));
}

// ── Public bridge ─────────────────────────────────────────────────────────────

/// Manages the dedicated isolate that runs the mpv event loop.
///
/// The mpv API is thread-safe: the main isolate continues to call
/// [mpv_set_property], [mpv_command] etc. while this isolate blocks on
/// [mpv_wait_event], keeping the Flutter render thread free.
class MpvEventIsolate {
  Isolate? _isolate;
  SendPort? _toIsolate;
  final _events = StreamController<MpvIsolateEvent>.broadcast();

  Stream<MpvIsolateEvent> get events => _events.stream;

  /// Spawns the event loop isolate and wires it to [handle].
  Future<void> start(Pointer<mpv.MpvHandle> handle, {String? libraryPath}) async {
    final initPort = ReceivePort();
    _isolate = await Isolate.spawn(_isolateEntry, initPort.sendPort);

    // The isolate immediately sends back its own receive port.
    final completer = Completer<SendPort>();
    final sub = initPort.listen((msg) {
      if (msg is SendPort && !completer.isCompleted) {
        completer.complete(msg);
      }
    });
    _toIsolate = await completer.future;
    await sub.cancel();
    initPort.close();

    // Open the main ReceivePort, tell the isolate to start.
    final fromIsolate = ReceivePort();
    fromIsolate.listen((msg) {
      if (msg is MpvIsolateEvent) {
        _events.add(msg);
      }
    });

    _toIsolate!.send(_InitMessage(handle.address, fromIsolate.sendPort,
        libraryPath: libraryPath));
  }

  /// Signals the isolate to exit and cleans up resources.
  void stop() {
    _toIsolate?.send(_ShutdownMessage());
    _isolate?.kill(priority: Isolate.beforeNextEvent);
    _events.close();
    _isolate = null;
    _toIsolate = null;
  }
}
