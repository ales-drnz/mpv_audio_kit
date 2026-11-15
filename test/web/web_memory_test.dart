// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The memory the package hands the module: shared, 32 MB at the start,
// growing up to 512 MiB, or 256 MiB on WebKit for phones and tablets. Chrome
// stands in for an iPhone with the profile forced (debugWebKitMobile): the
// allocations past the ceiling fail as they would there. The real limits of
// iOS need a real iPhone. A player on the web starts with the demuxer cache
// of 64 MiB ahead and 16 MiB behind.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

const int _mib = 1024 * 1024;

/// Whether the module can allocate [bytes] at once; frees them again.
bool _fits(MpvModule module, int bytes) {
  final int p;
  try {
    p = module.malloc(bytes);
  } on WebOutOfMemory {
    return false;
  }
  module.free(p);
  return true;
}

void main() {
  tearDown(() => debugWebKitMobile = null);

  test('the module grows up to 512 MiB', () async {
    debugWebKitMobile = false;
    final module = await loadModuleInstance();
    expect(_fits(module, 300 * _mib), isTrue);
    expect(_fits(module, 600 * _mib), isFalse);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('on WebKit for phones and tablets, up to 256 MiB', () async {
    debugWebKitMobile = true;
    final module = await loadModuleInstance();
    expect(_fits(module, 100 * _mib), isTrue);
    expect(_fits(module, 300 * _mib), isFalse);
  }, timeout: const Timeout(Duration(seconds: 60)));

  test(
    'a player starts with 64 MiB of cache ahead and 16 MiB behind',
    () async {
      await loadTestModule();
      MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
      final player = Player();
      addTearDown(player.dispose);
      await player.ready;
      await waitUntil(
        () => player.state.settings.demuxer.maxBytes == 64 * _mib,
        what: 'the cache of the web',
      );
      expect(player.state.settings.demuxer.maxBackBytes, 16 * _mib);
      expect(await player.getRawProperty('demuxer-max-bytes'), '${64 * _mib}');
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
