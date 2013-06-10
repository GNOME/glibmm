#!/bin/bash

# This script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in gio/src.

ROOT_DIR="$(dirname "$0")/../.."
GEN_DIR="$ROOT_DIR/tools/extra_defs_gen"
OUT_DIR="$ROOT_DIR/gio/src"

"$GEN_DIR"/generate_defs_gio > "$OUT_DIR"/gio_signals.defs
patch "$OUT_DIR"/gio_signals.defs "$OUT_DIR"/gio_signals.defs.patch
