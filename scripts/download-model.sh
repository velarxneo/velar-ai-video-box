#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo "Usage: $0 <URL> <destination-folder> <filename>"
  exit 1
fi

MODEL_URL="$1"
DESTINATION="$2"
FILENAME="$3"

mkdir -p "$DESTINATION"

AUTH_HEADER=()
if [ -n "${HF_TOKEN:-}" ]; then
  AUTH_HEADER=(--header="Authorization: Bearer ${HF_TOKEN}")
fi

echo "Downloading ${FILENAME}..."
wget \
  "${AUTH_HEADER[@]}" \
  --continue \
  --output-document="${DESTINATION}/${FILENAME}" \
  "${MODEL_URL}"

echo "Saved to ${DESTINATION}/${FILENAME}"
