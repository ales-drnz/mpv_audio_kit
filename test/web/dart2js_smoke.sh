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
# lib/web_smoke.dart, which plays a fixture to its end; the script waits
# for the line it prints. The web module must be in web/.
#
#   CHROME_EXECUTABLE=<chrome> test/web/dart2js_smoke.sh
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
chrome="${CHROME_EXECUTABLE:?the Chrome to run}"
for f in libmpv.mjs libmpv.wasm mak_webaudio_processor.js; do
  [[ -f "$root/web/$f" ]] || { echo "web/$f is missing: install the web module first"; exit 1; }
done
work="$(mktemp -d)"
server=""
browser=""
cleanup() {
  [[ -n "$browser" ]] && kill "$browser" 2>/dev/null || true
  [[ -n "$server" ]] && kill "$server" 2>/dev/null || true
  rm -rf "$work"
}
trap cleanup EXIT

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
"$chrome" --headless --mute-audio --autoplay-policy=no-user-gesture-required \
  --enable-logging=stderr --v=0 --user-data-dir="$work/profile" \
  --remote-debugging-port=0 "$url" 2> "$work/chrome.txt" &
browser=$!
for _ in $(seq 240); do
  if grep -q 'MAK_WEB_SMOKE' "$work/chrome.txt"; then break; fi
  sleep 0.5
done
line="$(grep -o 'MAK_WEB_SMOKE[^"]*' "$work/chrome.txt" | head -1 || true)"
echo "${line:-no line from the page in 120 s}"
if [[ "$line" != "MAK_WEB_SMOKE completed webaudio" ]]; then
  grep -iE 'console|error' "$work/chrome.txt" | tail -20 || true
  exit 1
fi
