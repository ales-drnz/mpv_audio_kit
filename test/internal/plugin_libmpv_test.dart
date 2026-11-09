// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Where the build hook does not run (flutter-webos), webos/CMakeLists.txt
// bundles libmpv as lib/libmpv_audio_kit.so beside the app's executable:
// with no libmpv given, ensureInitialized opens it when the hook's libmpv
// does not resolve. Linux desktop has the same file, the hook's asset,
// which resolves: there nothing changes.

@TestOn('vm')
library;

import 'package:mpv_audio_kit/src/internals/library_loader.dart';
import 'package:test/test.dart';

void main() {
  const exe = '/media/developer/apps/usr/palm/applications/app/runner';
  const bundled =
      '/media/developer/apps/usr/palm/applications/app/lib/'
      'libmpv_audio_kit.so';

  String? pick({
    bool isLinux = true,
    bool hookResolves = false,
    Set<String> files = const {bundled},
  }) {
    var asked = false;
    final path = pluginLibmpv(
      isLinux: isLinux,
      hookResolves: () {
        asked = true;
        return hookResolves;
      },
      executable: exe,
      exists: files.contains,
    );
    // The hook's libmpv is tried only where a plugin's could be.
    if (!isLinux || !files.contains(bundled)) expect(asked, isFalse);
    return path;
  }

  test('webOS: the plugin\'s libmpv beside the executable', () {
    expect(pick(), bundled);
  });

  test('Linux desktop: the hook\'s libmpv resolves, nothing given', () {
    expect(pick(hookResolves: true), isNull);
  });

  test('no file beside the executable: nothing given', () {
    expect(pick(files: const {}), isNull);
  });

  test('another OS: nothing given', () {
    expect(pick(isLinux: false), isNull);
  });
}
