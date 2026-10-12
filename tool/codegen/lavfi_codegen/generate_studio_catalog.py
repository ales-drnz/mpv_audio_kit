#!/usr/bin/env python3
"""Standalone target: emit the **logical filter catalog** for the MPV Studio
showcase app (the sibling `mpv_studio` package).

This emits DATA, not widgets: one `filter_catalog.dart` describing every
non-featured audio filter as a `FilterDescriptor` — its identity, its editable
parameters (each a typed `ParamSpec` carrying range / options + get/set
closures over one chain stage, an `AudioEffect`), its category, and (for the
required-param "advanced" filters) curated presets. The app renders all of it
generically (a single `FilterCard` / `ParamControl` renderer), so every visual
decision lives in the app and the generated artifact stays reusable.

Per-parameter control mapping (decided by the app's renderer from the type):
    double / int  →  slider          enum  →  dropdown
    bool          →  switch          string/chlayout  →  text field

The hand-written "Featured" effects (bespoke visualisers) are excluded.
Idempotent. Runs `dart format` on the emitted file.
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from pathlib import Path

from .config import PACKAGE_ROOT, Config, WireConfig
from .generate import (
    _bundle_default_ctor,
    _param_dart_name,
    _settings_class_name,
    effect_params,
)
from .required_params import (
    ADVANCED_FILTERS,
    FILE_BACKED_PARAM,
    PRESETS,
    required_for,
)

_WIRE: WireConfig = WireConfig()
_ENUM: str = "AudioFilter"

ADVANCED_SET = set(ADVANCED_FILTERS)

# Display title + Material icon (sans `Icons.`) for each advanced filter's
# dedicated page / grid tile.
ADVANCED_META = {
    "chorus": ("Chorus", "graphic_eq_rounded"),
    "pan": ("Channel mixer", "tune_rounded"),
    "channelmap": ("Channel remap", "swap_horiz_rounded"),
    "aeval": ("Custom expression", "functions_rounded"),
    "arnndn": ("AI noise reduction", "auto_fix_high_rounded"),
}

# Curated "Featured" modules hand-written in MPV Studio's rack — excluded from
# the generated catalog so each effect has one canonical home.
FEATURED = {
    "acompressor", "bass", "treble", "crossfeed", "crystalizer",
    "extrastereo", "asubboost", "loudnorm", "superequalizer",
}

# (slug, class-suffix [unused], title, icon-without-suffix, [filters]). The
# required-param "advanced" filters live on their own pages, NOT in these
# lists, so every category is "safe" for a bulk Enable-all.
CATEGORIES = [
    ("dynamics", "Dynamics", "Dynamics and loudness", "compress", [
        "acompressor", "acontrast", "adrc", "adynamicequalizer",
        "adynamicsmooth", "agate", "alimiter", "apsyclip", "asoftclip",
        "compand", "deesser", "drmeter", "dynaudnorm", "ebur128",
        "loudnorm", "mcompand", "speechnorm",
    ]),
    ("eq", "Equalization", "Equalization and tone", "equalizer", [
        "anequalizer", "asubboost", "atilt", "bass", "biquad",
        "equalizer", "firequalizer", "highshelf", "lowshelf",
        "superequalizer", "tiltshelf", "treble",
    ]),
    ("cut_pass", "CutPass", "Filters", "tune", [
        "allpass", "asubcut", "asupercut", "asuperpass",
        "asuperstop", "bandpass", "bandreject", "highpass", "lowpass",
    ]),
    ("pitch_time", "PitchTime", "Pitch, tempo and time", "speed", [
        "afreqshift", "aphaseshift", "aresample", "asetrate", "atempo",
        "rubberband",
    ]),
    ("stereo", "Stereo", "Stereo, channels and spatial", "surround_sound", [
        "crossfeed", "dialoguenhance", "earwax", "extrastereo", "haas",
        "stereotools", "stereowiden", "surround", "virtualbass",
    ]),
    ("modulation", "Modulation", "Modulation and creative", "auto_fix_high", [
        "acrusher", "aecho", "aemphasis", "aexciter", "aphaser",
        "apulsator", "crystalizer", "dcshift", "flanger", "hdcd",
        "tremolo", "vibrato",
    ]),
    ("denoise", "Denoise", "Denoise and restoration", "graphic_eq", [
        "adeclick", "adeclip", "adecorrelate", "adelay", "adenorm",
        "aderivative", "aintegral", "afftdn", "afwtdn", "anlmdn",
        "compensationdelay",
    ]),
    ("utility", "Utility", "Spectral, fade and routing", "science", [
        "afftfilt", "aiir", "afade", "apad", "silenceremove", "aformat",
    ]),
]

_ICON_MAP = {
    "compress": "compress_rounded",
    "equalizer": "equalizer_rounded",
    "tune": "tune_rounded",
    "speed": "speed_rounded",
    "surround_sound": "surround_sound_rounded",
    "auto_fix_high": "auto_fix_high_rounded",
    "graphic_eq": "graphic_eq_rounded",
    "science": "science_rounded",
}

DART_RESERVED = {
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




def _field_name(name: str) -> str:
    return name + "_" if name in DART_RESERVED else name




def _normalise_double(raw: str) -> str:
    raw = str(raw).strip()
    m = re.match(r"^(-?\d+(?:\.\d*)?(?:[eE][-+]?\d+)?)[fF]$", raw)
    if m:
        raw = m.group(1)
    # Dart needs a digit before the decimal point: `.4` → `0.4`, `-.4` → `-0.4`.
    if raw.startswith("."):
        raw = "0" + raw
    elif raw.startswith("-."):
        raw = "-0" + raw[1:]
    if raw.endswith("."):
        return raw + "0"
    if "." in raw or "e" in raw or "E" in raw:
        return raw
    return raw + ".0"


def _dstr(s: str) -> str:
    """A single-quoted Dart string literal (escapes \\, $, ')."""
    return "'" + s.replace("\\", "\\\\").replace("$", "\\$").replace("'", "\\'") + "'"


# ── Logical emission: param → ParamSpec, filter → FilterDescriptor ──────────


def _param_spec(cls, pname, p, ptype, required_set):
    """One editable param → a `ParamSpec` Dart literal with get/set closures
    over one stage of the chain (an `AudioEffect` of class [cls]), or None
    if it has no usable control."""
    if p.get("readonly"):
        return None
    dn = _param_dart_name(pname)
    label = _dstr(pname)
    slot = f"(e as {cls})"
    get = f"(e) => {slot}.{dn}"
    set_ = f"(e, v) => {slot}.copyWith({dn}: v)"

    if ptype in ("double", "int"):
        if p.get("default") is None or p.get("min") is None or p.get("max") is None:
            return None
        try:
            d, mn, mx = float(p["default"]), float(p["min"]), float(p["max"])
        except (TypeError, ValueError):
            return None
        if d < mn or d > mx or mn >= mx:
            return None
        # Unbounded sentinel ranges (e.g. INT64_MAX) make no usable slider —
        # and the int literal would overflow Dart's 64-bit int. Skip them.
        if abs(mn) > 1e12 or abs(mx) > 1e12:
            return None
        if ptype == "int":
            return (f"IntParam({label}, min: {int(mn)}, max: {int(mx)}, "
                    f"def: {int(d)}, get: {get}, set: {set_})")
        lmin = _normalise_double(p["min"])
        lmax = _normalise_double(p["max"])
        ldef = _normalise_double(p["default"])
        return (f"DoubleParam({label}, min: {lmin}, max: {lmax}, "
                f"def: {ldef}, get: {get}, set: {set_})")

    if ptype == "enum":
        enum_id = p.get("enum_id")
        if not enum_id:
            return None
        getter = _WIRE.value_getter
        options = (f"[for (final o in {enum_id}.values) "
                   f"(label: o.{getter}, value: o as Object)]")
        set_e = f"(e, v) => {slot}.copyWith({dn}: v as {enum_id})"
        return f"EnumParam({label}, options: {options}, get: {get}, set: {set_e})"

    if ptype == "bool":
        if p.get("default") is None:
            return None
        return f"BoolParam({label}, get: {get}, set: {set_})"

    if ptype in ("string", "chlayout"):
        nullable = pname not in required_set and p.get("default") is None
        get_s = f"(e) => {slot}.{dn}" + (" ?? ''" if nullable else "")
        req = "true" if pname in required_set else "false"
        return f"StringParam({label}, required: {req}, get: {get_s}, set: {set_})"

    return None


def _filter_descriptor(name, fdata, category, advanced, required_set):
    cls = _settings_class_name(name)
    dflt = _bundle_default_ctor(name)
    specs = []
    for pname, p in effect_params(fdata).items():
        spec = _param_spec(cls, pname, p, p.get("type"), required_set)
        if spec is not None:
            specs.append("      " + spec + ",")
    params_block = "\n".join(specs)

    if advanced:
        title, icon = ADVANCED_META.get(name, (name, "tune_rounded"))
    else:
        title, icon = name, "tune_rounded"
    file_param = FILE_BACKED_PARAM.get(name)

    preset_lines = []
    if advanced:
        for pn, values in PRESETS.get(name, []):
            kv = ", ".join(f"{_dstr(k)}: {_dstr(v)}" for k, v in values.items())
            preset_lines.append(f"      (name: {_dstr(pn)}, values: {{{kv}}}),")
    presets_block = "\n".join(preset_lines)

    return f"""  FilterDescriptor(
    name: {_dstr(name)},
    title: {_dstr(title)},
    wire: {_dstr(_WIRE.label_prefix + name)},
    category: {_dstr(category)},
    advanced: {str(advanced).lower()},
    icon: Icons.{icon},
    fileBacked: {str(file_param is not None).lower()},
    fileParam: {_dstr(file_param) if file_param else 'null'},
    params: [
{params_block}
    ],
    presets: [
{presets_block}
    ],
    filter: {_ENUM}.{_field_name(name)},
    create: () => const {dflt},
    setEnabled: (e, on) => (e as {cls}).copyWith(enabled: on),
  ),"""


def _emit_catalog(descriptors_block, categories_block):
    return f"""// Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
// All rights reserved.
// Use of this source code is governed by BSD 3-Clause license that can be
// found in the LICENSE file.
//
// AUTO-GENERATED by lavfi-codegen (studio_catalog) — do not edit by hand.
//
// The LOGICAL filter catalog: pure data + typed get/set adapters over one
// stage of the effects chain (an [AudioEffect]) — NO widgets. The app renders all of it generically
// (see FilterCard / ParamControl), so every visual decision lives in the app
// and this artifact stays reusable by any consumer.

import 'package:flutter/material.dart';
import 'package:mpv_audio_kit/mpv_audio_kit.dart';

/// One editable filter parameter. Subclasses carry the type-specific range /
/// options plus typed get/set closures over one stage of the chain.
sealed class ParamSpec {{
  final String name;
  const ParamSpec(this.name);
}}

class DoubleParam extends ParamSpec {{
  final double min;
  final double max;
  final double def;
  final double Function(AudioEffect) get;
  final AudioEffect Function(AudioEffect, double) set;
  DoubleParam(super.name,
      {{required this.min,
      required this.max,
      required this.def,
      required this.get,
      required this.set}});
}}

class IntParam extends ParamSpec {{
  final int min;
  final int max;
  final int def;
  final int Function(AudioEffect) get;
  final AudioEffect Function(AudioEffect, int) set;
  IntParam(super.name,
      {{required this.min,
      required this.max,
      required this.def,
      required this.get,
      required this.set}});
}}

class BoolParam extends ParamSpec {{
  final bool Function(AudioEffect) get;
  final AudioEffect Function(AudioEffect, bool) set;
  BoolParam(super.name, {{required this.get, required this.set}});
}}

class EnumParam extends ParamSpec {{
  final List<({{String label, Object value}})> options;
  final Object? Function(AudioEffect) get;
  final AudioEffect Function(AudioEffect, Object) set;
  EnumParam(super.name,
      {{required this.options, required this.get, required this.set}});
}}

class StringParam extends ParamSpec {{
  final bool required;
  final String Function(AudioEffect) get;
  final AudioEffect Function(AudioEffect, String) set;
  StringParam(super.name,
      {{required this.required, required this.get, required this.set}});
}}

/// A curated preset for an advanced filter: a friendly name + the mandatory
/// option values it sets (every value validated to init in ffmpeg).
typedef FilterPreset = ({{String name, Map<String, String> values}});

/// The logical description of one audio filter: identity, editable [params],
/// bypass get/set, plus (for advanced filters) curated [presets]. Everything
/// an app needs to render and drive it — no widgets.
class FilterDescriptor {{
  final String name;
  final String title;
  final String wire;
  final String category;
  final bool advanced;
  final IconData icon;
  final bool fileBacked;
  final String? fileParam;
  final List<ParamSpec> params;
  final List<FilterPreset> presets;
  /// The filter, to find its stages in a chain (`e.filter == filter`).
  final AudioFilter filter;
  /// A new stage of this filter, every param at its default.
  final AudioEffect Function() create;
  /// The same stage, bypassed or not.
  final AudioEffect Function(AudioEffect, bool) setEnabled;
  FilterDescriptor({{
    required this.name,
    required this.title,
    required this.wire,
    required this.category,
    required this.advanced,
    required this.icon,
    required this.fileBacked,
    required this.fileParam,
    required this.params,
    required this.presets,
    required this.filter,
    required this.create,
    required this.setEnabled,
  }});
}}

/// One filter category (navigation): slug + display + icon.
class FilterCategory {{
  final String slug;
  final String title;
  final IconData icon;
  const FilterCategory(
      {{required this.slug, required this.title, required this.icon}});
}}

/// Every non-featured filter, as logical data. Featured effects are
/// hand-written in the app; advanced (required-param) filters carry
/// `advanced: true` + presets and render on their own page.
final List<FilterDescriptor> kFilterCatalog = [
{descriptors_block}
];

/// Categories that hold at least one (non-advanced) filter.
const List<FilterCategory> kFilterCategories = [
{categories_block}
];
"""


def _resolve_studio_root() -> Path:
    override = os.environ.get("MPV_STUDIO_ROOT")
    candidates = []
    if override:
        candidates.append(Path(override).resolve())
    candidates.append((PACKAGE_ROOT.parent / "mpv_studio").resolve())
    for cand in candidates:
        pubspec = cand / "pubspec.yaml"
        if pubspec.is_file():
            for line in pubspec.read_text().splitlines():
                if line.startswith("name:") and line.split(":", 1)[1].strip() == "mpv_studio":
                    return cand
    raise SystemExit(
        "cannot locate the mpv_studio repo. Set MPV_STUDIO_ROOT=/abs/path "
        "or check it out next to mpv_audio_kit."
    )


def run(config: Config) -> int:
    global _WIRE, _ENUM
    _WIRE = config.wire
    _ENUM = config.naming.enum_name

    studio_root = _resolve_studio_root()
    out_dir = studio_root / "lib" / "generated"
    out_dir.mkdir(parents=True, exist_ok=True)

    schema = json.loads(config.output.schema.read_text())
    filters = schema["filters"]

    # filter name -> category slug; + ordered category metadata.
    cat_slug_of = {}
    cat_meta = []  # (slug, title, icon_dart)
    for slug, _suffix, title, icon, names in CATEGORIES:
        cat_meta.append((slug, title, _ICON_MAP[icon]))
        for n in names:
            cat_slug_of[n] = slug

    descriptors = []
    cat_counts: dict[str, int] = {}
    n_advanced = 0
    for name in sorted(filters):
        if name in FEATURED:
            continue  # hand-written Featured rack
        fdata = filters[name]
        advanced = name in ADVANCED_SET
        required_set = required_for(name)
        if advanced:
            category = "advanced"
            n_advanced += 1
        else:
            category = cat_slug_of.get(name)
            if category is None:
                continue  # not placed in any category
            cat_counts[category] = cat_counts.get(category, 0) + 1
        descriptors.append(
            _filter_descriptor(name, fdata, category, advanced, required_set))

    descriptors_block = "\n".join(descriptors)
    cat_lines = [
        f"  FilterCategory(slug: {_dstr(slug)}, title: {_dstr(title)}, "
        f"icon: Icons.{icon}),"
        for slug, title, icon in cat_meta
        if cat_counts.get(slug, 0) > 0
    ]
    categories_block = "\n".join(cat_lines)

    out_path = out_dir / "filter_catalog.dart"
    out_path.write_text(_emit_catalog(descriptors_block, categories_block))

    # Drop the old widget-based generated files (superseded by the data
    # catalog the app now renders generically).
    stale = ["catalog.dart", "advanced.dart"] + [
        f"filters_{slug}.dart" for slug, *_ in CATEGORIES
    ]
    for old in stale:
        (out_dir / old).unlink(missing_ok=True)

    try:
        subprocess.run(
            ["dart", "format", str(out_path)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except (FileNotFoundError, subprocess.CalledProcessError):
        print(f"WARN: `dart format` failed for {out_path}", file=sys.stderr)

    try:
        rel = out_path.relative_to(studio_root)
    except ValueError:
        rel = out_path
    print(
        f"Wrote {rel} ({len(descriptors)} filters, "
        f"{len(cat_lines)} categories, {n_advanced} advanced)",
        file=sys.stderr,
    )
    return 0
