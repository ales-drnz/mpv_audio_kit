#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license.
#
# Builds and runs the multi engine table (engine_ownership_test.cc) against
# native_common/engine_ownership.h, the header the Windows and Linux plugins
# share. Needs a C++17 compiler only: $CXX, or g++.
#
# Usage: bash test/media_session/cpp/run.sh
set -euo pipefail
root="$(cd "$(dirname "$0")/../../.." && pwd)"
out="$(mktemp -d)"
trap 'rm -rf "$out"' EXIT
"${CXX:-g++}" -std=c++17 -Wall -Wextra -Werror -I"$root/native_common" \
  "$root/test/media_session/cpp/engine_ownership_test.cc" -o "$out/engine_ownership_test"
"$out/engine_ownership_test"
