#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/api_diff.sh on reports written as dart_apitool 0.23.2
# writes them, without running it (API_DIFF_REPORT).
#
#   bash test/ci/api_diff_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/api_diff.sh"

pkg="$scratch/pkg"
mkdir -p "$pkg"
printf 'name: mpv_audio_kit\nversion: 9.9.9\n' > "$pkg/pubspec.yaml"

report() { # file, breaking lines, non-breaking lines
  {
    printf '# API Changes Report\n\n## Report\n\n'
    if [[ -n "$2" ]]; then
      printf '### \xf0\x9f\x9a\xa8 BREAKING CHANGES\n\n * Changelist:\n     * Class Player\n%s\n\n' "$2"
    fi
    if [[ -n "$3" ]]; then
      printf '### \xf0\x9f\x86\x95 Non-Breaking Changes\n\n * Changelist:\n     * Class Player\n%s\n' "$3"
    fi
  } > "$1"
}
run() { # report, changelog section; prints the exit code and the verdict
  printf '## [9.9.9]\n\n%s\n\n## [9.9.8]\n' "$2" > "$pkg/CHANGELOG.md"
  local out code=0
  out="$(cd "$pkg" && API_DIFF_REPORT="$1" bash "$script" 2>&1)" || code=$?
  printf '%s|%s' "$code" "$(grep -oE 'no breaking change|breaking changes, stated|has no \*\*Breaking\*\* part' <<<"$out" | head -1)"
}

private='         * **Super Type "_FfiModule" removed** [(CI05)](https://example.invalid)'
added='         * **Super Type "_RawModule" added** [(CI04)](https://example.invalid) (minor)'
member='         * **Method "setVolume" removed** [(CE01)](https://example.invalid)'

report "$scratch/private.md" "$private" "$added"
expect_eq "private super types only" "0|no breaking change" \
  "$(run "$scratch/private.md" '### All platforms')"

report "$scratch/member.md" "$private
$member" "$added"
expect_eq "a public member removed" "1|has no **Breaking** part" \
  "$(run "$scratch/member.md" '### All platforms')"
expect_eq "a public member removed and stated" "0|breaking changes, stated" \
  "$(run "$scratch/member.md" '**Breaking**')"

report "$scratch/none.md" "" "$added"
expect_eq "non-breaking changes only" "0|no breaking change" \
  "$(run "$scratch/none.md" '### All platforms')"

exit "$failures"
