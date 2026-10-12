#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license.
#
# Native test runner for the Apple (macOS + iOS) MediaSessionPlugin.
#
# What it does:
#   1. Compiles `darwin/Sources/mpv_audio_kit/MediaSessionPlugin.swift`
#      together with `test/media_session/darwin/main.swift` into a
#      single Mach-O executable.
#   2. Links against `FlutterMacOS.framework` (materialized by a
#      previous `flutter build macos` of test_app) and
#      `MediaPlayer.framework`.
#   3. Runs the executable, which drives the plugin (enable,
#      updatePlayback, handleScrub, disable) and asserts against the
#      real `MPNowPlayingInfoCenter.default()` and
#      `MPRemoteCommandCenter.shared()` after each step.
#
# Requirements:
#   • macOS (uses `swiftc` and Apple frameworks).
#   • test_app must have been built at least once so the
#     Flutter framework is on disk:
#       (cd test_app && flutter build macos --debug)
#
# Usage:
#   bash test/media_session/darwin/run.sh
#
# Why this lives next to the platform-shared darwin/ Swift source
# rather than inside `darwin/Sources/`: SwiftPM rejects test targets
# that share a folder with a library target, and shipping these as
# part of the published package would bloat pub.dev. They are pure
# internal tooling for the maintainer.
set -euo pipefail

OS=$(uname -s)
if [ "$OS" != "Darwin" ]; then
  echo "media-session/darwin tests require macOS (uname -s=Darwin). Got: $OS"
  exit 2
fi

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
FLUTTER_FW_DIR="$REPO_ROOT/test_app/build/macos/Build/Products/Debug"

if [ ! -d "$FLUTTER_FW_DIR/FlutterMacOS.framework" ]; then
  echo "FlutterMacOS.framework not found at:" >&2
  echo "  $FLUTTER_FW_DIR" >&2
  echo "Build test_app first:" >&2
  echo "  (cd test_app && flutter build macos --debug)" >&2
  exit 2
fi

OUT="$REPO_ROOT/test/media_session/darwin/.build"
mkdir -p "$OUT"
BIN="$OUT/scrub_flow_tests"

swiftc \
  -target arm64-apple-macos12.0 \
  -F "$FLUTTER_FW_DIR" \
  -framework FlutterMacOS \
  -framework MediaPlayer \
  -framework AppKit \
  -Xlinker -rpath -Xlinker "$FLUTTER_FW_DIR" \
  -o "$BIN" \
  "$REPO_ROOT/darwin/Sources/mpv_audio_kit/MediaSessionPlugin.swift" \
  "$REPO_ROOT/test/media_session/darwin/main.swift"

echo
DYLD_FRAMEWORK_PATH="$FLUTTER_FW_DIR" exec "$BIN"
