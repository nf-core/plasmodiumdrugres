# nf-core-style module image (Bioconda env). Build:
#   docker build -t plasmogenepi/plasmodiumdrugres-translate-loci:1.0.0 .
FROM mambaorg/micromamba:1.5.10

# Nextflow collects task metrics via `ps` inside the container
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends procps \
    && rm -rf /var/lib/apt/lists/*
USER $MAMBA_USER

WORKDIR /workspace

COPY --chown=$MAMBA_USER:$MAMBA_USER environment.yml /tmp/environment.yml

RUN micromamba install -y -n base -f /tmp/environment.yml \
    && micromamba clean -a -y
