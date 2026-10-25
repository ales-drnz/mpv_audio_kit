// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _probe = MethodChannel('mpv_audio_kit/media_session');

/// Reads the OS-visible Now Playing snapshot back from the plugin (the
/// real `MPNowPlayingInfoCenter.default()`). Apple only.
Future<Map<String, Object?>> readNowPlaying() async {
  final raw = await _probe.invokeMethod<Map<Object?, Object?>>(
    'debugNowPlayingInfo',
  );
  return Map<String, Object?>.from(raw ?? const {});
}

/// Reads back the published session state from the Android, Windows or
/// Linux plugin: the Media3 session State, the SMTC renderer or the MPRIS
/// server.
Future<Map<String, Object?>> readMediaSession() async {
  final raw = await _probe.invokeMethod<Map<Object?, Object?>>(
    'debugMediaSessionState',
  );
  return Map<String, Object?>.from(raw ?? const {});
}

/// Polls [reader] until [predicate] holds or the timeout fires. Returns
/// the last snapshot so the caller can assert on it (and get a useful
/// failure message). Method-channel pushes are async, so a settled
/// assertion needs a poll, not a fixed delay. [reader] defaults to the
/// Apple Now Playing probe; the other platforms pass [readMediaSession].
Future<Map<String, Object?>> pumpUntil(
  bool Function(Map<String, Object?>) predicate, {
  Duration timeout = const Duration(seconds: 5),
  Future<Map<String, Object?>> Function() reader = readNowPlaying,
}) async {
  final deadline = DateTime.now().add(timeout);
  var snapshot = await reader();
  while (!predicate(snapshot)) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Media session never satisfied the predicate. Last: $snapshot');
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
    snapshot = await reader();
  }
  return snapshot;
}
