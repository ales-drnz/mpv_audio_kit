#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# update_libmpv.sh
#
# Points the package at a libmpv release: reads the release's manifest.json
# (written by libmpv-scripts' write_manifest.sh), rewrites the release in
# lib/src/internals/libmpv_release.dart, the one place the package names it
# (the hook downloads it, the player expects it in mpv's version string),
# and the `_sha256` table of its assets in hook/build.dart, installs the web
# module of the release in web/ and copies the manifest to tool/codegen,
# whose filter list the effects API follows.
#
# The web module is the release's libmpv_web.zip: its SHA-256 is checked
# against the manifest, its ABI against webModuleAbi in libmpv_release.dart,
# and each file the manifest lists under web.files against its own SHA-256
# before it lands in web/, which pubspec.yaml ships as web assets. Nothing
# is written unless every check passes. The files stay out of git and go
# into the published package.
#
# Usage (from the package root):
#   scripts/update_libmpv.sh r20                       # published release
#   scripts/update_libmpv.sh r20 path/to/manifest.json # before publishing,
#       with libmpv_web.zip beside the manifest (the libmpv-release artifact
#       of the Build has both)
# =============================================================================

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE="${1:?usage: scripts/update_libmpv.sh <release, e.g. r20> [manifest.json]}"
TAG="libmpv-$RELEASE"
BASE_URL="https://github.com/ales-drnz/mpv_audio_kit/releases/download/$TAG"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [[ -n "${2:-}" ]]; then
  MANIFEST="$2"
  WEB_ZIP="$(dirname "$2")/libmpv_web.zip"
else
  MANIFEST="$WORK/manifest.json"
  WEB_ZIP="$WORK/libmpv_web.zip"
  curl -fsSL --retry 3 -o "$MANIFEST" "$BASE_URL/manifest.json"
  curl -fsSL --retry 3 -o "$WEB_ZIP" "$BASE_URL/libmpv_web.zip"
fi

python3 - "$MANIFEST" "$WEB_ZIP" "$ROOT" "$TAG" <<'PY'
import hashlib, json, os, re, sys, zipfile

manifest_path, zip_path, root, tag = sys.argv[1:]
manifest = json.load(open(manifest_path))
if f"libmpv-{manifest['release']}" != tag:
    sys.exit(f"manifest is for libmpv-{manifest['release']}, not {tag}")

def sha256(data):
    return hashlib.sha256(data).hexdigest()

# Native assets: the hook's table, rewritten from the manifest.
hook_path = f"{root}/hook/build.dart"
hook = open(hook_path).read()
table = re.search(r"const _sha256 = <String, String>\{\n(.*?)\n\};", hook, re.S)
if not table:
    sys.exit("hook/build.dart: _sha256 table not found")
pinned = re.findall(r"'([^']+)':\s*'[0-9a-f]*',", table.group(1))
missing = [name for name in pinned if name not in manifest["assets"]]
if missing:
    sys.exit(f"{tag} has no {', '.join(missing)}")
rows = "\n".join(f"  '{name}': '{manifest['assets'][name]}'," for name in pinned)
hook = hook[:table.start(1)] + rows + hook[table.end(1):]

release_path = f"{root}/lib/src/internals/libmpv_release.dart"
release = open(release_path).read()
release, n = re.subn(r"const String libmpvRelease = '[^']*';",
                     f"const String libmpvRelease = '{manifest['release']}';", release)
if n != 1:
    sys.exit("libmpv_release.dart: libmpvRelease not found")

# The web module: the zip, its ABI and each file, all checked first.
web = manifest.get("web")
if not web:
    sys.exit(f"{tag} has no web module (its manifest names no \"web\"); "
             "this package ships one, from libmpv-r20 on")
abi = re.search(r"const int webModuleAbi = (\d+);", release)
if not abi:
    sys.exit("libmpv_release.dart: webModuleAbi not found")
if web["abi"] != int(abi.group(1)):
    sys.exit(f"the web module of {tag} has ABI {web['abi']}, and the package "
             f"drives ABI {abi.group(1)}: update lib/src/backend/web first")
asset = web["asset"]
if not os.path.isfile(zip_path):
    sys.exit(f"{zip_path} not found: {asset} goes beside the manifest")
zip_bytes = open(zip_path, "rb").read()
if sha256(zip_bytes) != manifest["assets"].get(asset):
    sys.exit(f"{zip_path}: SHA-256 {sha256(zip_bytes)} is not the "
             f"{manifest['assets'].get(asset)} of the manifest")
files = {}
with zipfile.ZipFile(zip_path) as z:
    for name, digest in web["files"].items():
        if os.path.basename(name) != name or name.startswith("."):
            sys.exit(f"web.files: {name!r} is not a plain file name")
        try:
            data = z.read(name)
        except KeyError:
            sys.exit(f"{asset} has no {name}")
        if sha256(data) != digest:
            sys.exit(f"{asset}: {name} has SHA-256 {sha256(data)}, "
                     f"the manifest says {digest}")
        files[name] = data

# Every check passed: write.
open(hook_path, "w").write(hook)
open(release_path, "w").write(release)
web_dir = f"{root}/web"
os.makedirs(web_dir, exist_ok=True)
for name, data in files.items():
    tmp = f"{web_dir}/.{name}.tmp"
    open(tmp, "wb").write(data)
    os.replace(tmp, f"{web_dir}/{name}")
print(f"hook/build.dart -> {tag} (mpv {manifest['mpv']}, FFmpeg {manifest['ffmpeg']}, "
      f"{len(pinned)} assets); web/ <- {asset} (ABI {web['abi']}, {len(files)} files)")
PY

dart format "$ROOT/hook/build.dart" >/dev/null

# The codegen reads the filters and the FFmpeg version from its own copy;
# rerun tool/codegen/regen.sh afterwards if they changed.
if [[ ! "$MANIFEST" -ef "$ROOT/tool/codegen/libmpv_manifest.json" ]]; then
  cp "$MANIFEST" "$ROOT/tool/codegen/libmpv_manifest.json"
fi

if [[ -n "${2:-}" ]]; then
  echo "While $TAG is not published, CI needs the repository" \
    "variable LIBMPV_SCRIPTS_RUN set to the libmpv-scripts run that built it," \
    "and the secret LIBMPV_SCRIPTS_TOKEN present and not expired" \
    "(see .github/workflows/ci.yml)."
fi
