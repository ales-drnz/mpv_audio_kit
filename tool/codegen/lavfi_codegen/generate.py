#!/usr/bin/env python3
"""Stage 2 of the lavfi codegen: read `schema.json` and emit two files
under `lib/src/types/`:
  - `enums/audio_effects.dart`: every Dart enum derived from libavfilter
    AVOption `.unit` groups (95 today). No Freezed dependency.
  - `settings/audio_effects_settings.dart`: every per-filter Settings
    class (one per libavfilter audio filter, 144 today) plus the
    `AudioEffects` bundle that concatenates everything into mpv's
    `--af` value. Imports the enums file.

The split keeps each tipo in its categorically-correct folder
(`types/enums/` vs `types/settings/`) and matches the rest of the
package's hand-written types.

Usage:
    scripts/lavfi_codegen/generate.py

Idempotent. Runs `dart format` at the end if the binary is on PATH.

Naming rules (load-bearing — see project CLAUDE.md):
  - Settings class:   `<FilterPascal>Settings` (e.g. `AcompressorSettings`).
  - Bundle field:     ffmpeg name verbatim (e.g. `e.acompressor`).
  - Param field:      ffmpeg AVOption.name verbatim (snake_case kept).
                      Dart reserved word → trailing underscore (`type` →
                      `type_`). Digit-prefix names → routed via
                      `Map<String, T> params` keyed by the exact ffmpeg
                      identifier.
  - Enum type:        `<FilterPascal><UnitPascal>` (e.g. `RubberbandPitch`).
                      Members keep the ffmpeg CONST name; digit-prefix
                      members get an `n` prefix (`n50fm` → `'50fm'`).

Wire format: every enabled stage emits `lavfi-NAME=k=v:...` joined with
`,`. No wrapper labels — the typed bundle is the only writer of mpv's
`af` property, so `state.audioEffects` is the source of truth and
external raw writes are not reverse-parsed.
"""
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path

from .config import Config, NamingConfig, WireConfig
from .required_params import REQUIRED_PARAMS, SAMPLE_VALUES, required_for

# Sentinel default for required constructor params. A required field is
# non-nullable, has NO `= default`, and is emitted as a `required this.x`
# arg in the const constructor. `_ctor_field_spec` returns this in the
# default-literal slot so the const-ctor emitter can branch on identity.
_REQUIRED = object()

# Per-run wire-format config. Populated by run(); the per-class
# emission helpers consult it for the lavfi-/empty prefix and for the
# enum accessor name (`mpvValue`/`fromMpv` vs `ffmpegValue`/
# `fromFfmpeg`). Kept as a module-level handle because the emission
# helpers are called recursively from many points; threading config
# through every call would explode the diff for no gain.
_WIRE: WireConfig = WireConfig()

# Feature-gated emission (set from config in run()): `@label:` chain
# syntax and the af-command runtime diff are mpv-specific wire features.
_EMIT_LABELS: bool = False
_EMIT_DIFF: bool = False

# Per-run domain naming (set from config in run()): the Dart identifiers + doc
# nouns that differ between the audio and video flavors. Defaults reproduce the
# historical audio output verbatim.
_NAMING: NamingConfig = NamingConfig()
# Basename of the enums file the settings file imports (e.g.
# `audio_effects.dart` / `video_effects.dart`). Set in run() from output paths.
_ENUMS_IMPORT: str = "audio_effects.dart"

# Whitelist of (filter, param) pairs whose ffmpeg AVOption table is
# internally inconsistent — the C source itself declares a default
# outside the [min, max] range. The codegen omits the bound assert
# for these so default-constructed Settings don't blow up. Anything
# else that triggers the same condition is almost always a parser
# bug; the codegen prints a WARNING to stderr in that case.
_INTERNALLY_INCONSISTENT_DEFAULTS: set[tuple[str, str]] = {
    ("acrusher", "dc"),  # default=1, min=4 (af_acrusher.c)
}

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


# ── Identifier helpers ─────────────────────────────────────────────────


def _to_pascal(snake: str) -> str:
    parts = re.split(r"[^A-Za-z0-9]+", snake)
    return "".join(p[:1].upper() + p[1:] for p in parts if p)


def _settings_class_name(filter_name: str) -> str:
    """`equalizer` → `EqualizerEffect`: the filter's lavfi name, suffixed so
    short names (Bass, Pan, Surround) never collide with app classes."""
    sanitised = re.sub(r"[^A-Za-z0-9_]", "_", filter_name)
    return sanitised[:1].upper() + sanitised[1:] + "Effect"


def _camel(snake: str) -> str:
    """ffmpeg's snake_case → Dart lowerCamelCase: `level_in` → `levelIn`,
    `lr_to_l_plus_r` → `lrToLPlusR`, an all-caps word lowered (`LUFS` →
    `lufs`)."""
    parts = [p for p in snake.split("_") if p]
    if not parts:
        return snake
    head = parts[0]
    head = head.lower() if head.isupper() else head[:1].lower() + head[1:]
    return head + "".join(p[:1].upper() + p[1:] for p in parts[1:])


def effect_params(fdata: dict) -> dict:
    """The params an effect class exposes: every settable (non-readonly)
    option, minus case-only aliases. ffmpeg declares some options twice
    for the same field (loudnorm's `I` and `i`, `LRA` and `lra`), which
    would collapse onto one camelCase name; the lowercase spelling wins."""
    params = {n: p for n, p in fdata["params"].items() if not p.get("readonly")}
    by_dart: dict[str, str] = {}
    for name in params:
        dart = _param_dart_name(name)
        kept = by_dart.get(dart)
        if kept is None or (kept != kept.lower() and name == name.lower()):
            by_dart[dart] = name
    keep = set(by_dart.values())
    return {n: p for n, p in params.items() if n in keep}


# Members every effect class already has; a param whose Dart name lands on
# one gets a `Value` suffix instead.
_EFFECT_MEMBERS = {
    "enabled", "filter", "filterName", "copyWith", "toFilterString",
    "hashCode", "runtimeType", "toString", "noSuchMethod",
}


def _bundle_field_name(filter_name: str) -> str:
    if filter_name in DART_RESERVED_WORDS:
        return filter_name + "_"
    return filter_name


def _param_dart_name(name: str) -> str:
    dart = _camel(name)
    if dart in DART_RESERVED_WORDS:
        return dart + "_"
    if dart in _EFFECT_MEMBERS:
        return dart + "Value"
    return dart


_SPECIAL_CHAR_MAP = {
    ">": "_to_",
    "+": "_plus_",
    "-": "_minus_",
}


def _enum_member_dart_name(name: str) -> str:
    """ffmpeg CONST names are reused verbatim modulo three escapes:
      - digit-prefix → `n` prefix (`50fm` → `n50fm`).
      - reserved word → trailing underscore (`true` → `true_`).
      - special chars (`>`, `+`, `-`) → readable replacements so members
        like `lr>l+r` and `lr>l-r` (both ffmpeg `mode` CONSTs of
        stereotools) don't collapse to the same identifier.
    The wire-side enum accessor always returns the original ffmpeg name."""
    if not name:
        return "valueUnknown"
    sanitised = "".join(_SPECIAL_CHAR_MAP.get(ch, ch) for ch in name)
    sanitised = re.sub(r"[^A-Za-z0-9_]", "_", sanitised)
    sanitised = re.sub(r"_+", "_", sanitised).strip("_")
    if not sanitised:
        sanitised = "value_unknown"
    if not re.match(r"^[A-Za-z_]", sanitised):
        sanitised = "n" + sanitised
    sanitised = _camel(sanitised)
    if sanitised in DART_RESERVED_WORDS:
        sanitised += "_"
    return sanitised


# ── Literal formatters ─────────────────────────────────────────────────

# C limit macros sometimes survive in `default` values from the runtime
# (`ffmpeg -h filter=`) introspection — the C-source AVOption parser resolves
# them numerically, the help text doesn't. Map them to Dart numeric literals so
# the emitted constructor defaults compile. (ffmpeg uses *_MAX sentinels as
# "unset" markers; emitting the same numeric keeps the "omit when == default"
# wire logic exact.)
_C_LIMIT_MACROS = {
    "DBL_MAX": "1.7976931348623157e+308",
    "-DBL_MAX": "-1.7976931348623157e+308",
    "FLT_MAX": "3.4028234663852886e+38",
    "-FLT_MAX": "-3.4028234663852886e+38",
    "DBL_MIN": "2.2250738585072014e-308",
    "FLT_MIN": "1.1754943508222875e-38",
    "INT_MAX": "2147483647",
    "INT_MIN": "-2147483648",
    "UINT32_MAX": "4294967295",
}


def _normalise_double_literal(raw: str) -> str:
    m = re.match(r"^(-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)[fF]$", raw)
    if m:
        raw = m.group(1)
    if raw.endswith("."):
        return raw + "0"
    if "." in raw or "e" in raw or "E" in raw:
        return raw
    return raw + ".0"


def _dart_default_literal(dart_type: str, raw: str) -> str:
    raw = _C_LIMIT_MACROS.get(str(raw).strip(), raw)
    if dart_type == "bool":
        return "true" if raw in ("1", "true") else "false"
    if dart_type == "string":
        if raw.startswith('"') and raw.endswith('"'):
            return f"'{raw[1:-1]}'"
        return f"'{raw}'"
    if dart_type == "duration":
        # `Duration(microseconds: 0)` trips avoid_redundant_argument_values
        # (0 is the constructor default) — emit the canonical zero instead.
        return (
            "Duration.zero"
            if str(raw).strip() in ("0", "0.0")
            else f"const Duration(microseconds: {raw})"
        )
    if dart_type == "double":
        return _normalise_double_literal(raw)
    if dart_type in ("int",):
        return raw
    # Fallback (e.g. channel-layout strings such as `"stereo"`): normalise
    # any double-quoted literal to Dart single quotes (prefer_single_quotes).
    if raw.startswith('"') and raw.endswith('"'):
        return f"'{raw[1:-1]}'"
    return raw


def _dart_field_type(dart_type: str, enum_id: str | None) -> str:
    """Returns the Dart type for a regular param (not nullable, not Map)."""
    if dart_type == "double":
        return "double"
    if dart_type == "int":
        return "int"
    if dart_type == "bool":
        return "bool"
    if dart_type == "string":
        return "String"
    if dart_type == "duration":
        return "Duration"
    if dart_type == "chlayout":
        return "String"
    if dart_type == "enum":
        return enum_id or "int"
    if dart_type == "flags":
        return f"Set<{enum_id}>" if enum_id else "Set<String>"
    return "Object"


def _format_value_expr(name: str, dart_type: str, nullable: bool) -> str:
    dn = _param_dart_name(name) + ("!" if nullable else "")
    if dart_type == "double":
        return f"_wireDouble({dn})"
    if dart_type == "int":
        return f"{dn}.toString()"
    if dart_type == "bool":
        return f"({dn} ? '1' : '0')"
    if dart_type == "duration":
        return f"_wireDouble({dn}.inMicroseconds / 1e6)"
    if dart_type == "enum":
        return f"{dn}.{_WIRE.value_getter}"
    if dart_type == "flags":
        # Render as `+v1+v2` per ffmpeg flag CSV conventions; the
        # leading `+` makes the chain string equivalent to a CSV write.
        return (
            f"{dn}.map((e) => e.{_WIRE.value_getter}).join('+')"
        )
    if dart_type in ("string", "chlayout"):
        # Wrap in `[...]` so mpv's filter-args parser doesn't split on
        # internal `:` `=` `,` `|` characters within the value. This is
        # the documented mpv canonical escape (vf.rst).
        return f"'[' + {dn} + ']'"
    return dn


# ── Emission ───────────────────────────────────────────────────────────


_COPYRIGHT = (
    "// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.\n"
    "// All rights reserved.\n"
    "// Use of this source code is governed by BSD 3-Clause license\n"
    "// that can be found in the LICENSE file.\n"
    "//\n"
    "// AUTO-GENERATED — do not edit by hand.\n"
)


def _emit_test_filter_names(sorted_names: list[str]) -> str:
    """Test-side mirror of every typed audio filter name. Imported by
    runtime tests that exercise the bundled libmpv binary's filter
    registry without consuming the public AudioEffects API."""
    body = [_COPYRIGHT, ""]
    body.append("library;")
    body.append("")
    body.append(
        f"/// Names of every typed {_NAMING.noun} filter the public "
        f"`{_NAMING.bundle_name}`"
    )
    body.append("/// bundle exposes, in declaration order. Kept in `test/` because")
    body.append("/// no production code consumes the list.")
    body.append(f"const List<String> {_NAMING.test_names_const} = [")
    for name in sorted_names:
        body.append(f"  '{name}',")
    body.append("];")
    return "\n".join(body) + "\n"


def _emit_audio_effect_enum(sorted_names: list[str]) -> str:
    """Singular `AudioEffect` enum — one value per typed audio filter.
    Identifies a slot in the [AudioEffects] bundle for APIs that pick a
    single filter (e.g. `PlayerStream.tap`). Enum value name == mpv
    filter type name, exposed verbatim through [filterName]. Appended
    to the multi-enum `audio_effects.dart` file alongside the AVOption
    enums to avoid a near-identical second filename in the directory.
    """
    body: list[str] = []
    body.append("")
    body.append(f"/// Identifies one of the typed {_NAMING.noun} filters: one value per")
    body.append("/// `XxxEffect` class, i.e. per filter compiled into the bundled")
    body.append("/// libmpv. Use it as a typed identifier in APIs that pick a filter,")
    body.append(
        f"/// e.g. `player.stream.tap({_NAMING.enum_name}.equalizer, "
        "side: TapSide.post)`."
    )
    body.append(f"enum {_NAMING.enum_name} {{")
    for name in sorted_names:
        body.append(f"  /// The `{name}` {_NAMING.noun} filter.")
        body.append(f"  {_bundle_field_name(name)},")
    body.append("  ;")
    body.append("")
    body.append("  /// mpv filter-type name. Coincides with the enum value")
    body.append("  /// [name] for every entry on the current whitelist; the")
    body.append("  /// getter exists so consumers don't depend on that")
    body.append("  /// coincidence (a future filter colliding with a Dart")
    body.append("  /// reserved word would gain a trailing `_` on its enum")
    body.append("  /// value, which this getter would strip).")
    body.append("  String get filterName {")
    body.append("    final n = name;")
    body.append("    return n.endsWith('_') ? n.substring(0, n.length - 1) : n;")
    body.append("  }")
    body.append("}")
    return "\n".join(body)




def _emit_enums_header() -> str:
    return (
        _COPYRIGHT
        + "// ignore_for_file: constant_identifier_names, camel_case_types,"
        " non_constant_identifier_names\n"
    )


def _emit_settings_header(*, needs_set: bool = True, needs_map: bool = True) -> str:
    # `_setEq` / `_mapEq` are emitted only when some field actually uses them
    # (Set / Map params). Audio has both, so its output is unchanged; a flavor
    # with neither (video) omits them rather than tripping `unused_element`.
    parts: list[str] = [
        _COPYRIGHT,
        "// ignore_for_file: non_constant_identifier_names,"
        " constant_identifier_names, camel_case_types,"
        " curly_braces_in_flow_control_structures,"
        " prefer_adjacent_string_concatenation,"
        " prefer_interpolation_to_compose_strings\n"
        "\n"
        "import 'package:meta/meta.dart';\n"
        "\n"
        f"import '{_NAMING.sentinel_import}';\n"
        f"import '{_ENUMS_IMPORT}';\n"
        "\n"
        "// Collection equality helpers used by the generated `==`. Kept\n"
        "// inline to avoid a transitive `package:collection` dependency.\n",
    ]
    if needs_set:
        parts.append(
            "bool _setEq<T>(Set<T> a, Set<T> b) {\n"
            "  if (identical(a, b)) return true;\n"
            "  if (a.length != b.length) return false;\n"
            "  for (final e in a) {\n"
            "    if (!b.contains(e)) return false;\n"
            "  }\n"
            "  return true;\n"
            "}\n"
            "\n"
        )
    if needs_map:
        parts.append(
            "bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) {\n"
            "  if (identical(a, b)) return true;\n"
            "  if (a.length != b.length) return false;\n"
            "  for (final entry in a.entries) {\n"
            "    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {\n"
            "      return false;\n"
            "    }\n"
            "  }\n"
            "  return true;\n"
            "}\n"
            "\n"
        )
    parts.append(
        f"/// Wire-format a double for the lavfi {_NAMING.wire_word}-chain. "
        "Uses 3-decimal\n"
        "/// fixed-point for normal values; falls back to a 1-significant-\n"
        "/// figure exponential for tiny values that would otherwise round\n"
        "/// to `0.000` (e.g. `1e-6` for `asoftclip.threshold`'s minimum).\n"
        "/// `toStringAsExponential()` is deterministic across runtimes\n"
        "/// (Dart's `toString()` chooses between decimal and exponential\n"
        f"/// based on magnitude and platform), and {_WIRE.accessor}'s "
        "AVOption parser\n"
        "/// accepts exponential floats natively.\n"
        "String _wireDouble(double v) {\n"
        "  final fixed = v.toStringAsFixed(3);\n"
        "  if (v == 0 || double.parse(fixed) == v) return fixed;\n"
        "  if (v.abs() < 0.001) return v.toStringAsExponential();\n"
        "  return fixed;\n"
        "}\n"
    )
    return "".join(parts)


def _emit_enum(
    enum_id: str,
    members: list[dict],
    filter_name: str,
    option: str | None,
) -> str:
    """One Dart enum per AVOption `.unit` group. Members carry their
    exact ffmpeg CONST name in the wire accessor (`mpvValue` for the
    mpv-flavoured consumer, `ffmpegValue` for the plain-FFmpeg one).
    The `fromX` parser is non-throwing — defaults to the first member
    on unknown input — per project conventions."""
    getter = _WIRE.value_getter
    parser = _WIRE.from_method
    consumer_label = "mpv" if _WIRE.accessor == "mpv" else "ffmpeg"
    lines: list[str] = []
    lines.append("")
    if option:
        lines.append(
            f"/// Values for the `{option}` option of the `{filter_name}` "
            f"{_NAMING.noun} filter."
        )
    else:
        lines.append(
            f"/// Enumerated option values for the `{filter_name}` "
            f"{_NAMING.noun} filter."
        )
    lines.append(f"enum {enum_id} {{")
    for m in members:
        member_name = _enum_member_dart_name(m["name"])
        desc = (m.get("desc") or "").replace("\n", " ").strip()
        if desc:
            lines.append(f"  /// {desc}")
        else:
            lines.append(f"  /// The `{m['name']}` option value.")
        lines.append(f"  {member_name},")
    lines.append("  ;")
    lines.append("")
    lines.append(f"  /// Wire-side string consumed by {consumer_label}.")
    lines.append(f"  String get {getter} {{")
    lines.append("    switch (this) {")
    for m in members:
        member_name = _enum_member_dart_name(m["name"])
        lines.append(f"      case {enum_id}.{member_name}: return '{m['name']}';")
    lines.append("    }")
    lines.append("  }")
    lines.append("")
    lines.append(f"  /// Parses a {consumer_label} wire string back into a [{enum_id}].")
    lines.append("  /// Unknown / empty input falls back to the first member.")
    lines.append(f"  static {enum_id} {parser}(String? raw) {{")
    lines.append("    switch (raw) {")
    for m in members:
        member_name = _enum_member_dart_name(m["name"])
        lines.append(f"      case '{m['name']}': return {enum_id}.{member_name};")
    lines.append(f"      default: return {enum_id}.{_enum_member_dart_name(members[0]['name'])};")
    lines.append("    }")
    lines.append("  }")
    lines.append("}")
    return "\n".join(lines)


def _resolve_enum_default(enum_id: str | None, raw_default: str | None) -> str | None:
    """Map an enum default back to a member name.

    Three strategies, tried in order:
      1. INT default `{.i64=42}` → match the member with matching value.
      2. SYMBOL default `{.i64=QFACTOR}` → match the member whose CONST
         row was itself `{.i64=QFACTOR}` (parse.py captures these as
         `symbol` on the EnumValue).
      3. Positional fallback for unit enums whose CONST rows are ALL
         symbol-typed (every `value` is None) — common pattern when
         a unit's CONSTs reference a C `enum {…}` rather than int
         literals. C enums number sequentially from 0, so default N
         picks members[N] when in range. Mirrors the convention
         ffmpeg's own help text uses to print these defaults.

    Returns the member's option name (Dart-cased) or `None` if no
    strategy resolves — caller makes the field nullable in that case.
    """
    if not enum_id or raw_default is None:
        return None
    members = _ENUM_LOOKUP.get(enum_id, [])
    if not members:
        return None
    # 1) Integer default.
    default_int: int | None = None
    try:
        default_int = int(str(raw_default))
        chosen = next(
            (m for m in members if m.get("value") == default_int),
            None,
        )
        if chosen is not None:
            return _enum_member_dart_name(chosen["name"])
    except (ValueError, TypeError):
        pass
    # 2) Symbol default.
    raw = str(raw_default).strip()
    if re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", raw):
        chosen = next(
            (m for m in members if m.get("symbol") == raw),
            None,
        )
        if chosen is not None:
            return _enum_member_dart_name(chosen["name"])
    # 3) Positional fallback (all-symbol unit).
    if default_int is not None and all(m.get("value") is None for m in members):
        if 0 <= default_int < len(members):
            return _enum_member_dart_name(members[default_int]["name"])
    return None


def _ctor_field_spec(pname: str, p: dict) -> tuple[str, str, bool]:
    """Returns (dart_type, default_literal_or_empty, nullable). The dart_type
    is the field's declared type. The default literal is "" when the field
    is nullable (no default needed). nullable=True means the field accepts
    null and the copyWith path needs the sentinel.

    Required params (init/config fails in ffmpeg if unset) are emitted as
    non-nullable, default-less `required` ctor args: the dart_type is the
    bare (non-nullable) type, the default slot is the `_REQUIRED` sentinel,
    and nullable is False."""
    if p.get("required"):
        return _dart_field_type(p["type"], p.get("enum_id")), _REQUIRED, False
    ptype = p["type"]
    enum_id = p.get("enum_id")
    field_type = _dart_field_type(ptype, enum_id)
    if ptype == "flags":
        return field_type, f"<{enum_id}>{{}}", False
    if ptype == "enum":
        member = _resolve_enum_default(enum_id, p.get("default"))
        if member is not None:
            return field_type, f"{enum_id}.{member}", False
        return f"{field_type}?", "", True
    if p.get("default") is not None:
        return field_type, _dart_default_literal(ptype, p["default"]), False
    return f"{field_type}?", "", True


def _emit_param_constants(params: dict) -> list[str]:
    """For every numeric parameter (`double` / `int`) with a `min`,
    `max`, or `default` declared by ffmpeg, emit a public
    `static const` field exposing that bound.

    Naming: `<dartName>Min`, `<dartName>Max`, `<dartName>Default`. UI
    builders consume these to populate slider / knob bounds, runtime
    validators, tooltips — everything that today would otherwise have
    to grep the source or guess (and crash on the asserts in
    `toFilterString()`).

    Single source of truth: the same `p["min"]` / `p["max"]` /
    `p["default"]` values feed the consts AND the asserts AND the
    constructor's default literal, so they cannot drift across
    regeneration runs.

    Skipped:
    - non-numeric params (bool / enum / flags / string / duration —
      either type-safe, range-less, or not knob-able);
    - bounds that fail to parse as the declared Dart numeric type
      (rare AVOption corner cases).
    """
    out: list[str] = []
    for pname, p in params.items():
        if p["type"] not in ("double", "int"):
            continue
        dart_name = _param_dart_name(pname)
        type_name = "double" if p["type"] == "double" else "int"
        const_doc = {"Default": "Default", "Min": "Minimum", "Max": "Maximum"}
        for suffix, key in (("Default", "default"), ("Min", "min"), ("Max", "max")):
            raw = p.get(key)
            if raw is None:
                continue
            try:
                lit = _dart_default_literal(type_name, str(raw))
            except Exception:
                continue
            out.append(f"  /// {const_doc[suffix]} value for [{dart_name}].")
            out.append(
                f"  static const {type_name} {dart_name}{suffix} = {lit};"
            )
    return out


def _emit_settings_class(filter_name: str, fdata: dict) -> str:
    """One `final class` per filter. Hand-rolled fields, const constructor,
    copyWith with sentinel-based null semantics for nullable params,
    operator==, hashCode, toString, and toFilterString. No `@freezed`,
    no generated mixin — the Python codegen IS the generator. Drops
    ~50000 lines of `*.freezed.dart` for the 144 filters while keeping
    the public API identical (same constructor shape, same copyWith,
    same value-equality semantics)."""
    cls = _settings_class_name(filter_name)
    # AVOption flag AV_OPT_FLAG_READONLY (and typically EXPORT) marks
    # an option as a filter OUTPUT, not an input — ebur128 publishes
    # its integrated-loudness / range / peak measurements that way.
    # FFmpeg rejects attempts to set them at chain build, so we
    # exclude them from the Settings surface entirely. Consumers
    # read these via `af-metadata/<label>` at runtime, not as
    # constructor args.
    params: dict = effect_params(fdata)
    # Flag the mandatory params (ffmpeg init/config fails if unset) so the
    # field loop below emits them as `required` ctor args and toFilterString
    # always writes them. Must run before `_ctor_field_spec` is consulted.
    req = required_for(filter_name)
    for pname, p in params.items():
        p["required"] = pname in req
    invalid: dict = {
        n: p
        for n, p in fdata.get("params_invalid", {}).items()
        if not p.get("readonly")
    }
    description = fdata.get("description") or ""

    # Pick the Map value type for the digit-prefix routes. If every
    # invalid param is the same Dart type we can keep the map typed;
    # otherwise fall back to Object.
    invalid_types = {p["type"] for p in invalid.values()}
    if invalid_types == {"double"}:
        map_value_type = "double"
    elif invalid_types == {"int"}:
        map_value_type = "int"
    elif invalid_types and len(invalid_types) == 1:
        only = next(iter(invalid_types))
        map_value_type = _dart_field_type(only, None)
    else:
        map_value_type = "Object"

    # Pre-compute every (name, dart_type, default, nullable) tuple. The
    # rest of the emission is a fold over this list — keeps the bookkeeping
    # for ctor / copyWith / == / hashCode / toString in lockstep.
    fields: list[tuple[str, str, str, bool]] = []
    fields.append(("enabled", "bool", "true", False))
    for pname, p in params.items():
        dart_name = _param_dart_name(pname)
        ftype, default_lit, nullable = _ctor_field_spec(pname, p)
        fields.append((dart_name, ftype, default_lit, nullable))
    _names = [f[0] for f in fields]
    if len(_names) != len(set(_names)):
        sys.exit(f"{filter_name}: Dart field names collide: {sorted(_names)}")
    has_params_map = bool(invalid)
    if has_params_map:
        map_type = f"Map<String, {map_value_type}>"
        fields.append(
            ("params", map_type, f"<String, {map_value_type}>{{}}", False)
        )

    lines: list[str] = []
    lines.append("")
    lines.append(f"/// Configuration for the `{filter_name}` {_NAMING.noun} effect.")
    if description:
        lines.append("///")
        for dl in description.splitlines():
            stripped = dl.rstrip()
            lines.append(f"/// {stripped}" if stripped else "///")
    if params:
        lines.append("///")
        lines.append("/// Parameters:")
        for pname, p in params.items():
            extras: list[str] = []
            if p.get("min") is not None and p.get("max") is not None:
                extras.append(f"range {p['min']}..{p['max']}")
            if p.get("default") is not None:
                extras.append(f"default {p['default']}")
            # AVOption flag bits — surface in the doc so consumers
            # don't have to grep the ffmpeg source. Only the bits
            # that change usage are surfaced (export+readonly = stat
            # output, runtime = live-tunable, array = wire as
            # separator-joined string, deprecated = phasing out).
            if p.get("is_array"):
                extras.append(
                    f"array, base={p.get('av_type', 'AV_OPT_TYPE_STRING')}, "
                    f"sep='{p.get('array_sep', '|')}'"
                )
            if p.get("readonly") and p.get("export"):
                extras.append("readonly stat output")
            elif p.get("runtime"):
                extras.append("runtime-tunable")
            if p.get("deprecated"):
                extras.append("DEPRECATED")
            extra_str = f" ({', '.join(extras)})" if extras else ""
            desc = (p.get("desc_long") or p.get("desc") or "").replace("\n", " ").strip()
            lines.append(f"/// - [{_param_dart_name(pname)}]: {desc}{extra_str}")
    if invalid:
        lines.append("///")
        lines.append("/// Parameters whose names start with a digit, addressed by")
        lines.append("/// their original key in the [params] map:")
        for pname, p in invalid.items():
            extras: list[str] = []
            if p.get("min") is not None and p.get("max") is not None:
                extras.append(f"range {p['min']}..{p['max']}")
            if p.get("default") is not None:
                extras.append(f"default {p['default']}")
            extra_str = f" ({', '.join(extras)})" if extras else ""
            desc = (p.get("desc_long") or p.get("desc") or "").replace("\n", " ").strip()
            lines.append(f"/// - `{pname}`: {desc}{extra_str}")

    lines.append(f"final class {cls} extends {_NAMING.bundle_name[:-1]} {{")
    # Public bound + default constants — let UI builders read engine
    # constraints (`Settings.fooMin`, `Settings.fooMax`,
    # `Settings.fooDefault`) without parsing source. See
    # [_emit_param_constants] for what's emitted.
    const_lines = _emit_param_constants(params)
    if const_lines:
        lines.extend(const_lines)
        lines.append("")
    # Final fields. @Deprecated lands on the field itself so a
    # consumer's reference (constructor, copyWith, direct read) is
    # called out by `dart analyze`. The bundle's `enabled` field
    # never carries an annotation; only AVOptions tagged with
    # AV_OPT_FLAG_DEPRECATED do.
    _dep_params = {
        pname for pname, p in params.items() if p.get("deprecated")
    }
    # ffmpeg short description per Dart-cased field name, reused verbatim
    # as the field's doc comment so the public API is self-documenting.
    _field_desc = {
        _param_dart_name(pn): (p.get("desc") or "").replace("\n", " ").strip()
        for pn, p in params.items()
    }
    for name, ftype, _, _ in fields:
        # Field doc — the effect's `enabled` flag, the digit-prefixed
        # `params` escape hatch, or the per-AVOption ffmpeg description.
        if name == "enabled":
            lines.append(
                "  /// Whether this effect is applied. `false` keeps it in the"
            )
            lines.append(
                "  /// list, with its settings, without inserting it in the chain."
            )
            lines.append("  @override")
        elif name == "params":
            lines.append(
                "  /// Raw values for parameters whose names start with a digit,"
            )
            lines.append("  /// keyed by their original ffmpeg option name.")
        else:
            d = _field_desc.get(name)
            lines.append(f"  /// {d}" if d else f"  /// The `{name}` parameter.")
        # `name` is the Dart-cased param name; find the matching
        # ffmpeg-side name (one of `params.keys()` after _param_dart_name).
        if name in _dep_params or any(
            _param_dart_name(pn) == name and params[pn].get("deprecated")
            for pn in params
        ):
            lines.append(
                f"  @Deprecated('marked AV_OPT_FLAG_DEPRECATED in libavfilter')"
            )
        lines.append(f"  final {ftype} {name};")
    lines.append("")
    # Const constructor. Collection defaults (Set<>{} / Map<,>{}) must
    # be const-prefixed to be valid in a parameter default position.
    lines.append(f"  /// Creates an [{cls}] with the given parameter values.")
    lines.append("  ///")
    lines.append("  /// Each parameter defaults to its ffmpeg default.")
    lines.append(f"  const {cls}({{")
    for name, ftype, default_lit, nullable in fields:
        if default_lit is _REQUIRED:
            # Mandatory ffmpeg option — no Dart default, must be supplied.
            lines.append(f"    required this.{name},")
        elif nullable:
            lines.append(f"    this.{name},")
        else:
            lit = default_lit
            if (
                lit
                and (ftype.startswith("Set<") or ftype.startswith("Map<"))
                and not lit.startswith("const ")
            ):
                lit = "const " + lit
            lines.append(f"    this.{name} = {lit},")
    lines.append("  });")
    lines.append("")
    lines.append("  @override")
    lines.append(f"  String get filterName => '{filter_name}';")
    lines.append("")
    lines.append("  @override")
    lines.append(
        f"  {_NAMING.enum_name} get filter => "
        f"{_NAMING.enum_name}.{_bundle_field_name(filter_name)};"
    )
    lines.append("")
    # copyWith — sentinel for nullable fields, `??` for non-nullable.
    lines.append(
        f"  /// Returns a copy of this [{cls}] with the given fields replaced."
    )
    lines.append(f"  {cls} copyWith({{")
    for name, ftype, _, nullable in fields:
        if nullable:
            lines.append(f"    Object? {name} = unset,")
        else:
            lines.append(f"    {ftype}? {name},")
    lines.append(f"  }}) => {cls}(")
    for name, ftype, _, nullable in fields:
        if nullable:
            lines.append(
                f"    {name}: identical({name}, unset) "
                f"? this.{name} : {name} as {ftype},"
            )
        else:
            lines.append(f"    {name}: {name} ?? this.{name},")
    lines.append("  );")
    lines.append("")
    # operator==
    lines.append("  @override")
    lines.append("  bool operator ==(Object other) =>")
    cmp_parts = [
        "      identical(this, other) ||",
        f"      (other is {cls}",
    ]
    for name, ftype, _, _ in fields:
        if ftype.startswith("Set<"):
            cmp_parts.append(f"          && _setEq({name}, other.{name})")
        elif ftype.startswith("Map<"):
            cmp_parts.append(f"          && _mapEq({name}, other.{name})")
        else:
            cmp_parts.append(f"          && other.{name} == {name}")
    cmp_parts[-1] = cmp_parts[-1] + ");"
    lines.extend(cmp_parts)
    lines.append("")
    # hashCode — collection fields contribute their content via
    # hashAllUnordered (Set: members; Map: entry-pair hashes), so two
    # equal collections always hash the same regardless of insertion
    # order. The contract holds: == compares contents semantically, and
    # hashCode mirrors that without falling back to length-as-proxy.
    hash_args = []
    for name, ftype, _, _ in fields:
        if ftype.startswith("Set<"):
            hash_args.append(f"Object.hashAllUnordered({name})")
        elif ftype.startswith("Map<"):
            hash_args.append(
                f"Object.hashAllUnordered({name}.entries.map("
                f"(e) => Object.hash(e.key, e.value)))"
            )
        else:
            hash_args.append(name)
    lines.append("  @override")
    if len(hash_args) == 1:
        # Object.hash requires ≥2 positional args. Single-field classes
        # fall back to the field's own hashCode.
        lines.append(f"  int get hashCode => {hash_args[0]}.hashCode;")
    elif len(hash_args) <= 20:
        lines.append(f"  int get hashCode => Object.hash({', '.join(hash_args)});")
    else:
        lines.append(
            f"  int get hashCode => Object.hashAll([{', '.join(hash_args)}]);"
        )
    lines.append("")
    # toString
    field_names = [name for name, _, _, _ in fields]
    lines.append("  @override")
    body_parts = ", ".join([f"{n}: ${n}" for n in field_names])
    lines.append(f"  String toString() => '{cls}({body_parts})';")
    lines.append("")
    # toFilterString
    lines.append(f"  /// Returns the {_NAMING.noun} chain entry for this effect.")
    lines.append("  /// Only non-default parameters are emitted.")
    lines.append("  @override")
    lines.append("  String toFilterString() {")
    if not params and not invalid:
        lines.append(f"    return '{_WIRE.label_prefix}{filter_name}';")
        lines.append("  }")
        lines.append("}")
        return "\n".join(lines)
    # Range asserts (debug-only). Always emitted on numeric params
    # with a parsable default — enums and flags are already type-safe.
    #
    # ffmpeg's own AVOption table is occasionally internally
    # inconsistent (the canonical case: `acrusher.dc` declares
    # default=1 with min=4). For those known cases, the bound is
    # explicitly elided via [_INTERNALLY_INCONSISTENT_DEFAULTS]. ANY
    # other default-outside-[min,max] pairing prints a WARNING during
    # codegen — that's almost always a parser bug masquerading as an
    # ffmpeg quirk (drmeter.length got past for months because the
    # parser misread `.01` as a designated initialiser, leaving
    # min=10 and the assert silently elided).
    for pname, p in params.items():
        if p["type"] not in ("double", "int") or p.get("default") is None:
            continue
        dart_name = _param_dart_name(pname)
        try:
            df = float(p["default"])
        except (ValueError, TypeError):
            df = None
        skip_lo = (filter_name, pname) in _INTERNALLY_INCONSISTENT_DEFAULTS
        skip_hi = skip_lo
        if p.get("min") is not None:
            try:
                pm = float(p["min"])
            except (ValueError, TypeError):
                pm = None
            if df is not None and pm is not None and df < pm and not skip_lo:
                print(
                    f"WARNING: {filter_name}.{pname} default {df} < min {pm} "
                    "— add to _INTERNALLY_INCONSISTENT_DEFAULTS or fix the "
                    "parser",
                    file=sys.stderr,
                )
            if not skip_lo:
                # Reference the public `<name>Min` const so the message
                # and the bound stay aligned across regeneration runs.
                lines.append(
                    f"    assert({dart_name} >= {dart_name}Min,"
                    f" '{filter_name}.{pname} must be >= {p['min']}');"
                )
        if p.get("max") is not None:
            try:
                pM = float(p["max"])
            except (ValueError, TypeError):
                pM = None
            if df is not None and pM is not None and df > pM and not skip_hi:
                print(
                    f"WARNING: {filter_name}.{pname} default {df} > max {pM} "
                    "— add to _INTERNALLY_INCONSISTENT_DEFAULTS or fix the "
                    "parser",
                    file=sys.stderr,
                )
            if not skip_hi:
                lines.append(
                    f"    assert({dart_name} <= {dart_name}Max,"
                    f" '{filter_name}.{pname} must be <= {p['max']}');"
                )
    lines.append("    final parts = <String>[];")
    for pname, p in params.items():
        ptype = p["type"]
        enum_id = p.get("enum_id")
        dart_name = _param_dart_name(pname)
        if p.get("required"):
            # Mandatory option — non-nullable, no default to omit, so emit
            # unconditionally. (All five curated required params are string
            # type, but format generically for safety.)
            fmt = _format_value_expr(pname, ptype, nullable=False)
            lines.append(f"    parts.add('{pname}=' + {fmt});")
            continue
        if ptype == "flags":
            # Empty flag set is the natural "default" — only emit when
            # the consumer actually populated the set.
            lines.append(
                f"    if ({dart_name}.isNotEmpty) "
                f"parts.add('{pname}=' + {dart_name}.map((e) => e.{_WIRE.value_getter}).join('+'));"
            )
            continue
        if ptype == "enum":
            # Reuse the single resolver — defaults can be int OR symbol,
            # and symbol-based defaults are common in af_biquads.c via
            # WIDTH_TYPE_OPTION(QFACTOR) / TRANSFORM_OPTION(DI) / etc.
            member = _resolve_enum_default(enum_id, p.get("default"))
            if member is not None:
                lines.append(
                    f"    if ({dart_name} != {enum_id}.{member}) "
                    f"parts.add('{pname}=' + {dart_name}.{_WIRE.value_getter});"
                )
            else:
                lines.append(
                    f"    if ({dart_name} != null) "
                    f"parts.add('{pname}=' + {dart_name}!.{_WIRE.value_getter});"
                )
            continue
        # Numeric / bool / string / duration.
        formatted = _format_value_expr(pname, ptype, nullable=p.get("default") is None)
        if p.get("default") is not None:
            default_lit = _dart_default_literal(ptype, p["default"])
            lines.append(
                f"    if ({dart_name} != {default_lit}) "
                f"parts.add('{pname}=' + {formatted});"
            )
        else:
            lines.append(
                f"    if ({dart_name} != null) "
                f"parts.add('{pname}=' + {formatted});"
            )
    if invalid:
        if map_value_type == "double":
            lines.append(
                "    params.forEach((k, v) => parts.add('$k=' + _wireDouble(v)));"
            )
        else:
            lines.append(
                "    params.forEach((k, v) => parts.add('$k=' + v.toString()));"
            )
    lines.append(
        f"    return parts.isEmpty ? '{_WIRE.label_prefix}{filter_name}' : "
        f"'{_WIRE.label_prefix}{filter_name}=' + parts.join(':');"
    )
    lines.append("  }")
    if _EMIT_DIFF and fdata.get("supports_commands"):
        lines.extend(_emit_runtime_diff(filter_name, cls, params, invalid))
    lines.append("}")
    return "\n".join(lines)


def _emit_runtime_diff(filter_name, cls, params, invalid):
    """`_runtimeDiff(prev)` for a filter whose source defines
    `.process_command`: `(option, wire value)` pairs for every changed
    runtime-tunable AVOption, or null when any change needs a rebuild.
    String values are emitted RAW (no `[...]` wrap) — that escape is for
    mpv's `af` list parser; `af-command` hands the argument verbatim to
    avfilter_process_command."""
    out = [""]
    out.append("  /// Runtime-tunable option diff against [prev]: the `(option,")
    out.append(
        f"  /// wire value)` pairs the live graph can apply via "
        f"`{_NAMING.wire_word}-command`,"
    )
    out.append("  /// or `null` when a changed option requires a chain rebuild.")
    out.append("  @override")
    out.append(f"  List<(String, String)>? _runtimeDiff(covariant {cls} prev) {{")
    out.append("    final out = <(String, String)>[];")
    for pname, p in params.items():
        ptype = p["type"]
        dn = _param_dart_name(pname)
        nullable = p.get("default") is None and not p.get("required")
        changed = (
            f"!_setEq({dn}, prev.{dn})"
            if ptype == "flags"
            else f"{dn} != prev.{dn}"
        )
        if not p.get("runtime"):
            out.append(f"    if ({changed}) return null;")
            continue
        if ptype == "flags":
            out.append(f"    if ({changed}) {{")
            out.append(f"      if ({dn}.isEmpty) return null;")
            out.append(
                f"      out.add(('{pname}', "
                f"{dn}.map((e) => e.{_WIRE.value_getter}).join('+')));"
            )
            out.append("    }")
            continue
        if ptype in ("string", "chlayout"):
            fmt = dn + ("!" if nullable else "")
        else:
            fmt = _format_value_expr(pname, ptype, nullable=nullable)
        out.append(f"    if ({changed}) {{")
        if nullable:
            out.append(f"      if ({dn} == null) return null;")
        out.append(f"      out.add(('{pname}', {fmt}));")
        out.append("    }")
    if invalid:
        out.append("    if (!_mapEq(params, prev.params)) return null;")
    out.append("    return out;")
    out.append("  }")
    return out


def _bundle_default_ctor(filter_name: str) -> str:
    """Const default-constructor expression for a filter's bundle field.

    Most filters use the zero-arg `<Cls>()` (every param defaulted,
    `enabled: false`). Filters with REQUIRED params have no zero-arg
    constructor, so we supply a const placeholder for each required arg.
    The default instance is always `enabled: false`, so it never enters
    the chain — these placeholders are inert wire-wise; SAMPLE_VALUES are
    reused where present (arnndn has none, so a literal placeholder is
    used for `model`)."""
    cls = _settings_class_name(filter_name)
    req = REQUIRED_PARAMS.get(filter_name)
    if not req:
        return f"{cls}()"
    samples = SAMPLE_VALUES.get(filter_name, {})
    args = []
    for pname in req:
        # All five curated required params are string type; the bundle
        # default is never enabled, so any const String satisfies the
        # `required` arg. Prefer the runtime SAMPLE_VALUES when available.
        val = samples.get(pname, "")
        args.append(f"{_param_dart_name(pname)}: '{val}'")
    return f"{cls}({', '.join(args)})"






def _emit_chain() -> str:
    """The chain model: the sealed [AudioEffect] base every generated
    `XxxEffect` extends, [RawAudioEffect] for hand-written lavfi entries,
    and the internal functions that turn an ordered effect list into the
    `af` chain and diff two lists into live `af-command` updates.

    Labels are per instance, `aek_<filter>_<n>` with n the occurrence of
    that filter in the list (disabled entries count too), so a filter keeps
    its label, its af-metadata and its tap when the user toggles or
    reorders the others."""
    base = _NAMING.bundle_name[:-1]  # AudioEffect
    cmd = _NAMING.command_type
    pfx = _NAMING.chain_label_prefix
    w = _NAMING.wire_word
    n = _NAMING.noun
    return f"""
/// One stage of the {n} effects chain: an entry of the ordered list given
/// to `Player.{_NAMING.setter}`. Stages run in list order, and the same
/// filter may appear more than once.
///
/// Every typed `XxxEffect` extends it; [Raw{base}] carries a lavfi
/// entry written by hand.
sealed class {base} {{
  const {base}();

  /// Whether this stage is applied. `false` keeps it in the list, with
  /// its settings, without inserting it in the chain.
  bool get enabled;

  /// The lavfi filter this stage runs, e.g. `equalizer`.
  String get filterName;

  /// The filter this stage runs, as a typed identifier (`null` for a
  /// [Raw{base}]).
  {_NAMING.enum_name}? get filter;

  /// The chain entry for this stage.
  String toFilterString();

  /// Runtime-tunable option diff against [prev], the same filter one
  /// step earlier: the `(option, wire value)` pairs the live graph can
  /// apply via `{w}-command`, or `null` when the change needs a rebuild.
  List<(String, String)>? _runtimeDiff(covariant {base} prev) =>
      this == prev ? const [] : null;
}}

/// A chain stage written as a raw lavfi entry, for filters or option
/// forms the typed effects do not cover, e.g.
/// `Raw{base}('lavfi-aeval=val(0)*0.5|val(1)*0.5')`.
///
/// It is inserted as is, without a chain label, so it is never updated
/// live: any change rebuilds the chain.
final class Raw{base} extends {base} {{
  /// Creates a raw chain stage from [entry].
  const Raw{base}(this.entry, {{this.enabled = true}});

  /// The lavfi entry, inserted verbatim.
  final String entry;

  @override
  final bool enabled;

  @override
  String get filterName {{
    final start = entry.startsWith('lavfi-') ? 'lavfi-'.length : 0;
    final end = entry.indexOf('=', start);
    return entry.substring(start, end < 0 ? entry.length : end);
  }}

  @override
  {_NAMING.enum_name}? get filter => null;

  @override
  String toFilterString() => entry;

  /// Returns a copy with the given fields replaced.
  Raw{base} copyWith({{String? entry, bool? enabled}}) =>
      Raw{base}(entry ?? this.entry, enabled: enabled ?? this.enabled);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Raw{base} && other.entry == entry && other.enabled == enabled);

  @override
  int get hashCode => Object.hash(entry, enabled);

  @override
  String toString() => 'Raw{base}($entry, enabled: $enabled)';
}}

/// One incremental `{w}-command` update produced by [{n}EffectsDiff]:
/// applies [option] = [value] to the live chain stage labelled [label]
/// (an instance of the ffmpeg filter [filterName]).
typedef {cmd} = ({{String label, String option, String value, String filterName}});

/// The chain label of the [instance]th [filterName] stage in a list
/// (0 for the first), e.g. `{pfx}_equalizer_1`.
@internal
String {n}EffectLabel(String filterName, int instance) =>
    '{pfx}_${{filterName}}_$instance';

/// The chain labels of [effects], in order; `null` for raw stages,
/// which carry none.
@internal
List<String?> {n}EffectLabels(List<{base}> effects) {{
  final seen = <String, int>{{}};
  return [
    for (final e in effects)
      if (e is Raw{base})
        null
      else
        {n}EffectLabel(
          e.filterName,
          seen.update(e.filterName, (i) => i + 1, ifAbsent: () => 0),
        ),
  ];
}}

/// The `{w}` chain for [effects]: every enabled stage in list order,
/// typed stages under their [{n}EffectLabels]. A blank raw stage is
/// skipped, since an empty chain entry is a syntax error for mpv.
@internal
String {n}EffectsChain(List<{base}> effects) {{
  final labels = {n}EffectLabels(effects);
  return [
    for (var i = 0; i < effects.length; i++)
      if (effects[i].enabled &&
          effects[i].toFilterString().trim().isNotEmpty)
        labels[i] == null
            ? effects[i].toFilterString()
            : '@${{labels[i]}}:${{effects[i].toFilterString()}}',
  ].join(',');
}}

/// The incremental `{w}-command` updates that turn the live chain built
/// from [prev] into the one for [next], or `null` when only a rebuild
/// can: a stage was added, removed, reordered, enabled or disabled, a
/// non-runtime-tunable option changed, or the filter takes no live
/// commands. Empty when the two lists build the same chain.
@internal
List<{cmd}>? {n}EffectsDiff(List<{base}> prev, List<{base}> next) {{
  if (prev.length != next.length) return null;
  final labels = {n}EffectLabels(next);
  final out = <{cmd}>[];
  for (var i = 0; i < next.length; i++) {{
    final a = prev[i];
    final b = next[i];
    if (identical(a, b)) continue;
    if (a.runtimeType != b.runtimeType || a.enabled != b.enabled) return null;
    if (b is Raw{base}) {{
      if (a != b) return null;
      continue;
    }}
    if (!b.enabled) continue;
    final d = b._runtimeDiff(a);
    if (d == null) return null;
    for (final (option, value) in d) {{
      out.add((
        label: labels[i]!,
        option: option,
        value: value,
        filterName: b.filterName,
      ));
    }}
  }}
  return out;
}}
"""


# Populated by main(); read by _emit_settings_class for enum default
# resolution (we need the int → member-name mapping when the C source
# declares e.g. `{.i64=0}` as the default of an `enum` param).
_ENUM_LOOKUP: dict[str, list[dict]] = {}


def _emit_extensions(src_path: Path) -> str:
    """Re-emit the hand-maintained typed string-/map-DSL helpers with
    the AUTO-GENERATED banner. The decoder logic lives in the shared
    `static/` dir (or a consumer-specific override path) — never in
    the consumer repo. Drift against the generated *Settings classes
    is caught by `flutter analyze` after codegen."""
    src = src_path.read_text()
    # Drop the source file's own leading comment block; _COPYRIGHT (which
    # carries the AUTO-GENERATED line) replaces it.
    lines = src.splitlines(keepends=True)
    i = 0
    while i < len(lines) and (
        lines[i].lstrip().startswith("//") or lines[i].strip() == ""
    ):
        i += 1
    return _COPYRIGHT + "\n" + "".join(lines[i:])


def run(config: Config) -> int:
    """Read the schema produced by parse.run() and emit every Dart
    output configured in [config]. Returns 0 on success."""
    global _WIRE, _EMIT_LABELS, _EMIT_DIFF, _NAMING, _ENUMS_IMPORT
    _WIRE = config.wire
    _EMIT_LABELS = config.features.emit_af_labels
    _EMIT_DIFF = config.features.emit_diff_commands
    _NAMING = config.naming
    _ENUMS_IMPORT = config.output.enums.name

    schema = json.loads(config.output.schema.read_text())
    filters: dict = schema["filters"]
    sorted_names = sorted(filters.keys())
    # Build the global enum lookup before any class emission so per-filter
    # default resolution can map an int default → enum member name.
    _ENUM_LOOKUP.clear()
    for fname in sorted_names:
        for enum_id, members in filters[fname]["enums"].items():
            _ENUM_LOOKUP[enum_id] = members

    # File 1: enums (no Freezed, no part directive — pure Dart enums).
    # Includes the singular `AudioEffect` filter-id enum at the end so
    # the directory doesn't accumulate near-identical filenames
    # (`audio_effect.dart` vs `audio_effects.dart`).
    enum_pieces: list[str] = [_emit_enums_header()]
    seen_enums: set[str] = set()
    for fname in sorted_names:
        for enum_id, members in filters[fname]["enums"].items():
            if enum_id in seen_enums or not members:
                continue
            seen_enums.add(enum_id)
            option = next(
                (
                    pn
                    for pn, p in {
                        **filters[fname]["params"],
                        **filters[fname].get("params_invalid", {}),
                    }.items()
                    if p.get("enum_id") == enum_id
                ),
                None,
            )
            enum_pieces.append(_emit_enum(enum_id, members, fname, option))
    enum_pieces.append(_emit_audio_effect_enum(sorted_names))
    config.output.enums.parent.mkdir(parents=True, exist_ok=True)
    config.output.enums.write_text("\n".join(enum_pieces))

    # File 2: settings + AudioEffects bundle + AudioEffectsX.active
    # extension. Imports the enums file for typed enum / flags param
    # fields and for the singular `AudioEffect` enum used by the
    # extension.
    settings_bodies: list[str] = []
    for fname in sorted_names:
        settings_bodies.append(_emit_settings_class(fname, filters[fname]))
    settings_bodies.insert(0, _emit_chain())
    # The Set/Map equality helpers are emitted only when a field uses them, so a
    # flavor with neither (video) doesn't trip `unused_element`.
    _body = "\n".join(settings_bodies)
    settings_pieces: list[str] = [
        _emit_settings_header(
            needs_set="_setEq(" in _body,
            needs_map="_mapEq(" in _body,
        ),
        *settings_bodies,
    ]
    config.output.settings.parent.mkdir(parents=True, exist_ok=True)
    config.output.settings.write_text("\n".join(settings_pieces))

    written: list[Path] = [config.output.enums, config.output.settings]

    # File 2b (optional): typed string-/map-DSL extension helpers,
    # re-emitted verbatim from the codegen's static source so the
    # consumer repo carries no hand-written decoder logic.
    if config.features.emit_extensions:
        assert config.output.extensions is not None
        assert config.extensions_source is not None
        config.output.extensions.parent.mkdir(parents=True, exist_ok=True)
        config.output.extensions.write_text(
            _emit_extensions(config.extensions_source)
        )
        written.append(config.output.extensions)

    # File 3: test-side filter manifest. Contains only the lavfi filter
    # names — no enums, no settings, no link to the public API.
    config.output.test_filter_names.parent.mkdir(parents=True, exist_ok=True)
    config.output.test_filter_names.write_text(
        _emit_test_filter_names(sorted_names)
    )
    written.append(config.output.test_filter_names)

    for path in written:
        try:
            subprocess.run(
                ["dart", "format", str(path)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"WARN: `dart format` failed for {path}", file=sys.stderr)

    # `dart format` does NOT add the trailing commas that
    # `require_trailing_commas` wants on the lines it splits, so a strict
    # consumer would flag the emitted code. Apply that single fix in place.
    # Scoped to the generated directories (which hold only generated files),
    # so no hand-written source is touched. No-op when the consumer doesn't
    # enable the lint.
    for gen_dir in sorted({str(p.parent) for p in written}):
        try:
            subprocess.run(
                [
                    "dart", "fix", "--apply",
                    "--code=require_trailing_commas", gen_dir,
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except (FileNotFoundError, subprocess.CalledProcessError):
            print(f"WARN: `dart fix` failed for {gen_dir}", file=sys.stderr)
    for path, label in [
        (config.output.enums, f"{len(seen_enums)} enums"),
        (config.output.settings,
         f"{len(sorted_names)} effects + the chain model"),
        *(
            [(config.output.extensions, "typed string-/map-DSL helpers")]
            if config.features.emit_extensions else []
        ),
        (config.output.test_filter_names,
         f"{len(sorted_names)} filter names"),
    ]:
        try:
            rel = path.relative_to(config.consumer_root)
        except ValueError:
            rel = path
        print(f"Wrote {rel} ({label})", file=sys.stderr)
    return 0
