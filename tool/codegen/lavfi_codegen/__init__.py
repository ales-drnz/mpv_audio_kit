"""lavfi-codegen — generate typed Dart bindings from FFmpeg lavfi
filter sources.

Lives in mpv_audio_kit's tool/codegen and generates its typed audio
effects API (lib/src/generated) and tests (test/generated), plus
mpv_studio's filter catalog. Configured by the TOML files next to it.

Public entry points are in :mod:`lavfi_codegen.cli` and the dataclass
in :mod:`lavfi_codegen.config`. Each stage (parse / generate /
generate_tests / parse_from_help / audit) is also importable on its
own — see the module docstrings.
"""
from __future__ import annotations

__version__ = "0.1.0"
