"""Single command-line entry point for the lavfi codegen pipeline.

Run from tool/codegen (tool/codegen/regen.sh does)::

    python3 -m lavfi_codegen --config mpv_audio_kit.toml all

Stages:
    parse      → C-source → schema.json
    generate   → schema.json → Dart effect classes + enums + extensions
    tests      → schema.json → coverage + param-corner Dart tests
    studio_catalog → schema.json → mpv_studio's filter catalog (not in `all`)
    all        → parse + generate + tests
                 (tests is skipped when its feature flag is off)

Picks the right stages based on the consumer's feature flags; nothing
re-runs that the config didn't ask for.
"""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from . import generate, generate_studio_catalog
from . import generate_tests
from . import parse
from .config import Config, load_config


STAGES = ("parse", "generate", "tests", "studio_catalog", "all")


def _do(stage: str, config: Config) -> int:
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
    if stage == "all":
        for s in ("parse", "generate", "tests"):
            rc = _do(s, config)
            if rc != 0:
                return rc
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
        "stage",
        choices=STAGES,
        default="all",
        nargs="?",
        help="Which stage to run. Default: all.",
    )
    args = ap.parse_args(argv)
    config = load_config(args.config)
    return _do(args.stage, config)


if __name__ == "__main__":
    sys.exit(main())
