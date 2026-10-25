// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

import 'libmpv_release.dart';

/// The first libmpv-scripts release whose patches the player relies on
/// (libmpv-scripts 0.3.0). A libmpv without them still plays, with the
/// losses of [libmpvRequiredPatches].
const int libmpvMinimumRelease = 20;

/// Each patch of [libmpvMinimumRelease] the player relies on: the property
/// it adds, which mpv reports as not found on a libmpv without it, and what
/// the player loses there.
const List<(String, String)> libmpvRequiredPatches = [
  (
    'prefetch-open-filename',
    'the prefetch of the next entry runs Hook.load, and the playing entry '
        'stops while a source resolver or a Hook.load listener runs for it',
  ),
];

/// The libmpv-scripts release stamped in an mpv version string:
/// `mpv v0.41.0+r20` gives 20. `null` for a version without the stamp, a
/// build of upstream mpv.
int? libmpvReleaseOfVersion(String version) {
  final m = RegExp(r'\+r(\d+)$').firstMatch(version.trim());
  return m == null ? null : int.parse(m.group(1)!);
}

/// What to tell about a libmpv that reports [version] (`null` when the read
/// failed) and lacks the patches whose properties are [missing], or `null`
/// when there is nothing to tell. [custom] is a libmpv the app passed to
/// `MpvAudioKit.ensureInitialized`, which may be any build; the bundled one
/// should be the [libmpvRelease] build.
String? libmpvWarning({
  required String? version,
  required bool custom,
  required Iterable<String> missing,
}) {
  final parts = <String>[];
  if (!custom && version != null && !version.endsWith('+$libmpvRelease')) {
    parts.add(
      'mpv_audio_kit expects its $libmpvRelease build. Features may be '
      'missing.',
    );
  }
  final release = version == null ? null : libmpvReleaseOfVersion(version);
  final losses = [
    for (final (name, loss) in libmpvRequiredPatches)
      if (missing.contains(name)) loss,
  ];
  if (losses.isNotEmpty ||
      (custom && (release == null || release < libmpvMinimumRelease))) {
    parts.add(
      'mpv_audio_kit needs the patches of libmpv-scripts 0.3.0 '
      '(libmpv-r$libmpvMinimumRelease) or later.',
    );
    if (losses.isNotEmpty) parts.add('Without them ${losses.join('; ')}.');
  }
  if (parts.isEmpty) return null;
  return 'libmpv reports "${version ?? 'no version'}". ${parts.join(' ')}';
}
