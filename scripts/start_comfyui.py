"""Launch ComfyUI and propagate its exit status and signals."""

from __future__ import annotations

import logging
import os
import shlex
import subprocess
import sys

from utils import configure_logging, env_path

LOGGER = logging.getLogger("velar.launch")


def main() -> int:
    configure_logging()
    root = env_path("COMFYUI_ROOT", "/opt/comfyui")
    main_script = root / "main.py"
    if not main_script.is_file():
        LOGGER.error("ComfyUI entry point not found: %s", main_script)
        return 1
    host = os.getenv("COMFYUI_LISTEN", "0.0.0.0")
    port = os.getenv("COMFYUI_PORT", "8188")
    extra_args = shlex.split(os.getenv("COMFYUI_ARGS", ""))
    command = [sys.executable, str(main_script), "--listen", host, "--port", port, *extra_args]
    LOGGER.info("Launching ComfyUI on %s:%s", host, port)
    return subprocess.call(command, cwd=root)


if __name__ == "__main__":
    raise SystemExit(main())
