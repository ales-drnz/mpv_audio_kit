// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import '../_helpers/libmpv_resolver.dart';

void main() {
  // Streaming smoke — exercises the network path of the libmpv demuxer
  // against a maintained reference stream provider (radiomast.io publishes
  // these "ref-*" endpoints explicitly for testing) and Apple's BipBop
  // HLS test asset. Both targets are stable and have been used by the
  // wider streaming-media tooling community for years.
  //
  // The whole group skips when the host has no internet — `flutter test`
  // ought to pass on an air-gapped CI machine, so a connectivity probe
  // gates the suite at setUpAll. Once probe passes, individual tests
  // assume reachability.
  const icyRadio = 'https://streams.radiomast.io/ref-128k-mp3-stereo';
  const hlsStream =
      'https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear0/prog_index.m3u8';

  bool networkAvailable = false;

  setUpAll(() async {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    // Probe radiomast.io with a short HEAD timeout — if it fails the
    // whole group is skipped, no point burning 30s of timeouts per test.
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final req = await client.headUrl(Uri.parse(icyRadio));
      final resp = await req.close().timeout(const Duration(seconds: 4));
      await resp.drain();
      client.close();
      networkAvailable = true;
    } catch (_) {
      networkAvailable = false;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Streaming — HTTP / HTTPS / HLS', () {
    late Player player;

    setUpAll(() async {
      if (!networkAvailable) return;
      player = Player(
        configuration: const PlayerConfiguration(
          autoPlay: false,
          logLevel: 'no',
        ),
      );
      await player.setRawProperty('ao', 'null');
    });

    tearDownAll(() async {
      if (!networkAvailable) return;
      await player.stop();
      await player.dispose();
    });

    test('ICY MP3 radio stream settles audioParams', () async {
      if (!networkAvailable) {
        markTestSkipped('Network unreachable');
        return;
      }
      // Pre-subscribe so the broadcast emit isn't missed by a late
      // listener — the network roundtrip can land before firstWhere
      // attaches if we open() first.
      final paramsFuture = player.stream.audioParams
          .firstWhere((p) => p.sampleRate != null)
          .timeout(const Duration(seconds: 20));
      await player.open(Media(icyRadio), play: false);
      final params = await paramsFuture;
      expect(params.sampleRate, isNotNull,
          reason: 'demuxer must report sampleRate after the network buffer fills');
      expect(params.channelCount, anyOf(1, 2),
          reason: 'reference stream is mono or stereo');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('HLS audio playlist demuxes and reports duration', () async {
      if (!networkAvailable) {
        markTestSkipped('Network unreachable');
        return;
      }
      // Apple BipBop is a finite test stream (~30s clip), so duration
      // should be non-zero once the playlist is parsed.
      final paramsFuture = player.stream.audioParams
          .firstWhere((p) => p.sampleRate != null)
          .timeout(const Duration(seconds: 20));
      await player.open(Media(hlsStream), play: false);
      await paramsFuture;
      expect(player.state.duration.inMilliseconds, greaterThan(0),
          reason: 'BipBop HLS clip has finite duration; mpv must parse the '
              'playlist and surface it');
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
