// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/pcm/pcm_native.dart';
import 'package:mpv_audio_kit/src/player/player.dart';

import '../pcm/fake_pcm_native.dart';

/// The per-entry `loadfile` options a [Media] gives, without a player.
void main() {
  group('start', () {
    test('null adds nothing', () {
      expect(loadfileOptions(const Media('a.flac')), '');
    });

    test('goes out in seconds with fixed decimals', () {
      String opts(Duration d) => loadfileOptions(Media('a.flac', start: d));
      expect(opts(Duration.zero), 'start=0.000');
      expect(opts(const Duration(seconds: 2)), 'start=2.000');
      expect(opts(const Duration(milliseconds: 1250)), 'start=1.250');
      // Every microsecond is kept.
      expect(opts(const Duration(microseconds: 1500500)), 'start=1.500500');
      // Never an exponent, at either end.
      expect(opts(const Duration(microseconds: 5)), 'start=0.000005');
      expect(opts(const Duration(days: 365 * 1000)), 'start=31536000000.000');
    });

    test('rides along with the other options', () {
      final opts = loadfileOptions(
        const Media(
          'https://example.com/a.mp3',
          httpHeaders: {'X-Token': 'abc'},
          start: Duration(minutes: 1),
        ),
      );
      expect(opts.split(','), contains('start=60.000'));
      expect(opts, contains('http-header-fields='));
    });

    test('a negative start is refused before any load', () {
      const media = Media('a.flac', start: Duration(milliseconds: -1));
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'start')),
      );
      expect(() => loadfileOptions(media), throwsArgumentError);
    });

    test('a live PCM entry refuses a start', () {
      debugPcmNativeOverride = FakePcmNative();
      addTearDown(() {
        debugPcmNativeOverride = null;
        PcmSource.debugReset();
      });
      final source = PcmSource.create(
        const PcmFormat(sampleRate: 1000, channels: 1),
      );
      final media = source.toMedia().copyWith(
        start: const Duration(seconds: 1),
      );
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'start')),
      );
      // Without a start it loads as before.
      validateLoadOptions(source.toMedia());
    });
  });

  group('end', () {
    test('goes out like start, after it', () {
      expect(
        loadfileOptions(const Media('a.flac', end: Duration(seconds: 30))),
        'end=30.000',
      );
      expect(
        loadfileOptions(
          const Media(
            'a.flac',
            start: Duration(minutes: 1),
            end: Duration(minutes: 1, seconds: 30, microseconds: 5),
          ),
        ),
        'start=60.000,end=90.000005',
      );
    });

    test('must be later than start, or than zero', () {
      Matcher refused() =>
          throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'end'));
      expect(
        () => validateLoadOptions(const Media('a.flac', end: Duration.zero)),
        refused(),
      );
      expect(
        () => validateLoadOptions(
          const Media('a.flac', end: Duration(milliseconds: -5)),
        ),
        refused(),
      );
      expect(
        () => validateLoadOptions(
          const Media(
            'a.flac',
            start: Duration(seconds: 2),
            end: Duration(seconds: 2),
          ),
        ),
        refused(),
      );
      expect(
        () => loadfileOptions(
          const Media(
            'a.flac',
            start: Duration(seconds: 3),
            end: Duration(seconds: 2),
          ),
        ),
        refused(),
      );
      // Just after start is fine.
      validateLoadOptions(
        const Media(
          'a.flac',
          start: Duration(seconds: 2),
          end: Duration(seconds: 2, microseconds: 1),
        ),
      );
    });

    test('a live PCM entry refuses an end', () {
      debugPcmNativeOverride = FakePcmNative();
      addTearDown(() {
        debugPcmNativeOverride = null;
        PcmSource.debugReset();
      });
      final media = PcmSource.create(
        const PcmFormat(sampleRate: 1000, channels: 1),
      ).toMedia().copyWith(end: const Duration(seconds: 1));
      expect(
        () => validateLoadOptions(media),
        throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'end')),
      );
    });
  });
  group('stream-lavf-o', () {
    const defaults =
        'reconnect=1,reconnect_delay_max=7,'
        'reconnect_on_network_error=1,seg_max_retry=4';

    /// The `stream-lavf-o` value [media] gives, its length prefix checked;
    /// `null` when it gives none.
    String? streamOptions(Media media) {
      final opts = loadfileOptions(media);
      final m = RegExp(r'stream-lavf-o=%(\d+)%').firstMatch(opts);
      if (m == null) return null;
      final length = int.parse(m.group(1)!);
      final value = opts.substring(m.end, m.end + length);
      expect(utf8.encode(value).length, length);
      return value;
    }

    test('an http or https entry gets the reconnect defaults', () {
      expect(streamOptions(const Media('http://h/a.mp3')), defaults);
      expect(streamOptions(const Media('https://h/a.m3u8')), defaults);
      expect(streamOptions(const Media('HTTPS://h/a.mp3')), defaults);
    });

    test('other entries get none', () {
      expect(loadfileOptions(const Media('a.flac')), '');
      expect(loadfileOptions(const Media('file:///m/a.flac')), '');
      expect(loadfileOptions(const Media('asset:///assets/a.mp3')), '');
      expect(loadfileOptions(const Media('rtsp://h/live')), '');
      expect(loadfileOptions(const Media('smb2://h/share/a.flac')), '');
      expect(loadfileOptions(const Media('fd://7')), '');
    });

    test('httpChunkSize joins them, each key once', () {
      expect(
        streamOptions(const Media('https://h/a.mp3', httpChunkSize: 1024)),
        '$defaults,initial_request_size=1024,request_size=1024,'
        'reconnect_streamed=1',
      );
    });

    test('a key of streamLavfOptions wins, a new one is added', () {
      expect(
        streamOptions(
          const Media(
            'https://h/a.mp3',
            httpChunkSize: 1024,
            streamLavfOptions: {
              'reconnect_on_network_error': '0',
              'reconnect_streamed': '0',
              'timeout': '5000000',
            },
          ),
        ),
        'reconnect=1,reconnect_delay_max=7,reconnect_on_network_error=0,'
        'seg_max_retry=4,initial_request_size=1024,request_size=1024,'
        'reconnect_streamed=0,timeout=5000000',
      );
    });

    test('streamLavfOptions alone on any other entry', () {
      expect(
        loadfileOptions(
          const Media('rtsp://h/live', streamLavfOptions: {'timeout': '5'}),
        ),
        'stream-lavf-o=%9%timeout=5',
      );
    });

    test('rides along with the other options, in place', () {
      final opts = loadfileOptions(
        const Media(
          'https://h/a.mp3',
          httpHeaders: {'X-Token': 'abc'},
          demuxerLavfOptions: {'k': 'v'},
          start: Duration(seconds: 1),
        ),
      );
      expect(opts.indexOf('http-header-fields='), 0);
      expect(
        opts.indexOf('stream-lavf-o='),
        lessThan(opts.indexOf('demuxer-lavf-o=')),
      );
      expect(opts, endsWith(',start=1.000'));
    });

    test('a bad key or value is refused before any load', () {
      for (final bad in const [
        {'': 'v'},
        {'k': 'a,b'},
        {'k\n': 'v'},
        {'k': 'v\r'},
        {'k': 'v\x00'},
      ]) {
        final media = Media('https://h/a.mp3', streamLavfOptions: bad);
        expect(() => validateLoadOptions(media), throwsArgumentError);
        expect(() => loadfileOptions(media), throwsArgumentError);
      }
    });
  });
}
