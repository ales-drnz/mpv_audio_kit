#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The web module of ci.yml's Test (Web) job: installs into test/web/module,
# where the browser tests load it from, the web build of the libmpv the
# other jobs bundle. With LIBMPV_SCRIPTS_RUN set, that is the run's
# libmpv_web.zip, from the libmpv-release artifact
# .github/actions/libmpv-from-run downloads (RUN_DIR) and checked against
# the run's manifest. Otherwise it is the pinned release's, downloaded and
# checked against the manifest copy in tool/codegen. scripts/web_module.py
# checks the SHA-256 of the zip and of each file, and the ABI.
#
# libmpv-r20 is the first release with a web module. On a libmpv before it
# the web tests do not run, with a notice: the pin is r19 until
# scripts/update_libmpv.sh moves it, and test/packaging/web_module_test
# fails on a pinned manifest without the module from r20 on. From r20 on a
# module that cannot be had fails the job with CI=true, as a missing libmpv
# fails the runtime suites; off CI it only warns. A module that does not
# match its manifest always fails.
#
# Writes ready=true to GITHUB_OUTPUT once the module is in place, and
# ready=false when the tests are not to run.
#
# Reads from the environment:
#   RUN_DIR             the run's libmpv-release, empty for the pinned release
#   LIBMPV_SCRIPTS_RUN  the run's id, for the messages
#   CI                  "true" on CI
#   MANIFEST            the pinned manifest, tool/codegen/libmpv_manifest.json
#                       by default
#   RELEASE_FILE        the pin, lib/src/internals/libmpv_release.dart by
#                       default
#   HOOK                the build hook, hook/build.dart by default, whose
#                       release URL the pinned module is downloaded from
#   RELEASE_URL         that URL instead, without the file name
#   DEST                test/web/module by default
#
#   scripts/ci/web_module.sh
set -euo pipefail

first_web_release=20
manifest_pin="${MANIFEST:-tool/codegen/libmpv_manifest.json}"
release_file="${RELEASE_FILE:-lib/src/internals/libmpv_release.dart}"
hook="${HOOK:-hook/build.dart}"
dest="${DEST:-test/web/module}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

output() { if [[ -n "${GITHUB_OUTPUT:-}" ]]; then echo "$1" >> "$GITHUB_OUTPUT"; fi; }
summary() { if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then echo "$1" >> "$GITHUB_STEP_SUMMARY"; fi; }

# A module that cannot be had: a failure on CI, a warning elsewhere.
missing() {
  if [[ "${CI:-}" == true ]]; then
    echo "::error::$1"
    exit 1
  fi
  echo "::warning::$1 The web tests do not run."
  output ready=false
  exit 0
}

if [[ -n "${RUN_DIR:-}" ]]; then
  manifest="$RUN_DIR/manifest.json"
  from="libmpv-scripts run ${LIBMPV_SCRIPTS_RUN:-}"
else
  manifest="$manifest_pin"
  pin="$(sed -n "s/^const String libmpvRelease = '\([^']*\)';/\1/p" "$release_file")"
  if [[ "$(jq -r .release "$manifest")" != "$pin" ]]; then
    echo "::error::$manifest is the manifest of libmpv-$(jq -r .release "$manifest"), and the pin is libmpv-$pin: run scripts/update_libmpv.sh."
    exit 1
  fi
  from="the pinned release"
fi
release="$(jq -r .release "$manifest")"

if ! jq -e .web "$manifest" > /dev/null; then
  number="${release#r}"
  if [[ "$number" =~ ^[0-9]+$ ]] && (( number < first_web_release )); then
    echo "::notice::libmpv-$release ($from) has no web module, the first is libmpv-r$first_web_release: the web tests do not run."
    summary "The web tests did not run: libmpv-$release ($from) has no web module, the first is libmpv-r$first_web_release."
    output ready=false
    exit 0
  fi
  missing "libmpv-$release ($from) has no web module: its manifest names no \"web\"."
fi
asset="$(jq -r .web.asset "$manifest")"

if [[ -n "${RUN_DIR:-}" ]]; then
  zip="$RUN_DIR/$asset"
  [[ -f "$zip" ]] || missing "The libmpv-release artifact of $from has no $asset."
else
  zip="$work/$asset"
  repo="$(sed -n 's#.*https://github\.com/\([^/]*/[^/]*\)/releases/download/.*#\1#p' "$hook" | head -n 1)"
  url="${RELEASE_URL:-https://github.com/$repo/releases/download/libmpv-$release}/$asset"
  curl -fsSL --retry 3 -o "$zip" "$url" || missing "Could not download $url."
fi

if ! log="$(python3 scripts/web_module.py "$manifest" "$zip" "$dest" 2>&1)"; then
  echo "::error::The web module of libmpv-$release ($from) does not match its manifest: $log"
  exit 1
fi
echo "$log"
echo "Web module of libmpv-$release from $from, ABI $(jq -r .web.abi "$manifest")."
output ready=true
