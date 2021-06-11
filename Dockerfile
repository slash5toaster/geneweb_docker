FROM debian:stable-slim

ARG GW_VER=7.0.0 \
    GW_PR=88536ed4 \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115 
ENV GW_ROOT=/opt/geneweb \
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
    && rm -v /tmp/geneweb-linux-${GW_PR}.zip

COPY opt/geneweb/startup.sh ${GW_ROOT}
COPY opt/geneweb/bashrc ${GW_ROOT}/.bashrc

RUN chown -cR ${GW_USER}.${GW_GROUP} ${GW_ROOT} \
    && chmod -c +x /opt/geneweb/startup.sh

USER ${GW_USER}
WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} ${GWSETUP_PORT}

HEALTHCHECK --interval=5m \
            --timeout=3s \
            --start-period=30s \
  CMD curl -s --fail http://localhost:2317 -o /dev/null

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "sh", "-c", "/opt/geneweb/startup.sh", "$@" ]

# Mandatory Labels
LABEL PROJECT=geneweb
LABEL MAINTAINER="slash5toaster@gmail.com"
LABEL NAME=geneweb
LABEL VERSION=7.0.0-pb
LABEL GENERATE_SINGULARITY_IMAGE=true
LABEL PRODUCTION=false

#### End of File, if this is missing the file has been truncated
