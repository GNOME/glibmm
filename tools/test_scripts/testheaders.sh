#!/bin/bash

# Compile each header file, one at a time.
# The compiler will notice if a header file does not include all other header
# files that it depends on.

# Example: In glibmm, go to directory glibmm, and run
#   tools/test_scripts/testheaders.sh -I glib giomm-2.68 gio # compile glibmm/gio/giomm/*.h
#   tools/test_scripts/testheaders.sh giomm-2.68 glib gio    # compile glibmm/glib/glibmm/*.h and glibmm/gio/giomm/*.h
#   tools/test_scripts/testheaders.sh -I glib glibmm-2.68 glib/glibmm/ustring.h # compile glibmm/glib/glibmm/ustring.h

# Usage: testheaders.sh [-I<dir>]... <pkg> [<dir> | <file>]...
# -I<dir> is added to the compiler flags.
# <pkg> is the name of the package, given to pkg-config.

function usage() {
  echo "Usage: $0 [-I<dir>]... <pkg> [<dir> | <file>]..."
  exit 1
}

# Compiler, default: CXX=g++
if test "x$CXX" = x
then
  CXX=g++
fi

# Extra compiler flags, default: CXXFLAGS=-std=c++17
if test "x$CXXFLAGS" = x
then
  CXXFLAGS=-std=c++17
fi

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
echo CXX=$CXX, CXXFLAGS=$CXXFLAGS
echo CFLAGS=$CFLAGS

# Compile the specified files
for i in "$@"
do
  if [ -d "$i" ]
  then
    for headerfile in $i/${i}mm/*.h
    do
      echo "=== $headerfile"
      $CXX -c -x c++ $CXXFLAGS -o /dev/null $headerfile $CFLAGS
    done
  else
    echo "=== $i"
    $CXX -c -x c++ $CXXFLAGS -o /dev/null $i $CFLAGS
  fi
done
