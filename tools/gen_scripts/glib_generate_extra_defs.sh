#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources.  The script assumes that it resides in the
# tools/gen_scripts directory and the defs files will be placed in glib/src.

ROOT_DIR="$(dirname "$0")/../.."
GEN_DIR="$ROOT_DIR/tools/extra_defs_gen"
OUT_DIR="$ROOT_DIR/glib/src"

"$GEN_DIR"/../extra_defs_gen/generate_defs_glib > "$OUT_DIR"/glib_signals.defs
