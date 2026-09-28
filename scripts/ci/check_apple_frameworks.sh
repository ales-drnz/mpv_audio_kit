#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Checks that an app's Frameworks directory holds the bundled libmpv as
# libmpv_audio_kit.framework, with its symbols. With --expect-plugin it
# must also hold the plugin itself: under CocoaPods' use_frameworks! that
# is mpv_audio_kit.framework, and libmpv must land beside it, not over it.
# On iOS the libmpv framework must target iOS 15 or later, the version
# the binary is built for.
#
#   scripts/ci/check_apple_frameworks.sh [--expect-plugin] <app>/Frameworks
set -euo pipefail

expect_plugin=0
if [[ "${1:-}" == --expect-plugin ]]; then
  expect_plugin=1
  shift
fi
dir="$1"

binary() {
  # A macOS framework keeps its binary under Versions/.
  local fw="$dir/$1.framework"
  if [[ -f "$fw/$1" ]]; then echo "$fw/$1"; else echo "$fw/Versions/A/$1"; fi
}

# nm's output is read whole before matching: grep -q stopping early would
# make nm fail on SIGPIPE, which pipefail reports as a missing symbol.
exports() { nm -gU "$1"; }

libmpv="$(binary libmpv_audio_kit)"
symbols="$(exports "$libmpv")"
grep -q ' _mpv_create$' <<<"$symbols" ||
  { echo "no mpv_create in $libmpv" >&2; exit 1; }
echo "ok: $libmpv exports mpv_create"

plist="$dir/libmpv_audio_kit.framework/Info.plist"
if [[ -f "$plist" ]]; then
  # iOS frameworks keep Info.plist at the top, macOS ones under Resources/.
  min="$(plutil -extract MinimumOSVersion raw "$plist")"
  if (( ${min%%.*} < 15 )); then
    echo "$plist has MinimumOSVersion $min, below the iOS 15 of libmpv" >&2
    exit 1
  fi
  echo "ok: MinimumOSVersion $min"
fi

plugin="$(binary mpv_audio_kit)"
if [[ -e "$plugin" ]]; then
  symbols="$(exports "$plugin")"
  grep -q 'MpvAudioKitPlugin' <<<"$symbols" ||
    { echo "$plugin is not the plugin" >&2; exit 1; }
  echo "ok: $plugin holds the plugin"
elif (( expect_plugin )); then
  echo "no plugin framework in $dir" >&2
  exit 1
fi
