#!/bin/bash

# This script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in glib/src.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/glib/src"

"$extra_defs_gen_dir"/generate_defs_glib > "$out_dir"/glib_signals.defs
