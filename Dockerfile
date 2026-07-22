FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

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

RUN git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /opt/comfyui

RUN python -m pip install --upgrade pip setuptools wheel

RUN pip install --no-cache-dir -r requirements.txt

# ----------------------------------------------------
# Core Python packages
# ----------------------------------------------------
RUN pip install --no-cache-dir \
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
# Install Custom Nodes
# ----------------------------------------------------
WORKDIR /opt/comfyui/custom_nodes

# ComfyUI Manager
RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI-Manager.git

# Video Helper Suite
RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

# GGUF Loader
RUN git clone --depth 1 \
    https://github.com/city96/ComfyUI-GGUF.git

# Wan Video Wrapper
RUN git clone --depth 1 \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git

# Advanced ControlNet
RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git

# ----------------------------------------------------
# Install requirements for every node
# ----------------------------------------------------
RUN find /opt/comfyui/custom_nodes -name requirements.txt \
    -exec pip install --no-cache-dir -r {} \;

# ----------------------------------------------------
# Create folders
# ----------------------------------------------------
RUN mkdir -p \
    /opt/comfyui/models/checkpoints \
    /opt/comfyui/models/unet \
    /opt/comfyui/models/diffusion_models \
    /opt/comfyui/models/clip \
    /opt/comfyui/models/text_encoders \
    /opt/comfyui/models/vae \
    /opt/comfyui/models/vae_approx \
    /opt/comfyui/models/clip_vision \
    /opt/comfyui/models/controlnet \
    /opt/comfyui/models/loras \
    /opt/comfyui/models/upscale_models \
    /opt/comfyui/models/embeddings \
    /opt/comfyui/models/style_models \
    /opt/comfyui/input \
    /opt/comfyui/output \
    /opt/comfyui/user/default/workflows

# ----------------------------------------------------
# Launch
# ----------------------------------------------------
WORKDIR /opt/comfyui

EXPOSE 8188

CMD ["python","main.py","--listen","::","--port","8188"]
