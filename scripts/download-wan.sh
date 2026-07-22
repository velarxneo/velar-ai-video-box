#!/usr/bin/env bash
set -euo pipefail

COMFYUI_DIR="${COMFYUI_DIR:-/opt/comfyui}"
DOWNLOADER="/opt/velar/scripts/download-model.sh"

echo "Velar WAN downloader"

if [ -z "${WAN_MODEL_URL:-}" ]; then
  echo "WAN_MODEL_URL is not set."
  echo "Add it as a Salad environment variable."
  exit 1
fi

WAN_MODEL_NAME="${WAN_MODEL_NAME:-wan_model.safetensors}"

bash "$DOWNLOADER" \
  "$WAN_MODEL_URL" \
  "$COMFYUI_DIR/models/diffusion_models" \
  "$WAN_MODEL_NAME"

if [ -n "${WAN_VAE_URL:-}" ]; then
  bash "$DOWNLOADER" \
    "$WAN_VAE_URL" \
    "$COMFYUI_DIR/models/vae" \
    "${WAN_VAE_NAME:-wan_vae.safetensors}"
fi

if [ -n "${WAN_TEXT_ENCODER_URL:-}" ]; then
  bash "$DOWNLOADER" \
    "$WAN_TEXT_ENCODER_URL" \
    "$COMFYUI_DIR/models/text_encoders" \
    "${WAN_TEXT_ENCODER_NAME:-wan_text_encoder.safetensors}"
fi

echo "WAN downloads completed."
