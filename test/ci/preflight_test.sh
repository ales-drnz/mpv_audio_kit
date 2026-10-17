#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/preflight.sh on a copy of the real hook/build.dart
# pinned to libmpv-r99, with the fake gh of test/ci/bin serving the
# release and the libmpv-scripts runs.
#
#   bash test/ci/preflight_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
preflight="$repo_root/scripts/ci/preflight.sh"

mkdir -p "$scratch/kit/hook"
cd "$scratch/kit"
sed "s/^const _release = '[^']*';/const _release = 'libmpv-r99';/" \
  "$repo_root/hook/build.dart" > hook/build.dart
grep -q "^const _release = 'libmpv-r99';" hook/build.dart
mapfile -t assets < <(grep -oE "^  'libmpv_[^']+':" hook/build.dart | tr -d "':" | tr -d ' ')
(( ${#assets[@]} >= 9 ))

# The release libmpv-r99 with these assets.
release() {
  printf '%s\n' "$@" | jq -R '{name: .}' | jq -s '{tag_name: "libmpv-r99", assets: .}' \
    > "$FAKE_GH/release/libmpv-r99.json"
}

# Runs the preflight as the changes job does and prints its exit status.
preflight() { # run, token, fork
  local status=0
  LIBMPV_SCRIPTS_RUN="$1" LIBMPV_SCRIPTS_TOKEN="$2" FORK="$3" GH_TOKEN=workflow-token \
    "$preflight" > "$FAKE_GH/log" 2>&1 || status=$?
  echo "$status"
}

new_gh
release "${assets[@]}"
expect_eq "a published release passes" 0 "$(preflight "" "" "")"
expect_eq "looked up with the workflow token on the hook's repository" \
  "workflow-token api repos/ales-drnz/mpv_audio_kit/releases/tags/libmpv-r99 --jq .assets[].name" \
  "$(cat "$FAKE_GH/calls")"

new_gh
expect_eq "a release not published stops the run" 1 "$(preflight "" "" "")"
expect_log "and names the way out" "::error::.*libmpv-r99 is not published.*LIBMPV_SCRIPTS_RUN"

new_gh
release "${assets[@]:1}"
expect_eq "a release without one of its assets stops the run" 1 "$(preflight "" "" "")"
expect_log "and names it" "::error::.*has no ${assets[0]}"

new_gh
touch "$FAKE_GH/down"
expect_eq "a release lookup GitHub cannot answer only warns" 0 "$(preflight "" "" "")"
expect_log "with a warning" "::warning::"

new_gh
expect_eq "a libmpv-scripts run leaves the pinned release alone" 0 \
  "$(preflight 4242 scripts-token "")"
expect_eq "without looking it up" "" "$(grep releases "$FAKE_GH/calls" || true)"

new_gh
expect_eq "a fork without the token checks the pinned release" 1 \
  "$(preflight 4242 "" true)"
expect_log "and warns about the fallback" "::warning::No LIBMPV_SCRIPTS_TOKEN on a fork"

new_gh
release "${assets[@]}"
expect_eq "and passes when it is published" 0 "$(preflight 4242 "" true)"

finish
