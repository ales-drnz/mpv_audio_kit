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

/// One chain to check with [captureChainErrorsEach]: [key] names it in
/// the report.
typedef ChainCase = ({String key, List<AudioEffect> bundle});

/// The errors of every case in [cases] whose chain mpv refuses, by key, as
/// [captureChainErrors] finds them case by case, with a short [drain].
///
/// While audio plays, mpv builds the chain inside the `af` write: a value
/// out of range is logged, and the write refused, before the reply. The
/// long drain of [captureChainErrors] is for the rarer error a filter
/// raises at its first frames, which can arrive after [drain] and land on
/// one of the next cases. So any case that shows an error is checked
/// again, with the [lookBack] cases before it, one by one with the long
/// drain and its retry, and only those that fail on their own are
/// reported. A late error after the last case is caught the same way.
Future<Map<String, List<MpvLogEntry>>> captureChainErrorsEach(
  Player player,
  List<ChainCase> cases, {
  Duration drain = const Duration(milliseconds: 25),
  int lookBack = 3,
}) async {
  final suspects = <int>{};
  void suspect(int i) {
    for (var k = i - lookBack; k <= i; k++) {
      if (k >= 0 && k < cases.length) suspects.add(k);
    }
  }

  for (var i = 0; i < cases.length; i++) {
    final errors = await captureMpvErrors(player, () async {
      try {
        await player.setAudioEffects(cases[i].bundle);
      } on MpvCommandException {
        // The refusal is logged as an error too.
      }
    }, drain: drain);
    try {
      await player.setAudioEffects(const []);
    } on MpvCommandException {
      // Errors of the chain being dropped are caught on the next case.
    }
    if (errors.isNotEmpty) suspect(i);
  }
  final tail = await captureMpvErrors(player, () async {});
  if (tail.isNotEmpty) suspect(cases.length - 1);

  final failures = <String, List<MpvLogEntry>>{};
  for (final i in suspects.toList()..sort()) {
    List<MpvLogEntry> own;
    try {
      own = await captureChainErrors(player, cases[i].bundle);
    } on MpvCommandException catch (e) {
      own = [MpvLogEntry(prefix: 'af', level: LogLevel.error, text: '$e')];
    }
    try {
      await player.setAudioEffects(const []);
    } on MpvCommandException {
      // As above.
    }
    if (own.isNotEmpty) failures[cases[i].key] = own;
  }
  return failures;
}
