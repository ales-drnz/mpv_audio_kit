// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Test helper that subscribes to `Player.stream.log`, runs a body, and
// returns every `error` / `fatal` entry that arrived during the call.

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';

Future<List<MpvLogEntry>> captureMpvErrors(
  Player player,
  Future<void> Function() body, {
  Duration drain = const Duration(milliseconds: 150),
}) async {
  final errors = <MpvLogEntry>[];
  final sub = player.stream.log
      .where((e) => e.level == LogLevel.error || e.level == LogLevel.fatal)
      .listen(errors.add);
  try {
    await body();
    await Future<void>.delayed(drain);
  } finally {
    await sub.cancel();
  }
  return errors;
}
