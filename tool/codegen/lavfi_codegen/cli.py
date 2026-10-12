"""Single command-line entry point for the lavfi codegen pipeline.

Run from tool/codegen (tool/codegen/regen.sh does)::

    python3 -m lavfi_codegen --config mpv_audio_kit.toml all

Stages:
    parse      → C-source → schema.json
    generate   → schema.json → Dart effect classes + enums + extensions
    tests      → schema.json → coverage + param-corner Dart tests
    studio_catalog → schema.json → mpv_studio's filter catalog (not in `all`)
    runtime    → ffmpeg -h filter → schema_runtime.json
    diff       → runtime ↔ C-source diff (also runs `runtime`)
    audit      → highlight string params needing hand-written extensions
    all        → parse + generate + tests + diff + audit
                 (each optional stage is skipped when its feature flag
                 is off or its output path is unset)

Picks the right stages based on the consumer's feature flags; nothing
re-runs that the config didn't ask for.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import audit_string_params, generate, generate_studio_catalog
from . import generate_tests
from . import parse, parse_from_help
from .config import Config, load_config


STAGES = (
    "parse", "generate", "tests", "studio_catalog",
    "runtime", "diff", "audit", "all",
)


def _do(stage: str, config: Config, *, ffmpeg: str | None = None) -> int:
    """Run a single stage. ``stage='all'`` runs the canonical sequence.
    Optional stages (tests/catalog) silently skip when their feature
    flag is off; required stages always run."""
    if stage == "parse":
        return parse.run(config)
    if stage == "generate":
        return generate.run(config)
    if stage == "tests":
        if not config.features.emit_tests:
            print("tests: features.emit_tests = false → skipped", file=sys.stderr)
            return 0
        return generate_tests.run(config)
    if stage == "studio_catalog":
        # Standalone target: emits MPV Studio-styled filter cards into the
        # sibling `mpv_studio` package. Not part of `all`.
        return generate_studio_catalog.run(config)
    if stage == "runtime":
        return parse_from_help.run(config, ffmpeg=ffmpeg, diff_mode=False)
    if stage == "diff":
        return parse_from_help.run(config, ffmpeg=ffmpeg, diff_mode=True)
    if stage == "audit":
        return audit_string_params.run(config)
    if stage == "all":
        for s in ("parse", "generate", "tests"):
            rc = _do(s, config, ffmpeg=ffmpeg)
            if rc != 0:
                return rc
        # Diff is best-effort — surface failures but don't gate the run.
        try:
            _do("diff", config, ffmpeg=ffmpeg)
        except SystemExit as e:
            print(f"diff: {e}", file=sys.stderr)
        try:
            _do("audit", config, ffmpeg=ffmpeg)
        except Exception as e:  # noqa: BLE001 — audit is informational
            print(f"audit: {e}", file=sys.stderr)
        return 0
    sys.exit(f"unknown stage: {stage} (pick one of {STAGES})")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(
        prog="lavfi_codegen",
        description="FFmpeg lavfi → typed Dart bindings codegen.",
    )
    ap.add_argument(
        "--config",
        required=True,
        type=Path,
        help="Path to the consumer's codegen.toml",
    )
    ap.add_argument(
        "--ffmpeg",
        default=None,
        help="Override the ffmpeg binary used by the runtime parser "
        "(default: $PATH lookup).",
    )
    ap.add_argument(
        "stage",
        choices=STAGES,
        default="all",
        nargs="?",
        help="Which stage to run. Default: all.",
    )
    args = ap.parse_args(argv)
    config = load_config(args.config)
    return _do(args.stage, config, ffmpeg=args.ffmpeg)


if __name__ == "__main__":
    sys.exit(main())
