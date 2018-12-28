#!/bin/bash

# Regenerate all glibmm's docs.xml and .defs files

cd "$(dirname "$0")"

./glib_generate_docs.sh
./glib_generate_enums.sh
./glib_generate_extra_defs.sh
./glib_generate_methods.sh

./gio_generate_docs.sh
./gio_generate_enums.sh
./gio_generate_extra_defs.sh
./gio_generate_methods.sh
