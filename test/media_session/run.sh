#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license.
#
# Orchestrates every native media-session test suite available on the
# current host. Each per-platform subdirectory ships its own
# `run.sh` that compiles + runs the suite in the platform's native
# language; this script delegates to whichever ones the host can run.
#
# Platforms:
#   darwin   macOS and iOS (Swift), on a macOS host.
#   linux    no native suite: MPRIS runs through test_app
#            (integration_test/linux_mpris_test.dart).
#   windows  no native suite: SMTC runs through test_app
#            (integration_test/windows_smtc_test.dart).
#   android  the plugin's JVM tests (android/src/test), through Gradle.
#
# Usage (from anywhere in the repo):
#   bash test/media_session/run.sh
#
# Exit codes:
#   0 — all available suites passed.
#   1 — at least one suite failed.
#   2 — environment problem (missing dependency etc.).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
OS=$(uname -s)

failures=0
ran=0

run_suite() {
  local name="$1"
  local script="$2"
  if [ -x "$script" ]; then
    echo "▶ $name"
    if bash "$script"; then
      echo "✓ $name passed"
    else
      echo "✗ $name FAILED"
      failures=$((failures + 1))
    fi
    ran=$((ran + 1))
    echo
  fi
}

case "$OS" in
  Darwin)
    run_suite "darwin (Swift; macOS + iOS shared source)" "$HERE/darwin/run.sh"
    ;;
  Linux)
    if [ -x "$HERE/linux/run.sh" ]; then
      run_suite "linux" "$HERE/linux/run.sh"
    else
      echo "(no native Linux suite: MPRIS runs in test_app, integration_test/linux_mpris_test.dart)"
    fi
    ;;
  MINGW*|CYGWIN*|MSYS*)
    if [ -x "$HERE/windows/run.sh" ]; then
      run_suite "windows" "$HERE/windows/run.sh"
    else
      echo "(no native Windows suite: SMTC runs in test_app, integration_test/windows_smtc_test.dart)"
    fi
    ;;
  *)
    echo "Unsupported host OS: $OS" >&2
    exit 2
    ;;
esac

if [ "$ran" -eq 0 ]; then
  echo "No applicable native media-session test suite for host OS '$OS'."
  exit 0
fi

if [ "$failures" -gt 0 ]; then
  echo "$failures suite(s) failed."
  exit 1
fi
echo "All $ran suite(s) passed."
