#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The changes gate of ci.yml: decides whether the tests and the builds have
# anything to check, and writes code=true or code=false to $GITHUB_OUTPUT.
# They are skipped for a change to the docs alone (README, CHANGELOG,
# MIGRATION, imgs, doc, tool/diagrams) on top of a commit that passed, and
# for a commit that already passed on another branch (the same commit
# pushed to main and to a release branch runs once when the first run is
# green). When GitHub cannot be asked, they run.
#
# Reads from the environment:
#   EVENT   github.event_name
#   BASE    the commit the change is measured from (pull request base or
#           the branch head before the push); empty or zeros for none
#   SHA     the commit under test
#   RUN_ID  this workflow run
#   REPO    owner/name, for the GitHub API (through gh, with GH_TOKEN)
#
#   scripts/ci/changes_gate.sh
set -euo pipefail

# How many CI runs other than this one went green on commit $1. Only
# pushes and manual runs count: they test the commit itself, while a pull
# request run tests a merge. Fails when GitHub cannot be asked.
green_runs() {
  gh api "repos/$REPO/actions/workflows/ci.yml/runs?head_sha=$1&per_page=100" \
    --jq "[.workflow_runs[] | select(.id != $RUN_ID and .conclusion == \"success\" and (.event == \"push\" or .event == \"workflow_dispatch\"))] | length"
}

code=true
if [[ -n "$BASE" && ! "$BASE" =~ ^0+$ ]] &&
  git cat-file -e "$BASE^{commit}" 2>/dev/null; then
  code=false
  while read -r path; do
    case "$path" in
      ''|README.md|CHANGELOG.md|MIGRATION.md|imgs/*|doc/*|tool/diagrams/*) ;;
      *) code=true ;;
    esac
  done < <(git diff --name-only "$BASE" "$SHA")
  if [[ "$code" == false ]]; then
    # BASE is the last commit pushed, not the last one tested: its run may
    # have been cancelled by this push, or failed. Docs on top of it would
    # then skip its code too.
    if ! green="$(green_runs "$BASE")"; then
      echo "::warning::Could not look up the runs of $BASE: tests and builds run."
      code=true
    elif (( green == 0 )); then
      echo "::notice::Only docs changed, but $BASE has no green run: tests and builds run."
      code=true
    else
      echo "::notice::Only docs changed since $BASE, which passed: tests and builds are skipped."
    fi
  fi
fi
if [[ "$code" == true && "$EVENT" == push ]]; then
  # Only a run that went green: one still going may yet fail or be
  # cancelled, and nothing would come back to test this commit.
  if ! green="$(green_runs "$SHA")"; then
    echo "::warning::Could not look up the runs of $SHA: tests and builds run."
  elif (( green > 0 )); then
    echo "::notice::$SHA already passed on another branch: tests and builds are skipped."
    code=false
  fi
fi
echo "code=$code" >> "$GITHUB_OUTPUT"
