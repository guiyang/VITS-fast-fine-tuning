# Base image
FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# Setting some environment variables to suppress warnings
ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="/opt/conda/bin:${PATH}"

# Install necessary Ubuntu packages, Python, pip, Anaconda and other tools
RUN apt-get update && apt-get install -y \
    software-properties-common \
    wget \
    unzip \
    build-essential \
    libopenblas-base \
    libopenblas-dev \
    libgfortran5 && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && apt-get install -y \
    python3.8 \
    python3.8-dev \
    python3.8-distutils \
    python3-pip && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1 && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    python3 -m pip install --upgrade pip && \
    pip config set global.timeout 120 && \
    pip config set global.retries 28 && \
    pip config set global.cache-dir /tmp/pip-cache && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-py38_23.5.0-3-Linux-x86_64.sh && \
    bash Miniconda3-py38_23.5.0-3-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-py38_23.5.0-3-Linux-x86_64.sh && \
    conda install -y pytorch torchvision torchaudio pytorch-cuda=11.7 -c pytorch -c nvidia && \
    conda install -y numpy=1.21.6 scipy=1.5.2 tensorboard -c conda-forge

# Set working directory
WORKDIR /app

# Copy requirements.txt and install requirements
COPY ./requirements.txt .
RUN while read line; do pip install --no-cache-dir --progress-bar=on $line && echo "$line installed."; done < requirements.txt

# Copy app source to working directory
COPY ./ /app

# Run the setup and data download commands
RUN mkdir pretrained_models video_data raw_audio denoised_audio custom_character_voice segmented_character_voice && \
    cd monotonic_align && \
    mkdir monotonic_align && \
    python setup.py build_ext --inplace && \
    cd .. && \
    wget https://huggingface.co/datasets/Plachta/sampled_audio4ft/resolve/main/sampled_audio4ft_v2.zip && \
    unzip sampled_audio4ft_v2.zip && \
    wget https://huggingface.co/spaces/Plachta/VITS-Umamusume-voice-synthesizer/resolve/main/pretrained_models/D_trilingual.pth -O ./pretrained_models/D_0.pth
