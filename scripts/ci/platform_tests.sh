#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Prints the test files whose result can depend on the host, one per line:
# the ones under test/runtime, test/runtime_extended, test/media_session and
# test/packaging, and elsewhere the ones that import dart:io, dart:ffi or
# package:ffi, carry @TestOn, or reach libmpv through the test helpers. The
# rest is Dart alone, and gives on macOS what it gives on Linux, which runs
# the whole suite. Test (macOS) in ci.yml runs only these.
#
#   scripts/ci/platform_tests.sh [repository root]
set -euo pipefail

cd "${1:-$(dirname "$0")/../..}"

# What reaches libmpv or the host from a test file.
marks="^import 'dart:(io|ffi)'|^import 'package:ffi/|^@TestOn"
marks+="|runtimeSuite|libmpvReleaseGroup|needsLibmpvRelease|skipMissing"
marks+="|libmpvSkipReason|resolveLibmpv|slowCoreShimSuite|buildPlayer"
marks+="|MpvAudioKit\.ensureInitialized|(^|[^A-Za-z0-9_])Player\("

find test -name '*_test.dart' | LC_ALL=C sort | while read -r f; do
  case "$f" in
    test/runtime/* | test/runtime_extended/* | test/media_session/* | test/packaging/*)
      echo "$f"
      ;;
    *)
      if grep -qE "$marks" "$f"; then echo "$f"; fi
      ;;
  esac
done
