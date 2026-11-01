#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# Finds the libmpv-scripts Build that CI should bundle instead of the
# pinned libmpv release, and prints its run id, or nothing when the pinned
# release serves. ci.yml's changes job runs it once for every job, and
# mpv_studio's setup action runs it from its checkout of the kit.
#
# The release CI needs is the later of the pin (libmpvRelease in
# lib/src/internals/libmpv_release.dart) and the minimum the player relies
# on (libmpvMinimumRelease in lib/src/internals/libmpv_requirements.dart),
# libmpv-rN:
#   - published (on the repository the hook downloads from) and pinned:
#     nothing to do;
#   - published but past the pin: nothing either, the jobs keep the pin,
#     with a warning that the pin must move (scripts/update_libmpv.sh rN);
#   - not published: the latest successful Build (build.yml) of the
#     libmpv-scripts branch release/rN started by a push. Runs started by
#     hand, on wip branches among others, are never taken. When the latest
#     run of the branch did not succeed, or is still going, the log says so
#     and the previous successful one serves. None is an error.
# A run id given by hand (LIBMPV_SCRIPTS_RUN) is printed as it is. Without
# a token (a pull request from a fork gets no secrets) the jobs use the
# pinned release, with a warning.
#
# Everything but the run id goes to stderr, so that
#   run="$(scripts/ci/resolve_libmpv_run.sh)"
# holds the id alone.
#
# Reads from the environment:
#   LIBMPV_SCRIPTS_RUN  a run id to use as it is, empty to look one up
#   GH_TOKEN            a token with Actions read access on
#                       ales-drnz/libmpv-scripts (LIBMPV_SCRIPTS_TOKEN)
#   RELEASE_TOKEN       the token for the release lookup, GH_TOKEN by
#                       default (the workflow's own reads public releases)
#   KIT_ROOT            the mpv_audio_kit checkout, this script's by default
#
#   scripts/ci/resolve_libmpv_run.sh
set -euo pipefail

if [[ -n "${LIBMPV_SCRIPTS_RUN:-}" ]]; then
  echo "libmpv-scripts run $LIBMPV_SCRIPTS_RUN, given by hand" >&2
  echo "$LIBMPV_SCRIPTS_RUN"
  exit 0
fi

scripts_repo=ales-drnz/libmpv-scripts
root="${KIT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
release_file="$root/lib/src/internals/libmpv_release.dart"
requirements_file="$root/lib/src/internals/libmpv_requirements.dart"
hook="$root/hook/build.dart"
err="$(mktemp)"
trap 'rm -f "$err"' EXIT

# The HTTP status of the last failed gh call, or nothing for a failure
# that never reached GitHub.
http_status() { sed -n 's/.*(HTTP \([0-9]*\)).*/\1/p' "$err" | tail -n 1; }

pin="$(sed -n "s/^const String libmpvRelease = 'r\([0-9]*\)';/\1/p" "$release_file")"
minimum="$(sed -n 's/^const int libmpvMinimumRelease = \([0-9]*\);/\1/p' "$requirements_file")"
repo="$(sed -n 's#.*https://github\.com/\([^/]*/[^/]*\)/releases/download/.*#\1#p' "$hook" | head -n 1)"
if [[ -z "$pin" || -z "$minimum" || -z "$repo" ]]; then
  echo "::error::$release_file has no libmpvRelease, $requirements_file no libmpvMinimumRelease or $hook no release URL." >&2
  exit 1
fi
want=$(( pin > minimum ? pin : minimum ))
tag="libmpv-r$want"

no_token() {
  echo "::warning::No LIBMPV_SCRIPTS_TOKEN (a fork pull request gets no secrets): using the pinned libmpv release r$pin." >&2
  exit 0
}
release_token="${RELEASE_TOKEN:-${GH_TOKEN:-}}"
[[ -n "$release_token" ]] || no_token

if GH_TOKEN="$release_token" gh api "repos/$repo/releases/tags/$tag" \
  --jq .tag_name > /dev/null 2>"$err"; then
  if (( want > pin )); then
    echo "::warning::$tag is published and the pin is still r$pin: run scripts/update_libmpv.sh r$want. Until then the jobs use the pinned release r$pin." >&2
  else
    echo "The pinned libmpv release $tag is published." >&2
  fi
  exit 0
fi
if [[ "$(http_status)" != 404 ]]; then
  echo "::warning::Could not look up the libmpv release $tag on $repo: $(cat "$err")" >&2
  # The pinned release serves if it is the one wanted; the preflight
  # checks it again.
  (( want > pin )) || exit 0
fi
[[ -n "${GH_TOKEN:-}" ]] || no_token
echo "$tag is not published on $repo: looking for the Build of release/r$want." >&2

# The runs of build.yml on release/rN started by a push, newest first. The
# filter checks branch and event again in case the query ignored them.
runs="repos/$scripts_repo/actions/workflows/build.yml/runs?branch=release/r$want&event=push"
select="select(.head_branch == \"release/r$want\" and .event == \"push\")"
fields='"\(.id) \(.head_sha) \(.created_at) \(.status) \(.conclusion)"'
lookup() { # extra query
  if ! gh api "$runs$1" --jq "[.workflow_runs[] | $select][0] // empty | $fields" 2>"$err"; then
    if [[ "$(http_status)" == 401 ]]; then
      echo "::error::LIBMPV_SCRIPTS_TOKEN was refused (HTTP 401): it has most likely expired. Renew it, Actions read access on $scripts_repo only." >&2
    else
      echo "::error::Could not list the Builds of $scripts_repo release/r$want: $(cat "$err")" >&2
    fi
    exit 1
  fi
}

latest="$(lookup '&per_page=1')"
if [[ -z "$latest" ]]; then
  echo "::error::$tag is not published and $scripts_repo has no Build of release/r$want started by a push. Push release/r$want there, or give a run by hand (the libmpv_scripts_run input or the LIBMPV_SCRIPTS_RUN variable)." >&2
  exit 1
fi
read -r id sha date status conclusion <<<"$latest"
if [[ "$conclusion" != success ]]; then
  [[ "$status" == completed ]] || conclusion="$status"
  echo "The latest Build of release/r$want, run $id ($sha, $date), is $conclusion: taking the latest successful one." >&2
  latest="$(lookup '&status=success&per_page=1')"
  if [[ -z "$latest" ]]; then
    echo "::error::$scripts_repo has no successful Build of release/r$want started by a push." >&2
    exit 1
  fi
  read -r id sha date status conclusion <<<"$latest"
fi
echo "libmpv-scripts run $id: release/r$want at $sha, $date, $conclusion" >&2
echo "$id"
