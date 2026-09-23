// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/setter_test_helpers.dart';

// End-to-end coverage for the opt-in [Media.httpChunkSize]: a throttling CDN
// rate-limits a single open-ended `Range: bytes=N-`
// request, so after a seek the buffer drains and playback freezes. Setting
// `httpChunkSize` makes ffmpeg issue bounded requests instead, which the CDN
// serves at full speed — the freeze is gone.
//
// The local server throttles open-ended requests (serves a window, then hangs)
// and serves bounded requests in full at full speed — no real network.

Uint8List _buildSineWav({required int seconds, int freq = 440}) {
  const sampleRate = 44100;
  const channels = 1;
  const bytesPerSample = 2;
  const byteRate = sampleRate * channels * bytesPerSample;
  final numSamples = sampleRate * seconds;
  final dataSize = numSamples * channels * bytesPerSample;

  final out = BytesBuilder();
  void str(String s) => out.add(s.codeUnits);
  void u32(int v) =>
      out.add([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >> 24) & 0xff]);
  void u16(int v) => out.add([v & 0xff, (v >> 8) & 0xff]);

  str('RIFF');
  u32(36 + dataSize);
  str('WAVE');
  str('fmt ');
  u32(16);
  u16(1);
  u16(channels);
  u32(sampleRate);
  u32(byteRate);
  u16(channels * bytesPerSample);
  u16(8 * bytesPerSample);
  str('data');
  u32(dataSize);

  final pcm = Uint8List(dataSize);
  final bd = ByteData.view(pcm.buffer);
  for (var i = 0; i < numSamples; i++) {
    final v = (32767 * 0.3 * math.sin(2 * math.pi * freq * i / sampleRate))
        .round();
    bd.setInt16(i * 2, v, Endian.little);
  }
  out.add(pcm);
  return out.toBytes();
}

/// Throttles open-ended `Range: bytes=start-` requests (serves a window then
/// hangs); serves bounded `Range: bytes=start-end` requests in full.
class _ThrottlingServer {
  _ThrottlingServer(this._body);

  final Uint8List _body;
  static const _initialWindow = 6 * 44100 * 2; // ~6 s
  static const _laterWindow = 44100 * 2; // ~1 s
  final List<Socket> _hung = [];
  late final ServerSocket _server;

  int get port => _server.port;
  String url(String name) => 'http://127.0.0.1:$port/$name';

  Future<void> start() async {
    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server.listen(_handle);
  }

  Future<void> stop() async {
    for (final s in _hung) {
      s.destroy();
    }
    await _server.close();
  }

  void _handle(Socket socket) {
    final acc = BytesBuilder();
    late StreamSubscription<Uint8List> sub;
    sub = socket.listen(
      (chunk) async {
        acc.add(chunk);
        final bytes = acc.toBytes();
        final headEnd = _indexOf(bytes, const [13, 10, 13, 10]);
        if (headEnd < 0) return;
        await sub.cancel();
        await _respond(socket, String.fromCharCodes(bytes.sublist(0, headEnd)));
      },
      onError: (_) {},
      cancelOnError: true,
    );
  }

  Future<void> _respond(Socket socket, String head) async {
    final total = _body.length;
    final (start, end) = _range(head);

    if (end != null) {
      // Bounded request → full speed.
      final realEnd = end < total ? end : total - 1;
      final header = StringBuffer()
        ..write('HTTP/1.1 206 Partial Content\r\n')
        ..write('Content-Range: bytes $start-$realEnd/$total\r\n')
        ..write('Content-Length: ${realEnd - start + 1}\r\n')
        ..write('Accept-Ranges: bytes\r\n')
        ..write('Content-Type: audio/wav\r\n')
        ..write('Connection: close\r\n\r\n');
      try {
        socket.add(header.toString().codeUnits);
        socket.add(_body.sublist(start, realEnd + 1));
        await socket.flush();
        await socket.close();
      } catch (_) {
        socket.destroy();
      }
      return;
    }

    // Open-ended request → throttle: serve a window then hang.
    final window = start == 0 ? _initialWindow : _laterWindow;
    final toSend = (total - start) < window ? total - start : window;
    final header = StringBuffer()
      ..write('HTTP/1.1 206 Partial Content\r\n')
      ..write('Content-Range: bytes $start-${total - 1}/$total\r\n')
      ..write('Content-Length: ${total - start}\r\n')
      ..write('Accept-Ranges: bytes\r\n')
      ..write('Content-Type: audio/wav\r\n')
      ..write('Connection: close\r\n\r\n');
    try {
      socket.add(header.toString().codeUnits);
      socket.add(_body.sublist(start, start + toSend));
      await socket.flush();
      if (start + toSend >= total) {
        await socket.close();
      } else {
        _hung.add(socket);
      }
    } catch (_) {
      socket.destroy();
    }
  }

  static (int, int?) _range(String head) {
    for (final line in head.split('\r\n')) {
      final lower = line.toLowerCase();
      if (lower.startsWith('range:')) {
        final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(lower);
        if (m != null) {
          final start = int.parse(m.group(1)!);
          final endStr = m.group(2)!;
          return (start, endStr.isEmpty ? null : int.parse(endStr));
        }
      }
    }
    return (0, null);
  }

  static int _indexOf(List<int> haystack, List<int> needle) {
    for (var i = 0; i <= haystack.length - needle.length; i++) {
      var ok = true;
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) {
          ok = false;
          break;
        }
      }
      if (ok) return i;
    }
    return -1;
  }
}

void main() {
  final wav = _buildSineWav(seconds: 20); // ~3.5 MB
  const seekTo = Duration(seconds: 3);
  const mustReach = Duration(seconds: 8);

  late _ThrottlingServer server;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
    server = _ThrottlingServer(wav);
    await server.start();
  });

  tearDownAll(() async {
    await server.stop();
  });

  /// Opens [media], seeks, plays, returns whether playback advanced past
  /// [mustReach] within [budget]. `false` means it froze on the throttle.
  Future<bool> seekAdvances(
    Player player,
    Media media, {
    Duration budget = const Duration(seconds: 30),
  }) async {
    final reached = player.stream.position
        .firstWhere((p) => p >= mustReach)
        .then((_) => true);

    final loaded = player.stream.seekCompleted.first.timeout(
      const Duration(seconds: 10),
    );
    await player.open(media, play: false);
    await loaded;

    await player.seek(seekTo);
    await player.play();

    return reached.timeout(budget, onTimeout: () => false);
  }

  test(
    'without httpChunkSize a throttled stream freezes after a seek',
    () async {
      final player = await buildPlayer();
      try {
        final advanced = await seekAdvances(
          player,
          Media(server.url('plain.wav')),
          budget: const Duration(seconds: 15),
        );
        expect(
          advanced,
          isFalse,
          reason:
              'An open-ended request is throttled, so playback starves '
              'and never reaches $mustReach.',
        );
      } finally {
        await player.stop();
        await player.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 90)),
  );

  test(
    'Media.httpChunkSize keeps a throttled stream flowing after a seek',
    () async {
      final player = await buildPlayer();
      try {
        // Small chunk forces several bounded requests on the test file.
        final advanced = await seekAdvances(
          player,
          Media(server.url('chunked.wav'), httpChunkSize: 256 * 1024),
        );
        expect(
          advanced,
          isTrue,
          reason:
              'Bounded chunk requests are served at full speed, so '
              'playback flows past $mustReach without throttling.',
        );
      } finally {
        await player.stop();
        await player.dispose();
      }
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );

  test('a non-positive httpChunkSize is rejected', () async {
    final player = await buildPlayer();
    try {
      await expectLater(
        player.open(Media(server.url('bad.wav'), httpChunkSize: 0)),
        throwsArgumentError,
      );
    } finally {
      await player.stop();
      await player.dispose();
    }
  });
}
