#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the defs files will be placed in glib/src.

# To update the g[lib|module|object]_enums.defs files:
# 1. ./glib_generate_enums.sh
#    Generates glib/src/glib_enums.defs.orig and glib/src/g[lib|module|object]_enums.defs.
#    If any hunks from the patch file fail to apply, apply them manually to the
#    glib_enums.defs file, if required.
# 2. Optional: Remove glib/src/glib_enums.defs.orig.

# To update the g[lib|module|object]_enums.defs files and the patch file:
# 1. Like step 1 when updating only the g[lib|module|object]_enums.defs files.
# 2. Apply new patches manually to the glib_enums.defs file.
# 3. ./glib_generate_enums.sh --make-patch
# 4. Like step 2 when updating only the g[lib|module|object]_enums.defs files.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/glib/src"

shopt -s extglob # Enable extended pattern matching
shopt -s nullglob # Skip a filename pattern that matches no file
if [ $# -eq 0 ]
then
  # Process files whose names end with .h, but not with private.h.
  "$gen_enums" "$source_prefix"/glib/!(*private).h "$source_prefix"/glib/deprecated/!(*private).h \
               "$build_prefix"/glib/!(*private).h "$build_prefix"/glib/deprecated/!(*private).h > "$out_dir"/glib_enums.defs
  "$gen_enums" "$source_prefix"/gmodule/!(*private).h "$build_prefix"/gmodule/!(*private).h > "$out_dir"/gmodule_enums.defs
  "$gen_enums" "$source_prefix"/gobject/!(*private).h "$build_prefix"/gobject/!(*private).h > "$out_dir"/gobject_enums.defs
  # patch version 2.7.5 does not like directory names.
  cd "$out_dir"
  patch_options="--backup --version-control=simple --suffix=.orig"
  patch $patch_options glib_enums.defs glib_enums.defs.patch
elif [ "$1" = "--make-patch" ]
then
  out_dir_file="$out_dir"/glib_enums.defs
  diff --unified=5 "$out_dir_file".orig "$out_dir_file" > "$out_dir_file".patch
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
