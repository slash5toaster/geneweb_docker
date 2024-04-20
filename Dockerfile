FROM debian:unstable-slim

ARG GW_VER \
    GW_PR \
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
         --system \
         -l \
         -s /bin/bash

RUN pwck -s \
  ; grpck -s

# Update OS to apply latest vulnerability fix
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && \
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
            rsync \
            tini \
            unzip \
            wget

# make geneweb
WORKDIR /tmp/
RUN git clone https://github.com/geneweb/geneweb \
    && cd geneweb \
    && git checkout tags/Geneweb-${GW_PR} \
    && ocaml ./configure.ml \
             --sosa-zarith \
    && make distrib

USER ${GW_USER}
WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} \
       ${GWSETUP_PORT} \
       ${HTTP_PORT} \
       ${HTTPS_PORT}

HEALTHCHECK --interval=5m \
            --timeout=3s \
            --start-period=30s \
  CMD curl -s --fail http://localhost:2317 -o /dev/null

ENTRYPOINT [ "/usr/bin/tini", "--" ]
CMD [ "sh", "-c", "/opt/geneweb/startup.sh", "$@" ]

# Mandatory Labels
LABEL org.opencontainers.image.vendor=slash5toaster \
      org.opencontainers.image.authors="slash5toaster@gmail.com" \
      org.opencontainers.image.ref.name=geneweb \
      org.opencontainers.image.version=7.1.0-beta

#### End of File, if this is missing the file has been truncated
