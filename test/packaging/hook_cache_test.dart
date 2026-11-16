// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The build hook's shared cache: a pinned download against a loopback
// server (right, wrong, cut and refused bodies), the pruning of earlier
// releases, and the unpacked copy of an Apple zip, checked on every build.

@TestOn('vm')
library;

import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:mpv_audio_kit/src/internals/hook_download.dart';
import 'package:test/test.dart';

const _asset = 'libmpv_linux-x86_64.so';
const _release = 'libmpv-r0';

String _hex(List<int> bytes) => sha256.convert(bytes).toString();

/// Every file under [dir], by path relative to it, with `/` between its
/// parts on every host.
List<String> _files(Directory dir) => [
  if (dir.existsSync())
    for (final e in dir.listSync(recursive: true))
      if (e is File) _slashed(e.path.substring(dir.path.length + 1)),
]..sort();

/// [path] with the separators of the host as `/`.
String _slashed(String path) => path.replaceAll(Platform.pathSeparator, '/');

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('mak_hook_cache');
  });

  tearDown(() async {
    await tmp.delete(recursive: true);
  });

  group('fetchPinned', () {
    late HttpServer server;
    late Future<void> Function(HttpResponse) answer;
    var requests = 0;
    final body = List<int>.generate(64 * 1024, (i) => (i * 7) & 0xff);
    final sha = _hex(body);

    setUp(() async {
      requests = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((req) async {
        requests++;
        await answer(req.response);
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    Future<void> ok(HttpResponse r) async {
      r.contentLength = body.length;
      r.add(body);
      await r.close();
    }

    Directory cache() => Directory('${tmp.path}/cache');

    Future<File> fetch({String? expected}) => fetchPinned(
      asset: _asset,
      release: _release,
      url: 'http://127.0.0.1:${server.port}/$_asset',
      sha256Hex: expected ?? sha,
      cacheDir: Uri.directory(cache().path),
      connectTimeout: const Duration(seconds: 2),
      idleTimeout: const Duration(milliseconds: 300),
      backoff: const Duration(milliseconds: 10),
    );

    test('the right hash lands the file under its checksum, '
        'with no partial file, and is reused', () async {
      answer = ok;
      final file = await fetch();
      expect(_slashed(file.path), _slashed('${cache().path}/$sha/$_asset'));
      expect(await file.readAsBytes(), body);
      expect(_files(cache()), ['$sha/$_asset']);
      await fetch();
      expect(requests, 1);
    });

    test('a cached file that no longer matches is downloaded again', () async {
      answer = ok;
      final file = await fetch();
      final bytes = await file.readAsBytes();
      bytes[100] ^= 0xff;
      await file.writeAsBytes(bytes);
      await fetch();
      expect(requests, 2);
      expect(await file.readAsBytes(), body);
    });

    test('a wrong hash fails, says so and leaves no file', () async {
      answer = ok;
      final wrong = 'f' * 64;
      await expectLater(
        fetch(expected: wrong),
        throwsA(
          isA<ChecksumMismatch>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('SHA-256 mismatch'),
              contains(_asset),
              contains(sha),
            ),
          ),
        ),
      );
      expect(_files(cache()), isEmpty);
    });

    test('a body always cut short fails with the offline way, '
        'and leaves no file', () async {
      answer = (r) async {
        r.contentLength = body.length;
        final socket = await r.detachSocket();
        socket.add(body.sublist(0, 1000));
        await socket.flush();
        socket.destroy();
      };
      await expectLater(
        fetch(),
        throwsA(
          isA<DownloadFailed>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains(_asset),
              contains(_release),
              contains('without network'),
              contains('libmpv user define'),
            ),
          ),
        ),
      );
      expect(requests, 3);
      expect(_files(cache()), isEmpty);
    });

    test('a body cut short with no length fails on its hash', () async {
      answer = (r) async {
        final socket = await r.detachSocket(writeHeaders: false);
        socket.write('HTTP/1.1 200 OK\r\nConnection: close\r\n\r\n');
        socket.add(body.sublist(0, 1000));
        await socket.flush();
        await socket.close();
      };
      await expectLater(fetch(), throwsA(isA<ChecksumMismatch>()));
      expect(_files(cache()), isEmpty);
    });

    test('a 404 fails at once and leaves no file', () async {
      answer = (r) async {
        r.statusCode = HttpStatus.notFound;
        await r.close();
      };
      await expectLater(
        fetch(),
        throwsA(
          isA<DownloadRefused>().having(
            (e) => e.statusCode,
            'status',
            HttpStatus.notFound,
          ),
        ),
      );
      expect(requests, 1);
      expect(_files(cache()), isEmpty);
    });
  });

  test('pruneCache drops earlier releases and nothing else', () async {
    final cache = Directory('${tmp.path}/cache');
    final pinnedA = 'a' * 64;
    final pinnedB = 'b' * 64;
    final old = 'c' * 64;
    for (final path in [
      '$pinnedA/$_asset',
      '$pinnedA/$_asset.1234.part', // a build downloading right now
      '$pinnedB/unzipped/libmpv.xcframework/Info.plist',
      '$old/$_asset',
      '$old/unzipped/libmpv.xcframework/Info.plist',
      '6b4ebf10e7/libmpv_audio_kit.so', // not one of the hook's
      '${'d' * 64}.txt',
    ]) {
      File('${cache.path}/$path')
        ..createSync(recursive: true)
        ..writeAsStringSync(path);
    }
    await pruneCache(Uri.directory(cache.path), [pinnedA, pinnedB]);
    expect(_files(cache), [
      '6b4ebf10e7/libmpv_audio_kit.so',
      '$pinnedA/$_asset',
      '$pinnedA/$_asset.1234.part',
      '$pinnedB/unzipped/libmpv.xcframework/Info.plist',
      '${'d' * 64}.txt',
    ]);
    await pruneCache(Uri.directory('${tmp.path}/none'), [pinnedA]);
  });

  // The hook unpacks an xcframework only for an iOS or macOS target, which
  // only a macOS host builds (Xcode, and lipo right after): never on
  // Windows, whose links and short paths this group does not model. Linux
  // keeps the coverage of the cache logic.
  group('unpackedBinary', testOn: 'mac-os || linux', () {
    const slice = 'libmpv.xcframework/macos-arm64_x86_64/libmpv.framework';
    const binary = '$slice/libmpv';
    final content = utf8.encode('the libmpv binary');
    var extractions = 0;
    late File zip;
    late Directory dir;

    // What unzip leaves from a macOS xcframework: the binary under
    // Versions/A and links to it.
    Future<void> extract(File zip, Directory into) async {
      extractions++;
      final versions = Directory('${into.path}/$slice/Versions/A')
        ..createSync(recursive: true);
      File('${versions.path}/libmpv').writeAsBytesSync(content);
      File('${into.path}/libmpv.xcframework/Info.plist').writeAsStringSync('');
      Link('${into.path}/$slice/Versions/Current').createSync('A');
      Link('${into.path}/$slice/libmpv').createSync('Versions/Current/libmpv');
    }

    Future<String> unpack({String? zipSha256 = 'zipsha'}) => unpackedBinary(
      zip,
      dir,
      binary,
      zipSha256: zipSha256,
      extract: extract,
    );

    setUp(() {
      extractions = 0;
      zip = File('${tmp.path}/libmpv_macos.xcframework.zip')
        ..writeAsStringSync('zip');
      dir = Directory('${tmp.path}/unzipped');
    });

    test('unpacks once, follows the links and reuses the copy', () async {
      final path = await unpack();
      expect(_slashed(path), endsWith('$slice/Versions/A/libmpv'));
      expect(await File(path).readAsBytes(), content);
      expect(File('${dir.path}/$unpackedMarker').existsSync(), isTrue);
      await unpack();
      expect(extractions, 1);
      expect(
        tmp.listSync().map((e) => e.uri.pathSegments.lastWhere((s) => s != '')),
        unorderedEquals(['libmpv_macos.xcframework.zip', 'unzipped']),
        reason: 'no staging copy is left beside it',
      );
    });

    test('a corrupted binary in the copy is unpacked again', () async {
      final path = await unpack();
      File(path).writeAsStringSync('corrupt');
      final again = await unpack();
      expect(extractions, 2);
      expect(await File(again).readAsBytes(), content);
    });

    test('a removed binary in the copy is unpacked again', () async {
      final path = await unpack();
      File(path).deleteSync();
      expect(await File(await unpack()).readAsBytes(), content);
      expect(extractions, 2);
    });

    test('a copy with no marker, as the hook left before, '
        'is unpacked again', () async {
      await unpack();
      File('${dir.path}/$unpackedMarker').deleteSync();
      await unpack();
      expect(extractions, 2);
    });

    test('a copy of another zip is unpacked again', () async {
      await unpack();
      await unpack(zipSha256: 'otherzip');
      expect(extractions, 2);
      await unpack(zipSha256: 'otherzip');
      expect(extractions, 2);
    });

    test('a zip without the binary fails', () async {
      await expectLater(
        unpackedBinary(
          zip,
          dir,
          'libmpv.xcframework/ios-arm64/libmpv.framework/libmpv',
          extract: extract,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
