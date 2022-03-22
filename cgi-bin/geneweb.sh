#!/usr/bin/env bash

# # The CGI working directory.
# PWD=$(pwd)
# # The language for the user interface.
# LNG="en"
# # The programs folder.
# GENEWEBSHARE=$PWD/gw
# # The documentation folder (obsolete).
# GENEWEBDOC=$PWD/gw/doc
# # The databases folder.
# GENEWEBDB=$PWD/../bases
# # The program gwd itself.
# DAEMON=$GENEWEBSHARE/gwd
# # Gwd log file, it helps to solve problems.
# LOGFILE=$GENEWEBDB/gw.log
#
#
# #!/bin/sh
BIN_DIR=/opt/geneweb
BASE_DIR=/opt/geneweb/bases
OPTIONS="-robot_xcl 19,60 -allowed_tags ./tags.txt -hd ./"
$BIN_DIR/gwd -cgi  $OPTIONS   -bd $BASE_DIR   2>./gwd.log
