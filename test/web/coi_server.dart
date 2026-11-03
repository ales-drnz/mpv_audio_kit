// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Serves a directory on loopback with COOP and COEP on every response, as
// a host of a cross-origin isolated app must, for dart2js_smoke.sh.
//
//   dart run test/web/coi_server.dart <directory>
//
// Prints `MAK_COI=<base URL>` once it listens, then serves until killed.

import 'dart:io';

const _types = {
  'html': 'text/html',
  'js': 'text/javascript',
  'mjs': 'text/javascript',
  'wasm': 'application/wasm',
  'json': 'application/json',
  'wav': 'audio/wav',
  'flac': 'audio/flac',
};

Future<void> main(List<String> args) async {
  final root = Directory(args.single).absolute.path;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  stdout.writeln('MAK_COI=http://127.0.0.1:${server.port}/');
  await for (final request in server) {
    final response = request.response
      ..headers.set('Cross-Origin-Opener-Policy', 'same-origin')
      ..headers.set('Cross-Origin-Embedder-Policy', 'require-corp')
      ..headers.set('Cross-Origin-Resource-Policy', 'same-origin');
    var path = Uri.decodeComponent(request.uri.path);
    if (path.endsWith('/')) path += 'index.html';
    final file = File('$root$path');
    if (path.contains('..') || !file.existsSync()) {
      response.statusCode = 404;
    } else {
      final ext = path.substring(path.lastIndexOf('.') + 1);
      response.headers.contentType = ContentType.parse(
        _types[ext] ?? 'application/octet-stream',
      );
      await response.addStream(file.openRead());
    }
    await response.close();
  }
}
