// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A bring-up that fails on the web keeps what failed it: the
// PlayerInitException carries the error as its cause and is thrown with
// that error's stack, where up to 0.7.0 both were flattened into the
// message (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/mpv_session.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';
import 'package:mpv_audio_kit/src/backend/web/web_session.dart';

import 'fake_module.dart';

const _recipe = CoreRecipe(
  preInitOptions: {},
  postInitOptions: {},
  observes: [],
);

void main() {
  test('a module that failed to load is the cause, with its stack', () async {
    final failure = StateError('the module did not load');
    final stack = StackTrace.fromString('the stack of the load');
    final session = WebSession(() => Future.error(failure, stack));
    try {
      await session.start(_recipe, (_) {});
      fail('the bring-up passed');
    } on PlayerInitException catch (e, st) {
      expect(e.message, contains('the module did not load'));
      expect(e.cause, same(failure));
      expect(st.toString(), contains('the stack of the load'));
    }
  });

  test('an init that crashed is the cause, its stack out of the '
      'message', () async {
    final fake = FakeModule()..throwing.add('_mpv_set_option_string');
    final module = MpvModule(fake.instance);
    final session = WebSession(() async => module);
    try {
      await session.start(_recipe, (_) {});
      fail('the bring-up passed');
    } on PlayerInitException catch (e) {
      expect(e.message, startsWith('init crashed: '));
      expect(e.message, isNot(contains('\n')));
      expect(e.cause, isNotNull);
      expect('${e.cause}', contains('Aborted()'));
    }
    // The core made before the crash is destroyed.
    expect(fake.calls.last, '_mpv_terminate_destroy');
  });
}
