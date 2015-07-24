#!/bin/bash

# Note that JHBUILD_SOURCES should be defined to contain the path to the root
# of the jhbuild sources. The script assumes that it resides in the
# tools/gen_scripts directory and the defs file will be placed in gio/src.

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

if [ -z "$JHBUILD_SOURCES" ]; then
  echo -e "JHBUILD_SOURCES must contain the path to the jhbuild sources."
  exit 1;
fi

PREFIX="$JHBUILD_SOURCES/glib"
ROOT_DIR="$(dirname "$0")/../.."
OUT_DIR="$ROOT_DIR/gio/src"
OUT_FILE=gio_enums.defs
OUT_DIR_FILE="$OUT_DIR"/$OUT_FILE

if [ $# -eq 0 ]
then
  ENUM_PL="$JHBUILD_SOURCES/glibmm/tools/enum.pl"
  $ENUM_PL "$PREFIX"/gio/*.h > "$OUT_DIR_FILE"
  # patch version 2.7.5 does not like directory names.
  cd "$OUT_DIR"
  PATCH_OPTIONS="--backup --version-control=simple --suffix=.orig"
  patch $PATCH_OPTIONS $OUT_FILE $OUT_FILE.patch
elif [ "$1" = "--make-patch" ]
then
  diff --unified=5 "$OUT_DIR_FILE".orig "$OUT_DIR_FILE" > "$OUT_DIR_FILE".patch
else
  echo "Usage: $0 [--make-patch]"
  exit 1
fi
