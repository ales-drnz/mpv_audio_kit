#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The line coverage of lib in an lcov file of flutter test --coverage, for
# the files the metrics read (tool/metrics/README.md): lib/src/generated and
# libmpv_licenses.dart left out. Prints the total, then each directory of
# lib/src. Fails when the total is under the floor of
# tool/metrics/coverage_floor.txt: it may rise, by hand, never fall.
#
# An lcov holds only the files the VM loaded, so every file of lib is
# accounted for: one missing from the lcov must be in
# tool/metrics/coverage_unmeasured.txt, as "web" (runs in the browser
# alone) or "none" (no line to cover), or the script fails. The web files
# count in the total as lines not covered. Their lines are an estimate,
# since nothing compiled them: the lines of code of each (comments,
# directives, annotations and lone brackets left out) times the share of
# such lines the lcov counts in the files it holds. A listed file the lcov
# holds fails too, so the list stays true.
#
#   scripts/ci/coverage.sh [coverage/lcov.info]
#
# Reads from the environment, for the tests:
#   LIB_ROOT    the directory that holds lib/, the repository by default
#   UNMEASURED  the list, tool/metrics/coverage_unmeasured.txt by default
#   FLOOR_FILE  the floor, tool/metrics/coverage_floor.txt by default
set -euo pipefail
lcov="${1:-coverage/lcov.info}"
repo="$(cd "$(dirname "$0")/../.." && pwd)"
root="${LIB_ROOT:-$repo}"
unmeasured="${UNMEASURED:-$repo/tool/metrics/coverage_unmeasured.txt}"
floor_file="${FLOOR_FILE:-$repo/tool/metrics/coverage_floor.txt}"
if [[ ! -f "$lcov" ]]; then
  echo "coverage: no $lcov" >&2
  # With a floor, no measure is no pass.
  [[ -f "$floor_file" ]] && exit 1
  exit 0
fi
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# The files of lib the number is about.
(cd "$root" && find lib -name '*.dart' | LC_ALL=C sort) |
  grep -v -e '^lib/src/generated/' -e '^lib/src/internals/libmpv_licenses\.dart$' \
    > "$work/files" || true
# The list: "kind path" lines.
if [[ -f "$unmeasured" ]]; then
  sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$unmeasured" > "$work/list"
else
  : > "$work/list"
fi

status=0
awk -v root="$root" -v total_file="$work/total" '
  # The lines of code of a file: what is left without blank lines,
  # comments, directives, annotations and lines of closing brackets alone.
  function code_lines(path,    line, n) {
    n = 0
    while ((getline line < path) > 0) {
      sub(/\r$/, "", line)
      sub(/^[ \t]+/, "", line)
      if (line == "" || line ~ /^\/\// || line ~ /^@/) continue
      if (line ~ /^(import|export|part|library)[ ;]/) continue
      if (line ~ /^[\])},;]+$/) continue
      n++
    }
    close(path)
    return n
  }
  function dir_of(file,    p) {
    if (file !~ /^lib\/src\//) return "lib"
    split(file, p, "/")
    return "lib/src/" p[3]
  }
  FILENAME == ARGV[1] { wanted[$0] = 1; order[++files] = $0; next }
  FILENAME == ARGV[2] {
    if ($1 != "web" && $1 != "none") {
      printf "::error title=Coverage::coverage_unmeasured.txt: \"%s\" is neither web nor none\n", $0
      bad = 1
      next
    }
    listed[$2] = $1
    next
  }
  /^SF:/ {
    file = substr($0, 4)
    gsub(/\\/, "/", file)
    sub(/^.*\/lib\//, "lib/", file)
    keep = file in wanted
    if (keep) measured[file] = 1
    dir = dir_of(file)
    next
  }
  keep && /^DA:/ {
    split(substr($0, 4), da, ",")
    found[dir]++; total_found++
    if (da[2] > 0) { hit[dir]++; total_hit++ }
  }
  END {
    if (total_found == 0) { print "coverage: no lines of lib"; exit bad }
    for (i = 1; i <= files; i++) {
      file = order[i]
      if (file in measured) {
        measured_code += code_lines(root "/" file)
        if (file in listed) {
          printf "::error title=Coverage::%s is listed as %s in coverage_unmeasured.txt, and the lcov holds it: take it off the list\n", file, listed[file]
          bad = 1
        }
      } else if (!(file in listed)) {
        printf "::error title=Coverage::%s is in no test the VM runs: the lcov does not hold it, and coverage_unmeasured.txt does not list it\n", file
        bad = 1
      }
    }
    for (file in listed) {
      if (!(file in wanted)) {
        printf "::error title=Coverage::coverage_unmeasured.txt lists %s, which is not a file of lib the coverage reads\n", file
        bad = 1
      }
    }
    share = measured_code ? total_found / measured_code : 1
    for (i = 1; i <= files; i++) {
      file = order[i]
      if (listed[file] != "web" || file in measured) continue
      lines = int(code_lines(root "/" file) * share + 0.5)
      web[++webs] = sprintf("  %s: about %d lines", file, lines)
      web_lines += lines
      d = dir_of(file)
      found[d] += lines; total_found += lines
    }
    printf "lib: %.1f%% (%d of %d lines)\n", 100 * total_hit / total_found, total_hit, total_found
    printf "%.1f\n", 100 * total_hit / total_found > total_file
    for (d in found) {
      printf "  %s: %.1f%% (%d of %d)\n", d, 100 * hit[d] / found[d], hit[d], found[d] | "sort"
    }
    close("sort")
    if (webs) {
      printf "not measured on the VM, counted as not covered (%d lines, an estimate):\n", web_lines
      for (i = 1; i <= webs; i++) print web[i]
      printf "without them: %.1f%% (%d of %d lines)\n", 100 * total_hit / (total_found - web_lines), total_hit, total_found - web_lines
    }
    exit bad
  }
' "$work/files" "$work/list" "$lcov" || status=$?

total="$(cat "$work/total" 2>/dev/null || true)"
if [[ -f "$floor_file" ]]; then
  if [[ -z "$total" ]]; then
    echo "::error title=Coverage::no line of lib in $lcov"
    exit 1
  fi
  floor="$(tr -d '[:space:]' < "$floor_file")"
  if awk -v t="$total" -v f="$floor" 'BEGIN { exit !(t < f) }'; then
    echo "::error title=Coverage::lib is covered at $total%, under the floor of $floor%"
    exit 1
  fi
  echo "coverage: $total%, floor $floor%"
fi
exit "$status"
