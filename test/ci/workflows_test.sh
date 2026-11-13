#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Reads the workflows and the actions of .github: every job has a
# timeout-minutes, every action from outside is pinned by the 40 characters
# of its commit with the version in a comment, and each one at a single
# commit across the files.
#
#   bash test/ci/workflows_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
cd "$repo_root"

# The jobs of a workflow without a timeout-minutes of their own.
no_timeout() {
  awk '
    function flush() { if (job != "" && !timed) print FILENAME ": " job }
    FNR == 1 { flush(); job = ""; in_jobs = 0 }
    /^jobs:/ { in_jobs = 1; next }
    in_jobs && /^[^ #]/ { flush(); job = ""; in_jobs = 0 }
    in_jobs && /^  [A-Za-z0-9_-]+:[ \t]*$/ {
      flush(); job = $1; sub(/:$/, "", job); timed = 0; next
    }
    in_jobs && /^    timeout-minutes:/ { timed = 1 }
    END { flush() }
  ' "$@"
}

# The made-up workflow first: the check sees a job without a timeout.
cat > "$scratch/w.yml" <<'YAML'
jobs:
  with:
    timeout-minutes: 5
    steps:
      - timeout-minutes: 1
  without:
    steps:
      - timeout-minutes: 1
YAML
expect_eq "a job without a timeout is found" "$scratch/w.yml: without" \
  "$(no_timeout "$scratch/w.yml")"

expect_eq "every job has a timeout-minutes" "" \
  "$(no_timeout .github/workflows/*.yml)"

uses="$(grep -rnE '^\s*(- )?uses:' .github/workflows .github/actions)"
expect_eq "every action from outside is pinned by its commit, with the version" "" \
  "$(grep -vE 'uses: \./' <<<"$uses" |
    grep -vE 'uses: [A-Za-z0-9_.-]+/[A-Za-z0-9_./-]+@[0-9a-f]{40} # v[0-9]+\.[0-9]+\.[0-9]+$' || true)"
# actions/cache/restore and actions/cache are one repository.
expect_eq "each action is at one commit" "" \
  "$(grep -oE 'uses: [A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+[^@]*@[0-9a-f]{40}' <<<"$uses" |
    sed -E 's#uses: ([^/]+/[^/@]+)[^@]*@#\1 #' | sort -u | awk '{ print $1 }' | uniq -d)"

finish
