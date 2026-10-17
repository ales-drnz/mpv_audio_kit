// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The Hot-Restart tracker keeps its buffer in the process environment.
// Each OrphanHandleTracker.forTesting below stands for one Dart VM of a
// process whose environment is the fake one it gets: a second tracker over
// the same environment is the VM a Hot-Restart brings up. The real
// process environment is checked once, through the singleton.
// orphan_handle_tracker_process_test.dart runs the tracker in processes of
// its own.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:mpv_audio_kit/src/internals/orphan_handle_tracker.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:test/test.dart';

const _name = OrphanHandleTracker.envName;

void main() {
  final h1 = Pointer<MpvHandle>.fromAddress(0x1110);
  final h2 = Pointer<MpvHandle>.fromAddress(0x2220);
  final h3 = Pointer<MpvHandle>.fromAddress(0x3330);

  List<int> bringUp(OrphanHandleTracker tracker) {
    final found = <int>[];
    tracker.ensureInitialized((refs) {
      found.addAll(refs.map((r) => r.address));
    });
    return found;
  }

  test('a fresh process publishes its buffer once, with its pid', () {
    final env = _FakeEnvironment();
    final tracker = OrphanHandleTracker.forTesting(env);
    expect(bringUp(tracker), isEmpty);
    expect(tracker.restarted, isFalse);
    expect(env.sets, 1);
    expect(env.values[_name], matches(RegExp('^$pid:[1-9][0-9]*\$')));

    // A second call is a no-op.
    expect(bringUp(tracker), isEmpty);
    expect(env.sets, 1);
  });

  test('the VM a Hot-Restart brings up gets the handles left behind', () async {
    final env = _FakeEnvironment();
    final old = OrphanHandleTracker.forTesting(env);
    bringUp(old);
    old
      ..add(h1)
      ..add(h2)
      ..add(h3)
      ..remove(h2);
    // add() and remove() land once the init future completes.
    await Future<void>.delayed(Duration.zero);

    final restarted = OrphanHandleTracker.forTesting(env);
    expect(bringUp(restarted), [h1.address, h3.address]);
    expect(restarted.restarted, isTrue);
    expect(env.sets, 1, reason: 'a restart only reads the environment');

    // The reported slots are cleared: the next restart finds none of them,
    // only what this VM added.
    restarted.add(h2);
    await Future<void>.delayed(Duration.zero);
    expect(bringUp(OrphanHandleTracker.forTesting(env)), [h2.address]);
  });

  test('a value with the pid of a parent process is not read', () {
    // A child process inherits the environment, with its parent's pid.
    final env = _FakeEnvironment()..values[_name] = '${pid + 1}:4096';
    final tracker = OrphanHandleTracker.forTesting(env);
    expect(bringUp(tracker), isEmpty);
    expect(tracker.restarted, isFalse);
    expect(env.values[_name], startsWith('$pid:'));
  });

  test('a malformed value is replaced and the tracker still works', () async {
    for (final bad in ['abc', '$pid', '$pid:', '$pid:abc', ':4096', '$pid:0']) {
      final env = _FakeEnvironment()..values[_name] = bad;
      final tracker = OrphanHandleTracker.forTesting(env);
      expect(bringUp(tracker), isEmpty, reason: bad);
      expect(tracker.restarted, isFalse, reason: bad);
      tracker.add(h1);
      await Future<void>.delayed(Duration.zero);
      expect(bringUp(OrphanHandleTracker.forTesting(env)), [
        h1.address,
      ], reason: bad);
    }
  });

  test('a buffer that cannot be published still tracks for this VM', () async {
    final env = _FakeEnvironment()..fails = true;
    final tracker = OrphanHandleTracker.forTesting(env);
    expect(bringUp(tracker), isEmpty);
    expect(() => tracker.add(h1), returnsNormally);
    expect(() => tracker.remove(h1), returnsNormally);
    await Future<void>.delayed(Duration.zero);
    expect(env.values, isEmpty);
  });

  test('the process environment holds the buffer after init', () {
    OrphanHandleTracker.instance.ensureInitialized((_) {});
    final value = ProcessEnvironment.native().get(_name);
    expect(value, matches(RegExp('^$pid:[1-9][0-9]*\$')));
    expect(
      Directory.systemTemp.listSync().where(
        (e) => e.path.endsWith('mpv_audio_kit_refs_$pid.txt'),
      ),
      isEmpty,
      reason: 'nothing is written to the temp directory',
    );
  });

  // A slot is two Int64 words on every ABI. In IntPtr words a 32-bit ABI
  // (armeabi-v7a) cut the 64-bit cookie, so the tracker turned itself off
  // there and a Hot Restart left the old cores playing (F228). This host is
  // 64-bit, so the layout is read back instead: cookie and address in
  // 8-byte words, as a 32-bit ABI now has them too.
  test('a slot is two Int64 words on every ABI', () async {
    expect(OrphanHandleTracker.slotBytes, 16);
    final env = _FakeEnvironment();
    final tracker = OrphanHandleTracker.forTesting(env);
    bringUp(tracker);
    tracker
      ..add(h1)
      ..add(h2);
    await Future<void>.delayed(Duration.zero);
    final address = int.parse(env.values[_name]!.split(':').last);
    const cookie = 0x4D414B5F4D5056AB;
    expect(Pointer<Int64>.fromAddress(address).asTypedList(4), [
      cookie,
      h1.address,
      cookie,
      h2.address,
    ]);
  });
}

class _FakeEnvironment implements ProcessEnvironment {
  final values = <String, String>{};
  int sets = 0;
  bool fails = false;

  @override
  String? get(String name) => values[name];

  @override
  bool set(String name, String value) {
    sets++;
    if (fails) return false;
    values[name] = value;
    return true;
  }
}
