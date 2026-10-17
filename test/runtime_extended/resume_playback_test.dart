// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = defaultFixturePath();
  runtimeSuite(fixturePath: fx, () {
    test('writeResumeConfig + reopen restores the saved position', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_resume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final cfg = PlayerConfiguration(
        logLevel: LogLevel.off,
        watchLaterDir: tmp.path,
      );

      // Session 1: play in, seek to 0.6s, save the resume point.
      final p1 = await buildPlayer(configuration: cfg);
      await openAndWaitForLoad(p1, fx);
      await p1.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p1.state.position.inMilliseconds > 500);
      await p1.writeResumeConfig();
      await waitUntil(() => tmp.listSync().isNotEmpty);
      expect(
        tmp.listSync(),
        isNotEmpty,
        reason: 'a watch-later config file is written into watchLaterDir',
      );
      await p1.dispose();

      // Session 2: reopen the SAME file → mpv restores ~0.6s during load.
      final p2 = await buildPlayer(configuration: cfg);
      addTearDown(p2.dispose);
      final resumed = p2.stream.position
          .firstWhere((x) => x.inMilliseconds > 400)
          .timeout(const Duration(seconds: 8));
      await p2.open(Media(fx), play: false);
      final pos = await resumed;
      expect(
        pos.inMilliseconds,
        greaterThan(400),
        reason: 'resume-playback restored the position from the saved config',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('deleteResumeConfig clears the saved resume point', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_delresume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final cfg = PlayerConfiguration(
        logLevel: LogLevel.off,
        watchLaterDir: tmp.path,
      );

      final p = await buildPlayer(configuration: cfg);
      addTearDown(p.dispose);
      await openAndWaitForLoad(p, fx);
      await p.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p.state.position.inMilliseconds > 500);

      // Write a resume point, confirm it lands...
      await p.writeResumeConfig();
      await waitUntil(() => tmp.listSync().isNotEmpty);
      expect(
        tmp.listSync(),
        isNotEmpty,
        reason: 'precondition: a watch-later config exists to delete',
      );

      // ...then delete it for the current file and confirm it is gone.
      await p.deleteResumeConfig();
      await waitUntil(() => tmp.listSync().isEmpty);
      expect(
        tmp.listSync(),
        isEmpty,
        reason: 'deleteResumeConfig removed the current file\'s resume config',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('deleteResumeConfig takes the file:// URL the file was opened '
        'with', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_delresume_url_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final p = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      addTearDown(p.dispose);
      final url = Uri.file(fx).toString();
      await openAndWaitForLoad(p, url);
      await p.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p.state.position.inMilliseconds > 500);
      await p.writeResumeConfig();
      await waitUntil(() => tmp.listSync().isNotEmpty);

      await p.deleteResumeConfig(filename: url);
      await waitUntil(
        () => tmp.listSync().isEmpty,
        reason: 'the resume point of the file opened by URL is gone',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('deleteResumeConfig takes the asset:// URI the file was opened '
        'with', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_delresume_asset_');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final bytes = File(fx).readAsBytesSync();
      messenger.setMockMessageHandler(
        'flutter/assets',
        (_) async => ByteData.sublistView(bytes),
      );
      addTearDown(() {
        messenger.setMockMessageHandler('flutter/assets', null);
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final p = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      addTearDown(p.dispose);
      const asset = 'asset:///assets/resume_delete.wav';
      await openAndWaitForLoad(p, asset);
      await p.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p.state.position.inMilliseconds > 500);
      await p.writeResumeConfig();
      await waitUntil(() => tmp.listSync().isNotEmpty);

      await p.deleteResumeConfig(filename: asset);
      await waitUntil(
        () => tmp.listSync().isEmpty,
        reason: 'the resume point of the asset copy is gone',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));

    group(
      'an fd:// entry',
      skip: Platform.isWindows ? 'POSIX descriptors' : false,
      () {
        // mpv keys its resume point by the descriptor number, which the
        // system hands out again to the next file opened (Android content://
        // URIs load as fd://N).
        test('writeResumeConfig saves nothing for it', () async {
          final tmp = Directory.systemTemp.createTempSync('mak_resume_fdw_');
          addTearDown(() {
            try {
              tmp.deleteSync(recursive: true);
            } catch (_) {}
          });
          final fd = _openFd(fx);
          addTearDown(() => _closeFd(fd));
          final p = await buildPlayer(
            configuration: PlayerConfiguration(
              logLevel: LogLevel.off,
              watchLaterDir: tmp.path,
            ),
          );
          addTearDown(p.dispose);
          await openAndWaitForLoad(p, 'fd://$fd');
          await p.seek(const Duration(milliseconds: 600));
          await waitUntil(() => p.state.position.inMilliseconds > 500);
          final logged = p.stream.internalLog
              .firstWhere((e) => e.text.contains('fd://$fd'))
              .timeout(const Duration(seconds: 5));
          await p.writeResumeConfig();
          await Future<void>.delayed(const Duration(milliseconds: 300));
          expect(tmp.listSync(), isEmpty, reason: 'no resume point written');
          await logged;
        }, timeout: const Timeout(Duration(seconds: 30)));

        test('does not take a resume point saved under its number', () async {
          final tmp = Directory.systemTemp.createTempSync('mak_resume_fdr_');
          addTearDown(() {
            try {
              tmp.deleteSync(recursive: true);
            } catch (_) {}
          });
          final fd = _openFd(fx);
          addTearDown(() => _closeFd(fd));
          // As 0.5.1 wrote it for whatever file had this number before.
          final key = 'fd://$fd';
          final stale = File(
            '${tmp.path}/${md5.convert(utf8.encode(key)).toString().toUpperCase()}',
          )..writeAsStringSync('start=0.600000\n');
          final p = await buildPlayer(
            configuration: PlayerConfiguration(
              logLevel: LogLevel.off,
              watchLaterDir: tmp.path,
            ),
          );
          addTearDown(p.dispose);
          await openAndWaitForLoad(p, key);
          expect(
            p.state.position.inMilliseconds,
            lessThan(300),
            reason: 'the file starts from its beginning',
          );
          expect(stale.existsSync(), isFalse);
        }, timeout: const Timeout(Duration(seconds: 30)));
      },
    );

    test('the resume point does not save the effects chain', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_resume_af_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final p = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      addTearDown(p.dispose);
      await p.setAudioEffects(const [
        EqualizerEffect(frequency: 1000, width: 200, gain: 12),
      ]);
      await openAndWaitForLoad(p, fx);
      await p.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p.state.position.inMilliseconds > 500);
      await p.writeResumeConfig();
      final saved = _resumeFile(tmp);
      expect(saved.readAsStringSync(), contains('start='));
      // The chain belongs to the player's state: saved with the file, it
      // came back on a later load without the state knowing.
      expect(saved.readAsStringSync(), isNot(contains('af=')));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('a chain restored from an older resume point gives way to the '
        "player's own", () async {
      final tmp = Directory.systemTemp.createTempSync('mak_resume_oldaf_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final p = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      addTearDown(p.dispose);
      await p.setAudioEffects(const [
        EqualizerEffect(frequency: 1000, width: 200, gain: 12),
      ]);
      final restored = (await p.getRawProperty('af'))!;
      await openAndWaitForLoad(p, fx);
      await p.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p.state.position.inMilliseconds > 500);
      await p.writeResumeConfig();
      // A resume point written by 0.5.1 or earlier also held the chain.
      _resumeFile(tmp).writeAsStringSync(
        'af=%${restored.length}%$restored\n',
        mode: FileMode.append,
      );

      // The player's chain is empty now: the load must not bring the
      // saved equalizer back behind the state.
      await p.setAudioEffects(const []);
      await openAndWaitForLoad(p, fx);
      expect(
        p.state.position.inMilliseconds,
        greaterThan(400),
        reason: 'precondition: the resume point applied',
      );
      await waitUntil(
        () async => await p.getRawProperty('af') == '',
        reason: 'the empty chain of the state plays, not the saved one',
      );

      // Same shape, other values: the state's values play.
      await p.setAudioEffects(const [
        EqualizerEffect(frequency: 1000, width: 200, gain: -6),
      ]);
      final mine = (await p.getRawProperty('af'))!;
      expect(mine, isNot(restored));
      await openAndWaitForLoad(p, fx);
      await waitUntil(
        () async => await p.getRawProperty('af') == mine,
        reason: "the state's equalizer plays, not the saved one",
      );
      expect(p.state.audioEffects, const [
        EqualizerEffect(frequency: 1000, width: 200, gain: -6),
      ]);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('resumePlayback=false does NOT restore position', () async {
      final tmp = Directory.systemTemp.createTempSync('mak_noresume_');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });

      // Write a resume point with resume ON...
      final p1 = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
        ),
      );
      await openAndWaitForLoad(p1, fx);
      await p1.seek(const Duration(milliseconds: 600));
      await waitUntil(() => p1.state.position.inMilliseconds > 500);
      await p1.writeResumeConfig();
      await waitUntil(() => tmp.listSync().isNotEmpty);
      await p1.dispose();

      // ...but reopen with resume OFF → starts at 0.
      final p2 = await buildPlayer(
        configuration: PlayerConfiguration(
          logLevel: LogLevel.off,
          watchLaterDir: tmp.path,
          resumePlayback: false,
        ),
      );
      addTearDown(p2.dispose);
      await openAndWaitForLoad(p2, fx);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(
        p2.state.position.inMilliseconds,
        lessThan(300),
        reason: 'with resumePlayback:false playback starts from the beginning',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}

/// The resume file of the one file saved in [dir]: mpv also writes a
/// redirect entry for each parent directory.
File _resumeFile(Directory dir) => dir.listSync().whereType<File>().singleWhere(
  (f) => !f.readAsStringSync().contains('# redirect entry'),
);

/// A descriptor of [path] opened read-only with libc's `open`.
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
