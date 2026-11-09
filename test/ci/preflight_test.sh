#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/preflight.sh on copies of the real hook/build.dart and
# lib/src/internals/libmpv_release.dart, pinned to libmpv-r99, with the
# fake gh of test/ci/bin serving the release and the libmpv-scripts runs.
#
#   bash test/ci/preflight_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
preflight="$repo_root/scripts/ci/preflight.sh"

mkdir -p "$scratch/kit/hook" "$scratch/kit/lib/src/internals" "$scratch/kit/webos" "$scratch/kit/tvos"
cd "$scratch/kit"
cp "$repo_root/hook/build.dart" hook/build.dart
cp "$repo_root/webos/CMakeLists.txt" webos/CMakeLists.txt
cp "$repo_root/tvos/Package.swift" tvos/Package.swift
sed "s/^const String libmpvRelease = '[^']*';/const String libmpvRelease = 'r99';/" \
  "$repo_root/lib/src/internals/libmpv_release.dart" \
  > lib/src/internals/libmpv_release.dart
grep -q "^const String libmpvRelease = 'r99';" lib/src/internals/libmpv_release.dart
mapfile -t assets < <(grep -oE "^  'libmpv_[^']+':" hook/build.dart | tr -d "':" | tr -d ' ')
(( ${#assets[@]} >= 9 ))
# And the two pinned outside the hook, by the files that bundle them.
assets+=(libmpv_webos-armv7l.so libmpv_tvos.xcframework.zip)

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
expect_log "and names the way out" "::error::.*libmpv-r99 is not published.*resolve_libmpv_run.sh"

new_gh
release "${assets[@]:1}"
expect_eq "a release without one of its assets stops the run" 1 "$(preflight "" "" "")"
expect_log "and names it" "::error::.*has no ${assets[0]}"

# A row with no SHA yet (a platform the next release adds) is not pinned:
# the release need not have it.
cp hook/build.dart "$scratch/build.dart.pinned"
sed -i "s/^const _sha256 = <String, String>{\$/&\\n  'libmpv_future.so': '',/" hook/build.dart
grep -q "^  'libmpv_future.so': ''," hook/build.dart
new_gh
release "${assets[@]}"
expect_eq "a row not pinned yet is not asked of the release" 0 "$(preflight "" "" "")"
cp "$scratch/build.dart.pinned" hook/build.dart

# webOS and tvOS take their libmpv from the same release, pinned in
# webos/CMakeLists.txt and tvos/Package.swift: a release without one fails
# every build of that platform.
for outside in libmpv_webos-armv7l.so libmpv_tvos.xcframework.zip; do
  new_gh
  kept=()
  for a in "${assets[@]}"; do [[ "$a" == "$outside" ]] || kept+=("$a"); done
  release "${kept[@]}"
  expect_eq "a release without $outside stops the run" 1 "$(preflight "" "" "")"
  expect_log "and names it" "::error::.*has no $outside"
done

# A webOS SHA-256 not pinned yet is not asked of the release.
cp webos/CMakeLists.txt "$scratch/CMakeLists.txt.pinned"
sed -i 's/^set(MAK_LIBMPV_SHA256 "[0-9a-f]*")$/set(MAK_LIBMPV_SHA256 "")/' webos/CMakeLists.txt
grep -q '^set(MAK_LIBMPV_SHA256 "")$' webos/CMakeLists.txt
new_gh
kept=()
for a in "${assets[@]}"; do [[ "$a" == libmpv_webos-armv7l.so ]] || kept+=("$a"); done
release "${kept[@]}"
expect_eq "a webOS libmpv not pinned yet is not asked of the release" 0 "$(preflight "" "" "")"
cp "$scratch/CMakeLists.txt.pinned" webos/CMakeLists.txt

new_gh
touch "$FAKE_GH/down"
expect_eq "a release lookup GitHub cannot answer only warns" 0 "$(preflight "" "" "")"
expect_log "with a warning" "::warning::"

# The libmpv-scripts run 4242, finished with $1.
scripts_run() {
  echo "{\"id\":4242,\"head_sha\":\"abc123\",\"head_branch\":\"release/r99\",\"conclusion\":\"$1\"}" \
    > "$FAKE_GH/run/4242.json"
}

new_gh
scripts_run success
expect_eq "a green libmpv-scripts run passes" 0 "$(preflight 4242 scripts-token "")"
expect_log "and says which build is under test" "run 4242: release/r99 at abc123"
expect_eq "looked up with LIBMPV_SCRIPTS_TOKEN, leaving the pinned release alone" \
  "scripts-token api repos/ales-drnz/libmpv-scripts/actions/runs/4242" \
  "$(cut -d' ' -f1-3 "$FAKE_GH/calls")"

new_gh
scripts_run success
expect_eq "a libmpv-scripts run without the token stops the run" 1 "$(preflight 4242 "" "")"
expect_log "and names the secret" "::error::LIBMPV_SCRIPTS_RUN is set but LIBMPV_SCRIPTS_TOKEN is not"

new_gh
scripts_run success
echo scripts-token > "$FAKE_GH/expired"
expect_eq "an expired token stops the run" 1 "$(preflight 4242 scripts-token "")"
expect_log "and says it expired" "::error::LIBMPV_SCRIPTS_TOKEN was refused (HTTP 401).*expired"

new_gh
expect_eq "a run the token cannot see stops the run" 1 "$(preflight 4242 scripts-token "")"
expect_log "and says so" "::error::.*run 4242.*HTTP 404"

new_gh
scripts_run failure
expect_eq "a run that failed stops the run" 1 "$(preflight 4242 scripts-token "")"
expect_log "and says so" "::error::libmpv-scripts run 4242 did not succeed (failure)"

new_gh
touch "$FAKE_GH/down"
expect_eq "a run lookup GitHub cannot answer only warns" 0 \
  "$(preflight 4242 scripts-token "")"
expect_log "with a warning" "::warning::"

new_gh
expect_eq "a fork without the token checks the pinned release" 1 \
  "$(preflight 4242 "" true)"
expect_log "and warns about the fallback" "::warning::No LIBMPV_SCRIPTS_TOKEN on a fork"

new_gh
release "${assets[@]}"
expect_eq "and passes when it is published" 0 "$(preflight 4242 "" true)"

finish
