from __future__ import annotations

import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))

from download_model import load_manifest
from utils import sha256, verify_file


class ManifestTests(unittest.TestCase):
    def write_manifest(self, directory: Path, model: dict[str, object]) -> Path:
        path = directory / "pack.json"
        path.write_text(
            json.dumps({"id": "pack", "models": [model]}), encoding="utf-8"
        )
        return path

    def test_loads_generic_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = self.write_manifest(
                Path(temporary),
                {
                    "filename": "model.bin",
                    "folder": "checkpoints",
                    "url": "https://example.com/model.bin",
                    "required": True,
                },
            )
            manifest_id, models = load_manifest(path)
            self.assertEqual(manifest_id, "pack")
            self.assertEqual(models[0].folder, "checkpoints")

    def test_rejects_path_traversal(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = self.write_manifest(
                Path(temporary),
                {
                    "filename": "../model.bin",
                    "folder": "checkpoints",
                    "url": "https://example.com/model.bin",
                },
            )
            with self.assertRaisesRegex(ValueError, "Unsafe model path"):
                load_manifest(path)


class VerificationTests(unittest.TestCase):
    def test_checksum_and_size(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "model.bin"
            path.write_bytes(b"velar")
            valid, _ = verify_file(
                path, expected_sha256=sha256(path), expected_size=5
            )
            self.assertTrue(valid)

    def test_rejects_empty_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "model.bin"
            path.touch()
            valid, reason = verify_file(path)
            self.assertFalse(valid)
            self.assertEqual(reason, "file is empty")


if __name__ == "__main__":
    unittest.main()
