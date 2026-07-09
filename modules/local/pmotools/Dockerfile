# Build: docker build -t plasmogenepi/plasmodiumdrugres-pmotools:1.0.0 .
FROM mambaorg/micromamba:1.5.10

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

WORKDIR /workspace

RUN micromamba install -y -n base python=3.12 pip \
    && micromamba run -n base pip install --no-cache-dir pmotools==1.0.0 \
    && micromamba clean -a -y
