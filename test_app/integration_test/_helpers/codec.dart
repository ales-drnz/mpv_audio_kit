// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// Codec coverage helper — framework-agnostic, used by both the host suite
// (`test/runtime_extended/codec_coverage_test.dart`) and the device app
// (`test_app/integration_test/codec_coverage_test.dart`). The two callers
// import this file from different framework worlds (`package:test` vs
// `package:flutter_test`); to stay compatible with both, this helper does
// I/O and returns data — it never calls `expect()`. The caller asserts.
//
// The matrix lists every codec / container / sample-rate / channel-count
// combination produced by `scripts/generate_codec_fixtures.sh`. To add a
// new codec: add a row here, add the encoder line to the script, run the
// script, commit the new fixture in both `test/fixtures/codec/` and
// `test_app/assets/fixtures/codec/`.
//
// **Keep this file in lock-step with `test_app/integration_test/_helpers/codec.dart`.**
// Both copies must have identical content. There's no test_support package
// to deduplicate them today — the shared logic is small enough (~80 lines)
// that two copies are cheaper than the indirection of a sub-package.

import 'dart:async';

import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// What we expect mpv to report for a codec fixture once it's loaded.
///
/// `sampleRate` and `channels` are the load-bearing assertions: they round-trip
/// through the demuxer and confirm the binary decodes the codec correctly.
/// `codecHint` is a substring match (mpv codec ids vary across builds:
/// `mp3` vs `mp3float`, `aac` vs `aac_lc`, etc.); the test treats a `null`
/// hint as "any codec is fine, only sample-rate / channels matter".
class CodecExpectation {
  final String label;
  final int sampleRate;
  final int channels;
  final String? codecHint;

  const CodecExpectation({
    required this.label,
    required this.sampleRate,
    required this.channels,
    this.codecHint,
  });
}

class CodecResult {
  final AudioParams params;
  final Duration duration;

  CodecResult({required this.params, required this.duration});
}

/// Builds a Player wired for tests: no audio device, no auto-play, no logs.
/// Callers `await player.dispose()` once the per-test cycle completes.
Future<Player> createTestPlayer() async {
  final p = Player(
    configuration: const PlayerConfiguration(
      autoPlay: false,
      logLevel: 'no',
    ),
  );
  await p.setRawProperty('ao', 'null');
  return p;
}

/// Waits for the mpv `PLAYBACK_RESTART` event (exposed as `seekCompleted`),
/// which fires exactly once per `loadfile` after the demuxer has settled.
/// Anchoring on this rather than `duration` avoids the dedup race where a
/// new fixture with the same duration as the previous one wouldn't emit.
Future<void> waitForFileLoaded(
  Player p, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final c = Completer<void>();
  final sub = p.stream.seekCompleted.listen((_) {
    if (!c.isCompleted) c.complete();
  });
  try {
    await c.future.timeout(timeout);
  } finally {
    await sub.cancel();
  }
}

/// Opens [path] on [p], waits for `audioParams` to settle on the values
/// declared by [expected], and returns the observed result. Asserting is
/// the caller's job — this helper stays framework-agnostic so
/// `package:test` (host) and `package:flutter_test` (device) can both
/// use it.
///
/// `audioParams` is an aggregate cell fed by three mpv specs
/// (`audio-params`, `audio-codec`, `audio-codec-name`); they don't
/// emit in lockstep. A naive wait on sample-rate alone returns while
/// the codec field is still stale from the previous fixture. We
/// therefore match the full triple — sample-rate, channels, AND the
/// codec hint when supplied — so the helper only returns once every
/// dimension we care about has settled on the new file.
bool _matches(AudioParams p, CodecExpectation e) {
  if (p.sampleRate != e.sampleRate) return false;
  if (p.channelCount != e.channels) return false;
  if (e.codecHint != null) {
    final h = e.codecHint!.toLowerCase();
    final c = (p.codec ?? '').toLowerCase();
    final cn = (p.codecName ?? '').toLowerCase();
    if (!c.contains(h) && !cn.contains(h)) return false;
  }
  return true;
}

Future<CodecResult> verifyCodec(
  Player p,
  String path,
  CodecExpectation expected,
) async {
  // Short-circuit on already-settled params (consecutive fixtures with
  // identical triple — e.g. aac_lc → aac_adts, ac3 → eac3): dedup means
  // no new emit will fire, so the stream wait would hang.
  final alreadySettled = _matches(p.state.audioParams, expected);

  Future<AudioParams>? paramsFuture;
  if (!alreadySettled) {
    paramsFuture = p.stream.audioParams
        .firstWhere((x) => _matches(x, expected))
        .timeout(const Duration(seconds: 10));
  }

  await p.open(Media(path), play: false);
  await waitForFileLoaded(p);

  final params =
      paramsFuture != null ? await paramsFuture : p.state.audioParams;
  return CodecResult(params: params, duration: p.state.duration);
}

/// (filename, expectation) pairs — sorted by family for readability.
/// Each filename matches the output of `scripts/generate_codec_fixtures.sh`.
const codecMatrix = <(String, CodecExpectation)>[
  // Lossy
  (
    'mp3_44100_stereo.mp3',
    CodecExpectation(
        label: 'MP3 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'mp3')
  ),
  (
    'mp3_48000_mono.mp3',
    CodecExpectation(
        label: 'MP3 48 kHz mono',
        sampleRate: 48000,
        channels: 1,
        codecHint: 'mp3')
  ),
  (
    'aac_lc_44100.m4a',
    CodecExpectation(
        label: 'AAC-LC 44.1 kHz stereo (m4a)',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'aac')
  ),
  (
    'aac_adts_44100.aac',
    CodecExpectation(
        label: 'AAC ADTS 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'aac')
  ),

  // Lossless
  (
    'flac_44100_16bit.flac',
    CodecExpectation(
        label: 'FLAC 44.1 kHz 16-bit',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'flac')
  ),
  (
    'flac_88200_24bit.flac',
    CodecExpectation(
        label: 'FLAC 88.2 kHz 24-bit',
        sampleRate: 88200,
        channels: 2,
        codecHint: 'flac')
  ),
  (
    'flac_192000_24bit.flac',
    CodecExpectation(
        label: 'FLAC 192 kHz 24-bit',
        sampleRate: 192000,
        channels: 2,
        codecHint: 'flac')
  ),
  (
    'alac_44100.m4a',
    CodecExpectation(
        label: 'ALAC 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'alac')
  ),

  // Open-source
  (
    'opus_48000_stereo.opus',
    CodecExpectation(
        label: 'Opus 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'opus')
  ),
  (
    'vorbis_44100_stereo.ogg',
    CodecExpectation(
        label: 'Vorbis 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'vorbis')
  ),

  // Dolby
  (
    'ac3_48000_stereo.ac3',
    CodecExpectation(
        label: 'AC-3 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'ac3')
  ),
  (
    'eac3_48000_stereo.eac3',
    CodecExpectation(
        label: 'E-AC-3 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'eac3')
  ),

  // Uncompressed PCM
  (
    'wav_pcm_s16_44100.wav',
    CodecExpectation(
        label: 'WAV PCM s16 44.1 kHz',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'wav_pcm_s24_48000.wav',
    CodecExpectation(
        label: 'WAV PCM s24 48 kHz',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'wav_pcm_s32_96000.wav',
    CodecExpectation(
        label: 'WAV PCM s32 96 kHz',
        sampleRate: 96000,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'aiff_pcm_44100.aiff',
    CodecExpectation(
        label: 'AIFF PCM 44.1 kHz',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'pcm')
  ),

  // Pro / broadcast / lossless extras
  (
    'dts_48000_stereo.dts',
    CodecExpectation(
        label: 'DTS Coherent Acoustics 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'dts')
  ),
  (
    'mlp_48000_stereo.mlp',
    CodecExpectation(
        label: 'Dolby MLP 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'mlp')
  ),
  (
    'truehd_48000_stereo.thd',
    CodecExpectation(
        label: 'Dolby TrueHD 48 kHz stereo',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'truehd')
  ),
  (
    'tta_44100.tta',
    CodecExpectation(
        label: 'TrueAudio (TTA) 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'tta')
  ),
  (
    'wavpack_44100.wv',
    CodecExpectation(
        label: 'WavPack 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'wavpack')
  ),
  (
    'mp2_44100.mp2',
    CodecExpectation(
        label: 'MPEG Audio Layer II 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'mp2')
  ),

  // WMA family
  (
    'wma_v1_44100.wma',
    CodecExpectation(
        label: 'WMA v1 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'wmav1')
  ),
  (
    'wma_v2_44100.wma',
    CodecExpectation(
        label: 'WMA v2 44.1 kHz stereo',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'wmav2')
  ),

  // ADPCM (telephony / legacy)
  (
    'adpcm_ms_22050.wav',
    CodecExpectation(
        label: 'ADPCM Microsoft 22.05 kHz stereo',
        sampleRate: 22050,
        channels: 2,
        codecHint: 'adpcm')
  ),
  (
    'adpcm_ima_qt_22050.mov',
    CodecExpectation(
        label: 'ADPCM IMA QuickTime 22.05 kHz stereo',
        sampleRate: 22050,
        channels: 2,
        codecHint: 'adpcm')
  ),

  // PCM long-tail (μ-law / a-law / float / big-endian)
  (
    'pcm_alaw_8000.wav',
    CodecExpectation(
        label: 'PCM A-law 8 kHz stereo',
        sampleRate: 8000,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'pcm_mulaw_8000.wav',
    CodecExpectation(
        label: 'PCM μ-law 8 kHz stereo',
        sampleRate: 8000,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'pcm_f32le_44100.wav',
    CodecExpectation(
        label: 'PCM 32-bit float LE 44.1 kHz',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'pcm_f64le_44100.wav',
    CodecExpectation(
        label: 'PCM 64-bit float LE 44.1 kHz',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'pcm_s32be_48000.aiff',
    CodecExpectation(
        label: 'PCM s32 big-endian 48 kHz (AIFF)',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'pcm')
  ),
  (
    'pcm_s24be_48000.aiff',
    CodecExpectation(
        label: 'PCM s24 big-endian 48 kHz (AIFF)',
        sampleRate: 48000,
        channels: 2,
        codecHint: 'pcm')
  ),

  // Containers
  (
    'mka_flac.mka',
    CodecExpectation(
        label: 'Matroska + FLAC',
        sampleRate: 44100,
        channels: 2,
        codecHint: 'flac')
  ),
  (
    'webm_opus.webm',
    CodecExpectation(
        label: 'WebM + Opus', sampleRate: 48000, channels: 2, codecHint: 'opus')
  ),
];
