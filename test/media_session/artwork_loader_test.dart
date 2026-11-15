// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// `ArtworkLoader`: one artwork load at a time, cancelled by the next one,
// with a limit on its whole time and the last few covers kept. Then the
// cancellation of the dart:io download against a loopback server that
// never ends its response.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_cancel.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_loader.dart';

CoverArt _cover(int byte, [int length = 1]) => CoverArt(
  bytes: Uint8List(length)..fillRange(0, length, byte),
  mimeType: 'image/png',
);

/// A fetcher whose loads stay pending until the test completes them.
class _Fetches {
  final urls = <String>[];
  final tokens = <ArtworkCancel>[];
  final results = <Completer<CoverArt?>>[];

  Future<CoverArt?> call(String url, String caFile, ArtworkCancel cancel) {
    urls.add(url);
    tokens.add(cancel);
    results.add(Completer<CoverArt?>());
    return results.last.future;
  }
}

void main() {
  group('ArtworkLoader', () {
    test('a new load cancels the one in flight', () async {
      final fetches = _Fetches();
      final loader = ArtworkLoader(fetches.call);

      final first = loader.load('https://a/1.jpg', '');
      final second = loader.load('https://a/2.jpg', '');
      expect(fetches.tokens[0].isCancelled, isTrue);
      expect(fetches.tokens[1].isCancelled, isFalse);
      expect(await first, isNull);

      // The fetch that was left may still end with a cover: it is dropped.
      fetches.results[0].complete(_cover(1));
      await pumpEventQueue();
      expect(loader.cached('https://a/1.jpg', ''), isNull);

      final cover = _cover(2);
      fetches.results[1].complete(cover);
      expect(await second, same(cover));
    });

    test('cancel ends the load in flight with null', () async {
      final fetches = _Fetches();
      final loader = ArtworkLoader(fetches.call);
      final load = loader.load('https://a/1.jpg', '');
      loader.cancel();
      expect(fetches.tokens.single.isCancelled, isTrue);
      expect(await load, isNull);
    });

    test('a load ends at the time limit, whatever the fetch does', () async {
      final fetches = _Fetches();
      final loader = ArtworkLoader(
        fetches.call,
        timeLimit: const Duration(milliseconds: 50),
      );
      final watch = Stopwatch()..start();
      expect(await loader.load('https://a/slow.jpg', ''), isNull);
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      expect(fetches.tokens.single.isCancelled, isTrue);
    });

    test('a load that ends in time is not cancelled later', () async {
      final loader = ArtworkLoader(
        (_, _, _) async => _cover(1),
        timeLimit: const Duration(milliseconds: 20),
      );
      final cover = await loader.load('https://a/1.jpg', '');
      await Future<void>.delayed(const Duration(milliseconds: 60));
      expect(loader.cached('https://a/1.jpg', ''), same(cover));
    });

    test(
      'keeps the last covers, the least recently used going first',
      () async {
        final urls = <String>[];
        final loader = ArtworkLoader((url, _, _) async {
          urls.add(url);
          return _cover(urls.length);
        }, capacity: 2);

        final a = await loader.load('a', '');
        await loader.load('b', '');
        // Used again: b is now the older of the two.
        expect(await loader.load('a', ''), same(a));
        await loader.load('c', '');

        expect(urls, ['a', 'b', 'c'], reason: 'the second a loaded nothing');
        expect(loader.cached('a', ''), same(a));
        expect(loader.cached('b', ''), isNull);
        expect(loader.cached('c', ''), isNotNull);
      },
    );

    test('keeps a cover per CA bundle, and no failure', () async {
      var calls = 0;
      final loader = ArtworkLoader(
        (_, caFile, _) async => ++calls == 1 ? null : _cover(calls),
      );
      expect(await loader.load('a', ''), isNull);
      expect(await loader.load('a', ''), isNotNull, reason: 'fetched again');
      expect(calls, 2);
      await loader.load('a', '/ca.pem');
      expect(calls, 3, reason: 'another trust, another load');
    });

    test('keeps no more bytes than its budget, the newest aside', () async {
      final loader = ArtworkLoader(
        (url, _, _) async => _cover(1, url == 'big' ? 100 : 40),
        byteBudget: 100,
      );
      await loader.load('a', '');
      await loader.load('b', '');
      expect(loader.cached('a', ''), isNotNull);
      await loader.load('c', '');
      expect(loader.cached('b', ''), isNull, reason: '120 bytes are too many');
      await loader.load('big', '');
      expect(loader.cached('a', ''), isNull);
      expect(loader.cached('c', ''), isNull);
      expect(loader.cached('big', ''), isNotNull);
    });

    test('a fetch that throws is a failure', () async {
      final loader = ArtworkLoader((_, _, _) => throw StateError('boom'));
      expect(await loader.load('a', ''), isNull);
      final late = ArtworkLoader.uncancellable(
        (_, _) => Future.error(StateError('late')),
      );
      expect(await late.load('a', ''), isNull);
    });
  });

  group('the dart:io download', () {
    // A raw socket server: it sees the client's connection close, which
    // an HttpServer with a response under way does not report.
    late ServerSocket server;
    late Uri base;
    // Completes when the server sees the client of /stall or /drip go.
    late Completer<void> dropped;
    final requested = StreamController<String>.broadcast();

    setUp(() async {
      dropped = Completer<void>();
      server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      server.listen((socket) {
        void gone() {
          if (!dropped.isCompleted) dropped.complete();
          socket.destroy();
        }

        var answered = false;
        socket.listen(
          (data) async {
            if (answered) return;
            answered = true;
            final path = String.fromCharCodes(data).split(' ')[1];
            socket.write(
              'HTTP/1.1 200 OK\r\n'
              'Content-Type: image/png\r\n'
              'Content-Length: 1000000\r\n\r\n',
            );
            // A first piece, then nothing more (/stall), or a byte every
            // 50 ms (/drip): no timeout between two pieces ever fires.
            socket.add(const [1, 2, 3]);
            await socket.flush();
            requested.add(path);
            while (path == '/drip' && !dropped.isCompleted) {
              await Future<void>.delayed(const Duration(milliseconds: 50));
              if (dropped.isCompleted) break;
              socket.add(const [7]);
            }
          },
          onDone: gone,
          onError: (Object _) => gone(),
        );
        unawaited(socket.done.catchError((Object _) {}));
      });
    });

    tearDown(() => server.close());
    tearDownAll(requested.close);

    test('a cancel closes the connection and ends the download', () async {
      final cancel = ArtworkCancel();
      final seen = requested.stream.first;
      final watch = Stopwatch()..start();
      final download = downloadArtwork(base.resolve('/stall'), '', cancel);
      await seen;
      cancel.cancel();

      expect(await download, isNull);
      await dropped.future.timeout(const Duration(seconds: 5));
      expect(
        watch.elapsed,
        lessThan(const Duration(seconds: 5)),
        reason: 'not the 15 s between two pieces',
      );
    });

    test('a download cancelled before it starts requests nothing', () async {
      final cancel = ArtworkCancel()..cancel();
      var requests = 0;
      final sub = requested.stream.listen((_) => requests++);
      expect(await downloadArtwork(base.resolve('/stall'), '', cancel), isNull);
      await sub.cancel();
      expect(requests, 0);
    });

    test('the platform loader ends a body that never ends at its time '
        'limit', () async {
      final loader = ArtworkLoader.platform(
        timeLimit: const Duration(milliseconds: 400),
      );
      final watch = Stopwatch()..start();
      expect(await loader.load(base.resolve('/drip').toString(), ''), isNull);
      expect(watch.elapsed, lessThan(const Duration(seconds: 5)));
      await dropped.future.timeout(const Duration(seconds: 5));
    });
  });
}
