// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  setUpAll(() => initLibmpvOrSkip());

  group('load-policy config (force-seekable / hls-bitrate)', () {
    test(
      'forceSeekable + hlsBitrate reach the real libmpv from config',
      () async {
        final p = await buildPlayer(
          configuration: const PlayerConfiguration(
            logLevel: LogLevel.off,
            forceSeekable: true,
            hlsBitrate: HlsBitrate.min,
          ),
        );
        addTearDown(p.dispose);
        expect(await p.getRawProperty('force-seekable'), 'yes');
        expect(await p.getRawProperty('hls-bitrate'), 'min');
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test('normalizeDownmix + demuxerCacheDir reach the real libmpv', () async {
      final p = await buildPlayer(
        configuration: const PlayerConfiguration(
          logLevel: LogLevel.off,
          normalizeDownmix: true,
          demuxerCacheDir: '/tmp/mak-cache',
        ),
      );
      addTearDown(p.dispose);
      expect(await p.getRawProperty('audio-normalize-downmix'), 'yes');
      expect(await p.getRawProperty('demuxer-cache-dir'), '/tmp/mak-cache');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('defaults match mpv: force-seekable off, hls-bitrate max', () async {
      final p = await buildPlayer(); // default config
      addTearDown(p.dispose);
      expect(await p.getRawProperty('force-seekable'), 'no');
      expect(await p.getRawProperty('hls-bitrate'), 'max');
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
