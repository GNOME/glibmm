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

opt_api_o=0
opt_api_o_val=''
opt_api_p=0
opt_api_p_val=''

struct_file='gir_structure'

if test ! -f "${struct_file}"
then
  echo "No ${struct_file} found. Bailing out." >&2
  exit 1
fi

script_file='taghandlerwriter.pl'

if test ! -x "${script_file}"
then
  echo "${script_file} either does not exist or is not an executable. Bailing out." >&2
  exit 1
fi

for opt in ${@}
do
  if test ${opt_o} -eq 1
  then
    opt_o=2
    opt_o_val=${opt}
  elif test ${opt_api_o} -eq 1
  then
    opt_api_o=2
    opt_api_o_val=${opt}
  elif test ${opt_p} -eq 1
  then
    opt_p=2
    opt_p_val=${opt}
  elif test ${opt_api_p} -eq 1
  then
    opt_api_p=2
    opt_api_p_val=${opt}
  elif test "x${opt}" = 'x-o'
  then
    opt_o=1
  elif test "x${opt}" = 'x-d'
  then
    opt_api_o=1
  elif test "x${opt}" = 'x-p'
  then
    opt_p=1
  elif test "x${opt}" = 'x-a'
  then
    opt_api_p=1
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

if test ${opt_api_o} -eq 1
then
  echo "-d option needs value. Bailing out." >&2
  exit 1
fi

if test ${opt_api_p} -eq 1
then
  echo "-a option needs value. Bailing out." >&2
  exit 1
fi

if test ${opt_o} -eq 0
then
  opt_o_val='Gir/Handlers'
  echo "No -o option given. Output directory is set to ${opt_o_val}."
fi

if test ${opt_p} -eq 0
then
  opt_p_val='Gir::Handlers'
  echo "No -p option given. Package prefix is set to ${opt_p_val}."
fi

if test ${opt_api_o} -eq 0
then
  opt_api_o_val='Gir/Api'
  echo "No -d option given. API output directory is set to ${opt_api_o_val}."
fi

if test ${opt_api_p} -eq 0
then
  opt_api_p_val='Gir::Api'
  echo "No -a option given. Package prefix is set to ${opt_api_p_val}."
fi

commondir="${opt_o_val}/Common"
if test ! -e "${commondir}"
then
  mkdir -p "${commondir}"
elif test ! -d "${commondir}"
then
  echo "${commondir} already exists and is not a directory. Bailing out." >&2
  exit 1
fi

apicommondir="${opt_api_o_val}/Common"
if test ! -e "${apicommondir}"
then
  mkdir -p "${apicommondir}"
elif test ! -d "${apicommondir}"
then
  echo "${apicommondir} already exists and is not a directory. Bailing out." >&2
  exit 1
fi

"./${script_file}" -o "${opt_o_val}" -p "${opt_p_val}" -d "${opt_api_o_val}" -a "${opt_api_p_val}" -i "${struct_file}"
