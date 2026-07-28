#!/usr/bin/env bash

set -e

echo "========================================"
echo " Velar AI Video Box v6 Installer"
echo "========================================"
echo

echo "[1/7] Updating system..."
sudo apt-get update

echo "[2/7] Installing system packages..."
sudo apt-get install -y \
    git \
    git-lfs \
    ffmpeg \
    curl \
    wget \
    unzip \
    ca-certificates \
    build-essential \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1

git lfs install

echo "[3/7] Cloning ComfyUI..."

if [ ! -d "/workspace/ComfyUI" ]; then
    git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git /workspace/ComfyUI
else
    echo "ComfyUI already exists."
fi

echo "[4/7] Installing Python requirements..."

cd /workspace/ComfyUI

python3 -m pip install --upgrade pip setuptools wheel

python3 -m pip install -r requirements.txt

echo "[5/7] Installing ComfyUI Manager..."

if [ ! -d "custom_nodes/ComfyUI-Manager" ]; then
    git clone \
        --depth 1 \
        https://github.com/Comfy-Org/ComfyUI-Manager.git \
        custom_nodes/ComfyUI-Manager
fi

python3 -m pip install \
    -r custom_nodes/ComfyUI-Manager/requirements.txt

echo "[6/7] Installation complete."

echo

echo "[7/7] Next step"

echo

echo "Run:"
echo

echo "./launch.sh"

echo

echo "========================================"
