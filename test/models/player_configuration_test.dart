// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

void main() {
  group('PlayerConfiguration defaults', () {
    test('autoPlay defaults to false', () {
      const c = PlayerConfiguration();
      expect(c.autoPlay, isFalse);
    });

    test('initialVolume defaults to 100', () {
      const c = PlayerConfiguration();
      expect(c.initialVolume, 100.0);
    });

    test('logLevel defaults to warn', () {
      const c = PlayerConfiguration();
      expect(c.logLevel, 'warn');
    });

    test('audioClientName defaults to null', () {
      const c = PlayerConfiguration();
      expect(c.audioClientName, isNull);
    });

    test('processCoverArt defaults to true (cover-art pipeline opt-in)', () {
      // Regression test for the 0.1.0 breaking-change addition: the
      // default must remain `true` so existing apps that relied on
      // implicit PNG generation in `playlist.medias[i].extras` keep
      // working without code changes.
      const c = PlayerConfiguration();
      expect(c.processCoverArt, isTrue);
    });
  });

  group('PlayerConfiguration full-field construction', () {
    test('all fields can be overridden', () {
      const c = PlayerConfiguration(
        autoPlay: true,
        initialVolume: 50.0,
        logLevel: 'debug',
        audioClientName: 'TestApp',
        processCoverArt: false,
      );
      expect(c.autoPlay, isTrue);
      expect(c.initialVolume, 50.0);
      expect(c.logLevel, 'debug');
      expect(c.audioClientName, 'TestApp');
      expect(c.processCoverArt, isFalse);
    });
  });
}
