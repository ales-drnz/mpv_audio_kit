// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The FFmpeg of libmpv-r18. Up to r17 the build left out the spdif muxer,
// so a passthrough of AC3 never started (F258), and the httpproxy
// protocol, so HTTPS through a proxy failed with "Protocol not found"
// (F177). Its filters accepted values that read out of their buffers
// (F195), and its SMB protocol waited out the network timeout before a
// stop could land (F83).
//
// The last two are FFmpeg patches: a libmpv built against a system FFmpeg
// does not have them, and their groups skip there. The spdif muxer and the
// httpproxy protocol come with a system FFmpeg.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/long_wav.dart';
import '../_helpers/setter_test_helpers.dart';

/// A [libmpvReleaseGroup] of r18 that also needs the FFmpeg patch that
/// logs [message]: skipped on a libmpv without it, which is a build
/// against a system FFmpeg, and failed on CI, whose libmpv is a release.
void _ffmpegPatchGroup(
  String message,
  String description,
  void Function() body,
) {
  if (needsLibmpvRelease(18) != null) {
    libmpvReleaseGroup(18, description, body);
    return;
  }
  final lib = resolveLibmpv();
  String? reason;
  if (lib != null && !libmpvNamesProperty(lib, message)) {
    reason =
        'this libmpv has no FFmpeg patch of libmpv-scripts (a build '
        'against a system FFmpeg)';
    if (Platform.environment['CI'] == 'true') {
      test(description, () => fail(reason!));
      return;
    }
  }
  group(description, body, skip: reason);
}

/// A CONNECT proxy that sends every tunnel to [targetPort] on loopback,
/// whatever host it names, and logs the request lines.
Future<(ServerSocket, List<String>)> _proxy(int targetPort) async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final requests = <String>[];
  server.listen((client) {
    final head = <int>[];
    Socket? upstream;
    // Lives as long as the tunnel: either side closing ends it.
    // ignore: cancel_subscriptions
    late StreamSubscription<List<int>> sub;
    sub = client.listen(
      (data) async {
        if (upstream != null) {
          upstream!.add(data);
          return;
        }
        head.addAll(data);
        final text = latin1.decode(head);
        final end = text.indexOf('\r\n\r\n');
        if (end < 0) return;
        requests.add(text.substring(0, text.indexOf('\r\n')));
        sub.pause();
        final up = await Socket.connect(
          InternetAddress.loopbackIPv4,
          targetPort,
        );
        up.listen(client.add, onDone: client.destroy, onError: (_) {});
        client.add(
          latin1.encode('HTTP/1.1 200 Connection established\r\n\r\n'),
        );
        if (head.length > end + 4) up.add(head.sublist(end + 4));
        upstream = up;
        sub.resume();
      },
      onDone: () => upstream?.destroy(),
      onError: (_) {},
    );
  });
  return (server, requests);
}

void main() {
  final ac3 =
      '${Directory.current.path}/test/fixtures/codec/ac3_48000_stereo.ac3';

  runtimeSuite(fixturePath: ac3, () {
    libmpvReleaseGroup(18, 'The FFmpeg components', () {
      late Player player;

      setUp(() async {
        player = await buildPlayer(configuration: const PlayerConfiguration());
      });
      tearDown(() => player.dispose());

      // F258: r17 loaded the file and never played a sample.
      test('AC3 passthrough plays', () async {
        await player.setAudioSpdif({Spdif.ac3});
        await player.open(Media(ac3), play: true);
        await waitUntil(
          () => player.state.position > const Duration(milliseconds: 300),
          reason: 'the passthrough never started',
        );
        expect(
          await player.getRawProperty('audio-out-params/format'),
          contains('spdif'),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));

      // F177: r17 failed with "Protocol not found" and the proxy saw nothing.
      test('HTTPS goes through an HTTP proxy', () async {
        final tls = '${Directory.current.path}/test/fixtures/tls';
        final https = await HttpServer.bindSecure(
          InternetAddress.loopbackIPv4,
          0,
          SecurityContext()
            ..useCertificateChain('$tls/self_signed_cert.pem')
            ..usePrivateKey('$tls/self_signed_key.pem'),
        );
        addTearDown(() => https.close(force: true));
        final wav = longWav(1);
        https.listen((req) {
          req.response
            ..headers.contentType = ContentType('audio', 'wav')
            ..contentLength = wav.length
            ..add(wav);
          req.response.close();
        });
        final (proxy, requests) = await _proxy(https.port);
        addTearDown(proxy.close);
        await player.setTlsVerify(false);
        await player.setHttpProxy('http://127.0.0.1:${proxy.port}');
        final loaded = player.stream.seekCompleted.first.timeout(
          const Duration(seconds: 10),
        );
        // A name only the proxy can reach: a direct connection fails.
        await player.open(
          const Media('https://mak-proxy-test.invalid/a.wav'),
          play: false,
        );
        await loaded;
        expect(requests, isNotEmpty);
        expect(
          requests.first,
          startsWith('CONNECT mak-proxy-test.invalid:443'),
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    // F195: the patch refuses chorus voices whose modulation leaves the
    // delay line, with this message, where upstream reads out of it.
    _ffmpegPatchGroup(
      'Invalid delay, decay, speed or depth for voice %d.\n',
      'The FFmpeg filter bounds',
      () {
        test('a chorus voice out of its delay line is refused', () async {
          final player = await buildPlayer(
            configuration: const PlayerConfiguration(),
          );
          addTearDown(player.dispose);
          final refused = player.stream.log
              .firstWhere((l) => l.text.contains('Invalid delay, decay'))
              .timeout(const Duration(seconds: 10));
          // A raw stage, which the player passes through unchecked.
          await player.setAudioEffects(const [
            RawAudioEffect('lavfi-chorus=0.5:0.9:40:0.4:0.25:-2'),
          ]);
          await player.open(Media(defaultFixturePath()), play: true);
          await refused;
          // The core answers: the stage failed, not the process.
          expect(await player.getRawProperty('mpv-version'), isNotNull);
        }, timeout: const Timeout(Duration(seconds: 30)));
      },
    );

    // F83: a server that stops answering (a sleeping NAS) held a stop for
    // the whole network timeout, here 60 s.
    _ffmpegPatchGroup(
      'SMB2 connect timed out\n',
      'The FFmpeg SMB protocol',
      () {
        test('a stop lands at once while the server does not answer', () async {
          final silent = await ServerSocket.bind(
            InternetAddress.loopbackIPv4,
            0,
          );
          final held = <Socket>[];
          silent.listen(held.add);
          addTearDown(() async {
            for (final s in held) {
              s.destroy();
            }
            await silent.close();
          });
          final player = await buildPlayer();
          await player.setNetworkTimeout(const Duration(seconds: 60));
          await player.open(
            Media('smb2://127.0.0.1:${silent.port}/share/a.flac'),
            play: true,
          );
          await waitUntil(
            () => held.isNotEmpty,
            reason: 'mpv never connected to the server',
          );
          await Future<void>.delayed(const Duration(seconds: 1));
          final sw = Stopwatch()..start();
          final ended = player.stream.endFile.first.timeout(
            const Duration(seconds: 10),
          );
          await player.stop();
          await ended;
          final stopped = sw.elapsed;
          sw.reset();
          await player.dispose().timeout(const Duration(seconds: 10));
          final disposed = sw.elapsed;
          expect(stopped, lessThan(const Duration(seconds: 1)));
          expect(disposed, lessThan(const Duration(seconds: 2)));
        }, timeout: const Timeout(Duration(seconds: 40)));
      },
    );
  });
}
