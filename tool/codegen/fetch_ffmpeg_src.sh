#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Fetches the FFmpeg source the codegen parses (libavfilter AVOption tables
# and the filter docs), at the version the pinned libmpv release was built
# with (libmpv_manifest.json). Idempotent; the tree lands in .ffmpeg-src/,
# which git ignores. The tarball is checked against the SHA-256 pinned below,
# the one libmpv-scripts pins in scripts/shared/_sources.sha256, and kept
# there: CI caches it (ci.yml), so ffmpeg.org is reached once per version.
# The tree is extracted beside and renamed once complete, so an extraction
# cut short is never taken for a tree.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['ffmpeg'])" "$DIR/libmpv_manifest.json")"
SRC="$DIR/.ffmpeg-src/ffmpeg-$VERSION"

case "$VERSION" in
  8.1.1) SHA256=1b856f26a07082b6879f3e5300d81e8c7ce3b410ade5898b14382d90c2904634 ;;
  *) echo "no SHA-256 pinned for FFmpeg $VERSION in $0" >&2; exit 1 ;;
esac

[[ -f "$SRC/.complete" ]] && exit 0

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

mkdir -p "$DIR/.ffmpeg-src"
TARBALL="$DIR/.ffmpeg-src/ffmpeg-$VERSION.tar.gz"
if [[ -f "$TARBALL" && "$(sha256 "$TARBALL")" != "$SHA256" ]]; then
  echo "dropping ffmpeg-$VERSION.tar.gz: not the pinned one" >&2
  rm -f "$TARBALL"
fi
if [[ ! -f "$TARBALL" ]]; then
  curl -fsSL --retry 3 -o "$TARBALL.part" "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.gz"
  ACTUAL="$(sha256 "$TARBALL.part")"
  if [[ "$ACTUAL" != "$SHA256" ]]; then
    rm -f "$TARBALL.part"
    echo "SHA-256 mismatch for ffmpeg-$VERSION.tar.gz: $ACTUAL" >&2
    exit 1
  fi
  mv "$TARBALL.part" "$TARBALL"
fi
TMP="$(mktemp -d "$DIR/.ffmpeg-src/.extract.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
tar -xzf "$TARBALL" -C "$TMP"
[[ -d "$TMP/ffmpeg-$VERSION/libavfilter" ]] || { echo "no libavfilter in ffmpeg-$VERSION.tar.gz" >&2; exit 1; }
touch "$TMP/ffmpeg-$VERSION/.complete"
rm -rf "$SRC"
mv "$TMP/ffmpeg-$VERSION" "$SRC"
echo "FFmpeg $VERSION source ready at $SRC"
