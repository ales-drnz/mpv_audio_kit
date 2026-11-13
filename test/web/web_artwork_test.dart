// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The artwork fetcher of the browser on a blob: URL of the page, what a
// cover the user picked becomes, and its bounds on a fetch that stands in
// for the browser's: a download past the timeout is aborted, and a body
// without a content-length stops at the limit (flutter test --platform
// chrome --wasm).

@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_cancel.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_sources.dart';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL.createObjectURL')
external JSString _createObjectUrl(JSObject blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(JSString url);

@JS('ReadableStream')
extension type _Stream._(JSObject _) implements JSObject {
  external _Stream(JSObject source);
}

@JS('Response')
extension type _Response._(JSObject _) implements JSObject {
  external _Response(JSObject body);
}

@JS('Promise')
extension type _Promise._(JSObject _) implements JSObject {
  external _Promise(JSFunction executor);
}

/// Puts [fetch] in place of the browser's for the test; returns the init
/// objects it was called with.
List<JSObject> _replaceFetch(JSObject Function() fetch) {
  final inits = <JSObject>[];
  final real = globalContext['fetch'];
  addTearDown(() => globalContext['fetch'] = real);
  globalContext['fetch'] = ((JSString url, JSObject init) {
    inits.add(init);
    return fetch();
  }).toJS;
  return inits;
}

bool _aborted(JSObject init) {
  final signal = init['signal'];
  return signal.isA<JSObject>() &&
      ((signal as JSObject)['aborted'] as JSBoolean).toDart;
}

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

  // A widget test for its clock: the 15 s pass at once.
  testWidgets('a fetch that does not answer is aborted at the timeout', (
    tester,
  ) async {
    final inits = _replaceFetch(() => _Promise(((JSAny a, JSAny b) {}).toJS));
    Object? cover = 'none';
    unawaited(
      loadArtwork(
        'https://example.invalid/cover.png',
      ).then((value) => cover = value),
    );
    await tester.pump(const Duration(seconds: 14));
    expect(cover, 'none');
    expect(_aborted(inits.single), isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(cover, isNull);
    expect(_aborted(inits.single), isTrue);
  });

  test('a cancel that fires aborts the fetch in flight', () async {
    final inits = _replaceFetch(() => _Promise(((JSAny a, JSAny b) {}).toJS));
    // The stand-in never settles: the abort of its signal is what shows.
    // The browser's own fetch rejects on it, which ends the download.
    final cancel = ArtworkCancel();
    unawaited(loadArtwork('https://example.invalid/cover.png', '', cancel));
    await Future<void>.delayed(Duration.zero);
    expect(_aborted(inits.single), isFalse);
    cancel.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(_aborted(inits.single), isTrue);
  });

  test('a cancel that fired before the load starts no fetch', () async {
    final inits = _replaceFetch(() => _Promise(((JSAny a, JSAny b) {}).toJS));
    final cancel = ArtworkCancel()..cancel();
    expect(
      await loadArtwork('https://example.invalid/cover.png', '', cancel),
      isNull,
    );
    expect(inits, isEmpty);
  });

  test('a body without a content-length stops at the limit', () async {
    // 30 chunks of 1 MB, past the 20 MB a cover may have.
    const chunks = 30;
    var pulls = 0;
    var cancelled = false;
    final chunk = Uint8List(1024 * 1024).toJS;
    final source = JSObject()
      ..['pull'] = ((JSObject controller) {
        if (pulls++ < chunks) {
          controller.callMethod('enqueue'.toJS, chunk);
        } else {
          controller.callMethod('close'.toJS);
        }
      }).toJS
      ..['cancel'] = ((JSAny? reason) {
        cancelled = true;
      }).toJS;
    final inits = _replaceFetch(
      () => Future.value(_Response(_Stream(source))).toJS,
    );
    expect(await loadArtwork('https://example.invalid/cover.png'), isNull);
    expect(pulls, lessThan(maxArtworkBytes ~/ (1024 * 1024) + 3));
    expect(cancelled, isTrue);
    expect(_aborted(inits.single), isTrue);
  });

  test('a body without a content-length under the limit is the '
      'cover', () async {
    var pulls = 0;
    final source = JSObject()
      ..['pull'] = ((JSObject controller) {
        if (pulls++ < 3) {
          final chunk = Uint8List.fromList([pulls, pulls]).toJS;
          controller.callMethod('enqueue'.toJS, chunk);
        } else {
          controller.callMethod('close'.toJS);
        }
      }).toJS;
    _replaceFetch(() => Future.value(_Response(_Stream(source))).toJS);
    final cover = await loadArtwork('https://example.invalid/cover.png');
    expect(cover?.bytes, [1, 1, 2, 2, 3, 3]);
  });
}
