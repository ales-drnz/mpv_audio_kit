// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// A loopback HTTP/1.1 server for the network runtime tests. It serves
// in-memory files with byte-range support and logs every request, so a
// test can count how many times mpv (or the analysis beside it) opened a
// URL and how much it downloaded. It runs on raw sockets rather than
// `HttpServer` to control what reaches the wire: a body cut after N
// bytes, a chunked body with no length, a throttled body.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// How [RangeHttpServer] answers a request.
enum ServeMode {
  /// `Accept-Ranges: bytes` and a `Content-Length`; a `Range` request is
  /// answered with 206 and its `Content-Range`.
  ranges,

  /// Byte ranges as in [ranges], but the total size is hidden: no
  /// `Content-Length`, the end of the body marked by closing the
  /// connection, a read from the start answered with 200 and a later range
  /// with 206 and a `Content-Range` ending in `/*`.
  rangesUnknownSize,

  /// 200 with a chunked body, no `Content-Length` and no `Accept-Ranges`;
  /// a `Range` header is ignored, as by a server streaming a transcode.
  chunked,
}

/// One request [RangeHttpServer] received.
final class ServedRequest {
  ServedRequest._(this.method, this.path, this.range, this.at);

  /// `GET`, `HEAD`, ...
  final String method;

  /// The request target, e.g. `/track.wav`.
  final String path;

  /// The raw `Range` header, or `null` when the request had none.
  final String? range;

  /// When the request arrived.
  final DateTime at;

  /// The status the server answered with.
  int status = 0;

  /// The first byte of the file the answer started from.
  int start = 0;

  /// Body bytes written to the socket (they may still sit in a kernel
  /// buffer when the client hangs up).
  int bytesSent = 0;

  /// The whole answer was written.
  bool completed = false;

  /// The server cut the body on purpose ([RangeHttpServer.dropAfterBytes]).
  bool dropped = false;

  /// The client went away before the body was complete.
  bool aborted = false;

  @override
  String toString() =>
      '$method $path range=${range ?? '-'} -> $status from $start, '
      '$bytesSent B${completed ? '' : ' (incomplete)'}'
      '${dropped ? ' dropped' : ''}${aborted ? ' aborted' : ''}';
}

/// A loopback server for in-memory files. See the file comment.
final class RangeHttpServer {
  RangeHttpServer._(this._socket, this._files, this.mode);

  final ServerSocket _socket;
  final Map<String, Uint8List> _files;

  /// How every request is answered.
  ServeMode mode;

  /// Body bytes per second for every answer, or `null` for no limit. Read
  /// on each chunk, so a test can lift it while a body is being sent.
  int? bytesPerSecond;

  /// When set, the next GET has its connection closed after this many body
  /// bytes; the GETs after it are served in full.
  int? dropAfterBytes;

  /// After a [dropAfterBytes] cut, answer 503 to every GET that tries to
  /// resume the body from where it was cut, so the client cannot complete
  /// that download; a GET from anywhere else is served.
  bool refuseResume = false;

  /// When set, every request waits for it before it is answered, so a test
  /// can keep mpv's open from completing until it has done something during
  /// the load. The requests are logged as they arrive.
  Future<void>? hold;

  int? _cutAt;

  final List<ServedRequest> _requests = [];
  final Set<Socket> _open = {};

  /// The GET requests for [path], in arrival order.
  List<ServedRequest> gets(String path) =>
      _requests.where((r) => r.method == 'GET' && r.path == path).toList();

  /// The body bytes sent for [path] across all its requests.
  int bytesSent(String path) => _requests
      .where((r) => r.path == path)
      .fold(0, (sum, r) => sum + r.bytesSent);

  /// A readable dump of the log, for failure messages.
  String describe() => _requests.isEmpty
      ? '(no requests)'
      : _requests.map((r) => '  $r').join('\n');

  /// Starts a server for [files], keyed by name (served at `/<name>`).
  static Future<RangeHttpServer> start(
    Map<String, Uint8List> files, {
    ServeMode mode = ServeMode.ranges,
    int? bytesPerSecond,
    int? dropAfterBytes,
  }) async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final server = RangeHttpServer._(socket, files, mode)
      ..bytesPerSecond = bytesPerSecond
      ..dropAfterBytes = dropAfterBytes;
    socket.listen(server._accept);
    return server;
  }

  /// The URL of the file served as [name].
  String url(String name) =>
      'http://${_socket.address.address}:${_socket.port}/$name';

  /// Stops accepting connections and closes the open ones.
  Future<void> close() async {
    await _socket.close();
    for (final s in _open.toList()) {
      s.destroy();
    }
    _open.clear();
  }

  void _accept(Socket client) {
    _open.add(client);
    final head = BytesBuilder(copy: false);
    var handled = false;
    var gone = false;
    final goneSignal = Completer<void>();
    void markGone() {
      gone = true;
      if (!goneSignal.isCompleted) goneSignal.complete();
      _open.remove(client);
    }

    client.listen(
      (data) {
        if (handled) return;
        head.add(data);
        final bytes = head.toBytes();
        final end = _headerEnd(bytes);
        if (end < 0) return;
        handled = true;
        final text = latin1.decode(bytes.sublist(0, end));
        unawaited(
          _answer(client, text, () => gone, goneSignal.future).whenComplete(() {
            _open.remove(client);
            client.destroy();
          }),
        );
      },
      onError: (_) => markGone(),
      onDone: markGone,
      cancelOnError: true,
    );
  }

  static int? _rangeStart(Map<String, String> headers) {
    final m = RegExp(r'^bytes=(\d+)-').firstMatch(headers['range'] ?? '');
    return m == null ? null : int.parse(m.group(1)!);
  }

  static int _headerEnd(Uint8List b) {
    for (var i = 3; i < b.length; i++) {
      if (b[i - 3] == 13 && b[i - 2] == 10 && b[i - 1] == 13 && b[i] == 10) {
        return i + 1;
      }
    }
    return -1;
  }

  Future<void> _answer(
    Socket client,
    String head,
    bool Function() gone,
    Future<void> goneSignal,
  ) async {
    final lines = head.split('\r\n');
    final requestLine = lines.first.split(' ');
    final method = requestLine.isNotEmpty ? requestLine[0] : '';
    final target = requestLine.length > 1 ? requestLine[1] : '/';
    final headers = <String, String>{};
    for (final line in lines.skip(1)) {
      final i = line.indexOf(':');
      if (i > 0) {
        headers[line.substring(0, i).trim().toLowerCase()] = line
            .substring(i + 1)
            .trim();
      }
    }
    final path = Uri.parse(target).path;
    final req = ServedRequest._(method, path, headers['range'], DateTime.now());
    _requests.add(req);
    final gate = hold;
    if (gate != null) await gate;

    final file = _files[path.startsWith('/') ? path.substring(1) : path];
    if (file == null) {
      req.status = 404;
      await _writeHead(client, 404, const {'Content-Length': '0'});
      req.completed = true;
      return;
    }
    if (method == 'GET' && _cutAt != null && _rangeStart(headers) == _cutAt) {
      req.status = 503;
      await _writeHead(client, 503, const {'Content-Length': '0'});
      req.completed = true;
      return;
    }
    final total = file.length;
    final contentType = _contentType(path);

    if (mode == ServeMode.chunked) {
      req.status = 200;
      await _writeHead(client, 200, {
        'Content-Type': contentType,
        'Transfer-Encoding': 'chunked',
      });
      if (method == 'HEAD') {
        req.completed = true;
        return;
      }
      await _sendBody(client, req, file, 0, total, gone, goneSignal, (chunk) {
        final out = BytesBuilder(copy: false)
          ..add(latin1.encode('${chunk.length.toRadixString(16)}\r\n'))
          ..add(chunk)
          ..add(latin1.encode('\r\n'));
        return out.toBytes();
      });
      if (req.completed) {
        client.add(latin1.encode('0\r\n\r\n'));
        await _flush(client);
      }
      return;
    }

    var start = 0;
    var end = total - 1;
    var partial = false;
    final range = headers['range'];
    if (range != null) {
      final m = RegExp(r'^bytes=(\d*)-(\d*)$').firstMatch(range.trim());
      if (m != null) {
        final a = m.group(1)!;
        final b = m.group(2)!;
        if (a.isEmpty && b.isNotEmpty) {
          start = total - int.parse(b);
          if (start < 0) start = 0;
        } else if (a.isNotEmpty) {
          start = int.parse(a);
          if (b.isNotEmpty) end = int.parse(b);
        }
        if (end > total - 1) end = total - 1;
        partial = true;
      }
    }
    req.start = start;
    if (partial && start >= total) {
      req.status = 416;
      await _writeHead(client, 416, {
        'Content-Range': 'bytes */$total',
        'Content-Length': '0',
      });
      req.completed = true;
      return;
    }
    final known = mode == ServeMode.ranges;
    // Without a known size a read from the start is a plain 200: FFmpeg
    // takes the size of a `Content-Range: bytes 0-N/*` as zero.
    if (!known && start == 0) partial = false;
    final status = partial ? 206 : 200;
    req.status = status;
    await _writeHead(client, status, {
      'Content-Type': contentType,
      'Accept-Ranges': 'bytes',
      if (known) 'Content-Length': '${end - start + 1}',
      if (partial) 'Content-Range': 'bytes $start-$end/${known ? total : '*'}',
    });
    if (method == 'HEAD') {
      req.completed = true;
      return;
    }
    await _sendBody(client, req, file, start, end + 1, gone, goneSignal, null);
  }

  Future<void> _sendBody(
    Socket client,
    ServedRequest req,
    Uint8List file,
    int from,
    int to,
    bool Function() gone,
    Future<void> goneSignal,
    Uint8List Function(Uint8List chunk)? frame,
  ) async {
    int? drop;
    if (dropAfterBytes != null && req.method == 'GET') {
      drop = dropAfterBytes;
      dropAfterBytes = null;
    }
    const chunkSize = 16 * 1024;
    var pos = from;
    final clock = Stopwatch()..start();
    var sentSinceClock = 0;
    int? clockRate;
    while (pos < to) {
      if (gone()) {
        req.aborted = true;
        return;
      }
      var n = to - pos < chunkSize ? to - pos : chunkSize;
      if (drop != null && req.bytesSent + n > drop) n = drop - req.bytesSent;
      if (n > 0) {
        final chunk = Uint8List.sublistView(file, pos, pos + n);
        try {
          client.add(frame != null ? frame(chunk) : chunk);
          await client.flush();
        } catch (_) {
          req.aborted = true;
          return;
        }
        pos += n;
        req.bytesSent += n;
        sentSinceClock += n;
      }
      if (drop != null && req.bytesSent >= drop) {
        req.dropped = true;
        if (refuseResume) _cutAt = from + req.bytesSent;
        return;
      }
      if (pos >= to) break;
      final rate = bytesPerSecond;
      if (rate != clockRate) {
        // The rate changed (or was lifted): pace from here.
        clockRate = rate;
        clock.reset();
        sentSinceClock = 0;
      }
      if (rate != null && rate > 0) {
        final dueMs = sentSinceClock * 1000 ~/ rate;
        final waitMs = dueMs - clock.elapsedMilliseconds;
        if (waitMs > 0) {
          await Future.any([
            Future<void>.delayed(Duration(milliseconds: waitMs)),
            goneSignal,
          ]);
        }
      }
    }
    req.completed = true;
  }

  static Future<void> _writeHead(
    Socket client,
    int status,
    Map<String, String> headers,
  ) async {
    final reason = switch (status) {
      200 => 'OK',
      206 => 'Partial Content',
      404 => 'Not Found',
      416 => 'Range Not Satisfiable',
      503 => 'Service Unavailable',
      _ => 'Status',
    };
    final b = StringBuffer('HTTP/1.1 $status $reason\r\n');
    headers.forEach((k, v) => b.write('$k: $v\r\n'));
    b.write('Connection: close\r\n\r\n');
    client.add(latin1.encode(b.toString()));
    await _flush(client);
  }

  static Future<void> _flush(Socket client) async {
    try {
      await client.flush();
    } catch (_) {}
  }

  static String _contentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    return switch (ext) {
      'wav' => 'audio/wav',
      'flac' => 'audio/flac',
      'mka' => 'audio/x-matroska',
      'mp3' => 'audio/mpeg',
      'aac' => 'audio/aac',
      'm3u8' => 'application/vnd.apple.mpegurl',
      _ => 'application/octet-stream',
    };
  }
}
