#!/usr/bin/env bash

sudo apt-get install ocaml curl make m4 unzip bubblewrap gcc libgmp-dev libcurl4-gnutls-dev git build-essential
# Install Opam.

sudo apt-get install opam
# If the Opam install fails with the command above, build and install the latest Opam version from its repository:
# cd /tmp/
# git clone https://github.com/ocaml/opam.git
# cd opam
# ./configure
# make lib-ext
# make
# sudo make install

opam init
opam switch create 4.09.0
eval $(opam env)

opam install depext
opam install benchmark calendars camlp5.7.12 cppo dune.1.11.4 jingoo.1.4.1 markup num ounit stdlib-shims unidecode.0.2.0 uucp uunf zarith

# make geneweb
cd /tmp/
git clone https://github.com/geneweb/geneweb
cd geneweb
git checkout tags/v7.0.0 -b v7.0.0
ocaml ./configure.ml --sosa-zarith
make distrib
