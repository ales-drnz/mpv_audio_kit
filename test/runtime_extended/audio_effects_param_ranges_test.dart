// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Schema-vs-reality runtime gate. The companion to the bare-name
// `audio_effects_chain_runtime_test.dart`: instead of loading each
// filter as `lavfi-<name>` (no params), this test feeds each typed
// `*Settings` corner-case (min / default / max for every numeric
// param) to a live mpv instance via `setAudioEffects` and captures
// any AVOption-rejection errors.
//
// What this catches that the bare-name test misses:
//   * Codegen parser bugs that make `*Min` / `*Max` constants land
//     outside ffmpeg's actual AVOption range (the canonical regression:
//     `drmeter.length` got `min=10, max=None` for months because the
//     parser misread `.01` as a designated initialiser).
//   * Schema↔ffmpeg version drift on a binary bump.
//
// The corner manifest is auto-generated alongside the coverage test
// (see `_audio_effects_param_corners.dart`); this file is a thin
// hand-written iterator with the runtime plumbing.

@TestOn('mac-os || linux || windows')
library;

import 'dart:io';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';
import 'package:test/test.dart';

import '../_helpers/libmpv_resolver.dart';
import '../_helpers/mpv_error_capture.dart';
import '../generated/_audio_effects_param_corners.dart';

void main() {
  final fixturePath =
      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';

  // Same set as in `audio_effects_chain_runtime_test.dart`: filters
  // that compile + register correctly but require additional context
  // (channel layout, model file, custom expression) before mpv will
  // initialise them. Setting just one numeric param is not enough,
  // so corner-case checks for these would always fail.
  const requireParams = {
    'aeval',
    'ametadata',
    'arnndn',
    'asegment',
    'asendcmd',
    'asidedata',
    'astreamselect',
    'channelmap',
    'chorus',
    'headphone',
    'pan',
  };

  // Specific (filter, label) corners that ffmpeg rejects because of
  // CROSS-PARAM constraints the codegen cannot know about. Each one is
  // a relation between two AVOptions on the same filter — setting the
  // tested param to its corner value violates the relation against
  // the other param's default. Not codegen bugs.
  const skipCorners = <String>{
    // surround: ffmpeg requires `lfe_low < lfe_high`. Default
    // lfe_low=128, lfe_high=256.
    //   * `lfe_high=lfe_highMin (0)` < default lfe_low (128) → reject
    //   * `lfe_low=lfe_lowMax (256)` >= default lfe_high (256) → reject
    'surround.lfe_high=lfe_highMin',
    'surround.lfe_low=lfe_lowMax',
    // afade: AVOption declares `start_sample` / `ss` max as I64_MAX,
    // but the filter rejects it at init time — `start_sample +
    // nb_samples` would overflow internally. Min / Default are
    // accepted; only the I64_MAX extreme blows up.
    'afade.start_sample=start_sampleMax',
    'afade.ss=ssMax',
  };

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

    MpvAudioKit.ensureInitialized(libmpv: lib, hotRestartCleanup: false);

    player = Player(
      configuration: const PlayerConfiguration(logLevel: LogLevel.error),
    );
    await player.setRawProperty('ao', 'null');
    await player.open(Media(fixturePath), play: false);
    await player.stream.seekCompleted.first.timeout(
      const Duration(seconds: 10),
    );
  });

  tearDownAll(() async {
    await player.dispose();
  });

  test(
    'every typed numeric param accepts its codegen Min/Default/Max in mpv',
    () async {
      final failures = <String, List<String>>{};
      for (final corner in kFilterParamCorners) {
        if (requireParams.contains(corner.filter)) continue;
        if (skipCorners.contains('${corner.filter}.${corner.label}')) continue;
        final errors = await captureMpvErrors(player, () async {
          await player.setAudioEffects(corner.bundle);
        });
        if (errors.isNotEmpty) {
          final key = '${corner.filter}.${corner.label}';
          failures[key] = errors.map((e) => e.text.trim()).toList();
        }
        // Reset between iterations so a previous failure doesn't bleed
        // into the next drain.
        await player.setAudioEffects(const AudioEffects());
      }

      if (failures.isNotEmpty) {
        final buf = StringBuffer()
          ..writeln(
            '${failures.length} of ${kFilterParamCorners.length} typed '
            'param-corner cases produced mpv errors:',
          )
          ..writeln();
        final sortedKeys = failures.keys.toList()..sort();
        for (final key in sortedKeys) {
          buf.writeln('  - $key:');
          for (final msg in failures[key]!) {
            buf.writeln('      $msg');
          }
        }
        fail(buf.toString());
      }
    },
    timeout: const Timeout(Duration(minutes: 8)),
  );
}
