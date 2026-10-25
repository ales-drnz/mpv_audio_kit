// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// The web backend around the players: the module loads asynchronously and
// a PCM source waits for it or says why it cannot; the players' cores are
// kept in the page's record, and the program after a Hot Restart destroys
// the cores, the PCM sources and the network streams the replaced one left
// (simulated: a core made on the module stands for the old program's).
// flutter test --platform chrome --wasm.

@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/backend/web/web_pcm.dart';
import 'package:mpv_audio_kit/src/backend/web/web_registry.dart';
import 'package:mpv_audio_kit/src/pcm/pcm_native.dart';

import '../_helpers/parity_scenario.dart';
import 'web_module_helper.dart';

const _format = PcmFormat(sampleRate: 48000, channels: 1);

void main() {
  test('a PCM source before the module loaded says why; openPcmStream '
      'waits for it', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // The module starts loading here, as in an app's main().
    loadTestModule().ignore();
    MpvAudioKit.ensureInitialized(hotRestartCleanup: false);
    expect(
      () => PcmSource.create(_format),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          allOf(contains('still loading'), contains('openPcmStream')),
        ),
      ),
    );
    final player = Player();
    addTearDown(player.dispose);
    final source = await player.openPcmStream(_format, play: false);
    expect(source.state, PcmSourceState.waiting);
    source.abort();
  });

  test('a player keeps its core in the page record until dispose', () async {
    final player = Player();
    await player.ready;
    expect(debugTrackedCores, hasLength(1));
    await player.dispose();
    expect(debugTrackedCores, isEmpty);
  });

  test('after a Hot Restart the cores, PCM sources and streams the replaced '
      'program left are gone', () async {
    final module = await loadTestModule();
    final c = module.c;
    // The record of the replaced program.
    registerModule('previous', module, reap: false);
    // The replaced program's core: playing a file over http, with a live
    // PCM source, kept in the record as its player left it.
    final h = c.mpvCreate();
    module.withStrings([
      'ao',
      'null',
    ], (p) => c.mpvSetOptionString(h, p[0], p[1]));
    expect(c.mpvInitialize(h), 0);
    final reads = module.withStrings([
      'old_reads',
    ], (p) => c.mpvCreateClient(h, p[0]));
    final handleBridge = module.attachWakeup(h, () {});
    final readsBridge = module.attachWakeup(reads, () {});
    module.withStrings([
      'loadfile ${testUrl('fixtures/sine_5s.flac')}',
    ], (p) => c.mpvCommandString(h, p[0]));
    await waitUntil(
      () => c.webioLiveStreams() > 0,
      what: 'the old core reading over http',
    );
    final pcm = WebPcmNative(module);
    final source = pcm.create(48000);
    expect(pcm.state(source), PcmNative.stateOpen);
    trackCore(
      handle: h,
      reads: reads,
      handleBridge: handleBridge,
      readsBridge: readsBridge,
    );

    final reaped = <int>[];
    debugWebReapTrace = reaped.add;
    addTearDown(() => debugWebReapTrace = null);
    // The next program registers the module it found in the record.
    registerModule('restart', module, reap: true);
    expect(reaped, [h]);
    expect(debugTrackedCores, isEmpty);
    expect(pcm.state(source), PcmNative.errUnknown);
    await waitUntil(
      () => c.webioLiveStreams() == 0,
      what: 'the old network stream closed',
    );

    // The module goes on: a player of the new program plays.
    final player = Player();
    addTearDown(player.dispose);
    await player.ready;
    await player.setRawProperty('ao', 'null');
    await player.open(
      Media(testUrl('fixtures/sine_stereo_1s.flac')),
      play: true,
    );
    await waitUntil(() => player.state.completed, what: 'the new player');
  });

  test('without the cleanup, the cores of the record are left alone', () {
    final reaped = <int>[];
    debugWebReapTrace = reaped.add;
    addTearDown(() => debugWebReapTrace = null);
    return loadTestModule().then((module) {
      registerModule('previous', module, reap: false);
      trackCore(handle: 1, reads: 2, handleBridge: 3, readsBridge: 4);
      registerModule('again', module, reap: false);
      expect(reaped, isEmpty);
      expect(debugTrackedCores, isEmpty);
    });
  });
}
