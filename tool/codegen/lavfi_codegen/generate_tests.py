#!/usr/bin/env python3
"""Stage 3 of the lavfi codegen: read `schema.json` and emit
`test/internal/audio_effects_coverage_test.dart` — exhaustive,
schema-driven verification that every parameter of every filter
shows up in `toFilterString()`, and every enum member round-trips
through `mpvValue` / `fromMpv`.

Usage:
    scripts/lavfi_codegen/generate_tests.py

Idempotent. Runs `dart format` at the end.

Coverage strategy:
  - Per filter:
    * `enabled: false` → drops out of `toAfChain()`.
    * `enabled: true` with every param at its ffmpeg default →
      `toFilterString()` returns the bare `lavfi-NAME`.
    * Per param: set it to a known-non-default sentinel value and
      assert the param's name appears in the wire output. Sentinel
      picking favours the documented bounds (max, then min) so the
      test is closer to a realistic in-range write than a random
      pick.
  - Per enum:
    * Every member's `mpvValue` round-trips through `fromMpv`.
    * `fromMpv(<unknown>)` falls back to the first member (per the
      project convention "Unknown values fall back to a safe default;
      never throw").

This file is deliberately ~6k lines: every test is mechanical, no
human picks. The codegen owns the assertion shape so a regression in
`generate.py` is caught here at unit-test speed.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional

from .config import Config, NamingConfig, WireConfig
from .generate import (
    _enum_member_dart_name,
    _param_dart_name,
    _settings_class_name,
    effect_params,
)
from .required_params import (
    ARNNDN_MODEL_FIXTURE,
    REQUIRED_PARAMS,
    SAMPLE_VALUES,
    required_for,
)

# Per-run wire flavour; mirrors the same handle in generate.py — the
# coverage test's expected substrings must match what generate.py
# emits for `toFilterString()` / enum `<wire>Value`.
_WIRE: WireConfig = WireConfig()

# Per-run domain naming; mirrors generate.py. Defaults reproduce audio output.
_NAMING: NamingConfig = NamingConfig()

# Mirrors generate.py's emit_af_labels: when on, `toAfChain()` wraps each
# typed stage in its stable `@aek_<field>:` chain label and the bundle-level
# expectations must include it.
_LABELS: bool = False


def _chain_label(filter_name: str) -> str:
    """Label of the first `filter_name` stage in a list, as the chain
    carries it."""
    return (
        f"@{_NAMING.chain_label_prefix}_{filter_name}_0:"
        if _LABELS
        else ""
    )

_CONSUMER_PACKAGE: str = "mpv_audio_kit"

DART_RESERVED_WORDS = {
    "abstract", "as", "assert", "async", "await", "break", "case", "catch",
    "class", "const", "continue", "covariant", "default", "deferred", "do",
    "dynamic", "else", "enum", "export", "extends", "extension", "external",
    "factory", "false", "final", "finally", "for", "function", "get", "hide",
    "if", "implements", "import", "in", "interface", "is", "late", "library",
    "mixin", "new", "null", "of", "on", "operator", "part", "rethrow", "return",
    "set", "show", "static", "super", "switch", "sync", "this", "throw", "true",
    "try", "typedef", "var", "void", "while", "with", "yield",
    "bool", "double", "int", "num", "String", "List", "Map", "Set",
    "Object", "Function", "Future", "Stream", "Iterable",
}

_SPECIAL_CHAR_MAP = {">": "_to_", "+": "_plus_", "-": "_minus_"}




def _bundle_field_name(filter_name: str) -> str:
    return filter_name + "_" if filter_name in DART_RESERVED_WORDS else filter_name




def _required_args_fragment(filter_name: str) -> str:
    """Comma-prefixed `name: 'value'` fragment for every REQUIRED param of
    a filter (empty string when it has none). Reuses SAMPLE_VALUES; falls
    back to a literal placeholder (arnndn has no runtime sample). All five
    curated required params are string type."""
    return _required_args_fragment_except(filter_name, None)


def _required_args_fragment_except(filter_name: str, skip: Optional[str]) -> str:
    """Like `_required_args_fragment`, but omits the `skip` param (used when
    a test already sets that one required param to its own sentinel)."""
    req = REQUIRED_PARAMS.get(filter_name)
    if not req:
        return ""
    samples = SAMPLE_VALUES.get(filter_name, {})
    parts = [
        f"{_param_dart_name(pn)}: '{samples.get(pn, '')}'"
        for pn in req
        if pn != skip
    ]
    if not parts:
        return ""
    return ", " + ", ".join(parts)




def _normalise_double_literal(raw) -> str:
    raw = str(raw)
    m = re.match(r"^(-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)[fF]$", raw)
    if m:
        raw = m.group(1)
    if raw.endswith("."):
        return raw + "0"
    if "." in raw or "e" in raw or "E" in raw:
        return raw
    return raw + ".0"


# ── Sentinel picking ───────────────────────────────────────────────────


def _try_int(value) -> Optional[int]:
    try:
        return int(value) if value is not None else None
    except (ValueError, TypeError):
        return None


def _try_float(value) -> Optional[float]:
    """Tolerates ffmpeg's C float-literal quirks (`1.f`, `2.F`, `50.`)
    that our `parse.py` keeps verbatim in the schema for fidelity. We
    strip the suffix here so sentinel picking treats `1.f` as `1.0`."""
    if value is None:
        return None
    s = str(value).strip()
    m = re.match(r"^(-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)[fF]$", s)
    if m:
        s = m.group(1)
    if s.endswith("."):
        s += "0"
    try:
        return float(s)
    except ValueError:
        return None


def _dart_to_string_as_fixed_3(v: float) -> str:
    """Replicates Dart's `(num).toStringAsFixed(3)`. Dart uses
    round-half-away-from-zero (also called `ROUND_HALF_UP`); Python's
    default formatter rounds half-to-even, which mismatches at exact
    halves like `0.0625 → 0.063` (Dart) vs `0.062` (Python)."""
    factor = 1000.0
    if v >= 0:
        rounded = int(v * factor + 0.5)
    else:
        rounded = -int(-v * factor + 0.5)
    int_part = rounded // 1000
    frac = abs(rounded) - abs(int_part) * 1000
    sign = "-" if rounded < 0 and int_part == 0 and frac > 0 else ""
    return f"{sign}{int_part}.{frac:03d}"


def _dart_to_string_as_fixed_6(v: float) -> str:
    """Replicates Dart's `(num).toStringAsFixed(6)`, which rounds the
    double's exact binary value half away from zero."""
    from decimal import ROUND_HALF_UP, Decimal

    return str(Decimal(v).quantize(Decimal("0.000001"), rounding=ROUND_HALF_UP))


def _wire_double(v: float) -> str:
    """Mirrors `_wireDouble` in the generated Dart settings file:
    3-decimal fixed when exact, 6 decimals when not, and a precise
    representation for tiny values that would otherwise round to
    `0.000` (e.g. `1e-06` for asoftclip.threshold's minimum)."""
    fixed = _dart_to_string_as_fixed_3(v)
    if v == 0:
        return fixed
    # `fixed`'s parsed value matches `v` → 3-decimal is lossless.
    if abs(float(fixed) - v) < 1e-12:
        return fixed
    if abs(v) < 0.001:
        # Dart's `double.toString()` for tiny numbers uses exponential.
        # Mirror that so the test expectation matches the runtime wire.
        # Examples: 1e-06 → "1e-6", 1e-04 → "0.0001", 5e-7 → "5e-7".
        return _dart_double_to_string(v)
    return _dart_to_string_as_fixed_6(v)


def _dart_double_to_string(v: float) -> str:
    """Best-effort mirror of Dart's `double.toString()` for the small
    values we feed through the wire format. Dart uses the shortest
    round-trip representation; Python's `repr(float)` does the same.
    For values in [1e-6, 1e-3) Dart switches to exponential notation
    with a single-digit exponent ('1e-6' not '1e-06')."""
    if v == 0:
        return "0.0"
    # Use repr's round-trip property, then normalise to Dart's style:
    # strip leading zero from the exponent ('1e-06' → '1e-6').
    s = repr(v)
    m = re.match(r"^(-?\d+(?:\.\d+)?)e([+-])0*(\d+)$", s)
    if m:
        mant, sign, exp = m.groups()
        sign = "" if sign == "+" else "-"
        return f"{mant}e{sign}{exp}"
    return s


def _sentinel_double(p: dict) -> Optional[tuple[str, str]]:
    """Returns (literal, expected_wire_substring) for a double param."""
    default = p.get("default")
    df = _try_float(default) if default is not None else None
    pmax = _try_float(p.get("max"))
    pmin = _try_float(p.get("min"))
    # Bounds that come from DBL_MAX / FLT_MAX / -DBL_MAX (ffmpeg's
    # "unbounded" sentinels in ebur128 stat outputs and similar) are
    # not realistic sentinel values — they overflow `int(v*1000)` in
    # the wire-roundtrip calculator and would never round-trip across
    # mpv's AVOption parser anyway. Filter them out so we fall back
    # to a smaller candidate.
    def _usable(v: Optional[float]) -> bool:
        # 1e30 picks up FLT_MAX (~3.4e38) and DBL_MAX (~1.8e308); no
        # AVOption with a real bound uses values that large.
        return v is not None and abs(v) < 1e30
    candidates: list[float] = []
    if _usable(pmax):
        candidates.append(pmax)
    if _usable(pmin):
        candidates.append(pmin)
    if df is not None:
        candidates.append(df + 1.0)
    candidates.append(1.0)
    for c in candidates:
        if df is None or abs(c - df) > 1e-9:
            lit = _normalise_double_literal(c)
            wire = _wire_double(c)
            return (lit, wire)
    return None


def _sentinel_int(p: dict) -> Optional[tuple[str, str]]:
    default = p.get("default")
    di = _try_int(default) if default is not None else None
    pmax = _try_int(p.get("max"))
    pmin = _try_int(p.get("min"))
    candidates: list[int] = []
    if pmax is not None:
        candidates.append(pmax)
    if pmin is not None:
        candidates.append(pmin)
    if di is not None:
        candidates.append(di + 1)
    candidates.append(1)
    for c in candidates:
        if di is None or c != di:
            return (str(c), str(c))
    return None


def _sentinel_bool(p: dict) -> tuple[str, str]:
    default = p.get("default")
    if default in ("1", "true", 1, True):
        return ("false", "0")
    return ("true", "1")


def _sentinel_duration(p: dict) -> tuple[str, str]:
    """Duration is microseconds in the C struct. The Dart wire format
    emits seconds with 3 decimals (`(d.inMicroseconds/1e6).toStringAsFixed(3)`)."""
    default = _try_int(p.get("default")) or 0
    sentinel_us = default + 1_000_000  # +1 second; differ from default
    seconds = sentinel_us / 1e6
    return (
        f"const Duration(microseconds: {sentinel_us})",
        f"{seconds:.3f}",
    )


def _sentinel_enum(p: dict, enum_lookup: dict) -> Optional[tuple[str, str]]:
    """Pick a member that is NOT the one resolved as the field's default.

    Default resolution mirrors `generate._resolve_enum_default`:
      1. INT default → match member whose `value` equals it.
      2. SYMBOL default (e.g. `QFACTOR`) → match member whose CONST
         row carried that symbol (the `symbol` field on EnumValue).
      3. Otherwise → fall back to `members[0]` (the field is nullable
         on the lib side and the default at construction time is null).

    The sentinel is the first member *other than* the resolved default;
    if every member is the default (single-member enum), return None.
    """
    enum_id = p.get("enum_id")
    members = enum_lookup.get(enum_id or "", [])
    if not members:
        return None

    raw_default = p.get("default")
    default_member: dict = members[0]
    di = _try_int(raw_default)
    if di is not None:
        default_member = next(
            (m for m in members if m.get("value") == di),
            members[0],
        )
    elif isinstance(raw_default, str) and raw_default:
        if all(c.isalnum() or c == "_" for c in raw_default) and not raw_default[0].isdigit():
            default_member = next(
                (m for m in members if m.get("symbol") == raw_default),
                members[0],
            )

    chosen = next(
        (m for m in members if m["name"] != default_member["name"]),
        None,
    )
    if chosen is None:
        return None
    member = _enum_member_dart_name(chosen["name"])
    return (f"{enum_id}.{member}", chosen["name"])


def _sentinel_flags(p: dict, enum_lookup: dict) -> Optional[tuple[str, str]]:
    enum_id = p.get("enum_id")
    members = enum_lookup.get(enum_id or "", [])
    if not members:
        return None
    member = _enum_member_dart_name(members[0]["name"])
    return (
        f"const {{{enum_id}.{member}}}",
        members[0]["name"],
    )


def _sentinel_string(p: dict) -> tuple[str, str]:
    default = p.get("default") or ""
    if "wire_test_alt" in default:
        return ("'wire_test_xtra'", "wire_test_xtra")
    return ("'wire_test_alt'", "wire_test_alt")


def _sentinel(p: dict, enum_lookup: dict) -> Optional[tuple[str, str]]:
    """Returns (Dart literal, expected wire substring) or None when we
    cannot synthesise a non-default value for this param type."""
    ptype = p["type"]
    if ptype == "double":
        return _sentinel_double(p)
    if ptype == "int":
        return _sentinel_int(p)
    if ptype == "bool":
        return _sentinel_bool(p)
    if ptype == "duration":
        return _sentinel_duration(p)
    if ptype == "enum":
        return _sentinel_enum(p, enum_lookup)
    if ptype == "flags":
        return _sentinel_flags(p, enum_lookup)
    if ptype in ("string", "chlayout"):
        return _sentinel_string(p)
    return None


# ── Emission ───────────────────────────────────────────────────────────


def _emit_header() -> str:
    pkg = _CONSUMER_PACKAGE
    getter = _WIRE.value_getter
    parser = _WIRE.from_method
    return (
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.\n"
        "// All rights reserved.\n"
        "// Use of this source code is governed by BSD 3-Clause license\n"
        "// that can be found in the LICENSE file.\n"
        "//\n"
        "// AUTO-GENERATED — do NOT edit by hand.\n"
        "//\n"
        "// Schema-driven coverage of the effects chain (`audioEffectsChain`) and the\n"
        "// per-filter `toFilterString()` wire output: every parameter of\n"
        f"// every libavfilter {_NAMING.noun} filter shipped with this build "
        "has at\n"
        "// least one test pinning the wire shape, and every typed enum\n"
        "// has its `" + getter + "` / `" + parser + "` round-trip checked exhaustively.\n"
        "// ignore_for_file: prefer_const_constructors,"
        " prefer_const_literals_to_create_immutables,"
        " unused_local_variable, unnecessary_const,"
        " prefer_adjacent_string_concatenation,"
        " prefer_interpolation_to_compose_strings\n"
        "\n"
        "import 'package:test/test.dart';\n"
        "import 'package:" + pkg + "/" + pkg + ".dart';\n"
        "import 'package:" + pkg + "/src/generated/audio_effects_settings.dart'\n"
        "    show audioEffectsChain;\n"
        "\n"
        "void main() {\n"
    )


def _emit_filter_group(filter_name: str, fdata: dict, enum_lookup: dict) -> str:
    cls = _settings_class_name(filter_name)
    # Mirror generate.py: readonly+export options aren't input
    # parameters, so they don't get a Settings field and don't get a
    # coverage test either.
    params = effect_params(fdata)
    invalid = {
        n: p
        for n, p in fdata.get("params_invalid", {}).items()
        if not p.get("readonly")
    }
    req_frag = _required_args_fragment(filter_name)
    lines: list[str] = []
    lines.append(f"  group('{cls} ($filter_name)', () {{".replace(
        "$filter_name", filter_name))
    lines.append("    test('disabled → drops out of the chain', () {")
    lines.append(f"      const fx = [{cls}(enabled: false{req_frag})];")
    lines.append("      expect(audioEffectsChain(fx), '');")
    lines.append("    });")
    lines.append("")
    if req_frag:
        # Required-param filters ALWAYS emit their mandatory options, so an
        # enabled instance is never the bare `lavfi-NAME`. Assert the name
        # and each required option are present in the wire instead.
        lines.append(
            "    test('enabled with required params → wire carries the filter name "
            "and required options', () {")
        lines.append(
            f"      const fx = [{cls}({req_frag.lstrip(', ')})];")
        lines.append(
            "      expect(audioEffectsChain(fx), "
            f"startsWith('{_chain_label(filter_name)}{_WIRE.label_prefix}{filter_name}'));")
        for pname in REQUIRED_PARAMS.get(filter_name, []):
            lines.append(f"      expect(audioEffectsChain(fx), contains('{pname}='));")
        lines.append("    });")
    else:
        lines.append("    test('enabled with every param at default → bare lavfi name', () {")
        lines.append(f"      const fx = [{cls}()];")
        lines.append(
            "      expect(audioEffectsChain(fx), "
            f"'{_chain_label(filter_name)}{_WIRE.label_prefix}{filter_name}');")
        lines.append("    });")

    # Per-param tests.
    for pname, p in params.items():
        sentinel = _sentinel(p, enum_lookup)
        if sentinel is None:
            continue
        literal, wire_token = sentinel
        param_dart = _param_dart_name(pname)
        lines.append("")
        lines.append(
            f"    test('param `{pname}` lands in wire when set to a"
            f" non-default value', () {{"
        )
        extra = _required_args_fragment_except(filter_name, pname)
        lines.append(
            f"      final s = const {cls}(enabled: true, "
            f"{param_dart}: {literal}{extra});"
        )
        lines.append(
            f"      expect(s.toFilterString(), contains('{pname}='));"
        )
        # Best-effort value check too — for double we know toStringAsFixed(3).
        if p["type"] in ("double", "int"):
            lines.append(
                f"      expect(s.toFilterString(), contains('{pname}={wire_token}'));"
            )
        elif p["type"] == "enum":
            lines.append(
                f"      expect(s.toFilterString(), contains('{pname}={wire_token}'));"
            )
        lines.append("    });")

    # Const-bound smoke tests. For every numeric (double/int) param,
    # build the Settings with the field set to `<name>Min`, `<name>Max`,
    # and `<name>Default` consts and verify `toFilterString()` doesn't
    # trip the runtime assert that gates the same bound. Regression
    # guard against codegen drift between the `static const` emission
    # and the `assert(...)` emission — they share `p['min']` /
    # `p['max']` as input, so any future divergence would surface here
    # immediately.
    for pname, p in params.items():
        if p["type"] not in ("double", "int"):
            continue
        param_dart = _param_dart_name(pname)
        suffix_keys = [
            ("Min", p.get("min")),
            ("Max", p.get("max")),
            ("Default", p.get("default")),
        ]
        for suffix, raw in suffix_keys:
            if raw is None:
                continue
            const_ref = f"{cls}.{param_dart}{suffix}"
            extra = _required_args_fragment_except(filter_name, pname)
            lines.append("")
            lines.append(
                f"    test('param `{pname}` const `{param_dart}{suffix}`"
                f" is accepted by toFilterString', () {{"
            )
            lines.append(
                f"      final s = {cls}(enabled: true,"
                f" {param_dart}: {const_ref}{extra});"
            )
            lines.append(
                "      expect(s.toFilterString, returnsNormally);"
            )
            lines.append("    });")

    # Invalid (digit-prefix) params route through the `params` Map field.
    if invalid:
        for pname, p in invalid.items():
            sentinel = _sentinel(p, enum_lookup)
            if sentinel is None:
                continue
            literal, wire_token = sentinel
            lines.append("")
            lines.append(
                f"    test('digit-prefix param `{pname}` lands in wire via"
                f" params map', () {{"
            )
            req_extra = _required_args_fragment(filter_name)
            lines.append(
                f"      final s = const {cls}(enabled: true{req_extra}, "
                f"params: {{'{pname}': {literal}}});"
            )
            lines.append(
                f"      expect(s.toFilterString(), contains('{pname}='));"
            )
            if p["type"] in ("double", "int"):
                lines.append(
                    f"      expect(s.toFilterString(),"
                    f" contains('{pname}={wire_token}'));"
                )
            lines.append("    });")

    lines.append("  });")
    return "\n".join(lines)


def _emit_enum_group(enum_id: str, members: list[dict]) -> str:
    lines: list[str] = []
    getter = _WIRE.value_getter
    parser = _WIRE.from_method
    lines.append(f"  group('$enum_id (codegen enum)', () {{".replace(
        "$enum_id", enum_id))
    lines.append(
        f"    test('every member round-trips via {getter} / {parser}', () {{"
    )
    lines.append(f"      for (final v in {enum_id}.values) {{")
    lines.append(f"        expect(v.{getter}, isNotEmpty);")
    lines.append(f"        expect({enum_id}.{parser}(v.{getter}), v);")
    lines.append("      }")
    lines.append("    });")
    lines.append("")
    lines.append(
        f"    test('{parser} unknown / null → first member (safe fallback)', () {{"
    )
    first_member = _enum_member_dart_name(members[0]["name"])
    lines.append(
        f"      expect({enum_id}.{parser}('this_will_never_match'), "
        f"{enum_id}.{first_member});"
    )
    lines.append(
        f"      expect({enum_id}.{parser}(null), {enum_id}.{first_member});"
    )
    lines.append("    });")
    lines.append("  });")
    return "\n".join(lines)


def _emit_param_corners(filters: dict, sorted_names: list[str]) -> str:
    """Emits the runtime corner-case manifest. One `(filter, label,
    bundle)` record per (filter, numeric-param, corner ∈ {Min, Default,
    Max}). The runtime test iterates this list and feeds each bundle
    to live mpv, capturing any AVOption-rejection errors.

    Skips:
      - Non-numeric params (enums / flags / bools / strings / durations).
      - Params whose corner const isn't emitted by `generate.py` (e.g.
        params with no parsable min — the ffmpeg AVOption uses
        `INT_MAX` / `DBL_MAX` / a C symbol).
    """
    pkg = _CONSUMER_PACKAGE
    pieces: list[str] = [
        "// AUTO-GENERATED — do not edit by hand.",
        "//",
        "// Per-filter param corner-case manifest. See",
        "// test/runtime_extended/audio_effects_param_ranges_test.dart",
        "// for the test that iterates this list.",
        "",
        "// ignore_for_file: lines_longer_than_80_chars,"
        " unnecessary_const, prefer_const_constructors,"
        " prefer_const_literals_to_create_immutables",
        "",
        f"import 'package:{pkg}/{pkg}.dart';",
        "",
        "typedef ParamCorner = ({String filter, String label, "
        "List<AudioEffect> bundle});",
        "",
        "const List<ParamCorner> kFilterParamCorners = [",
    ]
    for fname in sorted_names:
        # Same readonly filter as _emit_filter_group / generate.py —
        # readonly params aren't settable so their bounds aren't
        # corner-testable.
        params = effect_params(filters[fname])
        if not params:
            continue
        cls = _settings_class_name(fname)
        for pname, p in params.items():
            ptype = p.get("type")
            if ptype not in ("double", "int"):
                continue
            dart_pname = _param_dart_name(pname)
            # Each corner uses the codegen's public const so a drift in
            # the const value is automatically reflected here.
            for suffix in ("Min", "Default", "Max"):
                # Skip when the underlying schema field is missing —
                # generate.py won't emit a `<param><suffix>` const if
                # min/max parses to None.
                if suffix == "Min" and p.get("min") is None:
                    continue
                if suffix == "Max" and p.get("max") is None:
                    continue
                if suffix == "Default" and p.get("default") is None:
                    continue
                const_name = f"{cls}.{dart_pname}{suffix}"
                req_extra = _required_args_fragment_except(fname, pname)
                bundle_expr = f"[{cls}({dart_pname}: {const_name}{req_extra})]"
                label = f"{pname}={dart_pname}{suffix}"
                pieces.append(
                    f"  (filter: '{fname}', label: '{label}', "
                    f"bundle: const {bundle_expr}),"
                )
    pieces.append("];")
    return "\n".join(pieces) + "\n"


def _emit_runtime_coverage(filters: dict, sorted_names: list[str]) -> str:
    """Runtime init-coverage test: build every whitelisted filter with
    `enabled: true` (required params filled from SAMPLE_VALUES), apply it
    to a live mpv via `setAudioEffects`, and assert no init error.

    Filters with REQUIRED params would fail to init if those options were
    left unset (the bug this codegen change fixes) — here they're filled
    from SAMPLE_VALUES so mpv accepts them. `arnndn`'s required `model` is a
    real `.rnnn` FILE (not an inline string), so its case is built at run
    time from a committed fixture (ARNNDN_MODEL_FIXTURE, produced by
    mpv_kit/scripts/generate_filter_fixtures.sh) and appended to the
    init loop — it stays OUT of the `const` case list only because its model
    arg is a runtime path, not a const literal. Its `model=` wire string is
    additionally asserted statically below.

    Modeled on test/runtime_extended/audio_effects_param_ranges_test.dart
    (same libmpv_resolver + mpv_error_capture plumbing + setUpAll Player)."""
    pkg = _CONSUMER_PACKAGE
    lp = _WIRE.label_prefix
    has_arnndn = "arnndn" in sorted_names

    # (name, bundle_expr) for every filter we init at runtime from a const
    # bundle. arnndn is handled separately (runtime model path → non-const).
    runtime_cases: list[tuple[str, str]] = []
    for fname in sorted_names:
        if fname == "arnndn":
            continue  # runtime model path — appended to the loop below.
        cls = _settings_class_name(fname)
        req_frag = _required_args_fragment(fname)
        bundle = f"[{cls}({req_frag.lstrip(', ')})]"
        runtime_cases.append((fname, bundle))

    lines: list[str] = []
    lines.append(
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.")
    lines.append("// All rights reserved.")
    lines.append("// Use of this source code is governed by BSD 3-Clause license")
    lines.append("// that can be found in the LICENSE file.")
    lines.append("//")
    lines.append("// AUTO-GENERATED — do NOT edit by hand.")
    lines.append("//")
    lines.append("// Runtime init coverage. For every whitelisted audio filter, build")
    lines.append("// the typed Settings with `enabled: true` (REQUIRED params filled")
    lines.append("// from the codegen's curated SAMPLE_VALUES), apply the bundle to a")
    lines.append("// live mpv via `setAudioEffects`, and assert mpv emits NO error /")
    lines.append("// fatal log line — i.e. the filter actually initialises.")
    lines.append("//")
    lines.append("// This is the companion to the wire-shape coverage test: it catches")
    lines.append("// filters that are wire-valid but fail at mpv init time because a")
    lines.append("// MANDATORY ffmpeg option was left unset (e.g. `chorus()` with no")
    lines.append("// delays/decays/speeds/depths → AVERROR(EINVAL)).")
    lines.append("")
    lines.append("@TestOn('mac-os || linux || windows')")
    lines.append("library;")
    lines.append("")
    lines.append("// ignore_for_file: prefer_const_constructors,"
                 " prefer_const_literals_to_create_immutables,"
                 " lines_longer_than_80_chars, unnecessary_const")
    lines.append("")
    lines.append("import 'dart:io';")
    lines.append("")
    lines.append(f"import 'package:{pkg}/{pkg}.dart';")
    lines.append("import 'package:test/test.dart';")
    lines.append("")
    lines.append("import '../_helpers/mpv_error_capture.dart';")
    lines.append("import '../_helpers/setter_test_helpers.dart';")
    lines.append("")
    lines.append("typedef RuntimeCase = ({String filter, List<AudioEffect> bundle});")
    lines.append("")
    lines.append("const List<RuntimeCase> _kRuntimeCases = [")
    for fname, bundle in runtime_cases:
        lines.append(f"  (filter: '{fname}', bundle: const {bundle}),")
    lines.append("];")
    lines.append("")
    lines.append("void main() {")
    lines.append("  final fixturePath =")
    lines.append("      '${Directory.current.path}/test/fixtures/sine_440hz_1s.wav';")
    if has_arnndn:
        lines.append("  // arnndn's required `model` is a path to a real .rnnn FILE on disk")
        lines.append("  // (generated by scripts/generate_filter_fixtures.sh), so — unlike the")
        lines.append("  // inline-string required params — it can't live in the const case")
        lines.append("  // list; it's resolved here and appended to the init loop.")
        lines.append("  final arnndnModelPath =")
        lines.append(f"      '${{Directory.current.path}}/test/fixtures/{ARNNDN_MODEL_FIXTURE}';")
    lines.append("")
    lines.append("  late Player player;")
    lines.append("")
    # runtimeSuite (test/_helpers/setter_test_helpers.dart) skips the whole
    # suite at declaration time when a fixture is missing, and initializes
    # the kit against the bundled libmpv otherwise.
    extra = ", extraFixtures: [arnndnModelPath]" if has_arnndn else ""
    lines.append(f"  runtimeSuite(fixturePath: fixturePath{extra}, () {{")
    lines.append("  setUpAll(() async {")
    lines.append("    player = Player(")
    lines.append("      configuration: const PlayerConfiguration(")
    lines.append("        logLevel: LogLevel.error,")
    lines.append("      ),")
    lines.append("    );")
    lines.append("    await player.setRawProperty('ao', 'null');")
    lines.append("    await player.open(Media(fixturePath), play: false);")
    lines.append("    await player.stream.seekCompleted.first")
    lines.append("        .timeout(const Duration(seconds: 10));")
    lines.append("  });")
    lines.append("")
    lines.append("  tearDownAll(() async {")
    lines.append("    await player.dispose();")
    lines.append("  });")
    lines.append("")
    lines.append("  test(")
    lines.append("    'every whitelisted filter initialises in mpv with required params filled',")
    lines.append("    () async {")
    if has_arnndn:
        arnndn_cls = _settings_class_name("arnndn")
        arnndn_model_arg = _param_dart_name("model")
        lines.append("      // arnndn is appended here (not in the const list) because its")
        lines.append("      // model arg is a runtime-resolved fixture path.")
        lines.append("      final cases = <RuntimeCase>[")
        lines.append("        ..._kRuntimeCases,")
        lines.append("        (")
        lines.append("          filter: 'arnndn',")
        lines.append(
            f"          bundle: [{arnndn_cls}({arnndn_model_arg}: arnndnModelPath)],"
        )
        lines.append("        ),")
        lines.append("      ];")
        iter_name = "cases"
    else:
        iter_name = "_kRuntimeCases"
    lines.append("      final failures = <String, List<String>>{};")
    lines.append(f"      for (final c in {iter_name}) {{")
    lines.append("        final errors = await captureMpvErrors(player, () async {")
    lines.append("          await player.setAudioEffects(c.bundle);")
    lines.append("        });")
    lines.append("        if (errors.isNotEmpty) {")
    lines.append("          failures[c.filter] = errors.map((e) => e.text.trim()).toList();")
    lines.append("        }")
    lines.append("        // Reset between iterations so a failure doesn't bleed forward.")
    lines.append("        await player.setAudioEffects(const []);")
    lines.append("      }")
    lines.append("")
    lines.append("      if (failures.isNotEmpty) {")
    lines.append("        final buf = StringBuffer()")
    lines.append("          ..writeln(")
    lines.append(f"              '${{failures.length}} of ${{{iter_name}.length}} filters "
                 "produced mpv init errors:')")
    lines.append("          ..writeln();")
    lines.append("        final keys = failures.keys.toList()..sort();")
    lines.append("        for (final key in keys) {")
    lines.append("          buf.writeln('  - $key:');")
    lines.append("          for (final msg in failures[key]!) {")
    lines.append("            buf.writeln('      $msg');")
    lines.append("          }")
    lines.append("        }")
    lines.append("        fail(buf.toString());")
    lines.append("      }")
    lines.append("    },")
    lines.append("    timeout: const Timeout(Duration(minutes: 8)),")
    lines.append("  );")
    lines.append("")
    # Static assertions for required-param filters. These never touch mpv,
    # so they run even when libmpv is absent — and they pin the codegen
    # contract: each required param IS required (compile-enforced by the
    # `required this.x` ctor arg, exercised here) and ALWAYS lands in the
    # wire string. `arnndn` is also init-tested at runtime (above), but is
    # asserted here too so its contract holds even with no libmpv present.
    lines.append("  group('required-param filters always emit their mandatory options', () {")
    for fname in sorted_names:
        req = REQUIRED_PARAMS.get(fname)
        if not req:
            continue
        cls = _settings_class_name(fname)
        req_frag = _required_args_fragment(fname)
        note = " (also init-tested at runtime)" if fname == "arnndn" else ""
        lines.append(f"    test('{fname} wire string contains every required option"
                     f"{note}', () {{")
        lines.append(f"      const s = {cls}({req_frag.lstrip(', ')});")
        lines.append("      final wire = s.toFilterString();")
        for pname in req:
            lines.append(f"      expect(wire, contains('{pname}='),")
            lines.append(f"          reason: '{fname}.{pname} is mandatory and must "
                         "always be in the wire string');")
        lines.append(f"      expect(wire, startsWith('{lp}{fname}'));")
        lines.append("    });")
    lines.append("  });")
    lines.append("  });")
    lines.append("}")
    return "\n".join(lines) + "\n"


# Filters whose ONLY runtime-tunable options are free strings: no generic
# safe alternate value can be derived from the schema, so each carries a
# hand-probed (baseline ctor arg, option, new value) triple — verified
# rc=0 against the shipped binary (2026-06-11).
_AF_COMMAND_STRING_CASES: dict[str, dict] = {
    "adelay": {"baseline_args": ", delays: '100'", "updates": [("delays", "'400'")]},
    "firequalizer": {"baseline_args": "", "updates": [("gain", "'0'")]},
}




def _af_command_probe_literal(p: dict) -> Optional[str]:
    """Dart literal for a SAFE near-default alternate value of a
    runtime-tunable numeric/bool param, or None when no such value can be
    derived (enum / duration / string / degenerate range).

    The value stays close to the default on purpose: corner values can be
    DYNAMICALLY invalid even when statically inside the AVOption range
    (e.g. a biquad frequency above Nyquist), and a failed runtime
    reconfigure poisons the filter instance — every later command on it
    fails too, which would read as a bogus "unsupported command"."""
    t = p.get("type")
    if t == "bool":
        return "true" if str(p.get("default")) in ("0", "false", "False") else "false"
    if t not in ("int", "double"):
        return None
    try:
        mn = float(p["min"])
        mx = float(p["max"])
        df = float(p["default"])
    except (KeyError, TypeError, ValueError):
        return None
    if t == "int":
        if mx >= df + 1:
            return str(int(df) + 1)
        if mn <= df - 1:
            return str(int(df) - 1)
        return None
    if mx > df:
        v = df + min(1.0, (mx - df) / 2)
    elif mn < df:
        v = df - min(1.0, (df - mn) / 2)
    else:
        return None
    lit = "%g" % v
    if float(lit) == df:  # rounding collapsed the delta — keep full precision
        lit = repr(v)
        if float(lit) == df:
            return None
    if "." not in lit and "e" not in lit and "E" not in lit:
        lit += ".0"  # Dart double literal
    return lit


def _emit_af_command_coverage(
    filters: dict, sorted_names: list[str]
) -> tuple[str, int, int]:
    """Runtime af-command coverage test: for every filter whose schema
    carries `supports_commands` (the gate for live updates in `audioEffectsDiff`),
    enable it on a live playing mpv, then change each runtime-tunable
    option through `Player.updateAudioEffects` and assert the `af`
    property string did NOT change — i.e. the update was applied in place
    via `af-command` (rc=0) instead of falling back to a full rewrite.

    A failure means the parse-derived `supports_commands` flag (or an
    option's runtime flag) is wrong for the SHIPPED binary — fix the
    codegen and regenerate; never edit the test.

    Returns (file text, n filter cases, n option probes)."""
    pkg = _CONSUMER_PACKAGE
    has_arnndn = "arnndn" in sorted_names and bool(
        filters.get("arnndn", {}).get("supports_commands")
    )

    # (filter, baseline bundle expr, const?, [(dart param, literal)])
    cases: list[tuple[str, str, bool, list[tuple[str, str]]]] = []
    uncovered: list[str] = []
    for fname in sorted_names:
        f = filters[fname]
        if not f.get("supports_commands"):
            continue
        params = f.get("params") or {}
        updates: list[tuple[str, str]] = []
        for pname, p in params.items():
            if not p.get("runtime") or p.get("readonly"):
                continue
            lit = _af_command_probe_literal(p)
            if lit is None:
                continue
            updates.append((_param_dart_name(pname), lit))
        curated = _AF_COMMAND_STRING_CASES.get(fname)
        baseline_extra = curated["baseline_args"] if curated else ""
        if curated:
            updates.extend(
                (_param_dart_name(n), v) for n, v in curated["updates"]
            )
        if not updates:
            uncovered.append(fname)
            continue
        cls = _settings_class_name(fname)
        if fname == "arnndn":
            bundle = f"[{cls}(model: arnndnModelPath)]"
            cases.append((fname, bundle, False, updates))
        else:
            req_frag = _required_args_fragment(fname)
            args = f"{req_frag}{baseline_extra}".lstrip(", ")
            bundle = f"[{cls}({args})]"
            cases.append((fname, bundle, True, updates))

    lines: list[str] = []
    lines.append(
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.")
    lines.append("// All rights reserved.")
    lines.append("// Use of this source code is governed by BSD 3-Clause license")
    lines.append("// that can be found in the LICENSE file.")
    lines.append("//")
    lines.append("// AUTO-GENERATED — do NOT edit by hand.")
    lines.append("//")
    lines.append("// Runtime af-command coverage. For every filter whose ffmpeg source")
    lines.append("// declares `.process_command` (the schema's `supports_commands` flag")
    lines.append("// — the gate for live updates in `audioEffectsDiff`), enable the filter on a")
    lines.append("// live playing mpv, then change each runtime-tunable option through")
    lines.append("// `Player.updateAudioEffects` and assert the `af` property string did")
    lines.append("// NOT change: the update was applied to the live graph in place via")
    lines.append("// `af-command` instead of a full chain rewrite. A rewrite here means")
    lines.append("// the flag (or an option's runtime flag) is wrong for the SHIPPED")
    lines.append("// binary — fix the codegen and regenerate.")
    lines.append("//")
    lines.append("// Probe values stay close to each option's default: corner values can")
    lines.append("// be DYNAMICALLY invalid even when statically inside the AVOption")
    lines.append("// range (e.g. a biquad frequency above Nyquist), and a failed runtime")
    lines.append("// reconfigure poisons the filter instance — every later command on it")
    lines.append("// fails too, which would read here as a bogus unsupported command.")
    lines.append("//")
    lines.append("// Enum, duration and free-string options have no schema-derivable safe")
    lines.append("// alternate value and are skipped (string-only filters carry curated")
    lines.append("// hand-probed values instead). Command-capable filters with NO")
    if uncovered:
        lines.append(f"// runtime-tunable options ({', '.join(uncovered)}) can never")
    else:
        lines.append("// runtime-tunable options (none in this schema) can never")
    lines.append("// receive a diff command, so there is nothing to validate for them.")
    lines.append("")
    lines.append("@TestOn('mac-os || linux || windows')")
    lines.append("library;")
    lines.append("")
    lines.append("// ignore_for_file: prefer_const_constructors,"
                 " prefer_const_literals_to_create_immutables,"
                 " lines_longer_than_80_chars, unnecessary_const")
    lines.append("")
    lines.append("import 'dart:io';")
    lines.append("")
    lines.append(f"import 'package:{pkg}/{pkg}.dart';")
    lines.append("import 'package:test/test.dart';")
    lines.append("")
    lines.append("import '../_helpers/setter_test_helpers.dart';")
    lines.append("")
    lines.append("typedef AfCommandUpdate = ({")
    lines.append("  String label,")
    lines.append("  List<AudioEffect> Function(List<AudioEffect>) apply,")
    lines.append("});")
    lines.append("")
    lines.append("typedef AfCommandCase = ({")
    lines.append("  String filter,")
    lines.append("  String field,")
    lines.append("  List<AudioEffect> bundle,")
    lines.append("  List<AfCommandUpdate> updates,")
    lines.append("});")
    lines.append("")
    lines.append("void main() {")
    lines.append("  // The LONG fixture on purpose: the file loops for the whole run and")
    lines.append("  // every loop wrap resets the filter chain — a shorter file would")
    lines.append("  // multiply the command-vs-chain-reset races the retry below absorbs.")
    lines.append("  final fixturePath =")
    lines.append("      '${Directory.current.path}/test/fixtures/sine_5s.flac';")
    if has_arnndn:
        lines.append("  final arnndnModelPath =")
        lines.append(f"      '${{Directory.current.path}}/test/fixtures/{ARNNDN_MODEL_FIXTURE}';")
    lines.append("")
    lines.append("  late Player player;")
    lines.append("")
    # runtimeSuite (test/_helpers/setter_test_helpers.dart) skips the whole
    # suite at declaration time when a fixture is missing, and initializes
    # the kit against the bundled libmpv otherwise.
    extra = ", extraFixtures: [arnndnModelPath]" if has_arnndn else ""
    lines.append(f"  runtimeSuite(fixturePath: fixturePath{extra}, () {{")
    lines.append("  setUpAll(() async {")
    lines.append("    player = Player(")
    lines.append("      configuration: const PlayerConfiguration(")
    lines.append("        logLevel: LogLevel.error,")
    lines.append("      ),")
    lines.append("    );")
    lines.append("    await player.setRawProperty('ao', 'null');")
    lines.append("    // af-command needs a LIVE filter graph as its target: keep the")
    lines.append("    // (silent) fixture playing on a loop for the whole run.")
    lines.append("    await player.setLoop(Loop.file);")
    lines.append("    await player.open(Media(fixturePath), play: true);")
    lines.append("    await player.stream.seekCompleted.first")
    lines.append("        .timeout(const Duration(seconds: 10));")
    lines.append("  });")
    lines.append("")
    lines.append("  tearDownAll(() async {")
    lines.append("    await player.dispose();")
    lines.append("  });")
    lines.append("")
    lines.append("  test(")
    lines.append("    'every supports_commands filter applies af-command on its runtime options',")
    lines.append("    () async {")
    lines.append("      final cases = <AfCommandCase>[")
    n_updates = 0
    for fname, bundle, is_const, updates in cases:
        cls = _settings_class_name(fname)
        lines.append("        (")
        lines.append(f"          filter: '{fname}',")
        lines.append(f"          field: '{fname}_0',")
        lines.append(f"          bundle: {'const ' if is_const else ''}{bundle},")
        lines.append("          updates: <AfCommandUpdate>[")
        for dart_pname, lit in updates:
            n_updates += 1
            label = f"{dart_pname}={lit}".replace("'", "")
            lines.append("            (")
            lines.append(f"              label: '{label}',")
            lines.append(
                f"              apply: (e) => [(e.single as {cls})"
                f".copyWith({dart_pname}: {lit})],"
            )
            lines.append("            ),")
        lines.append("          ],")
        lines.append("        ),")
    lines.append("      ];")
    lines.append("")
    lines.append("      for (final c in cases) {")
    lines.append("        await player.setAudioEffects(c.bundle);")
    lines.append("        var baseline = await player.getRawProperty('af');")
    lines.append(
        f"        expect(baseline, contains('@{_NAMING.chain_label_prefix}_"
        "${c.field}:'),"
    )
    lines.append("            reason: '${c.filter}: enabled stage must carry its "
                 "chain label',);")
    lines.append("        for (final u in c.updates) {")
    lines.append("          await player.updateAudioEffects(u.apply);")
    lines.append("          var after = await player.getRawProperty('af');")
    lines.append("          if (after != baseline) {")
    lines.append("            // An af-command can lose the race against a chain "
                 "(re)build —")
    lines.append("            // right after the baseline rewrite or on a loop wrap "
                 "— and the")
    lines.append("            // player then falls back to a rewrite BY DESIGN. "
                 "Re-arm the")
    lines.append("            // baseline values, give the graph a moment, and retry "
                 "once:")
    lines.append("            // only a SECOND rewrite is a real unsupported-command "
                 "signal.")
    lines.append("            await player.setAudioEffects(c.bundle);")
    lines.append("            await Future<void>.delayed("
                 "const Duration(milliseconds: 250));")
    lines.append("            baseline = await player.getRawProperty('af');")
    lines.append("            await player.updateAudioEffects(u.apply);")
    lines.append("            after = await player.getRawProperty('af');")
    lines.append("          }")
    lines.append("          expect(after, baseline,")
    lines.append("              reason: '${c.filter} ${u.label}: the af string was "
                 "rewritten — '")
    lines.append("                  'the runtime update did not go through af-command, "
                 "so '")
    lines.append("                  'supports_commands (or the option runtime flag) is "
                 "wrong '")
    lines.append("                  'for the shipped binary',);")
    lines.append("        }")
    lines.append("      }")
    lines.append("")
    lines.append("      // Leave a clean chain behind for whatever runs next.")
    lines.append("      await player.setAudioEffects(const []);")
    lines.append("    },")
    lines.append("    timeout: const Timeout(Duration(minutes: 4)),")
    lines.append("  );")
    lines.append("  });")
    lines.append("}")
    return "\n".join(lines) + "\n", len(cases), n_updates


def run(config: Config) -> int:
    """Read the schema produced by parse.run() and emit the schema-
    driven coverage test and the runtime param-corner manifest."""
    if config.output.test_coverage is None or config.output.test_param_corners is None:
        # features.emit_tests true requires both paths.
        sys.exit(
            "codegen.toml: features.emit_tests = true requires "
            "[output].test_coverage AND [output].test_param_corners"
        )
    global _WIRE, _CONSUMER_PACKAGE, _LABELS, _NAMING
    _WIRE = config.wire
    _CONSUMER_PACKAGE = config.consumer.name
    _LABELS = config.features.emit_af_labels
    _NAMING = config.naming

    schema = json.loads(config.output.schema.read_text())
    filters: dict = schema["filters"]
    sorted_names = sorted(filters.keys())
    enum_lookup: dict[str, list[dict]] = {}
    for fname in sorted_names:
        for enum_id, members in filters[fname]["enums"].items():
            enum_lookup[enum_id] = members
    pieces: list[str] = [_emit_header()]

    pieces.append("  group('Per-filter wire coverage', () {")
    for fname in sorted_names:
        pieces.append(_emit_filter_group(fname, filters[fname], enum_lookup))
    pieces.append("  });")

    pieces.append("")
    pieces.append("  group('Per-enum round-trip coverage', () {")
    seen: set[str] = set()
    for fname in sorted_names:
        for enum_id, members in filters[fname]["enums"].items():
            if enum_id in seen or not members:
                continue
            seen.add(enum_id)
            pieces.append(_emit_enum_group(enum_id, members))
    pieces.append("  });")

    pieces.append("}")
    out = config.output.test_coverage
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text("\n".join(pieces) + "\n")
    try:
        subprocess.run(
            ["dart", "format", str(out)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(f"WARN: `dart format` failed for {out}", file=sys.stderr)
    try:
        rel = out.relative_to(config.consumer_root)
    except ValueError:
        rel = out
    print(
        f"Wrote {rel} ({len(sorted_names)} filters, {len(seen)} enums)",
        file=sys.stderr,
    )

    corners = config.output.test_param_corners
    corners.parent.mkdir(parents=True, exist_ok=True)
    corners.write_text(_emit_param_corners(filters, sorted_names))
    try:
        subprocess.run(
            ["dart", "format", str(corners)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(f"WARN: `dart format` failed for {corners}", file=sys.stderr)
    corner_count = sum(
        1
        for line in corners.read_text().splitlines()
        if line.lstrip().startswith("filter:")
    )
    try:
        rel = corners.relative_to(config.consumer_root)
    except ValueError:
        rel = corners
    print(f"Wrote {rel} ({corner_count} corners)", file=sys.stderr)

    # Runtime init-coverage test (optional output). Emitted alongside the
    # wire-coverage test so the `tests` stage produces it as part of `all`.
    runtime = config.output.test_runtime
    if runtime is not None:
        runtime.parent.mkdir(parents=True, exist_ok=True)
        runtime.write_text(_emit_runtime_coverage(filters, sorted_names))
        try:
            subprocess.run(
                ["dart", "format", str(runtime)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"WARN: `dart format` failed for {runtime}", file=sys.stderr)
        try:
            rel = runtime.relative_to(config.consumer_root)
        except ValueError:
            rel = runtime
        n_runtime = len(sorted_names)
        print(
            f"Wrote {rel} ({n_runtime} runtime init cases)", file=sys.stderr
        )

    # af-command coverage test (optional output). Only meaningful when the
    # consumer emits the diff path it validates.
    af_cmd = config.output.test_af_command
    if af_cmd is not None and config.features.emit_diff_commands:
        af_cmd.parent.mkdir(parents=True, exist_ok=True)
        text, n_cases, n_probes = _emit_af_command_coverage(
            filters, sorted_names
        )
        af_cmd.write_text(text)
        try:
            subprocess.run(
                ["dart", "format", str(af_cmd)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"WARN: `dart format` failed for {af_cmd}", file=sys.stderr)
        try:
            rel = af_cmd.relative_to(config.consumer_root)
        except ValueError:
            rel = af_cmd
        print(
            f"Wrote {rel} ({n_cases} af-command filters, "
            f"{n_probes} option probes)",
            file=sys.stderr,
        )
    return 0
