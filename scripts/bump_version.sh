#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# bump_version.sh
#
# Updates the library version and/or binary release version across all
# platform files in one shot.
#
# Usage (from the package root):
#   ./scripts/bump_version.sh
#
# Edit these two variables, then run the script:
# =============================================================================

LIB_VERSION="0.4.4"        # Library version (pubspec, podspecs, gradle)
RELEASE_VERSION="libmpv-r12" # Binary release tag (GitHub release download URL)

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
echo "  Release version:  $RELEASE_VERSION"
echo ""

# ── Library version ──────────────────────────────────────────────────────────

# pubspec.yaml
sedi "s|^version: .*|version: $LIB_VERSION|" "$ROOT/pubspec.yaml"
echo "  pubspec.yaml              -> $LIB_VERSION"

# macOS podspec
sedi "s|s\.version *= *'[^']*'|s.version          = '$LIB_VERSION'|" "$ROOT/macos/mpv_audio_kit.podspec"
echo "  macos/mpv_audio_kit.podspec -> $LIB_VERSION"

# iOS podspec
sedi "s|s\.version *= *'[^']*'|s.version          = '$LIB_VERSION'|" "$ROOT/ios/mpv_audio_kit.podspec"
echo "  ios/mpv_audio_kit.podspec   -> $LIB_VERSION"

# Android build.gradle.kts
sedi "s|^version = \"[^\"]*\"|version = \"$LIB_VERSION\"|" "$ROOT/android/build.gradle.kts"
echo "  android/build.gradle.kts    -> $LIB_VERSION"

# ── Release version (binary download tag) ────────────────────────────────────

# macOS podspec
sedi "s|MPV_RELEASE_VERSION=\"[^\"]*\"|MPV_RELEASE_VERSION=\"$RELEASE_VERSION\"|" "$ROOT/macos/mpv_audio_kit.podspec"
echo "  macos podspec release       -> $RELEASE_VERSION"

# iOS podspec
sedi "s|MPV_RELEASE_VERSION=\"[^\"]*\"|MPV_RELEASE_VERSION=\"$RELEASE_VERSION\"|" "$ROOT/ios/mpv_audio_kit.podspec"
echo "  ios podspec release         -> $RELEASE_VERSION"

# Android build.gradle.kts
sedi "s|val MPV_RELEASE_VERSION = \"[^\"]*\"|val MPV_RELEASE_VERSION = \"$RELEASE_VERSION\"|" "$ROOT/android/build.gradle.kts"
echo "  android gradle release      -> $RELEASE_VERSION"

# Linux CMakeLists.txt
sedi "s|set(MPV_RELEASE_VERSION \"[^\"]*\")|set(MPV_RELEASE_VERSION \"$RELEASE_VERSION\")|" "$ROOT/linux/CMakeLists.txt"
echo "  linux CMakeLists release    -> $RELEASE_VERSION"

# Windows CMakeLists.txt
sedi "s|set(MPV_RELEASE_VERSION \"[^\"]*\")|set(MPV_RELEASE_VERSION \"$RELEASE_VERSION\")|" "$ROOT/windows/CMakeLists.txt"
echo "  windows CMakeLists release  -> $RELEASE_VERSION"

# SwiftPM Package.swift binaryTarget URLs (iOS + macOS) — the release tag
# is embedded in the GitHub Releases download URL.
sedi -E "s|releases/download/[^/]+/|releases/download/$RELEASE_VERSION/|" "$ROOT/ios/mpv_audio_kit/Package.swift"
echo "  ios Package.swift release   -> $RELEASE_VERSION"
sedi -E "s|releases/download/[^/]+/|releases/download/$RELEASE_VERSION/|" "$ROOT/macos/mpv_audio_kit/Package.swift"
echo "  macos Package.swift release -> $RELEASE_VERSION"

# README install snippet (`mpv_audio_kit: ^X.Y.Z`)
sedi "s|mpv_audio_kit: \^[0-9][0-9.+-]*|mpv_audio_kit: ^$LIB_VERSION|" "$ROOT/README.md"
echo "  README.md install snippet   -> $LIB_VERSION"

echo ""
echo "Done. Run './build checksums' after building to update SHA-256 hashes."
