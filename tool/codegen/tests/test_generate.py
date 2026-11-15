# Copyright © 2026 & onwards, Alessandro Di Ronza <ales.drnz@gmail.com>.
# All rights reserved.
# Use of this source code is governed by BSD 3-Clause license that can be found in the LICENSE file.

"""The generator's output for five filters of the schema, against golden
files: a change to an emitter shows up here as a diff of the Dart it
writes, before the full regeneration.

The fixture (fixtures/schema.json) is a frozen piece of the schema the
parse stage writes: acompressor (enums, doubles, live options), aeval
(a required option), afade (durations and ints), compand (a `params`
map with digit-prefix options) and ebur128 (flags). The output is
compared before `dart format`, so the goldens hold the generator's
own text and do not depend on the Dart SDK.

Run from tool/codegen:

    python3 -m unittest discover -s tests -t .

After an intended change of the output, rewrite the goldens with
UPDATE_GOLDEN=1 and review their diff.
"""
from __future__ import annotations

import dataclasses
import os
import tempfile
import unittest
from pathlib import Path
from unittest import mock

from lavfi_codegen import generate, generate_tests
from lavfi_codegen.config import SHARED_ROOT, load_config

HERE = Path(__file__).resolve().parent
GOLDEN = HERE / "golden"
FIXTURE = HERE / "fixtures" / "schema.json"


def _config(out: Path):
    """The package's config, with every output in [out], the fixture as
    the schema, and no copy of the hand-written extensions."""
    config = load_config(SHARED_ROOT / "mpv_audio_kit.toml")
    paths = {
        f.name: out / getattr(config.output, f.name).name
        for f in dataclasses.fields(config.output)
        if getattr(config.output, f.name) is not None
    }
    paths["schema"] = FIXTURE
    paths["extensions"] = None
    return dataclasses.replace(
        config,
        output=dataclasses.replace(config.output, **paths),
        features=dataclasses.replace(config.features, emit_extensions=False),
    )


class GeneratorOutputTest(unittest.TestCase):
    maxDiff = None

    def test_output_matches_the_goldens(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp)
            config = _config(out)
            # No dart format or dart fix: the goldens are the raw output.
            with mock.patch("subprocess.run"), mock.patch(
                "sys.stderr", new=open(os.devnull, "w")
            ) as devnull:
                try:
                    self.assertEqual(generate.run(config), 0)
                    self.assertEqual(generate_tests.run(config), 0)
                finally:
                    devnull.close()
            written = sorted(
                (p for p in out.rglob("*") if p.is_file()),
                key=lambda p: str(p.relative_to(out)),
            )
            self.assertTrue(written)
            if os.environ.get("UPDATE_GOLDEN"):
                for p in GOLDEN.rglob("*.golden"):
                    p.unlink()
                for p in written:
                    g = GOLDEN / (str(p.relative_to(out)) + ".golden")
                    g.parent.mkdir(parents=True, exist_ok=True)
                    g.write_text(p.read_text())
            goldens = sorted(
                str(p.relative_to(GOLDEN)).removesuffix(".golden")
                for p in GOLDEN.rglob("*.golden")
            )
            self.assertEqual(
                [str(p.relative_to(out)) for p in written], goldens,
                "the generator writes other files than the goldens",
            )
            for p in written:
                rel = str(p.relative_to(out))
                with self.subTest(file=rel):
                    expected = (GOLDEN / (rel + ".golden")).read_text()
                    self.assertEqual(
                        p.read_text(), expected,
                        f"{rel} differs from its golden"
                        " (UPDATE_GOLDEN=1 rewrites it)",
                    )


class EnumMemberNameTest(unittest.TestCase):
    def test_ffmpeg_names_become_dart_identifiers(self):
        cases = {
            "peak": "peak",
            "50fm": "n50fm",
            "true": "true_",
            "lr>l+r": "lrToLPlusR",
            "lr>l-r": "lrToLMinusR",
            "": "valueUnknown",
        }
        for ffmpeg, dart in cases.items():
            with self.subTest(ffmpeg=ffmpeg):
                self.assertEqual(generate._enum_member_dart_name(ffmpeg), dart)


if __name__ == "__main__":
    unittest.main()
