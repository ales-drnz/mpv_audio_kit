// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'package:mpv_audio_kit/src/internals/libmpv_release.dart';
import 'package:mpv_audio_kit/src/internals/libmpv_requirements.dart';
import 'package:test/test.dart';

void main() {
  final all = [for (final (name, _) in libmpvRequiredPatches) name];
  const pinned = 'mpv v0.41.0+$libmpvRelease';

  test('the release is read from the version stamp', () {
    expect(libmpvReleaseOfVersion('mpv v0.41.0+r20'), 20);
    expect(libmpvReleaseOfVersion('mpv v0.41.0+r7'), 7);
    expect(libmpvReleaseOfVersion('mpv v0.41.0'), isNull);
    expect(libmpvReleaseOfVersion('mpv v0.41.0-dirty'), isNull);
  });

  group('a custom libmpv', () {
    test('older than the minimum gets the losses of each missing patch', () {
      final w = libmpvWarning(
        version: 'mpv v0.41.0+r19',
        custom: true,
        missing: all,
      );
      expect(w, contains('mpv v0.41.0+r19'));
      expect(w, contains('libmpv-r$libmpvMinimumRelease'));
      for (final (_, loss) in libmpvRequiredPatches) {
        expect(w, contains(loss));
      }
    });

    test('without a release stamp gets it too', () {
      final w = libmpvWarning(
        version: 'mpv v0.41.0',
        custom: true,
        missing: all,
      );
      expect(w, contains('libmpv-r$libmpvMinimumRelease'));
      expect(w, contains(libmpvRequiredPatches.first.$2));
    });

    test('of the minimum with every patch gets nothing', () {
      expect(
        libmpvWarning(
          version: 'mpv v0.41.0+r$libmpvMinimumRelease',
          custom: true,
          missing: const [],
        ),
        isNull,
      );
    });

    test('of the minimum built without a patch gets its loss only', () {
      final (name, loss) = libmpvRequiredPatches.first;
      final w = libmpvWarning(
        version: 'mpv v0.41.0+r$libmpvMinimumRelease',
        custom: true,
        missing: [name],
      );
      expect(w, contains(loss));
      for (final (_, other) in libmpvRequiredPatches.skip(1)) {
        expect(w, isNot(contains(other)));
      }
    });
  });

  group('the bundled libmpv', () {
    test('of the pinned build with every patch gets nothing', () {
      expect(
        libmpvWarning(version: pinned, custom: false, missing: const []),
        isNull,
      );
    });

    test('of another build gets the pinned release', () {
      final w = libmpvWarning(
        version: 'mpv v0.41.0+r1',
        custom: false,
        missing: const [],
      );
      expect(w, contains('expects its $libmpvRelease build'));
    });

    test('without a patch gets its loss', () {
      final w = libmpvWarning(version: pinned, custom: false, missing: all);
      expect(w, contains(libmpvRequiredPatches.first.$2));
    });
  });
}
