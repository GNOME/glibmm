#!/bin/bash

# Compile each header file, one at a time.
# The compiler will notice if a header file does not include all other header
# files that it depends on.

# Example: In glibmm, go to directory glibmm, and run
#   tools/test_scripts/testheaders.sh -I glib giomm-2.4 gio # compile glibmm/gio/giomm/*.h
#   tools/test_scripts/testheaders.sh giomm-2.4 glib gio    # compile glibmm/glib/glibmm/*.h and glibmm/gio/giomm/*.h
#   tools/test_scripts/testheaders.sh -I glib glibmm-2.4 glib/glibmm/ustring.h # compile glibmm/glib/glibmm/ustring.h

# Usage: testheaders.sh [-I<dir>]... <pkg> [<dir> | <file>]...
# -I<dir> is added to the g++ command.
# <pkg> is the name of the package, given to pkg-config.

function usage() {
  echo "Usage: $0 [-I<dir>]... <pkg> [<dir> | <file>]..."
  exit 1
}

# Search for directories to include in CFLAGS.
idirs=""
while [ $# -gt 0 ]
do
  case "$1" in
    -I) if [ $# -lt 2 ]
        then
          usage
        fi
        idirs+=" -I$2"
        shift; shift
        ;;
    -I*) idirs+=" $1"
         shift
         ;;
    -*) echo "Illegal option: $1"
        usage
        ;;
    *) break
       ;;
  esac
done

# Package name
if [ $# -lt 1 ]
then
  echo "No package name"
  usage
fi
pkg="$1"
shift

# Search for more directories to include in CFLAGS.
for i in "$@"
do
  if [ -d "$i" ]
  then
    idirs+=" -I$i"
  fi
done

CFLAGS="$idirs `pkg-config --cflags $pkg`"
if [ $? -ne 0 ]
then
  echo "pkg-config failed"
  usage
fi
echo CFLAGS=$CFLAGS

# Compile the specified files
for i in "$@"
do
  if [ -d "$i" ]
  then
    for headerfile in $i/${i}mm/*.h
    do
      echo "=== $headerfile"
      g++ -c -x c++ -std=c++11 -o /dev/null $headerfile $CFLAGS
    done
  else
    echo "=== $i"
    g++ -c -x c++ -std=c++11 -o /dev/null $i $CFLAGS
  fi
done

