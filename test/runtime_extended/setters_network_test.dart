// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fixturePath = defaultFixturePath();

  setUpAll(() => initLibmpvOrSkip(fixturePath: fixturePath));

  group('Network / demuxer / buffer setters end-to-end', () {
    late Player player;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fixturePath);
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('networkTimeout / tlsVerify round-trip', () async {
      await player.setNetworkTimeout(const Duration(seconds: 60));
      expect(player.state.networkTimeout, const Duration(seconds: 60));

      await player.setTlsVerify(false);
      expect(player.state.tlsVerify, isFalse);
      await player.setTlsVerify(true);
      expect(player.state.tlsVerify, isTrue);
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('hlsBitrate / cookies / httpProxy round-trip', () async {
      // Pre-subscribe BEFORE the setter: the optimistic emit lands
      // synchronously and a late firstWhere would miss it.
      final hlsMin = player.stream.hlsBitrate
          .firstWhere((v) => v == HlsBitrate.min)
          .timeout(const Duration(seconds: 5));
      await player.setHlsBitrate(HlsBitrate.min);
      await hlsMin;
      expect(player.state.hlsBitrate, HlsBitrate.min);
      expect(await player.getRawProperty('hls-bitrate'), 'min');
      await player.setHlsBitrate(HlsBitrate.max);
      expect(player.state.hlsBitrate, HlsBitrate.max);

      final cookiesOn = player.stream.cookies
          .firstWhere((v) => v)
          .timeout(const Duration(seconds: 5));
      await player.setCookies(true);
      await cookiesOn;
      expect(player.state.cookies, isTrue);
      expect(await player.getRawProperty('cookies'), 'yes');
      await player.setCookies(false);
      expect(player.state.cookies, isFalse);

      const proxy = 'http://127.0.0.1:3128';
      final proxySet = player.stream.httpProxy
          .firstWhere((v) => v == proxy)
          .timeout(const Duration(seconds: 5));
      await player.setHttpProxy(proxy);
      await proxySet;
      expect(player.state.httpProxy, proxy);
      expect(await player.getRawProperty('http-proxy'), proxy);
      await player.setHttpProxy('');
      expect(player.state.httpProxy, '');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test(
      'audioBuffer / audioStreamSilence / audioNullUntimed round-trip',
      () async {
        await player.setAudioBuffer(const Duration(milliseconds: 500));
        expect(player.state.audioBuffer, const Duration(milliseconds: 500));

        await player.setAudioStreamSilence(true);
        expect(player.state.audioStreamSilence, isTrue);
        await player.setAudioStreamSilence(false);
        expect(player.state.audioStreamSilence, isFalse);

        await player.setAudioNullUntimed(true);
        expect(player.state.audioNullUntimed, isTrue);
        await player.setAudioNullUntimed(false);
        expect(player.state.audioNullUntimed, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}
