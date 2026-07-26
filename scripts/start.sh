#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

echo "Velar bootstrap: installing custom nodes"
python "${SCRIPT_DIR}/install_nodes.py"

exec python "${SCRIPT_DIR}/start_comfyui.py"
