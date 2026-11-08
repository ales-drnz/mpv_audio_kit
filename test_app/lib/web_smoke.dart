// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The web build of an app, as `flutter build web` makes it (dart2js, the
// module loaded from the package's web assets): plays a fixture to its end
// and posts the outcome to the server of test/web/dart2js_smoke.sh.

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/widgets.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

@JS('fetch')
external JSPromise<JSAny?> _fetch(JSString url, JSObject init);

Future<void> _report(String outcome) async {
  // ignore: avoid_print
  print('MAK_WEB_SMOKE $outcome');
  final init = JSObject()
    ..['method'] = 'POST'.toJS
    ..['body'] = outcome.toJS;
  await _fetch('mak-result'.toJS, init).toDart;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  try {
    final player = Player();
    // Listened to before the open: a second of audio can end before it
    // returns.
    final completed = player.stream.completed
        .firstWhere((c) => c)
        .timeout(const Duration(seconds: 60));
    await player.open(
      Media(
        Uri.base.resolve('assets/assets/fixtures/sine_440hz_1s.wav').toString(),
      ),
      play: true,
    );
    await completed;
    final ao = player.state.output.currentAo;
    await player.dispose();
    await _report('completed $ao');
  } catch (e) {
    await _report('failed $e');
  }
}
