// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// END_FILE of the web module carries the four fields of the read_error
// patch (offsets 28, 32, 40 and 48 in r21), decoded by the web session into
// the event the player gets: a file read to its end says no error, a file
// cut short whose resume the server refuses says it ended on one, and the
// event carries the duration and position of the entry, which a bare
// session observes nowhere else. The cut file
// comes from net_server.dart (test/web/with_net_server.sh --platform chrome
// --wasm), without which that case skips.

@TestOn('browser')
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/mpv_session.dart';
import 'package:mpv_audio_kit/src/backend/web/web_session.dart';
import 'package:mpv_audio_kit/src/internals/core_events.dart';
import 'package:mpv_audio_kit/src/mpv_constants.dart';

import 'web_module_helper.dart';

const String _net = String.fromEnvironment('MAK_WEB_NET');

/// Plays [url] on a bare session of the module to its end, with the
/// loadfile [options], and returns the END_FILE the player would get.
Future<MpvEventEndFile> _endOf(String url, {String? options}) async {
  final session = WebSession(loadTestModule);
  final ended = Completer<MpvEventEndFile>();
  await session.start(
    const CoreRecipe(
      preInitOptions: {'ao': 'null', 'idle': 'yes', 'keep-open': 'no'},
      postInitOptions: {},
      observes: [],
    ),
    (event) {
      switch (event) {
        case MpvEventEndFile() when !ended.isCompleted:
          ended.complete(event);
        case MpvEventReply(:final userdata, :final error):
          session.onReply(userdata, error, null);
        default:
      }
    },
  );
  try {
    await session.command([
      'loadfile',
      url,
      if (options != null) ...['replace', '-1', options],
    ]);
    return await ended.future.timeout(const Duration(seconds: 40));
  } finally {
    session.requestStop();
    if (await session.stop()) await session.terminateDestroy();
  }
}

void main() {
  test('a file read to its end ends with no read error', () async {
    final end = await _endOf(testUrl('fixtures/sine_stereo_1s.flac'));
    expect(end.reason, MpvEndFileReason.mpvEndFileReasonEof);
    expect(end.readError, isFalse);
    expect(end.skippedSegments, 0);
    expect(end.duration, closeTo(1.0, 0.005));
    expect(end.position, inInclusiveRange(0.0, 1.005));
  }, timeout: const Timeout(Duration(seconds: 60)));

  // A duration and a position apart: offsets 40 and 48 read the wrong way
  // round, or one of them twice, fail here.
  test('an entry ended at 0.5 s carries its own position', () async {
    final end = await _endOf(
      testUrl('fixtures/sine_stereo_1s.flac'),
      options: 'end=0.5',
    );
    expect(end.reason, MpvEndFileReason.mpvEndFileReasonEof);
    expect(end.duration, closeTo(1.0, 0.005));
    // Gapless ends the entry once its decoder is done, while the output
    // still plays the buffer: the position trails 0.5 s.
    expect(end.position, inInclusiveRange(0.0, 0.505));
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'a file cut short, its resume refused, ends on a read error',
    () async {
      final end = await _endOf('$_net/cut/sine_5s.flac');
      expect(end.reason, MpvEndFileReason.mpvEndFileReasonEof);
      expect(end.readError, isTrue);
      expect(end.skippedSegments, 0);
    },
    skip: _net.isEmpty ? 'needs test/web/with_net_server.sh' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );

  // kit-web-10: skippedSegments at its offset, with a value other than 0.
  test(
    'an HLS stream with a segment that never opens counts it',
    () async {
      final end = await _endOf('$_net/hls/a.m3u8');
      expect(end.reason, MpvEndFileReason.mpvEndFileReasonEof);
      expect(end.skippedSegments, 1);
      expect(end.readError, isFalse);
    },
    skip: _net.isEmpty ? 'needs test/web/with_net_server.sh' : false,
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
