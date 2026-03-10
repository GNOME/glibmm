#!/bin/bash

# The script assumes it resides in the tools/gen_scripts directory and
# the defs files will be placed in glib/src.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/glib/src"
gir_dir="$build_prefix"/girepository/introspection

"$gen_vfuncs" "$gir_dir"/GLib-2.0.gir "$gir_dir"/GLibUnix-2.0.gir "$gir_dir"/GModule-2.0.gir "$gir_dir"/GObject-2.0.gir > "$out_dir"/glib_vfuncs.defs

