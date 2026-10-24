// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/internals/mpv_client.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';
import 'package:test/test.dart';

/// The `mpv_node` MpvClient.setNodeProperty builds from a Dart tree, read
/// inside the call, while the arena still holds it. No reply ever comes
/// (no event isolate), so the calls are not awaited.
void main() {
  late List<(String, int, Object?)> written;
  late MpvClient client;
  // Checks on the raw node, run inside the call.
  void Function(Pointer<MpvNode> node)? inspect;

  setUp(() {
    written = [];
    inspect = null;
    final lib = MpvLibrary.uninitializedForTest()
      ..mpvSetPropertyAsync = (_, _, name, format, data) {
        final node = data.cast<MpvNode>();
        inspect?.call(node);
        written.add((name.toDartString(), format, decodeMpvNode(node.ref)));
        return MpvError.mpvErrorSuccess;
      };
    client = MpvClient(lib, nullptr);
  });

  test('scalars keep their mpv format', () {
    for (final value in <Object?>[null, true, false, 7, -1, 0.5, 'a']) {
      client.setNodeProperty('p', value).ignore();
    }
    expect(written.map((w) => w.$3), [null, true, false, 7, -1, 0.5, 'a']);
    expect(written.map((w) => w.$2).toSet(), {MpvFormat.mpvFormatNode});

    final formats = <int>[];
    inspect = (node) => formats.add(node.ref.format);
    for (final value in <Object?>[null, true, 7, 0.5, 'a']) {
      client.setNodeProperty('p', value).ignore();
    }
    expect(formats, [
      MpvFormat.mpvFormatNone,
      MpvFormat.mpvFormatFlag,
      MpvFormat.mpvFormatInt64,
      MpvFormat.mpvFormatDouble,
      MpvFormat.mpvFormatString,
    ]);
  });

  test('the chapter-list tree', () {
    final chapters = [
      {'title': 'Intro', 'time': 0.0},
      {'title': '', 'time': 61.5},
    ];
    inspect = (node) {
      // An array carries no keys; each chapter is a map of two.
      expect(node.ref.format, MpvFormat.mpvFormatNodeArray);
      final list = node.ref.u.list.ref;
      expect(list.num, 2);
      expect(list.keys, nullptr);
      for (var i = 0; i < 2; i++) {
        final entry = (list.values + i).ref;
        expect(entry.format, MpvFormat.mpvFormatNodeMap);
        expect(entry.u.list.ref.num, 2);
        expect(entry.u.list.ref.keys[0].toDartString(), 'title');
        expect(entry.u.list.ref.keys[1].toDartString(), 'time');
      }
    };
    client.setNodeProperty('chapter-list', chapters).ignore();
    final (name, format, value) = written.single;
    expect(name, 'chapter-list');
    expect(format, MpvFormat.mpvFormatNode);
    expect(value, chapters);
  });

  test('an empty array points to no values', () {
    inspect = (node) {
      expect(node.ref.format, MpvFormat.mpvFormatNodeArray);
      expect(node.ref.u.list.ref.num, 0);
      expect(node.ref.u.list.ref.values, nullptr);
      expect(node.ref.u.list.ref.keys, nullptr);
    };
    client.setNodeProperty('chapter-list', const <Object?>[]).ignore();
    expect(written.single.$3, isEmpty);
  });

  test('nested lists and maps', () {
    final tree = {
      'a': [
        1,
        [2.5, 'x'],
        {'b': null},
      ],
      'c': <String, Object?>{},
    };
    client.setNodeProperty('p', tree).ignore();
    expect(written.single.$3, tree);
  });

  test('a value outside the shapes throws and settles its slot', () async {
    expect(
      () => client.setNodeProperty('p', DateTime(2026)),
      throwsArgumentError,
    );
    expect(
      () => client.setNodeProperty('p', {1: 'not a string key'}),
      throwsArgumentError,
    );
    expect(written, isEmpty, reason: 'nothing reached libmpv');
    await expectLater(
      client.settleWrites().timeout(const Duration(seconds: 1)),
      completes,
    );
  });
}
