#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/check_trailers.sh on a made-up repository.
#
#   bash test/ci/check_trailers_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/check_trailers.sh"

repo="$scratch/repo"
mkdir -p "$repo/test/player"
cd "$repo"
git init -q
git config user.email ci@example.com
git config user.name CI
printf "test('a pause stays a pause', () {});\n" > test/player/pause_test.dart
git add -A
git commit -qm "base"
base="$(git rev-parse HEAD)"

commit() { # message
  git commit -q --allow-empty -m "$1"
}

commit "$(printf 'fix: a pause stays a pause\n\nRed: pause_test "a pause stays a pause" -1: Expected paused.\nGreen 3 times: pause_test +1.')"
commit "$(printf 'fix(web): by name\n\nRed: CI, "a pause stays a pause" timed out.\nGreen: CI 123.')"
commit "$(printf 'feat: not a fix\n\nNo trailers.')"
commit "$(printf 'fix: no paragraphs\n\nJust words.')"
commit "$(printf 'fix: placeholders\n\nRed: TODO\nGreen: pending')"
commit "$(printf 'fix: unknown test\n\nRed: other_test -1, Expected 1.\nGreen: other_test +1.')"
commit "$(printf 'fix: no failure\n\nRed: pause_test ran.\nGreen: pause_test +1.')"

out="$(bash "$script" "$base..HEAD")"
expect_eq "exit status 0 and a summary" \
  "Red and green: 6 fix commits, 8 warnings" "$(tail -1 <<<"$out")"
warned() { grep -F "\"$1\"" <<<"$out" | sed 's/.*": //' | tr '\n' '|'; }
expect_eq "a full red and green" "" "$(warned 'fix: a pause stays a pause')"
expect_eq "a test by its description" "" "$(warned 'fix(web): by name')"
expect_eq "not a fix" "" "$(warned 'feat: not a fix')"
expect_eq "no paragraphs" "no Red: paragraph|no Green: paragraph|" \
  "$(warned 'fix: no paragraphs')"
expect_eq "placeholders" \
  "the Red: paragraph is a placeholder|the Red: paragraph names no test of the tree|the Red: paragraph says not how the test failed|the Green: paragraph is a placeholder|" \
  "$(warned 'fix: placeholders')"
expect_eq "unknown test" "the Red: paragraph names no test of the tree|" \
  "$(warned 'fix: unknown test')"
expect_eq "no failure" "the Red: paragraph says not how the test failed|" \
  "$(warned 'fix: no failure')"

exit "$failures"
