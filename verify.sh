#!/usr/bin/env bash

set -euo pipefail

echo "========================================"
echo " Velar AI Video Box Verification"
echo "========================================"
echo

echo "[1/5] Python"

python3 --version

echo
echo "[2/5] Git"

git --version

echo
echo "[3/5] NVIDIA"

nvidia-smi

echo
echo "[4/5] ComfyUI"

if [ -d "/workspace/ComfyUI" ]; then
    echo "✓ ComfyUI installed"
else
    echo "✗ ComfyUI not installed"
fi

echo
echo "[5/5] Manager"

if [ -d "/workspace/ComfyUI/custom_nodes/ComfyUI-Manager" ]; then
    echo "✓ ComfyUI Manager installed"
else
    echo "✗ Manager not installed"
fi

echo
echo "Verification complete."
