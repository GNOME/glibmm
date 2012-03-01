#!/bin/bash

# Note that h2def.py should be in PATH for this script to work and
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The script assumes that it resides in the tools/gen_scripts
# directory and the defs files will be placed in glib/src.

if [ -z "$JHBUILD_SOURCES" -o ! -x "`which h2def.py`" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources and \
h2def.py\nneeds to be executable and in PATH."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

h2def.py "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_functions.defs
patch "$OUT_DIR"/glib_functions.defs "$OUT_DIR"/glib_functions.defs.patch

h2def.py "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_functions.defs
h2def.py "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_functions.defs
