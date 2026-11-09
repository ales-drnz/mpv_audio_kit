#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The API docs pub.dev builds: dart doc finds no warning in them, so every
# [reference] of a doc comment and every topic of dartdoc_options.yaml
# resolves. A reference that does not resolve is a broken link on pub.dev.
# Nor does a reference point at a flat field of PlayerState, deprecated
# until 0.8.0: [PlaybackState.position], not [PlayerState.position].
#
#   bash test/docs/dartdoc_test.sh      (after flutter pub get)
set -euo pipefail
cd "$(dirname "$0")/../.."
out="$(dart doc --dry-run 2>&1)" || { echo "$out"; exit 1; }
summary="$(grep -E '^Found [0-9]+ warnings? and [0-9]+ errors?' <<<"$out" || true)"
echo "${summary:-dart doc printed no summary}"
grep -E '^ *(warning|error):' <<<"$out" || true
flat="$(sed -nE "s/^ *@Deprecated\('Use [a-z]+\.([A-Za-z]+);.*/\1/p" lib/src/generated/player_state_data.dart | paste -sd'|')"
deprecated="$(grep -rnE "\[PlayerState\.($flat)\]" lib --include='*.dart' | grep -v '/generated/' || true)"
[[ -z "$deprecated" ]] || { echo "references to the deprecated flat fields:"; echo "$deprecated"; }
[[ "$summary" == "Found 0 warnings and 0 errors." && -z "$deprecated" ]]
