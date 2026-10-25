// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Loads the web module (test/web/module, see fetch_module.sh) for the
// browser tests, and turns fixtures into URLs the module opens.
//
// `flutter test --cross-origin-isolation` sends COOP and COEP with the
// .html page only. A worker inherits the page's isolation only when its
// script comes from a blob: URL; one served without COEP is refused. So the
// glue is loaded from a blob of its own text, whose workers (Emscripten's
// pthreads, `new Worker(new URL("libmpv.mjs", import.meta.url))`) are made
// from the same blob. An app served with the headers on every file, as a
// web host is set up, needs none of this.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';

@JS('fetch')
external JSPromise<_Response> _fetch(JSString url);

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external int get status;
  external JSPromise<JSString> text();
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

/// The origin the test page is served from.
String get testOrigin => Uri.base.origin;

/// The URL of [path] under the test directory, as the test server serves
/// it (`fixtures/sine_5s.flac` is test/fixtures/sine_5s.flac).
String testUrl(String path) => '$testOrigin/$path';

Future<_Response> _get(String url) async {
  final response = await _fetch(url.toJS).toDart;
  if (!response.ok) {
    throw StateError('GET $url: HTTP ${response.status}');
  }
  return response;
}

/// The bytes of [path] under the test directory.
Future<Uint8List> fetchBytes(String path) async {
  final response = await _get(testUrl(path));
  final buffer = await response.arrayBuffer().toDart;
  return buffer.toDart.asUint8List();
}

String _blobUrl(JSAny part, String type) {
  final options = JSObject()..['type'] = type.toJS;
  return _createObjectUrl(_Blob(<JSAny>[part].toJS, options)).toDart;
}

/// A `makblob://` URL the module opens for the bytes of [path], as it
/// opens a file the user picked (a blob: URL of the page).
Future<String> blobFixture(String path) async {
  final bytes = await fetchBytes(path);
  final url = _blobUrl(bytes.toJS, 'application/octet-stream');
  return 'makblob://${url.substring('blob:'.length)}';
}

/// Loads the module once and makes it the one every session uses.
Future<MpvModule> loadTestModule() {
  return debugWebModule ??= () async {
    final glue = await (await _get(
      testUrl('web/module/libmpv.mjs'),
    )).text().toDart;
    const from = 'new URL("libmpv.mjs",import.meta.url)';
    final text = glue.toDart;
    if (!text.contains(from)) {
      throw StateError('the glue makes its workers another way');
    }
    final blob = _blobUrl(
      text.replaceAll(from, 'new URL(import.meta.url)').toJS,
      'text/javascript',
    );
    return loadMpvModule(
      blob,
      wasmUrl: testUrl('web/module/libmpv.wasm'),
      processorUrl: testUrl('web/module/mak_webaudio_processor.js'),
    );
  }();
}
