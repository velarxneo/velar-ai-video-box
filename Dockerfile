FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    COMFYUI_DIR=/opt/comfyui \
    COMFYUI_PORT=8188

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
    && git lfs install \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI.git \
    comfyui

WORKDIR /opt/comfyui

RUN python -m pip install --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

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

WORKDIR /opt/comfyui/custom_nodes

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI-Manager.git

RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

RUN git clone --depth 1 \
    https://github.com/city96/ComfyUI-GGUF.git

RUN git clone --depth 1 \
    https://github.com/kijai/ComfyUI-WanVideoWrapper.git

RUN git clone --depth 1 \
    https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git

RUN set -eux; \
    for requirements_file in /opt/comfyui/custom_nodes/*/requirements.txt; do \
      if [ -f "$requirements_file" ]; then \
        pip install --no-cache-dir -r "$requirements_file"; \
      fi; \
    done

COPY scripts /opt/velar/scripts

RUN chmod +x /opt/velar/scripts/*.sh \
    && mkdir -p \
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
      /opt/comfyui/input \
      /opt/comfyui/output \
      /opt/comfyui/user/default/workflows

WORKDIR /opt/comfyui

EXPOSE 8188

HEALTHCHECK --interval=30s --timeout=5s --start-period=120s --retries=5 \
  CMD curl --fail "http://localhost:8188/" || exit 1

CMD ["/opt/velar/scripts/start.sh"]
