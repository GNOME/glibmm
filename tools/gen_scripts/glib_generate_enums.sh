#!/bin/bash

# Note that 
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The script assumes that it resides in the tools/gen_scripts
# directory and the defs files will be placed in glib/src.

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

ENUM_PL="$JHBUILD_SOURCES/glibmm/tools/enum.pl"
$ENUM_PL "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_enums.defs
patch "$OUT_DIR"/glib_enums.defs "$OUT_DIR"/glib_enums.defs.patch

$ENUM_PL "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_enums.defs
$ENUM_PL "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_enums.defs
