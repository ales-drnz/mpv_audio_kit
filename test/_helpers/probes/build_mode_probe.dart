// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A plain `dart` program (no Flutter) that reports what the Hot Restart
// support does in the build mode it was compiled for. The tests run it with
// `-Ddart.vm.profile=true` to see a profile build, which `flutter test`
// cannot compile. Takes the libmpv path and prints one JSON line:
// - `wakeups`: how often an idle event isolate came back from
//   `mpv_wait_event` in [_idleWindow];
// - `orphans`: the handles that a second isolate of this process, standing
//   for the VM a Hot Restart brings up, found in the tracker after this one
//   registered [_fakeHandle].

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as mpv;

const Duration _idleWindow = Duration(seconds: 2);

/// Never handed to libmpv: the probe only records what the tracker reports.
const int _fakeHandle = 0x5a5a0;

Future<void> main(List<String> args) async {
  final wakeups = await _idleWakeups(args.single);

  OrphanHandleTracker.instance.ensureInitialized((_) {});
  OrphanHandleTracker.instance.add(Pointer.fromAddress(_fakeHandle));
  // add() lands once the tracker's init future completes.
  await Future<void>.delayed(Duration.zero);
  final orphans = await Isolate.run(() {
    final found = <int>[];
    OrphanHandleTracker.instance.ensureInitialized(
      (refs) => found.addAll(refs.map((r) => r.address)),
    );
    return found;
  });

  stdout.writeln(jsonEncode({'wakeups': wakeups, 'orphans': orphans}));
}

Future<int> _idleWakeups(String libPath) async {
  final lib = mpv.MpvLibrary.open(libPath);
  final counter = calloc<Int64>();
  final iso = MpvEventIsolate();
  try {
    final handle = Pointer<mpv.MpvHandle>.fromAddress(
      await iso.start(
        libraryPath: libPath,
        preInitOptions: const {'ao': 'null', 'vo': 'null', 'idle': 'yes'},
        postInitOptions: const {},
        observes: const <MpvObserveSpec>[],
        wakeupCounterAddress: counter.address,
      ),
    );
    // The startup events go first.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final before = counter.value;
    await Future<void>.delayed(_idleWindow);
    final wakeups = counter.value - before;
    iso.requestStop(lib, handle);
    if (await iso.stop()) lib.mpvTerminateDestroy(handle);
    return wakeups;
  } finally {
    calloc.free(counter);
  }
}
