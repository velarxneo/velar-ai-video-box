#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/comfyui}"

mkdir -p \
  "$COMFYUI_DIR/models/checkpoints" \
  "$COMFYUI_DIR/models/diffusion_models" \
  "$COMFYUI_DIR/models/text_encoders" \
  "$COMFYUI_DIR/models/clip" \
  "$COMFYUI_DIR/models/vae" \
  "$COMFYUI_DIR/models/loras" \
  "$COMFYUI_DIR/models/controlnet" \
  "$COMFYUI_DIR/input" \
  "$COMFYUI_DIR/output" \
  "$COMFYUI_DIR/user/default/workflows"

exec python "$COMFYUI_DIR/main.py" \
  --listen "::" \
  --port "${COMFYUI_PORT:-8188}"
