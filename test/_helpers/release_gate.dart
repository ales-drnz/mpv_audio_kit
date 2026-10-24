// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// What a test of a fix in a libmpv-scripts release does on the binary at
// hand. The file exists twice, in test/_helpers and in test_app's
// integration_test/_helpers, which cannot import from test/; the packaging
// test libmpv_release_test keeps the two copies equal.

/// What a test of a fix of a libmpv-scripts release does on a binary.
enum ReleaseGate {
  /// The binary has the fix: the test runs.
  run,

  /// The binary predates the fix and nothing asks for it: the test skips.
  skip,

  /// The binary should have the fix and has not: the test fails.
  fail,
}

/// What a test of a fix of libmpv-r[release] does on a binary of
/// r[bundled] (`null` for one without the stamp, a build of upstream mpv),
/// in a run that expects libmpv-r[expected]. With [ci] a release up to
/// [expected] that the binary lacks fails, since the binary is not the one
/// the run means to test. A release past [expected] skips: the tests of
/// the next release land before its binary, and libmpv_release_test fails
/// CI on them instead.
ReleaseGate releaseGate(int release, int? bundled, int expected, bool ci) {
  if (bundled != null && bundled >= release) return ReleaseGate.run;
  if (ci && release <= expected) return ReleaseGate.fail;
  return ReleaseGate.skip;
}

/// The number of a release as the manifest and libmpvRelease name it:
/// `r19` gives 19. `null` for anything else.
int? releaseNumber(String name) {
  final m = RegExp(r'^r?(\d+)$').firstMatch(name.trim());
  return m == null ? null : int.parse(m.group(1)!);
}
