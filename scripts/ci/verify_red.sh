#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Checks the red of each fix commit of a range by machine: the unit tests
# its "Red:" paragraph names, run on the parent commit with the test files
# of the commit, must fail. A test that passes there was never red, and
# fails this script. Only unit tests run (the folders in $unit_dirs): a
# runtime test needs libmpv, and its red stays the one the commit reports.
# A fix commit that names no unit test is skipped with a notice. Red means
# a test ran and failed: a test that only fails to compile on the parent
# (it calls what the fix adds) warns, and a run that never got to the tests
# (a timeout, pub or the build hook) fails as a test that passes does.
#
#   scripts/ci/verify_red.sh [range]     (origin/main..HEAD by default)
#
# Needs flutter and a C compiler: the tests run against a stub libmpv
# (the build hook's libmpv user define), which no unit test calls.
set -euo pipefail
range="${1:-origin/main..HEAD}"
unit_dirs='^test/(internal|models|backend|player|packaging|event_isolate|reactive|dsp|pcm|utils)/'
root="$(git rev-parse --show-toplevel)"
if ! git rev-list "$range" > /dev/null 2>&1; then
  echo "::error title=Red by machine::the range $range does not resolve"
  exit 1
fi
work="$(mktemp -d)"
trap 'git -C "$root" worktree remove --force "$work/tree" >/dev/null 2>&1 || true; rm -rf "$work"' EXIT

# The paragraph of message $1 that starts with a line matching $2.
paragraph() {
  awk -v re="$2" '
    found && /^[[:space:]]*$/ { exit }
    found && /^(Red|Green)( [0-9]+ times)?:/ { exit }
    found { print; next }
    $0 ~ re { found = 1; print }
  ' <<<"$1"
}

printf 'int mak_stub;\n' > "$work/stub.c"
cc -shared -fPIC -o "$work/libmpv_stub.so" "$work/stub.c"

failures=0
checked=0
while read -r sha; do
  subject="$(git log -1 --format=%s "$sha")"
  [[ "$subject" =~ ^fix(\([^\)]*\))?!?: ]] || continue
  red="$(paragraph "$(git log -1 --format=%b "$sha")" '^Red:')"
  [[ -n "$red" ]] || continue
  tree="$(git ls-tree -r --name-only "$sha")"
  tests=()
  while read -r name; do
    name="${name##*/}"
    name="${name%.dart}"
    while read -r path; do
      [[ -n "$path" && "$path" =~ $unit_dirs ]] && tests+=("$path")
    done < <(grep -E "(^|/)$name\.dart$" <<<"$tree" || true)
  done < <(grep -Eo '[A-Za-z0-9_./-]*_test(\.dart)?' <<<"$red" | sort -u || true)
  if [[ ${#tests[@]} -eq 0 ]]; then
    echo "::notice title=Red by machine::${sha:0:7} \"$subject\": names no unit test, skipped"
    continue
  fi
  mapfile -t tests < <(printf '%s\n' "${tests[@]}" | sort -u)
  checked=$((checked + 1))

  # The parent, with the test files of the commit.
  git -C "$root" worktree remove --force "$work/tree" >/dev/null 2>&1 || true
  git -C "$root" worktree add --detach "$work/tree" "$sha^" >/dev/null 2>&1
  mapfile -t changed < <(git diff --name-only --diff-filter=AM "$sha^" "$sha" -- test)
  if [[ ${#changed[@]} -gt 0 ]]; then
    git -C "$work/tree" checkout "$sha" -- "${changed[@]}"
  fi
  printf '\nhooks:\n  user_defines:\n    mpv_audio_kit:\n      libmpv: %s\n' \
    "$work/libmpv_stub.so" >> "$work/tree/pubspec.yaml"

  for t in "${tests[@]}"; do
    if [[ ! -f "$work/tree/$t" ]]; then
      echo "::notice title=Red by machine::${sha:0:7}: $t is not in the commit's test files, skipped"
      continue
    fi
    status=0
    (cd "$work/tree" && timeout 900 flutter test "$t" > "$work/log" 2>&1) || status=$?
    # A test that ran and failed is marked [E] on its own line; a file
    # that does not compile is marked on its "loading" line.
    ran="$(grep -E '\[E\]' "$work/log" | grep -v ': loading ' | head -1 || true)"
    loading="$(grep -E ': loading .*\[E\]' "$work/log" | head -1 || true)"
    if [[ $status -eq 0 ]]; then
      echo "::error title=Red by machine::${sha:0:7} \"$subject\": $t passes on the parent with the commit's tests, so it was never red"
      tail -5 "$work/log"
      failures=$((failures + 1))
    elif [[ -n "$ran" ]]; then
      echo "Red by machine: ${sha:0:7} $t fails on the parent: $ran"
    elif [[ -n "$loading" ]]; then
      echo "::warning title=Red by machine::${sha:0:7} \"$subject\": $t does not compile on the parent, a red that runs no test"
    else
      echo "::error title=Red by machine::${sha:0:7} \"$subject\": $t did not run on the parent (exit $status), so its red is not checked"
      tail -5 "$work/log"
      failures=$((failures + 1))
    fi
  done
done < <(git rev-list --no-merges --reverse "$range")

echo "Red by machine: $checked fix commits with unit tests, $failures never red"
exit $(( failures > 0 ))
