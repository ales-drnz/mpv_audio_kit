// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A module that did not load (libmpv.wasm lost to the network) fails the
// player that asked for it and no other: the next one starts the module
// again, where up to 0.7.0 the failure was the page's until a reload. In a
// file of its own, since the load is the page's.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

int get _starts => (globalContext['__makReloadStarts'] as JSNumber).toDartInt;

void main() {
  test('a player after a module that did not load starts it again', () async {
    // The first start fails as a fetch of libmpv.wasm does; the next ones
    // resolve with no exports, which the ABI check refuses.
    final url = _createObjectUrl(
      _Blob(
        <JSAny>[
          'export default () => {'
                  ' const n = globalThis.__makReloadStarts ='
                  ' (globalThis.__makReloadStarts || 0) + 1;'
                  ' return n === 1'
                  ' ? Promise.reject(new TypeError("Failed to fetch"))'
                  ' : Promise.resolve({});'
                  ' };'
              .toJS,
        ].toJS,
        JSObject()..['type'] = 'text/javascript'.toJS,
      ),
    ).toDart;
    startBackend(libmpv: url, hotRestartCleanup: false);
    await expectLater(
      backendReady(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('did not load'), contains('Failed to fetch')),
        ),
      ),
    );
    expect(_starts, 1);
    // A PCM source meanwhile names the failure.
    expect(
      () => openPcmNative(null),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('failed to load'),
        ),
      ),
    );
    // The next player starts the module again.
    await expectLater(
      backendReady(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('states no ABI version'),
        ),
      ),
    );
    expect(_starts, 2);
    // A module of another ABI is the page's: no third start.
    await expectLater(
      backendReady(),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('states no ABI version'),
        ),
      ),
    );
    expect(_starts, 2);
  });
}
