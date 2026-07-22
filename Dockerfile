FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_PATH=/opt/comfyui

# ----------------------------------------------------
# System packages
# ----------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
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
    libxrender1 \
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------
# Install ComfyUI
# ----------------------------------------------------
WORKDIR /opt

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI.git \
    comfyui

WORKDIR /opt/comfyui

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# ----------------------------------------------------
# Install core Python packages
# ----------------------------------------------------
# Do not install xformers, SageAttention or Flash Attention yet.
# These need careful version matching with PyTorch and CUDA.
RUN pip install --no-cache-dir \
    onnx \
    onnxruntime-gpu \
    accelerate \
    transformers \
    sentencepiece \
    protobuf \
    safetensors \
    einops \
    imageio \
    imageio-ffmpeg \
    moviepy \
    opencv-python-headless

# ----------------------------------------------------
# Install custom nodes
# ----------------------------------------------------
WORKDIR /opt/comfyui/custom_nodes

# ComfyUI Manager
RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    ComfyUI-Manager

# Video loading and export
RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    ComfyUI-VideoHelperSuite

# GGUF model support
RUN git clone --depth 1 \
    https://github.com/city96/ComfyUI-GGUF.git \
    ComfyUI-GGUF

# FaceDetailer, detectors and image enhancement
RUN git clone --depth 1 \
    https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
    ComfyUI-Impact-Pack

RUN git clone --depth 1 \
    https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git \
    ComfyUI-Impact-Subpack

# WAN video support
RUN git clone --depth 1 \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
    ComfyUI-WanVideoWrapper

# Advanced ControlNet scheduling and masking
RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git \
    ComfyUI-Advanced-ControlNet

# ----------------------------------------------------
# Install custom-node requirements
# ----------------------------------------------------
RUN set -eux; \
    for requirements_file in /opt/comfyui/custom_nodes/*/requirements.txt; do \
        if [ -f "$requirements_file" ]; then \
            echo "Installing: $requirements_file"; \
            pip install --no-cache-dir -r "$requirements_file"; \
        fi; \
    done

# ----------------------------------------------------
# Create model, workflow and output folders
# ----------------------------------------------------
RUN mkdir -p \
    /opt/comfyui/models/checkpoints \
    /opt/comfyui/models/diffusion_models \
    /opt/comfyui/models/unet \
    /opt/comfyui/models/vae \
    /opt/comfyui/models/vae_approx \
    /opt/comfyui/models/loras \
    /opt/comfyui/models/controlnet \
    /opt/comfyui/models/clip \
    /opt/comfyui/models/clip_vision \
    /opt/comfyui/models/text_encoders \
    /opt/comfyui/models/upscale_models \
    /opt/comfyui/models/ultralytics \
    /opt/comfyui/input \
    /opt/comfyui/output \
    /opt/comfyui/user/default/workflows

# ----------------------------------------------------
# Start ComfyUI for Salad's IPv6 Container Gateway
# ----------------------------------------------------
WORKDIR /opt/comfyui

EXPOSE 8188

CMD ["python", "/opt/comfyui/main.py", "--listen", "::", "--port", "8188"]
