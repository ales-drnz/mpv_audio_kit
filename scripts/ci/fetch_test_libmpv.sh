#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# Downloads the released libmpv the runtime test suites load, into the path
# test/_helpers/libmpv_resolver.dart looks at. The release tag and SHA-256
# are read from the platform build files, so this never drifts from what a
# real build downloads.
#
# Usage (from the package root): scripts/ci/fetch_test_libmpv.sh linux|macos

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BASE_URL="https://github.com/ales-drnz/mpv_audio_kit/releases/download"

fetch() {
  local url="$1" sha="$2" out="$3"
  curl -fsSL --retry 3 -o "$out" "$url"
  echo "$sha  $out" | sha256sum -c -
}

case "${1:-}" in
  linux)
    cmake="$ROOT/linux/CMakeLists.txt"
    tag=$(sed -nE 's/^set\(MPV_RELEASE_VERSION "([^"]+)"\)/\1/p' "$cmake")
    case "$(uname -m)" in
      x86_64) arch=x86_64 var=EXPECTED_SHA256_X86_64 ;;
      aarch64) arch=aarch64 var=EXPECTED_SHA256_AARCH64 ;;
      *) echo "Unsupported arch: $(uname -m)" >&2; exit 1 ;;
    esac
    sha=$(sed -nE "s/^set\($var +\"([0-9a-f]{64})\"\)/\1/p" "$cmake")
    mkdir -p "$ROOT/linux/libs/$arch"
    fetch "$BASE_URL/$tag/libmpv_linux-$arch.so" "$sha" \
      "$ROOT/linux/libs/$arch/libmpv.so"
    ;;
  macos)
    manifest="$ROOT/macos/mpv_audio_kit/Package.swift"
    url=$(grep -oE 'https://[^"]+libmpv_macos\.xcframework\.zip' "$manifest")
    sha=$(grep -oE 'checksum: "[0-9a-f]{64}"' "$manifest" | grep -oE '[0-9a-f]{64}')
    dest="$ROOT/macos/mpv_audio_kit/Frameworks"
    mkdir -p "$dest"
    zip="$(mktemp -d)/libmpv_macos.xcframework.zip"
    fetch "$url" "$sha" "$zip"
    rm -rf "$dest/libmpv.xcframework"
    unzip -q "$zip" -d "$dest"
    ;;
  *)
    echo "Usage: $0 linux|macos" >&2
    exit 1
    ;;
esac
