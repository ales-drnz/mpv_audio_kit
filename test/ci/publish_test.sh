#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Tests the checks of scripts/publish.sh on a made-up package in a git
# repository of its own, with a made-up remote: a ready one passes, and
# each thing out of place is refused by name, the libmpv release asked of
# the fake gh. Then the versions of the repository itself. Nothing is
# published: only --check, --dry-run up to its checks and --versions run.
#
#   bash test/ci/publish_test.sh
set -euo pipefail
source "$(dirname "$0")/harness.sh"
script="$repo_root/scripts/publish.sh"

sha() {
  if command -v sha256sum > /dev/null; then sha256sum "$1" | cut -d' ' -f1
  else shasum -a 256 "$1" | cut -d' ' -f1; fi
}
git_q() { git -c user.name=test -c user.email=test@example.com -c commit.gpgsign=false -c tag.gpgsign=false "$@"; }

# A package at version 1.2.3 pinned to libmpv-r99, with its web module,
# committed, and a bare remote named origin.
pkg="$scratch/pkg"
mkdir -p "$pkg"/{darwin,android,web,tool/codegen,lib/src/internals,hook}
cd "$pkg"
printf 'name: kit\nversion: 1.2.3\n' > pubspec.yaml
printf "Pod::Spec.new do |s|\n  s.version          = '1.2.3'\nend\n" > darwin/mpv_audio_kit.podspec
printf 'group = "kit"\nversion = "1.2.3"\n' > android/build.gradle.kts
printf 'dependencies:\n  mpv_audio_kit: ^1.2.3\n' > README.md
printf '## [1.2.3] - 01-01-2026\n\n## [1.2.2] - 01-12-2025\n' > CHANGELOG.md
# As long as a real one: a read that stops at the first title must not
# break the pipe it reads from.
for i in $(seq 1 3000); do echo "- an entry of the past, number $i, as long as a real one"; done >> CHANGELOG.md
printf "const String libmpvRelease = 'r99';\n" > lib/src/internals/libmpv_release.dart
printf "const _base =\n    'https://github.com/owner/kit/releases/download/\$_release';\n" > hook/build.dart
files=(libmpv.mjs libmpv.wasm mak_webaudio_processor.js)
for name in "${files[@]}"; do echo "$name of r99" > "web/$name"; done
echo "the licenses" > web/THIRD_PARTY_LICENSES.txt
: > web/.gitkeep
printf '/web/libmpv.*\n/web/mak_webaudio_processor.js\n/web/THIRD_PARTY_LICENSES.txt\n' > .gitignore
manifest() { # release
  jq -n --arg release "$1" \
    --arg mjs "$(sha web/libmpv.mjs)" --arg wasm "$(sha web/libmpv.wasm)" \
    --arg js "$(sha web/mak_webaudio_processor.js)" \
    '{release: $release,
      assets: {"libmpv_linux-x86_64.so": "aa11", "libmpv_web.zip": "bb22"},
      web: {asset: "libmpv_web.zip", files:
      {"libmpv.mjs": $mjs, "libmpv.wasm": $wasm, "mak_webaudio_processor.js": $js}}}' \
    > tool/codegen/libmpv_manifest.json
}
# The release libmpv-r99 on the fake GitHub, with the assets "name:sha"
# given (no :sha, an asset without a digest).
published() {
  local spec name sha assets=()
  for spec in "$@"; do
    name="${spec%%:*}" sha="${spec#*:}"
    if [[ "$sha" == "$name" ]]; then assets+=("{\"name\":\"$name\",\"digest\":null}")
    else assets+=("{\"name\":\"$name\",\"digest\":\"sha256:$sha\"}"); fi
  done
  local IFS=,
  echo "{\"tag_name\":\"libmpv-r99\",\"assets\":[${assets[*]}]}" > "$FAKE_GH/release/libmpv-r99.json"
}
new_gh
published libmpv_linux-x86_64.so:aa11 libmpv_web.zip:bb22
manifest r99
git init -q -b main .
git_q add -A
git_q commit -q -m "1.2.3"
git init -q --bare "$scratch/remote.git"
git remote add origin "$scratch/remote.git"
git_q push -q origin main

run() { # mode: sets code and out
  code=0
  out="$(PUBLISH_ROOT="$pkg" bash "$script" "$1" 2>&1)" || code=$?
}
has() { grep -qF -- "$1" <<<"$out" && echo yes || echo no; }
# Refused with the reason, then the tree is put back.
refused() { # name, reason
  run --check
  expect_eq "$1 is refused" 1 "$code"
  expect_eq "$1: the reason" yes "$(has "$2")"
  git_q checkout -q -- . && git clean -qfd
  for name in "${files[@]}"; do echo "$name of r99" > "web/$name"; done
  echo "the licenses" > web/THIRD_PARTY_LICENSES.txt
}

run --check
expect_eq "a ready package passes" 0 "$code"
expect_eq "it says what it is" yes "$(has '1.2.3 is ready')"
run --versions
expect_eq "its versions agree" 0 "$code"

rm web/libmpv.wasm
refused "a web file missing" "web/libmpv.wasm is missing"

echo "another build" > web/libmpv.mjs
refused "a web file of another build" "web/libmpv.mjs is not the file of libmpv-r99"

rm web/THIRD_PARTY_LICENSES.txt
refused "the web licenses missing" "web/THIRD_PARTY_LICENSES.txt is missing or empty"

echo "{}" > web/build_web.json
refused "a stray file in web/" "web/build_web.json is not a file of the web module"

echo "// a change" >> lib/src/internals/libmpv_release.dart
refused "a changed file" "the git tree is not clean"

echo "notes" > notes.txt
refused "an untracked file" "the git tree is not clean"

sed -i.bak "s/'1.2.3'/'1.2.2'/" darwin/mpv_audio_kit.podspec && rm darwin/mpv_audio_kit.podspec.bak
run --versions
expect_eq "a podspec left behind fails the versions" 1 "$code"
refused "a podspec left behind" "darwin/mpv_audio_kit.podspec says '1.2.2', and pubspec.yaml 1.2.3"

sed -i.bak 's/"1.2.3"/"1.2.2"/' android/build.gradle.kts && rm android/build.gradle.kts.bak
refused "a gradle file left behind" "android/build.gradle.kts says '1.2.2'"

sed -i.bak 's/\^1.2.3/^1.2.2/' README.md && rm README.md.bak
refused "a README left behind" "The install snippet of README.md says '1.2.2'"

printf '## [1.2.2] - 01-12-2025\n' > CHANGELOG.md
refused "a CHANGELOG without the version" "The first title of CHANGELOG.md says '1.2.2'"

# The manifest of another release: committed, so the tree is clean.
manifest r98
git_q commit -q -am "manifest of r98"
run --check
expect_eq "a manifest of another release is refused" 1 "$code"
expect_eq "a manifest of another release: the reason" yes \
  "$(has 'is the manifest of libmpv-r98, and the pin is libmpv-r99')"
git_q reset -q --hard HEAD~1

git_q tag v1.2.3
refused "a tag here" "the tag v1.2.3 exists here"
git_q push -q origin v1.2.3
git_q tag -d v1.2.3 > /dev/null
refused "a tag on the remote" "the tag v1.2.3 exists on origin"
git_q push -q origin :refs/tags/v1.2.3

# The libmpv release, as GitHub has it.
rm "$FAKE_GH/release/libmpv-r99.json"
refused "a release not published" "the release libmpv-r99 is not published on owner/kit"
code=0; out="$(PUBLISH_ROOT="$pkg" bash "$script" --dry-run 2>&1)" || code=$?
expect_eq "--dry-run refuses it too" 1 "$code"
expect_eq "--dry-run: the reason" yes "$(has 'the release libmpv-r99 is not published')"
published libmpv_linux-x86_64.so:aa11
refused "a release without an asset" "the release libmpv-r99 has no libmpv_web.zip"
published libmpv_linux-x86_64.so:aa11 libmpv_web.zip:cc33
refused "an asset of another build" "libmpv_web.zip of the release libmpv-r99 is not the one of"
published libmpv_linux-x86_64.so libmpv_web.zip:bb22
refused "an asset without a digest" "(no SHA-256 there, sha256:aa11 in the manifest)"
touch "$FAKE_GH/down"
refused "GitHub out of reach" "could not ask GitHub for the release libmpv-r99"
rm "$FAKE_GH/down"
published libmpv_linux-x86_64.so:aa11 libmpv_web.zip:bb22

# The date of the first title, which --versions does not ask for.
sed -i.bak '1s/ - 01-01-2026$//' CHANGELOG.md && rm CHANGELOG.md.bak
git_q commit -q -am "no date"
run --versions
expect_eq "an undated CHANGELOG keeps its versions" 0 "$code"
run --check
expect_eq "an undated CHANGELOG is refused" 1 "$code"
expect_eq "an undated CHANGELOG: the reason" yes "$(has "The first title of CHANGELOG.md has no date ('## [1.2.3]')")"
git_q reset -q --hard HEAD~1

run --check
expect_eq "the package put back passes again" 0 "$code"

code=0; PUBLISH_ROOT="$pkg" bash "$script" --force > /dev/null 2>&1 || code=$?
expect_eq "another argument is refused" 2 "$code"

# The repository: pubspec, podspec, gradle, README and CHANGELOG agree.
cd "$repo_root"
code=0; out="$(bash "$script" --versions 2>&1)" || code=$?
expect_eq "the versions of the repository agree ($out)" 0 "$code"

finish
