#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# Copies the web module (libmpv.mjs, libmpv.wasm and
# mak_webaudio_processor.js of a libmpv-scripts web build, or of web/ once
# scripts/update_libmpv.sh installed it) into test/web/module, where the
# browser tests load it from:
#
#   test/web/fetch_module.sh <dir with the three files>
#   CHROME_EXECUTABLE=<chrome> test/web/with_net_server.sh --platform chrome \
#     --wasm test/web
#
# The directory defaults to $MAK_WEB_MODULE_DIR. The release of the module
# is checked by the tests (mpv-version).
set -euo pipefail
src="${1:-${MAK_WEB_MODULE_DIR:?pass the directory of the three files}}"
dst="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/module"
mkdir -p "$dst"
cp "$src/libmpv.mjs" "$src/libmpv.wasm" "$src/mak_webaudio_processor.js" "$dst/"
sha256sum "$dst/libmpv.mjs" "$dst/libmpv.wasm" "$dst/mak_webaudio_processor.js"
