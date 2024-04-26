FROM debian:unstable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
       apt-get update \
    && apt-get install -y \
       software-properties-common \
    && add-apt-repository -y ppa:avsm/ppa

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
       apt-get update \
    && apt-get install -y \
            curl \
            gcc \
            git \
            libcurl4-gnutls-dev \
            libgmp-dev \
            libipc-system-simple-perl \
            libstring-shellquote-perl \
            m4 \
            make \
            ocaml \
            opam \
            procps \
            rsync \
            tini \
            unzip \
            vim \
            wget \
            xdot

# setup opam
RUN opam -y init --compiler=4.14.2 \
    && eval $(opam env) \
    && opam install -y \
            calendars.1.0.0 \
            camlp-streams \
            camlp5 \
            cppo \
            dune \
            jingoo \
            markup \
            oUnit \
            ppx_blob \
            ppx_deriving \
            ppx_import \
            stdlib-shims \
            syslog \
            unidecode.0.2.0 \
            uri \
            uucp \
            uutf \
            uunf \
    && opam exec -- ocaml --version \
    && opam exec -- opam --version \
    && opam list

# make geneweb
USER ${GW_USER}
WORKDIR ${GW_ROOT}

RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
    cd /tmp/build/ \ 
    && (test -e geneweb/.git || git --depth=1 --no-single-branch https://github.com/geneweb/geneweb) \
    && cd geneweb \
    && git checkout ${GW_VER} \
    && eval $(opam env) \
    && opam exec -- ocaml ./configure.ml --release \
    && opam exec -- make distrib

RUN mv -v /tmp/build/geneweb/distribution/* /opt/geneweb/

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
