#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The line coverage of lib in an lcov file of flutter test --coverage, for
# the files the metrics read (tool/metrics/README.md): lib/src/generated and
# libmpv_licenses.dart left out. Prints the total, then each directory of
# lib/src. Measures only: the exit status is 0 for any number.
#
#   scripts/ci/coverage.sh [coverage/lcov.info]
set -euo pipefail
lcov="${1:-coverage/lcov.info}"
[[ -f "$lcov" ]] || { echo "coverage: no $lcov" >&2; exit 0; }

awk -F: '
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
    for (d in found) {
      printf "  %s: %.1f%% (%d of %d)\n", d, 100 * hit[d] / found[d], hit[d], found[d] | "sort"
    }
  }
' "$lcov"
