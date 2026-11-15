#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

# =============================================================================
# publish.sh
#
# Publishes the package to pub.dev, once the checkout is the package to
# publish. The web module (web/) is out of git and comes from
# scripts/update_libmpv.sh, so nothing else stops a release without it, or
# with the module of another libmpv. Refuses, naming every reason, when:
#
#   - the git tree is not clean (a file changed, staged or untracked);
#   - the version of pubspec.yaml is not the one of the podspec, of
#     android/build.gradle.kts, of the README's install snippet and of the
#     first title of the CHANGELOG;
#   - the tag v<version> exists, here or on the remote: the release is
#     tagged after it is published;
#   - the pinned manifest (tool/codegen/libmpv_manifest.json) is not the one
#     of libmpvRelease, a file it lists under web.files is missing from web/
#     or has another SHA-256, THIRD_PARTY_LICENSES.txt is missing, or web/
#     holds a file that is none of them.
#
# Usage (from anywhere):
#   scripts/publish.sh              checks, then flutter pub publish, which
#                                   asks before it uploads
#   scripts/publish.sh --dry-run    checks, then flutter pub publish --dry-run
#   scripts/publish.sh --check      checks only
#   scripts/publish.sh --versions   the versions only (CI, whose checkout has
#                                   no web module)
#
# Reads from the environment, for the tests:
#   PUBLISH_ROOT    the package, the parent of scripts/ by default
#   PUBLISH_REMOTE  the remote asked for the tag, origin by default
# =============================================================================

set -euo pipefail

mode="${1:-publish}"
case "$mode" in
  publish | --dry-run | --check | --versions) ;;
  *)
    echo "usage: scripts/publish.sh [--dry-run | --check | --versions]" >&2
    exit 2
    ;;
esac

root="${PUBLISH_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
remote="${PUBLISH_REMOTE:-origin}"
cd "$root"

refusals=0
refuse() {
  echo "publish: $1" >&2
  refusals=$((refusals + 1))
}

sha256() {
  if command -v sha256sum > /dev/null; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# The first match of sed expression $2 in file $1, without a CR.
read_version() {
  tr -d '\r' < "$1" | sed -n "$2" | head -n 1
}

# ── The versions ─────────────────────────────────────────────────────────────

version="$(read_version pubspec.yaml 's/^version: *\([^ ]*\) *$/\1/p')"
if [[ ! "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+([-+][0-9A-Za-z.+-]+)?$ ]]; then
  echo "publish: pubspec.yaml has no version (read '$version')" >&2
  exit 1
fi
same_version() { # what, value
  if [[ "$2" != "$version" ]]; then
    refuse "$1 says '${2:-nothing}', and pubspec.yaml $version: run scripts/bump_version.sh"
  fi
}
same_version "darwin/mpv_audio_kit.podspec" \
  "$(read_version darwin/mpv_audio_kit.podspec "s/^ *s\.version *= *'\([^']*\)'.*/\1/p")"
same_version "android/build.gradle.kts" \
  "$(read_version android/build.gradle.kts 's/^version = "\([^"]*\)".*/\1/p')"
same_version "The install snippet of README.md" \
  "$(read_version README.md 's/^ *mpv_audio_kit: \^\([0-9][0-9A-Za-z.+-]*\).*/\1/p')"
same_version "The first title of CHANGELOG.md" \
  "$(read_version CHANGELOG.md 's/^## \[\([^]]*\)\].*/\1/p')"

if [[ "$mode" != --versions ]]; then

  # ── The tree ───────────────────────────────────────────────────────────────

  dirty="$(git status --porcelain)"
  if [[ -n "$dirty" ]]; then
    refuse "the git tree is not clean:"
    sed 's/^/  /' <<<"$dirty" >&2
  fi

  # ── The tag ────────────────────────────────────────────────────────────────

  tag="v$version"
  if git rev-parse -q --verify "refs/tags/$tag" > /dev/null; then
    refuse "the tag $tag exists here: $version is already released"
  fi
  if git remote get-url "$remote" > /dev/null 2>&1; then
    if ! on_remote="$(git ls-remote --tags "$remote" "refs/tags/$tag")"; then
      refuse "could not ask $remote for the tag $tag"
    elif [[ -n "$on_remote" ]]; then
      refuse "the tag $tag exists on $remote: $version is already released"
    fi
  fi

  # ── The web module ─────────────────────────────────────────────────────────

  manifest=tool/codegen/libmpv_manifest.json
  pin="$(read_version lib/src/internals/libmpv_release.dart \
    "s/^const String libmpvRelease = '\([^']*\)';/\1/p")"
  release="$(jq -r .release "$manifest" | tr -d '\r')"
  if [[ "$release" != "$pin" ]]; then
    refuse "$manifest is the manifest of libmpv-$release, and the pin is libmpv-$pin: run scripts/update_libmpv.sh $pin"
  fi
  expected=(THIRD_PARTY_LICENSES.txt)
  if ! jq -e .web "$manifest" > /dev/null; then
    refuse "$manifest names no web module"
  else
    while read -r name sha; do
      sha="${sha%$'\r'}"
      expected+=("$name")
      if [[ ! -f "web/$name" ]]; then
        refuse "web/$name is missing: run scripts/update_libmpv.sh $pin"
      elif [[ "$(sha256 "web/$name")" != "$sha" ]]; then
        refuse "web/$name is not the file of libmpv-$release (SHA-256 $(sha256 "web/$name"), the manifest says $sha): run scripts/update_libmpv.sh $pin"
      fi
    done < <(jq -r '.web.files | to_entries[] | "\(.key) \(.value)"' "$manifest")
  fi
  if [[ ! -s web/THIRD_PARTY_LICENSES.txt ]]; then
    refuse "web/THIRD_PARTY_LICENSES.txt is missing or empty: run scripts/update_libmpv.sh $pin"
  fi
  # What web/ holds goes into the package: nothing but the module.
  while read -r path; do
    name="${path#web/}"
    [[ "$name" == .gitkeep ]] && continue
    known=false
    for e in "${expected[@]}"; do [[ "$e" == "$name" ]] && known=true; done
    $known || refuse "web/$name is not a file of the web module, and would be published"
  done < <(find web -mindepth 1 | LC_ALL=C sort)
fi

if ((refusals)); then
  echo "publish: $version is not ready, $refusals reason(s) above." >&2
  exit 1
fi

case "$mode" in
  --versions)
    echo "publish: every file says $version."
    ;;
  --check)
    echo "publish: $version is ready: clean tree, one version, no tag v$version, the web module of libmpv-$release."
    ;;
  --dry-run)
    flutter pub publish --dry-run
    ;;
  publish)
    flutter pub publish
    ;;
esac
