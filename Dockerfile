FROM debian:stable-slim

ENV GW_VER=7.0.0 \
    GW_PR=88536ed4 \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115 \
    GW_ROOT=/opt/geneweb \
    GWD_PORT=2317 \
    GWSETUP_PORT=2316

# Add rsiapp user
RUN groupadd ${GW_GROUP} \
          -g ${GW_GID}
RUN useradd ${GW_USER} \
         -u ${GW_UID} \
         -g ${GW_GROUP} \
         -m -d ${GW_ROOT} \
         -s /bin/bash

RUN pwck -s \
  ; grpck -s

# Update OS to apply latest vulnerability fix
RUN apt-get update && \
    apt-get install -y \
            bubblewrap \
            build-essential \
            curl \
            gcc \
            git \
            libcurl4-gnutls-dev \
            libgmp-dev \
            m4 \
            make \
            ocaml \
            procps \
            tini \
            wget \
            unzip

RUN apt-get install -y \
            opam

# make geneweb
WORKDIR /tmp/

RUN wget https://github.com/geneweb/geneweb/releases/download/v${GW_VER}/geneweb-linux-${GW_PR}.zip \
      -O /tmp/geneweb-linux-${GW_PR}.zip \
    && cd ${GW_ROOT} \
    && unzip /tmp/geneweb-linux-${GW_PR}.zip \
    && mv -v ${GW_ROOT}/distribution/* ${GW_ROOT} \
    && chown -cR ${GW_USER}.${GW_GROUP} ${GW_ROOT}

COPY opt/geneweb/startup.sh ${GW_ROOT}

USER ${GW_USER}
WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} ${GWSETUP_PORT}

# ENTRYPOINT ["${GW_ROOT}/startup.sh"]

# Mandatory CBS Labels
LABEL PROJECT=geneweb
LABEL MAINTAINER="slash5toaster@gmail.com"
LABEL NAME=geneweb
LABEL VERSION=7.0.0
LABEL GENERATE_SINGULARITY_IMAGE=true
LABEL PRODUCTION=false

#### End of File, if this is missing the file has been truncated
