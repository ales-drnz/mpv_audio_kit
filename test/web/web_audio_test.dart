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

import 'dart:ui_web' as ui_web;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/web_audio.dart';
import 'package:mpv_audio_kit/src/backend/web_backend.dart';
import 'package:mpv_audio_kit/src/media_session/media_session_channel.dart';
import 'package:mpv_audio_kit/src/web/mpv_audio_kit_web.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

const bool _autoplay = bool.fromEnvironment('MAK_WEB_AUTOPLAY');

@JS('document')
external JSObject get _document;

@JS('Event')
extension type _Event._(JSObject _) implements JSObject {
  external _Event(String type);
}

JSObject _event(String type) => _Event(type);

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
    // The media session's plugin, for the outside pauses: platform
    // messages delivered as in web_media_session_test.dart.
    ui_web.TestEnvironment.setUp(
      const ui_web.TestEnvironment(
        forceTestFonts: true,
        disableFontFallbacks: true,
        keepSemanticsDisabledOnUpdate: true,
        defaultToTestUrlStrategy: true,
      ),
    );
    MpvAudioKitWeb.registerWith(webPluginRegistrar);
    webPluginRegistrar.registerMessageHandler();
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
        () => player.state.output.audioOutputState == AudioOutputState.active,
        what: 'the output open',
      );
      await waitUntil(
        () => player.state.output.currentAo.isNotEmpty,
        what: 'ao',
      );
      expect(player.state.output.currentAo, 'webaudio');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      expect(player.state.playback.completed, isFalse);
      expect(
        player.state.playback.position,
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
      await waitUntil(() => player.state.playback.completed, what: 'the end');
      final seconds = clock.elapsedMilliseconds / 1000;
      expect(player.state.output.currentAo, 'webaudio');
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
      await waitUntil(() => player.state.playback.completed, what: 'the end');
      expect(await _consumed() - before, greaterThan(30000));
      expect((element['paused'] as JSBoolean).toDart, isFalse);
    });

    // kit-web-4: the context's destination keeps the sound until the
    // element plays, and gets it back when the element stops without the
    // player asking. The next gesture plays the element again.
    test('an element paused from outside gives the sound back to the '
        'destination until a gesture plays it again', () async {
      final output = await webAudioOutput();
      trace.clear();
      output.routeToElement(true);
      addTearDown(() => output.routeToElement(false));
      await waitUntil(
        () => trace.contains('element playing'),
        what: 'the element playing',
      );
      expect(trace, containsAllInOrder(['direct true', 'direct false']));
      trace.clear();
      output.element!.callMethod('pause'.toJS);
      await waitUntil(
        () => trace.contains('element paused'),
        what: 'the pause seen',
      );
      expect(trace, contains('direct true'));
      trace.clear();
      _document.callMethod('dispatchEvent'.toJS, _event('pointerdown'));
      await waitUntil(
        () => trace.contains('element playing'),
        what: 'the element playing again',
      );
      expect(trace, contains('direct false'));
    });

    // 0.7.0: an outside pause of the session's <audio> element (the browser,
    // a call, another app) follows MediaSession.interruptionPolicy, as on
    // iOS and Android. 0.6 played on, as keepPlaying.
    group('an outside pause follows the interruption policy', () {
      /// Enables a session with [policy] and [playing], waits for the
      /// element to play, then pauses it and plays it again from outside
      /// the output. Returns the commands sent.
      Future<List<MediaSessionCommand>> outside(
        InterruptionPolicy policy, {
        bool playing = true,
      }) async {
        final channel = MediaSessionChannel();
        final commands = <MediaSessionCommand>[];
        final sub = channel.commandStream.listen(commands.add);
        addTearDown(sub.cancel);
        addTearDown(channel.disable);
        await channel.enable(
          session: MediaSession(interruptionPolicy: policy),
          metadata: const MediaSessionMetadataSnapshot(title: 'Outside'),
          playback: MediaSessionPlaybackSnapshot(
            playing: playing,
            position: Duration.zero,
            rate: 1,
            seekable: true,
            loop: Loop.off,
            shuffle: false,
          ),
        );
        final output = await webAudioOutput();
        final element = output.element!;
        await waitUntil(
          () => (element['paused'] as JSBoolean).toDart == false,
          what: 'the element playing',
        );
        // Let its playing event land before the outside pause.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        element.callMethod('pause'.toJS);
        await Future<void>.delayed(const Duration(milliseconds: 300));
        element.callMethod('play'.toJS);
        await waitUntil(
          () => (element['paused'] as JSBoolean).toDart == false,
          what: 'the element playing again',
        );
        await Future<void>.delayed(const Duration(milliseconds: 300));
        return commands;
      }

      test(
        'pauseAndResume pauses, and plays when the element plays again',
        () async {
          expect(await outside(InterruptionPolicy.pauseAndResume), [
            MediaSessionCommand.pause,
            MediaSessionCommand.play,
          ]);
        },
      );

      test('pauseOnly pauses and stays paused', () async {
        expect(await outside(InterruptionPolicy.pauseOnly), [
          MediaSessionCommand.pause,
        ]);
      });

      test('keepPlaying sends nothing, as 0.6', () async {
        expect(await outside(InterruptionPolicy.keepPlaying), isEmpty);
      });

      test('a player already paused is not resumed', () async {
        expect(
          await outside(InterruptionPolicy.pauseAndResume, playing: false),
          isEmpty,
        );
      });
    });
  });

  test('setSystemVolume and setSystemMute before the first file set the '
      "output's gain options", () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setSystemVolume(50);
    await player.setSystemMute(true);
    expect(player.state.output.systemVolume, 50);
    expect(player.state.output.systemMute, isTrue);
    expect(double.parse((await player.getRawProperty('webaudio-volume'))!), 50);
    expect(await player.getRawProperty('webaudio-mute'), 'yes');
  });

  // kit-web-2: the module closes the old context before it makes the new
  // one, so a rate the browser refuses left the page without sound.
  test('a rate the browser refuses throws and keeps the output at the rate '
      'before', () async {
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    final rate = ((await _context())['sampleRate'] as JSNumber).toDartInt;
    final samplerate = await player.getRawProperty('audio-samplerate');
    trace.clear();
    await expectLater(player.setAudioSampleRate(1000), throwsStateError);
    expect(trace, ['init 1000', 'init 0']);
    expect(((await _context())['sampleRate'] as JSNumber).toDartInt, rate);
    expect(player.state.settings.audioSampleRate, 0);
    expect(await player.getRawProperty('audio-samplerate'), samplerate);
    // The same rate again tries again.
    trace.clear();
    await expectLater(player.setAudioSampleRate(1000), throwsStateError);
    expect(trace, contains('init 1000'));
  });

  // A refused rate puts back the rate from before the call only when no
  // other call wrote one since.
  test(
    'a refused rate set beside an accepted one leaves the accepted one',
    () async {
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      final refused = player.setAudioSampleRate(1000);
      final accepted = player.setAudioSampleRate(32000);
      await expectLater(refused, throwsStateError);
      await accepted;
      addTearDown(() => player.setAudioSampleRate(0));
      expect(player.state.settings.audioSampleRate, 32000);
      expect(await player.getRawProperty('audio-samplerate'), '32000');
    },
  );

  test('two rates set at once run one after the other', () async {
    final output = await webAudioOutput();
    trace.clear();
    await Future.wait([output.setSampleRate(32000), output.setSampleRate(0)]);
    expect(trace.where((l) => l.startsWith('init')), ['init 32000', 'init 0']);
    expect((await _context())['state'], isNot('closed'.toJS));
  });

  // kit-web-V1: after a Hot Restart a new context on the same module made
  // it abort. The new program keeps the context, and its rate.
  test('after a Hot Restart the output keeps the context', () async {
    final module = await loadTestModule();
    final output = await webAudioOutput();
    await output.setSampleRate(32000);
    addTearDown(() => output.setSampleRate(0));
    final context = await _context();
    trace.clear();
    final again = await WebAudioOutput.start(module, reuse: true);
    // The output is routed again, from the replaced program's element.
    expect(trace, ['reuse 32000', 'route destination']);
    expect((await _context()).strictEquals(context).toDart, isTrue);
    expect(again.needsGesture, output.needsGesture);
  });

  // After a Hot Restart the listeners of the replaced program stayed on
  // its element and on the page, and output 0 on its element.
  test(
    'after a Hot Restart the replaced element and gestures are let go',
    () async {
      final module = await loadTestModule();
      final output = await webAudioOutput();
      trace.clear();
      // The listeners are on as soon as the output goes to the element,
      // whether the browser lets it play or not.
      output.routeToElement(true);
      addTearDown(() => output.routeToElement(false));
      final old = output.element!;
      trace.clear();
      await WebAudioOutput.start(module, reuse: true);
      expect(trace, contains('route destination'));
      trace.clear();
      old.callMethod('dispatchEvent'.toJS, _event('pause'));
      _document.callMethod('dispatchEvent'.toJS, _event('pointerdown'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(trace, isNot(contains('element paused')));
      expect(trace, isNot(contains('element playing')));
    },
  );

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
