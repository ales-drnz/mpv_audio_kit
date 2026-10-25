// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// MPRIS2 on the real session bus (Linux). The test reads the player's
// entry with gdbus, as a desktop shell does, and drives the player with the
// shell's commands: Play, Pause, Seek and SetPosition go from the bus
// through linux/mpris_server.cc and the event channel to the Player, and
// the test waits for their effect on player.stream.
//
// It needs a session bus and gdbus (libglib2.0-bin):
//   dbus-run-session -- flutter test integration_test/linux_mpris_test.dart -d linux
// CI runs it in the Build Linux job of ci.yml, under xvfb-run.

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '_helpers/asset_fixture.dart';
import '_helpers/cover_file.dart';
import '_helpers/mpris_bus.dart';

const _appName = 'Mak CI';

/// Reads the bus with [read] until [ok] holds, and returns that value.
/// A read that fails (the name not owned yet) counts as not ok.
Future<T> eventually<T>(
  Future<T> Function() read,
  bool Function(T) ok, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  Object? last;
  while (true) {
    try {
      final value = await read();
      if (ok(value)) return value;
      last = value;
    } on ProcessException catch (e) {
      last = e.message;
    }
    if (DateTime.now().isAfter(deadline)) {
      fail('The bus never satisfied the predicate. Last: $last');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  final bus = MprisBus.of(_appName, pid);
  const session = MediaSession(appName: _appName);

  group('MPRIS on the session bus', () {
    late Player player;
    HttpServer? server;

    setUp(() async {
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.off),
      );
      await player.setRawProperty('ao', 'null');
    });

    tearDown(() async {
      await player.setMediaSession(null);
      await player.stop();
      await player.dispose();
      await server?.close(force: true);
      server = null;
    });

    Future<Map<String, Object?>> metadataWhere(
      bool Function(Map<String, Object?>) ok,
    ) => eventually(bus.metadata, ok);

    testWidgets('a local file publishes its tags, length, cover and url', (
      _,
    ) async {
      final tagged = await materializeFixture('tagged.m4a');
      await player.setMediaSession(session);
      await player.open(Media(tagged), play: false);

      final meta = await metadataWhere(
        (m) => m['xesam:title'] == 'Tagged Title' && m['mpris:artUrl'] != null,
      );
      expect(meta['xesam:artist'], ['Tagged Artist']);
      expect(meta['xesam:album'], 'Tagged Album');
      expect(meta['mpris:length'] as int, greaterThan(1500000));
      expect(
        meta['mpris:trackid'] as String,
        startsWith('/org/mpris/MediaPlayer2/Track/'),
      );
      // The embedded cover, written to this process's runtime directory.
      final art = Uri.parse(meta['mpris:artUrl'] as String);
      expect(art.scheme, 'file');
      expect(art.path, contains('/mpv_audio_kit/$pid/art-'));
      expect(File.fromUri(art).existsSync(), isTrue, reason: '$art');
      // xesam:url is a URI, not the bare path the Media was opened with.
      expect(meta['xesam:url'], Uri.file(tagged).toString());

      expect(await bus.playbackStatus(), 'Paused');
      expect(await bus.property(MprisBus.rootIface, 'Identity'), _appName);
    }, skip: !Platform.isLinux);

    testWidgets('a network URL keeps its credentials off the bus', (_) async {
      final song = await File(
        await materializeFixture('with_chapters.mka'),
      ).readAsBytes();
      final srv = server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      srv.listen((request) {
        final cover = request.uri.path == '/cover.png';
        request.response
          ..headers.contentType = cover
              ? ContentType('image', 'png')
              : ContentType('audio', 'x-matroska')
          ..add(cover ? onePixelPng : song);
        unawaited(request.response.close());
      });
      final base = 'http://127.0.0.1:${srv.port}';

      await player.setMediaSession(session);
      await player.open(
        Media(
          '$base/song.mka?api_key=secret',
          extras: {'art': '$base/cover.png?api_key=secret'},
        ),
        play: false,
      );

      // The cover is downloaded by the package and published from a file:
      // the URL, credentials and all, never reaches the bus.
      final meta = await metadataWhere(
        (m) => m['xesam:title'] != null && m['mpris:artUrl'] != null,
      );
      expect(meta['xesam:title'], 'mpv_audio_kit chapter test');
      expect(Uri.parse(meta['mpris:artUrl'] as String).scheme, 'file');
      expect(meta.containsKey('xesam:url'), isFalse, reason: '$meta');
      expect('$meta', isNot(contains('secret')));
    }, skip: !Platform.isLinux);

    testWidgets('a file:// cover is published from a copy of its own', (
      _,
    ) async {
      final fixture = await materializeFixture('with_chapters.mka');
      final cover = await coverFileUrl();
      await player.setMediaSession(session);
      await player.open(Media(fixture, extras: {'art': cover}), play: false);

      // Read by the package and written to the runtime directory, as an
      // embedded cover is: the bus never names the user's file.
      final meta = await metadataWhere((m) => m['mpris:artUrl'] != null);
      final art = Uri.parse(meta['mpris:artUrl'] as String);
      expect(art.toString(), isNot(cover));
      expect(art.path, contains('/mpv_audio_kit/$pid/art-'));
      expect(File.fromUri(art).readAsBytesSync(), onePixelPng);
    }, skip: !Platform.isLinux);

    testWidgets('Play and Pause from the bus reach the player', (_) async {
      final fixture = await materializeFixture('with_chapters.mka');
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(session);
      await eventually(bus.playbackStatus, (s) => s == 'Paused');

      final playing = player.stream.playing.firstWhere((p) => p);
      await bus.call('Play');
      await playing.timeout(const Duration(seconds: 5));
      expect(player.state.playWhenReady, isTrue);
      await eventually(bus.playbackStatus, (s) => s == 'Playing');

      final paused = player.stream.playWhenReady.firstWhere((p) => !p);
      await bus.call('Pause');
      await paused.timeout(const Duration(seconds: 5));
      await eventually(bus.playbackStatus, (s) => s == 'Paused');
    }, skip: !Platform.isLinux);

    testWidgets('SetPosition and Seek from the bus move the player', (_) async {
      final fixture = await materializeFixture('with_chapters.mka');
      await player.open(Media(fixture), play: false);
      await player.stream.duration
          .firstWhere((d) => d.inMilliseconds > 2500)
          .timeout(const Duration(seconds: 10));
      await player.setMediaSession(session);
      await eventually(
        () => bus.property(MprisBus.playerIface, 'CanSeek'),
        (v) => v == true,
      );
      final loaded = await metadataWhere((m) => m['mpris:trackid'] != null);
      final track = loaded['mpris:trackid'] as String;

      // seekCompleted is an event stream: subscribed before the command,
      // it fires for this seek only.
      var landed = player.stream.seekCompleted.first;
      await bus.call('SetPosition', ["objectpath '$track'", 'int64 1500000']);
      await landed.timeout(const Duration(seconds: 5));
      expect(
        player.state.position.inMilliseconds,
        inInclusiveRange(1400, 1600),
      );
      // The landing goes back to the bus: paused, Position is exact.
      final position = await eventually(
        () => bus.property(MprisBus.playerIface, 'Position'),
        (v) => (v as int) >= 1400000,
      );
      expect(position as int, lessThanOrEqualTo(1600000));

      landed = player.stream.seekCompleted.first;
      await bus.call('Seek', ['int64 -1000000']);
      await landed.timeout(const Duration(seconds: 5));
      expect(player.state.position.inMilliseconds, lessThan(1000));
    }, skip: !Platform.isLinux);

    testWidgets('disable takes the name off the bus', (_) async {
      final fixture = await materializeFixture('with_chapters.mka');
      await player.open(Media(fixture), play: false);
      await player.setMediaSession(session);
      await eventually(bus.hasOwner, (owned) => owned);

      await player.setMediaSession(null);
      await eventually(bus.hasOwner, (owned) => !owned);
    }, skip: !Platform.isLinux);
  });
}
