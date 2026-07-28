#!/usr/bin/env bash

set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/workspace/ComfyUI}"
HOST="${COMFYUI_HOST:-0.0.0.0}"
PORT="${COMFYUI_PORT:-8188}"

echo "========================================"
echo " Velar AI Video Box v6"
echo "========================================"
echo

if [ ! -d "$COMFYUI_DIR" ]; then
    echo "Error: ComfyUI was not found at:"
    echo "$COMFYUI_DIR"
    echo
    echo "Run ./install.sh first."
    exit 1
fi

if [ ! -f "$COMFYUI_DIR/main.py" ]; then
    echo "Error: main.py was not found in:"
    echo "$COMFYUI_DIR"
    exit 1
fi

echo "Starting ComfyUI"
echo "Directory: $COMFYUI_DIR"
echo "Address:   http://$HOST:$PORT"
echo

cd "$COMFYUI_DIR"

exec python3 main.py \
    --listen "$HOST" \
    --port "$PORT"
