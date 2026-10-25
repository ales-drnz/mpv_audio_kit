#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# Copies the web module (libmpv.mjs and libmpv.wasm of a libmpv-scripts web
# build) into test/web/module, where the browser tests load it from:
#
#   test/web/fetch_module.sh <dir with libmpv.mjs and libmpv.wasm>
#   CHROME_EXECUTABLE=<chrome> flutter test --platform chrome \
#     --cross-origin-isolation test/web
#
# The directory defaults to $MAK_WEB_MODULE_DIR. The release of the module
# is checked by the tests (mpv-version).
set -euo pipefail
src="${1:-${MAK_WEB_MODULE_DIR:?pass the directory of libmpv.mjs and libmpv.wasm}}"
dst="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/module"
mkdir -p "$dst"
cp "$src/libmpv.mjs" "$src/libmpv.wasm" "$dst/"
sha256sum "$dst/libmpv.mjs" "$dst/libmpv.wasm"
