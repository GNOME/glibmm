#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in gio/src.

# To update the gio_enums.defs file:
# 1. ./gio_generate_enums.sh
#    Generates gio/src/gio_enums.defs.orig and gio/src/gio_enums.defs.
#    If any hunks from the patch file fail to apply, apply them manually to the
#    gio_enums.defs file, if required.
# 2. Optional: Remove gio/src/gio_enums.defs.orig.

# To update the gio_enums.defs file and the patch file:
# 1. Like step 1 when updating only the gio_enums.defs file.
# 2. Apply new patches manually to the gio_enums.defs file.
# 3. ./gio_generate_enums.sh --make-patch
# 4. Like step 2 when updating only the gio_enums.defs file.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/gio/src"
out_file=gio_enums.defs
out_dir_file="$out_dir"/$out_file

shopt -s extglob # Enable extended pattern matching
shopt -s nullglob # Skip a filename pattern that matches no file
if [ $# -eq 0 ]
then
  # Process files whose names end with .h, but not with private.h.
  # Exclude $source_prefix/gio/gwin32api-*.h and $build_prefix/gio/xdp-dbus.h.
  "$gen_enums" "$source_prefix"/gio/!(*private|gwin32api-*).h "$build_prefix"/gio/!(*private|xdp-dbus).h > "$out_dir_file"
  # patch version 2.7.5 does not like directory names.
  cd "$out_dir"
  patch_options="--backup --version-control=simple --suffix=.orig"
  patch $patch_options $out_file $out_file.patch
elif [ "$1" = "--make-patch" ]
then
  diff --unified=5 "$out_dir_file".orig "$out_dir_file" > "$out_dir_file".patch
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
