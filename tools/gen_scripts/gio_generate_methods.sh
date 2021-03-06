#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in gio/src.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/gio/src"

shopt -s extglob # Enable extended pattern matching
shopt -s nullglob # Skip a filename pattern that matches no file
# Process files whose names end with .h, but not with private.h.
  # Exclude $source_prefix/gio/gwin32api-*.h and $build_prefix/gio/xdp-dbus.h.
"$gen_methods" "$source_prefix"/gio/!(*private|gwin32api-*).h "$build_prefix"/gio/!(*private|xdp-dbus).h > "$out_dir"/gio_methods.defs
