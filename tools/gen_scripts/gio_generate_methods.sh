#!/bin/bash

# Note that h2def.py should be in PATH for this script to work and
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The defs files will be placed in
# $JHBUILD_SOURCES/glibmm/gio/src.

if [ -z "$JHBUILD_SOURCES" -o ! -x "`which h2def.py`" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources and \
h2def.py\nneeds to be executable and in PATH."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
OUT_DIR="$JHBUILD_SOURCES/glibmm/gio/src"

h2def.py "$PREFIX"/gio/*.h > "$OUT_DIR"/gio_methods.defs
#patch "$OUT_DIR"/gio_methods.defs "$OUT_DIR"/gio_methods.defs.patch
