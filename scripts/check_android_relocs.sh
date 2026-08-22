#!/usr/bin/env bash
#
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Guard against relocation formats the target's linker cannot read.
#
# Bionic ignores dynamic tags it does not know, so a .so linked with a
# relocation format that is too new does not fail to load: it loads with every
# relative relocation unapplied, and the first .init_array pointer still holds
# its link-time value. dlopen() then jumps to an unmapped address and the
# process dies with SIGSEGV before any Dart code runs. glibc guards against
# this with a GLIBC_ABI_DT_RELR version dependency; Android has no equivalent,
# which is why this has to be caught at build time. See issue #16.
#
# Floors, from bionic's linker:
#   DT_RELR         (0x24)       official tags, API 30+   (Android 11)
#   DT_ANDROID_RELR (0x6fffe000) OS-private tags, API 28+ (Android 9)
#   DT_ANDROID_RELA (0x60000011) APS2 packing, API 23+    (Android 6)
#   DT_ANDROID_REL  (0x6000000f) APS2 on a REL target (32-bit arm), API 23+
#
# The authority is the module's minSdk, NOT the API level a binary was compiled
# for: minSdk is what decides which devices may install the app, so a .so built
# against a higher API still has to load on the lowest one allowed.
#
# Exit codes: 0 all checked binaries are loadable, 1 at least one is not,
# 2 nothing could be checked (missing tools, missing or empty directory).
#
# Usage: scripts/check_android_relocs.sh [jniLibs_dir]

set -euo pipefail

# readelf localizes its output; keep tag names and columns predictable.
export LC_ALL=C

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

JNILIBS="${1:-$ROOT/android/src/main/jniLibs}"
GRADLE="$ROOT/android/build.gradle.kts"

# llvm-readelf understands every tag GNU binutils does, and more; accept either.
READELF=""
for c in readelf llvm-readelf eu-readelf; do
    if command -v "$c" >/dev/null 2>&1; then READELF="$c"; break; fi
done
if [ -z "$READELF" ]; then
    echo "check_android_relocs: no readelf found (install binutils or llvm)" >&2
    exit 2
fi

MIN_SDK="$(sed -n 's/.*minSdk[[:space:]]*=[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$GRADLE" 2>/dev/null | head -1 || true)"
if [ -z "${MIN_SDK:-}" ]; then
    echo "check_android_relocs: could not read minSdk from $GRADLE" >&2
    exit 2
fi

if [ ! -d "$JNILIBS" ]; then
    echo "check_android_relocs: $JNILIBS not found, nothing checked (run a build first)" >&2
    exit 2
fi

shopt -s nullglob globstar
libs=("$JNILIBS"/**/*.so)
if [ ${#libs[@]} -eq 0 ]; then
    echo "check_android_relocs: no .so under $JNILIBS, nothing checked" >&2
    exit 2
fi

# API level a .so was built for, from the first uint32 of the Android build ID
# note. Printed for context only. Empty when the note is absent.
built_for_api() {
    local bytes
    bytes="$($READELF -nW "$1" 2>/dev/null \
        | awk '/Android/ && /description data:/ {
                 for (i = 1; i < NF; i++) if ($i == "data:") {
                   print $(i+4) $(i+3) $(i+2) $(i+1); exit
                 }
               }')" || true
    [ -n "$bytes" ] && printf '%d' "$((16#$bytes))" || true
}

# "<tag name> <required api>" for the packing this .so uses, empty when it uses
# none. Matched on the dynamic tag NUMBER: whether readelf knows a symbolic name
# for it varies by binutils version, and an unknown tag prints anonymously.
reloc_format() {
    local dyn
    dyn="$($READELF -dW "$1" 2>/dev/null)" || return 1
    # A stripped-but-valid shared object always has these; their absence means
    # the file is not a dynamic ELF, or readelf could not parse it.
    grep -qE '\(STRTAB\)|\(SYMTAB\)' <<<"$dyn" || return 1
    local tag
    tag="$(awk '{ sub(/^0x0*/, "", $1); print tolower($1) }' <<<"$dyn")"
    if   grep -qx '24'       <<<"$tag"; then echo "DT_RELR 30"
    elif grep -qx '6fffe000' <<<"$tag"; then echo "DT_ANDROID_RELR 28"
    elif grep -qx '60000011' <<<"$tag"; then echo "DT_ANDROID_RELA 23"
    elif grep -qx '6000000f' <<<"$tag"; then echo "DT_ANDROID_REL 23"
    fi
}

failed=0
for so in "${libs[@]}"; do
    name="${so#"$JNILIBS"/}"
    api="$(built_for_api "$so")"

    if ! out="$(reloc_format "$so")"; then
        printf 'FAIL  %-32s unreadable, not a dynamic ELF?\n' "$name"
        failed=1
        continue
    fi
    read -r fmt floor <<<"$out"

    if [ -z "${fmt:-}" ]; then
        printf 'ok    %-32s minSdk %-3s unpacked relocations\n' "$name" "$MIN_SDK"
    elif [ "$MIN_SDK" -lt "$floor" ]; then
        printf 'FAIL  %-32s minSdk %-3s %s needs API %s+\n' "$name" "$MIN_SDK" "$fmt" "$floor"
        failed=1
    else
        printf 'ok    %-32s minSdk %-3s %s (needs %s+)\n' "$name" "$MIN_SDK" "$fmt" "$floor"
    fi

    # Not what this guard is for, but a .so built above minSdk can reference
    # symbols the oldest supported device does not have, so it is worth saying.
    if [ -n "${api:-}" ] && [ "$api" -gt "$MIN_SDK" ]; then
        printf 'warn  %-32s built for API %s, above minSdk %s\n' "$name" "$api" "$MIN_SDK"
    fi
done

if [ "$failed" -ne 0 ]; then
    cat >&2 <<'EOF'

Devices below the required API will SIGSEGV inside dlopen, with no error the
app can catch. Rebuild libmpv with -Wl,--pack-dyn-relocs=android (APS2, safe
from API 23) instead of -Wl,-z,pack-relative-relocs.

Note that appending an override is not enough: lld picks the format with an
if/else, so -z pack-relative-relocs beats --pack-dyn-relocs=none, and
--pack-dyn-relocs=relr beats -z nopack-relative-relocs. Remove the offending
flag, or append both annullers.
EOF
    exit 1
fi
