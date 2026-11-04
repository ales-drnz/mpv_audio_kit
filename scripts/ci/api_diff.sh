#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Compares the API of the package with the latest version on pub.dev
# (dart_apitool), and writes the report to the step summary. Fails when the
# API breaks and the CHANGELOG entry of this version has no **Breaking**
# part. A run of dart_apitool that gives no report only warns.
#
#   scripts/ci/api_diff.sh
set -euo pipefail
version="$(sed -n 's/^version: //p' pubspec.yaml)"
report="$(mktemp)"

dart pub global activate dart_apitool 0.23.2 >/dev/null
status=0
dart pub global run dart_apitool:main diff \
  --old pub://mpv_audio_kit \
  --new . \
  --version-check-mode=none \
  --report-format=markdown \
  --report-file-path="$report" || status=$?

if [[ ! -s "$report" ]]; then
  echo "::warning title=API against pub.dev::dart_apitool gave no report (exit $status)"
  exit 0
fi
{
  echo "## API of $version against pub.dev"
  cat "$report"
} >> "${GITHUB_STEP_SUMMARY:-/dev/null}"
cat "$report"

# The CHANGELOG entry of this version: from its heading to the next one.
entry="$(awk -v v="## [$version]" '
  index($0, v) == 1 { on = 1; next }
  on && /^## \[/ { exit }
  on { print }
' CHANGELOG.md)"

# A heading of breaking changes, not of non-breaking ones.
if grep -Eiq '^#+ *breaking' "$report"; then
  if grep -q '^\*\*Breaking\*\*' <<<"$entry"; then
    echo "API against pub.dev: breaking changes, stated in the CHANGELOG entry of $version"
  else
    echo "::error title=API against pub.dev::the API breaks against pub.dev and the CHANGELOG entry of $version has no **Breaking** part"
    exit 1
  fi
else
  echo "API against pub.dev: no breaking change"
fi
