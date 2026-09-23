"""Config for the lavfi codegen, which lives in mpv_audio_kit's tool/codegen.

One TOML per target (``tool/codegen/<target>.toml``). Paths resolve as:

* ``[inputs].manifest``   → relative to tool/codegen. The ``manifest.json``
  of the libmpv release the build hook pins (written by libmpv-scripts'
  write_manifest.sh, copied here by scripts/update_libmpv.sh): its
  ``audioFilters`` are the filters compiled into the binary, and its
  ``ffmpeg`` version picks the FFmpeg source parsed for their options.
* ``[output].schema`` /
  ``[output].schema_runtime`` → relative to tool/codegen (build products,
  git-ignored under .build/).
* every other ``[output].*`` → relative to the mpv_audio_kit package root.
* ``[extensions].source``    → a file in tool/codegen/static/.
"""
from __future__ import annotations

import json
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

try:
    import tomllib  # Python 3.11+
except ImportError:  # pragma: no cover - py<3.11 fallback
    import tomli as tomllib  # type: ignore


# tool/codegen (this file is tool/codegen/lavfi_codegen/config.py) and the
# package it generates into, two levels up.
SHARED_ROOT = Path(__file__).resolve().parent.parent
PACKAGE_ROOT = SHARED_ROOT.parent.parent


def read_manifest(manifest: Path) -> dict:
    if not manifest.is_file():
        sys.exit(f"libmpv manifest not found: {manifest} (run scripts/update_libmpv.sh)")
    return json.loads(manifest.read_text())


def resolve_whitelist(manifest: Path, key: str) -> list[str]:
    """The filters compiled into the pinned libmpv: ``manifest[key]``."""
    names = sorted({x.strip() for x in read_manifest(manifest).get(key, []) if x.strip()})
    if not names:
        sys.exit(f"No {key} in {manifest}")
    return names

# Hand-curated string-/map-DSL overlay files referenced by
# `[extensions].source` resolve here when a bare filename is given.
SHARED_STATIC_DIR = SHARED_ROOT / "static"


@dataclass(frozen=True)
class ConsumerInfo:
    """The package the codegen writes into (its pubspec `name:`)."""

    name: str


@dataclass(frozen=True)
class WireConfig:
    label_prefix: str = "lavfi-"
    accessor: str = "mpv"  # "mpv" | "ffmpeg"

    @property
    def value_getter(self) -> str:
        return "mpvValue" if self.accessor == "mpv" else "ffmpegValue"

    @property
    def from_method(self) -> str:
        return "fromMpv" if self.accessor == "mpv" else "fromFfmpeg"


@dataclass(frozen=True)
class NamingConfig:
    """Domain-specific Dart identifiers + doc nouns. Defaults reproduce the
    historical audio output verbatim; the video consumer overrides them so the
    one generator serves both flavors. ``[naming]`` in codegen.toml."""

    enum_name: str = "AudioEffect"          # singular filter-id enum
    bundle_name: str = "AudioEffects"       # plural settings bundle
    noun: str = "audio"                     # "{noun} filter" in docs
    wire_word: str = "af"                   # af / vf chain + command word
    whitelist_const: str = "AUDIO_FILTERS"  # whitelist name referenced in docs
    test_names_const: str = "kAudioFilterNames"
    sentinel_import: str = "../internals/unset_sentinel.dart"
    command_type: str = "AfCommand"         # incremental-update record type
    chain_label_prefix: str = "aek"         # per-slot chain label (@aek_<field>:)

    @property
    def bundle_ext(self) -> str:  # AudioEffectsX
        return self.bundle_name + "X"

    @property
    def setter(self) -> str:  # setAudioEffects
        return "set" + self.bundle_name

    @property
    def updater(self) -> str:  # updateAudioEffects
        return "update" + self.bundle_name


@dataclass(frozen=True)
class FeatureFlags:
    emit_extensions: bool = False
    emit_filter_catalog: bool = False
    emit_tests: bool = True
    emit_example_pages: bool = False
    # `@label:` chain syntax and runtime-diff commands are mpv-`af`
    # specific — they would corrupt the wire format of consumers that
    # feed raw ffmpeg filter strings. Off unless the consumer opts in.
    emit_af_labels: bool = False
    emit_diff_commands: bool = False
    # Generate from the runtime (`ffmpeg -h filter=`) schema rather than the
    # C-source AVOption parse. The C-source parser is tuned to the audio
    # filters' option-table patterns and yields no params for the video
    # filters; runtime introspection covers them. Set for the video consumer.
    params_from_runtime: bool = False


@dataclass(frozen=True)
class OutputPaths:
    """Every path absolute. ``schema`` / ``schema_runtime`` resolve
    against the shared repo; every other path resolves against the
    consumer Flutter pkg root."""

    enums: Path
    settings: Path
    test_filter_names: Path
    schema: Path
    test_coverage: Optional[Path] = None
    test_param_corners: Optional[Path] = None
    test_runtime: Optional[Path] = None
    test_af_command: Optional[Path] = None
    extensions: Optional[Path] = None
    filter_catalog: Optional[Path] = None
    example_pages_dir: Optional[Path] = None
    schema_runtime: Optional[Path] = None


@dataclass(frozen=True)
class Config:
    consumer: ConsumerInfo
    ffmpeg_source_dir: Path
    whitelist_file: Path
    whitelist_var: str
    wire: WireConfig
    features: FeatureFlags
    naming: NamingConfig
    output: OutputPaths
    extensions_source: Optional[Path] = None
    catalog_categories: list[tuple[str, str, list[str]]] = field(default_factory=list)
    consumer_root: Path = field(default_factory=lambda: Path("."))
    scripts_root: Path = field(default_factory=lambda: Path("."))


# ── Loading ─────────────────────────────────────────────────────────


def _package_name(root: Path) -> str:
    for line in (root / "pubspec.yaml").read_text().splitlines():
        if line.startswith("name:"):
            return line.split(":", 1)[1].strip()
    return ""


def load_config(toml_path: Path) -> Config:
    if not toml_path.is_file():
        sys.exit(f"codegen.toml not found: {toml_path}")
    data = tomllib.loads(toml_path.read_text())

    cdata = data.get("consumer") or {}
    if "name" not in cdata:
        sys.exit("codegen.toml [consumer]: missing key 'name'")
    consumer = ConsumerInfo(name=cdata["name"])
    if _package_name(PACKAGE_ROOT) != consumer.name:
        sys.exit(f"{PACKAGE_ROOT} is not the {consumer.name} package")
    consumer_root = PACKAGE_ROOT
    scripts_root = PACKAGE_ROOT

    idata = data.get("inputs") or {}
    whitelist_file = (SHARED_ROOT / idata.get("manifest", "libmpv_manifest.json")).resolve()
    whitelist_var = "audioFilters"
    ffmpeg_version = read_manifest(whitelist_file)["ffmpeg"]
    ffmpeg_source_dir = (SHARED_ROOT / ".ffmpeg-src" / f"ffmpeg-{ffmpeg_version}").resolve()

    widata = data.get("wire") or {}
    wire = WireConfig(
        label_prefix=widata.get("label_prefix", "lavfi-"),
        accessor=widata.get("accessor", "mpv"),
    )
    if wire.accessor not in ("mpv", "ffmpeg"):
        sys.exit(
            f"codegen.toml: [wire].accessor must be 'mpv' or 'ffmpeg', "
            f"got {wire.accessor!r}"
        )

    feat = data.get("features") or {}
    features = FeatureFlags(
        emit_extensions=bool(feat.get("emit_extensions", False)),
        emit_filter_catalog=bool(feat.get("emit_filter_catalog", False)),
        emit_tests=bool(feat.get("emit_tests", True)),
        emit_example_pages=bool(feat.get("emit_example_pages", False)),
        emit_af_labels=bool(feat.get("emit_af_labels", False)),
        emit_diff_commands=bool(feat.get("emit_diff_commands", False)),
        params_from_runtime=bool(feat.get("params_from_runtime", False)),
    )

    ndata = data.get("naming") or {}
    _naming_defaults = NamingConfig()
    naming = NamingConfig(
        enum_name=ndata.get("enum_name", _naming_defaults.enum_name),
        bundle_name=ndata.get("bundle_name", _naming_defaults.bundle_name),
        noun=ndata.get("noun", _naming_defaults.noun),
        wire_word=ndata.get("wire_word", _naming_defaults.wire_word),
        whitelist_const=ndata.get("whitelist_const", _naming_defaults.whitelist_const),
        test_names_const=ndata.get(
            "test_names_const", _naming_defaults.test_names_const
        ),
        sentinel_import=ndata.get("sentinel_import", _naming_defaults.sentinel_import),
        command_type=ndata.get("command_type", _naming_defaults.command_type),
        chain_label_prefix=ndata.get(
            "chain_label_prefix", _naming_defaults.chain_label_prefix
        ),
    )

    odata = data.get("output") or {}

    def _consumer_path(key: str) -> Optional[Path]:
        v = odata.get(key)
        return (consumer_root / v).resolve() if v else None

    def _shared_path(key: str, default_rel: Optional[str] = None) -> Optional[Path]:
        v = odata.get(key, default_rel)
        if v is None:
            return None
        p = Path(v)
        return p.resolve() if p.is_absolute() else (SHARED_ROOT / v).resolve()

    output = OutputPaths(
        enums=(consumer_root / odata["enums"]).resolve(),
        settings=(consumer_root / odata["settings"]).resolve(),
        test_filter_names=(consumer_root / odata["test_filter_names"]).resolve(),
        schema=_shared_path(
            "schema", f".build/{consumer.name}/schema.json"
        ),
        test_coverage=_consumer_path("test_coverage"),
        test_param_corners=_consumer_path("test_param_corners"),
        test_runtime=_consumer_path("test_runtime"),
        test_af_command=_consumer_path("test_af_command"),
        extensions=_consumer_path("extensions"),
        filter_catalog=_consumer_path("filter_catalog"),
        example_pages_dir=_consumer_path("example_pages_dir"),
        schema_runtime=_shared_path("schema_runtime"),
    )

    ext_src: Optional[Path] = None
    if features.emit_extensions:
        edata = data.get("extensions") or {}
        rel = edata.get("source")
        if rel:
            p = Path(rel)
            if p.is_absolute():
                ext_src = p
            else:
                ext_src = (SHARED_STATIC_DIR / p.name).resolve()
        else:
            ext_src = (SHARED_STATIC_DIR / "audio_effects_extensions.dart").resolve()
        if output.extensions is None:
            sys.exit(
                "codegen.toml: features.emit_extensions = true but "
                "[output].extensions is not set"
            )
        if not ext_src.is_file():
            sys.exit(
                f"codegen.toml: extensions source not found at {ext_src}"
            )

    catalog_categories: list[tuple[str, str, list[str]]] = []
    cat_data = (data.get("filter_catalog") or {}).get("category") or []
    for c in cat_data:
        catalog_categories.append(
            (c["id"], c["label"], list(c.get("filters", [])))
        )
    if features.emit_filter_catalog and not catalog_categories:
        sys.exit(
            "codegen.toml: features.emit_filter_catalog = true but no "
            "[[filter_catalog.category]] tables are defined"
        )
    if features.emit_filter_catalog and output.filter_catalog is None:
        sys.exit(
            "codegen.toml: features.emit_filter_catalog = true but "
            "[output].filter_catalog is not set"
        )
    if features.emit_example_pages and output.example_pages_dir is None:
        sys.exit(
            "codegen.toml: features.emit_example_pages = true but "
            "[output].example_pages_dir is not set"
        )

    return Config(
        consumer=consumer,
        ffmpeg_source_dir=ffmpeg_source_dir,
        whitelist_file=whitelist_file,
        whitelist_var=whitelist_var,
        wire=wire,
        features=features,
        naming=naming,
        output=output,
        extensions_source=ext_src,
        catalog_categories=catalog_categories,
        consumer_root=consumer_root,
        scripts_root=scripts_root,
    )
