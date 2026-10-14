// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook's libmpv download against a loopback server: a stalled or
// cut body and a 5xx are tried again, a 404 is not.

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';

import '../../hook/download.dart';

void main() {
  late HttpServer server;
  late Directory tmp;
  late List<Future<void> Function(HttpResponse)> answers;
  var requests = 0;
  final body = List<int>.generate(64 * 1024, (i) => i & 0xff);

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mak_hook_download');
    requests = 0;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final answer =
          answers[requests < answers.length ? requests : answers.length - 1];
      requests++;
      await answer(req.response);
    });
  });

  tearDown(() async {
    await server.close(force: true);
    await tmp.delete(recursive: true);
  });

  String url() => 'http://127.0.0.1:${server.port}/libmpv.so';

  Future<void> ok(HttpResponse r) async {
    r.contentLength = body.length;
    r.add(body);
    await r.close();
  }

  Future<void> status(HttpResponse r, int code) async {
    r.statusCode = code;
    await r.close();
  }

  Future<void> fetch(File target) => download(
    url(),
    target,
    connectTimeout: const Duration(seconds: 2),
    idleTimeout: const Duration(milliseconds: 300),
    backoff: const Duration(milliseconds: 10),
  );

  test('a 404 fails at once and points at the user define', () async {
    answers = [(r) => status(r, 404)];
    final target = File('${tmp.path}/out');
    await expectLater(
      fetch(target),
      throwsA(
        isA<DownloadRefused>().having(
          (e) => e.toString(),
          'message',
          contains('libmpv user define'),
        ),
      ),
    );
    expect(requests, 1);
  });

  test('a 503 is tried again', () async {
    answers = [(r) => status(r, 503), ok];
    final target = File('${tmp.path}/out');
    await fetch(target);
    expect(requests, 2);
    expect(await target.readAsBytes(), body);
  });

  test('a body that stalls is dropped after the idle timeout and tried '
      'again', () async {
    final stalled = Completer<void>();
    answers = [
      (r) async {
        r.contentLength = body.length;
        r.add(body.sublist(0, 1000));
        await r.flush();
        await stalled.future; // never sends the rest
      },
      ok,
    ];
    final target = File('${tmp.path}/out');
    await fetch(target).timeout(const Duration(seconds: 10));
    expect(requests, 2);
    expect(await target.readAsBytes(), body);
    stalled.complete();
  });

  test('a body cut short is tried again', () async {
    answers = [
      (r) async {
        r.contentLength = body.length;
        final socket = await r.detachSocket();
        socket.add(body.sublist(0, 1000));
        await socket.flush();
        socket.destroy();
      },
      ok,
    ];
    final target = File('${tmp.path}/out');
    await fetch(target);
    expect(requests, 2);
    expect(await target.readAsBytes(), body);
  });

  test('it gives up after the attempts', () async {
    answers = [(r) => status(r, 502)];
    await expectLater(
      fetch(File('${tmp.path}/out')),
      throwsA(isA<DownloadRefused>()),
    );
    expect(requests, 3);
  });
}
