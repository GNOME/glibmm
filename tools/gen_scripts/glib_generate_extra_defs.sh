#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources.  The defs files will be placed in
# $JHBUILD_SOURCES/glibmm/glib/src.

GEN_DIR="$JHBUILD_SOURCES/glibmm/tools/extra_defs_gen"
OUT_DIR="$JHBUILD_SOURCES/glibmm/glib/src"

"$GEN_DIR"/../extra_defs_gen/generate_defs_glib > "$OUT_DIR"/glib_signals.defs
