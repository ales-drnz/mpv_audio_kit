// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/setter_test_helpers.dart';

void main() {
  final fx = defaultFixturePath();
  setUpAll(() => initLibmpvOrSkip(fixturePath: fx));

  int audioCount(List<MpvTrack> t) => t.where((x) => x.type == 'audio').length;

  group('external audio tracks (audio-add / audio-remove)', () {
    late Player player;
    late Directory tmp;
    late String extra;

    setUpAll(() async {
      player = await buildPlayerWithFixture(fixturePath: fx);
      tmp = Directory.systemTemp.createTempSync('mak_extaud_');
      // A distinct file path so mpv treats it as a separate external track.
      extra = '${tmp.path}/extra.wav';
      File(fx).copySync(extra);
    });

    tearDownAll(() async {
      await player.dispose();
      try {
        tmp.deleteSync(recursive: true);
      } catch (_) {}
    });

    test(
      'addAudioTrack adds and removeAudioTrack removes a selectable track',
      () async {
        expect(
          audioCount(player.state.tracks),
          1,
          reason: 'the fixture has a single audio track to start',
        );
        final beforeIds = player.state.tracks
            .where((t) => t.type == 'audio')
            .map((t) => t.id)
            .toSet();

        // Pre-subscribe before the command (the track-list emits once on change).
        final grown = player.stream.tracks
            .firstWhere((t) => audioCount(t) >= 2)
            .timeout(const Duration(seconds: 10));
        await player.addAudioTrack(Media(extra), select: false);
        final after = await grown;
        expect(audioCount(after), 2);

        final added = after
            .where((t) => t.type == 'audio' && !beforeIds.contains(t.id))
            .toList();
        expect(added, hasLength(1), reason: 'one new external audio track');
        // #23: the added track is flagged external with its source filename.
        expect(
          added.first.external,
          isTrue,
          reason: 'audio-add tracks are marked external',
        );
        expect(
          added.first.externalFilename,
          contains('extra'),
          reason: 'external-filename points to the added file',
        );

        final shrunk = player.stream.tracks
            .firstWhere((t) => audioCount(t) <= 1)
            .timeout(const Duration(seconds: 10));
        await player.removeAudioTrack(Track.id(added.first.id));
        expect(
          audioCount(await shrunk),
          1,
          reason: 'audio-remove drops the external track',
        );
      },
      timeout: const Timeout(Duration(seconds: 25)),
    );

    test(
      'removeAudioTrack(Track.off) is rejected — off has no removal meaning',
      () async {
        // mpv's `audio-remove` takes an optional id and has no "off" notion, so
        // removing "no track" is a programming error rather than a silent no-op.
        await expectLater(
          player.removeAudioTrack(Track.off),
          throwsArgumentError,
        );
      },
    );
  });
}
