#!/usr/bin/env bash

set -x
set -o pipefail 
uname -a 

GW_VER="v7.1-beta"
OCAML_VER="4.14.2"
OPAM_VER="2.1.5"
TARGETOS="linux"
TARGETARCH="arm64"

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


if [[ $(type -p ocaml) ]] ; then 
    echo $(ocaml --version)
else 
    mkdir -vp /tmp/build/
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
    && make install
fi 

test -r /root/.opam/opam-init/init.sh \
&& source /root/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true

wget -c \
    https://github.com/ocaml/opam/releases/download/${OPAM_VER}/opam-${OPAM_VER}-${TARGETARCH}-${TARGETOS} \
    -O /usr/bin/opam \
 && wget -c \
    https://github.com/ocaml/opam/releases/download/${OPAM_VER}/opam-${OPAM_VER}-${TARGETARCH}-${TARGETOS}.sig \
    -O /tmp/opam.sig \
 && chmod -c +x /usr/bin/opam

    opam -y init --compiler=${OCAML_VER} \
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
            uunf
    opam exec -- ocaml --version \
    && opam exec -- opam --version \
    && opam list

    mkdir -vp /tmp/build/ \
    && cd /tmp/build/ \
    && (test -e /tmp/build/geneweb/.git || git clone --depth=1 --no-single-branch https://github.com/geneweb/geneweb /tmp/build/geneweb) \
    && cd /tmp/build/geneweb \
    && git checkout ${GW_VER}
    cd /tmp/build/geneweb \
    && eval $(opam env ) \
    && opam exec -- ocaml ./configure.ml --release \
    && opam exec -- make distrib \
    && rsync -azv /tmp/build/geneweb/distribution/ /opt/geneweb/