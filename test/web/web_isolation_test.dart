// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// What the page lacks fails the player at once, with the reason: in a page
// that is not cross-origin isolated the module's threads cannot start, and
// its factory would never settle. Run twice: with the suites (--wasm
// --cross-origin-isolation), where the page has what it needs, and through
// DDC, whose page flutter test serves without COOP and COEP:
//
//   flutter test --platform chrome test/web/web_isolation_test.dart

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';

import 'web_module_helper.dart';

final bool _isolated =
    globalContext.getProperty<JSBoolean?>('crossOriginIsolated'.toJS)?.toDart ??
    false;

void main() {
  test('an isolated page has what the player needs', () {
    expect(MpvAudioKit.unsupportedReason, isNull);
  }, skip: _isolated ? false : 'runs in an isolated page');

  test('a page that is not cross-origin isolated fails the player at once, '
      'with the reason', () async {
    final reason = MpvAudioKit.unsupportedReason;
    expect(reason, contains('is not cross-origin isolated'));
    // The module of the suites: without isolation its factory never
    // settles, since its threads cannot get the shared memory.
    debugWebModule = loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
    final player = Player();
    await expectLater(
      player.ready.timeout(const Duration(seconds: 5)),
      throwsA(
        isA<PlayerInitException>().having(
          (e) => e.message,
          'message',
          contains('is not cross-origin isolated'),
        ),
      ),
    );
    await player.dispose();
  }, skip: _isolated ? 'runs in a page that is not isolated' : false);
}
