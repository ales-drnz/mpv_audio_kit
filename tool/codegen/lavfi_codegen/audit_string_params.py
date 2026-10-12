#!/usr/bin/env python3
# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.

"""Audit `schema.json` for filters whose parameters likely require a
hand-written typed extension on top of the auto-generated `*Effect` classes.

Run after every `parse.py` regeneration (i.e. ffmpeg version bump) to
discover NEW filters that ship structured data inside opaque AVOption
strings or digit-prefixed `Map<String, double>` slots.

Three buckets, by decreasing priority:

  Tier A (LIST GRAMMAR — hand-write the extension)
    String params whose `desc_long` mentions "list", "separated",
    "pipe", "comma", "pairs", "entries", "multiple". These are
    near-certain candidates: they pack a `List<T>` or two parallel
    CSVs into a single AVOption string. Compare to the existing
    `*BandsX` / `*TapsX` / `*VoicesX` / `*PointsX` extensions.

  Tier B (DIGIT-PREFIX → MAP)
    Filters with `params_invalid` entries — AVOptions whose names
    start with a digit (e.g. `superequalizer.[1-18]b`). Routed
    through `Map<String, double>` by the codegen; an extension can
    collapse them to `List<double>` with positional access.

  Tier C (EXPRESSION GRAMMAR — DO NOT auto-typed)
    String params containing the word "expression" in `desc_long`
    (e.g. `dynaudnorm.curve`, `pan.args`, `aeval.exprs`,
    `firequalizer.gain`). These are math expressions, not lists.
    Typing them requires a full expression parser — out of scope.
    Listed for visibility only.

Output is grouped by tier with the param's short description, so a
human can decide which candidates merit a `lib/src/types/settings/
extensions/<filter>_<plural>.dart` overlay.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from .config import Config

# Heuristic markers in `desc_long` that suggest a list-shaped grammar.
_LIST_KEYWORDS = re.compile(
    r"\b(list|separated|pipe|comma|pairs|entries|multiple|tuples|csv)\b",
    flags=re.IGNORECASE,
)

# Marker for math-expression strings (different category — Tier C).
_EXPRESSION_KEYWORDS = re.compile(
    r"\b(expression|expressions|expr|formula)\b",
    flags=re.IGNORECASE,
)

# Filter+param pairs already covered by hand-written extensions in
# `lib/src/types/settings/extensions/`. Keep this in sync with that
# directory — the audit subtracts these from the candidate report so
# the output only highlights NEW candidates after a ffmpeg upgrade.
_ALREADY_COVERED = {
    ("anequalizer", "params"),
    ("mcompand", "args"),
    ("aecho", "delays"),
    ("aecho", "decays"),
    ("chorus", "delays"),
    ("chorus", "decays"),
    ("chorus", "depths"),
    ("chorus", "speeds"),
    ("adelay", "delays"),
    ("compand", "points"),
    ("compand", "attacks"),
    ("compand", "decays"),
    ("firequalizer", "gain_entry"),
    ("afftdn", "band_noise"),
    ("afftdn", "bn"),
    ("aiir", "gains"),
    ("aiir", "k"),
    ("aiir", "poles"),
    ("aiir", "p"),
    ("aiir", "zeros"),
    ("aiir", "z"),
}

# Filters whose digit-prefix / hyphen params already have a typed
# extension on top of their `params: Map<String, ...>` slot.
_ALREADY_COVERED_DIGIT = {"superequalizer", "compand"}

# `c` / `channels` / `h` is a uniform pattern across ~12 biquad-family
# filters — a channel-selector string that's NOT a structured list, but
# also not an expression. Skip from the audit to keep noise down.
_CHANNEL_SELECTOR_NAMES = {"c", "channels", "h"}


def run(config: Config) -> int:
    schema = json.loads(config.output.schema.read_text())
    filters: dict = schema["filters"]

    tier_a: list[tuple[str, str, str]] = []
    tier_b: list[tuple[str, list[str]]] = []
    tier_c: list[tuple[str, str, str]] = []

    for fname in sorted(filters.keys()):
        fdata = filters[fname]

        # Tier B — digit-prefix routed.
        invalid = fdata.get("params_invalid") or {}
        if invalid and fname not in _ALREADY_COVERED_DIGIT:
            tier_b.append((fname, sorted(invalid.keys())))

        # Tier A / C — string params.
        for pname, p in (fdata.get("params") or {}).items():
            if p["type"] != "string":
                continue
            if pname in _CHANNEL_SELECTOR_NAMES:
                continue
            if (fname, pname) in _ALREADY_COVERED:
                continue
            desc = (p.get("desc_long") or p.get("desc") or "").strip()
            short = (p.get("desc") or desc[:80] or "").strip()
            # Order matters: expression-shaped grammars dominate even
            # when the param is "a list of expressions" (e.g.
            # `afftfilt.imag` is both pipe-separated AND a math
            # expression per entry — typing it would need a full
            # expression parser, so it's still Tier C).
            if _EXPRESSION_KEYWORDS.search(desc):
                tier_c.append((fname, pname, short))
            elif _LIST_KEYWORDS.search(desc):
                tier_a.append((fname, pname, short))
            else:
                # Neither marker found — surface in Tier A as
                # "needs human inspection" rather than dropping it.
                tier_a.append((fname, pname, short))

    if tier_a:
        print("=== Tier A — list-shaped grammar (extension candidate) ===")
        print()
        for fname, pname, desc in tier_a:
            print(f"  {fname}.{pname}")
            print(f"    {desc}")
        print()
    if tier_b:
        print("=== Tier B — digit-prefix routed (Map → List collapse) ===")
        print()
        for fname, names in tier_b:
            print(f"  {fname}: {names}")
        print()
    if tier_c:
        print("=== Tier C — expression grammar (skip — math, not list) ===")
        print()
        for fname, pname, desc in tier_c:
            print(f"  {fname}.{pname}")
            print(f"    {desc}")
        print()

    print(
        f"Summary: Tier A = {len(tier_a)}, Tier B = {len(tier_b)},"
        f" Tier C = {len(tier_c)}.",
        file=sys.stderr,
    )
    print(
        "(Tier A entries already covered by an extension are filtered"
        " out via `_ALREADY_COVERED` in this module.)",
        file=sys.stderr,
    )
    return 0
