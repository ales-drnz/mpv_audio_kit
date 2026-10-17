#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/changes_gate.sh on a scratch git history, with the fake
# gh of test/ci/bin serving the CI runs of each commit.
#
#   bash test/ci/changes_gate_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
gate="$repo_root/scripts/ci/changes_gate.sh"

export GIT_AUTHOR_NAME=ci GIT_AUTHOR_EMAIL=ci@example.com
export GIT_COMMITTER_NAME=ci GIT_COMMITTER_EMAIL=ci@example.com
git init -q "$scratch/repo"
cd "$scratch/repo"

commit() { # message, then the files it touches
  local message="$1" file
  shift
  for file in "$@"; do
    mkdir -p "$(dirname "$file")"
    echo "$message" >> "$file"
  done
  git add -A
  git commit -q -m "$message"
  git rev-parse HEAD
}

# c0 the start, c1 code, c2 docs only, c3 code and docs.
c0="$(commit start lib/a.dart README.md)"
c1="$(commit code lib/a.dart)"
c2="$(commit docs CHANGELOG.md doc/guide.md imgs/a.png tool/diagrams/a.py)"
c3="$(commit mixed lib/a.dart README.md)"
zero=0000000000000000000000000000000000000000

# Runs the gate as the changes job does (this run is 500) and prints its
# code output, or how it failed.
gate() { # event, base, sha
  local status=0
  : > "$FAKE_GH/output"
  EVENT="$1" BASE="$2" SHA="$3" RUN_ID=500 REPO=owner/kit \
    GITHUB_OUTPUT="$FAKE_GH/output" "$gate" > "$FAKE_GH/log" 2>&1 || status=$?
  if (( status )); then
    echo "exit $status"
  else
    sed -n 's/^code=//p' "$FAKE_GH/output"
  fi
}

new_gh
expect_eq "a code push runs" true "$(gate push "$c0" "$c1")"

new_gh
expect_eq "a code and docs push runs" true "$(gate push "$c2" "$c3")"

new_gh
runs_of "$c1" 400:push:success
expect_eq "a docs-only push after a green run is skipped" false "$(gate push "$c1" "$c2")"
expect_log "and says so" "Only docs changed"

new_gh
runs_of "$c0" 400:push:cancelled
expect_eq "a code push after a cancelled run runs" true "$(gate push "$c0" "$c1")"

new_gh
expect_eq "a push that opens a branch runs" true "$(gate push "$zero" "$c2")"

new_gh
expect_eq "a push after a force push runs" true \
  "$(gate push 1234567890123456789012345678901234567890 "$c2")"

new_gh
expect_eq "a manual run runs" true "$(gate workflow_dispatch "" "$c2")"
expect_eq "without looking for other runs" "" "$(cat "$FAKE_GH/calls")"

new_gh
runs_of "$c3" 600:push:success 400:pull_request:success
expect_eq "a pull request with code runs" true "$(gate pull_request "$c1" "$c3")"
expect_eq "without looking for other runs" "" "$(cat "$FAKE_GH/calls")"

new_gh
runs_of "$c1" 400:push:success
expect_eq "a pull request with docs only is skipped" false \
  "$(gate pull_request "$c1" "$c2")"

new_gh
runs_of "$c3" 400:push:success
expect_eq "a commit green on another branch is skipped" false "$(gate push "$c2" "$c3")"
expect_log "and says so" "already"

new_gh
runs_of "$c3" 400:push:cancelled
expect_eq "a commit cancelled on another branch runs" true "$(gate push "$c2" "$c3")"

new_gh
runs_of "$c3" 400:push:failure
expect_eq "a commit failed on another branch runs" true "$(gate push "$c2" "$c3")"

finish
