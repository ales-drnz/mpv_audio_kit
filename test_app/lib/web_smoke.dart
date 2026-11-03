// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The web build of an app, as `flutter build web` makes it (dart2js, the
// module loaded from the package's web assets): plays a fixture to its end
// and prints the outcome to the console, where test/web/dart2js_smoke.sh
// reads it.

import 'package:flutter/widgets.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MpvAudioKit.ensureInitialized();
  try {
    final player = Player();
    await player.open(
      Media(
        Uri.base.resolve('assets/assets/fixtures/sine_440hz_1s.wav').toString(),
      ),
      play: true,
    );
    await player.stream.completed
        .firstWhere((c) => c)
        .timeout(const Duration(seconds: 60));
    // ignore: avoid_print
    print('MAK_WEB_SMOKE completed ${player.state.currentAo}');
    await player.dispose();
  } catch (e) {
    // ignore: avoid_print
    print('MAK_WEB_SMOKE failed $e');
  }
}
