#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/verify_red.sh on a made-up repository, with a flutter on
# PATH whose every test passes: what the script must not take for a red.
#
#   bash test/ci/verify_red_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/verify_red.sh"

fake="$scratch/bin"
mkdir -p "$fake"
printf '#!/usr/bin/env bash\necho "00:00 +1: All tests passed!"\n' > "$fake/flutter"
chmod +x "$fake/flutter"

repo="$scratch/repo"
mkdir -p "$repo/test/player" "$repo/lib" "$repo/scripts/ci"
cd "$repo"
git init -q
git config user.email ci@example.com
git config user.name CI
printf "test('a pause stays a pause', () {});\n" > test/player/pause_test.dart
printf 'name: fake\n' > pubspec.yaml
printf '// lib\n' > lib/a.dart
printf '# script\n' > scripts/ci/a.sh
git add -A
git commit -qm "base"
base="$(git rev-parse HEAD)"

# A fix of a CI script whose Red quotes a unit test: lib is the same on the
# parent, so the test cannot be red there.
printf '# script, fixed\n' > scripts/ci/a.sh
git commit -qam "$(printf 'fix(ci): the script\n\nRed: CI 1, "pause_test.dart passes on the parent".\nGreen: CI 2.')"

status=0
out="$(PATH="$fake:$PATH" bash "$script" "$base..HEAD" 2>&1)" || status=$?
expect_eq "a fix outside lib: exit 0" 0 "$status"
expect_eq "a fix outside lib: skipped with a notice" 1 \
  "$(grep -c 'changes nothing the unit tests run, skipped' <<<"$out" || true)"
expect_eq "a fix outside lib: the summary" \
  "Red by machine: 0 fix commits with unit tests, 0 never red" "$(tail -1 <<<"$out")"

# A fix of lib with the same Red: checked, and a test that passes is caught.
printf '// lib, fixed\n' > lib/a.dart
git commit -qam "$(printf 'fix: a pause\n\nRed: pause_test -1.\nGreen: pause_test +1.')"
status=0
out="$(PATH="$fake:$PATH" bash "$script" "HEAD~1..HEAD" 2>&1)" || status=$?
expect_eq "a fix of lib whose test passes on the parent: exit 1" 1 "$status"
expect_eq "a fix of lib: never red" 1 "$(grep -c 'so it was never red' <<<"$out" || true)"

finish
