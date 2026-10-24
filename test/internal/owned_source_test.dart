// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/owned_source.dart';
import 'package:mpv_audio_kit/src/internals/uri_resolver.dart';
import 'package:test/test.dart';

/// A resolved source a load call owns until mpv takes it: released once on
/// every way out, never after the hand-over unless mpv refused.
void main() {
  late int releases;
  late OwnedSource source;

  setUp(() {
    releases = 0;
    source = OwnedSource(ResolvedUri('fd://7', () async => releases++));
  });

  test('released once, however often release is called', () async {
    await source.release();
    await source.release();
    expect(releases, 1);
  });

  test('handed over, release does nothing', () async {
    source.handOver();
    await source.release();
    expect(releases, 0);
  });

  test('the hand-over gives the release to the next keeper', () async {
    final release = source.handOver();
    await release!();
    expect(releases, 1);
    await source.release();
    expect(releases, 1, reason: 'the keeper released it, not the call');
  });

  test('refused after the hand-over, it is released again', () async {
    source.handOver();
    source.revoke();
    await source.release();
    expect(releases, 1);
  });

  // The keeper (a playlist entry) may still hold the release when mpv's
  // refusal gives the source back: between them it runs once.
  test(
    'refused after the hand-over, the keeper does not release it again',
    () async {
      final keeper = source.handOver();
      source.revoke();
      await source.release();
      await keeper!();
      expect(releases, 1);
    },
  );

  test('a source with nothing to release', () async {
    final plain = OwnedSource(const ResolvedUri('/music/a.flac'));
    expect(plain.uri, '/music/a.flac');
    expect(plain.handOver(), isNull);
    plain.revoke();
    await plain.release();
  });

  // A load path as the player writes one: the source is released in a
  // finally unless the loadfile went out and mpv kept it.
  group('the scope of a load path', () {
    Future<void> load({
      bool superseded = false,
      bool failBefore = false,
      bool refused = false,
    }) async {
      try {
        if (superseded) return;
        if (failBefore) throw StateError('the pause write failed');
        source.handOver();
        // The reply of the loadfile.
        await Future<void>.delayed(Duration.zero);
        if (refused) {
          source.revoke();
          throw StateError('refused');
        }
      } finally {
        await source.release();
      }
    }

    test('superseded before the loadfile', () async {
      await load(superseded: true);
      expect(releases, 1);
    });

    test('an error before the loadfile', () async {
      await expectLater(load(failBefore: true), throwsStateError);
      expect(releases, 1);
    });

    test('a loadfile mpv refuses', () async {
      await expectLater(load(refused: true), throwsStateError);
      expect(releases, 1);
    });

    test('a loadfile mpv takes', () async {
      await load();
      expect(releases, 0);
    });
  });
}
