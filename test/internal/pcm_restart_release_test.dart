// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/internals/library_loader.dart';

void main() {
  // The live PCM sources are process-wide: only the root isolate a
  // Hot-Restart replaced may release them all.
  test(
    'a second isolate never releases the PCM sources of the process',
    () async {
      expect(
        await Isolate.run(() => releasesPcmSourcesAtInit(restarted: true)),
        isFalse,
      );
    },
  );

  test('without a restart nothing is released', () {
    expect(releasesPcmSourcesAtInit(restarted: false), isFalse);
  });
}
