#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Regenerates the typed audio effects API (lib/src/generated) and its tests
# (test/generated) from the filters compiled into the pinned libmpv and the
# FFmpeg source they come from. CI runs it and fails on any diff, so the
# generated files never drift from this generator.
#
#   tool/codegen/regen.sh           the package
#   tool/codegen/regen.sh studio    mpv_studio's filter catalog too
#                                   (MPV_STUDIO_ROOT, or ../mpv_studio)
#
# Needs Python 3.11 or later, curl and the Dart SDK.
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$DIR/../.." && pwd)"

# dart format reads the language version from the package config: without
# it, it formats the generated files for another version and they "drift".
if [[ ! -f "$ROOT/.dart_tool/package_config.json" ]]; then
  if command -v flutter >/dev/null; then
    (cd "$ROOT" && flutter pub get)
  else
    echo "regen.sh: no .dart_tool/package_config.json and no flutter on PATH;" \
      "run flutter pub get in $ROOT first" >&2
    exit 1
  fi
fi

"$DIR/fetch_ffmpeg_src.sh"
cd "$DIR"
for stage in parse generate tests; do
  python3 -m lavfi_codegen --config mpv_audio_kit.toml "$stage"
done
if [[ "${1:-}" == "studio" ]]; then
  python3 -m lavfi_codegen --config mpv_audio_kit.toml studio_catalog
fi
cd "$ROOT"
dart format lib/src/generated test/generated >/dev/null
