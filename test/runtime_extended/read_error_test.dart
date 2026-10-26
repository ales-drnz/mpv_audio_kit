// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// A stream cut short ends as a normal end of file: mpv reports EOF with no
// error. libmpv-r20 (patch read_error) remembers that the demuxer stopped
// on a read error, and counts the HLS and DASH segments it lost, in two
// fields at the end of END_FILE and in two properties read at the park of
// the last entry. The player puts them on MpvFileEndedEvent and on
// PlayerState. Up to r19 nothing told the two ends apart.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

void main() {
  final dir = '${Directory.current.path}/test/fixtures';
  final flacPath = '$dir/sine_5s.flac';
  final shortPath = '$dir/sine_440hz_1s.wav';
  final aacPath = '$dir/codec/aac_adts_44100.aac';
  // 6 s of audio, 18 s by the bitrate estimate.
  final vbrPath = '$dir/extra/vbr_no_xing.mp3';
  // No reconnect: a cut ends the read at once, as the retries that fail
  // would after about 11 s.
  const once = {'reconnect': '0'};

  runtimeSuite(
    fixturePath: flacPath,
    extraFixtures: [shortPath, aacPath, vbrPath],
    () {
      late Uint8List flac;
      late RangeHttpServer server;
      late Player player;
      late List<String> log;
      late List<MpvFileEndedEvent> ended;

      String describe() =>
          '${server.describe()}\nlog:\n  ${log.join('\n  ')}\n'
          'ended: $ended\nstate: position ${player.state.position}, '
          'duration ${player.state.duration}, readError '
          '${player.state.readError}, skipped ${player.state.skippedSegments}';

      setUpAll(() => flac = File(flacPath).readAsBytesSync());

      setUp(() async {
        server = await RangeHttpServer.start({'a.flac': flac});
        // The default configuration logs warnings: the cuts show.
        player = await buildPlayer(configuration: const PlayerConfiguration());
        // The tests wait on the network, not on playback: decode at once.
        await player.setAudioNullUntimed(true);
        log = [];
        ended = [];
        final subs = [
          player.stream.log.listen(
            (e) => log.add('${e.level.name} [${e.prefix}] ${e.text.trim()}'),
          ),
          player.stream.endFile.listen(ended.add),
        ];
        addTearDown(() async {
          for (final sub in subs) {
            await sub.cancel();
          }
          await player.dispose();
          await server.close();
        });
      });

      /// Opens [medias] and waits until the player parks at the end.
      Future<void> playToEnd(List<Media> medias) async {
        final completed = player.stream.completed
            .firstWhere((c) => c)
            .timeout(const Duration(seconds: 30));
        await player.openAll(medias, play: true);
        await completed;
      }

      Media cutOnce(String url) => Media(url, streamLavfOptions: once);

      // Without the patch the fields are null: the transport reads them
      // only from a libmpv that has it.
      test('a libmpv without the patch leaves the fields null', () async {
        final patched = libmpvNamesProperty(
          resolveLibmpv()!,
          'demuxer-read-error',
        );
        await playToEnd([Media(shortPath), Media(shortPath)]);
        expect(ended, hasLength(1), reason: describe());
        expect(ended.single.readError, patched ? isFalse : isNull);
        expect(ended.single.skippedSegments, patched ? 0 : isNull);
        expect(player.state.readError, patched ? isFalse : isNull);
        expect(player.state.skippedSegments, patched ? 0 : isNull);
      }, timeout: const Timeout(Duration(seconds: 30)));

      libmpvReleaseGroup(20, 'A read error', () {
        test('ends an entry cut short in a playlist, the next one does '
            'not', () async {
          server.dropAfterBytes = flac.length ~/ 2;
          await playToEnd([cutOnce(server.url('a.flac')), Media(shortPath)]);
          expect(ended, hasLength(1), reason: describe());
          final first = ended.single;
          expect(first.reason, MpvEndFileReason.eof, reason: describe());
          expect(first.error, 0);
          expect(first.readError, isTrue, reason: describe());
          expect(first.skippedSegments, 0);
          expect(player.state.readError, isFalse, reason: describe());
          expect(player.state.skippedSegments, 0);
        }, timeout: const Timeout(Duration(seconds: 40)));

        test('parks the last entry cut short, and its stop tells it '
            'again', () async {
          server.dropAfterBytes = flac.length ~/ 2;
          await playToEnd([cutOnce(server.url('a.flac'))]);
          expect(ended, isEmpty, reason: 'the park sends no event');
          expect(player.state.readError, isTrue, reason: describe());
          expect(player.state.skippedSegments, 0);
          await player.stop();
          await waitUntil(() => ended.isNotEmpty, reason: describe());
          expect(ended.single.reason, MpvEndFileReason.stop);
          expect(ended.single.readError, isTrue, reason: describe());
          expect(player.state.readError, isNull, reason: 'not completed');
        }, timeout: const Timeout(Duration(seconds: 40)));

        test('ends a file a server without ranges closed early, with no '
            'wait', () async {
          server.mode = ServeMode.noRanges;
          server.dropAfterBytes = flac.length ~/ 2;
          final clock = Stopwatch()..start();
          await playToEnd([Media(server.url('a.flac'))]);
          expect(player.state.readError, isTrue, reason: describe());
          expect(clock.elapsed, lessThan(const Duration(seconds: 5)));
          expect(server.gets('/a.flac'), hasLength(1), reason: describe());
        }, timeout: const Timeout(Duration(seconds: 40)));

        test('is not reported for a file read whole', () async {
          await playToEnd([Media(server.url('a.flac')), Media(shortPath)]);
          expect(ended, hasLength(1), reason: describe());
          expect(ended.single.readError, isFalse, reason: describe());
          expect(player.state.readError, isFalse);
          await player.stop();
          await waitUntil(
            () => ended.length == 2 && !player.state.completed,
            reason: describe(),
          );
          await playToEnd([Media(server.url('a.flac'))]);
          expect(player.state.readError, isFalse, reason: describe());
          expect(player.state.skippedSegments, 0);
        }, timeout: const Timeout(Duration(seconds: 40)));

        test(
          'tells a file read whole short of an estimated duration',
          () async {
            await openAndWaitForLoad(player, vbrPath);
            await waitUntil(() => player.state.duration > Duration.zero);
            final estimated = player.state.duration;
            final completed = player.stream.completed
                .firstWhere((c) => c)
                .timeout(const Duration(seconds: 30));
            await player.play();
            await completed;
            expect(player.state.readError, isFalse, reason: describe());
            expect(
              player.state.position,
              lessThan(estimated - const Duration(seconds: 5)),
              reason:
                  'the duration of an MP3 without a Xing header is an '
                  'estimate, $estimated (${describe()})',
            );
          },
          timeout: const Timeout(Duration(seconds: 30)),
        );

        test('is not reported when the read resumes after a cut', () async {
          final cut = flac.length ~/ 2;
          server.dropAfterBytes = cut;
          await playToEnd([Media(server.url('a.flac'))]);
          expect(
            server.gets('/a.flac').where((r) => r.start == cut && r.completed),
            isNotEmpty,
            reason: describe(),
          );
          expect(player.state.readError, isFalse, reason: describe());
        }, timeout: const Timeout(Duration(seconds: 40)));

        test('ends a file whose resume the server refuses, after the default '
            'retries', () async {
          server.dropAfterBytes = flac.length ~/ 2;
          server.refuseResume = true;
          await playToEnd([Media(server.url('a.flac')), Media(shortPath)]);
          expect(ended, hasLength(1), reason: describe());
          expect(ended.single.readError, isTrue, reason: describe());
          expect(
            server.gets('/a.flac').where((r) => r.status == 503),
            isNotEmpty,
            reason: describe(),
          );
        }, timeout: const Timeout(Duration(seconds: 60)));

        group('on a chunked live stream', () {
          setUp(() => server.mode = ServeMode.chunked);

          test('ends one closed between two chunks', () async {
            server.dropAfterBytes = 2 * 16 * 1024;
            await playToEnd([Media(server.url('a.flac'))]);
            expect(player.state.readError, isTrue, reason: describe());
            expect(server.gets('/a.flac'), hasLength(1), reason: describe());
          }, timeout: const Timeout(Duration(seconds: 40)));

          test('ends one closed inside a chunk', () async {
            server.dropAfterBytes = 2 * 16 * 1024 + 5000;
            server.cutInsideChunk = true;
            await playToEnd([Media(server.url('a.flac'))]);
            expect(player.state.readError, isTrue, reason: describe());
            expect(server.gets('/a.flac'), hasLength(1), reason: describe());
          }, timeout: const Timeout(Duration(seconds: 40)));

          test('does not end one closed with its last chunk', () async {
            await playToEnd([Media(server.url('a.flac'))]);
            expect(player.state.readError, isFalse, reason: describe());
            expect(server.gets('/a.flac'), hasLength(1), reason: describe());
          }, timeout: const Timeout(Duration(seconds: 40)));
        });

        group('on an HLS stream', () {
          // Eight packed AAC segments, each the same ADTS file: the HLS
          // demuxer reads them as one stream.
          const segments = 8;
          late Uint8List aac;

          Future<void> serve({Set<int> missing = const {}}) async {
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
              for (var i = 0; i < segments; i++)
                if (!missing.contains(i)) 's$i.aac': aac,
            });
          }

          test('counts a segment that never opens', () async {
            await serve(missing: {6});
            await playToEnd([Media(server.url('a.m3u8'))]);
            expect(player.state.skippedSegments, 1, reason: describe());
            expect(player.state.readError, isFalse, reason: describe());
          }, timeout: const Timeout(Duration(seconds: 40)));

          test('counts a segment whose read breaks off', () async {
            await serve();
            server.cutOnce['s5.aac'] = aac.length ~/ 2;
            server.refuseResume = true;
            await playToEnd([Media(server.url('a.m3u8')), Media(shortPath)]);
            expect(ended, hasLength(1), reason: describe());
            expect(ended.single.skippedSegments, 1, reason: describe());
            expect(ended.single.readError, isFalse, reason: describe());
          }, timeout: const Timeout(Duration(seconds: 60)));
        });
      });
    },
  );
}
