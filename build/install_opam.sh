#!/bin/bash

set -x 
set -o pipefail

TARGETARCH=${TARGETARCH:-$1}

if [[ -z ${TARGETARCH} ]]; then
    echo "need TARGETARCH"
    exit 2
fi

# this converts the $TARGETARCH from a dockerfile to do the correct actions
case $TARGETARCH in
    aarch)
        MYARCH="macos"
    ;;
    
    amd64)
        MYARCH="x86_64"
    ;;
    
    *)
        MYARCH=$TARGETARCH
    ;;

esac

wget -c --progress=dot:giga \
    https://github.com/ocaml/opam/releases/download/${OPAM_VER}/opam-${OPAM_VER}-${MYARCH}-${TARGETOS} \
    -O /usr/bin/opam \
 && chmod -c +x /usr/bin/opam
