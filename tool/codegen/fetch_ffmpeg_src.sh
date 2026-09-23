#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Fetches the FFmpeg source the codegen parses (libavfilter AVOption tables
# and the filter docs), at the version the pinned libmpv release was built
# with (libmpv_manifest.json). Idempotent; the tree lands in .ffmpeg-src/,
# which git ignores.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERSION="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['ffmpeg'])" "$DIR/libmpv_manifest.json")"
SRC="$DIR/.ffmpeg-src/ffmpeg-$VERSION"

[[ -d "$SRC/libavfilter" ]] && exit 0

mkdir -p "$DIR/.ffmpeg-src"
TARBALL="$DIR/.ffmpeg-src/ffmpeg-$VERSION.tar.gz"
curl -fsSL --retry 3 -o "$TARBALL" "https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.gz"
tar -xzf "$TARBALL" -C "$DIR/.ffmpeg-src"
rm -f "$TARBALL"
[[ -d "$SRC/libavfilter" ]] || { echo "no libavfilter in $SRC" >&2; exit 1; }
echo "FFmpeg $VERSION source ready at $SRC"
