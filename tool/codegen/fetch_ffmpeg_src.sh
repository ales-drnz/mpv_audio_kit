#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Fetches the FFmpeg source the codegen parses (libavfilter AVOption tables
# and the filter docs), at the version the pinned libmpv release was built
# with (libmpv_manifest.json). Idempotent; the tree lands in .ffmpeg-src/,
# which git ignores. The tarball is checked against the SHA-256 pinned below,
# the one libmpv-scripts pins in scripts/shared/_sources.sha256.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['ffmpeg'])" "$DIR/libmpv_manifest.json")"
SRC="$DIR/.ffmpeg-src/ffmpeg-$VERSION"

case "$VERSION" in
  8.1.1) SHA256=1b856f26a07082b6879f3e5300d81e8c7ce3b410ade5898b14382d90c2904634 ;;
  *) echo "no SHA-256 pinned for FFmpeg $VERSION in $0" >&2; exit 1 ;;
esac

[[ -d "$SRC/libavfilter" ]] && exit 0

mkdir -p "$DIR/.ffmpeg-src"
TARBALL="$DIR/.ffmpeg-src/ffmpeg-$VERSION.tar.gz"
curl -fsSL --retry 3 -o "$TARBALL" "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.gz"
if command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TARBALL" | cut -d' ' -f1)"
else
  ACTUAL="$(shasum -a 256 "$TARBALL" | cut -d' ' -f1)"
fi
if [[ "$ACTUAL" != "$SHA256" ]]; then
  rm -f "$TARBALL"
  echo "SHA-256 mismatch for ffmpeg-$VERSION.tar.gz: $ACTUAL" >&2
  exit 1
fi
tar -xzf "$TARBALL" -C "$DIR/.ffmpeg-src"
rm -f "$TARBALL"
[[ -d "$SRC/libavfilter" ]] || { echo "no libavfilter in $SRC" >&2; exit 1; }
echo "FFmpeg $VERSION source ready at $SRC"
