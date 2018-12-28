#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the XML file will be placed in gio/src.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/gio/src"

params="--with-properties --no-recursion"
for dir in "$source_prefix/gio" "$build_prefix/gio"; do
  params="$params -s $dir"
done
# Exclude $build_prefix/gio/xdp-dbus.c.
params="$params -x $build_prefix/gio/xdp-dbus.c"

"$gen_docs" $params > "$out_dir/gio_docs.xml"
