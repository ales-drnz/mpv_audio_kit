#!/usr/bin/env python3
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# web_module.py
#
# Checks the web module of a libmpv release against the release's
# manifest.json and installs its files. libmpv_web.zip must have the
# SHA-256 the manifest lists under assets, the manifest's web.abi must be
# webModuleAbi of lib/src/internals/libmpv_release.dart, and each file the
# manifest lists under web.files must be in the zip, under a plain name,
# with its own SHA-256. Nothing is written unless every check passes.
#
# scripts/update_libmpv.sh installs the module into web/ through it, and
# CI into test/web/module (scripts/ci/web_module.sh).
#
# Usage (from the package root):
#   scripts/web_module.py <manifest.json> <libmpv_web.zip> <directory>
# =============================================================================

import hashlib
import json
import os
import re
import sys
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def package_abi(root=ROOT):
    """The web module ABI the package drives."""
    release = open(f"{root}/lib/src/internals/libmpv_release.dart").read()
    abi = re.search(r"const int webModuleAbi = (\d+);", release)
    if not abi:
        sys.exit("libmpv_release.dart: webModuleAbi not found")
    return int(abi.group(1))


def check(manifest, zip_path, abi):
    """The files of the module by name, once every check has passed."""
    tag = f"libmpv-{manifest['release']}"
    web = manifest.get("web")
    if not web:
        sys.exit(f"{tag} has no web module (its manifest names no \"web\"); "
                 "this package ships one, from libmpv-r20 on")
    if web["abi"] != abi:
        sys.exit(f"the web module of {tag} has ABI {web['abi']}, and the package "
                 f"drives ABI {abi}: update lib/src/backend/web first")
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
    return files


def install(files, directory):
    """Writes [files] into [directory], each through a temporary file."""
    os.makedirs(directory, exist_ok=True)
    for name, data in files.items():
        tmp = f"{directory}/.{name}.tmp"
        open(tmp, "wb").write(data)
        os.replace(tmp, f"{directory}/{name}")


def main():
    if len(sys.argv) != 4:
        sys.exit("usage: scripts/web_module.py <manifest.json> <libmpv_web.zip> <directory>")
    manifest_path, zip_path, directory = sys.argv[1:]
    manifest = json.load(open(manifest_path))
    files = check(manifest, zip_path, package_abi())
    install(files, directory)
    print(f"{directory} <- {manifest['web']['asset']} of libmpv-{manifest['release']} "
          f"(ABI {manifest['web']['abi']}, {len(files)} files)")


if __name__ == "__main__":
    main()
