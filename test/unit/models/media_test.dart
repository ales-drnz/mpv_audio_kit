// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

void main() {
  test('Media.fromBlob is for the browser: elsewhere it throws', () {
    expect(() => Media.fromBlob(Object()), throwsUnsupportedError);
  });

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

  group('Media.streamLavfOptions copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', streamLavfOptions: {'k': 'v'});
      expect(a.copyWith(uri: 'b').streamLavfOptions, {'k': 'v'});
    });

    test('set overrides', () {
      const a = Media('a');
      expect(a.copyWith(streamLavfOptions: {'k': 'v2'}).streamLavfOptions, {
        'k': 'v2',
      });
    });

    test('explicit null clears', () {
      const a = Media('a', streamLavfOptions: {'k': 'v'});
      expect(a.copyWith(streamLavfOptions: null).streamLavfOptions, isNull);
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

  group('Media.end copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', end: Duration(seconds: 3));
      expect(a.copyWith(uri: 'b').end, const Duration(seconds: 3));
    });

    test('set overrides', () {
      const a = Media('a');
      expect(
        a.copyWith(end: const Duration(seconds: 4)).end,
        const Duration(seconds: 4),
      );
    });

    test('explicit null clears', () {
      const a = Media('a', end: Duration(seconds: 3));
      expect(a.copyWith(end: null).end, isNull);
    });
  });

  group('Media.waveformDurationHint copyWith', () {
    test('omitted keeps the current value', () {
      const a = Media('a', waveformDurationHint: Duration(seconds: 3));
      expect(
        a.copyWith(uri: 'b').waveformDurationHint,
        const Duration(seconds: 3),
      );
    });

    test('set overrides', () {
      const a = Media('a');
      expect(
        a
            .copyWith(waveformDurationHint: const Duration(seconds: 4))
            .waveformDurationHint,
        const Duration(seconds: 4),
      );
    });

    test('explicit null clears', () {
      const a = Media('a', waveformDurationHint: Duration(seconds: 3));
      expect(
        a.copyWith(waveformDurationHint: null).waveformDurationHint,
        isNull,
      );
    });
  });

  group('Media equality — 0.1.0 full-field semantics', () {
    test('waveformDurationHint participates in equality', () {
      const a = Media('a');
      const b = Media('a', waveformDurationHint: Duration(seconds: 2));
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(b, const Media('a', waveformDurationHint: Duration(seconds: 2)));
      expect(
        b.hashCode,
        const Media('a', waveformDurationHint: Duration(seconds: 2)).hashCode,
      );
      // Not the same as an end at the same time.
      expect(b, isNot(const Media('a', end: Duration(seconds: 2))));
    });

    test('end participates in equality', () {
      const a = Media('a');
      const b = Media('a', end: Duration(seconds: 2));
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));
      expect(b, const Media('a', end: Duration(seconds: 2)));
      // Not the same as a start at the same time.
      expect(b, isNot(const Media('a', start: Duration(seconds: 2))));
    });

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

    test('streamLavfOptions participate in equality', () {
      const a = Media('a');
      const b = Media('a', streamLavfOptions: {'reconnect_streamed': '1'});
      expect(a, isNot(b));
      expect(a.hashCode, isNot(b.hashCode));

      const c = Media('a', streamLavfOptions: {'reconnect_streamed': '1'});
      expect(b, c);
      expect(b.hashCode, c.hashCode);
      expect(
        b,
        isNot(
          const Media('a', demuxerLavfOptions: {'reconnect_streamed': '1'}),
        ),
        reason: 'the two option maps are not interchangeable',
      );
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

    test('the stream options are printed by name, not by value', () {
      // FFmpeg's http options can carry credentials as the headers do.
      final out = const Media(
        'a',
        streamLavfOptions: {
          'headers': 'Authorization: Bearer s3cr3t',
          'http_proxy': 'http://user:pa55@proxy:3128',
        },
      ).toString();
      expect(
        out,
        contains(
          'streamLavfOptions: {headers: <redacted>, http_proxy: <redacted>}',
        ),
      );
      expect(out, isNot(contains('s3cr3t')));
      expect(out, isNot(contains('pa55')));
    });

    test('the demuxer options are printed by name, not by value', () {
      // decryption_key and the http options of a demuxer hold secrets too.
      final out = const Media(
        'a',
        demuxerLavfOptions: {'decryption_key': 'deadbeef00112233'},
      ).toString();
      expect(out, contains('demuxerLavfOptions: {decryption_key: <redacted>}'));
      expect(out, isNot(contains('deadbeef')));
      expect(
        const Media('a.mp3').toString(),
        contains('demuxerLavfOptions: null'),
      );
    });

    test('the user info of the uri is not printed', () {
      for (final (uri, printed) in [
        (
          'https://user:pa55@example.com/a.mp3',
          'https://<redacted>@example.com/a.mp3',
        ),
        ('ftp://token@host/a@b.mp3', 'ftp://<redacted>@host/a@b.mp3'),
        ('rtsp://u:p%40ss@cam:554/s', 'rtsp://<redacted>@cam:554/s'),
      ]) {
        final out = Media(uri).toString();
        expect(out, contains('uri: $printed,'), reason: uri);
        final request = SourceResolveRequest(
          media: Media(uri),
          uri: uri,
          isRetry: false,
        ).toString();
        expect(request, contains('uri: $printed,'), reason: uri);
        for (final secret in ['pa55', 'token', 'p%40ss']) {
          expect(out, isNot(contains(secret)), reason: uri);
          expect(request, isNot(contains(secret)), reason: uri);
        }
      }
      // A uri with no user info is printed as it is.
      for (final uri in [
        'https://example.com/a@b.mp3',
        '/music/me@home.flac',
        'mailto:a@b.c',
        r'C:\music\a.flac',
      ]) {
        expect(Media(uri).toString(), contains('uri: $uri,'), reason: uri);
      }
    });

    test('the query values of the uri are not printed, the names are', () {
      // Where a music server's credentials sit: Subsonic u, t and s,
      // Jellyfin api_key, Plex X-Plex-Token.
      for (final (uri, printed) in [
        (
          'https://srv/rest/stream?u=joe&t=26719a1196d2a940&s=c19b2d&id=7',
          'https://srv/rest/stream?u=<redacted>&t=<redacted>&s=<redacted>'
              '&id=<redacted>',
        ),
        (
          'https://joe:pa55@srv/a.mp3?api_key=deadbeef#t=10',
          'https://<redacted>@srv/a.mp3?api_key=<redacted>#t=10',
        ),
        (
          'http://srv:32400/lib/7/file.flac?X-Plex-Token=xyzzy&download',
          'http://srv:32400/lib/7/file.flac?X-Plex-Token=<redacted>&download',
        ),
        ('https://srv/a.mp3?sig=', 'https://srv/a.mp3?sig=<redacted>'),
      ]) {
        final out = Media(uri).toString();
        expect(out, contains('uri: $printed,'), reason: uri);
        final request = SourceResolveRequest(
          media: const Media('a.mp3'),
          uri: uri,
          isRetry: true,
        ).toString();
        expect(request, contains('uri: $printed,'), reason: uri);
        for (final secret in ['joe', '26719a', 'c19b2d', 'deadbeef', 'xyzzy']) {
          expect(out, isNot(contains(secret)), reason: uri);
          expect(request, isNot(contains(secret)), reason: uri);
        }
      }
      // No query, or no URL: printed as it is.
      for (final uri in [
        'https://example.com/a.mp3',
        'https://example.com/a.mp3#frag',
        '/music/what?=really.flac',
        'what?a=b.mp3',
      ]) {
        expect(Media(uri).toString(), contains('uri: $uri,'), reason: uri);
      }
    });

    test('an extra that is a URL is printed without its secrets', () {
      final out = Media(
        'a.mp3',
        extras: {
          'title': 'Episode 42',
          'trackId': 7,
          'art': 'https://joe:pa55@srv/rest/getCoverArt?id=al-1&t=26719a',
          'page': Uri.parse('https://srv/album?token=xyzzy'),
          'note': 'see ?a=b',
        },
      ).toString();
      expect(
        out,
        contains(
          'extras: {title: Episode 42, trackId: 7, '
          'art: https://<redacted>@srv/rest/getCoverArt?id=<redacted>'
          '&t=<redacted>, page: https://srv/album?token=<redacted>, '
          'note: see ?a=b}, ',
        ),
      );
      expect(const Media('a.mp3').toString(), contains('extras: null,'));
    });

    test('a playlist and an end-file event print their media the same', () {
      const media = Media('https://srv/stream?api_key=deadbeef');
      expect(const Playlist([media]).toString(), isNot(contains('deadbeef')));
      expect(
        const MpvFileEndedEvent(
          reason: MpvEndFileReason.eof,
          error: 0,
          media: media,
        ).toString(),
        isNot(contains('deadbeef')),
      );
    });

    test('no stream options prints null', () {
      expect(
        const Media('a.mp3').toString(),
        contains('streamLavfOptions: null'),
      );
    });

    test('the end is printed', () {
      expect(
        const Media('a.mp3', end: Duration(seconds: 2)).toString(),
        contains('end: 0:00:02.000000'),
      );
    });

    test('the start is printed', () {
      expect(
        const Media('a.mp3', start: Duration(seconds: 2)).toString(),
        contains('start: 0:00:02.000000'),
      );
    });

    test('the duration hint is printed', () {
      expect(
        const Media(
          'a.mp3',
          waveformDurationHint: Duration(seconds: 2),
        ).toString(),
        contains('waveformDurationHint: 0:00:02.000000'),
      );
    });

    test('no headers prints null', () {
      expect(const Media('a.mp3').toString(), contains('httpHeaders: null'));
    });
  });
}
