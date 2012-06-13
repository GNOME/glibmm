#!/bin/bash

# Note that 
# JHBUILD_SOURCES should be defined to contain the path to the root of the
# jhbuild sources. The XML files will be placed in glib/src.

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

for dir in "$PREFIX"/glib/{glib,gmodule,gobject,gthread}; do
  PARAMS="$PARAMS -s $dir"
done

DOCEXTRACT_TO_XML_PY="$JHBUILD_SOURCES/glibmm/tools/defs_gen/docextract_to_xml.py"
$DOCEXTRACT_TO_XML_PY $PARAMS > "$OUT_DIR/glib_docs.xml"
