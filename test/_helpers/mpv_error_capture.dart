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

/// The errors from making [effects] the whole chain, set a second time
/// after a failure, from an empty chain and a short pause. Frames the
/// previous chain left in flight can reach the new first filter in a format
/// it does not take (`hdcd` wants integer samples, the earlier stage may
/// have made them float), while a value the filter refuses fails twice.
Future<List<MpvLogEntry>> captureChainErrors(
  Player player,
  List<AudioEffect> effects,
) async {
  final errors = await captureMpvErrors(
    player,
    () => player.setAudioEffects(effects),
  );
  if (errors.isEmpty) return errors;
  await player.setAudioEffects(const []);
  await Future<void>.delayed(const Duration(milliseconds: 300));
  return captureMpvErrors(player, () => player.setAudioEffects(effects));
}
