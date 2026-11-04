// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('vm')
library;

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as mpv;
import 'package:test/test.dart';

/// The END_FILE payload the native pump decodes, laid out by hand at the
/// offsets of libmpv-scripts' patch read_error: the upstream fields, then
/// mak_read_error at 28, mak_skipped_segments at 32, mak_duration at 40
/// and mak_position at 48.
void main() {
  late Pointer<Uint8> event;

  setUp(() {
    event = calloc<Uint8>(56);
    event.cast<Int32>()[0] = mpv.MpvEndFileReason.mpvEndFileReasonEof;
    event.cast<Int64>()[1] = 8; // playlist_entry_id at 8
    (event + 28).cast<Int32>().value = 1;
    (event + 32).cast<Int64>().value = 2;
    (event + 40).cast<Double>().value = 180.5;
    (event + 48).cast<Double>().value = 179.25;
  });

  tearDown(() => calloc.free(event));

  test('the struct has the size of the pinned release', () {
    expect(sizeOf<mpv.MpvEventEndFile>(), 56);
  });

  test('every field is read', () {
    final e = decodeEndFile(event.cast());
    expect(e.entryId, 8);
    expect(e.reason, mpv.MpvEndFileReason.mpvEndFileReasonEof);
    expect(e.readError, isTrue);
    expect(e.skippedSegments, 2);
    expect(e.duration, 180.5);
    expect(e.position, 179.25);
  });

  test('a duration or position mpv did not know is null', () {
    (event + 40).cast<Double>().value = -1;
    (event + 48).cast<Double>().value = -1;
    final e = decodeEndFile(event.cast());
    expect(e.duration, isNull);
    expect(e.position, isNull);
    expect(e.readError, isTrue);
  });
}
