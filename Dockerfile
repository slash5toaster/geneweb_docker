FROM debian:unstable-slim

ARG GW_VER \
    GW_PR \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115
ENV GW_ROOT=/opt/geneweb \
    GWD_PORT=2317 \
    GWC_PORT=2316 \
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
            curl \
            git \
            ocaml \
            procps \
            rsync \
            unzip \
            wget

# make geneweb
WORKDIR /tmp/

# https://github.com/geneweb/geneweb/releases/download/Geneweb-1eaac340/geneweb-linux-1eaac340.zip
# https://github.com/geneweb/geneweb/releases/download/Geneweb-${GW_PR}/geneweb-linux-${GW_PR}.zip \
RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
       cd /tmp/build/ \
    && ls /tmp/build/ \
    && wget --progress=dot:giga \
            -c https://github.com/geneweb/geneweb/releases/download/${GW_VER}/geneweb-linux.zip \
            -O /tmp/build/geneweb-linux-${GW_VER}.zip \
    && unzip /tmp/build/geneweb-linux-${GW_VER}.zip -d "${GW_ROOT}" \
    && mkdir -vp ${GW_ROOT} ${GW_ROOT}/logs 

COPY opt/geneweb/startup.sh ${GW_ROOT}
COPY opt/geneweb/bashrc ${GW_ROOT}/.bashrc

RUN chown -cR ${GW_USER}:${GW_GROUP} ${GW_ROOT} \
 && chmod -c +x ${GW_ROOT}/startup.sh

USER ${GW_USER}
WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} \
       ${GWC_PORT} \
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
