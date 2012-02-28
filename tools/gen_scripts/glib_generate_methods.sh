#!/bin/bash

# Note that h2def.py should be in PATH for this script to work and
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The defs files will be placed in
# $JHBUILD_SOURCES/glibmm/glib/src.

if [ -z "$JHBUILD_SOURCES" -o ! -x "`which h2def.py`" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources and \
h2def.py\nneeds to be executable and in PATH."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
OUT_DIR="$JHBUILD_SOURCES/glibmm/glib/src"

h2def.py "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_functions.defs
patch "$OUT_DIR"/glib_functions.defs "$OUT_DIR"/glib_functions.defs.patch

h2def.py "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_functions.defs
h2def.py "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_functions.defs
