#!/bin/bash

# Check if all header files are included in file <dir>/<dir>mm.h.

# Example: In glibmm, go to directory glibmm, and run
#   tools/test_scripts/testmmh.sh gio   # check glibmm/gio/giomm.h
#   tools/test_scripts/testmmh.sh glib  # check glibmm/glib/glibmm.h

# For each file $1/$1mm/<name>.h, check if $1mm/<name>.h is included in $1/$1mm.h.
# If the file is not included in $1/$1mm.h, search for inclusion in any of the
# files $1/$1mm/<name>.h. Thus you can see if it's included indirectly via
# another header file.

# Some manual checking of $1/$1mm.h is usually necessary.
# Perhaps some header files (like wrap_init.h and <name>_private.h) shall not be included.
# Other header files shall perhaps be surrounded by #ifdef/#ifndef/#endif directives.

if [ $# -ne 1 ]
then
  echo "Usage $0 <directory>"
  exit 1
fi

for headerfile in $1/$1mm/*.h
do
  h1="${headerfile#$1/}" # Delete the "$1/" prefix
  h2="${h1//./\.}" # Replace each "." by "\."
  echo "=== $h1"
  grep -q  "^ *# *include  *<$h2>" $1/$1mm.h
  if [ $? -ne 0 ]
  then
    echo "  Missing"
    grep "<$h2>" $1/$1mm/*.h
  fi
done

exit 0

