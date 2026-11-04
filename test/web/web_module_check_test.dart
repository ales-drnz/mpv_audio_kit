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
  test('the module of the pin loads', () async {
    await loadTestModule();
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
          contains('states no ABI version'),
        ),
      ),
    );
  });

  // kit-web-1: the factory waits for the workers of the module's threads,
  // and one that cannot load them never settles. The load fails instead.
  test('a module whose threads never start fails the load', () async {
    final url = _createObjectUrl(
      _Blob(
        <JSAny>['export default () => new Promise(() => {});'.toJS].toJS,
        JSObject()..['type'] = 'text/javascript'.toJS,
      ),
    ).toDart;
    await expectLater(
      loadMpvModule(url, timeout: const Duration(seconds: 1)),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('did not start within 1 s'), contains('COEP')),
        ),
      ),
    );
  });

  // A start past the timeout goes on: the next load waits for it, and
  // does not make a second module beside it.
  test('a load after a timeout waits for the same start', () async {
    final url = _createObjectUrl(
      _Blob(
        <JSAny>[
          'export default () => {'
                  ' globalThis.__makStarts = (globalThis.__makStarts || 0) + 1;'
                  ' return new Promise((r) => { globalThis.__makStarted = r; });'
                  ' };'
              .toJS,
        ].toJS,
        JSObject()..['type'] = 'text/javascript'.toJS,
      ),
    ).toDart;
    await expectLater(
      loadMpvModule(url, timeout: const Duration(milliseconds: 500)),
      throwsA(isA<WebModuleTimeout>()),
    );
    final again = loadMpvModule(url, timeout: const Duration(seconds: 10));
    // The start resolves with no exports: MpvModule then fails, not the
    // wait.
    (globalContext['__makStarted'] as JSFunction).callAsFunction(
      null,
      JSObject(),
    );
    await expectLater(again, throwsA(isNot(isA<WebModuleTimeout>())));
    expect((globalContext['__makStarts'] as JSNumber).toDartInt, 1);
  });
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);
