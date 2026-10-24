#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# bump_version.sh
#
# Updates the library version across all platform files in one shot. The
# libmpv binary release is set separately, by scripts/update_libmpv.sh.
#
# Usage (from the package root):
#   ./scripts/bump_version.sh
#
# Edit this variable, then run the script:
# =============================================================================

LIB_VERSION="0.5.3"

# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This script lives in the package's scripts/ dir, so the package root is one up.
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# sed in-place that works on both macOS and Linux
sedi() {
  if [[ "$OSTYPE" == darwin* ]]; then
    sed -i '' "$@"
  else
    sed -i "$@"
  fi
}

echo "=== mpv_audio_kit: bumping versions ==="
echo "  Library version:  $LIB_VERSION"
echo ""

# ── Library version ──────────────────────────────────────────────────────────

# pubspec.yaml
sedi "s|^version: .*|version: $LIB_VERSION|" "$ROOT/pubspec.yaml"
echo "  pubspec.yaml              -> $LIB_VERSION"

# iOS and macOS podspec
sedi "s|s\.version *= *'[^']*'|s.version          = '$LIB_VERSION'|" "$ROOT/darwin/mpv_audio_kit.podspec"
echo "  darwin/mpv_audio_kit.podspec -> $LIB_VERSION"

# Android build.gradle.kts
sedi "s|^version = \"[^\"]*\"|version = \"$LIB_VERSION\"|" "$ROOT/android/build.gradle.kts"
echo "  android/build.gradle.kts    -> $LIB_VERSION"

# README install snippet (`mpv_audio_kit: ^X.Y.Z`)
sedi "s|mpv_audio_kit: \^[0-9][0-9.+-]*|mpv_audio_kit: ^$LIB_VERSION|" "$ROOT/README.md"
echo "  README.md install snippet   -> $LIB_VERSION"

echo ""
echo "Done."
