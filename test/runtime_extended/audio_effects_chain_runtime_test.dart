// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Per-filter runtime gate. Reads the libavfilter audio-filter list from
// `scripts/lavfi_codegen/schema.json`, applies each one in isolation as
// a raw `lavfi-<name>` chain via `AudioEffects.custom`, and collects
// every mpv `error`/`fatal` log entry. The test fails with the full
// per-filter report so a single run surfaces ALL unusable filters
// (whether for missing ffmpeg deps or 1-in/1-out gating in mpv's
// lavfi-bridge) rather than failing on the first one.

@TestOn('mac-os || linux || windows')
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/mpv_error_capture.dart';

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';
  final schemaPath =
      '${Directory.current.path}/scripts/lavfi_codegen/schema.json';

  // Filters that compile + register correctly in libavfilter and pass
  // mpv's 1-in/1-out gate, but require at least one option to be set
  // before they can initialise. Bare `lavfi-<name>` invocation fails
  // with "filter failed to initialize". The typed `*Settings` API
  // exposes them — the consumer is expected to provide the required
  // params via copyWith/setAudioEffects. This test skips the bare-name
  // invocation since it has no way to fabricate sensible required
  // values across all of them.
  const requireParams = {
    'aeval',         // expression(s)
    'ametadata',     // mode + key
    'arnndn',        // model file
    'asegment',      // timestamps or counts
    'asendcmd',      // commands or filename
    'asidedata',     // side data type
    'astreamselect', // mapping definition
    'channelmap',    // output layout / map
    'chorus',        // delays/decays/speeds/depths
    'headphone',     // HRTF mapping
    'pan',           // channel layout + definitions
  };

  late List<String> filterNames;
  late Player player;

  setUpAll(() async {
    final lib = resolveLibmpv();
    if (lib == null) {
      markTestSkipped('libmpv not found');
      return;
    }
    if (!File(fixturePath).existsSync()) {
      markTestSkipped('Fixture missing: $fixturePath');
      return;
    }
    if (!File(schemaPath).existsSync()) {
      markTestSkipped('schema.json missing: $schemaPath');
      return;
    }

    final schema =
        jsonDecode(File(schemaPath).readAsStringSync()) as Map<String, dynamic>;
    final filters = (schema['filters'] as Map<String, dynamic>).keys.toList()
      ..sort();
    filterNames = filters;

    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);

    // logLevel must be at least 'error' to receive the diagnostics we
    // grep for. Default helper builds with 'no'.
    player = Player(
      configuration: const PlayerConfiguration(
        autoPlay: false,
        logLevel: 'error',
      ),
    );
    await player.setRawProperty('ao', 'null');
    await player.open(Media(fixturePath), play: false);
    // Wait for file-loaded so the audio chain is live; otherwise
    // setting `af` may be deferred and not surface load errors.
    await player.stream.seekCompleted.first
        .timeout(const Duration(seconds: 10));
  });

  tearDownAll(() async {
    await player.dispose();
  });

  test(
    'every libavfilter audio filter in schema.json loads in mpv\'s `af` chain',
    () async {
      final failures = <String, List<String>>{};

      for (final name in filterNames) {
        if (requireParams.contains(name)) {
          continue;
        }
        final errors = await captureMpvErrors(player, () async {
          await player.setAudioEffects(
            AudioEffects(custom: ['lavfi-$name']),
          );
        });
        if (errors.isNotEmpty) {
          failures[name] = errors.map((e) => e.text.trim()).toList();
        }
        // Reset so the next iteration starts from a clean chain — and
        // any error from THIS filter doesn't bleed into the next drain.
        await player.setAudioEffects(const AudioEffects());
      }

      if (failures.isNotEmpty) {
        final buf = StringBuffer()
          ..writeln('${failures.length} of ${filterNames.length} '
              'filters produced mpv errors:')
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
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
