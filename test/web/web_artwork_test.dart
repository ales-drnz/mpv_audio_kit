// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The artwork fetcher of the browser on a blob: URL of the page, what a
// cover the user picked becomes (flutter test --platform chrome --wasm).

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(JSString url);

void main() {
  test('a blob: cover of the page is fetched, with its type', () async {
    final bytes = Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47, 1, 2]);
    final options = {'type': 'image/png'}.jsify()! as JSObject;
    final url = _createObjectUrl(_Blob([bytes.toJS].toJS, options));
    addTearDown(() => _revokeObjectUrl(url));
    final cover = await loadArtwork(url.toDart);
    expect(cover?.bytes, bytes);
    expect(cover?.mimeType, 'image/png');
  });

  test('a content:// or file:// cover is not read in the browser', () async {
    expect(await loadArtwork('content://media/external/images/1'), isNull);
    expect(await loadArtwork('file:///cover.png'), isNull);
  });
}
