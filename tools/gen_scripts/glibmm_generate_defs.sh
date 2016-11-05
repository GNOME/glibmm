#!/bin/sh

if [ -z "$GLIBMM_DIR" ]; then
  echo -e "GLIBMM_DIR must contain the path to the glibmm repository."
  exit 1;
fi

function patch_directory {
    PATCH_OPTIONS="--backup --version-control=simple --suffix=.orig"
    for patch_file in $1/*.patch;
    do
	orig_file=$(echo $patch_file | sed s/.patch$//)
	patch $PATCH_OPTIONS $orig_file $patch_file
    done
}

MMGIRGEN_PATH=mmgirgenerator

############## GLib ###############
# GLib enums
$MMGIRGEN_PATH GLib-2.0 GModule-2.0 GObject-2.0 \
    --namespace=GLib \
    --namespace-mapping=GModule:GLib,GObject:GLib \
    --print-enum > $GLIBMM_DIR/glib/src/glib_enums.defs

#GLib signals & properties
$MMGIRGEN_PATH GLib-2.0 GModule-2.0 GObject-2.0 \
    --namespace=GLib \
    --namespace-mapping=GModule:GLib,GObject:GLib \
    --print-signal\
    --print-property > $GLIBMM_DIR/glib/src/glib_signals.defs

#GLib virtual methods
$MMGIRGEN_PATH GLib-2.0 GModule-2.0 GObject-2.0 \
    --namespace=GLib \
    --namespace-mapping=GModule:GLib,GObject:GLib \
    --print-vfunc > $GLIBMM_DIR/glib/src/glib_vfuncs.defs

patch_directory $GLIBMM_DIR/glib/src


############## Gio ###############
# Gio enums
$MMGIRGEN_PATH Gio-2.0 \
    --namespace=Gio \
    --print-enum > $GLIBMM_DIR/gio/src/gio_enums.defs

# Gio signals & properties
$MMGIRGEN_PATH Gio-2.0 \
    --namespace=Gio \
    --print-signal \
    --print-property > $GLIBMM_DIR/gio/src/gio_signals.defs

# Gio virtual methods
$MMGIRGEN_PATH Gio-2.0 \
    --namespace=Gio \
    --print-vfunc > $GLIBMM_DIR/gio/src/gio_vfuncs.defs

patch_directory $GLIBMM_DIR/gio/src
