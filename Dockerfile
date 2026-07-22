FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_PATH=/opt/comfyui

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    git-lfs \
    ffmpeg \
    curl \
    wget \
    ca-certificates \
    libgl1 \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender1 \
    && rm -rf /var/lib/apt/lists/*

RUN git lfs install

WORKDIR /opt

# Install ComfyUI
RUN git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /opt/comfyui

RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

# ComfyUI Manager
RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    custom_nodes/ComfyUI-Manager

# Video import/export nodes
RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git \
    custom_nodes/ComfyUI-VideoHelperSuite

# GGUF model support
RUN git clone --depth 1 \
    https://github.com/city96/ComfyUI-GGUF.git \
    custom_nodes/ComfyUI-GGUF

# Image detailer and detector nodes
RUN git clone --depth 1 \
    https://github.com/ltdrdata/ComfyUI-Impact-Pack.git \
    custom_nodes/ComfyUI-Impact-Pack

RUN git clone --depth 1 \
    https://github.com/ltdrdata/ComfyUI-Impact-Subpack.git \
    custom_nodes/ComfyUI-Impact-Subpack

# WAN video workflow nodes
RUN git clone --depth 1 \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git \
    custom_nodes/ComfyUI-WanVideoWrapper

# Install custom-node Python requirements when provided
RUN set -eux; \
    for requirements in custom_nodes/*/requirements.txt; do \
        if [ -f "$requirements" ]; then \
            echo "Installing $requirements"; \
            pip install -r "$requirements"; \
        fi; \
    done

# Create common model and output directories
RUN mkdir -p \
    models/checkpoints \
    models/diffusion_models \
    models/unet \
    models/text_encoders \
    models/clip \
    models/vae \
    models/loras \
    models/controlnet \
    models/upscale_models \
    models/ultralytics \
    input \
    output \
    user/default/workflows

EXPOSE 8188

CMD ["python", "/opt/comfyui/main.py", "--listen", "::", "--port", "8188"]
