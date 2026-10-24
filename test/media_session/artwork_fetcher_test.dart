// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
//
// `downloadArtwork` against a loopback HTTP server and local files: the
// media session hands the native side the image, never the URL.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/media_session/artwork_fetcher.dart';

void main() {
  late HttpServer server;
  late Uri base;
  // The paths of the plain server's requests, in arrival order.
  final served = <String>[];

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = Uri.parse('http://127.0.0.1:${server.port}');
    server.listen((request) {
      served.add(request.uri.toString());
      final response = request.response;
      if (request.uri.path == '/cover') {
        response.headers.contentType = ContentType('image', 'png');
        response.add(const [1, 2, 3, 4]);
      } else {
        response.statusCode = HttpStatus.notFound;
      }
      response.close();
    });
  });

  tearDownAll(() => server.close(force: true));

  test('returns the bytes and MIME type of a served image', () async {
    final cover = await downloadArtwork(base.resolve('/cover?t=tok'));
    expect(cover, isNotNull);
    expect(cover!.bytes, [1, 2, 3, 4]);
    expect(cover.mimeType, 'image/png');
  });

  test('returns null on an HTTP error', () async {
    expect(await downloadArtwork(base.resolve('/missing')), isNull);
  });

  test('returns null when the host is unreachable', () async {
    final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close();
    expect(await downloadArtwork(Uri.parse('http://127.0.0.1:$port/')), isNull);
  });

  group('a file:// cover', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('artwork_file'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('is read, with the MIME type of its extension', () async {
      final png = File('${dir.path}/Città.PNG')..writeAsBytesSync([1, 2, 3]);
      final cover = await downloadArtwork(png.uri);
      expect(cover?.bytes, [1, 2, 3]);
      expect(cover?.mimeType, 'image/png');

      final jpeg = File('${dir.path}/cover.jpeg')..writeAsBytesSync([4]);
      expect((await downloadArtwork(jpeg.uri))?.mimeType, 'image/jpeg');

      final unknown = File('${dir.path}/cover')..writeAsBytesSync([5]);
      final art = await downloadArtwork(unknown.uri);
      expect(art?.bytes, [5]);
      expect(art?.mimeType, '');
    });

    test('returns null when it is missing or empty', () async {
      expect(await downloadArtwork(Uri.file('${dir.path}/none.jpg')), isNull);
      final empty = File('${dir.path}/empty.jpg')..createSync();
      expect(await downloadArtwork(empty.uri), isNull);
    });

    test('returns null over 20 MB', () async {
      // Sparse where the file system allows it: nothing is written.
      final big = File('${dir.path}/big.jpg');
      big.openSync(mode: FileMode.write)
        ..truncateSync(20 * 1024 * 1024 + 1)
        ..closeSync();
      expect(await downloadArtwork(big.uri), isNull);

      final limit = File('${dir.path}/limit.jpg');
      limit.openSync(mode: FileMode.write)
        ..truncateSync(20 * 1024 * 1024)
        ..closeSync();
      expect(
        (await downloadArtwork(limit.uri))?.bytes.length,
        20 * 1024 * 1024,
      );
    });
  });

  // A CA of its own and a localhost certificate it signs, made for the run.
  // The certificate follows Apple's rules for a TLS server (one year,
  // serverAuth, the host in the SAN), which the system check on macOS and
  // iOS applies to every chain, a trusted extra CA included.
  group('over HTTPS with a certificate of a private CA', () {
    late Directory dir;
    late String caPath;
    late HttpServer secure;
    late Uri cover;

    setUpAll(() async {
      dir = Directory.systemTemp.createTempSync('artwork_tls');
      caPath = await _makeCertificates(dir);
      final context = SecurityContext()
        ..useCertificateChain('${dir.path}/chain.pem')
        ..usePrivateKey('${dir.path}/leaf.key');
      secure = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        context,
      );
      cover = Uri.parse('https://localhost:${secure.port}/cover');
      secure.listen((request) {
        switch (request.uri.path) {
          case '/to-http':
            // A downgrade: the plain HTTP server serves the cover.
            request.response.redirect(base.resolve('/cover'));
          case '/to-https':
            request.response.redirect(cover);
          default:
            request.response
              ..headers.contentType = ContentType('image', 'png')
              ..add(const [9, 8, 7])
              ..close();
        }
      });
    });

    tearDownAll(() async {
      await secure.close(force: true);
      dir.deleteSync(recursive: true);
    });

    test('is refused against the system roots alone', () async {
      expect(await downloadArtwork(cover), isNull);
    });

    test("loads when the player's CA bundle trusts it", () async {
      final art = await downloadArtwork(cover, caPath);
      expect(art?.bytes, [9, 8, 7]);
    });

    test('a redirect from https to plain http is refused', () async {
      final art = await downloadArtwork(cover.resolve('/to-http'), caPath);
      expect(art, isNull);
    });

    test('a redirect that stays on https is followed', () async {
      final art = await downloadArtwork(cover.resolve('/to-https'), caPath);
      expect(art?.bytes, [9, 8, 7]);
    });

    // Against this server the system roots refuse too, so the case
    // proves nothing on its own: the one below does.
    test('is refused when the CA bundle cannot be read', () async {
      expect(await downloadArtwork(cover, '/nonexistent/ca.pem'), isNull);
    });
  });

  // F208: an unreadable CA bundle fails closed. A fetcher that ignored it
  // and fell back to the system roots would fetch a plain http cover, which
  // needs no CA at all.
  test('an unreadable CA bundle refuses even a plain http cover', () async {
    const path = '/cover?ca=unreadable';
    expect(
      await downloadArtwork(base.resolve(path), '/nonexistent/ca.pem'),
      isNull,
    );
    expect(served, isNot(contains(path)), reason: 'nothing is requested');
  });
}

/// Writes a CA (ca.pem) and a localhost certificate it signs (chain.pem,
/// with leaf.key) into [dir] with openssl, and returns the CA's path.
/// Subjects and extensions live in config files, which OpenSSL and the
/// LibreSSL of macOS read alike.
Future<String> _makeCertificates(Directory dir) async {
  File('${dir.path}/ca.cnf').writeAsStringSync('''
[req]
prompt = no
distinguished_name = dn
x509_extensions = ext
[dn]
CN = mpv_audio_kit test CA
[ext]
basicConstraints = critical, CA:TRUE
keyUsage = critical, keyCertSign, cRLSign
subjectKeyIdentifier = hash
''');
  File('${dir.path}/leaf.cnf').writeAsStringSync('''
[req]
prompt = no
distinguished_name = dn
[dn]
CN = localhost
[ext]
basicConstraints = critical, CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:localhost, IP:127.0.0.1
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid
''');
  Future<void> openssl(List<String> args) async {
    final result = await Process.run(
      'openssl',
      args,
      workingDirectory: dir.path,
    );
    if (result.exitCode != 0) {
      throw StateError('openssl ${args.join(' ')}: ${result.stderr}');
    }
  }

  await openssl([
    'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-sha256', //
    '-days', '365', '-config', 'ca.cnf', //
    '-keyout', 'ca.key', '-out', 'ca.pem',
  ]);
  await openssl([
    'req', '-new', '-newkey', 'rsa:2048', '-nodes', '-sha256', //
    '-config', 'leaf.cnf', '-keyout', 'leaf.key', '-out', 'leaf.csr',
  ]);
  await openssl([
    'x509', '-req', '-in', 'leaf.csr', '-CA', 'ca.pem', '-CAkey', 'ca.key', //
    '-set_serial', '2', '-sha256', '-days', '365', //
    '-extfile', 'leaf.cnf', '-extensions', 'ext', '-out', 'leaf.pem',
  ]);
  final ca = File('${dir.path}/ca.pem').readAsStringSync();
  final leaf = File('${dir.path}/leaf.pem').readAsStringSync();
  File('${dir.path}/chain.pem').writeAsStringSync('$leaf$ca');
  return '${dir.path}/ca.pem';
}
