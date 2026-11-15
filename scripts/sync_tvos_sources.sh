#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# sync_tvos_sources.sh
#
# The Swift sources of the plugin live in
# darwin/mpv_audio_kit/Sources/mpv_audio_kit, and tvos/Sources/mpv_audio_kit
# holds a copy of each: flutter-tvos reads the plugin from tvos/Package.swift,
# SwiftPM takes no target outside the package root, and a published package
# keeps no symlink. The darwin files are the ones to edit.
#
#   scripts/sync_tvos_sources.sh            copies darwin over tvos
#   scripts/sync_tvos_sources.sh --check    changes nothing, exits 1 when the
#                                           two differ and names each file
#
# test/packaging/darwin_package_test.dart runs the check.
# =============================================================================
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
darwin="$root/darwin/mpv_audio_kit/Sources/mpv_audio_kit"
tvos="$root/tvos/Sources/mpv_audio_kit"

check=0
case "${1:-}" in
  "") ;;
  --check) check=1 ;;
  *)
    echo "usage: $0 [--check]" >&2
    exit 2
    ;;
esac

for dir in "$darwin" "$tvos"; do
  if [[ ! -d "$dir" ]]; then
    echo "sync_tvos_sources: $dir is missing" >&2
    exit 2
  fi
done

if [[ "$check" -eq 1 ]]; then
  different=0
  for file in "$darwin"/*; do
    name="$(basename "$file")"
    if [[ ! -f "$tvos/$name" ]]; then
      echo "tvos/Sources/mpv_audio_kit/$name is missing"
      different=1
    elif ! cmp -s "$file" "$tvos/$name"; then
      echo "tvos/Sources/mpv_audio_kit/$name differs from the darwin one"
      different=1
    fi
  done
  for file in "$tvos"/*; do
    name="$(basename "$file")"
    if [[ ! -f "$darwin/$name" ]]; then
      echo "tvos/Sources/mpv_audio_kit/$name has no darwin source"
      different=1
    fi
  done
  if [[ "$different" -ne 0 ]]; then
    echo "Run scripts/sync_tvos_sources.sh to copy the darwin sources over." >&2
    exit 1
  fi
  echo "The tvOS sources are the darwin ones."
  exit 0
fi

# The copy: every darwin file over its tvos one, and a tvos file with no
# darwin source goes.
for file in "$tvos"/*; do
  name="$(basename "$file")"
  if [[ ! -f "$darwin/$name" ]]; then
    rm -f "$file"
    echo "removed tvos/Sources/mpv_audio_kit/$name"
  fi
done
for file in "$darwin"/*; do
  name="$(basename "$file")"
  if ! cmp -s "$file" "$tvos/$name" 2>/dev/null; then
    cp "$file" "$tvos/$name"
    echo "copied $name"
  fi
done
