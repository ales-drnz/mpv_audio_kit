# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Sourced by the CI script tests: puts the fake gh of test/ci/bin first on
# PATH, gives each case a fresh fixture directory, and counts failures.

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$here/../.." && pwd)"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
export PATH="$here/bin:$PATH"
failures=0

# A fresh fixture directory for the fake gh (see test/ci/bin/gh).
new_gh() {
  FAKE_GH="$(mktemp -d -p "$scratch")"
  export FAKE_GH
  mkdir -p "$FAKE_GH/runs" "$FAKE_GH/run" "$FAKE_GH/release"
  : > "$FAKE_GH/calls"
}

# The ci.yml runs of commit $1, each given as id:event:conclusion
# (conclusion null for a run still going).
runs_of() {
  local sha="$1" spec id event conclusion runs=()
  shift
  for spec in "$@"; do
    IFS=: read -r id event conclusion <<<"$spec"
    [[ "$conclusion" == null ]] || conclusion="\"$conclusion\""
    runs+=("{\"id\":$id,\"event\":\"$event\",\"conclusion\":$conclusion}")
  done
  local IFS=,
  echo "{\"total_count\":${#runs[@]},\"workflow_runs\":[${runs[*]}]}" \
    > "$FAKE_GH/runs/$sha.json"
}

expect_eq() { # name, expected, actual
  if [[ "$2" == "$3" ]]; then
    echo "ok: $1"
  else
    echo "FAIL: $1: expected '$2', got '$3'" >&2
    failures=$((failures + 1))
  fi
}

# Whether the last script run printed a line matching $2.
expect_log() { # name, pattern
  if grep -q -- "$2" "$FAKE_GH/log"; then
    echo "ok: $1"
  else
    echo "FAIL: $1: no line matches '$2' in:" >&2
    sed 's/^/  /' "$FAKE_GH/log" >&2
    failures=$((failures + 1))
  fi
}

finish() {
  if (( failures )); then
    echo "$failures check(s) failed" >&2
    exit 1
  fi
  echo "all checks passed"
}
