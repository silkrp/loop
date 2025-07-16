FROM python:3.12-slim

# docker build --platform linux/amd64,linux/arm64 -t rpsilk/coral:latest .
# docker push rpsilk/coral:latest
# singularity pull docker://rpsilk/coral 

ENV DEBIAN_FRONTEND=noninteractive
ENV POETRY_VIRTUALENVS_CREATE=false

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

RUN git clone https://github.com/AmpliconSuite/CoRAL.git && \
    cd CoRAL && \
    pip install poetry && \
    poetry config virtualenvs.create false && \
    poetry install


