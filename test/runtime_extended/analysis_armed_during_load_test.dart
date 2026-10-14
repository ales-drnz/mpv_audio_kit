// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

// The waveform or the loudness scan armed while mpv is still opening a
// remote file must not open it a second time (#22). An app that mounts its
// waveform view on the first playlist event after `open` arms the analysis
// in that window: the setter used to start the scan before mpv had a
// demuxer, so the analysis could not tell an HTTP file or an HLS stream
// from a local one and opened the URL beside the player's own open. For an
// HTTP file that was a second download; for a Jellyfin HLS transcode the
// second open restarted the transcode and the player's open failed. The
// scan now starts when the file is loaded, from mpv's own classification.
//
// The loopback server (test/_helpers/range_http_server.dart) holds every
// answer until the test has armed the analysis, so the setter always lands
// while the open is in flight, and logs every request.

@TestOn('linux || mac-os || windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/range_http_server.dart';
import '../_helpers/setter_test_helpers.dart';

/// The `state` of the native analysis node [name] (`waveform-data` or
/// `loudness-scan-data`), or `null` when there is none.
Future<String?> _state(Player player, String name) async {
  final node = await player.getRawPropertyNode(name);
  return node is Map ? node['state'] as String? : null;
}

/// An HLS stream of ADTS AAC segments: [master] points at [media], which
/// lists [segments] copies of [adts] as `seg<i>.aac`.
Map<String, Uint8List> _hls(Uint8List adts, {int segments = 6}) {
  // Each copy of the fixture is a whole number of ADTS frames.
  final seconds = 1024 * _adtsFrames(adts) / 44100;
  final media = StringBuffer()
    ..writeln('#EXTM3U')
    ..writeln('#EXT-X-VERSION:3')
    ..writeln('#EXT-X-TARGETDURATION:2')
    ..writeln('#EXT-X-MEDIA-SEQUENCE:0')
    ..writeln('#EXT-X-PLAYLIST-TYPE:VOD');
  for (var i = 0; i < segments; i++) {
    media
      ..writeln('#EXTINF:${seconds.toStringAsFixed(6)},')
      ..writeln('seg$i.aac');
  }
  media.writeln('#EXT-X-ENDLIST');
  const master =
      '#EXTM3U\n'
      '#EXT-X-STREAM-INF:BANDWIDTH=140000,CODECS="mp4a.40.2"\n'
      'media.m3u8\n';
  return {
    'master.m3u8': Uint8List.fromList(utf8.encode(master)),
    'media.m3u8': Uint8List.fromList(utf8.encode(media.toString())),
    for (var i = 0; i < segments; i++) 'seg$i.aac': adts,
  };
}

/// The number of ADTS frames in [b].
int _adtsFrames(Uint8List b) {
  var n = 0;
  for (var i = 0; i + 6 < b.length; n++) {
    if (b[i] != 0xFF || (b[i + 1] & 0xF0) != 0xF0) {
      throw StateError('not an ADTS frame at byte $i');
    }
    i += ((b[i + 3] & 0x03) << 11) | (b[i + 4] << 3) | (b[i + 5] >> 5);
  }
  return n;
}

void main() {
  final fixtures = '${Directory.current.path}/test/fixtures';
  final flacPath = '$fixtures/sine_stereo_48k_5s.flac';
  final mp3Path = '$fixtures/codec/mp3_44100_stereo.mp3';
  final aacPath = '$fixtures/codec/aac_adts_44100.aac';

  analysisSuite(extraFixtures: [flacPath, mp3Path, aacPath], () {
    const flacName = 'sine_stereo_48k_5s.flac';
    const mp3Name = 'mp3_44100_stereo.mp3';
    late Map<String, Uint8List> files;
    late RangeHttpServer server;
    late Completer<void> release;
    Player? player;
    final subs = <StreamSubscription<Object?>>[];

    setUpAll(() async {
      files = {
        flacName: await File(flacPath).readAsBytes(),
        mp3Name: await File(mp3Path).readAsBytes(),
        ..._hls(await File(aacPath).readAsBytes()),
      };
    });

    setUp(() async {
      server = await RangeHttpServer.start(files);
      release = Completer<void>();
      player = await buildPlayer();
    });

    tearDown(() async {
      if (!release.isCompleted) release.complete();
      if (Platform.environment['MAK_HTTP_LOG'] != null) {
        // ignore: avoid_print
        print(server.describe());
      }
      for (final s in subs) {
        await s.cancel();
      }
      subs.clear();
      await player?.dispose();
      player = null;
      await server.close();
    });

    String log() => server.describe();

    /// Polls [condition] like [waitUntil], with the request log in the
    /// failure message.
    Future<void> waitFor(
      FutureOr<bool> Function() condition,
      String what, {
      Duration timeout = const Duration(seconds: 20),
    }) async {
      final deadline = DateTime.now().add(timeout);
      while (!await condition()) {
        if (DateTime.now().isAfter(deadline)) {
          fail('$what within $timeout\n${log()}');
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }

    /// Opens [name] with every answer held, runs [arm] on the first
    /// playlist event (as an app mounting its waveform view does), waits
    /// until mpv reports the analysis flags it set while the file is still
    /// opening, runs [beforeRelease], and lets the server answer.
    Future<void> openArmedDuringLoad(
      String name,
      void Function(Player p) arm, {
      required List<String> flags,
      Future<void> Function(Player p)? beforeRelease,
    }) async {
      final p = player!;
      server.hold = release.future;
      final armed = Completer<void>();
      late StreamSubscription<Playlist> playlist;
      playlist = p.stream.playlist.listen((pl) {
        if (pl.items.isEmpty || armed.isCompleted) return;
        arm(p);
        armed.complete();
        unawaited(playlist.cancel());
      });
      subs.add(playlist);
      await p.open(Media(server.url(name)), play: true);
      await armed.future.timeout(const Duration(seconds: 10));
      for (final f in flags) {
        await waitFor(
          () async => await p.getRawProperty(f) == 'yes',
          '$f did not turn on',
        );
      }
      expect(
        await p.getRawProperty('time-pos'),
        isNull,
        reason: 'the analysis must be armed before the file is loaded',
      );
      if (beforeRelease != null) await beforeRelease(p);
      server.hold = null;
      release.complete();
    }

    /// Waits for the waveform and the loudness scan to settle as [wave]
    /// and [loudness].
    Future<void> settle(String wave, String loudness) => waitFor(
      () async =>
          await _state(player!, 'waveform-data') == wave &&
          await _state(player!, 'loudness-scan-data') == loudness,
      'the analysis did not settle as $wave and $loudness',
    );

    /// The GETs of [name] that start at byte 0: mpv's own open, then one
    /// per time the analysis opened the file again.
    int fromStart(String name) =>
        server.gets('/$name').where((r) => r.start == 0).length;

    for (final name in [flacName, mp3Name]) {
      test('$name: a waveform armed during the load reads the cache, '
          'one GET', () async {
        // The app's order: the loudness scan has a listener from launch,
        // the waveform view mounts once the playlist has an entry.
        subs.add(player!.stream.loudnessScan.listen((_) {}));
        await openArmedDuringLoad(
          name,
          (p) => subs.add(p.stream.waveform.listen((_) {})),
          flags: ['waveform-enabled'],
        );
        await settle('ready', 'ready');
        expect(
          fromStart(name),
          1,
          reason: 'the analysis must not open the URL a second time\n${log()}',
        );
      });
    }

    test('both analyses armed during the load start at file loaded', () async {
      await openArmedDuringLoad(
        flacName,
        (p) => subs
          ..add(p.stream.loudnessScan.listen((_) {}))
          ..add(p.stream.waveform.listen((_) {})),
        flags: ['waveform-enabled', 'loudness-scan-enabled'],
      );
      await settle('ready', 'ready');
      expect(fromStart(flacName), 1, reason: log());
    });

    test('a waveform armed and disarmed during the load stays off', () async {
      StreamSubscription<Object?>? wave;
      await openArmedDuringLoad(
        flacName,
        (p) => wave = p.stream.waveform.listen((_) {}),
        flags: ['waveform-enabled'],
        beforeRelease: (p) async {
          await wave!.cancel();
          await waitFor(
            () async => await p.getRawProperty('waveform-enabled') == 'no',
            'waveform-enabled did not turn off',
          );
        },
      );
      await waitFor(
        () async => await player!.getRawProperty('time-pos') != null,
        'the file did not load',
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(await _state(player!, 'waveform-data'), 'idle', reason: log());
      expect(fromStart(flacName), 1, reason: log());
    });

    test('an HLS stream armed during the load is opened once', () async {
      // The reference: the same stream played with no analysis.
      final ref = await buildPlayer();
      int masters = 0, medias = 0;
      try {
        await ref.open(Media(server.url('master.m3u8')), play: true);
        await waitFor(
          () async => await ref.getRawProperty('time-pos') != null,
          'the reference did not load',
        );
        await Future<void>.delayed(const Duration(milliseconds: 500));
        masters = server.gets('/master.m3u8').length;
        medias = server.gets('/media.m3u8').length;
      } finally {
        await ref.dispose();
      }
      await server.close();
      server = await RangeHttpServer.start(files);

      await openArmedDuringLoad(
        'master.m3u8',
        (p) => subs
          ..add(p.stream.loudnessScan.listen((_) {}))
          ..add(p.stream.waveform.listen((_) {})),
        flags: ['waveform-enabled', 'loudness-scan-enabled'],
      );
      // A stream that cannot be decoded up front grows its envelope with
      // playback and has no integrated loudness.
      await settle('progressive', 'unavailable');
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(
        server.gets('/master.m3u8').length,
        masters,
        reason: 'the master playlist, as with no analysis\n${log()}',
      );
      expect(
        server.gets('/media.m3u8').length,
        medias,
        reason: 'the media playlist, as with no analysis\n${log()}',
      );
    });
  });
}
