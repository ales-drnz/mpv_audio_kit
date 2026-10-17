// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  group('Media construction', () {
    test('positional uri only', () {
      const media = Media('https://example.com/a.mp3');
      expect(media.uri, 'https://example.com/a.mp3');
      expect(media.extras, isNull);
      expect(media.httpHeaders, isNull);
      expect(media.httpChunkSize, isNull);
    });

    test('full constructor with extras + headers + chunk size', () {
      const media = Media(
        'https://example.com/a.mp3',
        extras: {'title': 'Song', 'artist': 'Artist'},
        httpHeaders: {'X-Token': 'abc'},
        httpChunkSize: 8 * 1024 * 1024,
      );
      expect(media.extras, {'title': 'Song', 'artist': 'Artist'});
      expect(media.httpHeaders, {'X-Token': 'abc'});
      expect(media.httpChunkSize, 8 * 1024 * 1024);
    });

    test('demuxerLavfOptions carried through', () {
      const media = Media(
        'https://example.com/a.mp3',
        demuxerLavfOptions: {'seg_format_options': 'advanced_editlist=0'},
      );
      expect(media.demuxerLavfOptions, {
        'seg_format_options': 'advanced_editlist=0',
      });
    });
  });

  group('Media.demuxerLavfOptions copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', demuxerLavfOptions: {'k': 'v'});
      expect(a.copyWith(uri: 'b').demuxerLavfOptions, {'k': 'v'});
    });

    test('set overrides', () {
      const a = Media('a');
      expect(a.copyWith(demuxerLavfOptions: {'k': 'v2'}).demuxerLavfOptions, {
        'k': 'v2',
      });
    });

    test('explicit null clears', () {
      const a = Media('a', demuxerLavfOptions: {'k': 'v'});
      expect(a.copyWith(demuxerLavfOptions: null).demuxerLavfOptions, isNull);
    });
  });

  group('Media.httpChunkSize copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', httpChunkSize: 4096);
      expect(a.copyWith(uri: 'b').httpChunkSize, 4096);
    });

    test('set overrides', () {
      const a = Media('a');
      expect(a.copyWith(httpChunkSize: 8192).httpChunkSize, 8192);
    });

    test('explicit null clears', () {
      const a = Media('a', httpChunkSize: 8192);
      expect(a.copyWith(httpChunkSize: null).httpChunkSize, isNull);
    });
  });

  group('Media.start copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', start: Duration(seconds: 3));
      expect(a.copyWith(uri: 'b').start, const Duration(seconds: 3));
    });

    test('set overrides', () {
      const a = Media('a');
      expect(
        a.copyWith(start: const Duration(seconds: 4)).start,
        const Duration(seconds: 4),
      );
    });

    test('explicit null clears', () {
      const a = Media('a', start: Duration(seconds: 3));
      expect(a.copyWith(start: null).start, isNull);
    });
  });

  group('Media equality — 0.1.0 full-field semantics', () {
    test('start participates in equality', () {
      const a = Media('a');
      const b = Media('a', start: Duration(seconds: 2));
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(b, const Media('a', start: Duration(seconds: 2)));
      expect(
        b.hashCode,
        const Media('a', start: Duration(seconds: 2)).hashCode,
      );
    });

    // Regression tests for the 0.1.0 breaking change: `Media` equality
    // now considers `extras` and `httpHeaders`, not just `uri`. The
    // previous behaviour silently broke playlist deduplication when a
    // consumer attached cover art to an existing entry.

    test('extras participate in equality', () {
      const a = Media('a');
      const b = Media('a', extras: {'cover': 'data'});
      expect(a, isNot(b));
    });

    test('httpHeaders participate in equality', () {
      const a = Media('a');
      const b = Media('a', httpHeaders: {'X-Token': 'foo'});
      expect(a, isNot(b));
    });

    test('httpChunkSize participates in equality', () {
      const a = Media('a');
      const b = Media('a', httpChunkSize: 8 * 1024 * 1024);
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
    });

    test('demuxerLavfOptions participate in equality', () {
      const a = Media('a');
      const b = Media('a', demuxerLavfOptions: {'seg_format_options': 'x=1'});
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));

      const c = Media('a', demuxerLavfOptions: {'seg_format_options': 'x=1'});
      expect(b, c);
      expect(b.hashCode, c.hashCode);
    });
  });

  group('toString hides header values', () {
    const media = Media(
      'https://example.com/a.mp3',
      httpHeaders: {'Authorization': 'Bearer s3cr3t', 'X-Token': 'abc123'},
    );

    test('Media keeps the header names, not their values', () {
      final out = media.toString();
      expect(out, contains('Authorization'));
      expect(out, contains('X-Token'));
      expect(out, isNot(contains('s3cr3t')));
      expect(out, isNot(contains('abc123')));
    });

    test('SourceResolveRequest prints its media without header values', () {
      final out = const SourceResolveRequest(
        media: media,
        uri: 'https://example.com/a.mp3',
        isRetry: false,
      ).toString();
      expect(out, contains('Authorization'));
      expect(out, isNot(contains('s3cr3t')));
    });

    test('the start is printed', () {
      expect(
        const Media('a.mp3', start: Duration(seconds: 2)).toString(),
        contains('start: 0:00:02.000000'),
      );
    });

    test('no headers prints null', () {
      expect(const Media('a.mp3').toString(), contains('httpHeaders: null'));
    });
  });
}
