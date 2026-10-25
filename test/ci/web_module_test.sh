#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests scripts/ci/web_module.sh on copies of the real hook/build.dart,
# lib/src/internals/libmpv_release.dart and scripts/web_module.py, with
# manifests and web modules made here: the pinned release's served from a
# directory, a run's as the libmpv-release artifact leaves it.
#
#   bash test/ci/web_module_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
web_module="$repo_root/scripts/ci/web_module.sh"

mkdir -p "$scratch/kit/hook" "$scratch/kit/lib/src/internals" \
  "$scratch/kit/scripts" "$scratch/kit/tool/codegen"
cd "$scratch/kit"
cp "$repo_root/hook/build.dart" hook/build.dart
cp "$repo_root/scripts/web_module.py" scripts/web_module.py
abi="$(sed -n 's/^const int webModuleAbi = \([0-9]*\);/\1/p' \
  "$repo_root/lib/src/internals/libmpv_release.dart")"
[[ -n "$abi" ]]
files=(libmpv.mjs libmpv.wasm mak_webaudio_processor.js)

# Pins the kit copy to release $1.
pin() {
  sed "s/^const String libmpvRelease = '[^']*';/const String libmpvRelease = '$1';/" \
    "$repo_root/lib/src/internals/libmpv_release.dart" \
    > lib/src/internals/libmpv_release.dart
}

# A release $2 in directory $1: libmpv_web.zip with the three files and
# build_web.json, and its manifest.json, with a web section unless $3 is
# "noweb". WEB_ABI and ZIP_SHA change what the manifest says.
release() { # dir, release, [noweb]
  local dir="$1" name
  mkdir -p "$dir/unpacked"
  for name in "${files[@]}"; do echo "$name of $2" > "$dir/unpacked/$name"; done
  echo "{\"release\": \"$2\", \"target\": \"web\"}" > "$dir/unpacked/build_web.json"
  python3 -c '
import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w") as z:
    for n in sorted(os.listdir(sys.argv[2])):
        z.write(os.path.join(sys.argv[2], n), n)
' "$dir/libmpv_web.zip" "$dir/unpacked"
  local zip_sha web=null
  zip_sha="${ZIP_SHA:-$(sha256sum "$dir/libmpv_web.zip" | cut -d' ' -f1)}"
  if [[ "${3:-}" != noweb ]]; then
    web="$(jq -n --argjson abi "${WEB_ABI:-$abi}" \
      --arg mjs "$(sha256sum "$dir/unpacked/libmpv.mjs" | cut -d' ' -f1)" \
      --arg wasm "$(sha256sum "$dir/unpacked/libmpv.wasm" | cut -d' ' -f1)" \
      --arg js "$(sha256sum "$dir/unpacked/mak_webaudio_processor.js" | cut -d' ' -f1)" \
      '{asset: "libmpv_web.zip", abi: $abi, webaudioAbi: 1, emscripten: "6.0.12",
        files: {"libmpv.mjs": $mjs, "libmpv.wasm": $wasm, "mak_webaudio_processor.js": $js}}')"
  fi
  jq -n --arg release "$2" --arg zip "$zip_sha" --argjson web "$web" \
    '{release: $release, mpv: "0.41.0", ffmpeg: "8.1.1",
      assets: {"libmpv_linux-x86_64.so": ("1" * 64), "libmpv_web.zip": $zip}}
     + (if $web == null then {} else {web: $web} end)' > "$dir/manifest.json"
}

# Pins the kit copy to release $1 with the manifest of directory $2.
pinned() { # release, dir
  pin "$1"
  cp "$2/manifest.json" tool/codegen/libmpv_manifest.json
}

# Runs the script as Test (Web) does, from the kit copy, and prints its
# exit status. Extra environment comes from the arguments (NAME=value).
run() {
  local status=0
  rm -rf test/web/module
  : > "$FAKE_GH/output"
  : > "$FAKE_GH/summary"
  env -u RUN_DIR -u CI GITHUB_OUTPUT="$FAKE_GH/output" \
    GITHUB_STEP_SUMMARY="$FAKE_GH/summary" "$@" "$web_module" \
    > "$FAKE_GH/log" 2>&1 || status=$?
  echo "$status"
}

ready() { sed -n 's/^ready=//p' "$FAKE_GH/output"; }

# Whether test/web/module holds the three files of release directory $1.
installed() {
  local name
  for name in "${files[@]}"; do
    cmp -s "$1/unpacked/$name" "test/web/module/$name" || { echo no; return; }
  done
  [[ ! -e test/web/module/build_web.json ]] || { echo no; return; }
  echo yes
}

# The pinned release.

new_gh
release "$scratch/r19" r19 noweb
pinned r19 "$scratch/r19"
expect_eq "r19 without a web module skips on CI" 0 "$(run CI=true)"
expect_eq "and tells the tests not to run" false "$(ready)"
expect_log "with a notice naming the first release" \
  "::notice::libmpv-r19 (the pinned release) has no web module, the first is libmpv-r20"
expect_eq "and a line in the job summary" 1 "$(grep -c 'did not run' "$FAKE_GH/summary")"

new_gh
release "$scratch/r20-noweb" r20 noweb
pinned r20 "$scratch/r20-noweb"
expect_eq "r20 without a web module fails on CI" 1 "$(run CI=true)"
expect_log "and says so" "::error::libmpv-r20 (the pinned release) has no web module"
expect_eq "off CI it only warns" 0 "$(run)"
expect_log "with a warning" "::warning::libmpv-r20 (the pinned release) has no web module"
expect_eq "and the tests do not run" false "$(ready)"

new_gh
release "$scratch/r20" r20
pinned r20 "$scratch/r20"
expect_eq "the pinned module installs" 0 "$(run CI=true RELEASE_URL="file://$scratch/r20")"
expect_eq "the tests run" true "$(ready)"
expect_eq "on the three files of the zip" yes "$(installed "$scratch/r20")"

# A curl that records its arguments and fails as on a 404.
mkdir -p "$scratch/bin"
cat > "$scratch/bin/curl" <<'EOF'
#!/usr/bin/env bash
echo "$*" >> "$FAKE_GH/curl"
exit 22
EOF
chmod +x "$scratch/bin/curl"

new_gh
pinned r20 "$scratch/r20"
expect_eq "a pinned module that cannot be downloaded fails on CI" 1 \
  "$(run CI=true PATH="$scratch/bin:$PATH")"
expect_eq "fetched from the hook's release" \
  "https://github.com/ales-drnz/mpv_audio_kit/releases/download/libmpv-r20/libmpv_web.zip" \
  "$(grep -o 'https://[^ ]*' "$FAKE_GH/curl")"
expect_log "and names the URL" "::error::Could not download https://github.com/.*/libmpv_web.zip"

new_gh
ZIP_SHA="$(printf '0%.0s' {1..64})" release "$scratch/r20-badzip" r20
pinned r20 "$scratch/r20-badzip"
expect_eq "a zip that is not the manifest's fails, off CI too" 1 \
  "$(run RELEASE_URL="file://$scratch/r20-badzip")"
expect_log "and says why" "::error::The web module of libmpv-r20 (the pinned release) does not match its manifest: .*of the manifest"
expect_eq "installing nothing" no "$(installed "$scratch/r20-badzip")"

new_gh
WEB_ABI=$((abi + 1)) release "$scratch/r20-abi" r20
pinned r20 "$scratch/r20-abi"
expect_eq "a module of another ABI fails" 1 "$(run CI=true RELEASE_URL="file://$scratch/r20-abi")"
expect_log "and names both" "has ABI $((abi + 1)), and the package drives ABI $abi"

new_gh
pin r20
cp "$scratch/r19/manifest.json" tool/codegen/libmpv_manifest.json
expect_eq "a manifest copy of another release than the pin fails" 1 "$(run)"
expect_log "and names the way out" "::error::.*libmpv-r19, and the pin is libmpv-r20: run scripts/update_libmpv.sh"

# A libmpv-scripts run, with the pin at r19.

new_gh
pinned r19 "$scratch/r19"
expect_eq "the run's module installs" 0 "$(run CI=true RUN_DIR="$scratch/r20" LIBMPV_SCRIPTS_RUN=4242)"
expect_eq "the tests run" true "$(ready)"
expect_eq "on the run's files" yes "$(installed "$scratch/r20")"
expect_log "and says where it came from" "libmpv-r20 from libmpv-scripts run 4242"

new_gh
expect_eq "a run of r19 skips on CI" 0 "$(run CI=true RUN_DIR="$scratch/r19" LIBMPV_SCRIPTS_RUN=4242)"
expect_log "with the notice" "::notice::libmpv-r19 (libmpv-scripts run 4242) has no web module"
expect_eq "and no tests" false "$(ready)"

new_gh
expect_eq "a run of r20 without the module fails on CI" 1 \
  "$(run CI=true RUN_DIR="$scratch/r20-noweb" LIBMPV_SCRIPTS_RUN=4242)"
expect_log "and says so" "::error::libmpv-r20 (libmpv-scripts run 4242) has no web module"

new_gh
mkdir -p "$scratch/run-nozip"
cp "$scratch/r20/manifest.json" "$scratch/run-nozip/"
expect_eq "a run whose artifact lacks the zip fails on CI" 1 \
  "$(run CI=true RUN_DIR="$scratch/run-nozip" LIBMPV_SCRIPTS_RUN=4242)"
expect_log "and names it" "::error::The libmpv-release artifact of libmpv-scripts run 4242 has no libmpv_web.zip"
expect_eq "off CI it only warns" 0 "$(run RUN_DIR="$scratch/run-nozip" LIBMPV_SCRIPTS_RUN=4242)"
expect_eq "and the tests do not run" false "$(ready)"

finish
