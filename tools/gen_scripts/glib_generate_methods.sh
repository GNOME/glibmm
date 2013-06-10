#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources. The script assumes it resides in the
# tools/gen_scripts directory and the defs files will be placed in glib/src.

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

H2DEF_PY="$JHBUILD_SOURCES/glibmm/tools/defs_gen/h2def.py"
$H2DEF_PY "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_functions.defs
patch "$OUT_DIR"/glib_functions.defs "$OUT_DIR"/glib_functions.defs.patch

$H2DEF_PY "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_functions.defs
$H2DEF_PY "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_functions.defs
