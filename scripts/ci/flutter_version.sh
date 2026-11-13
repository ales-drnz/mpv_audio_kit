#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Prints the Flutter version a CI job installs (.github/actions/flutter):
#
#   stable   the one of .github/flutter-version: the stable the format and
#            the drift of the generated code are checked on, raised by a
#            commit and not by a Flutter release
#   floor    the lower bound of environment.flutter in pubspec.yaml, the
#            oldest Flutter the package declares
#   latest   "any", the stable of the day
#
#   scripts/ci/flutter_version.sh stable|floor|latest [repository root]
set -euo pipefail

want="${1:-stable}"
cd "${2:-$(dirname "$0")/../..}"

case "$want" in
  stable)
    version="$(tr -d '[:space:]' < .github/flutter-version)"
    ;;
  floor)
    # A Windows checkout may end the lines with CRLF.
    version="$(tr -d '\r' < pubspec.yaml |
      sed -n "s/^  flutter: *['\"]>=\([0-9][0-9.]*\)['\"] *$/\1/p" | head -n 1)"
    ;;
  latest)
    echo any
    exit 0
    ;;
  *)
    echo "flutter_version: '$want' is not stable, floor or latest" >&2
    exit 2
    ;;
esac
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "flutter_version: no $want version (read '$version')" >&2
  exit 1
fi
echo "$version"
