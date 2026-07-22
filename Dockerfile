FROM pytorch/pytorch:2.9.1-cuda12.8-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ffmpeg \
    curl \
    wget \
    ca-certificates \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

RUN git clone --depth 1 https://github.com/Comfy-Org/ComfyUI.git comfyui

WORKDIR /opt/comfyui

RUN pip install --upgrade pip setuptools wheel \
    && pip install -r requirements.txt

RUN git clone --depth 1 \
    https://github.com/Comfy-Org/ComfyUI-Manager.git \
    /opt/comfyui/custom_nodes/ComfyUI-Manager \
    && if [ -f /opt/comfyui/custom_nodes/ComfyUI-Manager/requirements.txt ]; then \
         pip install -r /opt/comfyui/custom_nodes/ComfyUI-Manager/requirements.txt; \
       fi

EXPOSE 8188

CMD ["python", "/opt/comfyui/main.py", "--listen", "::", "--port", "8188"]
