FROM debian:unstable-slim

ENV DEBIAN_FRONTEND=noninteractive
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

ARG GW_VER \
    GW_PR \
    GW_USER=geneweb \
    GW_GROUP=geneweb \
    GW_UID=115 \
    GW_GID=115 \
    OCAML_VER \
    OPAM_VER \
    TARGETOS \
    TARGETARCH

ENV GW_ROOT=/opt/geneweb \
    GWD_PORT=2317 \
    GWSETUP_PORT=2316 \
    HTTP_PORT=80 \
    HTTPS_PORT=443

# Add geneweb user
RUN groupadd ${GW_GROUP} \
          -g ${GW_GID} \
 && useradd ${GW_USER} \
         -u ${GW_UID} \
         -g ${GW_GROUP} \
         -m -d ${GW_ROOT} \
         --system \
         -l \
         -s /bin/bash \
  ; pwck -s \
  ; grpck -s

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
       apt-get update \
    && apt-get install -y \
            bubblewrap \
            bzip2 \
            curl \
            gcc \
            git \
            libcurl4-gnutls-dev \
            libgmp-dev \
            libipc-system-simple-perl \
            libstring-shellquote-perl \
            m4 \
            make \
            procps \
            rsync \
            tini \
            unzip \
            vim \
            wget \
            xdot

# manually install ocaml and opam
# https://github.com/ocaml/ocaml/archive/refs/tags/4.14.2.zip
# https://github.com/ocaml/opam/releases/download/2.1.5/opam-2.1.5-arm64-linux
RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
       cd /tmp/build/ \
 && ls /tmp/build/ \
 && wget --progress=dot:giga \
         -c  https://github.com/ocaml/ocaml/archive/refs/tags/${OCAML_VER}.tar.gz \
         -O /tmp/build/${OCAML_VER}.tar.gz \
 && tar -xzvf /tmp/build/${OCAML_VER}.tar.gz \
 && cd /tmp/build/ocaml-${OCAML_VER}/ \
 && ./configure \
 && make clean \
 && make \
 && make install \
 && wget -c --progress=dot:giga \
    https://github.com/ocaml/opam/releases/download/${OPAM_VER}/opam-${OPAM_VER}-${TARGETARCH}-${TARGETOS} \
    -O /usr/bin/opam \
 && chmod -c +x /usr/bin/opam

RUN echo "test -r /root/.opam/opam-init/init.sh && . /root/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true" >> ~/.profile

# setup opam
RUN opam -y init --compiler=${OCAML_VER} \
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

RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
    cd /tmp/build/ \ 
 && (test -e /tmp/build/geneweb/.git || git clone --depth=1 --no-single-branch https://github.com/geneweb/geneweb /tmp/build/geneweb) \
 && cd /tmp/build/geneweb \
 && git checkout ${GW_VER}
RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
    cd /tmp/build/geneweb \
 && eval $(opam env) \
 && opam exec -- ocaml ./configure.ml --release \
 && opam exec -- make distrib

RUN --mount=type=cache,target=/tmp/build/,sharing=locked \
    rsync -azv /tmp/build/geneweb/distribution/ /opt/geneweb/ \
 && chown -cR ${GW_USER}:${GW_GROUP} /opt/geneweb/

# make geneweb
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
