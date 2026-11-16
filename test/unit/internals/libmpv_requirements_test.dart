// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_requirements.dart';
import 'package:test/test.dart';

void main() {
  test('the release is read from the version stamp', () {
    expect(libmpvReleaseOfVersion('mpv v0.41.0+r20'), 'r20');
    expect(libmpvReleaseOfVersion('mpv v0.41.0+r7 '), 'r7');
    expect(libmpvReleaseOfVersion('mpv v0.41.0'), isNull);
    expect(libmpvReleaseOfVersion('mpv v0.41.0-dirty'), isNull);
  });

  test('the libmpv of the pin runs', () {
    expect(libmpvMismatch('mpv v0.41.0+$libmpvRelease'), isNull);
  });

  test('any other libmpv is refused, naming the pin', () {
    for (final version in [
      'mpv v0.41.0+r20',
      'mpv v0.41.0+r99',
      'mpv v0.41.0',
      'mpv v0.41.0+${libmpvRelease}0',
      null,
    ]) {
      final why = libmpvMismatch(version);
      expect(why, contains('libmpv-$libmpvRelease'), reason: '$version');
      expect(why, contains(version ?? 'no version'), reason: '$version');
    }
  });
}
