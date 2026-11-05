// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The release check of the event isolate on a real library of another
// release: a copy of the bundled libmpv whose version stamp `+rN` is
// rewritten to another release of the same length. libmpv_pin_test fakes
// the version with the slow-core shim, which builds on Linux and macOS
// only; this one runs on Windows too. Not on macOS, where the edit breaks
// the code signature of the copy and dyld refuses it.

@TestOn('windows || linux')
@Timeout(Duration(minutes: 1))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

/// A release of the same length as [release] that is not it.
String otherRelease(String release) {
  final n = int.parse(release.substring(1));
  final other = n > 10 ? n - 1 : n + 1;
  return 'r$other'.padRight(release.length, '0').substring(0, release.length);
}

void main() {
  runtimeSuite(initialize: false, fixturePath: defaultFixturePath(), () {
    test(
      'a libmpv of another release fails bring-up in the event isolate',
      () async {
        TestWidgetsFlutterBinding.ensureInitialized();
        final real = resolveLibmpv()!;
        final bytes = File(real).readAsBytesSync();
        final stamp = '+$libmpvRelease'.codeUnits;
        final other = otherRelease(libmpvRelease);
        final replaced = '+$other'.codeUnits;
        var count = 0;
        for (var i = 0; i + stamp.length <= bytes.length; i++) {
          var hit = true;
          for (var j = 0; hit && j < stamp.length; j++) {
            hit = bytes[i + j] == stamp[j];
          }
          // The stamp ends the version string: a NUL follows.
          if (!hit || bytes[i + stamp.length] != 0) continue;
          bytes.setRange(i, i + stamp.length, replaced);
          count++;
        }
        expect(count, greaterThan(0), reason: 'no +$libmpvRelease in $real');
        final dir = Directory.systemTemp.createTempSync('mak_pin_copy');
        addTearDown(() {
          try {
            dir.deleteSync(recursive: true);
          } on FileSystemException {
            // Windows keeps a loaded DLL locked until the process ends.
          }
        });
        final copy = File(
          '${dir.path}${Platform.pathSeparator}${real.split(RegExp(r'[/\\]')).last}',
        )..writeAsBytesSync(bytes);
        MpvAudioKit.ensureInitialized(
          libmpv: copy.path,
          hotRestartCleanup: false,
        );
        final player = Player(
          configuration: const PlayerConfiguration(logLevel: LogLevel.off),
        );
        addTearDown(player.dispose);
        await expectLater(
          player.ready,
          throwsA(
            isA<PlayerInitException>().having(
              (e) => e.message,
              'message',
              allOf(contains('+$other'), contains('libmpv-$libmpvRelease')),
            ),
          ),
        );
      },
    );
  });
}
