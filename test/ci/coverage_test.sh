#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/coverage.sh on a made-up lib and lcov: the files the
# lcov does not hold count through the list of the ones not measured, and a
# file in neither fails, and on the repository's own list.
#
#   bash test/ci/coverage_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/coverage.sh"

tree="$scratch/tree"
mkdir -p "$tree"/lib/src/{a,web,generated,internals}
# Four lines of code each, under a comment and an import.
body() {
  printf '%s\n' '// A comment.' "import 'dart:io';" '' 'int f() {' \
    '  final a = 1;' '  final b = 2;' '  return a + b;' '}'
}
body > "$tree/lib/src/a/measured.dart"
body > "$tree/lib/src/web/browser.dart"
body > "$tree/lib/src/generated/made.dart"
body > "$tree/lib/src/internals/libmpv_licenses.dart"
printf '%s\n' "export 'src/a/measured.dart';" > "$tree/lib/kit.dart"

# The lcov of the measured file: two lines the VM counts, one of them hit.
# The generated file is there too, and is left out.
lcov="$scratch/lcov.info"
cat > "$lcov" <<LCOV
SF:/checkout/lib/src/a/measured.dart
DA:4,3
DA:7,0
end_of_record
SF:/checkout/lib/src/generated/made.dart
DA:4,0
end_of_record
LCOV

list="$scratch/list"
floor="$scratch/floor"
run() { # prints the output, sets code
  code=0
  out="$(LIB_ROOT="$tree" UNMEASURED="$list" FLOOR_FILE="$floor" bash "$script" "$lcov" 2>&1)" || code=$?
}
has() { grep -qF -- "$1" <<<"$out" && echo yes || echo no; }

echo 20 > "$floor"
printf '%s\n' '# what the lcov leaves out' 'web lib/src/web/browser.dart' \
  'none lib/kit.dart # exports alone' > "$list"
run
expect_eq "a complete list passes" 0 "$code"
# The lcov counts 2 of the 4 lines of code of the measured file, so the 4
# of the web file count as 2: 1 hit of 4.
expect_eq "the web file counts as lines not covered" yes "$(has 'lib: 25.0% (1 of 4 lines)')"
expect_eq "the web file is named" yes "$(has 'lib/src/web/browser.dart: about 2 lines')"
expect_eq "the measure without it is printed" yes "$(has 'without them: 50.0% (1 of 2 lines)')"
expect_eq "its directory is at 0%" yes "$(has 'lib/src/web: 0.0% (0 of 2)')"

echo 30 > "$floor"
run
expect_eq "under the floor fails" 1 "$code"
expect_eq "under the floor says so" yes "$(has 'under the floor of 30%')"
echo 20 > "$floor"

printf '%s\n' 'none lib/kit.dart' > "$list"
run
expect_eq "a file in neither the lcov nor the list fails" 1 "$code"
expect_eq "the file is named" yes "$(has 'lib/src/web/browser.dart is in no test the VM runs')"

printf '%s\n' 'web lib/src/web/browser.dart' 'none lib/kit.dart' \
  'none lib/src/a/measured.dart' > "$list"
run
expect_eq "a listed file the lcov holds fails" 1 "$code"
expect_eq "it says to take it off" yes "$(has 'lib/src/a/measured.dart is listed as none')"

printf '%s\n' 'web lib/src/web/browser.dart' 'none lib/kit.dart' \
  'none lib/src/gone.dart' > "$list"
run
expect_eq "a listed file that is not in lib fails" 1 "$code"

printf '%s\n' 'web lib/src/web/browser.dart' 'skip lib/kit.dart' > "$list"
run
expect_eq "a kind that is neither web nor none fails" 1 "$code"

rm "$lcov"
run
expect_eq "no lcov with a floor fails" 1 "$code"

# The repository's list names files of lib the coverage reads, once each.
real="$repo_root/tool/metrics/coverage_unmeasured.txt"
missing=0
while read -r kind path; do
  [[ "$kind" == web || "$kind" == none ]] || missing=$((missing + 1))
  [[ -f "$repo_root/$path" ]] || missing=$((missing + 1))
done < <(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$real")
expect_eq "every line of the repository's list is a kind and a file" 0 "$missing"
expect_eq "no file is listed twice" "" \
  "$(sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$real" | awk '{ print $2 }' | sort | uniq -d)"
# Every *_web.dart and every file under a web directory is either listed
# as web or loaded by the VM tests: none is listed as "none".
expect_eq "no web file is listed as none" "" \
  "$(sed -e 's/#.*//' "$real" | awk '$1 == "none" && $2 ~ /(_web\.dart$|\/web\/)/ { print $2 }')"

finish
