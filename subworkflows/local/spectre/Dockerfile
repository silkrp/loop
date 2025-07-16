FROM python:3.10-slim

# docker build --platform linux/amd64,linux/arm64 -t rpsilk/spectre:latest .
# docker push rpsilk/spectre:latest
# singularity pull docker://rpsilk/spectre 

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y && apt-get install -y \
    git \
    build-essential \
    gcc \
    libffi-dev \
    libpq-dev \
    libssl-dev \
    curl \
    procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir \
    numpy==1.24.3 \
    pandas==2.0.1 \
    matplotlib==3.7.1 \
    scipy==1.10.1 \
    pysam==0.22.0 \
    && pip install --no-cache-dir spectre-cnv


