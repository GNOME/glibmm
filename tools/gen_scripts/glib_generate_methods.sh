#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources. The script assumes it resides in the
# tools/gen_scripts directory and the defs files will be placed in glib/src.

# To update the g[lib|module|object]_functions.defs files:
# 1. ./glib_generate_methods.sh
#    Generates glib/src/glib_functions.defs.orig and glib/src/g[lib|module|object]_functions.defs.
#    If any hunks from the patch file fail to apply, apply them manually to the
#    glib_functions.defs file, if required.
# 2. Optional: Remove glib/src/glib_functions.defs.orig.

# To update the g[lib|module|object]_functions.defs files and the patch file:
# 1. Like step 1 when updating only the g[lib|module|object]_functions.defs files.
# 2. Apply new patches manually to the glib_functions.defs file.
# 3. ./glib_generate_methods.sh --make-patch
# 4. Like step 2 when updating only the g[lib|module|object]_functions.defs files.

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

shopt -s extglob # Enable extended pattern matching
if [ $# -eq 0 ]
then
  H2DEF_PY="$JHBUILD_SOURCES/glibmm/tools/defs_gen/h2def.py"
  # Process files whose names end with .h, but not with private.h.
  $H2DEF_PY "$PREFIX"/glib/!(*private).h "$PREFIX"/glib/deprecated/!(*private).h > "$OUT_DIR"/glib_functions.defs
  $H2DEF_PY "$PREFIX"/gmodule/!(*private).h > "$OUT_DIR"/gmodule_functions.defs
  $H2DEF_PY "$PREFIX"/gobject/!(*private).h > "$OUT_DIR"/gobject_functions.defs
  # patch version 2.7.5 does not like directory names.
  cd "$OUT_DIR"
  PATCH_OPTIONS="--backup --version-control=simple --suffix=.orig"
  patch $PATCH_OPTIONS glib_functions.defs glib_functions.defs.patch
elif [ "$1" = "--make-patch" ]
then
  OUT_DIR_FILE="$OUT_DIR"/glib_functions.defs
  diff --unified=5 "$OUT_DIR_FILE".orig "$OUT_DIR_FILE" > "$OUT_DIR_FILE".patch
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
