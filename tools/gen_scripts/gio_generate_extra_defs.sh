#!/bin/bash

# This script assumes that it resides in the tools/gen_scripts directory and
# the defs file will be placed in gio/src.

# To update the gio_signals.defs file:
# 1. ./gio_generate_extra_defs.sh
#    Generates gio/src/gio_signals.defs.orig and gio/src/gio_signals.defs.
#    If any hunks from the patch file fail to apply, apply them manually to the
#    gio_signals.defs file, if required.
# 2. Optional: Remove gio/src/gio_signals.defs.orig.

# To update the gio_signals.defs file and the patch file:
# 1. Like step 1 when updating only the gio_signals.defs file.
# 2. Apply new patches manually to the gio_signals.defs file.
# 3. ./gio_generate_extra_defs.sh --make-patch
# 4. Like step 2 when updating only the gio_signals.defs file.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/gio/src"
out_file=gio_signals.defs
out_dir_file="$out_dir"/$out_file

if [ $# -eq 0 ]
then
  "$extra_defs_gen_dir"/generate_defs_gio > "$out_dir_file"
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
