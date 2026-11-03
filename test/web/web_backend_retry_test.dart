// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The load of the page's module through the backend, as a player gets it:
// a start past the timeout fails that player, and the next one waits for
// the same start instead of the failure kept for the page. A failure of
// another kind stays the page's. In a file of its own, since the load is
// the page's and runs once.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

int get _starts => (globalContext['__makBackendStarts'] as JSNumber).toDartInt;

void main() {
  test('a player after a timeout waits for the same start, and a failure '
      'of another kind stays', () async {
    final url = _createObjectUrl(
      _Blob(
        <JSAny>[
          'export default () => {'
                  ' globalThis.__makBackendStarts ='
                  ' (globalThis.__makBackendStarts || 0) + 1;'
                  ' return new Promise((r) => { globalThis.__makBackendStart = r; });'
                  ' };'
              .toJS,
        ].toJS,
        JSObject()..['type'] = 'text/javascript'.toJS,
      ),
    ).toDart;
    debugWebModuleTimeout = const Duration(milliseconds: 500);
    startBackend(libmpv: url, hotRestartCleanup: false);
    await expectLater(backendReady(), throwsA(isA<WebModuleTimeout>()));
    // The next player waits for the start again: it resolves with no
    // exports, so the module fails, and not on the timeout.
    debugWebModuleTimeout = const Duration(seconds: 10);
    final again = backendReady()!;
    (globalContext['__makBackendStart'] as JSFunction).callAsFunction(
      null,
      JSObject(),
    );
    await expectLater(again, throwsA(isNot(isA<WebModuleTimeout>())));
    expect(_starts, 1);
    // That failure is the page's: a third player gets it, with no start.
    await expectLater(backendReady(), throwsA(isNot(isA<WebModuleTimeout>())));
    expect(_starts, 1);
  });
}
