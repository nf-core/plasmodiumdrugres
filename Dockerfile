FROM ubuntu:24.04
LABEL authors="PlasmoGenEpi"

ARG DEBIAN_FRONTEND="noninteractive"
ARG SHELL="/bin/bash"
ARG LANG="en_US.UTF-8"
ARG LANGUAGE="en_US.UTF-8"
ARG LC_ALL="en_US.UTF-8"
ARG CPU_COUNT=5
ARG TIME_ZONE=Etc/UTC

RUN ulimit -n 10000

# install wget for getting pubkey
RUN apt-get update
RUN apt-get -yq dist-upgrade wget

# add packages source to install r 4.4 which is needed for BiocManager 3.19 which is needed pwalign
RUN echo "deb https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" > /etc/apt/sources.list.d/cran.list
RUN echo "deb-src https://cloud.r-project.org/bin/linux/ubuntu noble-cran40/" >> /etc/apt/sources.list.d/cran.list
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc

# install basics
RUN apt-get update
RUN apt-get -yq dist-upgrade
RUN apt-get install -yq --no-install-recommends autotools-dev autoconf libtool automake build-essential curl wget file git locales libssl-dev libcurl4-gnutls-dev ca-certificates xz-utils zlib1g-dev libbz2-dev liblzma5 liblzma-doc liblzma-dev openssh-client python3-dev python3-pip libxml2-dev libfontconfig1-dev libharfbuzz-dev libfribidi-dev libfreetype6-dev libpng-dev libtiff5-dev libjpeg-dev libmpfr-dev libgmp3-dev

# install common bio tools
RUN apt-get install -yq --no-install-recommends muscle r-recommended=4.4* r-base=4.4.* r-base-core=4.4.* r-base-dev=4.4.*

# set environment locale
RUN echo "$LANG UTF-8" >> /etc/locale.gen
RUN echo "LANG=$LANG" > /etc/locale.conf
RUN echo "LC_ALL=$LC_ALL" >> /etc/environment
RUN echo "LANGUAGE=$LANGUAGE" >> /etc/environment
RUN locale-gen $LANG
RUN update-locale LANG=$LANG

RUN DEBIAN_FRONTEND=noninteractive TZ=$TIME_ZONE apt-get -y install tzdata

# add github key so can git clone from github
RUN mkdir ~/.ssh/
RUN ssh-keyscan github.com >> ~/.ssh/known_hosts


# pmotools from PyPI (provides pmotools-python CLI)
# Keep in sync with bioconda::pmotools in modules/local/*/environment.yml
RUN pip install --break-system-packages pmotools==1.1.0

# R configuration
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl', Ncpus = ${CPU_COUNT})" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages(c("remotes"))'
## attempt to load libraries to make sure they installed
RUN R -e 'library("remotes")'

# r-recommended can ship nlme built for an older R; reinstall before ape/pegas (need R 4.4 symbols)
RUN R -e 'install.packages("nlme", repos = "https://cran.rstudio.com/")'
RUN R -e 'library("nlme")'

# R packages
RUN Rscript -e "remotes::install_cran(c('tibble', 'dplyr', 'stringr', 'readr', 'optparse', 'ggplot2', 'tidyr', 'data.table', 'validate', 'openxlsx', 'Rmpfr', 'rlang', 'doParallel', 'magrittr', 'checkmate', 'ape', 'pegas', 'rngtools', 'parallelly', 'doMC'), Ncpus = ${CPU_COUNT})"

## attempt to load libraries to make sure they installed
RUN R -e 'library("tibble")'
RUN R -e 'library("dplyr")'
RUN R -e 'library("stringr")'
RUN R -e 'library("readr")'
RUN R -e 'library("optparse")'
RUN R -e 'library("ggplot2")'
RUN R -e 'library("tidyr")'
RUN R -e 'library("data.table")'
RUN R -e 'library("validate")'
RUN R -e 'library("openxlsx")'
RUN R -e 'library("Rmpfr")'
RUN R -e 'library("rlang")'
RUN R -e 'library("doParallel")'
RUN R -e 'library("magrittr")'
RUN R -e 'library("checkmate")'
RUN R -e 'library("pegas")'
RUN R -e 'library("ape")'
RUN R -e 'library("rngtools")'
RUN R -e 'library("parallelly")'
RUN R -e 'library("doMC")'

# R Install FEM
RUN R -e "remotes::install_github('aimeertaylor/FreqEstimationModel', build_vignettes = FALSE, dependencies = TRUE)"
RUN R -e 'library("FreqEstimationModel")'

# R install dcifer, variantstring
RUN R -e "install.packages(c('dcifer', 'variantstring'), repos = c('https://plasmogenepi.r-universe.dev', 'https://cloud.r-project.org'))"

## attempt to load libraries to make sure they installed
RUN R -e 'library("dcifer")'
RUN R -e 'library("variantstring")'

# Bioconductor packages (have to install 3.19 because that's needed for pwalign)
RUN Rscript -e 'if (!require("BiocManager", quietly = TRUE)) { install.packages("BiocManager"); }; BiocManager::install(version = "3.19", ask = FALSE);'
RUN Rscript -e 'BiocManager::install("Biostrings", ask = FALSE)'
RUN Rscript -e 'BiocManager::install("pwalign", ask = FALSE)'
RUN Rscript -e 'BiocManager::install("msa", ask = FALSE)'
## attempt to load libraries to make sure they installed
RUN R -e 'library("Biostrings")'
RUN R -e 'library("pwalign")'
