#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Generates Tier 1 fixtures used by the metadata-reading and robustness
# tests. Lives next to `generate_codec_fixtures.sh` (codec coverage); the
# split keeps each script focused — re-running one doesn't re-encode files
# whose contract is unrelated.
#
# Files produced (in both `test/fixtures/extra/` and
# `test_app/assets/fixtures/extra/`):
#
#   mp3_with_id3v2.mp3            — MP3 with ID3v2 title/artist/album tags
#   flac_with_vorbis_comments.flac — FLAC with Vorbis comment tags
#   truncated.mp3                  — MP3 with a valid header but cut payload;
#                                    must trigger endFile.error, not crash
#   corrupted.mp3                  — Plain text renamed .mp3; must fail clean
#   vbr_no_xing.mp3                  VBR MP3 without a Xing header, 2 s of
#                                    silence then 4 s of noise: the length
#                                    estimated from the first frames is
#                                    about 18 s, and the waveform keeps it

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives in the package's scripts/ dir, so the package root is one up.
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOST_DIR="$REPO_ROOT/test/fixtures/extra"
DEVICE_DIR="$REPO_ROOT/test_app/assets/fixtures/extra"

if ! command -v ffmpeg >/dev/null 2>&1; then
  echo "Error: ffmpeg not found in PATH." >&2
  exit 1
fi

mkdir -p "$HOST_DIR" "$DEVICE_DIR"

TMP_DIR="$(mktemp -d -t mpv_audio_kit_extra.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

MASTER="$TMP_DIR/master.wav"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "sine=frequency=440:duration=1:sample_rate=48000" \
  -ac 2 -c:a pcm_f32le \
  "$MASTER"

emit_to_both() {
  local out_name="$1"
  local out_path="$2"
  cp "$out_path" "$HOST_DIR/$out_name"
  cp "$out_path" "$DEVICE_DIR/$out_name"
  local size
  size="$(stat -f%z "$out_path" 2>/dev/null || stat -c%s "$out_path")"
  printf '  %-32s %8s bytes\n' "$out_name" "$size"
}

echo "Generating Tier 1 metadata + robustness fixtures…"
echo

# ── Tagged files ──────────────────────────────────────────────────────────
echo "Metadata-tagged:"

# MP3 with ID3v2 tags. ffmpeg writes ID3v2.4 by default with libmp3lame
# when -metadata flags are present. The values are deliberately unicode
# to catch encoding regressions on the wrapper side.
TAGGED_MP3="$TMP_DIR/mp3_with_id3v2.mp3"
ffmpeg -hide_banner -loglevel error -y -i "$MASTER" \
  -ar 44100 -ac 2 -c:a libmp3lame -b:a 128k \
  -metadata title='Test Title — ümlaut & accents' \
  -metadata artist='Test Artist' \
  -metadata album='Test Album' \
  -metadata date='2026' \
  -metadata genre='Electronic' \
  "$TAGGED_MP3"
emit_to_both mp3_with_id3v2.mp3 "$TAGGED_MP3"

# FLAC with Vorbis comments. The FLAC encoder embeds the metadata as
# vorbis comment block, which is a different parser path than ID3v2 in
# mpv — testing both catches reader regressions independently.
TAGGED_FLAC="$TMP_DIR/flac_with_vorbis_comments.flac"
ffmpeg -hide_banner -loglevel error -y -i "$MASTER" \
  -ar 44100 -ac 2 -sample_fmt s16 -c:a flac \
  -metadata title='Vorbis Comment Title' \
  -metadata artist='Vorbis Artist' \
  -metadata album='Vorbis Album' \
  "$TAGGED_FLAC"
emit_to_both flac_with_vorbis_comments.flac "$TAGGED_FLAC"

echo
echo "Robustness:"

# Truncated MP3: take a freshly-encoded MP3 and chop the back half off.
# The file keeps a valid ID3 / first-frame header so the demuxer accepts
# it for opening, then hits a truncated payload and must report
# endFile.error rather than crash.
SOURCE_MP3="$TMP_DIR/source_for_truncate.mp3"
ffmpeg -hide_banner -loglevel error -y -i "$MASTER" \
  -ar 44100 -ac 2 -c:a libmp3lame -b:a 128k "$SOURCE_MP3"
TRUNCATED="$TMP_DIR/truncated.mp3"
# 256 bytes is below the threshold where mpv can locate any complete
# MPEG audio frame: enough for the ID3 header (if any) plus a few bytes
# of frame data, but not a full frame. This forces the demuxer onto the
# error path rather than the lenient "play what you've got, then EOF"
# path triggered by mid-payload truncation.
dd if="$SOURCE_MP3" of="$TRUNCATED" bs=1 count=256 status=none
emit_to_both truncated.mp3 "$TRUNCATED"

# Corrupted MP3: a plain text file renamed .mp3. Header validation in
# the demuxer must fail this immediately — testing the failure path
# itself, not how libmpv recovers from a partial parse.
CORRUPTED="$TMP_DIR/corrupted.mp3"
printf 'this is plain text masquerading as an mp3 — the demuxer must reject it' > "$CORRUPTED"
emit_to_both corrupted.mp3 "$CORRUPTED"

echo
echo "Waveform axis:"

# A VBR MP3 without a Xing header: the demuxer estimates the length from
# the bitrate of the first frames, silent and small, so it reads about
# 18 s for 6 s of audio. The waveform ends its decode with fewer bins than
# its axis.
SILENCE="$TMP_DIR/silence.wav"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "anullsrc=r=44100:cl=mono" -t 2 "$SILENCE"
NOISE="$TMP_DIR/noise.wav"
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i "anoisesrc=r=44100:a=0.5:c=white:seed=1" -t 4 "$NOISE"
VBR_NO_XING="$TMP_DIR/vbr_no_xing.mp3"
ffmpeg -hide_banner -loglevel error -y -i "$SILENCE" -i "$NOISE" \
  -filter_complex "[0:a][1:a]concat=n=2:v=0:a=1" \
  -c:a libmp3lame -q:a 0 -write_xing 0 "$VBR_NO_XING"
emit_to_both vbr_no_xing.mp3 "$VBR_NO_XING"

echo
echo "Done. Files written to:"
echo "  $HOST_DIR"
echo "  $DEVICE_DIR"
