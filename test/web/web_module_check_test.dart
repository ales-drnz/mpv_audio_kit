// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The web module is checked before any other call into it: the r21 module
// of test/web/module passes and keeps the four fields of END_FILE at 28,
// 32, 40 and 48, and a module of another ABI, or one older than the ABI, is
// refused with a message that names it (flutter test --platform chrome
// --wasm).

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';

import 'web_module_helper.dart';

/// A stand-in for a module instance with only the exports a test names.
JSObject _fakeModule({int? abi}) {
  final module = JSObject();
  if (abi != null) module['_mak_web_abi_version'] = (() => abi.toJS).toJS;
  // A layout call means the ABI check let the module through.
  JSNumber layout() => throw StateError('the layout was read before the ABI');
  module['_mak_web_layout'] = layout.toJS;
  return module;
}

void main() {
  test('the r21 module loads, with the four fields of END_FILE', () async {
    final module = await loadTestModule();
    expect(module.endFile, (
      readError: 28,
      skippedSegments: 32,
      duration: 40,
      position: 48,
    ));
  });

  test('a module of another ABI is refused before any other call', () {
    expect(
      () => MpvModule(_fakeModule(abi: 1)),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('has ABI 1'), contains('needs ABI 2')),
        ),
      ),
    );
  });

  test('a module without an ABI version is refused', () {
    expect(
      () => MpvModule(_fakeModule()),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('older than libmpv-r20'),
        ),
      ),
    );
  });
}
