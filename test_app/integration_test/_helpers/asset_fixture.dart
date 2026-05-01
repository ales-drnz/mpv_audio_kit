// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

// libmpv accepts a filesystem path, not an asset URI. On iOS/Android we
// must materialize the bundled asset to a temp file before opening it.
// On macOS the same code path works (Flutter assets are read identically),
// so a single helper covers every platform the integration tests run on.
Future<String> materializeFixture(String name) async {
  final data = await rootBundle.load('assets/fixtures/$name');
  final dir = await getTemporaryDirectory();
  // The macOS sandbox returns a Caches path whose parent may not exist on
  // first launch (no-op on iOS/Android). When [name] contains a slash
  // (e.g. 'codec/mp3_44100_stereo.mp3') we also need to create the
  // sub-directory the file lives in — `writeAsBytes` doesn't create
  // missing parent directories on its own.
  final out = File('${dir.path}/$name');
  await out.parent.create(recursive: true);
  await out.writeAsBytes(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    flush: true,
  );
  return out.path;
}
