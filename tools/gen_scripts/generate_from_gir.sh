#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the XML and defs files will be placed in glib/src and gio/src.

# To update the defs files:
# 1. ./generate_from_gir.sh
#    Generates [glib,gio]/src/*.defs.orig and [glib,gio]/src/*.defs.
#    If any hunks from the patch files fail to apply, apply them manually to
#    the defs files, if required.
# 2. Optional: Remove [glib,gio]/src/*.defs.orig.

# To update the patch files:
# 1. Like step 1 when updating the [glib,gio]/src/*.defs files.
# 2. Apply new patches manually to the [glib,gio]/src/*.defs files.
# 3. ./generate_from_gir.sh --make-patch
# 4. Like step 2 when updating the [glib,gio]/src/*.defs file.

source "$(dirname "$0")/init_generate.sh"

gir_dir="$GMMPROC_GEN_INSTALL_DIR/share/gir-1.0"
out_dir_glib="$root_dir/glib/src"
out_dir_gio="$root_dir/gio/src"

if [ $# -eq 0 ]
then
  echo ===== GLib and Gio: Documentation
  "$(dirname "$0")"/glib_generate_docs.sh
  "$(dirname "$0")"/gio_generate_docs.sh

  echo; echo GLib: Enums and functions
  "$gen_with_mmgir" --gir "$gir_dir"/GLib-2.0.gir --gir "$gir_dir"/GLibUnix-2.0.gir \
    --gir-search-dir "$gir_dir" \
    --enum-defs "$out_dir_glib"/glib_enums.defs \
    --function-defs "$out_dir_glib"/glib_functions.defs

  echo; echo ===== GModule: Enums and functions
  "$gen_with_mmgir" --gir "$gir_dir"/GModule-2.0.gir \
    --gir-search-dir "$gir_dir" \
    --enum-defs "$out_dir_glib"/gmodule_enums.defs \
    --function-defs "$out_dir_glib"/gmodule_functions.defs

  echo; echo ===== GObject: Enums and functions
  "$gen_with_mmgir" --gir "$gir_dir"/GObject-2.0.gir \
    --gir-search-dir "$gir_dir" \
    --enum-defs "$out_dir_glib"/gobject_enums.defs \
    --function-defs "$out_dir_glib"/gobject_functions.defs

  echo; echo ===== GLib, GModule and GObject: Signals
  "$gen_with_mmgir" --gir "$gir_dir"/GLib-2.0.gir --gir "$gir_dir"/GLibUnix-2.0.gir \
    --gir "$gir_dir"/GModule-2.0.gir --gir "$gir_dir"/GObject-2.0.gir \
    --gir-search-dir "$gir_dir" \
    --enum-defs /dev/null \
    --function-defs /dev/null \
    --signal-defs "$out_dir_glib"/glib_signals.defs

  echo; echo ===== Gio: Enums, methods, signals and vfuncs
  "$gen_with_mmgir" --gir "$gir_dir"/Gio-2.0.gir --gir "$gir_dir"/GioUnix-2.0.gir \
    --gir-search-dir "$gir_dir" \
    --enum-defs "$out_dir_gio"/gio_enums.defs \
    --function-defs "$out_dir_gio"/gio_methods.defs \
    --signal-defs "$out_dir_gio"/gio_signals.defs \
    --vfunc-defs "$out_dir_gio"/gio_vfuncs.defs

  echo; echo ===== Patching defs files
  patch_options="--backup --version-control=simple --suffix=.orig"
  # Execute in a subshell. The effect of the cd command is undone when the subshell ends.
  (
    cd "$out_dir_glib"
    for file in glib_enums.defs
    do
      patch $patch_options $file $file.girpatch
    done
  )
  (
    cd "$out_dir_gio"
    for file in gio_enums.defs gio_methods.defs gio_signals.defs gio_vfuncs.defs
    do
      patch $patch_options $file $file.girpatch
    done
  )
elif [ "$1" = "--make-patch" ]
then
  (
    cd "$out_dir_glib"
    for file in glib_enums.defs
    do
      diff --unified=5 $file.orig $file > $file.girpatch
    done
  )
  (
    cd "$out_dir_gio"
    for file in gio_enums.defs gio_methods.defs gio_signals.defs gio_vfuncs.defs
    do
      diff --unified=5 $file.orig $file > $file.girpatch
    done
  )
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
