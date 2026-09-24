#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# update_libmpv.sh
#
# Points the build hook at a libmpv release: reads the release's manifest.json
# (written by libmpv-scripts' write_manifest.sh) and rewrites `_release` and
# the `_sha256` table in hook/build.dart, the only place the package pins
# its binaries, plus the release the player expects to find in mpv's
# version string (lib/src/internals/libmpv_release.dart), and copies the
# manifest to tool/codegen, whose filter list the effects API follows.
#
# Usage (from the package root):
#   scripts/update_libmpv.sh r15                       # published release
#   scripts/update_libmpv.sh r15 path/to/manifest.json # before publishing
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE="${1:?usage: scripts/update_libmpv.sh <release, e.g. r15> [manifest.json]}"
TAG="libmpv-$RELEASE"

if [[ -n "${2:-}" ]]; then
  MANIFEST="$2"
else
  MANIFEST="$(mktemp)"
  trap 'rm -f "$MANIFEST"' EXIT
  curl -fsSL --retry 3 -o "$MANIFEST" \
    "https://github.com/ales-drnz/mpv_audio_kit/releases/download/$TAG/manifest.json"
fi

python3 - "$MANIFEST" "$ROOT/hook/build.dart" "$TAG" <<'PY'
import json, re, sys

manifest_path, hook_path, tag = sys.argv[1:]
manifest = json.load(open(manifest_path))
if f"libmpv-{manifest['release']}" != tag:
    sys.exit(f"manifest is for libmpv-{manifest['release']}, not {tag}")

hook = open(hook_path).read()
hook, n = re.subn(r"const _release = '[^']*';", f"const _release = '{tag}';", hook)
if n != 1:
    sys.exit("hook/build.dart: _release not found")

table = re.search(r"const _sha256 = <String, String>\{\n(.*?)\n\};", hook, re.S)
if not table:
    sys.exit("hook/build.dart: _sha256 table not found")
pinned = re.findall(r"'([^']+)':\s*'[0-9a-f]*',", table.group(1))
missing = [name for name in pinned if name not in manifest["assets"]]
if missing:
    sys.exit(f"{tag} has no {', '.join(missing)}")
rows = "\n".join(f"  '{name}': '{manifest['assets'][name]}'," for name in pinned)
hook = hook[:table.start(1)] + rows + hook[table.end(1):]
open(hook_path, "w").write(hook)

release_path = hook_path.replace("hook/build.dart", "lib/src/internals/libmpv_release.dart")
release = open(release_path).read()
release, n = re.subn(r"const String libmpvRelease = '[^']*';",
                     f"const String libmpvRelease = '{manifest['release']}';", release)
if n != 1:
    sys.exit("libmpv_release.dart: libmpvRelease not found")
open(release_path, "w").write(release)
print(f"hook/build.dart -> {tag} (mpv {manifest['mpv']}, FFmpeg {manifest['ffmpeg']}, "
      f"{len(pinned)} assets)")
PY

dart format "$ROOT/hook/build.dart" >/dev/null

# The codegen reads the filters and the FFmpeg version from its own copy;
# rerun tool/codegen/regen.sh afterwards if they changed.
cp "$MANIFEST" "$ROOT/tool/codegen/libmpv_manifest.json"
