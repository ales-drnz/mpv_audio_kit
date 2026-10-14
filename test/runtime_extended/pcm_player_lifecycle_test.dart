// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:mpv_audio_kit/src/internals/pcm_native.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';
import '../pcm/fake_pcm_native.dart';

// The player side of a live PCM source over a fake native layer: what the
// player does with the source, whatever mpv makes of the `mak-pcm://` URI.
void main() {
  runtimeSuite(() {
    late FakePcmNative native;

    setUp(() {
      native = FakePcmNative();
      debugPcmNativeOverride = native;
    });

    tearDown(() => debugPcmNativeOverride = null);

    test(
      'dispose aborts and releases the sources openPcmStream opened',
      () async {
        final player = await buildPlayer();
        final a = await player.openPcmStream(
          const PcmFormat(sampleRate: 24000, channels: 1),
          play: false,
        );
        final other = PcmSource.create(
          const PcmFormat(sampleRate: 24000, channels: 1),
        );
        await waitUntil(
          () => player.state.playlist.items.length == 1,
          reason: 'the live entry reaches the playlist',
        );
        expect(player.state.playlist.items.single.isPcmStream, isTrue);
        await player.dispose();
        expect(a.state, PcmSourceState.aborted);
        expect(native.sources.values.first.state, PcmNative.stateAborted);
        expect(native.sources.values.first.released, isTrue);
        await a.done.timeout(const Duration(seconds: 1));
        // A source the player did not open stays the app's.
        expect(other.isDone, isFalse);
        other.abort();
      },
    );

    test(
      'a media of a source that is done is refused before loading',
      () async {
        final player = await buildPlayer();
        final s = PcmSource.create(
          const PcmFormat(sampleRate: 24000, channels: 1),
        );
        final media = s.toMedia();
        s.abort();
        await expectLater(player.open(media), throwsArgumentError);
        await expectLater(player.add(media), throwsArgumentError);
        await expectLater(player.openAll([media]), throwsArgumentError);
        await player.dispose();
      },
    );

    test('openPcmStream on a disposed player throws', () async {
      final player = await buildPlayer();
      await player.dispose();
      await expectLater(
        player.openPcmStream(const PcmFormat(sampleRate: 24000, channels: 1)),
        throwsA(isA<PlayerDisposedException>()),
      );
      expect(native.sources, isEmpty);
    });
  });
}
