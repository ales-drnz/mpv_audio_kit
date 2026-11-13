// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The Hot Restart cleanup on a module whose calls throw, as an aborted
// one's do: a core that cannot be destroyed is passed over, the others are
// destroyed, and the registration goes on, where the first throw used to
// fail the load of the page. On a stand-in for the module, in a file of
// its own since the record is the page's (flutter test --platform chrome
// --wasm).

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/src/backend/web/mpv_module.dart';
import 'package:mpv_audio_kit/src/backend/web/web_registry.dart';

import 'fake_module.dart';

void main() {
  test('a core that cannot be destroyed does not keep the next one', () {
    final fake = FakeModule();
    final module = MpvModule(fake.instance);
    registerModule('replaced', module, reap: false);
    trackCore(handle: 10, reads: 11, handleBridge: 12, readsBridge: 13);
    trackCore(handle: 20, reads: 21, handleBridge: 22, readsBridge: 23);
    // The first core's bridge is gone.
    fake.aborts = (name, args) =>
        name == '_mak_web_wakeup_detach' && args[0] == 13;
    registerModule('restart', module, reap: true);
    expect(
      fake.arguments,
      contains(
        isA<(String, List<int>)>()
            .having((c) => c.$1, 'name', '_mpv_terminate_destroy')
            .having((c) => c.$2, 'arguments', [20]),
      ),
    );
    expect(fake.calls.last, '_mak_pcm_release_all');
    expect(debugTrackedCores, isEmpty);
  });

  test('a module that aborted does not fail the registration', () {
    final fake = FakeModule();
    final module = MpvModule(fake.instance);
    registerModule('replaced', module, reap: false);
    trackCore(handle: 10, reads: 11, handleBridge: 12, readsBridge: 13);
    fake.aborts = (name, args) => true;
    registerModule('restart', module, reap: true);
    expect(debugTrackedCores, isEmpty);
  });
}
