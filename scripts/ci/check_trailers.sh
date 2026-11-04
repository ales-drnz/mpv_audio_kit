#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Warns about each fix commit of a range whose message lacks a real red and
# green: a "Red:" paragraph that names a test of the tree and how it failed,
# and a "Green:" (or "Green 3 times:") paragraph. A placeholder (RED, GREEN,
# TODO, pending) counts as none. Only warns: the exit status is 0.
#
#   scripts/ci/check_trailers.sh [range]     (origin/main..HEAD by default)
#
# A fix commit is one whose subject starts with fix: or fix(scope):.
set -euo pipefail
range="${1:-origin/main..HEAD}"
if ! git rev-list "$range" > /dev/null 2>&1; then
  echo "::error title=Red and green::the range $range does not resolve"
  exit 1
fi

# The paragraph of message $1 that starts with a line matching $2.
paragraph() {
  awk -v re="$2" '
    found && /^[[:space:]]*$/ { exit }
    found && /^(Red|Green)( [0-9]+ times)?:/ { exit }
    found { print; next }
    $0 ~ re { found = 1; print }
  ' <<<"$1"
}

warn() { # sha, subject, message
  echo "::warning title=Red and green::${1:0:7} \"$2\": $3"
  warnings=$((warnings + 1))
}

warnings=0
checked=0
while read -r sha; do
  subject="$(git log -1 --format=%s "$sha")"
  [[ "$subject" =~ ^fix(\([^\)]*\))?!?: ]] || continue
  checked=$((checked + 1))
  body="$(git log -1 --format=%b "$sha")"
  red="$(paragraph "$body" '^Red:')"
  green="$(paragraph "$body" '^Green( [0-9]+ times)?:')"
  if [[ -z "$red" ]]; then
    warn "$sha" "$subject" "no Red: paragraph"
  else
    if grep -Eq '\b(RED|GREEN|TODO)\b' <<<"$red" || grep -Eiq '\bpending\b' <<<"$red"; then
      warn "$sha" "$subject" "the Red: paragraph is a placeholder"
    fi
    # The test it names: a *_test or test_* file, a *Test class of the JVM,
    # or a path of one.
    tree="$(git ls-tree -r --name-only "$sha")"
    found=""
    while read -r name; do
      name="${name##*/}"
      name="${name%.*}"
      if grep -Eq "(^|/)$name\.[a-z]+$" <<<"$tree"; then
        found="$name"
        break
      fi
    done < <(grep -Eo '[A-Za-z0-9_./-]*_test(\.[a-z]+)?|\btest_[A-Za-z0-9_]+(\.py)?|\b[A-Z][A-Za-z0-9]*Test\b' <<<"$red" || true)
    # Or a test by its description, in quotes, found in a file of the tree.
    if [[ -z "$found" ]]; then
      while read -r quoted; do
        quoted="${quoted#\"}"
        quoted="${quoted%\"}"
        [[ ${#quoted} -ge 8 ]] || continue
        if git grep -qF -- "$quoted" "$sha" 2>/dev/null; then
          found="$quoted"
          break
        fi
      done < <(tr '\n' ' ' <<<"$red" | grep -Eo '"[^"]+"' || true)
    fi
    if [[ -z "$found" ]]; then
      warn "$sha" "$subject" "the Red: paragraph names no test of the tree"
    fi
    # How it failed: a quoted test or line, a count of failures, or the
    # words of a failure.
    if ! grep -Eq '"[^"]+"|(^|[[:space:]])-[0-9]+\b|[Ee]xpected|[Aa]ctual|[Ff]ail|[Ee]rror|[Tt]hrew|[Tt]imed out|got ' <<<"$red"; then
      warn "$sha" "$subject" "the Red: paragraph says not how the test failed"
    fi
  fi
  if [[ -z "$green" ]]; then
    warn "$sha" "$subject" "no Green: paragraph"
  elif grep -Eq '\b(RED|GREEN|TODO)\b' <<<"$green" || grep -Eiq '\bpending\b' <<<"$green"; then
    warn "$sha" "$subject" "the Green: paragraph is a placeholder"
  fi
done < <(git rev-list --no-merges "$range")

echo "Red and green: $checked fix commits, $warnings warnings"
