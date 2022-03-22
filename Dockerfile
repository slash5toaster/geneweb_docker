FROM debian:unstable-slim

ARG GW_VER=7.0.0 \
    GW_PR=88536ed4 \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115
ENV GW_ROOT=/opt/geneweb \
    GWD_PORT=2317 \
    GWSETUP_PORT=2316 \
    HTTP_PORT=80 \
    HTTPS_PORT=443

# Add geneweb user
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
            fcgiwrap \
            gcc \
            git \
            libcurl4-gnutls-dev \
            libgmp-dev \
            m4 \
            make \
            nginx-full \
            ocaml \
            procps \
            tini \
            unzip \
            wget

RUN apt-get install -y \
            opam

# install apache and auth mechanisms
RUN apt-get update && \
    apt-get install -y \
            apache2 \
            libapache2-mod-authnz-external \
            libapache2-mod-auth-plain \
            libapache2-mod-auth-openidc

# make geneweb
WORKDIR /tmp/
RUN mkdir -vp ${GW_ROOT}
RUN wget https://github.com/geneweb/geneweb/releases/download/v${GW_VER}/geneweb-linux-${GW_PR}.zip \
      -O /tmp/geneweb-linux-${GW_PR}.zip
RUN unzip /tmp/geneweb-linux-${GW_PR}.zip \
    && mv -v /tmp/distribution/* ${GW_ROOT}/ \
    && rm -v /tmp/geneweb-linux-${GW_PR}*

RUN chown -cR ${GW_USER}.${GW_GROUP} ${GW_ROOT}

# USER ${GW_USER}
# WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} \
       ${GWSETUP_PORT} \
       ${HTTP_PORT} \
       ${HTTPS_PORT}

HEALTHCHECK --interval=5m \
            --timeout=3s \
            --start-period=30s \
  CMD curl -s --fail http://localhost:80 -o /dev/null

ENTRYPOINT [ "/usr/bin/tini", "--" ]
# CMD [ "sh", "-c", "/opt/geneweb/startup.sh", "$@" ]

# Mandatory Labels
LABEL PROJECT=geneweb
LABEL MAINTAINER="slash5toaster@gmail.com"
LABEL NAME=geneweb
LABEL VERSION=7.0.0-cgi
LABEL GENERATE_SINGULARITY_IMAGE=false
LABEL PRODUCTION=false

#### End of File, if this is missing the file has been truncated
