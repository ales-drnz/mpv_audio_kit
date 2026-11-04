// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The layout of the client API structs the release states, against what
// the package reads. libmpv-scripts measures sizeof and offsetof on the
// patched client.h of the release, per data model, and write_manifest.sh
// puts them under structLayout in the manifest scripts/update_libmpv.sh
// copies to tool/codegen: the FFI structs of mpv_bindings.dart (lp64, the
// hosts the tests run on) and the wasm32 table of web_layout.dart (ilp32)
// must say the same, or a pin of a release that moved a field fails here.

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/backend/web/web_layout.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as ffi;
import 'package:test/test.dart';

typedef _Layout = Map<String, ({int size, Map<String, int> fields})>;

_Layout _model(String name) {
  final manifest =
      jsonDecode(File('tool/codegen/libmpv_manifest.json').readAsStringSync())
          as Map<String, Object?>;
  final layout = manifest['structLayout'] as Map<String, Object?>?;
  if (layout == null) {
    fail('the manifest of ${manifest['release']} has no structLayout');
  }
  return {
    for (final MapEntry(:key, :value)
        in (layout[name]! as Map<String, Object?>).entries)
      key: (
        size: (value! as Map)['size'] as int,
        fields: ((value as Map)['fields'] as Map).cast<String, int>(),
      ),
  };
}

/// The first byte of [p] that is not zero, or -1.
int _first(Pointer<Uint8> p, int size) {
  for (var i = 0; i < size; i++) {
    if (p[i] != 0) return i;
  }
  return -1;
}

final _one = Pointer<Void>.fromAddress(8);

/// The size of a struct and the offset of each C field, measured by
/// setting the field through the FFI copy in a zeroed struct.
typedef _Measured = ({int size, Map<String, int Function()> fields});

int _mpvEvent(void Function(ffi.MpvEvent s) set) {
  final p = calloc<ffi.MpvEvent>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEvent>());
  } finally {
    calloc.free(p);
  }
}

int _mpvEventStartFileData(void Function(ffi.MpvEventStartFileData s) set) {
  final p = calloc<ffi.MpvEventStartFileData>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEventStartFileData>());
  } finally {
    calloc.free(p);
  }
}

int _mpvEventEndFile(void Function(ffi.MpvEventEndFile s) set) {
  final p = calloc<ffi.MpvEventEndFile>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEventEndFile>());
  } finally {
    calloc.free(p);
  }
}

int _mpvEventProperty(void Function(ffi.MpvEventProperty s) set) {
  final p = calloc<ffi.MpvEventProperty>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEventProperty>());
  } finally {
    calloc.free(p);
  }
}

int _mpvEventLogMessage(void Function(ffi.MpvEventLogMessage s) set) {
  final p = calloc<ffi.MpvEventLogMessage>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEventLogMessage>());
  } finally {
    calloc.free(p);
  }
}

int _mpvNode(void Function(ffi.MpvNode s) set) {
  final p = calloc<ffi.MpvNode>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvNode>());
  } finally {
    calloc.free(p);
  }
}

int _mpvNodeList(void Function(ffi.MpvNodeList s) set) {
  final p = calloc<ffi.MpvNodeList>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvNodeList>());
  } finally {
    calloc.free(p);
  }
}

int _mpvByteArray(void Function(ffi.MpvByteArray s) set) {
  final p = calloc<ffi.MpvByteArray>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvByteArray>());
  } finally {
    calloc.free(p);
  }
}

int _mpvEventHook(void Function(ffi.MpvEventHook s) set) {
  final p = calloc<ffi.MpvEventHook>();
  try {
    set(p.ref);
    return _first(p.cast(), sizeOf<ffi.MpvEventHook>());
  } finally {
    calloc.free(p);
  }
}

final Map<String, _Measured> _ffiStructs = {
  'mpv_event': (
    size: sizeOf<ffi.MpvEvent>(),
    fields: {
      'event_id': () => _mpvEvent((s) => s.eventId = 1),
      'error': () => _mpvEvent((s) => s.error = 1),
      'reply_userdata': () => _mpvEvent((s) => s.replyUserdata = 1),
      'data': () => _mpvEvent((s) => s.data = _one),
    },
  ),
  'mpv_event_start_file': (
    size: sizeOf<ffi.MpvEventStartFileData>(),
    fields: {
      'playlist_entry_id': () =>
          _mpvEventStartFileData((s) => s.playlistEntryId = 1),
    },
  ),
  'mpv_event_end_file': (
    size: sizeOf<ffi.MpvEventEndFile>(),
    fields: {
      'reason': () => _mpvEventEndFile((s) => s.reason = 1),
      'error': () => _mpvEventEndFile((s) => s.error = 1),
      'playlist_entry_id': () => _mpvEventEndFile((s) => s.playlistEntryId = 1),
      'playlist_insert_id': () =>
          _mpvEventEndFile((s) => s.playlistInsertId = 1),
      'playlist_insert_num_entries': () =>
          _mpvEventEndFile((s) => s.playlistInsertNumEntries = 1),
      'mak_read_error': () => _mpvEventEndFile((s) => s.makReadError = 1),
      'mak_skipped_segments': () =>
          _mpvEventEndFile((s) => s.makSkippedSegments = 1),
      'mak_duration': () => _mpvEventEndFile((s) => s.makDuration = 5e-324),
      'mak_position': () => _mpvEventEndFile((s) => s.makPosition = 5e-324),
    },
  ),
  'mpv_event_property': (
    size: sizeOf<ffi.MpvEventProperty>(),
    fields: {
      'name': () => _mpvEventProperty((s) => s.name = _one),
      'format': () => _mpvEventProperty((s) => s.format = 1),
      'data': () => _mpvEventProperty((s) => s.data = _one),
    },
  ),
  'mpv_event_log_message': (
    size: sizeOf<ffi.MpvEventLogMessage>(),
    fields: {
      'prefix': () => _mpvEventLogMessage((s) => s.prefix = _one),
      'level': () => _mpvEventLogMessage((s) => s.level = _one),
      'text': () => _mpvEventLogMessage((s) => s.text = _one),
      'log_level': () => _mpvEventLogMessage((s) => s.logLevel = 1),
    },
  ),
  'mpv_node': (
    size: sizeOf<ffi.MpvNode>(),
    fields: {
      'u': () => _mpvNode((s) => s.u.int64 = 1),
      'format': () => _mpvNode((s) => s.format = 1),
    },
  ),
  'mpv_node_list': (
    size: sizeOf<ffi.MpvNodeList>(),
    fields: {
      'num': () => _mpvNodeList((s) => s.num = 1),
      'values': () => _mpvNodeList((s) => s.values = _one.cast()),
      'keys': () => _mpvNodeList((s) => s.keys = _one.cast()),
    },
  ),
  'mpv_byte_array': (
    size: sizeOf<ffi.MpvByteArray>(),
    fields: {
      'data': () => _mpvByteArray((s) => s.data = _one),
      'size': () => _mpvByteArray((s) => s.size = 1),
    },
  ),
  'mpv_event_hook': (
    size: sizeOf<ffi.MpvEventHook>(),
    fields: {
      'name': () => _mpvEventHook((s) => s.name = _one),
      'id': () => _mpvEventHook((s) => s.id = 1),
    },
  ),
};

void main() {
  test('the FFI structs lay out as the release states for lp64', () {
    expect(sizeOf<Pointer>(), 8, reason: 'the tests run on 64-bit hosts');
    final release = _model('lp64');
    expect(release.keys.toSet(), _ffiStructs.keys.toSet());
    for (final MapEntry(key: name, value: s) in _ffiStructs.entries) {
      final want = release[name]!;
      expect(s.size, want.size, reason: 'sizeof $name');
      expect(
        s.fields.keys.toSet(),
        want.fields.keys.toSet(),
        reason: 'the fields of $name',
      );
      for (final MapEntry(key: field, value: offset) in want.fields.entries) {
        expect(s.fields[field]!(), offset, reason: '$name.$field');
      }
    }
  });

  test('the wasm32 table of web_layout.dart is the release\'s ilp32', () {
    final l = _model('ilp32');
    int at(String s, String f) => l[s]!.fields[f]!;
    int size(String s) => l[s]!.size;
    // The order of mak_web_layout() (scripts/web/mak_web.c).
    final table = [
      size('mpv_node'),
      at('mpv_node', 'format'),
      size('mpv_node_list'),
      at('mpv_node_list', 'values'),
      at('mpv_node_list', 'keys'),
      size('mpv_byte_array'),
      at('mpv_byte_array', 'size'),
      size('mpv_event'),
      at('mpv_event', 'error'),
      at('mpv_event', 'reply_userdata'),
      at('mpv_event', 'data'),
      size('mpv_event_property'),
      at('mpv_event_property', 'format'),
      at('mpv_event_property', 'data'),
      size('mpv_event_log_message'),
      at('mpv_event_log_message', 'text'),
      at('mpv_event_log_message', 'log_level'),
      size('mpv_event_end_file'),
      at('mpv_event_end_file', 'error'),
      at('mpv_event_end_file', 'playlist_entry_id'),
      at('mpv_event_end_file', 'playlist_insert_id'),
      at('mpv_event_end_file', 'playlist_insert_num_entries'),
      at('mpv_event_end_file', 'mak_read_error'),
      at('mpv_event_end_file', 'mak_skipped_segments'),
      at('mpv_event_end_file', 'mak_duration'),
      at('mpv_event_end_file', 'mak_position'),
      size('mpv_event_hook'),
      at('mpv_event_hook', 'id'),
    ];
    checkWebLayout(table);
  });
}
