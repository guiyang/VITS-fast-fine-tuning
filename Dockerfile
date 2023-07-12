FROM nvidia/cuda:12.2.0-base-ubuntu22.04

# Switch to Tencent Cloud mirror and install necessary packages
RUN apt-get update && \
    apt-get install -y python3 python3-pip wget unzip build-essential lsb-release libopenblas-base libopenblas-dev libgfortran5 gfortran && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    lsb_release -a

# Install pip and Anaconda
RUN python3 -m pip install --upgrade pip && \
    pip config set global.timeout 120 && \
    pip config set global.retries 28 && \
    pip config set global.cache-dir /tmp/pip-cache && \
    wget https://mirrors.tuna.tsinghua.edu.cn/anaconda/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda3-latest-Linux-x86_64.sh
# Add Anaconda to PATH
ENV PATH="/opt/conda/bin:${PATH}"

# Create Python 3.8 environment
RUN conda create -n py38 python=3.8

# Activate Python 3.8 environment in subsequent RUN commands
RUN echo "source activate env" > ~/.bashrc
ENV PATH /opt/conda/envs/env/bin:$PATH

# RUN conda clean -y --index-cache
RUN conda install -y pytorch torchvision torchaudio -c pytorch
RUN conda install -y pytorch-cuda=11.8 -c nvidia
RUN conda install -y numpy=1.21.6 scipy=1.5.2 tensorboard -c conda-forge

# Set working directory
WORKDIR /app

# Copy requirements.txt and install requirements
COPY ./requirements.txt .
RUN while read line; do pip install --progress-bar=on $line && echo "$line installed."; done < requirements.txt

# Install pytorch, torchvision, torchaudio, pytorch-cuda, and other libraries
# RUN pip install imageio==2.4.1 moviepy

COPY ./ /app

RUN mkdir pretrained_models video_data raw_audio denoised_audio custom_character_voice segmented_character_voice && \
    cd monotonic_align && \
    mkdir monotonic_align && \
    python setup.py build_ext --inplace && \
    cd .. && \
    wget https://huggingface.co/datasets/Plachta/sampled_audio4ft/resolve/main/sampled_audio4ft_v2.zip && \
    unzip sampled_audio4ft_v2.zip && \
    wget https://huggingface.co/spaces/Plachta/VITS-Umamusume-voice-synthesizer/resolve/main/pretrained_models/D_trilingual.pth -O ./pretrained_models/D_0.pth


