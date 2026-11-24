#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The API docs pub.dev builds: dart doc finds no warning in them, so every
# [reference] of a doc comment and every topic of dartdoc_options.yaml
# resolves. A reference that does not resolve is a broken link on pub.dev.
# dart doc writes the page of a topic only when an element is in it
# ({@category Name}), and warns of nothing otherwise: each topic has one, or
# the README's link to its page is a 404.
# Nor does a reference point at a flat field of PlayerState, gone since
# 0.8.0: [PlaybackState.position], not [PlayerState.position]. Nor does a
# doc comment of lib read one in its prose or in an example:
# `state.playback.position`, not `state.position`, which no longer compiles.
#
#   bash test/docs/dartdoc_test.sh      (after flutter pub get)
set -euo pipefail
cd "$(dirname "$0")/../.."
out="$(dart doc --dry-run 2>&1)" || { echo "$out"; exit 1; }
summary="$(grep -E '^Found [0-9]+ warnings? and [0-9]+ errors?' <<<"$out" || true)"
echo "${summary:-dart doc printed no summary}"
grep -E '^ *(warning|error):' <<<"$out" || true
# The fields of the groups, the flat fields of 0.6 and 0.7.
flat="$(sed -nE 's/^  final [^;]+ ([a-zA-Z]+);$/\1/p' lib/src/player/state/*.dart | sort -u | paste -sd'|')"
[[ -n "$flat" ]] || { echo "no field found in lib/src/player/state"; exit 1; }
deprecated="$(grep -rnE "\[PlayerState\.($flat)\]" lib --include='*.dart' | grep -v '/generated/' || true)"
[[ -z "$deprecated" ]] || { echo "references to the flat fields:"; echo "$deprecated"; }
flat_docs="$(grep -rnE "^[[:space:]]*///.*\bstate\.($flat)\b" lib --include='*.dart' || true)"
# The topics and the README too, whose examples nothing compiles: all but
# the sentence that says the flat fields are gone.
flat_docs+="$(grep -nE "\bstate\.($flat)\b" doc/*.md README.md | grep -v 'are gone since 0.8.0' || true)"
[[ -z "$flat_docs" ]] || { echo "doc comments that read the flat fields:"; echo "$flat_docs"; }
empty=""
while read -r topic; do
  grep -rqF "{@category $topic}" lib --include='*.dart' || empty+="${empty:+, }$topic"
done < <(sed -nE '/^  categories:/,/^  [a-zA-Z]+:$/s/^    "([^"]+)":$/\1/p' dartdoc_options.yaml)
[[ -z "$empty" ]] || echo "topics with no element, so no page: $empty"
[[ "$summary" == "Found 0 warnings and 0 errors." && -z "$deprecated" && -z "$flat_docs" && -z "$empty" ]]
