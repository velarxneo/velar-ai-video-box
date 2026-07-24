"""Install and verify model files declared by Velar manifests."""

from __future__ import annotations

import argparse
import logging
import os
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

import requests
from tqdm import tqdm

from utils import configure_logging, env_path, load_json, verify_file

LOGGER = logging.getLogger("velar.models")
PROJECT_ROOT = Path(__file__).resolve().parent.parent


@dataclass(frozen=True)
class Model:
    filename: str
    folder: str
    url: str
    required: bool = True
    sha256: str | None = None
    size: int | None = None

    @classmethod
    def from_dict(cls, value: Any, source: Path) -> "Model":
        if not isinstance(value, dict):
            raise ValueError(f"Model entries in {source} must be objects")
        required_fields = ("filename", "folder", "url")
        missing = [field for field in required_fields if not value.get(field)]
        if missing:
            raise ValueError(f"Model in {source} is missing: {', '.join(missing)}")
        filename = str(value["filename"])
        folder = str(value["folder"])
        if Path(filename).name != filename or Path(folder).is_absolute() or ".." in Path(folder).parts:
            raise ValueError(f"Unsafe model path in {source}: {folder}/{filename}")
        url = str(value["url"])
        if urlparse(url).scheme not in {"http", "https"}:
            raise ValueError(f"Unsupported model URL in {source}: {url}")
        checksum = value.get("sha256")
        if checksum and (len(str(checksum)) != 64 or any(c not in "0123456789abcdefABCDEF" for c in str(checksum))):
            raise ValueError(f"Invalid SHA-256 for {filename} in {source}")
        size = value.get("size")
        if size is not None and (not isinstance(size, int) or size <= 0):
            raise ValueError(f"Invalid size for {filename} in {source}")
        required = value.get("required", True)
        if not isinstance(required, bool):
            raise ValueError(f"'required' must be a boolean for {filename} in {source}")
        return cls(
            filename=filename,
            folder=folder,
            url=url,
            required=required,
            sha256=str(checksum) if checksum else None,
            size=size,
        )


def load_manifest(path: Path) -> tuple[str, list[Model]]:
    data = load_json(path)
    manifest_id = data.get("id")
    models = data.get("models")
    if not isinstance(manifest_id, str) or not manifest_id:
        raise ValueError(f"Manifest {path} needs a non-empty 'id'")
    if not isinstance(models, list) or not models:
        raise ValueError(f"Manifest {path} needs a non-empty 'models' list")
    return manifest_id, [Model.from_dict(item, path) for item in models]


def download(model: Model, destination: Path, retries: int, timeout: int) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    partial = destination.with_name(f"{destination.name}.part")

    for attempt in range(1, retries + 1):
        resume_at = partial.stat().st_size if partial.exists() else 0
        headers = {"Range": f"bytes={resume_at}-"} if resume_at else {}
        try:
            with requests.get(
                model.url, headers=headers, stream=True, timeout=(15, timeout)
            ) as response:
                if resume_at and response.status_code != 206:
                    LOGGER.info("Server cannot resume %s; restarting", model.filename)
                    partial.unlink(missing_ok=True)
                    resume_at = 0
                response.raise_for_status()
                content_length = int(response.headers.get("content-length", 0))
                total = content_length + resume_at if content_length else model.size
                mode = "ab" if resume_at else "wb"
                with partial.open(mode) as stream, tqdm(
                    total=total,
                    initial=resume_at,
                    unit="B",
                    unit_scale=True,
                    desc=model.filename,
                ) as progress:
                    for chunk in response.iter_content(chunk_size=1024 * 1024):
                        if chunk:
                            stream.write(chunk)
                            progress.update(len(chunk))

            valid, reason = verify_file(
                partial, expected_sha256=model.sha256, expected_size=model.size
            )
            if not valid:
                partial.unlink(missing_ok=True)
                raise RuntimeError(reason)
            partial.replace(destination)
            return
        except (requests.RequestException, OSError, RuntimeError) as exc:
            if attempt == retries:
                raise RuntimeError(
                    f"Failed to download {model.filename} after {retries} attempts: {exc}"
                ) from exc
            delay = min(2 ** (attempt - 1), 30)
            LOGGER.warning(
                "Download attempt %d/%d failed for %s: %s; retrying in %ds",
                attempt, retries, model.filename, exc, delay,
            )
            time.sleep(delay)


def process_manifest(
    path: Path, models_root: Path, verify_only: bool, retries: int, timeout: int
) -> bool:
    manifest_id, models = load_manifest(path)
    LOGGER.info("%s manifest %s", "Verifying" if verify_only else "Installing", manifest_id)
    success = True
    for model in models:
        destination = models_root / model.folder / model.filename
        valid, reason = verify_file(
            destination, expected_sha256=model.sha256, expected_size=model.size
        )
        if valid:
            LOGGER.info("Verified %s", destination)
            continue
        if verify_only:
            log = LOGGER.error if model.required else LOGGER.warning
            log("%s: %s", destination, reason)
            success = success and not model.required
            continue
        LOGGER.info("Installing %s (%s)", destination, reason)
        try:
            download(model, destination, retries, timeout)
        except RuntimeError:
            if model.required:
                raise
            LOGGER.exception("Optional model installation failed: %s", model.filename)
    return success


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("manifests", nargs="+", help="Manifest IDs or JSON paths")
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--models-root", type=Path)
    parser.add_argument("--manifest-dir", type=Path)
    parser.add_argument("--retries", type=int, default=int(os.getenv("VELAR_DOWNLOAD_RETRIES", "4")))
    parser.add_argument("--timeout", type=int, default=int(os.getenv("VELAR_DOWNLOAD_TIMEOUT", "300")))
    return parser.parse_args()


def main() -> int:
    configure_logging()
    args = parse_args()
    if args.retries < 1 or args.timeout < 1:
        raise ValueError("Retries and timeout must be positive")
    models_root = (args.models_root or env_path("VELAR_MODELS_DIR", "/opt/comfyui/models")).resolve()
    manifest_dir = (args.manifest_dir or env_path("VELAR_MANIFEST_DIR", PROJECT_ROOT / "manifests")).resolve()
    success = True
    for value in args.manifests:
        candidate = Path(value)
        path = candidate if candidate.suffix == ".json" else manifest_dir / f"{value}.json"
        success = process_manifest(path.resolve(), models_root, args.verify_only, args.retries, args.timeout) and success
    return 0 if success else 1


if __name__ == "__main__":
    raise SystemExit(main())
