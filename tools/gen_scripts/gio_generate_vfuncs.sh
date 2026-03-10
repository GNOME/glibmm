#!/bin/bash

# The script assumes it resides in the tools/gen_scripts directory and
# the defs files will be placed in gio/src.

# To update the gio_vfuncs.defs file:
# 1. ./gio_generate_vfuncs.sh
#    Generates gio/src/gio_vfuncs.defs.orig and gio/src/gio_vfuncs.defs.
#    If any hunks from the patch file fail to apply, apply them manually to the
#    gio_vfuncs.defs file, if required.
# 2. Optional: Remove gio/src/gio_vfuncs.defs.orig.

# To update the gio_vfuncs.defs file and the patch file:
# 1. Like step 1 when updating only the gio_vfuncs.defs file.
# 2. Apply new patches manually to the gio_vfuncs.defs file.
# 3. ./gio_generate_vfuncs.sh --make-patch
# 4. Like step 2 when updating only the gio_vfuncs.defs file.

source "$(dirname "$0")/init_generate.sh"

gir_dir="$build_prefix"/girepository/introspection
out_dir="$root_dir/gio/src"
out_file=gio_vfuncs.defs
out_dir_file="$out_dir"/$out_file

if [ $# -eq 0 ]
then
  "$gen_vfuncs" "$gir_dir"/Gio-2.0.gir "$gir_dir"/GioUnix-2.0.gir > "$out_dir_file"
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
