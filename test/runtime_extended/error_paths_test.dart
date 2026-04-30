// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux')
library;

import 'dart:async';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  String? resolveLibmpv() {
    final root = Directory.current.path;
    if (Platform.isMacOS) {
      final p = '$root/macos/libs/libmpv.dylib';
      return File(p).existsSync() ? p : null;
    }
    if (Platform.isLinux) {
      final p = '$root/linux/libs/libmpv.so';
      return File(p).existsSync() ? p : null;
    }
    return null;
  }

  setUpAll(() {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);
  });

  group('Error paths — loadfile failures and endFile reasons', () {
    late Player player;

    setUpAll(() async {
      player = Player(
          configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'no',
      ));
      await player.setRawProperty('ao', 'null');
    });

    tearDownAll(() async {
      await player.stop();
      await player.clearPlaylist();
      await player.dispose();
    });

    test('opening a non-existent file emits MpvFileEndedEvent.error',
        () async {
      final endFileEvents = <MpvFileEndedEvent>[];
      final completer = Completer<MpvFileEndedEvent>();
      final sub = player.stream.endFile.listen((event) {
        endFileEvents.add(event);
        if (!completer.isCompleted) completer.complete(event);
      });

      try {
        await player.open(
          Media('/tmp/this-file-does-not-exist.flac'),
          play: false,
        );
        final event = await completer.future
            .timeout(const Duration(seconds: 5));
        expect(event.reason, MpvEndFileReason.error,
            reason: 'mpv reports loadfile failure as endFile.error');
        expect(event.error, lessThan(0),
            reason: 'errored end-file carries a negative mpv error code');
        expect(event.reachedNaturalEnd, isFalse);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('opening a malformed URL also reports endFile error', () async {
      final completer = Completer<MpvFileEndedEvent>();
      final sub = player.stream.endFile.listen((event) {
        if (event.reason == MpvEndFileReason.error &&
            !completer.isCompleted) {
          completer.complete(event);
        }
      });

      try {
        await player.open(
          Media('totally-not-a-valid-url://??'),
          play: false,
        );
        final event = await completer.future
            .timeout(const Duration(seconds: 5));
        expect(event.reason, MpvEndFileReason.error);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('error event also surfaces on Player.stream.error as MpvEndFileError',
        () async {
      // Subscribe to the typed error stream so we can assert the
      // sealed-union mapping (endFile.error → MpvEndFileError on the
      // error stream).
      final completer = Completer<MpvPlayerError>();
      final sub = player.stream.error.listen((err) {
        if (err is MpvEndFileError && !completer.isCompleted) {
          completer.complete(err);
        }
      });

      try {
        await player.open(Media('/tmp/another-missing-file.flac'),
            play: false);
        final err = await completer.future
            .timeout(const Duration(seconds: 5));
        expect(err, isA<MpvEndFileError>());
        final endErr = err as MpvEndFileError;
        expect(endErr.reason, MpvEndFileReason.error);
        expect(endErr.code, lessThan(0));
        expect(endErr.message, isNotEmpty);
      } finally {
        await sub.cancel();
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('MpvEndFileReason.fromValue exhaustively maps all 5 raw codes', () {
      // Pure sanity test for the enum's value-mapping. The five mpv
      // EndFile reasons are documented constants; if any drifts, the
      // wrapper-side parse would silently fall back to eof.
      expect(MpvEndFileReason.fromValue(0), MpvEndFileReason.eof);
      expect(MpvEndFileReason.fromValue(2), MpvEndFileReason.stop);
      expect(MpvEndFileReason.fromValue(3), MpvEndFileReason.quit);
      expect(MpvEndFileReason.fromValue(4), MpvEndFileReason.error);
      expect(MpvEndFileReason.fromValue(5), MpvEndFileReason.redirect);
      // Forward-compat: unknown raw → eof (defensive fallback).
      expect(MpvEndFileReason.fromValue(999), MpvEndFileReason.eof);
    });
  });
}
