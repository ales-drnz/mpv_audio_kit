#!/usr/bin/env python3
"""Stage 1 of the lavfi codegen: walk ffmpeg's libavfilter C sources and
optional `doc/filters.texi`, emit a single `schema.json` describing every
audio filter on the build whitelist (params, enum types, doc strings).

Usage (from tool/codegen; tool/codegen/regen.sh does it):
    python3 -m lavfi_codegen --config mpv_audio_kit.toml parse

Reads the FFmpeg tree fetch_ffmpeg_src.sh unpacks in
`.ffmpeg-src/ffmpeg-<version>/` (the version in libmpv_manifest.json).
Output is `[output].schema` (`.build/<consumer>/schema.json`, a build
product git ignores).

Schema shape:
    {
      "ffmpeg_version": "8.1.1",
      "filters": {
        "<filter>": {
          "source_file": "af_xxx.c",
          "description": "...long text from filters.texi if available...",
          "params": {
            "<name>": {
              "type": "double|int|bool|string|duration|chlayout|enum|flags",
              "default": <literal-or-null>,
              "min": <num-or-null>,
              "max": <num-or-null>,
              "desc": "...short from C source...",
              "desc_long": "...long from texi if available...",
              "enum_id": "<enum-name>"  // only for enum/flags
            },
            ...
          },
          "params_invalid": { "<digit-prefixed-name>": { ... } },
          "enums": {
            "<enum-name>": [
              {"name": "<member>", "value": <int>, "desc": "..."},
              ...
            ]
          }
        }
      }
    }

Naming: enum names are `<FilterPascal><UnitPascal>` so two filters that
both ship a `mode` unit (e.g. acompressor, aemphasis) keep distinct
types.
"""
from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from .config import Config, resolve_whitelist
from .required_params import apply_effective_ranges

# AVOption types we know how to emit. Anything else → param skipped.
#
# AV_OPT_TYPE_UINT landed in FFmpeg 7.1 (uses .i64 default like INT).
# AV_OPT_TYPE_SAMPLE_FMT / AV_OPT_TYPE_IMAGE_SIZE / AV_OPT_TYPE_VIDEO_RATE
# are wire-as-string opaque values (aformat, anequalizer.size, etc.).
# AV_OPT_TYPE_FLAG_ARRAY is NOT a type — it's a bit (`1 << 16`) OR-ed
# onto a base type to mark an array; handled separately in
# _parse_option_type below.
AV_OPT_DART_TYPE = {
    "AV_OPT_TYPE_DOUBLE": "double",
    "AV_OPT_TYPE_FLOAT": "double",
    "AV_OPT_TYPE_INT": "int",
    "AV_OPT_TYPE_INT64": "int",
    "AV_OPT_TYPE_UINT": "int",
    "AV_OPT_TYPE_BOOL": "bool",
    "AV_OPT_TYPE_STRING": "string",
    "AV_OPT_TYPE_DURATION": "duration",
    "AV_OPT_TYPE_CHLAYOUT": "chlayout",
    "AV_OPT_TYPE_FLAGS": "flags",
    "AV_OPT_TYPE_SAMPLE_FMT": "string",
    "AV_OPT_TYPE_IMAGE_SIZE": "string",
    "AV_OPT_TYPE_VIDEO_RATE": "string",
}

# Bit flag (FFmpeg 8) OR-ed onto the base AV_OPT_TYPE to mark the
# option as an array of base-type values, separator-joined per the
# AVOptionArrayDef.sep byte (defaults to ',' but every audio user in
# 8.1.1 sets '|'). The codegen emits the field as a plain `string`
# whose value is the joined wire form — that is exactly what mpv /
# avfilter_init_str() consume, and it avoids a Dart-side List API
# whose default value would have to encode the separator anyway.
AV_OPT_TYPE_FLAG_ARRAY = "AV_OPT_TYPE_FLAG_ARRAY"


@dataclass
class Param:
    name: str
    description: str
    av_type: str
    dart_type: str  # "double" | "int" | "bool" | "string" | "duration" |
                    # "chlayout" | "enum" | "flags"
    default: Optional[str]
    min_value: Optional[str]
    max_value: Optional[str]
    unit: Optional[str] = None  # AVOption .unit -> binds to an enum group
    is_array: bool = False      # AV_OPT_TYPE_FLAG_ARRAY OR-ed on type
    array_sep: Optional[str] = None  # AVOptionArrayDef.sep (printable char)
    # AVOption .flags bits surfaced via _parse_flag_bits. The codegen
    # uses these to add Dart-side `@Deprecated`, mark runtime-tunable
    # params, and call out export/readonly outputs (e.g. ebur128 stats).
    readonly: bool = False
    runtime: bool = False
    deprecated: bool = False
    export: bool = False


@dataclass
class EnumValue:
    name: str    # ffmpeg CONST name, exact (e.g. "50fm", "downward")
    value: Optional[int]  # int when the C source uses an integer literal,
                          # None when it references a C symbol like
                          # `RubberBandOptionTransientsCrisp`. Not on the
                          # wire — mpv uses the NAME — kept only for
                          # schema inspectability.
    desc: str    # the AVOption description (3rd field of the CONST entry)
    symbol: Optional[str] = None
    # The C symbol that appears as `{.i64=SYMBOL}` when the value isn't a
    # plain integer literal (e.g. `QFACTOR`, `DI`, `KHERTZ`). Used by
    # generate.py to resolve a *param's* default that references the same
    # symbol back to this CONST's option name — without it those params
    # would be nullable.


@dataclass
class Filter:
    name: str  # e.g. "aecho"
    source_file: str
    description: str = ""        # filled later from filters.texi
    # Whether the filter's source defines `.process_command` — required
    # for runtime parameter changes via mpv's `af-command` (the
    # AV_OPT_FLAG_RUNTIME_PARAM flag on an option is NOT sufficient on
    # its own). Detected per source FILE: macro-stamped families
    # (af_biquads.c) share one definition across every filter in the
    # file, so file-level attribution is the correct granularity.
    supports_commands: bool = False
    params: list[Param] = field(default_factory=list)
    # CONST entries collected from this filter's options array, keyed by
    # the unit name they belong to. Multiple INT/FLAGS params can target
    # the same unit, but typically there is exactly one per unit.
    consts: dict[str, list[EnumValue]] = field(default_factory=dict)


# ── C-source parsing ───────────────────────────────────────────────────


def _split_top_level(text: str, sep: str = ",") -> list[str]:
    """Split [text] on [sep] at depth-0 only, where depth is tracked
    across nested `()`/`{}`/`[]` AND across quoted strings.

    The string-quoting check matters for AVOption rows whose help
    text legitimately contains the separator (e.g. silenceremove's
    `"write"` const carries the description
    `"full timestamps rewrite, keep only the start time"` — the
    embedded comma would otherwise split the row in two and drop
    everything after it, including the type field and the .unit
    binding)."""
    out: list[str] = []
    buf: list[str] = []
    depth = 0
    in_string = False
    escape = False
    for ch in text:
        if in_string:
            buf.append(ch)
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
            buf.append(ch)
            continue
        if ch in "({[":
            depth += 1
            buf.append(ch)
        elif ch in ")}]":
            depth -= 1
            buf.append(ch)
        elif ch == sep and depth == 0:
            out.append("".join(buf).strip())
            buf = []
        else:
            buf.append(ch)
    tail = "".join(buf).strip()
    if tail:
        out.append(tail)
    return out


def _split_entries(block: str) -> list[str]:
    entries: list[str] = []
    depth = 0
    start = -1
    for i, ch in enumerate(block):
        if ch == "{":
            if depth == 0:
                start = i + 1
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0 and start >= 0:
                entries.append(block[start:i])
                start = -1
    return entries


def _parse_default(token: str) -> Optional[str]:
    """Extract the literal default from a `{.kind=value}` brace block.

    Numeric and string literals flow through unchanged. C symbols
    (e.g. `QFACTOR`, `DI`, `INT_MAX`) are passed through too — the
    schema records them verbatim, and generate.py uses them to
    resolve symbol-based enum defaults via the matching CONST entry's
    `.symbol` field. Compound numeric expressions like `NB_WTYPE-1`
    are still rejected because they're never the canonical CONST
    symbol.

    String literals (`{.str="0/1|2"}`) are passed through as-is
    INCLUDING separators — `compand.points` ("-70/-70|-60/-20|1/0")
    and `anequalizer.colors` ("red|green|blue|…") rely on this. The
    compound-expression rejection only applies to non-quoted values.
    """
    if not token:
        return None
    m = re.match(r"\{\s*\.(\w+)\s*=\s*(.+?)\s*\}", token, re.DOTALL)
    if not m:
        return None
    val = m.group(2).strip()
    # Quoted strings are always preserved verbatim — their separators
    # are part of the value, not a math expression.
    if val.startswith('"') and val.endswith('"'):
        return val
    # `{.str = NULL}` (and `{.str = 0}`) in C means "no default" — at
    # the wire level, FFmpeg omits the param if unset. Surface as an
    # empty-string literal so the Dart field stays non-nullable and
    # toFilterString() can compare against `''` to suppress emission.
    # This matches the existing API contract — hand-written
    # extensions on string fields (chorus, mcompand, etc.) consume
    # `String`, not `String?`.
    if val in ("NULL", "0") and m.group(1) == "str":
        return '""'
    # Reject compound C expressions (`A+1`, `NB_FOO-1`, etc) that can't
    # be matched as canonical CONST symbols. Plain identifiers and
    # numeric / string literals stay.
    if re.search(r"[+\-*/]", val) and not re.match(
        r"^-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?[fF]?$", val
    ):
        return None
    return val


def _parse_minmax(token: str) -> Optional[str]:
    token = token.strip()
    if not token:
        return None
    # Strip optional `f` / `F` C-float suffix (e.g. `0.5f`, `.01f`).
    m = re.match(
        r"^(-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)[fF]$",
        token,
    )
    if m:
        token = m.group(1)
    # Accept both `1.5` and `.5` (leading-dot floats are legal C and
    # appear all over libavfilter — `.01`, `.99`, etc.).
    nm = re.match(r"^(-?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?)$", token)
    if nm:
        v = nm.group(1)
        return v + "0" if v.endswith(".") else v
    return None


# Canonical numeric values for the C limit macros that appear as
# AVOption .min / .max in libavfilter. These are the same values
# the compiler resolves at build time on every platform we ship
# (LP64 + LLP64); pinning them lets the codegen surface a real
# bound on the Dart side rather than dropping the constraint.
_C_NUMERIC_CONSTANTS: dict[str, str] = {
    # Integers
    "INT_MAX":   "2147483647",
    "INT_MIN":   "-2147483648",
    "INT32_MAX": "2147483647",
    "INT32_MIN": "-2147483648",
    "INT64_MAX": "9223372036854775807",
    "INT64_MIN": "-9223372036854775808",
    "UINT_MAX":  "4294967295",
    "UINT32_MAX":"4294967295",
    "I64_MAX":   "9223372036854775807",
    "I64_MIN":   "-9223372036854775808",
    # IEEE-754 doubles + floats. We represent ±DBL_MAX literally for
    # bound display; generate.py turns them into double.infinity / -
    # double.infinity at emission so Dart consumers can compare against
    # finite values without conversion.
    "DBL_MAX":     "1.7976931348623157e+308",
    "DBL_MIN":     "2.2250738585072014e-308",
    "DBL_EPSILON": "2.220446049250313e-16",
    "FLT_MAX":     "3.4028234663852886e+38",
    "FLT_MIN":     "1.1754943508222875e-38",
    "FLT_EPSILON": "1.1920928955078125e-7",
    "M_PI":        "3.141592653589793",
    "M_E":         "2.718281828459045",
}

# File-local `#define NAME numeric_literal` table. Populated by
# _index_local_macros for every .c file we touch so per-file constants
# (YAE_ATEMPO_MIN, MAX_STAGES, NB_WTYPES…) can be substituted into
# min/max bounds.
_LOCAL_NUMERIC_DEFINES: dict[str, str] = {}

# File-local short-name flag macros: every audio filter source uses
# `FLAGS = A|F` / ebur128 uses `A|F|X|R` / afir uses `AF`/`AFR`. The
# single- or short-letter macros are expanded here so _parse_flag_bits
# can see the AV_OPT_FLAG_* tokens regardless of how the row was
# spelled. Indexed per .c file.
_LOCAL_FLAG_MACROS: dict[str, set[str]] = {}

# AVOptionArrayDef table. Populated by _index_array_defs at the start
# of each .c file scan so an option that references `&array_def` can
# look up the inline default string and `sep` byte.
_ARRAY_DEFS: dict[str, dict] = {}

# Header-defined function-like macros indexed once at module load.
# Populated by main() before any .c file is processed; .c-file-local
# macros override entries with the same name during per-file parsing.
_HEADER_MACROS: dict[str, tuple[list[str], str]] = {}


def _resolve_symbol(token: Optional[str]) -> Optional[str]:
    """Map a C identifier or unary-negated identifier to its numeric
    value via the canonical limit-macro table or the per-file #define
    index. Returns `None` if the token doesn't resolve — the schema
    field becomes `null` so generate.py emits a nullable Dart field
    (better than a spurious bound that doesn't exist at runtime)."""
    if token is None:
        return None
    t = str(token).strip()
    if not t:
        return None
    # Already numeric? Trust the caller's parsing.
    parsed = _parse_minmax(t)
    if parsed is not None:
        return parsed
    sign = ""
    body = t
    if body.startswith("-"):
        sign = "-"
        body = body[1:].strip()
    # Simple arithmetic on a known identifier: `NB_WTYPE-1`,
    # `MAX_STAGES+1`. Used by biquad-family options. Only `+` and
    # `-` with a single integer literal RHS are evaluated; complex
    # expressions still bail.
    arith = re.match(
        r"^([A-Za-z_][A-Za-z0-9_]*)\s*([+\-])\s*(\d+)\s*$",
        body,
    )
    if arith:
        ident, op, n = arith.group(1), arith.group(2), int(arith.group(3))
        base = _C_NUMERIC_CONSTANTS.get(ident) or _LOCAL_NUMERIC_DEFINES.get(ident)
        if base is None:
            return None
        try:
            base_int = int(base)
        except ValueError:
            return None
        result = base_int + n if op == "+" else base_int - n
        if sign:
            result = -result
        return str(result)
    if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", body):
        return None  # compound expression — bound stays null
    if body in _C_NUMERIC_CONSTANTS:
        v = _C_NUMERIC_CONSTANTS[body]
    elif body in _LOCAL_NUMERIC_DEFINES:
        v = _LOCAL_NUMERIC_DEFINES[body]
    else:
        return None
    # Apply leading minus. For `-INT_MIN` that's outside the int32
    # range; FFmpeg uses `-INT_MAX` for "no lower bound" instead, so
    # the only realistic negated values are `INT_MAX`, `DBL_MAX`,
    # `FLT_MAX`, etc., which negate cleanly.
    if sign:
        if v.startswith("-"):
            return v[1:]
        return "-" + v
    return v


_NUMERIC_DEFINE_RE = re.compile(
    r"^\s*#\s*define\s+(?P<name>[A-Za-z_][A-Za-z0-9_]*)\s+"
    r"\(?\s*(?P<value>-?\s*(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][-+]?\d+)?[fFlLuU]*)"
    r"\s*\)?\s*(?://.*|/\*.*)?$",
    re.MULTILINE,
)


# C enum body extractor — matches `enum [NAME] { A, B = 5, NB_X, };`.
# The NAME is optional (anonymous enums are common). Body comments
# are stripped before splitting on `,`.
_ENUM_DEF_RE = re.compile(
    r"\benum\s+(?:[A-Za-z_][A-Za-z0-9_]*\s+)?\{(?P<body>[^{}]*)\}",
    re.DOTALL,
)


def _index_enum_members(source: str) -> None:
    """Add every C enum member's integer value to `_LOCAL_NUMERIC_DEFINES`.

    Sequential by default (A=0, B=1, …), restartable by an explicit
    `= N` assignment (NUM literal only — `= OTHER_ENUM` is rejected).
    This unlocks the biquad family's `NB_WTYPE-1` / `NB_TTYPE-1` bounds
    so width-type and transform-type params get proper min/max.
    Must run AFTER `_index_local_macros` so per-file `#define`s win
    over enum-member values with the same name.
    """
    # Strip C-style comments inside enum bodies so commas inside
    # comments don't fool _split_top_level.
    src = re.sub(r"/\*.*?\*/", "", source, flags=re.DOTALL)
    src = re.sub(r"//[^\n]*", "", src)
    for m in _ENUM_DEF_RE.finditer(src):
        body = m.group("body")
        cursor = 0
        for raw in _split_top_level(body):
            entry = raw.strip()
            if not entry:
                continue
            eq = entry.split("=", 1)
            name = eq[0].strip()
            if not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name):
                continue
            if len(eq) == 2:
                val_tok = eq[1].strip()
                try:
                    cursor = int(val_tok, 0)
                except ValueError:
                    # Non-numeric initialiser → enum cursor unknown
                    # for any subsequent members of this enum.
                    cursor += 1
                    continue
            # `.setdefault` so file-local `#define A 5` wins over an
            # accidental enum collision.
            _LOCAL_NUMERIC_DEFINES.setdefault(name, str(cursor))
            cursor += 1


def _index_local_macros(source: str) -> None:
    """Refresh `_LOCAL_NUMERIC_DEFINES` with every plain `#define NAME
    numeric_literal` in [source]. Compound expressions (`(1<<8)`, math)
    are ignored — those are rarely used as bounds. Idempotent: each
    file replaces the entire table, so leaks between files are
    impossible."""
    _LOCAL_NUMERIC_DEFINES.clear()
    for m in _NUMERIC_DEFINE_RE.finditer(source):
        raw = m.group("value").replace(" ", "")
        # Strip C numeric suffixes (f, F, l, L, u, U).
        raw = re.sub(r"[fFlLuU]+$", "", raw)
        # Canonicalise leading-dot floats so `_parse_minmax` accepts
        # the substituted value later.
        if raw.endswith("."):
            raw = raw + "0"
        _LOCAL_NUMERIC_DEFINES[m.group("name")] = raw


_FLAG_MACRO_DEFINE_RE = re.compile(
    r"^\s*#\s*define\s+(?P<name>[A-Z][A-Z0-9_]*)\s+"
    r"(?P<body>(?:AV_OPT_FLAG_[A-Z_]+|[A-Z][A-Z0-9_]*|[|\s])+)\s*$",
    re.MULTILINE,
)


def _index_local_flag_macros(source: str) -> None:
    """Refresh `_LOCAL_FLAG_MACROS` with every `#define NAME EXPR`
    whose RHS is a bitwise-OR of `AV_OPT_FLAG_*` tokens (possibly
    indirected through other short-name flag macros, e.g.
    `#define AFR  AF|AV_OPT_FLAG_RUNTIME_PARAM`).

    Resolves transitively in a single pass — each value is the
    flattened set of `AV_OPT_FLAG_*` tokens reachable from NAME. The
    set is consulted by `_parse_flag_bits` when the AVOption row's
    flags field is a single short-name macro instead of a literal
    `AV_OPT_FLAG_*` expression."""
    _LOCAL_FLAG_MACROS.clear()
    raw_defs: dict[str, list[str]] = {}
    for m in _FLAG_MACRO_DEFINE_RE.finditer(source):
        name = m.group("name")
        # Skip if name already maps to anything that isn't a flag (e.g.
        # `#define A 5` numeric collision — we'd have caught it via
        # _index_local_macros).
        if name in _LOCAL_NUMERIC_DEFINES:
            continue
        tokens = [
            t.strip() for t in m.group("body").split("|") if t.strip()
        ]
        # Require at least one AV_OPT_FLAG_* token directly visible —
        # avoids gobbling unrelated single-letter macros.
        if not any(t.startswith("AV_OPT_FLAG_") for t in tokens):
            # Still try via recursion: if any token is a short macro
            # already known, we can flatten it later.
            if not any(t in raw_defs for t in tokens):
                continue
        raw_defs[name] = tokens

    def resolve(name: str, seen: set[str]) -> set[str]:
        if name in seen:
            return set()
        seen = seen | {name}
        out: set[str] = set()
        for tok in raw_defs.get(name, []):
            if tok.startswith("AV_OPT_FLAG_"):
                out.add(tok)
            elif tok in raw_defs:
                out |= resolve(tok, seen)
        return out

    for name in raw_defs:
        _LOCAL_FLAG_MACROS[name] = resolve(name, set())


# AVOptionArrayDef matcher — captures `.def = "..."` and `.sep = '|'`
# (or `.sep = COMMA`-style symbolic). The C source canonically writes
# the literal one of those two ways. Anything else (rare) we skip.
_ARRAY_DEF_RE = re.compile(
    r"\bAVOptionArrayDef\s+(?P<name>\w+)\s*=\s*\{(?P<body>[^}]*)\}",
)


def _index_array_defs(source: str) -> None:
    """Refresh `_ARRAY_DEFS` with every `AVOptionArrayDef X = { … }` in
    [source]. The `.def` string and `.sep` byte are extracted; other
    fields (size_min/size_max) are ignored — Dart consumers don't
    care about minimum array length."""
    _ARRAY_DEFS.clear()
    for m in _ARRAY_DEF_RE.finditer(source):
        name = m.group("name")
        body = m.group("body")
        defn: dict = {}
        dm = re.search(r"\.def\s*=\s*\"((?:[^\"\\]|\\.)*)\"", body)
        if dm:
            defn["def"] = dm.group(1)
        sm = re.search(r"\.sep\s*=\s*'((?:[^'\\]|\\.))'", body)
        if sm:
            defn["sep"] = sm.group(1).encode().decode("unicode_escape")
        _ARRAY_DEFS[name] = defn


def _parse_unit(fields: list[str]) -> Optional[str]:
    """Look for `.unit = "X"` in any field after position 4."""
    for f in fields[4:]:
        m = re.match(r'^\s*\.\s*unit\s*=\s*"([^"]+)"\s*$', f.strip())
        if m:
            return m.group(1)
    return None


# Bit-flag macros that may appear in an AVOption `.flags` expression.
# We surface a small subset that affects how the codegen renders the
# Dart field (deprecated → `@Deprecated`, runtime → live-update doc,
# export+readonly → output stat, not a setter).
_FLAG_BITS = (
    ("AV_OPT_FLAG_DEPRECATED", "deprecated"),
    ("AV_OPT_FLAG_RUNTIME_PARAM", "runtime"),
    ("AV_OPT_FLAG_READONLY", "readonly"),
    ("AV_OPT_FLAG_EXPORT", "export"),
)


def _parse_flag_bits(fields: list[str]) -> dict[str, bool]:
    """Return {bit_name: True} for every AV_OPT_FLAG_* we recognise in
    the row's flag expression.

    The flags field may be either positional (typical libavfilter
    audio sources: `…, A|F|X|R },`) or named (`.flags = AFR`). Short
    single-letter macros (`A`, `F`, `X`, `R`, `T`, `AF`, `AFR`, …)
    are expanded via `_LOCAL_FLAG_MACROS` to recover the full
    AV_OPT_FLAG_* token set.

    Bits we don't recognise (FILTERING/AUDIO/VIDEO/BSF/encoder/…) are
    ignored — only the four we care about (deprecated/runtime/
    readonly/export) feed the codegen.
    """
    out: dict[str, bool] = {}
    # Collect every plausible flag expression in the row:
    # - `.flags = X` named form;
    # - any positional field whose tokens include `AV_OPT_FLAG_*` or a
    #   known short-name macro from the local flag-macro table.
    candidates: list[str] = []
    for f in fields[4:]:
        s = f.strip()
        if not s:
            continue
        m = re.match(r"^\s*\.\s*flags\s*=\s*(.+?)\s*$", s)
        if m:
            candidates.append(m.group(1))
            continue
        # Positional field: detect a flag expression by content.
        if "AV_OPT_FLAG_" in s:
            candidates.append(s)
            continue
        # Look for an OR of short macros (`A|F|X|R`) — every token
        # must be a known flag-macro identifier; numeric values and
        # designated initialisers (`.x = ...`) are rejected here.
        if "|" in s and "=" not in s:
            toks = [t.strip() for t in s.split("|")]
            if toks and all(
                t in _LOCAL_FLAG_MACROS or t in _LOCAL_FLAG_MACROS.get("__direct__", set())
                for t in toks
            ):
                candidates.append(s)
                continue
        # Single short-macro identifier as the whole positional field.
        if re.match(r"^[A-Z][A-Z0-9_]*$", s) and s in _LOCAL_FLAG_MACROS:
            candidates.append(s)
    if not candidates:
        return out
    # Expand short-macro names into their AV_OPT_FLAG_* set, union
    # across every candidate field.
    bits: set[str] = set()
    for expr in candidates:
        for tok in re.split(r"\s*\|\s*", expr.strip()):
            tok = tok.strip()
            if not tok:
                continue
            if tok.startswith("AV_OPT_FLAG_"):
                bits.add(tok)
            elif tok in _LOCAL_FLAG_MACROS:
                bits |= _LOCAL_FLAG_MACROS[tok]
    for macro, key in _FLAG_BITS:
        if macro in bits:
            out[key] = True
    return out


# AV_OPT_TYPE_FLAG_ARRAY is a bit, not a type. When the C source uses
# `AV_OPT_TYPE_INT | AV_OPT_TYPE_FLAG_ARRAY` (af_aformat.c, FFmpeg 8+),
# split out the base type and surface the array bit separately.
def _parse_option_type(raw: str) -> Optional[tuple[str, bool]]:
    """Return (base_av_type, is_array) or None if no AV_OPT_TYPE_ token
    found / base type not understood. Whitespace and `|` are stripped
    so `AV_OPT_TYPE_X | AV_OPT_TYPE_FLAG_ARRAY` is accepted."""
    tokens = re.findall(r"AV_OPT_TYPE_[A-Z_0-9]+", raw)
    if not tokens:
        return None
    is_array = AV_OPT_TYPE_FLAG_ARRAY in tokens
    base = next((t for t in tokens if t != AV_OPT_TYPE_FLAG_ARRAY), None)
    if base is None:
        return None
    return base, is_array


def parse_options_block(block: str) -> tuple[list[Param], dict[str, list[EnumValue]]]:
    """Walk every `{ ... }` entry. Returns (regular_params, consts_by_unit).
    CONST entries are grouped by their `.unit` so the caller can build an
    enum from each group."""
    seen: set[str] = set()
    params: list[Param] = []
    consts: dict[str, list[EnumValue]] = {}
    # Index in `params` of the option that owns each struct field. ffmpeg
    # spells some options twice for one field (equalizer's `f` and
    # `frequency`, `g` and `gain`); they become one param.
    by_offset: dict[str, int] = {}
    for entry in _split_entries(block):
        fields = _split_top_level(entry)
        if len(fields) < 4:
            continue
        name_m = re.match(r'^\s*"([^"]+)"\s*$', fields[0])
        if not name_m:
            continue
        opt_name = name_m.group(1)
        desc = ""
        d = fields[1].strip()
        dm = re.match(r'^"((?:[^"\\]|\\.)*)"$', d)
        if dm:
            desc = dm.group(1)
        off = fields[2].strip()
        if not (off.startswith("OFFSET(") or off == "0"):
            continue
        parsed = _parse_option_type(fields[3])
        if parsed is None:
            continue
        av_type, is_array = parsed
        unit = _parse_unit(fields)
        flag_bits = _parse_flag_bits(fields)
        # CONST entries — gather into their unit group, never as params.
        # The default is `{.i64=N}` or `{.i64=SYMBOL_NAME}`. The integer
        # value is for the C side only; mpv's wire format uses the name,
        # so a non-integer default does NOT disqualify the entry.
        if av_type == "AV_OPT_TYPE_CONST":
            if unit is None:
                continue
            ivalue: Optional[int] = None
            symbol: Optional[str] = None
            for f in fields[4:]:
                f = f.strip()
                if not f.startswith("{"):
                    continue
                m = re.match(r"\{\s*\.\w+\s*=\s*([^}]+?)\s*\}", f)
                if m:
                    raw = m.group(1).strip()
                    try:
                        ivalue = int(raw)
                    except ValueError:
                        ivalue = None
                        # Capture only well-formed C identifiers — `1+1`
                        # or `NB_FOO-1` are expression literals, not the
                        # canonical CONST identifier we want for default
                        # back-resolution.
                        if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", raw):
                            symbol = raw
                break
            consts.setdefault(unit, []).append(
                EnumValue(name=opt_name, value=ivalue, desc=desc, symbol=symbol)
            )
            continue
        if av_type not in AV_OPT_DART_TYPE:
            continue
        # Remaining fields: optionally {default}, then 0+ positional
        # numerics interpreted as min/max, then `.flags`/`.unit` named
        # fields we either consumed (unit) or ignore (flags).
        default: Optional[str] = None
        array_sep: Optional[str] = None
        min_val: Optional[str] = None
        max_val: Optional[str] = None
        positional: list[str] = []
        # For ARRAY options the default brace is `.default_val.arr = &name`.
        # Resolve `name` to its AVOptionArrayDef definition (parsed by
        # _index_array_defs at module load) and pull the `.def` string +
        # `.sep` byte from there.
        array_ref_name: Optional[str] = None
        for f in fields[4:]:
            f = f.strip()
            if not f:
                continue
            if f.startswith("{"):
                if is_array:
                    # `.default_val.arr = &xxx` or `.arr = &xxx` brace.
                    am = re.match(
                        r"\{\s*(?:\.default_val\s*)?\.arr\s*=\s*&?\s*"
                        r"([A-Za-z_][A-Za-z0-9_]*)\s*\}",
                        f,
                    )
                    if am:
                        array_ref_name = am.group(1)
                    else:
                        # Fallback: plain string default for an array
                        # whose def is inlined (rare).
                        default = _parse_default(f)
                else:
                    default = _parse_default(f)
            elif f.startswith(".") and not re.match(r"^\.\d", f):
                # Named field (`.unit = "X"`, `.flags = AV_OPT_FLAG_…`,
                # `.min`, `.max`, `.default_val.X`). `.min=` / `.max=`
                # are handled below by scanning fields explicitly.
                # The `not \.\d` guard keeps leading-dot floats like
                # `.01` / `.5f` out of this branch — they're positional
                # min/max numerics, not designated initializers.
                pass
            else:
                positional.append(f)
        # _parse_minmax accepts numeric literals only. For symbolic
        # bounds (INT_MAX, FLT_MAX, YAE_ATEMPO_MIN), fall back to the
        # raw token so _resolve_symbol downstream can substitute the
        # numeric value.
        if len(positional) >= 1:
            min_val = _parse_minmax(positional[0]) or positional[0].strip() or None
        if len(positional) >= 2:
            max_val = _parse_minmax(positional[1]) or positional[1].strip() or None
        # Named `.min=NUM` / `.max=NUM` (used by af_aformat.c-style
        # array rows). The named form takes precedence over the
        # positional one — positionals are rare for FFmpeg 8 array
        # options.
        for f in fields[4:]:
            ff = f.strip()
            mm = re.match(r"^\.\s*min\s*=\s*(.+?)\s*$", ff)
            if mm:
                v = _parse_minmax(mm.group(1)) or mm.group(1).strip()
                min_val = v
            mm = re.match(r"^\.\s*max\s*=\s*(.+?)\s*$", ff)
            if mm:
                v = _parse_minmax(mm.group(1)) or mm.group(1).strip()
                max_val = v
        # Resolve symbolic min/max (INT_MAX, file-local #defines).
        min_val = _resolve_symbol(min_val)
        max_val = _resolve_symbol(max_val)
        # Resolve the array default + separator.
        if is_array and array_ref_name is not None:
            adef = _ARRAY_DEFS.get(array_ref_name)
            if adef is not None:
                if adef.get("def") is not None and default is None:
                    default = '"' + adef["def"] + '"'
                if adef.get("sep") is not None:
                    array_sep = adef["sep"]
        # Promote INT → enum / FLAGS → flags when the option binds to a unit.
        dart_type = AV_OPT_DART_TYPE[av_type]
        if unit is not None and av_type in (
            "AV_OPT_TYPE_INT", "AV_OPT_TYPE_INT64", "AV_OPT_TYPE_UINT"
        ):
            dart_type = "enum"
        elif av_type == "AV_OPT_TYPE_FLAGS":
            dart_type = "flags"
        # Arrays of any base type are rendered as a single opaque
        # string at the wire boundary — that's the FFmpeg-canonical
        # input form (`s16|s32|fltp`). Promote to string regardless of
        # the base type so the Dart side sees one consistent surface.
        if is_array:
            dart_type = "string"
        if opt_name in seen:
            continue
        owner = by_offset.get(off) if off.startswith("OFFSET(") else None
        if owner is not None:
            kept = params[owner]
            if (
                kept.av_type == av_type
                and kept.unit == unit
                and kept.default == default
                and kept.min_value == min_val
                and kept.max_value == max_val
            ):
                # The longer name wins; at equal length the lowercase one,
                # as in effect_params (loudnorm's `measured_LRA` and
                # `measured_lra`).
                if len(opt_name) > len(kept.name) or (
                    len(opt_name) == len(kept.name)
                    and opt_name == opt_name.lower()
                    and kept.name != kept.name.lower()
                ):
                    kept.name = opt_name
                    kept.description = desc or kept.description
                seen.add(opt_name)
                continue
        if off.startswith("OFFSET("):
            by_offset.setdefault(off, len(params))
        params.append(
            Param(
                name=opt_name,
                description=desc,
                av_type=av_type,
                dart_type=dart_type,
                default=default,
                min_value=min_val,
                max_value=max_val,
                unit=unit,
                is_array=is_array,
                array_sep=array_sep,
                readonly=flag_bits.get("readonly", False),
                runtime=flag_bits.get("runtime", False),
                deprecated=flag_bits.get("deprecated", False),
                export=flag_bits.get("export", False),
            )
        )
        seen.add(opt_name)
    return params, consts


def _extract_brace_block(source: str, start_after: int) -> Optional[str]:
    depth = 1
    i = start_after
    while i < len(source) and depth > 0:
        if source[i] == "{":
            depth += 1
        elif source[i] == "}":
            depth -= 1
        i += 1
    return source[start_after : i - 1] if depth == 0 else None


_OPTIONS_ARRAY_RE = re.compile(
    r"\b(?:static\s+(?:const\s+)?)?AVOption\s+(?P<arr>\w+)\s*\[\s*\]\s*=\s*\{",
)
# ffmpeg 8.0 renamed the implementation struct `AVFilter ff_<type>_<name>`
# to `FFFilter ff_<type>_<name>` (AVFilter is now the public-facing
# struct). Accept either spelling.
_FILTER_DECL_RE = re.compile(
    r"\b(?:AVFilter|FFFilter)\s+ff_(?:af|asrc|asink)_(?P<name>\w+)\b",
)
_BIQUAD_2_RE = re.compile(
    r"\bDEFINE_BIQUAD_FILTER_2\s*\(\s*(?P<name>\w+)\s*,[^,]+,\s*(?P<priv>\w+)\s*\)",
)
_BIQUAD_1_RE = re.compile(
    r"\bDEFINE_BIQUAD_FILTER\s*\(\s*(?P<name>\w+)\s*,",
)
_CLASS_EXT_RE = re.compile(
    r"\bAVFILTER_DEFINE_CLASS_EXT\s*\(\s*"
    r"(?P<klass>\w+)\s*,\s*"
    r'"[^"]*"\s*,\s*'
    r"(?P<arr>\w+)\s*\)",
    re.DOTALL,
)
_CLASS_PLAIN_RE = re.compile(
    r"\bAVFILTER_DEFINE_CLASS\s*\(\s*(?P<klass>\w+)\s*\)",
)


def find_filter_options_pairs(source: str) -> list[tuple[str, str]]:
    arrays: dict[str, str] = {}
    for m in _OPTIONS_ARRAY_RE.finditer(source):
        body = _extract_brace_block(source, m.end())
        if body is not None:
            arrays[m.group("arr")] = body

    def lookup_array(arr_var: str) -> Optional[str]:
        if arr_var in arrays:
            return arrays[arr_var]
        if f"{arr_var}_options" in arrays:
            return arrays[f"{arr_var}_options"]
        return None

    bindings: dict[str, str] = {}
    for m in _FILTER_DECL_RE.finditer(source):
        body = lookup_array(m.group("name"))
        if body is not None:
            bindings[m.group("name")] = body
    for m in _BIQUAD_2_RE.finditer(source):
        body = lookup_array(m.group("priv"))
        if body is not None:
            bindings[m.group("name")] = body
    for m in _BIQUAD_1_RE.finditer(source):
        body = lookup_array(m.group("name"))
        if body is not None:
            bindings.setdefault(m.group("name"), body)
    ext_arrays = []
    for m in _CLASS_EXT_RE.finditer(source):
        body = lookup_array(m.group("arr"))
        if body is not None:
            ext_arrays.append(body)
    if ext_arrays:
        for m in _FILTER_DECL_RE.finditer(source):
            bindings.setdefault(m.group("name"), ext_arrays[0])
    for m in _CLASS_PLAIN_RE.finditer(source):
        body = lookup_array(m.group("klass"))
        if body is not None:
            for fm in _FILTER_DECL_RE.finditer(source):
                bindings.setdefault(fm.group("name"), body)
            break
    if len(arrays) == 1 and not bindings:
        body = next(iter(arrays.values()))
        for m in _FILTER_DECL_RE.finditer(source):
            bindings.setdefault(m.group("name"), body)
    return list(bindings.items())


_MACRO_DEFINE_HEAD_RE = re.compile(r"^\s*#define\s+(\w+)\(([^)]*)\)\s*(.*)$")


def _parse_macros(source: str) -> dict[str, tuple[list[str], str]]:
    """Extract function-like `#define` macros that emit AVOption rows.

    Returns ``{name: (params, body)}``. Backslash line continuations are
    folded into a single line. Macros whose body contains no ``{`` are
    dropped — they don't shape options arrays so we ignore them.
    """
    macros: dict[str, tuple[list[str], str]] = {}
    lines = source.split("\n")
    i = 0
    while i < len(lines):
        line = lines[i]
        m = _MACRO_DEFINE_HEAD_RE.match(line)
        if not m:
            i += 1
            continue
        name = m.group(1)
        params_str = m.group(2)
        body_parts: list[str] = [m.group(3)]
        # Fold continuation lines.
        while body_parts[-1].rstrip().endswith("\\"):
            body_parts[-1] = body_parts[-1].rstrip()[:-1]
            i += 1
            if i >= len(lines):
                break
            body_parts.append(lines[i])
        body = " ".join(p.strip() for p in body_parts).strip()
        params = [p.strip() for p in params_str.split(",") if p.strip()]
        if "{" in body:
            macros[name] = (params, body)
        i += 1
    return macros


def _expand_macros(
    block: str, macros: dict[str, tuple[list[str], str]]
) -> str:
    """Substitute ``MACRO(args)`` invocations in [block] with their
    expanded body, replacing parameter tokens with the call args.

    Macros that don't appear in [block] cost nothing — the early
    `name not in block` short-circuit dominates. Single pass: macros
    that reference other macros aren't expanded recursively (none of
    the audio-filter biquad/shared macros do this).
    """
    for name, (params, body) in macros.items():
        if name not in block:
            continue
        # Match a balanced-paren invocation. Args may contain commas
        # nested in `(...)`, `{...}`, or strings — _split_top_level
        # handles that on the captured arg string.
        pattern = re.compile(
            r"\b" + re.escape(name) + r"\s*\(((?:[^()]|\([^)]*\))*)\)"
        )

        def replace(m: re.Match[str]) -> str:
            args = [a.strip() for a in _split_top_level(m.group(1))]
            if len(args) != len(params):
                return m.group(0)  # arg-count mismatch: leave as-is
            expanded = body
            for p, a in zip(params, args):
                if not p:
                    continue
                # Whole-word replace so `x` doesn't match inside `xxx`.
                expanded = re.sub(r"\b" + re.escape(p) + r"\b", a, expanded)
            return expanded

        block = pattern.sub(replace, block)
    return block


def parse_filters_in_file(path: Path) -> list[Filter]:
    text = path.read_text(errors="replace")
    # Refresh the per-file caches before walking option blocks.
    # `_resolve_symbol` reads `_LOCAL_NUMERIC_DEFINES`; the array
    # default lookup reads `_ARRAY_DEFS`; flag-bit detection reads
    # `_LOCAL_FLAG_MACROS`. All three are per-file.
    _index_local_macros(text)
    _index_enum_members(text)
    _index_array_defs(text)
    _index_local_flag_macros(text)
    # File-local macros override header ones with the same name
    # (header macros come first, then the .c file's redefinitions).
    macros = dict(_HEADER_MACROS)
    macros.update(_parse_macros(text))
    supports_commands = ".process_command" in text
    out: list[Filter] = []
    for filter_name, block in find_filter_options_pairs(text):
        block = _expand_macros(block, macros)
        params, consts = parse_options_block(block)
        if not params and not consts:
            continue
        # Drop CONST groups that no param references — they bloat the
        # schema and produce orphan enums in the Dart output.
        used_units = {p.unit for p in params if p.unit is not None}
        consts = {u: vs for u, vs in consts.items() if u in used_units}
        out.append(
            Filter(
                name=filter_name,
                source_file=path.name,
                supports_commands=supports_commands,
                params=params,
                consts=consts,
            )
        )
    return out


# ── filters.texi parsing ───────────────────────────────────────────────


_TEXI_OPTION_TABLE_RE = re.compile(
    r"@table\s+@option\s*\n(?P<body>.*?)\n@end\s+table",
    re.DOTALL,
)
_TEXI_ITEM_RE = re.compile(
    r"^@item\s+(?P<name>\S[^\n]*)\n(?P<body>.*?)(?=^@item\s|\Z)",
    re.MULTILINE | re.DOTALL,
)


def _strip_texi_markup(text: str) -> str:
    """Best-effort plain-text rendering of a texi snippet. Strips the
    common markup commands without pulling in a real texinfo parser."""
    s = text
    # @code{X}, @file{X}, @var{X}, @dfn{X}, @emph{X}, @strong{X}, @t{X}
    s = re.sub(r"@(?:code|file|var|dfn|emph|strong|t|samp)\{([^}]*)\}", r"`\1`", s)
    # @ref{LABEL,, TEXT} → TEXT, @ref{LABEL} → LABEL
    s = re.sub(r"@ref\{([^,}]+)(?:,[^}]*)?\}", r"\1", s)
    # @url{URL,, TEXT} → TEXT  /  @url{URL} → URL
    s = re.sub(r"@url\{([^,}]+)(?:,[^}]*)?\}", r"\1", s)
    # Quoting / accent commands — drop the wrapper, keep the text.
    s = re.sub(r"@(?:i|b|sc|asis)\{([^}]*)\}", r"\1", s)
    # @itemize / @enumerate / @bullet style markers — strip the directives.
    s = re.sub(r"^@(?:itemize|enumerate)(?:\s+\S+)?\s*$", "", s, flags=re.MULTILINE)
    s = re.sub(r"^@end\s+(?:itemize|enumerate)\s*$", "", s, flags=re.MULTILINE)
    s = re.sub(r"^@item\s*", "- ", s, flags=re.MULTILINE)
    # Anything else that begins with @ on its own — strip the directive.
    s = re.sub(r"^@\w+(?:\s+[^\n]*)?$", "", s, flags=re.MULTILINE)
    # @{ → {, @} → }
    s = s.replace("@{", "{").replace("@}", "}")
    # Collapse runs of blank lines to a single blank line.
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def parse_filters_texi(path: Path) -> dict[str, dict]:
    """Return {filter_name -> {description, params: {name -> desc_long}}}.
    The texi splits filter docs by `@section <name>`; some sections cover
    multiple filters via `@anchor` cross-refs (rare for audio), which we
    handle by also indexing on every `@anchor` we encounter inside a
    section body."""
    if not path.is_file():
        return {}
    text = path.read_text(errors="replace")
    sections = re.split(r"(?m)^@section\s+([^\n]+)\n", text)
    # split() yields [pre, name1, body1, name2, body2, ...]
    out: dict[str, dict] = {}
    for i in range(1, len(sections), 2):
        raw_name = sections[i].strip()
        body = sections[i + 1] if i + 1 < len(sections) else ""
        # Multi-filter sections (e.g. "abuffer, abuffersink"): same body
        # applies to each named filter.
        names = [n.strip() for n in re.split(r"[,/]\s*", raw_name) if n.strip()]
        # Description: text up to the first `@table @option` that
        # documents the parameters.
        desc_match = re.split(r"(?m)^@table\s+@option\s*$", body, maxsplit=1)
        description = _strip_texi_markup(desc_match[0])
        # Params: walk every top-level `@table @option` in the body and
        # collect `@item NAME / body` entries. Nested option tables (used
        # for documenting enum CONST values inline) are stripped first
        # so they don't pollute the outer items.
        params: dict[str, str] = {}
        # A non-greedy match on `@table @option ... @end table` would
        # latch on to the FIRST `@end table` even when the outer table
        # contains nested ones. Use a manual depth counter instead.
        depth = 0
        outer_blocks: list[str] = []
        cursor = 0
        for m in re.finditer(r"@table\s+@option|@end\s+table", body):
            tok = m.group(0)
            if tok.startswith("@table"):
                if depth == 0:
                    cursor = m.end()
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    outer_blocks.append(body[cursor:m.start()])
        for table_body in outer_blocks:
            for m in _TEXI_ITEM_RE.finditer(table_body):
                pname = m.group("name").strip()
                # Some items list aliases on one line: `@item framelen, f`.
                # Split and apply the same description to each alias.
                aliases = [a.strip() for a in pname.split(",") if a.strip()]
                pbody = _strip_texi_markup(m.group("body"))
                for a in aliases:
                    if a not in params:
                        params[a] = pbody
        for n in names:
            out[n] = {"description": description, "params": params}
        # Anchors inside the section body let other filters share docs.
        for m in re.finditer(r"@anchor\{([^}]+)\}", body):
            label = m.group(1).strip()
            out.setdefault(label, {"description": description, "params": params})
    return out


# ── Whitelist + version detection ──────────────────────────────────────


def read_whitelist(whitelist_file: Path, var_name: str) -> set[str]:
    """The EFFECTIVE filter set for ``$var_name``.

    Shell-evals the whitelist file (honoring `_user_overrides.sh` + the `VAR+=`
    accumulation form) via config.resolve_whitelist — so a TUI filter selection
    drives both the binary build and this codegen from one source of truth."""
    return set(resolve_whitelist(whitelist_file, var_name))


def read_ffmpeg_version(ffmpeg_root: Path) -> str:
    vfile = ffmpeg_root / "VERSION"
    if vfile.is_file():
        return vfile.read_text().strip()
    return "unknown"


# ── Schema assembly + serialisation ────────────────────────────────────


def _to_pascal(snake: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", snake)
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def _is_dart_invalid_param(name: str) -> bool:
    """True if the param name cannot legally be a Dart identifier and
    must be routed via Map<String, T>."""
    if not name:
        return True
    return bool(name[0].isdigit() or not re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name))


def assemble_schema(
    filters_by_name: dict[str, Filter], whitelist: set[str], version: str
) -> dict:
    schema: dict = {
        "ffmpeg_version": version,
        "filters": {},
    }
    for name in sorted(whitelist):
        f = filters_by_name.get(name)
        if f is None:
            schema["filters"][name] = {
                "source_file": None,
                "description": "",
                "params": {},
                "params_invalid": {},
                "enums": {},
            }
            continue
        params: dict[str, dict] = {}
        params_invalid: dict[str, dict] = {}
        for p in f.params:
            entry: dict = {
                "type": p.dart_type,
                "default": p.default,
                "min": p.min_value,
                "max": p.max_value,
                "desc": p.description,
                "desc_long": "",
            }
            if p.unit is not None and p.dart_type in ("enum", "flags"):
                # Stable enum id used by generate.py.
                entry["enum_id"] = f"{_to_pascal(f.name)}{_to_pascal(p.unit)}"
            # Array marker — generate.py renders the field as a string
            # with the array separator embedded in the doc-comment so
            # callers know how to build the value. The base type
            # surfaces in `av_type` for inspectors.
            if p.is_array:
                entry["is_array"] = True
                entry["array_sep"] = p.array_sep or "|"
                entry["av_type"] = p.av_type
            # Flag bits the codegen acts on. Always emitted so the
            # schema is self-documenting; values may be `false`.
            if p.readonly:
                entry["readonly"] = True
            if p.runtime:
                entry["runtime"] = True
            if p.deprecated:
                entry["deprecated"] = True
            if p.export:
                entry["export"] = True
            if _is_dart_invalid_param(p.name):
                params_invalid[p.name] = entry
            else:
                params[p.name] = entry
        # Enums: only include unit groups that are referenced by some
        # param in this filter (already filtered upstream, defensive).
        used_units = {p.unit for p in f.params if p.unit is not None}
        enums: dict[str, list[dict]] = {}
        for unit, vals in f.consts.items():
            if unit not in used_units:
                continue
            enum_id = f"{_to_pascal(f.name)}{_to_pascal(unit)}"
            enums[enum_id] = [
                {
                    "name": v.name,
                    "value": v.value,
                    "desc": v.desc,
                    "symbol": v.symbol,
                }
                for v in vals
            ]
        schema["filters"][name] = {
            "source_file": f.source_file,
            "description": f.description,
            "supports_commands": f.supports_commands,
            "params": params,
            "params_invalid": params_invalid,
            "enums": enums,
        }
    return schema


def merge_texi_into_schema(schema: dict, texi: dict[str, dict]) -> None:
    for fname, fdata in schema["filters"].items():
        tinfo = texi.get(fname)
        if tinfo is None:
            continue
        if not fdata.get("description"):
            fdata["description"] = tinfo.get("description", "")
        long_descs = tinfo.get("params", {})
        for pname, pinfo in fdata["params"].items():
            if pname in long_descs:
                pinfo["desc_long"] = long_descs[pname]
        for pname, pinfo in fdata["params_invalid"].items():
            if pname in long_descs:
                pinfo["desc_long"] = long_descs[pname]


def run(config: Config) -> int:
    """Walk the FFmpeg libavfilter tree pointed at by [config], parse
    every AVOption array, and write the schema JSON to
    config.output.schema. Returns 0 on success."""
    ffmpeg_root = config.ffmpeg_source_dir
    libavfilter = ffmpeg_root / "libavfilter"
    if not libavfilter.is_dir():
        sys.exit(
            f"libavfilter dir not found: {libavfilter}\n"
            "Run a build first (or fix [ffmpeg].source_dir in codegen.toml)."
        )
    whitelist = read_whitelist(config.whitelist_file, config.whitelist_var)
    version = read_ffmpeg_version(ffmpeg_root)
    print(f"ffmpeg {version}, whitelist {len(whitelist)} filters", file=sys.stderr)
    filters: dict[str, Filter] = {}
    # Index function-like macros defined in libavfilter/*.h once, up
    # front, so per-file parsing can pick up AVOption-emitting macros
    # that the .c files only see through a header (`WIN_FUNC_OPTION`
    # in window_func.h, surround / firequalizer / etc; biquad helpers
    # in af_biquads.h; …). _parse_macros applies the union of header
    # macros + the file-local ones before walking the options block.
    global _HEADER_MACROS
    _HEADER_MACROS = {}
    for hpath in sorted(libavfilter.glob("*.h")):
        try:
            htext = hpath.read_text(errors="replace")
        except OSError:
            continue
        _HEADER_MACROS.update(_parse_macros(htext))

    # Audio filters live in af_/asrc_/asink_ files. A handful of `f_`
    # files host audio-flavour filters too (e.g. f_ebur128.c). And a
    # few audio filters (aeval, aevalsrc) live in files whose names
    # don't carry an audio-only prefix (aeval.c) or whose name happens
    # to match a video filter (split.c, trim.c, setpts.c — these define
    # both video and audio variants in one file).
    #
    # The robust rule: open every .c file once, scan for an `ff_(af|
    # asrc|asink)_NAME` declaration, and parse only those. Filters with
    # no audio declaration are skipped — including pure-video filters,
    # which never reach the AVOption parser.
    _AUDIO_DECL_TOKENS = ("ff_af_", "ff_asrc_", "ff_asink_")
    for path in sorted(libavfilter.glob("*.c")):
        # Fast prefix path keeps the common case allocation-free.
        n = path.name
        if not n.startswith(("af_", "asrc_", "asink_")):
            try:
                text = path.read_text(errors="replace")
            except OSError:
                continue
            if not any(tok in text for tok in _AUDIO_DECL_TOKENS):
                continue
        for f in parse_filters_in_file(path):
            if f.name in whitelist:
                filters[f.name] = f
    print(
        f"Parsed AVOption arrays: {len(filters)} filters with params",
        file=sys.stderr,
    )
    texi = parse_filters_texi(ffmpeg_root / "doc/filters.texi")
    if texi:
        print(f"Loaded texi docs for {len(texi)} sections", file=sys.stderr)
    schema = assemble_schema(filters, whitelist, version)
    merge_texi_into_schema(schema, texi)
    apply_effective_ranges(schema)
    out = config.output.schema
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(schema, indent=2, sort_keys=True) + "\n")
    try:
        rel = out.relative_to(config.scripts_root)
    except ValueError:
        rel = out
    print(f"Wrote {rel}", file=sys.stderr)
    return 0
