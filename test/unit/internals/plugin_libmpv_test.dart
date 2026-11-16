// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

// Where the build hook does not run (flutter-webos), webos/CMakeLists.txt
// bundles libmpv as lib/libmpv_audio_kit_webos.so beside the app's
// executable: with no libmpv given, ensureInitialized opens it. Linux
// desktop has the hook's asset, lib/libmpv_audio_kit.so, at the same place:
// that one never counts, even when it does not load.

@TestOn('vm')
library;

import 'package:mpv_audio_kit/src/internals/library_loader.dart';
import 'package:test/test.dart';

void main() {
  const dir = '/media/developer/apps/usr/palm/applications/app';
  const exe = '$dir/runner';
  const plugin = '$dir/lib/libmpv_audio_kit_webos.so';
  const hookAsset = '$dir/lib/libmpv_audio_kit.so';

  String? pick({bool isLinux = true, Set<String> files = const {plugin}}) =>
      pluginLibmpv(isLinux: isLinux, executable: exe, exists: files.contains);

  test('webOS: the plugin\'s libmpv beside the executable', () {
    expect(pick(), plugin);
  });

  test('Linux desktop: the hook\'s asset is not the plugin\'s', () {
    expect(pick(files: const {hookAsset}), isNull);
  });

  test('no file beside the executable: nothing given', () {
    expect(pick(files: const {}), isNull);
  });

  test('another OS: nothing given', () {
    expect(pick(isLinux: false), isNull);
  });
}
