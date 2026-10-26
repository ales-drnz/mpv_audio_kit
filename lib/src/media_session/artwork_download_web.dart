// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// The artwork download of artwork_fetcher.dart in the browser: a fetch,
// which reads only what CORS allows. A URL it cannot read reaches the
// browser's media session as it is (media_session_controller.dart), and the
// browser loads it as an image.

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:meta/meta.dart';

import '../models/cover_art.dart';
import 'artwork_sources.dart';

const Duration _timeout = Duration(seconds: 15);

@JS('fetch')
external JSPromise<_Response> _fetch(String url, JSObject init);

extension type _Response._(JSObject _) implements JSObject {
  external bool get ok;
  external JSObject get headers;
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

/// Default `ArtworkFetcher` in the browser: fetches an `http(s)://` URL
/// with CORS, without credentials, or a `blob:` one of the page, and
/// returns the image with the MIME type the server gives; `null` for a URL
/// the page cannot read (no CORS, a network error, an error status), for a
/// `file://` URL (no file system), and past 20 MB. An `asset://` URL is
/// read from the app's bundle. [caFile] has no meaning there: the browser
/// verifies certificates.
@internal
Future<CoverArt?> downloadArtwork(Uri uri, [String caFile = '']) async {
  if (uri.scheme == 'asset') return readArtworkAsset(uri);
  if (uri.scheme != 'http' && uri.scheme != 'https' && uri.scheme != 'blob') {
    return null;
  }
  try {
    final init = JSObject()
      ..['mode'] = 'cors'.toJS
      ..['credentials'] = 'omit'.toJS;
    final response = await _fetch(
      uri.toString(),
      init,
    ).toDart.timeout(_timeout);
    if (!response.ok) return null;
    final length = int.tryParse(_header(response, 'content-length') ?? '');
    if (length != null && length > maxArtworkBytes) return null;
    final buffer = await response.arrayBuffer().toDart.timeout(_timeout);
    final bytes = buffer.toDart.asUint8List();
    if (bytes.isEmpty || bytes.length > maxArtworkBytes) return null;
    final type = _header(response, 'content-type') ?? '';
    return CoverArt(bytes: bytes, mimeType: type.split(';').first.trim());
  } catch (_) {
    return null;
  }
}

String? _header(_Response response, String name) {
  final value = response.headers.callMethod<JSString?>('get'.toJS, name.toJS);
  return value?.toDart;
}
