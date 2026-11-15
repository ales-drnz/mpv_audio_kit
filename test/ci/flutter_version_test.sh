#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/flutter_version.sh, the Flutter each CI job installs, on
# a made-up tree and on the repository, and that no workflow installs
# Flutter another way.
#
#   bash test/ci/flutter_version_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/flutter_version.sh"

tree="$scratch/tree"
mkdir -p "$tree/.github"
echo "3.99.1" > "$tree/.github/flutter-version"
printf 'environment:\n  sdk: ^3.10.0\n  flutter: %s\r\n' "'>=3.40.2'" > "$tree/pubspec.yaml"
expect_eq "stable is the pinned file" 3.99.1 "$(bash "$script" stable "$tree")"
expect_eq "floor is the bound of pubspec, CRLF or not" 3.40.2 "$(bash "$script" floor "$tree")"
expect_eq "latest is any" any "$(bash "$script" latest "$tree")"

echo "3.x" > "$tree/.github/flutter-version"
code=0; bash "$script" stable "$tree" > /dev/null 2>&1 || code=$?
expect_eq "a pin that is not a full version fails" 1 "$code"
printf 'environment:\n  sdk: ^3.10.0\n' > "$tree/pubspec.yaml"
code=0; bash "$script" floor "$tree" > /dev/null 2>&1 || code=$?
expect_eq "a pubspec without a Flutter bound fails" 1 "$code"
code=0; bash "$script" beta "$tree" > /dev/null 2>&1 || code=$?
expect_eq "another name fails" 2 "$code"

# The repository: a full version each, the stable not under the floor.
stable="$(bash "$script" stable)"
floor="$(bash "$script" floor)"
expect_eq "the repository's stable is not under its floor" "$floor" \
  "$(printf '%s\n' "$stable" "$floor" | sort -V | head -n 1)"
# Flutter is installed by .github/actions/flutter alone, which asks for
# the version the script printed.
expect_eq "no workflow installs Flutter by itself" "" \
  "$(grep -rlE 'subosito/flutter-action|flutter-version:' "$repo_root/.github/workflows" || true)"

finish
