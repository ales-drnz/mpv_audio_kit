// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:meta/meta.dart';

/// Extracts the bundled CA certificate bundle to a real filesystem path
/// that the underlying TLS stack can read via `tls-ca-file`. Required on
/// platforms (most importantly Android) where the OS trust store is not
/// reachable from native code in a form the TLS backend can consume.
///
/// Extraction happens lazily on first use and the resulting path is
/// cached for the rest of the process. The cached path is re-validated
/// on every hit because temp directories on some platforms can be
/// evicted between sessions or under disk pressure.
@internal
class TlsCaBundle {
  static const String _assetPath =
      'packages/mpv_audio_kit/lib/assets/cacert.pem';

  static String? _cachedPath;
  static Future<String>? _inflight;

  /// Extract the bundle to a real filesystem path. Idempotent: returns
  /// the same path across calls. Safe under concurrent invocations.
  static Future<String> extract() {
    final cached = _cachedPath;
    if (cached != null && File(cached).existsSync()) {
      return Future.value(cached);
    }
    if (cached != null) _cachedPath = null;
    return _inflight ??= _doExtract().whenComplete(() => _inflight = null);
  }

  static Future<String> _doExtract() async {
    final bytes = await rootBundle.load(_assetPath);
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}'
      'mpv_audio_kit_cacert.pem',
    );
    await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    _cachedPath = file.path;
    return file.path;
  }
}
