#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Checks that an app's Frameworks directory holds both the plugin and the
# bundled libmpv, each with its own symbols: under CocoaPods'
# use_frameworks! the plugin is mpv_audio_kit.framework, and libmpv must
# land beside it as libmpv_audio_kit.framework, not over it.
#
#   scripts/ci/check_apple_frameworks.sh <app>/Frameworks
set -euo pipefail

dir="$1"
binary() {
  # A macOS framework keeps its binary under Versions/.
  local fw="$dir/$1.framework"
  if [[ -f "$fw/$1" ]]; then echo "$fw/$1"; else echo "$fw/Versions/A/$1"; fi
}

libmpv="$(binary libmpv_audio_kit)"
nm -gU "$libmpv" | grep -q ' _mpv_create$' ||
  { echo "no mpv_create in $libmpv" >&2; exit 1; }
echo "ok: $libmpv exports mpv_create"

plugin="$(binary mpv_audio_kit)"
if [[ -e "$plugin" ]]; then
  nm -gU "$plugin" | grep -q 'MpvAudioKitPlugin' ||
    { echo "$plugin is not the plugin" >&2; exit 1; }
  echo "ok: $plugin holds the plugin"
fi
