#!/bin/sh

# installs m2html and shblg to the system path

PREFIX=${PREFIX:-/usr}

install -m755 src/md2html.sh ${PREFIX}/bin/md2html
install -m755 src/shblg.sh ${PREFIX}/bin/shblg
