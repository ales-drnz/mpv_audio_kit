// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The players on the page's audio output (mpv's webaudio output into the
// AudioContext of the module), never the null output. Two runs:
//
//   test/web/with_net_server.sh --platform chrome --wasm test/web
//       the autoplay policy holds the context, as before any user gesture;
//   CHROME_EXECUTABLE=test/web/chrome_autoplay.sh MAK_CHROME=<chrome> \
//     test/web/with_net_server.sh --platform chrome --wasm \
//     --dart-define=MAK_WEB_AUTOPLAY=true test/web/web_audio_test.dart
//       the context runs, as after one, and the audio is consumed in real
//       time.

@TestOn('browser')
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/web_audio.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

const bool _autoplay = bool.fromEnvironment('MAK_WEB_AUTOPLAY');

/// The page's AudioContext.
Future<JSObject> _context() async =>
    (await loadTestModule()).c.makWebAudio.context!;

/// Frames the worklet has played for output 0 so far, every slot summed.
Future<int> _consumed() async {
  final stats = (await loadTestModule()).c.makWebAudio
      .callMethod<JSArray<JSObject>>('stats'.toJS);
  return stats.toDart.fold<int>(
    0,
    (sum, slot) => sum + (slot['consumed'] as JSNumber).toDartInt,
  );
}

void main() {
  final gestures = <bool>[];
  final trace = <String>[];

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    debugWebAudioTrace = trace.add;
    MpvAudioKit.needsUserGestureStream.listen(gestures.add);
    await loadTestModule();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
    // The module and the output are up once a player is.
    final player = Player();
    await player.ready;
    await player.dispose();
  });

  group('held by the autoplay policy', skip: _autoplay, () {
    test('needsUserGesture says so', () async {
      expect(MpvAudioKit.needsUserGesture, isTrue);
      expect(gestures, [true]);
      expect((await _context())['state'], 'suspended'.toJS);
    });

    test('a player opens the webaudio output, not the null one, and '
        'waits at its position; play asks for a resume', () async {
      final player = Player();
      addTearDown(player.dispose);
      final errors = <PlayerError>[];
      player.stream.error.listen(errors.add);
      await player.ready;
      trace.clear();
      await player.open(Media(testUrl('fixtures/sine_stereo_1s.flac')));
      await player.play();
      expect(trace, contains('resume'));
      await waitUntil(
        () => player.state.audioOutputState == AudioOutputState.active,
        what: 'the output open',
      );
      await waitUntil(() => player.state.currentAo.isNotEmpty, what: 'ao');
      expect(player.state.currentAo, 'webaudio');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(player.state.completed, isFalse);
      expect(
        player.state.position,
        lessThan(const Duration(milliseconds: 300)),
      );
      expect(errors, isEmpty);
    });
  });

  group('playing after a gesture', skip: !_autoplay, () {
    test('needsUserGesture is false', () async {
      expect(MpvAudioKit.needsUserGesture, isFalse);
      expect((await _context())['state'], 'running'.toJS);
    });

    test('a player plays through the worklet in real time', () async {
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      final before = await _consumed();
      final clock = Stopwatch()..start();
      await player.open(
        Media(testUrl('fixtures/sine_stereo_1s.flac')),
        play: true,
      );
      await waitUntil(() => player.state.completed, what: 'the end');
      final seconds = clock.elapsedMilliseconds / 1000;
      expect(player.state.currentAo, 'webaudio');
      expect(seconds, inInclusiveRange(0.9, 3.0));
      final rate = ((await _context())['sampleRate'] as JSNumber).toDartInt;
      expect(await _consumed() - before, greaterThan(rate * 0.8));
    });

    test('through the <audio> element of the media session, too', () async {
      final output = await webAudioOutput();
      output.routeToElement(true);
      addTearDown(() => output.routeToElement(false));
      final element = output.element!;
      expect(element['srcObject'], isNotNull);
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      final before = await _consumed();
      await player.open(
        Media(testUrl('fixtures/sine_stereo_1s.flac')),
        play: true,
      );
      await waitUntil(() => player.state.completed, what: 'the end');
      expect(await _consumed() - before, greaterThan(30000));
      expect((element['paused'] as JSBoolean).toDart, isFalse);
    });
  });

  test('setSystemVolume and setSystemMute before the first file set the '
      "output's gain options", () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setSystemVolume(50);
    await player.setSystemMute(true);
    expect(player.state.systemVolume, 50);
    expect(player.state.systemMute, isTrue);
    expect(double.parse((await player.getRawProperty('webaudio-volume'))!), 50);
    expect(await player.getRawProperty('webaudio-mute'), 'yes');
  });

  test('setAudioSampleRate makes the page output run at that rate', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    trace.clear();
    await player.setAudioSampleRate(32000);
    expect(trace, contains('init 32000'));
    expect(((await _context())['sampleRate'] as JSNumber).toDartInt, 32000);
    await player.setAudioSampleRate(0);
    expect(trace, contains('init 0'));
  });
}
