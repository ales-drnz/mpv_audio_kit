// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/event_isolate.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart';

/// Allocates an [MpvNode] tree on the native heap and returns a typed
/// pointer plus a `dispose` thunk that frees every allocation. Each helper
/// in this file builds a leaf or branch through this builder so callers can
/// reason about memory ownership at a single point: every test does
/// `final (node, dispose) = build…(); … dispose();` and the heap returns
/// to its initial state.
typedef _NodeAlloc = (Pointer<MpvNode>, void Function());

_NodeAlloc _scalarString(String value) {
  final node = calloc<MpvNode>();
  final str = value.toNativeUtf8();
  node.ref.format = MpvFormat.mpvFormatString;
  node.ref.u.string = str.cast();
  return (node, () {
    calloc.free(str);
    calloc.free(node);
  });
}

_NodeAlloc _scalarInt64(int value) {
  final node = calloc<MpvNode>();
  node.ref.format = MpvFormat.mpvFormatInt64;
  node.ref.u.int64 = value;
  return (node, () => calloc.free(node));
}

_NodeAlloc _scalarDouble(double value) {
  final node = calloc<MpvNode>();
  node.ref.format = MpvFormat.mpvFormatDouble;
  node.ref.u.double_ = value;
  return (node, () => calloc.free(node));
}

_NodeAlloc _scalarFlag(bool value) {
  final node = calloc<MpvNode>();
  node.ref.format = MpvFormat.mpvFormatFlag;
  node.ref.u.flag = value ? 1 : 0;
  return (node, () => calloc.free(node));
}

_NodeAlloc _scalarNone() {
  final node = calloc<MpvNode>();
  node.ref.format = MpvFormat.mpvFormatNone;
  return (node, () => calloc.free(node));
}

_NodeAlloc _byteArray(List<int> bytes) {
  final node = calloc<MpvNode>();
  final ba = calloc<MpvByteArray>();
  final data = calloc<Uint8>(bytes.length);
  for (var i = 0; i < bytes.length; i++) {
    data[i] = bytes[i];
  }
  ba.ref.data = data.cast();
  ba.ref.size = bytes.length;
  node.ref.format = MpvFormat.mpvFormatByteArray;
  node.ref.u.ba = ba;
  return (node, () {
    calloc.free(data);
    calloc.free(ba);
    calloc.free(node);
  });
}

/// Build a tree, run an assertion on the decoded value, free everything.
/// Centralizes ownership so individual tests stay short.
T _decodeAndAssert<T>(_NodeAlloc Function() build, T Function(dynamic) check) {
  final (node, disposeRoot) = build();
  try {
    final decoded = decodeMpvNode(node.ref);
    return check(decoded);
  } finally {
    disposeRoot();
  }
}

void main() {
  group('decodeMpvNode — scalar formats', () {
    test('MPV_FORMAT_NONE → null', () {
      _decodeAndAssert(_scalarNone, (v) {
        expect(v, isNull);
        return null;
      });
    });

    test('MPV_FORMAT_STRING → String', () {
      // We do NOT route through [_decodeAndAssert] for string scalars
      // because the helper's dispose thunk would free the Utf8 buffer
      // before the assertion completes (decodeMpvNode copies the string
      // out, but the test machinery needs to reuse the buffer until the
      // closure returns — which it does already). Simpler: own the leaf.
      final (node, dispose) = _scalarString('hello mpv');
      try {
        expect(decodeMpvNode(node.ref), 'hello mpv');
      } finally {
        dispose();
      }
    });

    test('MPV_FORMAT_INT64 → int (preserves full 64-bit range)', () {
      final (node, dispose) = _scalarInt64(0x7FFFFFFFFFFFFFFF);
      try {
        expect(decodeMpvNode(node.ref), 0x7FFFFFFFFFFFFFFF);
      } finally {
        dispose();
      }

      final (node2, dispose2) = _scalarInt64(-1);
      try {
        expect(decodeMpvNode(node2.ref), -1);
      } finally {
        dispose2();
      }
    });

    test('MPV_FORMAT_DOUBLE → double', () {
      final (node, dispose) = _scalarDouble(3.14159);
      try {
        expect(decodeMpvNode(node.ref), closeTo(3.14159, 1e-9));
      } finally {
        dispose();
      }
    });

    test('MPV_FORMAT_FLAG → bool', () {
      final (n1, d1) = _scalarFlag(true);
      try {
        expect(decodeMpvNode(n1.ref), isTrue);
      } finally {
        d1();
      }

      final (n2, d2) = _scalarFlag(false);
      try {
        expect(decodeMpvNode(n2.ref), isFalse);
      } finally {
        d2();
      }
    });

    test('MPV_FORMAT_BYTE_ARRAY → Uint8List (deep-copied out of mpv heap)',
        () {
      final (node, dispose) = _byteArray([0x42, 0x99, 0x00, 0xFF]);
      try {
        final result = decodeMpvNode(node.ref);
        expect(result, isA<Uint8List>());
        expect(result, [0x42, 0x99, 0x00, 0xFF]);
      } finally {
        dispose();
      }
    });
  });

  group('decodeMpvNode — composite formats', () {
    test('MPV_FORMAT_NODE_MAP with mixed-type entries', () {
      // Build leaves directly so we own every allocation in this scope.
      final fmt = 'floatp'.toNativeUtf8();
      final ch = 'stereo'.toNativeUtf8();
      final samplerateNode = calloc<MpvNode>();
      final formatNode = calloc<MpvNode>();
      final channelsNode = calloc<MpvNode>();
      final channelCountNode = calloc<MpvNode>();
      final list = calloc<MpvNodeList>();
      final values = calloc<MpvNode>(4);
      final keys = calloc<Pointer<Utf8>>(4);
      final root = calloc<MpvNode>();
      final keyFormat = 'format'.toNativeUtf8();
      final keySamplerate = 'samplerate'.toNativeUtf8();
      final keyChannels = 'channels'.toNativeUtf8();
      final keyChannelCount = 'channel-count'.toNativeUtf8();

      try {
        formatNode.ref.format = MpvFormat.mpvFormatString;
        formatNode.ref.u.string = fmt.cast();

        samplerateNode.ref.format = MpvFormat.mpvFormatInt64;
        samplerateNode.ref.u.int64 = 48000;

        channelsNode.ref.format = MpvFormat.mpvFormatString;
        channelsNode.ref.u.string = ch.cast();

        channelCountNode.ref.format = MpvFormat.mpvFormatInt64;
        channelCountNode.ref.u.int64 = 2;

        keys[0] = keyFormat;
        keys[1] = keySamplerate;
        keys[2] = keyChannels;
        keys[3] = keyChannelCount;
        (values + 0).ref.format = formatNode.ref.format;
        (values + 0).ref.u.string = formatNode.ref.u.string;
        (values + 1).ref.format = samplerateNode.ref.format;
        (values + 1).ref.u.int64 = samplerateNode.ref.u.int64;
        (values + 2).ref.format = channelsNode.ref.format;
        (values + 2).ref.u.string = channelsNode.ref.u.string;
        (values + 3).ref.format = channelCountNode.ref.format;
        (values + 3).ref.u.int64 = channelCountNode.ref.u.int64;

        list.ref.num = 4;
        list.ref.values = values;
        list.ref.keys = keys.cast();
        root.ref.format = MpvFormat.mpvFormatNodeMap;
        root.ref.u.list = list;

        final decoded = decodeMpvNode(root.ref);
        expect(decoded, isA<Map<String, dynamic>>());
        final m = decoded as Map<String, dynamic>;
        expect(m['format'], 'floatp');
        expect(m['samplerate'], 48000);
        expect(m['channels'], 'stereo');
        expect(m['channel-count'], 2);
      } finally {
        calloc.free(keyFormat);
        calloc.free(keySamplerate);
        calloc.free(keyChannels);
        calloc.free(keyChannelCount);
        calloc.free(fmt);
        calloc.free(ch);
        calloc.free(formatNode);
        calloc.free(samplerateNode);
        calloc.free(channelsNode);
        calloc.free(channelCountNode);
        calloc.free(values);
        calloc.free(keys);
        calloc.free(list);
        calloc.free(root);
      }
    });

    test('MPV_FORMAT_NODE_ARRAY of strings (playlist-shaped payload)', () {
      // mpv's `audio-device-list` is a plain array of strings before each
      // entry expands into a node-map; this is the simpler shape.
      final s1 = 'a.mp3'.toNativeUtf8();
      final s2 = 'b.mp3'.toNativeUtf8();
      final list = calloc<MpvNodeList>();
      final values = calloc<MpvNode>(2);
      final root = calloc<MpvNode>();

      try {
        (values + 0).ref.format = MpvFormat.mpvFormatString;
        (values + 0).ref.u.string = s1.cast();
        (values + 1).ref.format = MpvFormat.mpvFormatString;
        (values + 1).ref.u.string = s2.cast();
        list.ref.num = 2;
        list.ref.values = values;
        list.ref.keys = nullptr;
        root.ref.format = MpvFormat.mpvFormatNodeArray;
        root.ref.u.list = list;

        final decoded = decodeMpvNode(root.ref);
        expect(decoded, isA<List<dynamic>>());
        expect(decoded, ['a.mp3', 'b.mp3']);
      } finally {
        calloc.free(s1);
        calloc.free(s2);
        calloc.free(values);
        calloc.free(list);
        calloc.free(root);
      }
    });

    test('empty MPV_FORMAT_NODE_ARRAY → empty Dart list', () {
      final list = calloc<MpvNodeList>();
      final root = calloc<MpvNode>();
      try {
        list.ref.num = 0;
        list.ref.values = nullptr;
        list.ref.keys = nullptr;
        root.ref.format = MpvFormat.mpvFormatNodeArray;
        root.ref.u.list = list;
        expect(decodeMpvNode(root.ref), isEmpty);
      } finally {
        calloc.free(list);
        calloc.free(root);
      }
    });

    test('empty MPV_FORMAT_NODE_MAP → empty Dart map', () {
      final list = calloc<MpvNodeList>();
      final root = calloc<MpvNode>();
      try {
        list.ref.num = 0;
        list.ref.values = nullptr;
        list.ref.keys = nullptr;
        root.ref.format = MpvFormat.mpvFormatNodeMap;
        root.ref.u.list = list;
        final decoded = decodeMpvNode(root.ref);
        expect(decoded, isA<Map<String, dynamic>>());
        expect(decoded, isEmpty);
      } finally {
        calloc.free(list);
        calloc.free(root);
      }
    });
  });

  group('decodeMpvNode — defensive', () {
    test('unknown format → null (forward-compat with new mpv format codes)',
        () {
      final node = calloc<MpvNode>();
      try {
        node.ref.format = 9999; // Hypothetical future format mpv may add.
        expect(decodeMpvNode(node.ref), isNull);
      } finally {
        calloc.free(node);
      }
    });
  });
}
