#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="${VELAR_MANIFESTS:-wan22}"

echo "Velar bootstrap: installing custom nodes"
python "${SCRIPT_DIR}/install_nodes.py"

read -r -a manifest_args <<< "${MANIFESTS//,/ }"
if [[ ${#manifest_args[@]} -eq 0 ]]; then
  echo "VELAR_MANIFESTS must contain at least one manifest ID" >&2
  exit 2
fi

echo "Velar bootstrap: installing models (${manifest_args[*]})"
python "${SCRIPT_DIR}/download_model.py" "${manifest_args[@]}"

echo "Velar bootstrap: verifying models"
python "${SCRIPT_DIR}/download_model.py" --verify-only "${manifest_args[@]}"

exec python "${SCRIPT_DIR}/start_comfyui.py"
