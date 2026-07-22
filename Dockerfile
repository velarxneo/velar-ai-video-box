FROM ghcr.io/lecode-official/comfyui-docker:latest

USER root

# ----------------------------------------------------
# System packages
# ----------------------------------------------------
RUN apt-get update && apt-get install -y \
    git \
    wget \
    curl \
    ffmpeg \
    unzip \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# ----------------------------------------------------
# Python packages
# ----------------------------------------------------
RUN pip install --no-cache-dir \
    onnx \
    onnxruntime-gpu \
    imageio \
    imageio-ffmpeg \
    moviepy \
    opencv-python-headless \
    accelerate \
    transformers \
    sentencepiece \
    protobuf \
    safetensors \
    einops \
    xformers

# ----------------------------------------------------
# Custom Nodes
# ----------------------------------------------------
WORKDIR /opt/comfyui/custom_nodes

RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git

RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git

RUN git clone https://github.com/cubiq/ComfyUI_Impact_Pack.git

RUN git clone https://github.com/city96/ComfyUI-GGUF.git

RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper.git

RUN git clone https://github.com/Kosinkadink/ComfyUI-Advanced-ControlNet.git

# ----------------------------------------------------
# Install node requirements
# ----------------------------------------------------
RUN find /opt/comfyui/custom_nodes -name requirements.txt \
    -exec pip install --no-cache-dir -r {} \;

# ----------------------------------------------------
# Create model folders
# ----------------------------------------------------
RUN mkdir -p \
    /opt/comfyui/models/checkpoints \
    /opt/comfyui/models/unet \
    /opt/comfyui/models/vae \
    /opt/comfyui/models/controlnet \
    /opt/comfyui/models/loras \
    /opt/comfyui/models/clip \
    /opt/comfyui/models/text_encoders \
    /opt/comfyui/models/upscale_models \
    /opt/comfyui/models/clip_vision \
    /opt/comfyui/models/diffusion_models \
    /opt/comfyui/models/vae_approx

WORKDIR /opt/comfyui

EXPOSE 8188

CMD ["python","main.py","--listen","::","--port","8188"]
