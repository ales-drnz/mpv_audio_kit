// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/event_isolate.dart';
import 'package:mpv_audio_kit/src/mpv_bindings.dart' as mpv;

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  // The bring-up dropped the return codes of its option and property
  // writes: an option mpv refused (a name another release changed, a
  // value out of range) left the default in place and no trace.
  test('an option or a property mpv refuses at bring-up is reported as a '
      'warning', () async {
    final libPath = resolveLibmpv();
    if (libPath == null) {
      skipMissing('libmpv not bundled for this host');
      return;
    }
    final lib = mpv.MpvLibrary.open(libPath);
    final iso = MpvEventIsolate();
    final events = <MpvIsolateEvent>[];
    final handleAddr = await iso.start(
      libraryPath: libPath,
      onEvent: events.add,
      preInitOptions: const {
        'ao': 'null',
        'vo': 'null',
        'idle': 'yes',
        'no-such-option': '1',
        'audio-channels': 'not-a-layout',
      },
      postInitOptions: const {'volume': 'loud', 'mute': 'yes'},
      observes: const <MpvObserveSpec>[],
    );
    final handle = Pointer<mpv.MpvHandle>.fromAddress(handleAddr);
    try {
      await waitUntil(
        () => events.whereType<MpvEventInternalLog>().isNotEmpty,
        reason: 'no warning for the refused writes',
      );
      final logs = events.whereType<MpvEventInternalLog>().toList();
      final warning = logs.singleWhere((l) => l.level == 'warn');
      expect(
        warning.text,
        contains('option audio-channels=not-a-layout: rc=-'),
      );
      expect(warning.text, contains('property volume=loud: rc=-'));
      expect(warning.text, isNot(contains('mute')));
      expect(warning.text, isNot(contains('idle')));
      // An option the build does not have is no warning: the recipe of
      // the player names features an audio build leaves out.
      expect(warning.text, isNot(contains('no-such-option')));
      final debug = logs.singleWhere((l) => l.level == 'debug');
      expect(debug.text, contains('no-such-option'));
    } finally {
      iso.requestStop(lib, handle);
      expect(await iso.stop(), isTrue);
      lib.mpvTerminateDestroy(handle);
    }
  }, timeout: const Timeout(Duration(seconds: 20)));

  runtimeSuite(() {
    test('the recipe of a default player gives no warning', () async {
      final logs = <MpvLogEntry>[];
      final player = Player();
      player.stream.internalLog.listen(logs.add);
      await player.ready;
      await Future<void>.delayed(const Duration(milliseconds: 200));
      await player.dispose();
      expect(
        logs.where((l) => l.level == LogLevel.warn),
        isEmpty,
        reason: '${logs.map((l) => l.text).toList()}',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
