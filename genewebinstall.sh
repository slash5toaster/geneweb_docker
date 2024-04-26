#!/usr/bin/env bash

set -x 
uname -a 

GW_VER="v7.1-beta"

apt update
apt-get install -y \
    software-properties-common
add-apt-repository -y ppa:avsm/ppa
apt update
apt install -y \
    curl \
    gcc \
    git \
    libcurl4-gnutls-dev \
    libgmp-dev \
    libipc-system-simple-perl \
    libstring-shellquote-perl \
    opam \
    vim \
    xdot

opam -y init --compiler=4.14.2
eval $(opam env)
opam install -y \
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

#[OPTIONAL] Verify installed versions of Ocaml and Opam versions, list Opam dependencies
opam exec -- ocaml --version
opam exec -- opam --version
opam list

# make geneweb
cd /tmp/
git clone --depth=1 --no-single-branch https://github.com/geneweb/geneweb
cd geneweb \
&& git checkout ${GW_VER} \
&& opam exec -- ocaml ./configure.ml --release \
&& opam exec -- make distrib
