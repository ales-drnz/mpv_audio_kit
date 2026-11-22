#!/usr/bin/env python3
"""Stage 3 of the lavfi codegen: read `schema.json` and emit the generated
tests under `test/generated/` (paths from `[output]` in the consumer TOML).
The main one, `audio_effects_coverage_test.dart`, is an exhaustive,
schema-driven check that every parameter of every filter shows up in
`toFilterString()`, and every enum member round-trips through
`mpvValue` / `fromMpv`; beside it go the param corners, the runtime
init coverage and the `af-command` probes. The filter-name manifest
comes from the generate stage (generate.py).

Usage (from tool/codegen; tool/codegen/regen.sh does it):
    python3 -m lavfi_codegen --config mpv_audio_kit.toml tests

Idempotent. Runs `dart format` on each emitted file.

Coverage strategy:
  - Per filter:
    * `enabled: false` → drops out of `audioEffectsChain()`.
    * `enabled: true` with every param at its ffmpeg default →
      `toFilterString()` returns the bare `lavfi-NAME`.
    * Per param: set it to a known-non-default sentinel value and
      assert the param's name appears in the wire output. Sentinel
      picking favours the documented bounds (max, then min) so the
      test is closer to a realistic in-range write than a random
      pick.
  - Per enum:
    * Every member's `mpvValue` round-trips through `fromMpv`, and the
      members carry the FFmpeg names of the schema, in order.
    * `fromMpv(<unknown>)` falls back to the first member (per the
      project convention "Unknown values fall back to a safe default;
      never throw").

The coverage cases are a table, one line each, in a part of the test
(`_audio_effects_coverage_cases.dart`), and the test runs them in a loop:
every case is mechanical, no human picks. The codegen owns the assertion
shape so a regression in `generate.py` is caught here at unit-test speed.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
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
    FILE_BACKED_PARAM,
    FILTER_TONE_FIXTURE,
    PRESETS,
    REQUIRED_PARAMS,
    SAMPLE_VALUES,
)

# Per-run wire flavour; mirrors the same handle in generate.py — the
# coverage test's expected substrings must match what generate.py
# emits for `toFilterString()` / enum `<wire>Value`.
_WIRE: WireConfig = WireConfig()

# Per-run domain naming; mirrors generate.py. Defaults reproduce audio output.
_NAMING: NamingConfig = NamingConfig()

# Mirrors generate.py's emit_af_labels: when on, `audioEffectsChain()` wraps
# each typed stage in its stable `@aek_<filter>_<n>:` chain label and the bundle-level
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

# Basenames of the coverage test and of the part with its cases (set in
# run() from the output paths).
_COVERAGE_FILE: str = "audio_effects_coverage_test.dart"
_CASES_FILE: str = "_audio_effects_coverage_cases.dart"

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
    emits seconds through `_wireDuration`: 3 decimals when exact, which
    holds for the whole-second sentinel here."""
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
    cases = _CASES_FILE
    return (
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.\n"
        "// All rights reserved.\n"
        "// Use of this source code is governed by BSD 3-Clause license\n"
        "// that can be found in the LICENSE file.\n"
        "//\n"
        "// AUTO-GENERATED: do NOT edit by hand.\n"
        "//\n"
        "// Schema-driven coverage of the effects chain (`audioEffectsChain`) and the\n"
        "// per-filter `toFilterString()` wire output: every parameter of\n"
        f"// every libavfilter {_NAMING.noun} filter shipped with this build "
        "has at\n"
        "// least one test pinning the wire shape, and every typed enum\n"
        "// has its `" + getter + "` and `" + parser + "` round-trip checked exhaustively.\n"
        f"// The cases are data, in {cases}; this file runs them.\n"
        "\n"
        "import 'package:test/test.dart';\n"
        "import 'package:" + pkg + "/" + pkg + ".dart';\n"
        "import 'package:" + pkg + "/src/generated/audio_effects_settings.dart'\n"
        "    show audioEffectsChain;\n"
        "\n"
        f"part '{cases}';\n"
        "\n"
        "void main() {\n"
        "  group('Per-filter wire coverage', () {\n"
        "    for (final f in _filters) {\n"
        "      group('${f.cls} (${f.name})', () {\n"
        "        final label = '" + _chain_label("${f.name}") + _WIRE.label_prefix + "${f.name}';\n"
        "        test('disabled → drops out of the chain', () {\n"
        "          expect(audioEffectsChain([f.disabled]), '');\n"
        "        });\n"
        "\n"
        "        if (f.required.isEmpty) {\n"
        "          test('enabled with every param at default → bare lavfi name', () {\n"
        "            expect(audioEffectsChain([f.enabled]), label);\n"
        "          });\n"
        "        } else {\n"
        "          test(\n"
        "            'enabled with required params → wire carries the filter name '\n"
        "            'and required options',\n"
        "            () {\n"
        "              expect(audioEffectsChain([f.enabled]), startsWith(label));\n"
        "              for (final p in f.required) {\n"
        "                expect(audioEffectsChain([f.enabled]), contains('$p='));\n"
        "              }\n"
        "            },\n"
        "          );\n"
        "        }\n"
        "\n"
        "        for (final (param, effect, wire) in f.wire) {\n"
        "          test('param `$param` lands in wire when set to a non-default value', () {\n"
        "            expect(effect.toFilterString(), contains(wire));\n"
        "          });\n"
        "        }\n"
        "\n"
        "        for (final (param, bound, effect) in f.bounds) {\n"
        "          test('param `$param` const `$bound` is accepted by toFilterString', () {\n"
        "            expect(effect.toFilterString, returnsNormally);\n"
        "          });\n"
        "        }\n"
        "\n"
        "        for (final (param, effect, wire) in f.digits) {\n"
        "          test('digit-prefix param `$param` lands in wire via params map', () {\n"
        "            expect(effect.toFilterString(), contains(wire));\n"
        "          });\n"
        "        }\n"
        "      });\n"
        "    }\n"
        "  });\n"
        "\n"
        "  group('Per-enum round-trip coverage', () {\n"
        "    for (final e in _enums) {\n"
        "      group('${e.name} (codegen enum)', e.run);\n"
        "    }\n"
        "  });\n"
        "}\n"
    )


def _emit_cases_header() -> str:
    getter = _WIRE.value_getter
    parser = _WIRE.from_method
    return (
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.\n"
        "// All rights reserved.\n"
        "// Use of this source code is governed by BSD 3-Clause license\n"
        "// that can be found in the LICENSE file.\n"
        "//\n"
        "// AUTO-GENERATED: do NOT edit by hand.\n"
        "//\n"
        f"// The cases of {_COVERAGE_FILE}, one line each, from the schema.\n"
        "\n"
        f"part of '{_COVERAGE_FILE}';\n"
        "\n"
        "/// One filter: [disabled] drops out of the chain, [enabled] is the\n"
        "/// bare entry (with its [required] options), [wire] sets one option\n"
        "/// off its default and names the text the entry carries, [bounds] sets\n"
        "/// one option to a `Min`, `Max` or `Default` constant, and [digits]\n"
        "/// sets a digit-prefix option through `params`.\n"
        "final class _Filter {\n"
        "  const _Filter(\n"
        "    this.name,\n"
        "    this.cls,\n"
        "    this.disabled,\n"
        "    this.enabled, {\n"
        "    this.required = const [],\n"
        "    this.wire = const [],\n"
        "    this.bounds = const [],\n"
        "    this.digits = const [],\n"
        "  });\n"
        "\n"
        "  final String name;\n"
        "  final String cls;\n"
        "  final AudioEffect disabled;\n"
        "  final AudioEffect enabled;\n"
        "  final List<String> required;\n"
        "  final List<(String, AudioEffect, String)> wire;\n"
        "  final List<(String, String, AudioEffect)> bounds;\n"
        "  final List<(String, AudioEffect, String)> digits;\n"
        "}\n"
        "\n"
        "/// One enum: every member round-trips through `" + getter + "` and\n"
        "/// `" + parser + "`, the members carry [wires] in order, and an unknown\n"
        "/// or null value parses to [first].\n"
        "final class _Enum<T extends Enum> {\n"
        "  const _Enum(this.name, this.values, this.parse, this.wire, this.first, this.wires);\n"
        "\n"
        "  final String name;\n"
        "  final List<T> values;\n"
        "  final T Function(String?) parse;\n"
        "  final String Function(T) wire;\n"
        "  final T first;\n"
        "  final List<String> wires;\n"
        "\n"
        "  void run() {\n"
        f"    test('every member round-trips via {getter} / {parser}', () {{\n"
        "      for (final v in values) {\n"
        "        expect(wire(v), isNotEmpty);\n"
        "        expect(parse(wire(v)), v);\n"
        "      }\n"
        "      expect([for (final v in values) wire(v)], wires);\n"
        "    });\n"
        "\n"
        f"    test('{parser} unknown / null → first member (safe fallback)', () {{\n"
        "      expect(parse('this_will_never_match'), first);\n"
        "      expect(parse(null), first);\n"
        "    });\n"
        "  }\n"
        "}\n"
        "\n"
    )


def _bare(literal: str) -> str:
    """[literal] inside a const table: a leading `const ` is implied."""
    return literal[len("const "):] if literal.startswith("const ") else literal


def _ctor(cls: str, *args: str) -> str:
    return f"{cls}({', '.join(a for a in args if a)})"


def _required_args(filter_name: str, skip: Optional[str]) -> str:
    return _required_args_fragment_except(filter_name, skip).lstrip(", ")


def _filter_entry(filter_name: str, fdata: dict, enum_lookup: dict) -> list[str]:
    """The `_Filter` of one filter, as table lines."""
    cls = _settings_class_name(filter_name)
    # Mirror generate.py: readonly+export options aren't input
    # parameters, so they don't get a Settings field and don't get a
    # coverage case either.
    params = effect_params(fdata)
    invalid = {
        n: p
        for n, p in fdata.get("params_invalid", {}).items()
        if not p.get("readonly")
    }
    req = _required_args(filter_name, None)
    lines = [
        f"  _Filter('{filter_name}', '{cls}', "
        f"{_ctor(cls, 'enabled: false', req)}, {_ctor(cls, req)},"
    ]
    required = REQUIRED_PARAMS.get(filter_name, [])
    if required:
        lines.append(
            "    required: [" + ", ".join(f"'{p}'" for p in required) + "],"
        )

    wire: list[str] = []
    for pname, p in params.items():
        sentinel = _sentinel(p, enum_lookup)
        if sentinel is None:
            continue
        literal, wire_token = sentinel
        # The value is checked where it is known: numbers and enums.
        token = (
            f"{pname}={wire_token}"
            if p["type"] in ("double", "int", "enum")
            else f"{pname}="
        )
        effect = _ctor(
            cls,
            f"{_param_dart_name(pname)}: {_bare(literal)}",
            _required_args(filter_name, pname),
        )
        wire.append(f"      ('{pname}', {effect}, '{token}'),")

    # Const-bound smoke cases. For every numeric (double/int) param,
    # the field set to its `<name>Min`, `<name>Max` and `<name>Default`
    # consts must not trip the assert of `toFilterString()` that gates
    # the same bound: both come from `p['min']` / `p['max']`, so a
    # divergence between the two emissions surfaces here.
    bounds: list[str] = []
    for pname, p in params.items():
        if p["type"] not in ("double", "int"):
            continue
        param_dart = _param_dart_name(pname)
        for suffix, raw in (
            ("Min", p.get("min")),
            ("Max", p.get("max")),
            ("Default", p.get("default")),
        ):
            if raw is None:
                continue
            effect = _ctor(
                cls,
                f"{param_dart}: {cls}.{param_dart}{suffix}",
                _required_args(filter_name, pname),
            )
            bounds.append(
                f"      ('{pname}', '{param_dart}{suffix}', {effect}),"
            )

    # Invalid (digit-prefix) params route through the `params` Map field.
    digits: list[str] = []
    for pname, p in invalid.items():
        sentinel = _sentinel(p, enum_lookup)
        if sentinel is None:
            continue
        literal, wire_token = sentinel
        token = (
            f"{pname}={wire_token}"
            if p["type"] in ("double", "int")
            else f"{pname}="
        )
        effect = _ctor(cls, req, f"params: {{'{pname}': {_bare(literal)}}}")
        digits.append(f"      ('{pname}', {effect}, '{token}'),")

    for key, rows in (("wire", wire), ("bounds", bounds), ("digits", digits)):
        if rows:
            lines.append(f"    {key}: [")
            lines.extend(rows)
            lines.append("    ],")
    lines.append("  ),")
    return lines


def _enum_entry(enum_id: str, members: list[dict]) -> str:
    getter = _WIRE.value_getter
    parser = _WIRE.from_method
    first = _enum_member_dart_name(members[0]["name"])
    wires = ", ".join(_dart_string(m["name"]) for m in members)
    return (
        f"  _Enum<{enum_id}>('{enum_id}', {enum_id}.values, {enum_id}.{parser}, "
        f"(v) => v.{getter}, {enum_id}.{first}, [{wires}]),"
    )


def _emit_cases(filters: dict, sorted_names: list[str], enum_lookup: dict) -> tuple[str, int]:
    """The part with the case tables; returns it and the enum count."""
    out: list[str] = [_emit_cases_header()]
    # One case a line: the formatter would split most of them over
    # several, for a table five times as long.
    out.append("// dart format off")
    out.append("const _filters = <_Filter>[")
    for fname in sorted_names:
        out.extend(_filter_entry(fname, filters[fname], enum_lookup))
    out.append("];")
    out.append("")
    out.append("final _enums = <_Enum<Enum>>[")
    seen: set[str] = set()
    for fname in sorted_names:
        for enum_id, members in filters[fname]["enums"].items():
            if enum_id in seen or not members:
                continue
            seen.add(enum_id)
            out.append(_enum_entry(enum_id, members))
    out.append("];")
    out.append("// dart format on")
    return "\n".join(out) + "\n", len(seen)


def _dart_string(s: str) -> str:
    """`s` as a single-quoted Dart string literal."""
    return "'" + s.replace("\\", "\\\\").replace("'", "\\'").replace("$", "\\$") + "'"


def _emit_param_corners(
    filters: dict, sorted_names: list[str]
) -> tuple[str, int, int]:
    """Emits the runtime corner-case manifest. One `(filter, label,
    bundle)` record per (filter, numeric-param, corner ∈ {Min, Max}).
    The runtime test iterates this list and feeds each bundle to live
    mpv, capturing any AVOption-rejection errors. No Default corner:
    toFilterString omits a value equal to the default, so it would send
    the bare filter, which the runtime coverage test already opens.

    A duration param gets one corner instead, 500 us when its range holds
    it: under a millisecond, where its wire value once took an exponent.

    Skips:
      - Non-numeric params (enums / flags / bools / strings).
      - Params whose corner const isn't emitted by `generate.py` (e.g.
        params with no parsable min — the ffmpeg AVOption uses
        `INT_MAX` / `DBL_MAX` / a C symbol).

    A second list, `kFilterSamples`, holds every filter at its defaults
    (required options from SAMPLE_VALUES) and the curated PRESETS: the
    values the typed API ships, which the effects validator must accept.
    File-backed filters (arnndn) are left out, their value being a path.

    Returns (file text, n corners, n samples)."""
    pkg = _CONSUMER_PACKAGE
    pieces: list[str] = [
        "// AUTO-GENERATED: do not edit by hand.",
        "//",
        "// Per-filter param corner-case manifest. See",
        "// test/runtime/effects/audio_effects_param_ranges_test.dart",
        "// for the test that iterates this list. kFilterSamples holds every",
        "// filter at its defaults and the curated presets, which",
        "// test/unit/internals/audio_effects_validation_test.dart passes through",
        "// the effects validator with the corners.",
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
            dart_pname = _param_dart_name(pname)
            if ptype == "duration":
                lo = _try_int(p.get("min"))
                hi = _try_int(p.get("max"))
                if (lo is None or lo <= 500) and (hi is None or hi >= 500):
                    req_extra = _required_args_fragment_except(fname, pname)
                    pieces.append(
                        f"  (filter: '{fname}', label: '{pname}=500us', "
                        f"bundle: const [{cls}({dart_pname}: "
                        f"Duration(microseconds: 500){req_extra})]),"
                    )
                continue
            if ptype not in ("double", "int"):
                continue
            # Each corner uses the codegen's public const so a drift in
            # the const value is automatically reflected here.
            for suffix in ("Min", "Max"):
                # Skip when the underlying schema field is missing —
                # generate.py won't emit a `<param><suffix>` const if
                # min/max parses to None.
                if suffix == "Min" and p.get("min") is None:
                    continue
                if suffix == "Max" and p.get("max") is None:
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
    n_corners = sum(1 for p in pieces if p.startswith("  (filter: "))
    pieces.append("")
    pieces.append("const List<ParamCorner> kFilterSamples = [")
    n_samples = 0
    for fname in sorted_names:
        if fname in FILE_BACKED_PARAM:
            continue
        cls = _settings_class_name(fname)
        req_frag = _required_args_fragment(fname).lstrip(", ")
        samples = [("defaults", f"{cls}({req_frag})")]
        for preset, values in PRESETS.get(fname, []):
            args = ", ".join(
                f"{_param_dart_name(k)}: {_dart_string(v)}"
                for k, v in values.items()
            )
            samples.append((f"preset {preset}", f"{cls}({args})"))
        for label, ctor in samples:
            n_samples += 1
            pieces.append(
                f"  (filter: '{fname}', label: {_dart_string(label)}, "
                f"bundle: const [{ctor}]),"
            )
    pieces.append("];")
    return "\n".join(pieces) + "\n", n_corners, n_samples


def _emit_runtime_coverage(filters: dict, sorted_names: list[str]) -> str:
    """Runtime init-coverage test: build every whitelisted filter with
    `enabled: true` (required params filled from SAMPLE_VALUES), apply it
    to a live mpv via `setAudioEffects`, and assert no init error.

    Filters with REQUIRED params would fail to init if those options were
    left unset (mpv reports an init error) — here they're filled
    from SAMPLE_VALUES so mpv accepts them. `arnndn`'s required `model` is a
    real `.rnnn` FILE (not an inline string), so its case is built at run
    time from a committed fixture (ARNNDN_MODEL_FIXTURE, produced by
    scripts/generate_filter_fixtures.sh) and appended to the
    init loop — it stays OUT of the `const` case list only because its model
    arg is a runtime path, not a const literal. Its `model=` wire string is
    additionally asserted statically below.

    Modeled on test/runtime/effects/audio_effects_param_ranges_test.dart
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
    lines.append("// AUTO-GENERATED: do NOT edit by hand.")
    lines.append("//")
    lines.append("// Runtime init coverage. For every whitelisted audio filter, build")
    lines.append("// the typed Settings with `enabled: true` (REQUIRED params filled")
    lines.append("// from the codegen's curated SAMPLE_VALUES), apply the bundle to a")
    lines.append("// live mpv via `setAudioEffects`, and assert mpv emits NO error /")
    lines.append("// fatal log line, that is the filter actually initialises.")
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
    lines.append("  // Stereo at 48 kHz, which every whitelisted filter takes, looped and")
    lines.append("  // playing: each new chain gets audio, so each filter is configured.")
    lines.append("  final fixturePath =")
    lines.append(f"      '${{Directory.current.path}}/test/fixtures/{FILTER_TONE_FIXTURE}';")
    if has_arnndn:
        lines.append("  // arnndn's required `model` is a path to a real .rnnn FILE on disk")
        lines.append("  // (generated by scripts/generate_filter_fixtures.sh), so, unlike the")
        lines.append("  // inline-string required params, it can't live in the const case")
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
    lines.append("      final errors = await captureChainErrorsEach(player, [")
    lines.append(f"        for (final c in {iter_name}) (key: c.filter, bundle: c.bundle),")
    lines.append("      ]);")
    lines.append("      final failures = {")
    lines.append("        for (final MapEntry(:key, :value) in errors.entries)")
    lines.append("          key: value.map((e) => e.text.trim()).toList(),")
    lines.append("      };")
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


# Hand-picked af-command probes: a baseline constructor argument and the
# (option, new value) updates to send. A curated probe replaces the one
# derived from the schema for the same option. Used where no safe value can
# be derived: options that are free strings (firequalizer), and a default
# the filter cannot take live (equalizer).
_AF_COMMAND_CURATED_CASES: dict[str, dict] = {
    "firequalizer": {"baseline_args": "", "updates": [("gain", "'0'")]},
    # The default frequency is 0 Hz, which the biquad takes at creation as a
    # bypass but refuses in a command (w0 <= 0 is EINVAL), so re-arming the
    # baseline live fails: start at 1 kHz.
    "equalizer": {
        "baseline_args": ", frequency: 1000.0",
        "updates": [("frequency", "1001.0")],
    },
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


_AfCommandCase = tuple[str, str, bool, list[tuple[str, str]]]


def _af_command_cases(
    filters: dict, sorted_names: list[str]
) -> tuple[list[_AfCommandCase], list[str]]:
    """The af-command probes: per command-capable filter, its baseline
    bundle and one update per runtime-tunable option, and the filters
    left without any."""
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
        curated = _AF_COMMAND_CURATED_CASES.get(fname)
        baseline_extra = curated["baseline_args"] if curated else ""
        if curated:
            # A curated probe replaces the derived one for the same option.
            own = {_param_dart_name(n) for n, _ in curated["updates"]}
            updates = [(n, v) for n, v in updates if n not in own]
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
    return cases, uncovered


def _emit_af_command_coverage(
    filters: dict, sorted_names: list[str]
) -> tuple[str, int, int]:
    """Runtime af-command coverage test: for every filter whose schema
    carries `supports_commands` (the gate for live updates in `audioEffectsDiff`),
    enable it on a live playing mpv, then change each runtime-tunable
    option through `Player.updateAudioEffects` and assert that the diff
    sends it as `af-command` and that mpv accepts it (the player logs
    `afCommandRefusedLog` on internalLog when it does not).

    A failure means the parse-derived `supports_commands` flag (or an
    option's runtime flag) is wrong for the SHIPPED binary — fix the
    codegen and regenerate; never edit the test.

    Returns (file text, n filter cases, n option probes)."""
    pkg = _CONSUMER_PACKAGE
    has_arnndn = "arnndn" in sorted_names and bool(
        filters.get("arnndn", {}).get("supports_commands")
    )

    cases, uncovered = _af_command_cases(filters, sorted_names)

    lines: list[str] = []
    lines.append(
        "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.")
    lines.append("// All rights reserved.")
    lines.append("// Use of this source code is governed by BSD 3-Clause license")
    lines.append("// that can be found in the LICENSE file.")
    lines.append("//")
    lines.append("// AUTO-GENERATED: do NOT edit by hand.")
    lines.append("//")
    lines.append("// Runtime af-command coverage. For every filter whose ffmpeg source")
    lines.append("// declares `.process_command` (the schema's `supports_commands` flag")
    lines.append("// is the gate for live updates in `audioEffectsDiff`), enable the filter on a")
    lines.append("// live playing mpv, then change each runtime-tunable option through")
    lines.append("// `Player.updateAudioEffects`: the diff must send it as `af-command`,")
    lines.append("// and mpv must accept it, which the player logs when it does not")
    lines.append("// before rebuilding the chain. A refusal here means the flag (or an")
    lines.append("// option's runtime flag) is wrong for the SHIPPED binary: fix the")
    lines.append("// codegen and regenerate.")
    lines.append("//")
    lines.append("// Probe values stay close to each option's default: corner values can")
    lines.append("// be DYNAMICALLY invalid even when statically inside the AVOption")
    lines.append("// range (e.g. a biquad frequency above Nyquist), and a failed runtime")
    lines.append("// reconfigure poisons the filter instance: every later command on it")
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
    lines.append(f"import 'package:{pkg}/src/generated/audio_effects_settings.dart'")
    lines.append("    show audioEffectsDiff;")
    lines.append(f"import 'package:{pkg}/src/player/player.dart' show afCommandRefusedLog;")
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
    lines.append("  // every loop wrap resets the filter chain; a shorter file would")
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
    lines.append("      // mpv refuses an af-command until a rebuilt filter graph has")
    lines.append("      // seen its first frame, which comes after the audio already")
    lines.append("      // buffered past it: wait until playback has moved 0.6 s on")
    lines.append("      // without a jump back, which a loop wrap or the refresh seek of")
    lines.append("      // a rebuild makes, and which resets the graph again.")
    lines.append("      Future<double> timePos() async =>")
    lines.append("          double.tryParse(await player.getRawProperty('time-pos') ?? '') ??")
    lines.append("          0;")
    lines.append("      Future<void> flowing() async {")
    lines.append("        var start = await timePos();")
    lines.append("        var last = start;")
    lines.append("        final deadline = DateTime.now().add(const Duration(seconds: 8));")
    lines.append("        while (DateTime.now().isBefore(deadline)) {")
    lines.append("          await Future<void>.delayed(const Duration(milliseconds: 50));")
    lines.append("          final now = await timePos();")
    lines.append("          if (now < last) start = now;")
    lines.append("          last = now;")
    lines.append("          if (now >= start + 0.6) return;")
    lines.append("        }")
    lines.append("        fail('playback did not move on for 8 s');")
    lines.append("      }")
    lines.append("")
    lines.append("      // The player logs each live update mpv refuses before rebuilding")
    lines.append("      // the chain from the state.")
    lines.append("      var refusals = 0;")
    lines.append("      final logSub = player.stream.internalLog.listen((e) {")
    lines.append("        if (e.text == afCommandRefusedLog) refusals++;")
    lines.append("      });")
    lines.append("      addTearDown(logSub.cancel);")
    lines.append("      Future<bool> refusedLive(")
    lines.append("        List<AudioEffect> Function(List<AudioEffect>) apply,")
    lines.append("      ) async {")
    lines.append("        final before = refusals;")
    lines.append("        await player.updateAudioEffects(apply);")
    lines.append("        await pumpEventQueue();")
    lines.append("        return refusals != before;")
    lines.append("      }")
    lines.append("")
    lines.append("      for (final c in cases) {")
    lines.append("        // Without libmpv-scripts' chain_eof patch, mpv stalls at the end")
    lines.append("        // of a file when a chain change there drops lavfi-dynaudnorm with")
    lines.append("        // the EOF it holds: change the chain at the start.")
    lines.append("        await player.seek(Duration.zero);")
    lines.append("        await player.setAudioEffects(c.bundle);")
    lines.append("        await flowing();")
    lines.append("        final baseline = await player.getRawProperty('af');")
    lines.append(
        f"        expect(baseline, contains('@{_NAMING.chain_label_prefix}_"
        "${c.field}:'),"
    )
    lines.append("            reason: '${c.filter}: enabled stage must carry its "
                 "chain label',);")
    lines.append("        for (final u in c.updates) {")
    lines.append("          final next = u.apply(player.state.settings.audioEffects);")
    lines.append("          expect(audioEffectsDiff(player.state.settings.audioEffects, next),")
    lines.append("              allOf(isNotNull, isNotEmpty),")
    lines.append("              reason: '${c.filter} ${u.label}: not sent as a live "
                 "update',);")
    lines.append("          var refused = await refusedLive(u.apply);")
    lines.append("          for (var attempt = 1; refused && attempt < 5; "
                 "attempt++) {")
    lines.append("            // A loop wrap resets the graph as well, and the refusal "
                 "rebuilt")
    lines.append("            // the stage. Re-arm the baseline, let the audio reach "
                 "the new")
    lines.append("            // graph and retry: an unsupported command is refused "
                 "every time,")
    lines.append("            // a race is not.")
    lines.append("            await player.setAudioEffects(c.bundle);")
    lines.append("            await flowing();")
    lines.append("            refused = await refusedLive(u.apply);")
    lines.append("          }")
    lines.append("          expect(refused, isFalse,")
    lines.append("              reason: '${c.filter} ${u.label}: mpv refused the "
                 "af-command, '")
    lines.append("                  'so supports_commands (or the option runtime "
                 "flag) is wrong '")
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
    global _COVERAGE_FILE, _CASES_FILE
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
    out = config.output.test_coverage
    cases = config.output.test_coverage_cases or out.with_name(
        "_" + out.name.removesuffix("_test.dart") + "_cases.dart"
    )
    _COVERAGE_FILE = out.name
    _CASES_FILE = cases.name
    cases_text, n_enums = _emit_cases(filters, sorted_names, enum_lookup)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(_emit_header())
    cases.write_text(cases_text)
    for path in (out, cases):
        try:
            subprocess.run(
                ["dart", "format", str(path)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"WARN: `dart format` failed for {path}", file=sys.stderr)
    try:
        rel = out.relative_to(config.consumer_root)
    except ValueError:
        rel = out
    print(
        f"Wrote {rel} and {cases.name} ({len(sorted_names)} filters, {n_enums} enums)",
        file=sys.stderr,
    )

    corners = config.output.test_param_corners
    corners.parent.mkdir(parents=True, exist_ok=True)
    corners_text, corner_count, sample_count = _emit_param_corners(
        filters, sorted_names
    )
    corners.write_text(corners_text)
    try:
        subprocess.run(
            ["dart", "format", str(corners)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(f"WARN: `dart format` failed for {corners}", file=sys.stderr)
    try:
        rel = corners.relative_to(config.consumer_root)
    except ValueError:
        rel = corners
    print(
        f"Wrote {rel} ({corner_count} corners, {sample_count} samples)",
        file=sys.stderr,
    )

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
