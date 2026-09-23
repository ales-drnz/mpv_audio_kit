#!/usr/bin/env python3
"""Stage 1b of the lavfi codegen: a SECOND, source-of-truth-independent
parser that introspects `ffmpeg -h filter=<name>` per whitelist filter
and emits `schema_runtime.json`.

Why a second parser:
  The C-source scraper at `parse.py` walks the literal `AVOption[]`
  arrays in `libavfilter/*.c`. That works but trips on macro
  expansions (`DEFINE_BIQUAD_FILTER_2`), bitwise-OR types
  (`AV_OPT_TYPE_X | AV_OPT_TYPE_FLAG_ARRAY`), symbolic limit macros
  (`INT_MAX`, file-local `#define`s), and child-class delegation
  (`aresample` → SWResampler).

  `ffmpeg -h filter=<name>` runs FFmpeg's own `av_opt_show2()` over
  the loaded `AVClass.option` table, so every macro is already
  expanded, every symbolic limit already resolved, every child class
  already listed. The output is a single 11-column textual format
  documented in `libavutil/opt.c::opt_list` — easier to parse than
  C, and impossible to drift from the runtime.

Usage:
    scripts/lavfi_codegen/parse_from_help.py            # use ffmpeg on PATH
    scripts/lavfi_codegen/parse_from_help.py /path/to/ffmpeg
    scripts/lavfi_codegen/parse_from_help.py --diff     # diff vs schema.json

Output: `scripts/lavfi_codegen/schema_runtime.json`.

The diff mode is the recommended QA step after every parse.py change:
it lists params present in one schema but missing from the other, and
bound/default mismatches per param. Anything that's runtime-truth but
missing from the C scrape is a bug in parse.py; anything in the C
scrape but missing from runtime usually means the filter is gated by
a build flag we're not compiling against.
"""
from __future__ import annotations

import json
import re
import shutil
import subprocess
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

from .config import Config, resolve_whitelist


# ── ffmpeg invocation ──────────────────────────────────────────────────


def _run_ffmpeg(ffmpeg: str, args: list[str]) -> str:
    res = subprocess.run(
        [ffmpeg, "-hide_banner", *args],
        capture_output=True,
        text=True,
        check=False,
    )
    # `-h filter=X` writes to stdout. Errors (filter missing, no
    # libavfilter linked) go to stderr; surface those by joining.
    return (res.stdout or "") + (res.stderr or "")


def _detect_ffmpeg() -> str:
    """Locate an ffmpeg binary. Prefer one matching the bundled
    libavfilter version (8.1.x); fall back to anything on PATH."""
    candidate = shutil.which("ffmpeg")
    if candidate is None:
        sys.exit(
            "ffmpeg binary not found on PATH. Install it (`brew install "
            "ffmpeg`) or pass an explicit path as the first argument."
        )
    return candidate


def _ffmpeg_version(ffmpeg: str) -> str:
    out = _run_ffmpeg(ffmpeg, ["-version"])
    m = re.search(r"^ffmpeg version (\S+)", out, re.MULTILINE)
    return m.group(1) if m else "unknown"


# ── Whitelist ──────────────────────────────────────────────────────────


def _read_whitelist(whitelist_file: Path, var_name: str) -> list[str]:
    # Shell-eval (honors _user_overrides.sh + `+=` accumulation) — see
    # config.resolve_whitelist.
    return resolve_whitelist(whitelist_file, var_name)


# ── av_opt_show2 textual format ────────────────────────────────────────
#
# A typical option line emitted by FFmpeg 8 looks like:
#
#     attack            <double>     ..F.A....T. set attack (from 0.01 to 2000) (default 20)
#     sample_fmts       [<sample_fmt>]..F.A...... A '|'-separated list of sample formats.
#     downward          0            ..F.A....T.
#     ratio             <double>     ..F.A....T. set ratio (from 1 to 20) (default 2)
#
# Columns (per libavutil/opt.c::opt_list):
#   1. Option name (indented 3 spaces; CONST members indented 5).
#   2. Type — `<int>` `<double>` `<duration>` `<boolean>` `<string>`
#      `<channel_layout>` `<sample_fmt>` `<image_size>` `<flags>`.
#      For arrays the type is wrapped in `[...]`.
#      CONST rows show only an integer (the enum value) at this column.
#   3. 11-character flags column EDFVASXRBTP (constants below).
#   4. Optional description text, ending with `(from MIN to MAX)`
#      and/or `(default VAL)` segments, and possibly a docstring
#      ending in a newline.
#
# Section boundaries (`<Title> AVOptions:`) demarcate the filter's
# own option table from any child-class option blocks
# (`SWResampler AVOptions:` for aresample, etc.).


_SECTION_HEADER_RE = re.compile(r"^(?P<name>\S.*?) AVOptions:\s*$")

# Option / CONST line. `name` is the first token; `type` is either
# `<…>` (scalar), `[<…>]` (array), or a plain integer for CONST rows.
# `flags` is the 11-char EDFVASXRBTP column (or a `.`-only run of the
# same length).
_OPT_LINE_RE = re.compile(
    r"^\s*"
    r"(?P<name>\S+)"
    r"\s+"
    r"(?P<type>\[?<[^>]+>\s*\]|<[^>]+>|-?\d+)"
    r"\s*"
    r"(?P<flags>[EDFVASXRBTP.]{11})"
    r"(?:\s+(?P<rest>.*))?$"
)


def _flag_bits(col: str) -> dict[str, bool]:
    # Positional: EDFVASXRBTP, see libavutil/opt.c.
    return {
        "encoding":   col[0] == "E",
        "decoding":   col[1] == "D",
        "filtering":  col[2] == "F",
        "video":      col[3] == "V",
        "audio":      col[4] == "A",
        "subtitle":   col[5] == "S",
        "export":     col[6] == "X",
        "readonly":   col[7] == "R",
        "bsf":        col[8] == "B",
        "runtime":    col[9] == "T",
        "deprecated": col[10] == "P",
    }


# Tail-segment extractors. Both are emitted by av_opt_show2 after the
# description text — order is `(from MIN to MAX)` then `(default VAL)`,
# either may be absent. The default segment carries either the
# resolved symbol (`default downward`) or a numeric literal (`default
# 2.82843`).
_RANGE_RE = re.compile(r"\(from\s+(?P<min>\S+)\s+to\s+(?P<max>\S+)\)")
_DEFAULT_RE = re.compile(r"\(default\s+(?P<val>.+?)\)\s*$")

# ffmpeg renders some bounds as the C limit macro itself
# (`I64_MAX`, `UINT32_MAX`, `INT_MIN`). Re-substitute to the numeric
# value so the diff stays clean. Mirror of `_C_NUMERIC_CONSTANTS` in
# parse.py; kept in sync intentionally.
_C_LIMIT_TO_NUMERIC = {
    "INT_MAX":    "2147483647",
    "INT_MIN":    "-2147483648",
    "INT32_MAX":  "2147483647",
    "INT32_MIN":  "-2147483648",
    "INT64_MAX":  "9223372036854775807",
    "INT64_MIN":  "-9223372036854775808",
    "I64_MAX":    "9223372036854775807",
    "I64_MIN":    "-9223372036854775808",
    "UINT_MAX":   "4294967295",
    "UINT32_MAX": "4294967295",
    "DBL_MAX":    "1.7976931348623157e+308",
    "FLT_MAX":    "3.4028234663852886e+38",
    "-DBL_MAX":   "-1.7976931348623157e+308",
    "-FLT_MAX":   "-3.4028234663852886e+38",
    "-INT_MAX":   "-2147483647",
    "-I64_MAX":   "-9223372036854775807",
}


def _resolve_limit(tok: Optional[str]) -> Optional[str]:
    if tok is None:
        return None
    return _C_LIMIT_TO_NUMERIC.get(tok.strip(), tok)


# Map ffmpeg's type token (without angle brackets) to the codegen's
# Dart-side type alias. Mirrors `AV_OPT_DART_TYPE` in parse.py for
# diffability.
_TYPE_TO_DART = {
    "double":         "double",
    "float":          "double",
    "int":            "int",
    "int64":          "int",
    "uint":           "int",
    "boolean":        "bool",
    "string":         "string",
    "duration":       "duration",
    "channel_layout": "chlayout",
    "sample_fmt":     "string",
    "image_size":     "string",
    "video_rate":     "string",
    "flags":          "flags",
    "rational":       "string",
    "dict":           "string",
    "color":          "string",
}


@dataclass
class HelpOption:
    name: str
    raw_type: str          # the ffmpeg type token (`int`, `sample_fmt`, …)
    dart_type: str         # mapped to the codegen alias
    is_array: bool
    flags: dict[str, bool]
    desc: str
    default: Optional[str]
    min_value: Optional[str]
    max_value: Optional[str]
    unit: Optional[str] = None  # not exposed by help text; left None
    consts: list[dict] = field(default_factory=list)


@dataclass
class HelpFilter:
    name: str
    description: str
    sections: dict[str, list[HelpOption]] = field(default_factory=dict)


def _parse_filter_help(text: str, name: str) -> HelpFilter:
    """Walk `ffmpeg -h filter=<name>` output and pull out the option
    table. The output begins with a header (filter name + I/O pads)
    and ends with optional notes about timeline support."""
    out = HelpFilter(name=name, description="")
    # Filter description — text between the `Filter <name>` header
    # and the first `Inputs:` line.
    desc_match = re.search(
        rf"^Filter {re.escape(name)}\s*\n(?P<desc>(?:.+\n)+?)\s*Inputs:",
        text,
        re.MULTILINE,
    )
    if desc_match:
        out.description = desc_match.group("desc").strip()
    section: Optional[str] = None
    current_opt: Optional[HelpOption] = None
    pending_unit: Optional[str] = None  # for CONST rows
    for raw_line in text.splitlines():
        sh = _SECTION_HEADER_RE.match(raw_line)
        if sh:
            section = sh.group("name").strip()
            out.sections.setdefault(section, [])
            current_opt = None
            continue
        if section is None:
            continue
        m = _OPT_LINE_RE.match(raw_line)
        if not m:
            continue
        name_tok = m.group("name")
        type_tok = m.group("type").strip()
        flag_col = m.group("flags")
        rest = (m.group("rest") or "").rstrip()
        flag_bits = _flag_bits(flag_col)
        # CONST row: type is an integer literal (e.g. `0`, `-1`).
        if re.match(r"^-?\d+$", type_tok):
            if current_opt is not None:
                current_opt.consts.append({
                    "name": name_tok,
                    "value": int(type_tok),
                    "desc": rest.strip(),
                })
            continue
        # Array form: `[<sample_fmt>]` or `[<int>     ]` (the printer
        # pads inside the brackets).
        is_array = type_tok.startswith("[")
        inner = type_tok.strip("[]").strip()
        # Strip the leading `<` and trailing `>` + any padding.
        raw_type = inner.strip("<>").strip()
        dart_type = _TYPE_TO_DART.get(raw_type, "string")
        # Promote int-with-CONSTs to enum if we already know this row
        # has constants (post-pass below).
        # Extract range + default from the tail. Order matters: the
        # printer emits `(from X to Y) (default V)` in that order, so
        # peel `(default …)` off the end FIRST and only then look for
        # the `(from … to …)` segment — otherwise stripping the range
        # would also drop the default that comes after it.
        default_v: Optional[str] = None
        min_v: Optional[str] = None
        max_v: Optional[str] = None
        dm = _DEFAULT_RE.search(rest)
        if dm:
            default_v = dm.group("val").strip()
            rest = rest[: dm.start()].rstrip()
        rm = _RANGE_RE.search(rest)
        if rm:
            min_v = _resolve_limit(rm.group("min"))
            max_v = _resolve_limit(rm.group("max"))
            rest = rest[: rm.start()].rstrip()
        # Quoting: ffmpeg prints string defaults wrapped in `"…"`; keep
        # them quoted so downstream knows it's a literal not a symbol.
        opt = HelpOption(
            name=name_tok,
            raw_type=raw_type,
            dart_type=dart_type,
            is_array=is_array,
            flags=flag_bits,
            desc=rest.strip(),
            default=default_v,
            min_value=min_v,
            max_value=max_v,
        )
        out.sections[section].append(opt)
        current_opt = opt
    # Promote int rows with consts to enum.
    for opts in out.sections.values():
        for o in opts:
            if o.consts and o.dart_type == "int":
                o.dart_type = "enum"
            elif o.consts and o.dart_type == "flags":
                pass  # already flags
    return out


# ── Schema assembly ────────────────────────────────────────────────────


def _to_pascal(snake: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", snake)
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def assemble(filters: dict[str, HelpFilter], version: str) -> dict:
    schema: dict = {
        "ffmpeg_version": version,
        "source": "ffmpeg -h filter",
        "filters": {},
    }
    for fname in sorted(filters):
        f = filters[fname]
        primary = f.sections.get(fname) or next(iter(f.sections.values()), [])
        children = {k: v for k, v in f.sections.items() if k != fname}
        params: dict[str, dict] = {}
        enums: dict[str, list[dict]] = {}
        for opt in primary:
            entry: dict = {
                "type": opt.dart_type,
                "default": opt.default,
                "min": opt.min_value,
                "max": opt.max_value,
                "desc": opt.desc,
                "raw_type": opt.raw_type,
            }
            if opt.is_array:
                entry["is_array"] = True
            for fb in ("readonly", "runtime", "deprecated", "export"):
                if opt.flags.get(fb):
                    entry[fb] = True
            if opt.dart_type in ("enum", "flags") and opt.consts:
                enum_id = f"{_to_pascal(fname)}{_to_pascal(opt.name)}"
                entry["enum_id"] = enum_id
                enums[enum_id] = [
                    {"name": c["name"], "value": c["value"], "desc": c["desc"]}
                    for c in opt.consts
                ]
            params[opt.name] = entry
        # Child sections expose options of an inherited AVClass
        # (SWResampler for aresample). Record them under `child_classes`
        # so the codegen can choose to inline or reference.
        child_dump: dict[str, dict] = {}
        for cname, opts in children.items():
            child_dump[cname] = {
                "params": {
                    opt.name: {
                        "type": opt.dart_type,
                        "default": opt.default,
                        "min": opt.min_value,
                        "max": opt.max_value,
                        "desc": opt.desc,
                        "raw_type": opt.raw_type,
                    }
                    for opt in opts
                    if not re.match(r"^-?\d+$", opt.raw_type or "")
                },
            }
        # A filter accepts live `*-command` updates when at least one of its
        # options carries the runtime flag (the `T` column / AV_OPT_FLAG_
        # RUNTIME_PARAM) — the runtime equivalent of the C-source parser's
        # `.process_command` detection. The diff emitter gates per-option on
        # the per-param `runtime` flag already recorded above.
        supports_commands = any(opt.flags.get("runtime") for opt in primary)
        schema["filters"][fname] = {
            "description": f.description,
            "params": params,
            "enums": enums,
            "child_classes": child_dump,
            "supports_commands": supports_commands,
        }
    return schema


# ── Diff mode ──────────────────────────────────────────────────────────


def _diff(runtime: dict, c_source: dict) -> str:
    out: list[str] = []
    rf = runtime["filters"]
    cf = c_source["filters"]
    all_names = sorted(set(rf) | set(cf))
    for name in all_names:
        r = rf.get(name)
        c = cf.get(name)
        if r is None:
            out.append(f"FILTER {name}: only in C-source schema")
            continue
        if c is None:
            out.append(f"FILTER {name}: only in runtime schema")
            continue
        rp = r["params"]
        cp = {**c.get("params", {}), **c.get("params_invalid", {})}
        only_r = sorted(set(rp) - set(cp))
        only_c = sorted(set(cp) - set(rp))
        if only_r:
            out.append(f"  {name}: params only in runtime: {only_r}")
        if only_c:
            out.append(f"  {name}: params only in C-source: {only_c}")
        for pname in sorted(set(rp) & set(cp)):
            rpp = rp[pname]
            cpp = cp[pname]
            mismatches: list[str] = []
            if rpp.get("default") != cpp.get("default"):
                mismatches.append(
                    f"default: runtime={rpp.get('default')!r} "
                    f"c_source={cpp.get('default')!r}"
                )
            # Compare bounds numerically — runtime may render
            # `DBL_MAX` as `1.79e+308`; both should round-trip the
            # same value.
            def _num(x):
                try:
                    return float(x) if x is not None else None
                except (TypeError, ValueError):
                    return None
            if _num(rpp.get("min")) != _num(cpp.get("min")):
                mismatches.append(
                    f"min: runtime={rpp.get('min')} "
                    f"c_source={cpp.get('min')}"
                )
            if _num(rpp.get("max")) != _num(cpp.get("max")):
                mismatches.append(
                    f"max: runtime={rpp.get('max')} "
                    f"c_source={cpp.get('max')}"
                )
            if mismatches:
                out.append(f"  {name}.{pname}: {'; '.join(mismatches)}")
    return "\n".join(out) if out else "(schemas agree on every param)"


# ── Entry point ────────────────────────────────────────────────────────


def run(
    config: Config,
    *,
    ffmpeg: Optional[str] = None,
    diff_mode: bool = False,
    out_path: Optional[Path] = None,
) -> int:
    """Run `ffmpeg -h filter=<X>` for every whitelist filter, parse the
    output, and write the runtime schema.

    By default the schema is written to ``config.output.schema_runtime``
    (skipped if that is None). Pass ``out_path`` to redirect it elsewhere —
    used to make the runtime introspection BE the generation schema for
    consumers whose filters the C-source parser doesn't cover (video).

    Pass ``diff_mode=True`` to print a runtime-vs-C-source diff after
    the runtime schema is built; the C-source schema is read from
    ``config.output.schema``.
    """
    ffmpeg = ffmpeg or _detect_ffmpeg()
    version = _ffmpeg_version(ffmpeg)
    whitelist = _read_whitelist(config.whitelist_file, config.whitelist_var)
    print(
        f"ffmpeg {version} at {ffmpeg}, whitelist {len(whitelist)} filters",
        file=sys.stderr,
    )
    filters: dict[str, HelpFilter] = {}
    for name in whitelist:
        out = _run_ffmpeg(ffmpeg, ["-h", f"filter={name}"])
        # Include parameterless filters (e.g. hflip / vflip) — valid filters
        # with no AVOptions section. Skip only genuinely-missing ones (no
        # `Filter <name>` header), which would otherwise yield an empty stub.
        if f"Filter {name}" not in out:
            continue
        filters[name] = _parse_filter_help(out, name)
    schema = assemble(filters, version)
    runtime_out = out_path or config.output.schema_runtime
    if runtime_out is not None:
        runtime_out.parent.mkdir(parents=True, exist_ok=True)
        runtime_out.write_text(
            json.dumps(schema, indent=2, sort_keys=True) + "\n"
        )
        try:
            rel = runtime_out.relative_to(config.scripts_root)
        except ValueError:
            rel = runtime_out
        print(
            f"Wrote {rel} ({len(filters)} filters introspected)",
            file=sys.stderr,
        )
    if diff_mode:
        ref = config.output.schema
        if not ref.is_file():
            print(f"diff: reference schema {ref} not found", file=sys.stderr)
            return 0
        c_source = json.loads(ref.read_text())
        print()
        print("=== runtime ↔ C-source diff ===")
        print(_diff(schema, c_source))
    return 0
