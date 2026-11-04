#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The line coverage of lib in an lcov file of flutter test --coverage, for
# the files the metrics read (tool/metrics/README.md): lib/src/generated and
# libmpv_licenses.dart left out. Prints the total, then each directory of
# lib/src. Fails when the total is under the floor of
# tool/metrics/coverage_floor.txt, the first measure (Test (Linux) of
# CI 41862276149): it may rise, by hand, never fall.
#
#   scripts/ci/coverage.sh [coverage/lcov.info]
set -euo pipefail
lcov="${1:-coverage/lcov.info}"
floor_file="$(dirname "$0")/../../tool/metrics/coverage_floor.txt"
if [[ ! -f "$lcov" ]]; then
  echo "coverage: no $lcov" >&2
  # With a floor, no measure is no pass.
  [[ -f "$floor_file" ]] && exit 1
  exit 0
fi
total_file="$(mktemp)"
trap 'rm -f "$total_file"' EXIT

awk -F: -v total_file="$total_file" '
  /^SF:/ {
    file = substr($0, 4)
    sub(/^.*\/lib\//, "lib/", file)
    keep = file ~ /^lib\// && file !~ /^lib\/src\/generated\// &&
      file != "lib/src/internals/libmpv_licenses.dart"
    dir = file
    if (dir ~ /^lib\/src\//) { split(dir, p, "/"); dir = "lib/src/" p[3] } else dir = "lib"
    next
  }
  keep && /^DA:/ {
    split($2, da, ",")
    found[dir]++; total_found++
    if (da[2] > 0) { hit[dir]++; total_hit++ }
  }
  END {
    if (total_found == 0) { print "coverage: no lines of lib"; exit }
    printf "lib: %.1f%% (%d of %d lines)\n", 100 * total_hit / total_found, total_hit, total_found
    printf "%.1f\n", 100 * total_hit / total_found > total_file
    for (d in found) {
      printf "  %s: %.1f%% (%d of %d)\n", d, 100 * hit[d] / found[d], hit[d], found[d] | "sort"
    }
  }
' "$lcov"

total="$(cat "$total_file")"
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
