// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../../_helpers/setter_test_helpers.dart';

/// A setter with a range throws RangeError past either end, before it
/// writes anything, and takes both ends.
void main() {
  runtimeSuite(() {
    late Player player;
    setUp(() async => player = await buildPlayer());
    tearDown(() => player.dispose());

    final cases =
        <
          String,
          (
            Future<void> Function(Player),
            List<Future<void> Function(Player)>,
            List<Future<void> Function(Player)>,
          )
        >{
          'setVolume': (
            (p) => p.setVolume(50),
            [(p) => p.setVolume(0), (p) => p.setVolume(1000)],
            [(p) => p.setVolume(-0.5), (p) => p.setVolume(1000.5)],
          ),
          'setVolumeGain': (
            (p) => p.setVolumeGain(1),
            [(p) => p.setVolumeGain(-150), (p) => p.setVolumeGain(150)],
            [(p) => p.setVolumeGain(-151), (p) => p.setVolumeGain(151)],
          ),
          'setVolumeGainMin': (
            (p) => p.setVolumeGainMin(-10),
            [(p) => p.setVolumeGainMin(-150), (p) => p.setVolumeGainMin(0)],
            [(p) => p.setVolumeGainMin(-151), (p) => p.setVolumeGainMin(1)],
          ),
          'setVolumeGainMax': (
            (p) => p.setVolumeGainMax(10),
            [(p) => p.setVolumeGainMax(0), (p) => p.setVolumeGainMax(150)],
            [(p) => p.setVolumeGainMax(-1), (p) => p.setVolumeGainMax(151)],
          ),
          'setVolumeMax': (
            (p) => p.setVolumeMax(200),
            [(p) => p.setVolumeMax(100), (p) => p.setVolumeMax(1000)],
            [(p) => p.setVolumeMax(99), (p) => p.setVolumeMax(1001)],
          ),
          'setAbLoopCount': (
            (p) => p.setAbLoopCount(2),
            [(p) => p.setAbLoopCount(0), (p) => p.setAbLoopCount(null)],
            [(p) => p.setAbLoopCount(-1)],
          ),
          'setAudioBuffer': (
            (p) => p.setAudioBuffer(const Duration(milliseconds: 300)),
            [
              (p) => p.setAudioBuffer(Duration.zero),
              (p) => p.setAudioBuffer(const Duration(seconds: 10)),
            ],
            [
              (p) => p.setAudioBuffer(const Duration(milliseconds: -1)),
              (p) => p.setAudioBuffer(
                const Duration(seconds: 10, microseconds: 1),
              ),
            ],
          ),
          'setNetworkTimeout': (
            (p) => p.setNetworkTimeout(const Duration(seconds: 5)),
            [(p) => p.setNetworkTimeout(Duration.zero)],
            [(p) => p.setNetworkTimeout(const Duration(seconds: -1))],
          ),
          'setAudioSampleRate': (
            (p) => p.setAudioSampleRate(44100),
            [
              (p) => p.setAudioSampleRate(0),
              (p) => p.setAudioSampleRate(768000),
            ],
            [
              (p) => p.setAudioSampleRate(-1),
              (p) => p.setAudioSampleRate(768001),
            ],
          ),
        };

    for (final MapEntry(key: name, value: (set, inside, outside))
        in cases.entries) {
      test('$name takes its ends and throws RangeError past them', () async {
        for (final call in inside) {
          await call(player);
        }
        await set(player);
        final before = player.state.settings;
        for (final call in outside) {
          await expectLater(call(player), throwsRangeError);
        }
        expect(player.state.settings, before, reason: 'nothing written');
      });
    }
  });
}
