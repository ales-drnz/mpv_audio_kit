#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# Runs `flutter test` with the network server of the browser tests
# (net_server.dart) beside it, its URL passed as MAK_WEB_NET:
#
#   test/web/with_net_server.sh --platform chrome --wasm test/web
#
# The tests that need it skip without it.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log="$(mktemp)"
dart run "$here/net_server.dart" > "$log" &
server=$!
trap 'kill "$server" 2>/dev/null; rm -f "$log"' EXIT
for _ in $(seq 100); do
  url="$(sed -n 's/^MAK_WEB_NET=//p' "$log")"
  [[ -n "$url" ]] && break
  sleep 0.1
done
[[ -n "$url" ]] || { echo "net_server.dart did not start" >&2; exit 1; }
flutter test --dart-define=MAK_WEB_NET="$url" "$@"
