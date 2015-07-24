#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources.  The script assumes that it resides in the
# tools/gen_scripts directory and the defs files will be placed in glib/src.

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

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/glib/src"

if [ $# -eq 0 ]
then
  ENUM_PL="$JHBUILD_SOURCES/glibmm/tools/enum.pl"
  $ENUM_PL "$PREFIX"/glib/*.h "$PREFIX"/glib/deprecated/*.h > "$OUT_DIR"/glib_enums.defs
  $ENUM_PL "$PREFIX"/gmodule/*.h > "$OUT_DIR"/gmodule_enums.defs
  $ENUM_PL "$PREFIX"/gobject/*.h > "$OUT_DIR"/gobject_enums.defs
  # patch version 2.7.5 does not like directory names.
  cd "$OUT_DIR"
  PATCH_OPTIONS="--backup --version-control=simple --suffix=.orig"
  patch $PATCH_OPTIONS glib_enums.defs glib_enums.defs.patch
elif [ "$1" = "--make-patch" ]
then
  OUT_DIR_FILE="$OUT_DIR"/glib_enums.defs
  diff --unified=5 "$OUT_DIR_FILE".orig "$OUT_DIR_FILE" > "$OUT_DIR_FILE".patch
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
