#!/usr/bin/env bash
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.
#
# The changes gate of ci.yml: decides whether the tests and the builds have
# anything to check, and writes code=true or code=false to $GITHUB_OUTPUT.
# They are skipped for a change to the docs alone (README, CHANGELOG,
# MIGRATION, imgs, doc, tool/diagrams), and for a commit already run on
# another branch (the same commit pushed to main and to a release branch
# runs once).
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
    echo "::notice::Only docs changed: tests and builds are skipped."
  fi
fi
if [[ "$code" == true && "$EVENT" == push ]]; then
  # A run of this commit that is still going or went green.
  earlier=$(gh api "repos/$REPO/actions/workflows/ci.yml/runs?head_sha=$SHA&event=push&per_page=50" \
    --jq "[.workflow_runs[] | select(.id < $RUN_ID and (.conclusion == null or .conclusion == \"success\"))] | length")
  if (( earlier > 0 )); then
    echo "::notice::$SHA already runs (or passed) on another branch: tests and builds are skipped."
    code=false
  fi
fi
echo "code=$code" >> "$GITHUB_OUTPUT"
