#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Generates filter-specific test fixtures that the audio-synthesis scripts
# (generate_codec_fixtures.sh / generate_extra_fixtures.sh) can't produce
# because they aren't audio at all.
#
# Currently produces:
#
#   arnndn_model.rnnn     — a tiny RNNoise model for the `arnndn` filter.
#   sine_stereo_48k_5s.flac — the audio the filter runtime tests loop. Every
#                           whitelisted filter takes stereo at 48 kHz
#                           (channelmap needs a second channel, hdcd 44.1 kHz
#                           or more, mcompand a crossover under Nyquist),
#                           and the loop keeps audio flowing through each
#                           new chain, so every filter is really configured.
#
# Why this exists
# ───────────────
# ffmpeg's af_arnndn.c REQUIRES a real model FILE (`m=<path>`); with no
# model the filter hard-fails init with AVERROR(EINVAL). That's exactly the
# "mandatory option left unset" bug class the runtime filter-coverage test
# (test/generated/audio_effects_runtime_coverage_test.dart) is meant to
# catch — but unlike chorus/pan/channelmap/aeval, arnndn's required arg is a
# path to a file on disk, not an inline string. So the runtime test needs a
# real .rnnn on disk to prove arnndn initialises in live mpv. No ffmpeg
# encoder can synthesize one, hence this dedicated generator.
#
# Why a synthetic ZERO-WEIGHT model (instead of downloading a real one)
# ─────────────────────────────────────────────────────────────────────
#   * Reproducible, offline, tiny (~0.8 KB vs the ~85 KB–1.5 MB real models)
#     — no network in CI, nothing to vendor or checksum-pin.
#   * The test asserts arnndn *initialises* (model loads + frames filter
#     without an mpv error), NOT denoise quality. A degenerate all-zero
#     model is sufficient and 100% deterministic (zero weights ⇒ finite,
#     constant activations ⇒ no NaN, no crash).
#   * The layer dimensions satisfy af_arnndn.c's compute_rnn() concatenation
#     EXACTLY, so frame processing reads no out-of-bounds buffer:
#
#       layer           nb_inputs  nb_neurons   note
#       input_dense        42          1        NB_FEATURES = 42 inputs
#       vad_gru             1          1
#       noise_gru          44          1        = input_dense + vad_gru + 42
#       denoise_gru        44          1        = vad_gru + noise_gru + 42
#       denoise_output      1         22        NB_BANDS = 22 gains
#       vad_output          1          1        loader hard-requires == 1
#
#     (af_arnndn.c: INPUT_SIZE/NB_FEATURES=42, NB_BANDS=22, MAX_NEURONS=128,
#      F_ACTIVATION_TANH=0 / SIGMOID=1 / RELU=2, and rnnoise_model_from_file
#      rejects any nb_inputs/nb_neurons outside [0,128] or vad_output != 1.)
#
# Verified end-to-end against host ffmpeg 8.1.1 — byte-for-byte the same
# af_arnndn.c as the bundled libmpv — with:
#
#     ffmpeg -loglevel error -i sine.wav -af arnndn=m=arnndn_model.rnnn -f null -
#
# producing empty stderr@error and a clean exit (mono/stereo, 22k/44k/48k,
# and the mix= option all pass).
#
# HOST-ONLY: written to test/fixtures/ only, mirroring sine_440hz_1s.wav's
# use by the host-only runtime-coverage test. There is no on-device arnndn
# test, so it is intentionally NOT shipped into the test_app asset bundle.
# Re-run this whenever the whitelist gains a filter with a file-backed
# required param; commit the regenerated fixture to git.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives in the package's scripts/ dir, so the package root is one up.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOST_DIR="$REPO_ROOT/test/fixtures"

mkdir -p "$HOST_DIR"

OUT="$HOST_DIR/arnndn_model.rnnn"

# Emit `n` space-separated integer zeros, no trailing newline. One logical
# weight/bias array per line keeps the file in the canonical .rnnn layout
# (rnnoise_model_from_file's NEW_LINE() consumes to end-of-line after each
# header and each array). fscanf("%d") itself is whitespace-agnostic, so
# the per-line grouping is for readability + format fidelity, not parsing.
zeros() {
  local n="$1" out="" i
  for ((i = 0; i < n; i++)); do out+="0 "; done
  printf '%s' "${out% }"
}

# Activations: TANH=0  SIGMOID=1  RELU=2  (af_arnndn.c F_ACTIVATION_*).
# A DENSE layer is read as: "<nb_inputs> <nb_neurons> <act>", then
# (nb_inputs*nb_neurons) input_weights, then (nb_neurons) bias.
# A GRU layer is read as:   "<nb_inputs> <nb_neurons> <act>", then
# (3*nb_inputs*nb_neurons) input_weights, then (3*nb_neurons*nb_neurons)
# recurrent_weights, then (3*nb_neurons) bias.
{
  echo "rnnoise-nu model file version 1"

  # input_dense : 42 -> 1, TANH
  echo "42 1 0"
  zeros $((42 * 1)); echo
  zeros 1; echo

  # vad_gru : 1 -> 1, RELU
  echo "1 1 2"
  zeros $((3 * 1 * 1)); echo
  zeros $((3 * 1 * 1)); echo
  zeros $((3 * 1)); echo

  # noise_gru : 44 -> 1, RELU   (44 = input_dense(1) + vad_gru(1) + 42)
  echo "44 1 2"
  zeros $((3 * 44 * 1)); echo
  zeros $((3 * 1 * 1)); echo
  zeros $((3 * 1)); echo

  # denoise_gru : 44 -> 1, RELU (44 = vad_gru(1) + noise_gru(1) + 42)
  echo "44 1 2"
  zeros $((3 * 44 * 1)); echo
  zeros $((3 * 1 * 1)); echo
  zeros $((3 * 1)); echo

  # denoise_output : 1 -> 22, SIGMOID  (22 = NB_BANDS gains)
  echo "1 22 1"
  zeros $((1 * 22)); echo
  zeros 22; echo

  # vad_output : 1 -> 1, SIGMOID  (nb_neurons MUST be 1)
  echo "1 1 1"
  zeros 1; echo
  zeros 1; echo
} >"$OUT"

TONE="$HOST_DIR/sine_stereo_48k_5s.flac"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=440:duration=5:sample_rate=48000" \
  -af "pan=stereo|c0=c0|c1=c0,volume=0.5" -c:a flac "$TONE"

size_of() { stat -f%z "$1" 2>/dev/null || stat -c%s "$1"; }
echo "Generating filter fixtures…"
echo
printf '  %-24s %6s bytes\n' "arnndn_model.rnnn" "$(size_of "$OUT")"
printf '  %-24s %6s bytes\n' "sine_stereo_48k_5s.flac" "$(size_of "$TONE")"
echo
echo "Done. Written to:"
echo "  $HOST_DIR"
