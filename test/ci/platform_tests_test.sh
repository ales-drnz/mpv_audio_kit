#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/platform_tests.sh, the test files Test (macOS) runs, on a
# made-up test tree and on the repository's own.
#
#   bash test/ci/platform_tests_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/ci/platform_tests.sh"

tree="$scratch/tree"
mkdir -p "$tree"/test/{models,dsp,x,runtime_extended,media_session,_helpers}
file() { # path, content
  printf '%s\n' "$2" > "$tree/$1"
}
file test/models/pure_test.dart "import 'package:flutter_test/flutter_test.dart';"
file test/models/io_test.dart "import 'dart:io';"
file test/models/ffi_test.dart "import 'package:ffi/ffi.dart';"
file test/dsp/runtime_test.dart "  runtimeSuite(() {});"
file test/dsp/on_test.dart "@TestOn('mac-os')"
file test/x/player_test.dart "  final player = Player();"
file test/x/not_player_test.dart "  final s = AnotherPlayer();"
file test/x/released_test.dart "  libmpvReleaseGroup(19, () {});"
file test/runtime_extended/plain_test.dart "void main() {}"
file test/media_session/plain_test.dart "void main() {}"
file test/_helpers/helper.dart "import 'dart:io';"

listed="$(bash "$script" "$tree" | tr '\n' ' ')"
expect_eq "made-up tree" \
  "test/dsp/on_test.dart test/dsp/runtime_test.dart test/media_session/plain_test.dart test/models/ffi_test.dart test/models/io_test.dart test/runtime_extended/plain_test.dart test/x/player_test.dart test/x/released_test.dart " \
  "$listed"

# The repository: every runtime file in, a Dart-only model test out.
mapfile -t repo < <(bash "$script")
expect_eq "every runtime_extended file is listed" \
  "$(find "$repo_root/test/runtime_extended" -name '*_test.dart' | wc -l | tr -d ' ')" \
  "$(printf '%s\n' "${repo[@]}" | grep -c '^test/runtime_extended/')"
in_repo() { printf '%s\n' "${repo[@]}" | grep -qx "$1" && echo in || echo out; }
expect_eq "a test of libmpv's client is listed" in "$(in_repo test/internal/mpv_client_test.dart)"
expect_eq "a Dart-only model test is not" out "$(in_repo test/models/media_test.dart)"

finish
