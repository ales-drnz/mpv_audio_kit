#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The production path of the web, which the browser tests do not take:
# `flutter build web` with dart2js (what Firefox and Safari get, and every
# browser without --wasm), the module loaded from the package's web assets
# and its workers from that URL, served with COOP and COEP on every file
# (coi_server.dart). Chrome headless opens the page of test_app's
# lib/web_smoke.dart, which plays a fixture to its end and posts the
# outcome to the server. The files of the web module in <module dir> are
# copied to web/ for the build, and taken out again after it.
#
#   CHROME_EXECUTABLE=<chrome> test/web/dart2js_smoke.sh <module dir>
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chrome="${CHROME_EXECUTABLE:?the Chrome to run}"
module="${1:?usage: dart2js_smoke.sh <module dir>}"
work="$(mktemp -d)"
server=""
browser=""
copied=()
# Chrome runs in a process group of its own, all of which goes: a child
# still writing to the profile made the rm of the work dir fail the run.
cleanup() {
  if [[ -n "$browser" ]]; then
    kill -- "-$browser" 2>/dev/null || true
    wait "$browser" 2>/dev/null || true
  fi
  [[ -n "$server" ]] && kill "$server" 2>/dev/null || true
  for f in "${copied[@]}"; do rm -f "$root/web/$f"; done
  rm -rf "$work" 2>/dev/null || true
}
trap cleanup EXIT

for f in libmpv.mjs libmpv.wasm mak_webaudio_processor.js THIRD_PARTY_LICENSES.txt; do
  [[ -f "$module/$f" ]] || { [[ $f == THIRD_PARTY_LICENSES.txt ]] && continue; echo "$module/$f is missing"; exit 1; }
  [[ -e "$root/web/$f" ]] && continue
  cp "$module/$f" "$root/web/$f"
  copied+=("$f")
done

(cd "$root/test_app" && flutter pub get >/dev/null &&
  flutter build web --release --no-web-resources-cdn -t lib/web_smoke.dart)

dart run "$root/test/web/coi_server.dart" "$root/test_app/build/web" > "$work/server.txt" &
server=$!
for _ in $(seq 100); do
  grep -q '^MAK_COI=' "$work/server.txt" 2>/dev/null && break
  sleep 0.2
done
url="$(sed -n 's/^MAK_COI=//p' "$work/server.txt")"
[[ -n "$url" ]] || { echo "coi_server.dart did not start"; exit 1; }

# The sound runs as after a gesture, into no device.
setsid "$chrome" --headless --no-sandbox --mute-audio \
  --autoplay-policy=no-user-gesture-required \
  --enable-logging=stderr --v=0 --user-data-dir="$work/profile" "$url" \
  2> "$work/chrome.txt" &
browser=$!
for _ in $(seq 240); do
  grep -q '^MAK_RESULT ' "$work/server.txt" && break
  kill -0 "$browser" 2>/dev/null || { echo "Chrome exited"; break; }
  sleep 0.5
done
line="$(sed -n 's/^MAK_RESULT //p' "$work/server.txt" | head -1)"
echo "${line:-no outcome from the page in 120 s}"
if [[ "$line" != "completed webaudio" ]]; then
  grep -iE 'console|error' "$work/chrome.txt" | tail -20 || true
  exit 1
fi
