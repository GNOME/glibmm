#!/bin/bash

# The script assumes that it resides in the tools/gen_scripts directory and
# the XML file will be placed in glib/src.

source "$(dirname "$0")/init_generate.sh"

out_dir="$root_dir/glib/src"

params="--with-properties --no-recursion"
for dir in "$source_prefix"/{glib,glib/deprecated,gmodule,gobject,gthread} \
           "$build_prefix"/{glib,gmodule,gobject,gthread}; do
  params="$params -s $dir"
done

"$gen_docs" $params > "$out_dir/glib_docs.xml"
