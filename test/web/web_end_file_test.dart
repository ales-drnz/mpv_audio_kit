// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// END_FILE of the web module carries the read error fields of the r20
// read_error patch (offsets 28 and 32), decoded by the web session into the
// event the player gets: a file read to its end says no error, a file cut
// short whose resume the server refuses says it ended on one. The cut file
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

/// Plays [url] on a bare session of the module to its end and returns the
/// END_FILE the player would get.
Future<MpvEventEndFile> _endOf(String url) async {
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
    await session.command(['loadfile', url]);
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
}
