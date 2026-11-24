#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be
# found in the LICENSE file.

# setup.sh <work dir>: the tools test_hap.sh expects in <work dir>, each at
# its pin, and the work dir's env file (env.sh) for the steps after it.
#
#   flutter/        Flutter-OH (gitcode CPF-Flutter/flutter_flutter) at
#                   FLUTTER_OH_COMMIT of oh-3.41.9-release, without the
#                   engine sources, tagged 3.41.9 so its version resolves
#   cmdtools/command-line-tools/   the HarmonyOS command-line tools at their
#                   sha256, without their own SDKs (API 18 and HMS, 5.8 GB):
#                   hvigor and ohpm are what the build takes from them
#   ohsdk/26/       ets, js, previewer, native and toolchains of the public
#                   OpenHarmony 7.0 SDK (API 26), at the sha256 of each zip.
#                   The Linux zips lead the 3.7 GB tarball: it is streamed
#                   and tar stops after them. Their descriptors get metaVersion
#                   3.0.0 and no platformVersion: hvigor 5.18 finds no
#                   component of API 26 otherwise.
#   sdk-lib/        toolchains/lib (hap-sign-tool and the debug keys)
#   hmsdk/          the SDK root Flutter-OH wants, pointing at ohsdk/26
#   hdc             toolchains/hdc, on PATH through env.sh
#
# A part already there at the same pin (its .pin file) is kept, so the
# Actions cache of the work dir restores it.
set -euo pipefail

work="$(mkdir -p "${1:?usage: setup.sh <work dir>}" && cd "$1" && pwd)"

FLUTTER_OH_REPO=https://gitcode.com/CPF-Flutter/flutter_flutter.git
FLUTTER_OH_COMMIT=4496580ac8668b23e2dfbd0b732c889f818e6e05
FLUTTER_OH_VERSION=3.41.9
CMDTOOLS_URL=https://repo.huaweicloud.com/harmonyos/ohpm/5.1.0/commandline-tools-linux-x64-5.1.0.840.zip
CMDTOOLS_SHA256=1dcefa4741dc289277560b2802040e0c45b433898d8db453d711d5376e0478f1
OHOS_SDK_URL=https://repo.huaweicloud.com/openharmony/os/7.0-Release/ohos-sdk-windows_linux-public_20260829.tar.gz
OHOS_SDK_VERSION=26.0.0.38
# <part> <sha256 of ohos-sdk/linux/<part>-linux-x64-<version>-Release.zip>
OHOS_SDK_ZIPS=(
  "toolchains 50b8c27dbba4d9ee34840613b08f988cd164e30d46dadaa149883b6f14fd83b7"
  "ets 3b8418f9e931e47699dd1f8bf9bf31ad13691748e45be202d33977e430ceb0d1"
  "native ab828a0f960a829e7b75d764158696a8b926cf8a3035cbd313ff98daf0c69fe0"
  "js a3dd68c806f8cb320ab2ded81f6e6f7e98d7cb1f84eec820ab26a314de0c73bd"
  "previewer a0b9e4e024b4aeaeaf9e934ba0381beafa9d55ec04ffc2620d7a09696c8759c3"
)

# pinned <dir> <pin>: whether <dir> holds what <pin> names.
pinned() { [[ -f "$1/.pin" && "$(cat "$1/.pin")" == "$2" ]]; }

# ── Flutter-OH ────────────────────────────────────────────────────────────
fl="$work/flutter"
if ! pinned "$fl" "$FLUTTER_OH_COMMIT"; then
  rm -rf "$fl"
  git init -q "$fl"
  git -C "$fl" remote add origin "$FLUTTER_OH_REPO"
  # The engine's sources are in the repository too; the tool downloads the
  # engine's artifacts instead.
  git -C "$fl" sparse-checkout set --no-cone '/*' '!/engine/'
  git -C "$fl" fetch -q --depth 1 --filter=blob:none origin "$FLUTTER_OH_COMMIT"
  git -C "$fl" checkout -q FETCH_HEAD
  git -C "$fl" tag -f "$FLUTTER_OH_VERSION" >/dev/null
  echo "$FLUTTER_OH_COMMIT" > "$fl/.pin"
fi
[[ "$(git -C "$fl" rev-parse HEAD)" == "$FLUTTER_OH_COMMIT" ]]

# ── HarmonyOS command-line tools ──────────────────────────────────────────
ct="$work/cmdtools"
if ! pinned "$ct" "$CMDTOOLS_SHA256"; then
  rm -rf "$ct"
  mkdir -p "$ct"
  curl -fsSL --retry 3 -o "$ct/tools.zip" "$CMDTOOLS_URL"
  echo "$CMDTOOLS_SHA256  $ct/tools.zip" | sha256sum -c -
  unzip -q "$ct/tools.zip" -d "$ct" -x 'command-line-tools/sdk/*' \
    'command-line-tools/codelinter/*' 'command-line-tools/hstack/*'
  rm "$ct/tools.zip"
  echo "$CMDTOOLS_SHA256" > "$ct/.pin"
fi

# ── OpenHarmony 7.0 SDK ───────────────────────────────────────────────────
sdk="$work/ohsdk/26"
sdk_pin="$OHOS_SDK_URL ${OHOS_SDK_ZIPS[*]}"
if ! pinned "$sdk" "$sdk_pin"; then
  rm -rf "$sdk"
  mkdir -p "$sdk/.download"
  members=() sums=""
  for entry in "${OHOS_SDK_ZIPS[@]}"; do
    read -r part sha <<<"$entry"
    zip="ohos-sdk/linux/$part-linux-x64-$OHOS_SDK_VERSION-Release.zip"
    members+=("$zip")
    sums+="$sha  $zip"$'\n'
  done
  # tar exits once it has each member and curl stops on the closed pipe:
  # the checksums below are what counts.
  set +o pipefail
  curl -fsL --retry 3 "$OHOS_SDK_URL" | tar -xzf - -C "$sdk/.download" --occurrence=1 "${members[@]}"
  set -o pipefail
  (cd "$sdk/.download" && sha256sum -c --quiet - <<<"$sums")
  for m in "${members[@]}"; do
    # Without what a HAP build never runs: lldb, clangd, the tidy tools.
    unzip -q "$sdk/.download/$m" -d "$sdk" -x 'native/llvm/bin/lldb*' \
      'native/llvm/bin/clangd' 'native/llvm/bin/clang-tidy' 'native/llvm/lib/liblldb*' 'native/docs/*'
  done
  rm -rf "$sdk/.download"
  python3 -I - "$sdk" <<'PY'
import json, os, sys
for part in ('ets', 'js', 'previewer', 'native', 'toolchains'):
    p = os.path.join(sys.argv[1], part, 'oh-uni-package.json')
    d = json.load(open(p))
    d['meta']['metaVersion'] = '3.0.0'
    d.pop('platformVersion', None)
    json.dump(d, open(p, 'w'), indent=2)
PY
  echo "$sdk_pin" > "$sdk/.pin"
fi
ln -sfn "$sdk/toolchains/lib" "$work/sdk-lib"
# The SDK root Flutter-OH looks for (flutter config --ohos-sdk), laid out as
# DevEco's: default/ with sdk-pkg.json and openharmony/. Without it the tool
# stops at "No Hmos SDK found".
mkdir -p "$work/hmsdk/default"
ln -sfn "$sdk" "$work/hmsdk/default/openharmony"
cat > "$work/hmsdk/default/sdk-pkg.json" <<'JSON'
{"meta": {"version": "1.0.0"}, "data": {"apiVersion": "26", "displayName": "OpenHarmony 7.0", "path": "default", "platformVersion": "7.0.0", "releaseType": "Release", "version": "26.0.0.38", "stage": "Release"}}
JSON
# hvigorw looks for the SDK next to itself, in command-line-tools/sdk.
ln -sfn "$work/hmsdk" "$ct/command-line-tools/sdk"

cat > "$work/env.sh" <<EOF
export OHOS_BASE_SDK_HOME="$work/ohsdk"
export PATH="$fl/bin:$ct/command-line-tools/bin:$ct/command-line-tools/ohpm/bin:$ct/command-line-tools/hvigor/bin:$sdk/toolchains:\$PATH"
export LD_LIBRARY_PATH="$sdk/toolchains\${LD_LIBRARY_PATH:+:\$LD_LIBRARY_PATH}"
EOF
# shellcheck source=/dev/null
source "$work/env.sh"
flutter config --no-analytics --ohos-sdk "$work/hmsdk" >/dev/null
flutter --version
hdc -v
