// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

/// An `http://` entry carries FFmpeg's reconnect options, so a server that
/// cuts a body or goes away for a moment no longer ends the track early:
/// a file on a server with ranges resumes where it stopped (mpv's own
/// `reconnect`), a connection that fails to open is tried again, and an
/// HLS segment that fails or is cut is requested again. A live stream
/// comes back with `reconnect_streamed`, which an app sets for it: on a
/// file it would replay the start, and the tests below hold that.
void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final flacPath = '$dir/sine_5s.flac';
  final aacPath = '$dir/codec/aac_adts_44100.aac';

  runtimeSuite(fixturePath: flacPath, extraFixtures: [aacPath], () {
    late Uint8List flac;
    late RangeHttpServer server;
    late Player player;
    late List<String> log;

    String describe() =>
        '${server.describe()}\nlog:\n  ${log.join('\n  ')}\n'
        'state: position ${player.state.position}, '
        'duration ${player.state.duration}';

    setUpAll(() => flac = File(flacPath).readAsBytesSync());

    setUp(() async {
      server = await RangeHttpServer.start({'a.flac': flac});
      // The default configuration logs warnings: the reconnects show.
      player = await buildPlayer(configuration: const PlayerConfiguration());
      // The tests wait on reconnects, not on playback: decode at once.
      await player.setAudioNullUntimed(true);
      log = [];
      final sub = player.stream.log.listen(
        (e) => log.add('${e.level.name} [${e.prefix}] ${e.text.trim()}'),
      );
      addTearDown(() async {
        await sub.cancel();
        await player.dispose();
        await server.close();
      });
    });

    /// Opens [media] and waits until the player parks at the end.
    Future<void> playToEnd(Media media) async {
      final completed = player.stream.completed
          .firstWhere((c) => c)
          .timeout(const Duration(seconds: 25));
      await player.open(media, play: true);
      await completed;
    }

    /// Whether the player parked at the end of what it was given: the
    /// position at the park against the duration.
    Matcher playedToEnd() => predicate<Player>(
      (p) =>
          p.state.position >=
          p.state.duration - const Duration(milliseconds: 200),
      'parked at the end of the file',
    );

    group('a progressive file', () {
      test(
        'cut short on a server with ranges resumes where it stopped',
        () async {
          final cut = flac.length ~/ 2;
          server.dropAfterBytes = cut;
          await playToEnd(Media(server.url('a.flac')));
          final gets = server.gets('/a.flac');
          expect(gets.first.dropped, isTrue, reason: describe());
          expect(
            gets.where((r) => r.start == cut && r.completed),
            isNotEmpty,
            reason: describe(),
          );
          expect(player, playedToEnd(), reason: describe());
        },
        timeout: const Timeout(Duration(seconds: 40)),
      );

      test('a server down at the open is tried again', () async {
        // Refused for 1.5 s: FFmpeg tries at 0, 0, 1 and 4 s.
        server.goDown(const Duration(milliseconds: 1500));
        final errors = <PlayerError>[];
        final sub = player.stream.error.listen(errors.add);
        addTearDown(sub.cancel);
        await playToEnd(Media(server.url('a.flac')));
        expect(server.refused, greaterThan(0), reason: describe());
        expect(errors.whereType<EndFileError>(), isEmpty, reason: describe());
        expect(player, playedToEnd(), reason: describe());
      }, timeout: const Timeout(Duration(seconds: 40)));

      test(
        'a server that stays down fails the entry after the retries',
        () async {
          server.goDown(const Duration(seconds: 30));
          final clock = Stopwatch()..start();
          final failed = player.stream.error
              .firstWhere((e) => e is EndFileError)
              .timeout(const Duration(seconds: 25));
          await player.open(Media(server.url('a.flac')), play: true);
          await failed;
          // The open and four more tries, after 0, 1, 3 and 7 s.
          expect(server.refused, 5, reason: describe());
          expect(
            clock.elapsed,
            greaterThanOrEqualTo(const Duration(seconds: 11)),
            reason: describe(),
          );
        },
        timeout: const Timeout(Duration(seconds: 40)),
      );

      test('an app can turn a default off', () async {
        server.goDown(const Duration(seconds: 30));
        final failed = player.stream.error
            .firstWhere((e) => e is EndFileError)
            .timeout(const Duration(seconds: 5));
        await player.open(
          Media(
            server.url('a.flac'),
            streamLavfOptions: const {'reconnect_on_network_error': '0'},
          ),
          play: true,
        );
        await failed;
        expect(server.refused, 1, reason: describe());
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('on a server without ranges a cut ends it, without replaying the '
          'start', () async {
        server.mode = ServeMode.noRanges;
        server.dropAfterBytes = flac.length ~/ 2;
        await playToEnd(Media(server.url('a.flac')));
        expect(server.gets('/a.flac'), hasLength(1), reason: describe());
        expect(
          player.state.position,
          lessThan(const Duration(seconds: 3)),
          reason: describe(),
        );
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('sent with no length, it plays once', () async {
        server.mode = ServeMode.closeDelimited;
        await playToEnd(Media(server.url('a.flac')));
        // A moment for a reopen to show up.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        expect(server.gets('/a.flac'), hasLength(1), reason: describe());
        expect(player, playedToEnd(), reason: describe());
      }, timeout: const Timeout(Duration(seconds: 40)));
    });

    group('a live stream', () {
      test('with reconnect_streamed comes back after it drops', () async {
        // A chunked body with no length, as a radio sends, cut halfway;
        // the server is then down for 1.5 s. The stream starts over from
        // its first byte, as a live one would go on from its live point.
        server.mode = ServeMode.chunked;
        server.dropAfterBytes = flac.length ~/ 2;
        server.downAfterDrop = const Duration(milliseconds: 1500);
        final ended = player.stream.endFile.first.timeout(
          const Duration(seconds: 25),
        );
        await player.open(
          Media(
            server.url('a.flac'),
            streamLavfOptions: const {'reconnect_streamed': '1'},
          ),
          play: true,
        );
        await player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 25));
        final gets = server.gets('/a.flac');
        expect(gets, hasLength(2), reason: describe());
        expect(gets.first.dropped, isTrue, reason: describe());
        expect(gets.last.completed, isTrue, reason: describe());
        expect(server.refused, greaterThan(0), reason: describe());
        // The cut came 2.09 s into the audio. The second body starts its
        // timestamps over and plays the file to its end, at 5 s.
        expect(
          player.state.position,
          greaterThan(const Duration(milliseconds: 4500)),
          reason: describe(),
        );
        await player.stop();
        expect((await ended).reason, MpvEndFileReason.stop);
      }, timeout: const Timeout(Duration(seconds: 40)));
    });

    group('an HLS stream', () {
      // Eight packed AAC segments, each the same ADTS file: the HLS
      // demuxer reads them as one stream, so a skipped segment shortens
      // the audio by one segment.
      const segments = 8;
      late Uint8List aac;

      setUp(() async {
        aac = File(aacPath).readAsBytesSync();
        await server.close();
        final playlist = StringBuffer(
          '#EXTM3U\n#EXT-X-VERSION:3\n#EXT-X-TARGETDURATION:2\n'
          '#EXT-X-MEDIA-SEQUENCE:0\n',
        );
        for (var i = 0; i < segments; i++) {
          playlist.write('#EXTINF:1.044900,\ns$i.aac\n');
        }
        playlist.write('#EXT-X-ENDLIST\n');
        server = await RangeHttpServer.start({
          'a.m3u8': Uint8List.fromList(playlist.toString().codeUnits),
          for (var i = 0; i < segments; i++) 's$i.aac': aac,
        });
      });

      /// Opens the stream and waits for the park.
      Future<void> play() async {
        final completed = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 25));
        await player.open(Media(server.url('a.m3u8')), play: true);
        await completed;
      }

      /// Whether [request] came while the stream played: the demuxer reads
      /// the first segments while it opens, then starts over from the first
      /// one, and a failure in those first reads would not reach playback.
      bool duringPlayback(ServedRequest request) =>
          !request.at.isBefore(server.gets('/s0.aac').last.at);

      test('a segment that fails to open once is not skipped', () async {
        // HTTP/1.0: FFmpeg then asks for each segment when it needs it.
        // Over HTTP/1.1 it also asks for the next one ahead, and that
        // early request takes a single failure on its own.
        server.http10 = true;
        server.statusOnce['s6.aac'] = 503;
        await play();
        final gets = server.gets('/s6.aac');
        final failed = gets.where((r) => r.status == 503);
        expect(failed, hasLength(1), reason: describe());
        expect(duringPlayback(failed.single), isTrue, reason: describe());
        expect(
          gets.where((r) => r.status ~/ 100 == 2 && r.completed),
          isNotEmpty,
          reason: describe(),
        );
        expect(player, playedToEnd(), reason: describe());
      }, timeout: const Timeout(Duration(seconds: 40)));

      test('a segment cut short is read again from where it stopped', () async {
        final cut = aac.length ~/ 2;
        server.cutOnce['s5.aac'] = cut;
        await play();
        final gets = server.gets('/s5.aac');
        final dropped = gets.where((r) => r.dropped);
        expect(dropped, hasLength(1), reason: describe());
        expect(duringPlayback(dropped.single), isTrue, reason: describe());
        expect(
          gets.where((r) => r.start == cut && r.completed),
          isNotEmpty,
          reason: describe(),
        );
        expect(player, playedToEnd(), reason: describe());
      }, timeout: const Timeout(Duration(seconds: 40)));
    });
  });
}
