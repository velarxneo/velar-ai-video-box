"""Shared helpers for the Velar bootstrap scripts."""

from __future__ import annotations

import hashlib
import json
import logging
import os
from pathlib import Path
from typing import Any

LOGGER = logging.getLogger("velar")


def configure_logging() -> None:
    level = os.getenv("VELAR_LOG_LEVEL", "INFO").upper()
    logging.basicConfig(
        level=getattr(logging, level, logging.INFO),
        format="%(asctime)s | %(levelname)s | %(message)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
    )


def env_path(name: str, default: str | Path) -> Path:
    return Path(os.getenv(name, str(default))).expanduser().resolve()


def load_json(path: Path) -> dict[str, Any]:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError as exc:
        raise ValueError(f"Configuration file not found: {path}") from exc
    except json.JSONDecodeError as exc:
        raise ValueError(f"Invalid JSON in {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ValueError(f"Expected a JSON object in {path}")
    return data


def sha256(path: Path, chunk_size: int = 4 * 1024 * 1024) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(chunk_size), b""):
            digest.update(chunk)
    return digest.hexdigest()


def verify_file(
    path: Path, *, expected_sha256: str | None = None, expected_size: int | None = None
) -> tuple[bool, str]:
    if not path.is_file():
        return False, "file is missing"
    size = path.stat().st_size
    if size == 0:
        return False, "file is empty"
    if expected_size is not None and size != expected_size:
        return False, f"size mismatch (expected {expected_size}, got {size})"
    if expected_sha256:
        actual = sha256(path)
        if actual.lower() != expected_sha256.lower():
            return False, f"SHA-256 mismatch (expected {expected_sha256}, got {actual})"
    return True, "verified"
