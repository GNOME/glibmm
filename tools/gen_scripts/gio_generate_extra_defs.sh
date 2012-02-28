#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources.  The defs files will be placed in
# $JHBUILD_SOURCES/glibmm/gio/src.

GEN_DIR="$JHBUILD_SOURCES/glibmm/tools/extra_defs_gen"
OUT_DIR="$JHBUILD_SOURCES/glibmm/gio/src"

"$GEN_DIR"/generate_defs_gio > "$OUT_DIR"/gio_signals.defs
patch "$OUT_DIR"/gio_signals.defs "$OUT_DIR"/gio_signals.defs.patch
