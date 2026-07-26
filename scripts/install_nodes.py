"""Install custom nodes declared in custom_nodes.json."""

from __future__ import annotations

import argparse
import logging
import subprocess
import sys
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from utils import configure_logging, env_path, load_json

LOGGER = logging.getLogger("velar.nodes")
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def run(command: list[str], description: str) -> None:
    LOGGER.info("%s", description)
    subprocess.run(command, check=True)


def install_node(node: Any, root: Path) -> None:
    if not isinstance(node, dict) or not node.get("name") or not node.get("repo"):
        raise ValueError("Each custom node needs 'name' and 'repo'")
    name, repo = str(node["name"]), str(node["repo"])
    if not isinstance(node.get("required", True), bool):
        raise ValueError(f"'required' must be a boolean for custom node {name}")
    if Path(name).name != name or urlparse(repo).scheme not in {"http", "https"}:
        raise ValueError(f"Unsafe custom node definition: {name}")
    destination = root / name
    if destination.exists():
        if not (destination / ".git").exists():
            raise RuntimeError(f"{destination} exists but is not a Git checkout")
        LOGGER.info("Custom node already installed: %s", name)
    else:
        run(["git", "clone", "--depth", "1", repo, str(destination)], f"Installing {name}")
    requirements = destination / "requirements.txt"
    if requirements.is_file():
        run(
            [sys.executable, "-m", "pip", "install", "-r", str(requirements)],
            f"Installing requirements for {name}",
        )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", type=Path)
    parser.add_argument("--nodes-root", type=Path)
    args = parser.parse_args()
    configure_logging()
    config = (args.config or env_path("VELAR_NODES_CONFIG", PROJECT_ROOT / "custom_nodes.json")).resolve()
    root = (args.nodes_root or env_path("VELAR_CUSTOM_NODES_DIR", "/opt/comfyui/custom_nodes")).resolve()
    root.mkdir(parents=True, exist_ok=True)
    nodes = load_json(config).get("nodes")
    if not isinstance(nodes, list):
        raise ValueError(f"{config} needs a 'nodes' list")
    for node in nodes:
        required = node.get("required", True) if isinstance(node, dict) else True
        try:
            install_node(node, root)
        except (OSError, subprocess.CalledProcessError, RuntimeError, ValueError):
            if required is False:
                LOGGER.exception("Optional custom node failed: %s", node.get("name", "unknown"))
                continue
            raise
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
