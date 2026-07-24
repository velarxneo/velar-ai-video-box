# Velar AI Video Box

Velar is a configuration-driven bootstrap layer for ComfyUI. At container
startup it installs declared custom nodes, installs and verifies declared model
files, and then launches ComfyUI.

## Configuration

Model packs live in `manifests/<id>.json`. Select one or more packs with a
comma-separated environment variable:

```text
VELAR_MANIFESTS=wan22
VELAR_MANIFESTS=flux,qwen
```

Adding a pack requires only another manifest; the Python installer contains no
model-specific URLs. A model entry supports:

```json
{
  "filename": "model.safetensors",
  "folder": "diffusion_models",
  "url": "https://example.com/model.safetensors",
  "required": true,
  "sha256": "optional-64-character-checksum",
  "size": 123456789
}
```

`sha256` and `size` are optional, but production manifests should provide at
least a SHA-256 checksum. Without either value, verification can only prove
that the downloaded file is non-empty.

Custom nodes are declared in `custom_nodes.json`. Missing repositories are
cloned and their `requirements.txt` files are installed. Failures stop startup
for required entries and are logged for optional entries.

## Persistence on SaladCloud

Bootstrap makes restarts unattended; persistent storage makes them fast. Mount
a persistent volume and point Velar at it:

```text
VELAR_MODELS_DIR=/data/models
VELAR_CUSTOM_NODES_DIR=/data/custom_nodes
```

ComfyUI must also see those locations. The simplest deployment is to mount the
persistent directories directly at `/opt/comfyui/models` and
`/opt/comfyui/custom_nodes`, which are Velar's defaults.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `VELAR_MANIFESTS` | `wan22` | Comma-separated model pack IDs |
| `VELAR_MODELS_DIR` | `/opt/comfyui/models` | Model installation root |
| `VELAR_CUSTOM_NODES_DIR` | `/opt/comfyui/custom_nodes` | Node installation root |
| `VELAR_DOWNLOAD_RETRIES` | `4` | Download attempts |
| `VELAR_DOWNLOAD_TIMEOUT` | `300` | Per-read timeout in seconds |
| `VELAR_LOG_LEVEL` | `INFO` | Python log level |
| `COMFYUI_LISTEN` | `::` | ComfyUI bind address (IPv6, required by Salad ingress) |
| `COMFYUI_PORT` | `8188` | ComfyUI port |
| `COMFYUI_ARGS` | empty | Additional ComfyUI arguments |

## Local commands

With the bootstrap requirements installed:

```bash
python scripts/install_nodes.py
python scripts/download_model.py wan22
python scripts/download_model.py --verify-only wan22
python scripts/start_comfyui.py
```

The Docker health check reports ready after ComfyUI responds on its HTTP port.
