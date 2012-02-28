#!/bin/bash

# Note that docextract_to_xml.py should be in PATH for this script to work and
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources.  The XML file will be placed in
# $JHBUILD_SOURCES/glibmm/glib/src.

if [ -z "$JHBUILD_SOURCES" -o ! -x "`which docextract_to_xml.py`" ]; then
  echo -e "JHBUILD_SOURCES must contain path to jhbuild sources and \
docextract_to_xml.py\nneeds to be executable and in PATH."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES"
OUT_DIR="$JHBUILD_SOURCES/glibmm/glib/src"

for dir in "$PREFIX"/glib/{glib,gmodule,gobject,gthread}; do
  PARAMS="$PARAMS -s $dir"
done

docextract_to_xml.py $PARAMS > "$OUT_DIR/glib_docs.xml"
