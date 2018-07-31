#!/bin/sh -e
SRCDIR=`realpath $(dirname $0)/..`
PKGTK=${SRCDIR}/bin/pkgtk
TCLLIBPATH=${SRCDIR}/lib

export TCLLIBPATH
exec ${PKGTK}
