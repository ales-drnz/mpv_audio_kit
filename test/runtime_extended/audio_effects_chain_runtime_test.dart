// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Per-filter runtime gate. Iterates the auto-generated
// `kAudioFilterNames` manifest (mirror of every typed filter on the
// public `AudioEffects` bundle), applies each one in isolation as a
// raw `lavfi-<name>` chain via a `RawAudioEffect`, and collects
// every mpv `error`/`fatal` log entry. The test fails with the full
// per-filter report so a single run surfaces ALL unusable filters
// (whether for missing ffmpeg deps or 1-in/1-out gating in mpv's
// lavfi-bridge) rather than failing on the first one.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/filter_sets.dart';
import '../_helpers/mpv_error_capture.dart';
import '../_helpers/setter_test_helpers.dart';
import '../generated/audio_filter_names.dart';

void main() {
  // Stereo at 48 kHz, which every filter takes, looped and playing: each
  // new chain gets audio, so each filter is really configured. A short
  // paused file stops feeding the chain once its end has gone through.
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_stereo_48k_5s.flac';

  // Filter names come from the auto-generated test manifest; sorting
  // keeps the failure report deterministic across runs.
  final filterNames = [...kAudioFilterNames]..sort();
  late Player player;

  runtimeSuite(fixturePath: fixturePath, () {
    setUpAll(() async {
      // logLevel must be at least 'error' to receive the diagnostics we
      // grep for. Default helper builds with 'no'.
      player = Player(
        configuration: const PlayerConfiguration(logLevel: LogLevel.error),
      );
      await player.setRawProperty('ao', 'null');
      await player.setLoop(Loop.file);
      await player.open(Media(fixturePath), play: true);
      // Wait for file-loaded so the audio chain is live; otherwise
      // setting `af` may be deferred and not surface load errors.
      await player.stream.seekCompleted.first.timeout(
        const Duration(seconds: 10),
      );
    });

    tearDownAll(() async {
      await player.dispose();
    });

    test('every typed audio filter loads in mpv\'s `af` chain', () async {
      final errors = await captureChainErrorsEach(player, [
        for (final name in filterNames)
          if (!kFiltersNeedingParams.contains(name))
            (key: name, bundle: [RawAudioEffect('lavfi-$name')]),
      ]);
      final failures = {
        for (final MapEntry(:key, :value) in errors.entries)
          key: value.map((e) => e.text.trim()).toList(),
      };

      if (failures.isNotEmpty) {
        final buf = StringBuffer()
          ..writeln(
            '${failures.length} of ${filterNames.length} '
            'filters produced mpv errors:',
          )
          ..writeln();
        final sortedKeys = failures.keys.toList()..sort();
        for (final name in sortedKeys) {
          buf.writeln('  - $name:');
          for (final msg in failures[name]!) {
            buf.writeln('      $msg');
          }
        }
        fail(buf.toString());
      }
    }, timeout: const Timeout(Duration(minutes: 3)));

    test('durations under a millisecond reach mpv', () async {
      // av_parse_time refuses an exponent, which these once carried.
      const us500 = Duration(microseconds: 500);
      final errors = await captureChainErrors(player, const [
        AfadeEffect(startTime: us500, duration: us500),
        SilenceremoveEffect(window: us500, startDuration: us500),
        ApadEffect(padDur: us500),
      ]);
      await player.setAudioEffects(const []);
      expect(errors.map((e) => e.text.trim()), isEmpty);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
