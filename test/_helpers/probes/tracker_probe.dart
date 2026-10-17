// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A plain `dart` program (no Flutter) that brings up the Hot Restart tracker
// of a fresh process, the way MpvAudioKit.ensureInitialized does in a debug
// build, then stands for the VM a Hot Restart brings up with a second
// isolate of the same process. Prints one JSON line:
// `{"first": {...}, "second": {...}}`, each with `restarted` and the
// `orphans` that isolate's tracker reported.
//
// Optional arguments leave a file in the temp directory first:
// - `own <content>`: a sentinel named after this process' pid, as a dead
//   process with the same pid left it;
// - `other <content>`: a sentinel of another pid, no longer alive.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';

/// Never handed to libmpv: the probe only records what the tracker reports.
const int _fakeHandle = 0x5a5a0;

/// A pid no process has: above the Linux limit (2^22) and odd.
const int _deadPid = 2147483645;

Future<void> main(List<String> args) async {
  if (args.isNotEmpty) {
    final owner = switch (args[0]) {
      'own' => pid,
      'other' => _deadPid,
      _ => throw ArgumentError('unknown mode ${args[0]}'),
    };
    final sep = Platform.pathSeparator;
    File(
      '${Directory.systemTemp.path}${sep}mpv_audio_kit_refs_$owner.txt',
    ).writeAsStringSync(args[1]);
  }

  final first = _bringUp();
  OrphanHandleTracker.instance.add(Pointer.fromAddress(_fakeHandle));
  // add() lands once the tracker's init future completes.
  await Future<void>.delayed(Duration.zero);
  final second = await Isolate.run(_bringUp);

  stdout.writeln(jsonEncode({'first': first, 'second': second}));
}

Map<String, Object> _bringUp() {
  final orphans = <int>[];
  final tracker = OrphanHandleTracker.instance;
  tracker.ensureInitialized(
    (refs) => orphans.addAll(refs.map((r) => r.address)),
  );
  return {'restarted': tracker.restarted, 'orphans': orphans};
}
