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
# (scripts/web_module.py) before it lands in web/, which pubspec.yaml ships
# as web assets. Nothing is written unless every check passes. The files
# stay out of git and go into the published package.
#
# The license texts are the release's licenses.zip (write_manifest.sh of
# libmpv-scripts: one <target>/ directory per target, with README.txt and a
# directory of license files per component), checked against the SHA-256 the
# manifest lists under licenses. Each text goes once, whatever the targets
# that carry it, into lib/src/internals/libmpv_licenses.dart, a const the
# script generates (libmpvLicenses, with the release in
# libmpvLicensesRelease): MpvAudioKit.ensureInitialized registers it with
# Flutter's LicenseRegistry, so showLicensePage and AboutDialog list the
# libmpv texts (README.txt under libmpv, each component under its name:
# mpv, FFmpeg, OpenSSL...) on every platform, the web included, with
# nothing for the app to set up. The texts of the web target also go to
# web/THIRD_PARTY_LICENSES.txt, beside the web module (the target's own
# THIRD_PARTY_LICENSES.txt when the zip has one, else its files joined),
# out of git like the module and in the published package. Before
# libmpv-r20, the first release with licenses.zip, libmpvLicenses is empty
# and nothing is registered.
#
# Usage (from the package root):
#   scripts/update_libmpv.sh r20                       # published release
#   scripts/update_libmpv.sh r20 path/to/manifest.json # before publishing,
#       with libmpv_web.zip and licenses.zip beside the manifest (the
#       libmpv-release artifact of the Build has them)
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
  LICENSES_ZIP="$(dirname "$2")/licenses.zip"
else
  MANIFEST="$WORK/manifest.json"
  WEB_ZIP="$WORK/libmpv_web.zip"
  LICENSES_ZIP="$WORK/licenses.zip"
  curl -fsSL --retry 3 -o "$MANIFEST" "$BASE_URL/manifest.json"
  curl -fsSL --retry 3 -o "$WEB_ZIP" "$BASE_URL/libmpv_web.zip"
  curl -fsSL --retry 3 -o "$LICENSES_ZIP" "$BASE_URL/licenses.zip"
fi

python3 - "$MANIFEST" "$WEB_ZIP" "$LICENSES_ZIP" "$ROOT" "$TAG" <<'PY'
import hashlib, json, os, re, sys, zipfile

manifest_path, zip_path, licenses_path, root, tag = sys.argv[1:]
sys.dont_write_bytecode = True
sys.path.insert(0, f"{root}/scripts")
import web_module

manifest = json.load(open(manifest_path))
if f"libmpv-{manifest['release']}" != tag:
    sys.exit(f"manifest is for libmpv-{manifest['release']}, not {tag}")

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

# The web module: the zip, its ABI and each file (scripts/web_module.py).
files = web_module.check(manifest, zip_path, web_module.package_abi(root))

# The license texts: licenses.zip, <target>/README.txt and
# <target>/<component>/<license files> (write_licenses of libmpv-scripts).
licenses = manifest.get("licenses")
if not licenses:
    sys.exit(f"{tag} has no license texts (its manifest names no \"licenses\"); "
             "this package ships them, from libmpv-r20 on")
if licenses["asset"] != os.path.basename(licenses_path):
    sys.exit(f"the license texts of {tag} are {licenses['asset']}, not "
             f"{os.path.basename(licenses_path)}")
if not os.path.isfile(licenses_path):
    sys.exit(f"{licenses_path} not found: {licenses['asset']} goes beside the manifest")
licenses_bytes = open(licenses_path, "rb").read()
if hashlib.sha256(licenses_bytes).hexdigest() != licenses["sha256"]:
    sys.exit(f"{licenses_path}: SHA-256 {hashlib.sha256(licenses_bytes).hexdigest()} "
             f"is not the {licenses['sha256']} of the manifest")

# The name showLicensePage lists a component under; another one keeps the
# name of its directory.
NAMES = {
    "mpv": "mpv", "ffmpeg": "FFmpeg", "openssl": "OpenSSL", "libxml2": "libxml2",
    "zlib": "zlib", "xz": "XZ Utils", "bzip2": "bzip2", "libiconv": "GNU libiconv",
    "fribidi": "GNU FriBidi", "fontconfig": "Fontconfig",
    "libass": "libass", "libpng": "libpng", "expat": "Expat",
    "libunibreak": "libunibreak", "libplacebo": "libplacebo", "libsmb2": "libsmb2",
    "pipewire": "PipeWire", "speexdsp": "SpeexDSP", "harfbuzz": "HarfBuzz",
    "freetype": "FreeType", "mozilla-ca": "Mozilla CA certificates",
    "winpthreads": "winpthreads", "implib": "Implib.so",
    "libmpv-scripts": "libmpv-scripts",
}
COMBINED = "THIRD_PARTY_LICENSES.txt"

def text(data):
    try:
        t = data.decode("utf-8")
    except UnicodeDecodeError:
        t = data.decode("latin-1")
    return t.replace("\r\n", "\n").lstrip("\ufeff")

targets = {}
with zipfile.ZipFile(licenses_path) as z:
    for info in z.infolist():
        if info.is_dir():
            continue
        parts = info.filename.split("/")
        if (info.filename.startswith("/") or "\\" in info.filename or len(parts) < 2
                or any(p in ("", ".", "..") for p in parts)):
            sys.exit(f"{licenses['asset']}: {info.filename!r} is not <target>/<file>")
        targets.setdefault(parts[0], {})["/".join(parts[1:])] = z.read(info)
if not targets:
    sys.exit(f"{licenses['asset']} of {tag} holds no license texts")
entries = {}
for target in sorted(targets):
    names = targets[target]
    if "README.txt" not in names:
        sys.exit(f"{licenses['asset']}: {target}/ has no README.txt")
    for name in ["README.txt"] + sorted(names):
        if name == COMBINED:
            continue
        package = "libmpv" if name == "README.txt" else NAMES.get(name.split("/")[0])
        if package is None:
            if "/" not in name:
                continue
            package = name.split("/")[0]
        entries.setdefault((package, text(names[name])), None)
# libmpv first, then the components by name.
entries = sorted(entries, key=lambda e: (e[0] != "libmpv", e[0].lower()))

def dart_string(t):
    lines = t.splitlines(keepends=True) or [""]
    return "\n".join("      " + json.dumps(l).replace("$", "\\$") for l in lines)

generated = (
    "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.\n"
    "// All rights reserved.\n"
    "// Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.\n"
    "//\n"
    "// AUTO-GENERATED by scripts/update_libmpv.sh from the licenses.zip of the\n"
    "// libmpv release: do not edit by hand. The license texts below are those\n"
    "// of the components of that libmpv, each under its own terms.\n"
    "\n"
    "// ignore_for_file: prefer_single_quotes\n"
    "\n"
    "/// The libmpv release whose license texts [libmpvLicenses] holds, or `''`\n"
    "/// when it holds none.\n"
    f"const String libmpvLicensesRelease = '{manifest['release']}';\n"
    "\n"
    "/// The license texts of the libmpv the package ships, from the\n"
    "/// `licenses.zip` of [libmpvLicensesRelease], each text once across the\n"
    "/// targets: the packages it applies to, as `showLicensePage` lists them,\n"
    "/// and the text.\n"
    "const List<(List<String>, String)> libmpvLicenses = [\n"
    + "".join(f"  (\n    [{json.dumps(p)}],\n{dart_string(t)},\n  ),\n" for p, t in entries)
    + "];\n"
)

# The texts of the web target, beside the web module.
web_texts = None
if "web" in targets:
    names = targets["web"]
    if COMBINED in names:
        web_texts = names[COMBINED]
    else:
        parts = [text(names["README.txt"])]
        parts += [f"==== {n} ====\n\n{text(names[n])}" for n in sorted(names)
                  if n not in ("README.txt", COMBINED)]
        web_texts = "\n\n".join(p.rstrip("\n") for p in parts).encode() + b"\n"
else:
    sys.exit(f"{licenses['asset']} of {tag} has no web/ texts for the web module")

# Every check passed: write.
open(hook_path, "w").write(hook)
open(release_path, "w").write(release)
web_module.install(files, f"{root}/web")
web_module.install({COMBINED: web_texts}, f"{root}/web")
open(f"{root}/lib/src/internals/libmpv_licenses.dart", "w", encoding="utf-8").write(generated)
web = manifest["web"]
print(f"hook/build.dart -> {tag} (mpv {manifest['mpv']}, FFmpeg {manifest['ffmpeg']}, "
      f"{len(pinned)} assets); web/ <- {web['asset']} (ABI {web['abi']}, {len(files)} files); "
      f"libmpv_licenses.dart <- {licenses['asset']} ({len(entries)} texts, "
      f"{len(targets)} targets)")
PY

dart format "$ROOT/hook/build.dart" "$ROOT/lib/src/internals/libmpv_licenses.dart" >/dev/null

# The codegen reads the filters and the FFmpeg version from its own copy;
# rerun tool/codegen/regen.sh afterwards if they changed.
if [[ ! "$MANIFEST" -ef "$ROOT/tool/codegen/libmpv_manifest.json" ]]; then
  cp "$MANIFEST" "$ROOT/tool/codegen/libmpv_manifest.json"
fi

if [[ -n "${2:-}" ]]; then
  echo "While $TAG is not published, CI takes the latest successful" \
    "Build of libmpv-scripts release/$RELEASE (scripts/ci/resolve_libmpv_run.sh)," \
    "which needs the secret LIBMPV_SCRIPTS_TOKEN present and not expired" \
    "(see .github/workflows/ci.yml)."
fi
