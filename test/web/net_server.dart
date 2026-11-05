// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The network cases of the browser tests, served on loopback with CORS (the
// page is on another port, so another origin). A browser test cannot start a
// server: with_net_server.sh runs this one beside `flutter test` and hands
// its URL to the tests as MAK_WEB_NET.
//
//   GET /cut/<fixture>  the fixture under test/fixtures, its whole length
//                       announced and the body cut at half, after a pause
//                       for the page to read it; a resume (a
//                       Range from past the start) gets 503 with an empty
//                       body: a file cut short whose resume is refused.
//   GET /file/<fixture> the fixture in full, with Range support.
//   GET /nocors/<fixture> the same without CORS: a page of another origin
//                       cannot read it.
//   GET /hls/a.m3u8     an HLS playlist of eight segments, s0.aac to
//                       s7.aac, each codec/aac_adts_44100.aac; s6.aac
//                       answers 404: a segment that never opens.
//
// Prints `MAK_WEB_NET=<base URL>` once it listens, then serves until killed.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// How long the bytes of a cut body stand before the connection breaks.
const _cutDelay = Duration(seconds: 2);

Future<void> main() async {
  final fixtures = Directory.fromUri(Platform.script.resolve('../fixtures/'));
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  stdout.writeln('MAK_WEB_NET=http://127.0.0.1:${server.port}');
  await stdout.flush();
  await for (final client in server) {
    unawaited(_serve(client, fixtures).catchError((Object _) {}));
  }
}

Future<void> _serve(Socket client, Directory fixtures) async {
  final head = BytesBuilder(copy: false);
  final ended = Completer<String>();
  final sub = client.listen(
    (data) {
      head.add(data);
      final text = latin1.decode(head.toBytes(), allowInvalid: true);
      final end = text.indexOf('\r\n\r\n');
      if (end >= 0 && !ended.isCompleted) {
        ended.complete(text.substring(0, end));
      }
    },
    onError: (Object _) {},
    onDone: () {
      if (!ended.isCompleted) ended.complete('');
    },
  );
  try {
    final request = await ended.future;
    final lines = request.split('\r\n');
    final target = lines.first.split(' ');
    if (target.length < 2) return;
    final range = RegExp(
      r'^range:\s*bytes=(\d+)-',
      caseSensitive: false,
      multiLine: true,
    ).firstMatch(request);
    final from = range == null ? 0 : int.parse(range.group(1)!);
    final path = Uri.parse(target[1]).pathSegments;
    final method = target[0];
    if (method == 'OPTIONS') {
      await _head(client, 204, {
        'Access-Control-Allow-Methods': 'GET',
        'Access-Control-Allow-Headers': '*',
        'Content-Length': '0',
      });
      return;
    }
    if (path.length == 2 && path[0] == 'hls') {
      await _hls(client, fixtures, path[1]);
      return;
    }
    final file = path.length == 2 ? File('${fixtures.path}${path[1]}') : null;
    if (file == null || !file.existsSync() || path[1].contains('..')) {
      await _head(client, 404, {'Content-Length': '0'});
      return;
    }
    final bytes = file.readAsBytesSync();
    final cut = path[0] == 'cut';
    if (cut && from > 0) {
      await _head(client, 503, {'Content-Length': '0'});
      return;
    }
    if (!const ['cut', 'file', 'nocors'].contains(path[0])) {
      await _head(client, 404, {'Content-Length': '0'});
      return;
    }
    final start = from.clamp(0, bytes.length);
    await _head(client, range == null ? 200 : 206, cors: path[0] != 'nocors', {
      'Content-Type': 'application/octet-stream',
      'Accept-Ranges': 'bytes',
      'Content-Length': '${bytes.length - start}',
      if (range != null)
        'Content-Range': 'bytes $start-${bytes.length - 1}/${bytes.length}',
    });
    if (method == 'HEAD') return;
    final end = cut ? bytes.length ~/ 2 : bytes.length;
    client.add(bytes.sublist(start, end));
    await client.flush();
    // Chrome drops what the page has not read yet of a body that breaks, and
    // a page on a slow machine then gets no byte at all: the open fails
    // instead of the file ending short. The break waits for the read.
    if (cut) await Future<void>.delayed(_cutDelay);
  } finally {
    await sub.cancel();
    client.destroy();
  }
}

/// The segments of /hls/a.m3u8, and the one that answers 404.
const _hlsSegments = 8;
const _hlsMissing = 6;

Future<void> _hls(Socket client, Directory fixtures, String name) async {
  final List<int> body;
  if (name == 'a.m3u8') {
    final playlist = StringBuffer(
      '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:2\n'
      '#EXT-X-MEDIA-SEQUENCE:0\n',
    );
    for (var i = 0; i < _hlsSegments; i++) {
      playlist.write('#EXTINF:1.044900,\ns$i.aac\n');
    }
    playlist.write('#EXT-X-ENDLIST\n');
    body = utf8.encode(playlist.toString());
  } else if (RegExp(r'^s(\d)\.aac$').firstMatch(name) case final m?
      when int.parse(m.group(1)!) < _hlsSegments &&
          int.parse(m.group(1)!) != _hlsMissing) {
    body = File('${fixtures.path}codec/aac_adts_44100.aac').readAsBytesSync();
  } else {
    await _head(client, 404, {'Content-Length': '0'});
    return;
  }
  await _head(client, 200, {
    'Content-Type': 'application/octet-stream',
    'Content-Length': '${body.length}',
  });
  client.add(body);
  await client.flush();
}

Future<void> _head(
  Socket client,
  int status,
  Map<String, String> headers, {
  bool cors = true,
}) {
  final reason = switch (status) {
    200 => 'OK',
    204 => 'No Content',
    206 => 'Partial Content',
    404 => 'Not Found',
    _ => 'Service Unavailable',
  };
  final out = StringBuffer('HTTP/1.1 $status $reason\r\n')
    ..write(cors ? 'Access-Control-Allow-Origin: *\r\n' : '')
    ..write('Connection: close\r\n');
  headers.forEach((k, v) => out.write('$k: $v\r\n'));
  out.write('\r\n');
  client.add(latin1.encode(out.toString()));
  return client.flush();
}
