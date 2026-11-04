// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The checks a web module (libmpv.mjs and libmpv.wasm of libmpv-scripts)
// passes before the package makes any other call into it: its ABI version
// and the layout of the client API structs on wasm32. Plain Dart, so the
// rules run on the VM too.

import 'package:meta/meta.dart';

import '../../internals/libmpv_release.dart';

/// The `struct` sizes and offsets of the client API on wasm32, in the order
/// of `mak_web_layout()` (scripts/web/mak_web.c of libmpv-scripts): sizeof
/// and offsetof of mpv_node, mpv_node_list, mpv_byte_array, mpv_event,
/// mpv_event_property, mpv_event_log_message, mpv_event_end_file (with the
/// four fields of the patch read_error) and mpv_event_hook. The decoders
/// use these numbers.
const List<int> _kLayout = [
  16, 8, // mpv_node: size, format
  12, 4, 8, // mpv_node_list: size, values, keys
  8, 4, // mpv_byte_array: size, size field
  24, 4, 8, 16, // mpv_event: size, error, reply_userdata, data
  12, 4, 8, // mpv_event_property: size, format, data
  16, 8, 12, // mpv_event_log_message: size, text, log_level
  56, 4, 8, 16, 24, // mpv_event_end_file: size, error, entry, insert, num
  28, 32, // mpv_event_end_file: mak_read_error, mak_skipped_segments
  40, 48, // mpv_event_end_file: mak_duration, mak_position
  16, 8, // mpv_event_hook: size, id
];

/// Where `mpv_event_end_file` keeps the four fields the patch read_error
/// adds at its end: `mak_read_error` (int32), `mak_skipped_segments`
/// (int64), `mak_duration` and `mak_position` (double).
@internal
const ({int readError, int skippedSegments, int duration, int position})
kEndFileFields = (
  readError: 28,
  skippedSegments: 32,
  duration: 40,
  position: 48,
);

/// Checks [version], what the module's `mak_web_abi_version()` returned
/// (`null` for a module without it), against [webModuleAbi].
///
/// Throws [StateError] for a module of another ABI.
@internal
void checkWebModuleAbi(int? version) {
  if (version == webModuleAbi) return;
  final what = version == null ? 'states no ABI version' : 'has ABI $version';
  throw StateError(
    'mpv_audio_kit: the web module $what, and this mpv_audio_kit needs '
    'ABI $webModuleAbi: use the libmpv.mjs, libmpv.wasm and '
    'mak_webaudio_processor.js of the libmpv-$libmpvRelease release',
  );
}

/// Checks [table], the module's `mak_web_layout()` up to its `-1` end,
/// against the layout the decoders read.
///
/// Throws [StateError] when any size or offset differs.
@internal
void checkWebLayout(List<int> table) {
  var ok = table.length == _kLayout.length;
  for (var i = 0; ok && i < _kLayout.length; i++) {
    ok = table[i] == _kLayout[i];
  }
  if (!ok) {
    throw StateError(
      'mpv_audio_kit: the web module lays out the client API structs as '
      '$table, which this mpv_audio_kit does not read',
    );
  }
}
