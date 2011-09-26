#!/bin/sh -e

## Copyright 2011 Krzesimir Nowak
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; if not, write to the Free Software
## Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307, USA.
##

opt_o=0
opt_o_val=''
opt_p=0
opt_p_val=''

if test ! -x 'taghandlerwriter.pl'
then
  echo 'taghandlerwriter.pl either does not exist or is not an executable. Bailing out.' >&2
  exit 1
fi

for opt in ${@}
do
  if test ${opt_o} -eq 1
  then
    opt_o=2
    opt_o_val=${opt}
  elif test ${opt_p} -eq 1
  then
    opt_p=2
    opt_p_val=${opt}
  elif test "x${opt}" = 'x-o'
  then
    opt_o=1
  elif test "x${opt}" = 'x-p'
  then
    opt_p=1
  else
    echo "Unknown option: ${opt}. Bailing out." >&2
    exit 1
  fi
done

if test ${opt_o} -eq 1
then
  echo "-o option needs value. Bailing out." >&2
  exit 1
fi

if test ${opt_p} -eq 1
then
  echo "-p option needs value. Bailing out." >&2
  exit 1
fi

if test ${opt_o} -eq 0
then
  opt_o_val='Gir/Handlers/Generated'
  echo "No -o option given. Output directory is set to ${opt_o_val}."
fi

if test ${opt_p} -eq 0
then
  opt_p_val='Gir::Handlers::Generated'
  echo "No -p option given. Package prefix is set to ${opt_p_val}."
fi

girdir=''
pkgconfinv='pkg-config --variable=girdir gobject-introspection-1.0'
if $pkgconfinv >/dev/null 2>&1
then
	girdir=`$pkgconfinv`
fi

if test "x${girdir}" = 'x' || test ! -d "${girdir}"
then
  echo 'Bad gir directory or pkg-config invocation failed. Bailing out.' >&2
  exit 1
fi

for d in "${girdir}"/*.gir
do
  if test "x${d}" = "x${girdir}"'/*.gir'
  then
    echo "No gir files in $girdir. Bailing out." >&2
    exit 1
  fi
  break
done

commondir="${opt_o_val}/Common"
if test ! -e "${commondir}"
then
  mkdir -p "${commondir}"
elif test ! -d "${commondir}"
then
  echo "${commondir} already exists and is not a directory. Bailing out." >&2
  exit 1
fi

modignore=''
if test ! -f 'modules.ignore'
then
  echo 'No modules.ignore file found - handwritten gir files may have different structure.' >&2
else
  modignore='-i modules.ignore'
fi

./taghandlerwriter.pl -o "${opt_o_val}" -p "${opt_p_val}" ${modignore} "${girdir}"/*
