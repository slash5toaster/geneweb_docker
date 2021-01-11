FROM debian:stable-slim

ENV GW_VER=7.0.0 \
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
            unzip

RUN apt-get install -y \
            opam

USER ${GW_USER}
RUN    opam init \
    && opam switch create 4.09.0 \
    && eval $(opam env) \
    && opam install depext \
    && opam install benchmark \
                    calendars \
                    camlp5.7.12 \
                    cppo \
                    dune.1.11.4 \
                    jingoo.1.4.1 \
                    markup \
                    num \
                    ounit \
                    stdlib-shims \
                    unidecode.0.2.0 \
                    uucp \
                    uunf \
                    zarith

# make geneweb
WORKDIR /tmp/
RUN git clone https://github.com/geneweb/geneweb \
    && cd geneweb \
    && git checkout tags/v${GW_VER} -b v${GW_VER} \
    && ocaml ./configure.ml \
             --sosa-zarith \
    && make distrib

USER ${GW_USER}
WORKDIR ${GW_ROOT}

EXPOSE ${GWD_PORT} ${GWSETUP_PORT}

ENTRYPOINT ["${GW_ROOT}/startup.sh"]

# Mandatory CBS Labels
LABEL PROJECT=geneweb
LABEL MAINTAINER="slash5toaster@gmail.com"
LABEL NAME=geneweb
LABEL VERSION=7.0.0
LABEL GENERATE_SINGULARITY_IMAGE=true
LABEL PRODUCTION=false

#### End of File, if this is missing the file has been truncated
