#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/resolve_libmpv_run.sh on copies of the real
# hook/build.dart, lib/src/internals/libmpv_release.dart and
# lib/src/internals/libmpv_requirements.dart, with the fake gh of
# test/ci/bin serving the kit's releases and the libmpv-scripts Builds.
#
#   bash test/ci/resolve_libmpv_run_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
resolve="$repo_root/scripts/ci/resolve_libmpv_run.sh"

kit="$scratch/kit"
mkdir -p "$kit/hook" "$kit/lib/src/internals"
cp "$repo_root/hook/build.dart" "$kit/hook/build.dart"

# Pins the kit copy to release r$1 with minimum r$2.
kit() { # pin, minimum
  sed "s/^const String libmpvRelease = '[^']*';/const String libmpvRelease = 'r$1';/" \
    "$repo_root/lib/src/internals/libmpv_release.dart" \
    > "$kit/lib/src/internals/libmpv_release.dart"
  sed "s/^const int libmpvMinimumRelease = [0-9]*;/const int libmpvMinimumRelease = $2;/" \
    "$repo_root/lib/src/internals/libmpv_requirements.dart" \
    > "$kit/lib/src/internals/libmpv_requirements.dart"
  grep -q "^const String libmpvRelease = 'r$1';" "$kit/lib/src/internals/libmpv_release.dart"
  grep -q "^const int libmpvMinimumRelease = $2;" "$kit/lib/src/internals/libmpv_requirements.dart"
}

# The kit's release libmpv-r$1, published.
published() { echo "{\"tag_name\": \"libmpv-r$1\", \"assets\": []}" > "$FAKE_GH/release/libmpv-r$1.json"; }

# The build.yml runs of libmpv-scripts, newest first, each given as
# id:branch:event:status:conclusion (conclusion null for a run going on).
builds() {
  local spec id branch event status conclusion runs=()
  for spec in "$@"; do
    IFS=: read -r id branch event status conclusion <<<"$spec"
    [[ "$conclusion" == null ]] || conclusion="\"$conclusion\""
    runs+=("{\"id\":$id,\"head_branch\":\"$branch\",\"event\":\"$event\",\"status\":\"$status\",\"conclusion\":$conclusion,\"head_sha\":\"sha$id\",\"created_at\":\"2026-10-0${#runs[@]}T00:00:00Z\"}")
  done
  local IFS=,
  echo "[${runs[*]}]" > "$FAKE_GH/builds.json"
}

# Runs the resolver as the changes job does: prints its exit status, keeps
# what it printed on stdout in $FAKE_GH/out and the rest in $FAKE_GH/log.
# Extra environment comes from the arguments (NAME=value).
run() {
  local status=0
  env LIBMPV_SCRIPTS_RUN= GH_TOKEN=scripts-token RELEASE_TOKEN=workflow-token \
    KIT_ROOT="$kit" "$@" "$resolve" > "$FAKE_GH/out" 2> "$FAKE_GH/log" || status=$?
  echo "$status"
}
out() { cat "$FAKE_GH/out"; }
calls() { wc -l < "$FAKE_GH/calls" | tr -d ' '; }
no_warning() { grep -c '::warning::\|::error::' "$FAKE_GH/log" || true; }

# A run given by hand.

new_gh
kit 19 20
expect_eq "a run given by hand passes" 0 "$(run LIBMPV_SCRIPTS_RUN=777)"
expect_eq "and is printed as it is" 777 "$(out)"
expect_eq "without asking GitHub" 0 "$(calls)"

# The pin.

new_gh
kit 20 20
published 20
expect_eq "a pin at the minimum, published, passes" 0 "$(run)"
expect_eq "and prints nothing" "" "$(out)"
expect_eq "with no warning" 0 "$(no_warning)"
expect_eq "looked up with the workflow token on the hook's repository" \
  "workflow-token api repos/ales-drnz/mpv_audio_kit/releases/tags/libmpv-r20 --jq .tag_name" \
  "$(cat "$FAKE_GH/calls")"

new_gh
kit 21 20
published 21
expect_eq "a pin past the minimum, published, prints nothing" "0 " "$(run) $(out)"

new_gh
kit 19 20
published 20
builds 9:release/r20:push:completed:success
expect_eq "the minimum published past the pin passes" 0 "$(run)"
expect_eq "and prints nothing: the jobs keep the pin" "" "$(out)"
expect_log "with a warning that the pin must move" \
  "::warning::libmpv-r20 is published and the pin is still r19: run scripts/update_libmpv.sh r20"
expect_eq "and no Build lookup" 1 "$(calls)"

# The Build of release/rN.

new_gh
kit 19 20
builds 12:wip/r20-x:workflow_dispatch:completed:success \
  11:release/r20:push:completed:success 10:release/r20:push:completed:success
expect_eq "the latest push Build of release/r20 passes" 0 "$(run)"
expect_eq "and is printed" 11 "$(out)"
expect_log "with its branch, commit and date" \
  "libmpv-scripts run 11: release/r20 at sha11, 2026-10-01T00:00:00Z, success"
expect_eq "listed with the libmpv-scripts token" 1 \
  "$(grep -c '^scripts-token api repos/ales-drnz/libmpv-scripts/actions/workflows/build.yml/runs?branch=release/r20&event=push' "$FAKE_GH/calls")"

new_gh
kit 19 20
builds 13:release/r20:push:completed:failure 12:release/r20:push:completed:success
expect_eq "a latest Build that failed passes" 0 "$(run)"
expect_eq "on the previous successful one" 12 "$(out)"
expect_log "and says so" "The latest Build of release/r20, run 13 (sha13, .*), is failure: taking the latest successful one"

new_gh
kit 19 20
builds 14:release/r20:push:in_progress:null 12:release/r20:push:completed:success
expect_eq "a latest Build still going gives the previous successful one" "0 12" "$(run) $(out)"
expect_log "and says so" "run 14 .* is in_progress"

new_gh
kit 19 20
builds 15:release/r20:workflow_dispatch:completed:success \
  14:wip/r20-x:workflow_dispatch:completed:success 13:wip/r20-x:push:completed:success \
  12:release/r20:push:completed:success
expect_eq "Builds started by hand or on other branches are passed over" "0 12" "$(run) $(out)"

new_gh
kit 19 20
builds 15:release/r20:workflow_dispatch:completed:success 14:wip/r20-x:push:completed:success
expect_eq "with only those, it fails" 1 "$(run)"
expect_eq "printing nothing" "" "$(out)"
expect_log "and says why" "::error::libmpv-r20 is not published and ales-drnz/libmpv-scripts has no Build of release/r20 started by a push"

new_gh
kit 19 20
expect_eq "no Build at all fails" 1 "$(run)"
expect_log "with the error" "::error::.*no Build of release/r20"

new_gh
kit 19 20
builds 13:release/r20:push:completed:failure 12:release/r20:push:completed:cancelled
expect_eq "no successful Build fails" 1 "$(run)"
expect_log "and says so" "::error::ales-drnz/libmpv-scripts has no successful Build of release/r20"

new_gh
kit 21 20
builds 31:release/r21:push:completed:success 20:release/r20:push:completed:success
expect_eq "an unpublished pin past the minimum takes the Build of the pin" "0 31" "$(run) $(out)"

# Tokens.

new_gh
kit 19 20
builds 11:release/r20:push:completed:success
expect_eq "without any token it passes" 0 "$(run GH_TOKEN= RELEASE_TOKEN=)"
expect_eq "printing nothing: the jobs use the pinned release" "" "$(out)"
expect_log "with a warning" "::warning::No LIBMPV_SCRIPTS_TOKEN .*the pinned libmpv release r19"
expect_eq "and no call" 0 "$(calls)"

new_gh
kit 20 20
published 20
expect_eq "a fork pull request on a published pin passes" "0 " "$(run GH_TOKEN=) $(out)"
expect_eq "without a warning" 0 "$(no_warning)"

new_gh
kit 19 20
builds 11:release/r20:push:completed:success
expect_eq "a fork pull request needing a Build prints nothing" "0 " "$(run GH_TOKEN=) $(out)"
expect_log "with the warning" "::warning::No LIBMPV_SCRIPTS_TOKEN"

new_gh
kit 19 20
builds 11:release/r20:push:completed:success
echo scripts-token > "$FAKE_GH/expired"
expect_eq "an expired token fails" 1 "$(run)"
expect_log "and says so" "::error::LIBMPV_SCRIPTS_TOKEN was refused (HTTP 401)"

new_gh
kit 19 20
touch "$FAKE_GH/down"
expect_eq "GitHub out of reach fails when a Build is needed" 1 "$(run)"
expect_log "with a warning for the release" "::warning::Could not look up the libmpv release libmpv-r20"
expect_log "and an error for the Builds" "::error::Could not list the Builds"

new_gh
kit 20 20
touch "$FAKE_GH/down"
expect_eq "but only warns for a pin at the minimum" "0 " "$(run) $(out)"

finish
