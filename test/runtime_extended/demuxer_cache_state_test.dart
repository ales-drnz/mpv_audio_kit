// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = '${Directory.current.path}/test/fixtures/sine_5s.flac';
  runtimeSuite(fixturePath: fx, () {
    test(
      'demuxer-cache-state exposes buffered ranges for a streamed source',
      () async {
        // Serve the fixture over a LOCAL HTTP server (with range support) so mpv
        // treats it as a network source and activates the demuxer cache — the only
        // way seekable-ranges populate (they stay empty for direct local files).
        final bytes = File(fx).readAsBytesSync();
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((req) {
          final range = req.headers.value('range');
          req.response.headers.set('accept-ranges', 'bytes');
          if (range != null && range.startsWith('bytes=')) {
            final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range)!;
            final s = int.parse(m.group(1)!);
            final e = m.group(2)!.isEmpty
                ? bytes.length - 1
                : int.parse(m.group(2)!);
            req.response.statusCode = 206;
            req.response.headers.set(
              'content-range',
              'bytes $s-$e/${bytes.length}',
            );
            req.response.add(bytes.sublist(s, e + 1));
          } else {
            req.response.add(bytes);
          }
          req.response.close();
        });

        final p = await buildPlayer();
        addTearDown(() async {
          await p.dispose();
          await server.close(force: true);
        });
        await p.setCache(const CacheSettings(mode: Cache.yes));
        await openAndWaitForLoad(p, 'http://127.0.0.1:${server.port}/s.flac');

        // Poll the snapshot until the small file is fully cached.
        var st = p.state.demuxerCacheState;
        for (
          var i = 0;
          i < 100 && !(st.seekableRanges.isNotEmpty && st.eofCached);
          i++
        ) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
          st = p.state.demuxerCacheState;
        }

        expect(
          st.seekableRanges,
          isNotEmpty,
          reason: 'a streamed source must expose its buffered ranges',
        );
        expect(st.seekableRanges.first.end, greaterThan(Duration.zero));
        expect(
          st.rawInputRate,
          isNotNull,
          reason:
              'raw download rate is reported while reading over the network',
        );
        expect(st.eofCached, isTrue, reason: 'the small 5s file caches fully');
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );
  });
}
