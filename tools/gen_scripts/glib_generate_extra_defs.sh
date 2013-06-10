#!/bin/bash

# This script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in glib/src.

ROOT_DIR="$(dirname "$0")/../.."
GEN_DIR="../extra_defs_gen"
OUT_DIR="$ROOT_DIR/glib/src"

"$GEN_DIR"/generate_defs_glib > "$OUT_DIR"/glib_signals.defs
