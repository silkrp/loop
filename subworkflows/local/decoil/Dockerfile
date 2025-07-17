FROM continuumio/miniconda3
ENV DEBIAN_FRONTEND=noninteractive

# docker build --platform linux/amd64 -t rpsilk/decoil:22-make-decoil-compatible-with-more-sv-callers-outputs .
# docker push rpsilk/decoil:22-make-decoil-compatible-with-more-sv-callers-outputs
# singularity pull docker://rpsilk/decoil:22-make-decoil-compatible-with-more-sv-callers-outputs

# Install system packages
RUN apt-get update -y && apt-get install -y \
    build-essential \
    gcc \
    g++ \
    git \
    git-lfs \
    wget \
    libssl-dev \
    libstdc++6 \
    zlib1g-dev \
    libcurl4-openssl-dev \
    python3-dev \
    software-properties-common \
    pandoc \
    openssh-server && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Clone the repo
RUN git clone --single-branch --branch 22-make-decoil-compatible-with-more-sv-callers-outputs https://github.com/madagiurgiu25/decoil-pre.git

# Create the Conda environment
RUN conda env create -f /decoil-pre/environment.yml

# Install setuptools + decoil using conda run
RUN conda run -n envdecoil python -m pip install --upgrade pip setuptools wheel && \
    conda run -n envdecoil python -m pip install numpy && \
    conda run -n envdecoil pip install /decoil-pre/

# Set environment path
ENV PATH /opt/conda/envs/envdecoil/bin:$PATH

# Working directory and command
WORKDIR /output
CMD ["decoil"]
