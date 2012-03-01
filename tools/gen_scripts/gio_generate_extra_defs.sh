#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources.  The script assumes that it resides in the
# tools/gen_scripts directory and the defs files will be placed in gio/src.

ROOT_DIR="$(dirname "$0")/../.."
GEN_DIR="$ROOT_DIR/tools/extra_defs_gen"
OUT_DIR="$ROOT_DIR/gio/src"

"$GEN_DIR"/generate_defs_gio > "$OUT_DIR"/gio_signals.defs
patch "$OUT_DIR"/gio_signals.defs "$OUT_DIR"/gio_signals.defs.patch
