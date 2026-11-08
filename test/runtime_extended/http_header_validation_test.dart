// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  // Per-track HTTP headers reach mpv via the `loadfile` 4th-arg
  // file-local-options string. The outer `%N%` length-prefix only
  // protects the loadfile option-list parser; it does NOT prevent
  // mpv's inner `http-header-fields` string-list parser from
  // splitting on `,`, nor does it prevent ffmpeg's HTTP demuxer from
  // sending CR/LF bytes verbatim. So the wrapper must validate
  // header keys and values before they reach mpv.
  //
  // These tests assert the validation rejects any input that would
  // either inject (`\r`, `\n`) or silently misbehave (`,`).
  final fixturePath = defaultFixturePath();

  runtimeSuite(fixturePath: fixturePath, () {
    group('Media.httpHeaders validation', () {
      late Player player;

      setUpAll(() async {
        player = await buildPlayer();
      });

      tearDownAll(() async {
        await player.dispose();
      });

      test(
        'CRLF in a value is rejected (HTTP header injection vector)',
        () async {
          await expectLater(
            player.open(
              Media(
                fixturePath,
                httpHeaders: const {
                  'X-Token': 'safe\r\nAuthorization: bearer evil',
                },
              ),
              play: false,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test('Bare LF in a value is rejected', () async {
        await expectLater(
          player.open(
            Media(
              fixturePath,
              httpHeaders: const {'X-Token': 'first\nSecond: line'},
            ),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'Comma in a value is rejected (would split into two headers)',
        () async {
          await expectLater(
            player.open(
              Media(
                fixturePath,
                httpHeaders: const {
                  // Looks like a legit Accept value but the comma triggers
                  // mpv's stringlist split; reject up front.
                  'Accept': 'text/html, application/json',
                },
              ),
              play: false,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test('CRLF in a key is rejected', () async {
        await expectLater(
          player.open(
            Media(
              fixturePath,
              httpHeaders: const {'X-Token\r\nInjected': 'value'},
            ),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Colon in a key is rejected (ambiguous boundary)', () async {
        await expectLater(
          player.open(
            Media(fixturePath, httpHeaders: const {'X:Token': 'value'}),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NUL byte in a value is rejected (truncates the C string '
          'mpv hands to ffmpeg)', () async {
        await expectLater(
          player.open(
            Media(
              fixturePath,
              httpHeaders: const {'X-Token': 'visible\x00hidden'},
            ),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('NUL byte in a key is rejected', () async {
        await expectLater(
          player.open(
            Media(
              fixturePath,
              httpHeaders: const {'X-Token\x00Smuggled': 'value'},
            ),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('Empty key is rejected', () async {
        await expectLater(
          player.open(
            Media(fixturePath, httpHeaders: const {'': 'value'}),
            play: false,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('add() validates the same set of constraints as open()', () async {
        await expectLater(
          player.add(
            Media(
              fixturePath,
              httpHeaders: const {'Authorization': 'a\r\nInjected: b'},
            ),
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      // Pins H1: rejected add() must not append to the playlist.
      test('rejected add() leaves player state untouched', () async {
        final before = player.state.playback.playlist.items.length;
        await expectLater(
          player.add(
            Media(fixturePath, httpHeaders: const {'Bad-Key,With-Comma': 'v'}),
          ),
          throwsA(isA<ArgumentError>()),
        );
        expect(player.state.playback.playlist.items.length, before);
        await player.add(Media(fixturePath));
      });

      test(
        'legitimate headers (no forbidden chars) load successfully',
        () async {
          // Sanity: validation must not break the happy path. mpv may or
          // may not actually reach the file — we only care that no
          // ArgumentError is thrown synchronously by the wrapper.
          await player.open(
            Media(
              fixturePath,
              httpHeaders: const {
                'X-Token': 'leak-canary-12345',
                'User-Agent': 'mpv_audio_kit/test',
              },
            ),
            play: false,
          );
          // Wait until mpv has actually processed the loadfile so the
          // validation we just exercised has been fully consumed.
          await player.stream.seekCompleted.first.timeout(
            const Duration(seconds: 5),
          );
        },
      );
    });
  });
}
