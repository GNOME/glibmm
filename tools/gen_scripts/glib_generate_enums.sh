#!/bin/bash

# Note that enum.pl should be in PATH for this script to work and
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The defs files will be placed in
# $JHBUILD_SOURCES/glibmm/glib/src.

if [ -z "$JHBUILD_SOURCES" -o ! -x "`which enum.pl`" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources and \
enum.pl\nneeds to be executable and in PATH."
  exit 1;
fi

OUT_DIR="$JHBUILD_SOURCES/glibmm/glib/src"
PREFIX="$JHBUILD_SOURCES/glib"

enum.pl "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_enums.defs
patch "$OUT_DIR"/glib_enums.defs "$OUT_DIR"/glib_enums.defs.patch

enum.pl "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_enums.defs
enum.pl "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_enums.defs
