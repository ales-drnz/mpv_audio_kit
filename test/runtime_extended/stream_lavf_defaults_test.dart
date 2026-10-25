// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

/// The reconnect defaults are mpv's global `stream-lavf-o`, set when the
/// player starts: every network open gets them, an entry carries no
/// options of its own for them (so the prefetch opens it ahead as before),
/// the app's own global value replaces them, and an entry's
/// `streamLavfOptions` add to them for that entry only. The opens that do
/// not speak HTTP ignore them.
void main() {
  const defaults =
      'reconnect=1,reconnect_delay_max=7,'
      'reconnect_on_network_error=1,seg_max_retry=4';
  final dir = '${Directory.current.path}/test/fixtures';
  final oneSecond = '$dir/sine_stereo_1s.flac';
  final fiveSeconds = '$dir/sine_5s.flac';

  runtimeSuite(fixturePath: fiveSeconds, extraFixtures: [oneSecond], () {
    group('the global stream-lavf-o', () {
      test('holds the defaults from the start', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        expect(await player.getRawProperty('stream-lavf-o'), defaults);
      });

      test('set by the app, replaces them', () async {
        final server = await RangeHttpServer.start({});
        addTearDown(server.close);
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.setRawProperty('stream-lavf-o', 'timeout=5000000');
        expect(await player.getRawProperty('stream-lavf-o'), 'timeout=5000000');
        // No reconnect_on_network_error any more: one refused open fails
        // the entry.
        server.goDown(const Duration(seconds: 30));
        final failed = player.stream.error
            .firstWhere((e) => e is EndFileError)
            .timeout(const Duration(seconds: 5));
        await player.open(Media(server.url('a.flac')), play: true);
        await failed;
        expect(server.refused, 1);
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('change-list add keeps them', () async {
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.sendRawCommand([
          'change-list',
          'stream-lavf-o',
          'add',
          'timeout=5000000',
        ]);
        expect(
          await player.getRawProperty('stream-lavf-o'),
          '$defaults,timeout=5000000',
        );
      });

      test('an entry adds its own options to them, for itself', () async {
        final server = await RangeHttpServer.start({
          'a.flac': File(fiveSeconds).readAsBytesSync(),
        });
        addTearDown(server.close);
        final player = await buildPlayer();
        addTearDown(player.dispose);
        await player.open(
          Media(
            server.url('a.flac'),
            streamLavfOptions: const {'timeout': '9'},
          ),
          play: true,
        );
        await waitUntil(
          () => player.state.position > const Duration(milliseconds: 200),
          timeout: const Duration(seconds: 10),
        );
        expect(
          await player.getRawProperty('stream-lavf-o'),
          '$defaults,timeout=9',
        );
        final ended = player.stream.endFile.first.timeout(
          const Duration(seconds: 5),
        );
        await player.stop();
        await ended;
        await waitUntil(
          () async => await player.getRawProperty('stream-lavf-o') == defaults,
          reason: 'the entry options outlived the entry',
        );
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    group('with the prefetch, a playlist of local and http entries', () {
      late RangeHttpServer server;
      late Player player;
      late List<PrefetchState> states;

      setUp(() async {
        server = await RangeHttpServer.start({
          'one.flac': File(oneSecond).readAsBytesSync(),
          'five.flac': File(fiveSeconds).readAsBytesSync(),
        });
        player = await buildPlayer();
        await player.setPrefetchPlaylist(true);
        states = [];
        final sub = player.stream.prefetchState.listen(states.add);
        addTearDown(() async {
          await sub.cancel();
          await player.dispose();
          await server.close();
        });
      });

      /// Plays [first] then [second] and returns once the second one plays
      /// on. mpv reports `used` when the second entry starts on the demuxer
      /// it opened ahead. Not `state.playing`: after a gapless transition
      /// it can stay false while the next entry plays (seen on local files
      /// too, a defect of its own).
      Future<void> playPair(Media first, Media second) async {
        final ends = <String>[];
        final sub = player.stream.endFile.listen(
          (e) => ends.add('${e.reason.name} ${e.media?.uri}'),
        );
        addTearDown(sub.cancel);
        await player.openAll([first, second], play: true);
        final deadline = DateTime.now().add(const Duration(seconds: 10));
        while (!(player.state.playlist.index == 1 &&
            player.state.position > const Duration(milliseconds: 200))) {
          if (DateTime.now().isAfter(deadline)) {
            final s = player.state;
            fail(
              'the second entry never played: index ${s.playlist.index}, '
              'position ${s.position}, completed ${s.completed}\n'
              'ends $ends\nprefetch $states\n${server.describe()}',
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
      }

      test('opens the http entry after a local file ahead', () async {
        await playPair(Media(oneSecond), Media(server.url('five.flac')));
        expect(server.gets('/five.flac'), hasLength(1));
        expect(states, contains(PrefetchState.used), reason: '$states');
      }, timeout: const Timeout(Duration(seconds: 30)));

      test('opens a local file after an http entry ahead', () async {
        await playPair(Media(server.url('one.flac')), Media(fiveSeconds));
        expect(states, contains(PrefetchState.used), reason: '$states');
      }, timeout: const Timeout(Duration(seconds: 30)));
    });

    // Each source is played twice, with the defaults and with the global
    // option cleared: what reaches the app must be the same.
    group('a source that does not speak HTTP is left as it was', () {
      /// What [media] gives on a fresh player: its end events and errors,
      /// its log lines at warn and above, and where it parked. [options]
      /// replaces the global `stream-lavf-o` when not null.
      Future<List<String>> outcome(
        Media media, {
        String? options,
        Duration? networkTimeout,
      }) async {
        final player = await buildPlayer(
          configuration: const PlayerConfiguration(),
        );
        try {
          await player.setAudioNullUntimed(true);
          if (networkTimeout != null) {
            await player.setNetworkTimeout(networkTimeout);
          }
          if (options != null) {
            await player.setRawProperty('stream-lavf-o', options);
          }
          final seen = <String>[];
          final subs = [
            player.stream.log.listen(
              (e) => seen.add('log ${e.level.name} [${e.prefix}] ${e.text}'),
            ),
            player.stream.endFile.listen(
              (e) => seen.add('end ${e.reason.name} ${e.error}'),
            ),
          ];
          final settled = Future.any([
            player.stream.completed.firstWhere((c) => c),
            player.stream.error.firstWhere((e) => e is EndFileError),
          ]).timeout(const Duration(seconds: 15));
          await player.open(media, play: true);
          await settled;
          // A moment for the lines that follow the end.
          await Future<void>.delayed(const Duration(milliseconds: 300));
          seen.add(
            'parked ${player.state.completed} '
            '${player.state.position.inMilliseconds}',
          );
          for (final s in subs) {
            await s.cancel();
          }
          return seen;
        } finally {
          await player.dispose();
        }
      }

      // The log lines and the end events reach the app on two streams, in
      // an order mpv does not fix: compared as sets of lines.
      Future<void> expectSame(Media media, {Duration? networkTimeout}) async {
        final cleared = await outcome(
          media,
          options: '',
          networkTimeout: networkTimeout,
        );
        final withDefaults = await outcome(
          media,
          networkTimeout: networkTimeout,
        );
        expect(withDefaults, unorderedEquals(cleared));
        expect(withDefaults.where((l) => l.contains('reconnect')), isEmpty);
      }

      test('a local path and a file:// URL', () async {
        await expectSame(Media(oneSecond));
        await expectSame(Media(Uri.file(oneSecond).toString()));
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('an asset', () async {
        final messenger =
            TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
        final bytes = File(oneSecond).readAsBytesSync();
        messenger.setMockMessageHandler(
          'flutter/assets',
          (_) async => ByteData.sublistView(bytes),
        );
        addTearDown(
          () => messenger.setMockMessageHandler('flutter/assets', null),
        );
        await expectSame(const Media('asset:///assets/stream_defaults.flac'));
      }, timeout: const Timeout(Duration(seconds: 60)));

      test(
        'an fd:// descriptor',
        skip: Platform.isWindows ? 'POSIX descriptors' : false,
        () async {
          // A descriptor each: mpv reads one from where the last read left
          // it.
          final first = _openFd(oneSecond);
          addTearDown(() => _closeFd(first));
          final second = _openFd(oneSecond);
          addTearDown(() => _closeFd(second));
          final cleared = await outcome(Media('fd://$first'), options: '');
          final withDefaults = await outcome(Media('fd://$second'));
          // The descriptor number is in some lines: compare without it.
          String strip(String l) => l.replaceAll(RegExp(r'fd://\d+'), 'fd://N');
          expect(withDefaults.map(strip), unorderedEquals(cleared.map(strip)));
        },
        timeout: const Timeout(Duration(seconds: 60)),
      );

      test('a live PCM source', () async {
        Media pcm() {
          const format = PcmFormat(sampleRate: 24000, channels: 1);
          final source = PcmSource.create(format);
          final d = ByteData(format.sampleRate * 2);
          for (var i = 0; i < format.sampleRate; i++) {
            final v = 0.3 * math.sin(2 * math.pi * 440 * i / format.sampleRate);
            d.setInt16(i * 2, (v * 32767).round(), Endian.little);
          }
          source.add(d.buffer.asUint8List());
          source.close();
          return source.toMedia();
        }

        final cleared = await outcome(pcm(), options: '');
        final withDefaults = await outcome(pcm());
        String strip(String l) =>
            l.replaceAll(RegExp(r'mak-pcm://\S+'), 'mak-pcm://N');
        expect(withDefaults.map(strip), unorderedEquals(cleared.map(strip)));
      }, timeout: const Timeout(Duration(seconds: 60)));

      test('an smb2:// share that refuses or does not answer', () async {
        // A port nothing listens on, then a server that never answers
        // (the connect times out after the network timeout). A server that
        // hangs up is left out: the socket error it gives varies.
        final closed = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final refusedPort = closed.port;
        await closed.close();
        await expectSame(Media('smb2://127.0.0.1:$refusedPort/share/a.flac'));

        final silent = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final held = <Socket>[];
        silent.listen(held.add);
        addTearDown(() async {
          for (final s in held) {
            s.destroy();
          }
          await silent.close();
        });
        await expectSame(
          Media('smb2://127.0.0.1:${silent.port}/share/a.flac'),
          networkTimeout: const Duration(seconds: 1),
        );
      }, timeout: const Timeout(Duration(seconds: 90)));
    });
  });
}

int _openFd(String path) {
  final open = DynamicLibrary.process()
      .lookupFunction<
        Int32 Function(Pointer<Utf8>, Int32),
        int Function(Pointer<Utf8>, int)
      >('open');
  final p = path.toNativeUtf8();
  try {
    final fd = open(p, 0);
    if (fd < 0) throw StateError('open($path) failed');
    return fd;
  } finally {
    malloc.free(p);
  }
}

void _closeFd(int fd) => DynamicLibrary.process()
    .lookupFunction<Int32 Function(Int32), int Function(int)>('close')(fd);
