// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('browser')
library;

import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import 'web_module_helper.dart';

Future<void> waitFor(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
  });

  test('a player starts on the web module and reads its version', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    final version = await player.getRawProperty('mpv-version');
    expect(version, startsWith('mpv v0.41.0'));
  });

  test(
    'an http file of the page loads, with duration and audio params',
    () async {
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      await player.setRawProperty('ao', 'null');
      await player.open(Media(testUrl('fixtures/sine_5s.flac')), play: false);
      await waitFor(() => player.state.duration > Duration.zero);
      expect(player.state.duration.inMilliseconds, closeTo(5000, 50));
      expect(player.state.audioParams.sampleRate, greaterThan(0));
    },
  );

  test('a live PCM source plays to its end through the module', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setRawProperty('ao', 'null');
    // The module is loaded once a player is ready: the input lives in it.
    const format = PcmFormat(sampleRate: 48000, channels: 1);
    final source = PcmSource.create(format);
    final tone = Int16List(48000 ~/ 2);
    for (var i = 0; i < tone.length; i++) {
      tone[i] = (8000 * math.sin(2 * math.pi * 440 * i / 48000)).round();
    }
    source.add(tone.buffer.asUint8List());
    await source.close();
    await player.open(source.toMedia(), play: true);
    await waitFor(() => player.state.completed);
    expect(player.state.audioParams.sampleRate, 48000);
  });
}
